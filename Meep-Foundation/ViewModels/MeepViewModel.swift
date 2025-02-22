//
//  MeepViewModel.swift
//  Meep-Foundation
//  Handles all location, geocoding, and midpoint logic.
//  Refactored for scalability and enhanced searchNearbyPlaces functionality.
//  Created by Chima onyekwere on 1/21/25.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

class MeepViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Map Region & Meeting Points
    @Published var mapRegion: MKCoordinateRegion = .init(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // List of meeting points found via search.
    @Published var meetingPoints: [MeetingPoint] = []
    
    @Published var categories: [Category] = [
        Category(emoji: "", name: "All", hidden: false),
        Category(emoji: "🍴", name: "Restaurant", hidden: false),
        Category(emoji: "🍺", name: "Bar", hidden: false),
        Category(emoji: "🌳", name: "Park", hidden: false),
        Category(emoji: "☕", name: "Coffee shop", hidden: false)
    ]
    
    @Published var hiddenCategories: [Category] = [
        Category(emoji: "✈️", name: "Airport", hidden: true),
        Category(emoji: "🍞", name: "Bakery", hidden: true),
        Category(emoji: "🏖", name: "Beach", hidden: true),
        Category(emoji: "🏋️", name: "Gym", hidden: true),
        Category(emoji: "🍎", name: "Groceries", hidden: true),
        Category(emoji: "🏨", name: "Hotel", hidden: true),
        Category(emoji: "📚", name: "Library", hidden: true),
        Category(emoji: "🎭", name: "Theater", hidden: true),
        Category(emoji: "🎨", name: "Museum", hidden: true),
        Category(emoji: "🏞", name: "National Park", hidden: true),
        Category(emoji: "🪩", name: "Nightlife", hidden: true),
        Category(emoji: "🚉", name: "Public Transport", hidden: true),
        Category(emoji: "🏟", name: "Stadium", hidden: true),
        Category(emoji: "🎓", name: "University", hidden: true),
        Category(emoji: "🍷", name: "Winery", hidden: true),
        Category(emoji: "🦁", name: "Zoo", hidden: true)
    ]
    
    // Mapping from MKLocalSearch place types to our categories.
    let categoryMapping: [String: (category: String, emoji: String)] = [
        "restaurant": ("Restaurant", "🍴"),
        "bar": ("Bar", "🍺"),
        "brewery": ("Bar", "🍺"),
        "cafe": ("Coffee shop", "☕"),
        "bakery": ("Bakery", "🍞"),
        "night club": ("Nightlife", "🪩"),
        "movie theater": ("Theater", "🎭"),
        "stadium": ("Stadium", "🏟"),
        "museum": ("Museum", "🎨"),
        "library": ("Library", "📚"),
        "art gallery": ("Museum", "🎨"),
        "park": ("Park", "🌳"),
        "national park": ("National Park", "🏞"),
        "zoo": ("Zoo", "🦁"),
        "supermarket": ("Groceries", "🍎"),
        "grocery store": ("Groceries", "🍎"),
        "department store": ("Retail", "🛍"),
        "train station": ("Public Transport", "🚉"),
        "airport": ("Airport", "✈️"),
        "bus station": ("Public Transport", "🚉"),
        "hotel": ("Hotel", "🏨"),
        "resort": ("Hotel", "🏨"),
        "gym": ("Gym", "🏋️"),
        "fitness center": ("Gym", "🏋️"),
        "winery": ("Winery", "🍷")
    ]
    
    
    private let searchQuery = """
    restaurant OR bar OR cafe OR park OR museum OR library OR bakery OR brewery OR winery OR stadium OR art gallery OR gym OR fitness center OR shopping mall OR supermarket OR grocery store OR hotel OR train station OR bus station OR airport OR zoo OR amusement park OR aquarium OR beach OR marina OR spa OR casino OR farmers market OR bookstore OR music venue OR theater OR deli OR diner OR food court
    """
    
    
    /// Returns the category name for a given emoji.
    func getCategory(for emoji: String) -> String {
        return (categories + hiddenCategories)
            .first(where: { $0.emoji == emoji })?.name ?? "📍 Unknown"
    }
    
    // MARK: - Filtering & Floating Card
    @Published var selectedCategory: Category = Category(emoji: "", name: "All", hidden: false)
    @Published var selectedPoint: MeetingPoint? = nil
    @Published var isFloatingCardVisible: Bool = false
    @Published var sharableUserLocation: String = "My Location"
    @Published var sharableFriendLocation: String = "Friend's Location"
    
    // MARK: - Location Properties
    private var locationManager: CLLocationManager?
    @Published var isLocationAccessGranted: Bool = false
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var friendLocation: CLLocationCoordinate2D?
    @Published var meetingPoint: CLLocationCoordinate2D?
    @Published var userTransportMode: TransportMode = .train
    @Published var friendTransportMode: TransportMode = .train
    
    /// Computes the midpoint (fallbacks to NYC coordinates if missing).
    var midpoint: CLLocationCoordinate2D {
        let uLat = userLocation?.latitude ?? 40.80129
        let uLon = userLocation?.longitude ?? -73.93684
        let fLat = friendLocation?.latitude ?? 40.729713
        let fLon = friendLocation?.longitude ?? -73.992796
        return CLLocationCoordinate2D(latitude: (uLat + fLat) / 2,
                                      longitude: (uLon + fLon) / 2)
    }
    
    // MARK: - Annotations
    @Published var searchResults: [MeepAnnotation] = []
    
    /// Combines user, friend, midpoint, and search result annotations.
    var annotations: [MeepAnnotation] {
        var results: [MeepAnnotation] = []
        // Midpoint Annotation
        results.append(MeepAnnotation(coordinate: midpoint, title: "Midpoint", type: .midpoint))
        // User Annotation
        if let uLoc = userLocation {
            results.append(MeepAnnotation(coordinate: uLoc, title: sharableUserLocation, type: .user))
        }
        // Friend Annotation
        if let fLoc = friendLocation {
            results.append(MeepAnnotation(coordinate: fLoc, title: sharableFriendLocation, type: .friend))
        }
        // Place Annotations from search results
        results.append(contentsOf: searchResults)
        return results
    }
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        Publishers.CombineLatest4($userLocation, $friendLocation, $userTransportMode, $friendTransportMode)
            .sink { [weak self] userLoc, friendLoc, userMode, friendMode in
                print("Combine triggered – userLoc: \(String(describing: userLoc)), friendLoc: \(String(describing: friendLoc)), userMode: \(userMode), friendMode: \(friendMode)")
                self?.sortMeetingPointsByMidpoint()
                self?.centerMapOnMidpoint()
                self?.calculateOptimalMeetingPoint()
                self?.searchNearbyPlaces()
            }
            .store(in: &cancellables)
    }

    
    // MARK: - Helpers
    private func sortMeetingPointsByMidpoint() {
        let midLoc = CLLocation(latitude: midpoint.latitude, longitude: midpoint.longitude)
        meetingPoints.sort {
            let locA = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            let locB = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
            return locA.distance(from: midLoc) < locB.distance(from: midLoc)
        }
    }
    
    private func centerMapOnMidpoint() {
        withAnimation {
            mapRegion = MKCoordinateRegion(
                center: midpoint,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
    }
    
    private func calculateOptimalMeetingPoint() {
        guard let userLoc = userLocation, let friendLoc = friendLocation else {
            print("❌ Missing one or both locations")
            return
        }
        
        let initialMidpoint = CLLocationCoordinate2D(
            latitude: (userLoc.latitude + friendLoc.latitude) / 2,
            longitude: (userLoc.longitude + friendLoc.longitude) / 2
        )
        
        fetchTravelTime(from: userLoc, to: initialMidpoint, mode: userTransportMode) { [weak self] userTime in
            self?.fetchTravelTime(from: friendLoc, to: initialMidpoint, mode: self?.friendTransportMode ?? .walk) { friendTime in
                if abs(userTime - friendTime) < 3 * 60 { // Allow a 3-minute difference
                    self?.meetingPoint = initialMidpoint
                } else {
                    let weight = userTime / (userTime + friendTime)
                    self?.meetingPoint = CLLocationCoordinate2D(
                        latitude: userLoc.latitude * weight + friendLoc.latitude * (1 - weight),
                        longitude: userLoc.longitude * weight + friendLoc.longitude * (1 - weight)
                    )
                }
            }
        }
    }
    
    private func fetchTravelTime(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, mode: TransportMode, completion: @escaping (TimeInterval) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        
        switch mode {
        case .walk: request.transportType = .walking
        case .car: request.transportType = .automobile
        case .bike:
            request.transportType = .walking // Approximate cycling with walking time
            request.requestsAlternateRoutes = true
        case .train: request.transportType = .transit
        }
        
        MKDirections(request: request).calculate { response, error in
            guard let travelTime = response?.routes.first?.expectedTravelTime, error == nil else {
                print("❌ Error fetching travel time: \(error?.localizedDescription ?? "Unknown")")
                completion(15 * 60) // Default 15 minutes
                return
            }
            
            let adjustedTime = mode == .bike ? travelTime / 3 : travelTime
            completion(adjustedTime)
        }
    }
    
    // MARK: - Search Nearby Places
    /// Searches for nearby places based on the current midpoint.
    func searchNearbyPlaces() {
        // Ensure both user and friend locations are available.
        guard let _ = userLocation, let _ = friendLocation else {
            print("User or friend location is nil. Skipping searchNearbyPlaces.")
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        // For testing, we use a larger region (0.05) so more results may be returned.
        request.region = MKCoordinateRegion(
            center: midpoint,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            if let error = error {
                print("Search error: \(error.localizedDescription)")
                return
            }
            guard let response = response else {
                print("Search returned no response.")
                return
            }
            
            print("🔍 Found \(response.mapItems.count) places near midpoint.")
            
            // Convert map items to meeting points.
            let meetingPoints = response.mapItems.compactMap { self.convert(mapItem: $0) }
            meetingPoints.forEach { point in
                print("📍 Place found: \(point.name) - Category: \(point.category)")
            }
            
            // Sort the meeting points based on distance from the midpoint.
            let sortedPoints = meetingPoints.sorted {
                let locA = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
                let locB = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
                let midLoc = CLLocation(latitude: self.midpoint.latitude, longitude: self.midpoint.longitude)
                return locA.distance(from: midLoc) < locB.distance(from: midLoc)
            }
            
            DispatchQueue.main.async {
                self.meetingPoints = sortedPoints
                self.searchResults = sortedPoints.map {
                    MeepAnnotation(coordinate: $0.coordinate, title: $0.name, type: .place(emoji: $0.emoji))
                }
                print("📍 Updated annotations with \(self.searchResults.count) search results.")
            }
        }
    }

    /// Converts an MKMapItem into a MeetingPoint.
    private func convert(mapItem: MKMapItem) -> MeetingPoint? {
        guard let coordinate = mapItem.placemark.location?.coordinate else { return nil }
        let placeType = mapItem.pointOfInterestCategory?.rawValue.lowercased() ?? "unknown"
        let mappedCategory = categoryMapping[placeType]?.category ?? "Other"
        let mappedEmoji = categoryMapping[placeType]?.emoji ?? "📍"
        
        return MeetingPoint(
            name: mapItem.name ?? "Unknown Place",
            emoji: mappedEmoji,
            category: mappedCategory,
            coordinate: coordinate,
            imageUrl: mapItem.url?.absoluteString ?? ""
        )
    }
    
    
    // MARK: - Location Permissions & Updates
    func requestUserLocation() {
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationAccessGranted = true
        case .denied:
            isLocationAccessGranted = false
        default:
            isLocationAccessGranted = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else {
            print("didUpdateLocations: No locations found.")
            return
        }
        print("Location updated: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
        userLocation = loc.coordinate
        mapRegion = MKCoordinateRegion(
            center: loc.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        locationManager?.stopUpdatingLocation()
    }

    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    // MARK: - Directions & Geocoding
    func showDirections(to point: MeetingPoint) {
        let placemark = MKPlacemark(coordinate: point.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = point.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    func reverseGeocodeUserLocation() {
        guard let userCoord = userLocation else {
            print("❌ User location is nil, skipping reverse geocoding")
            return
        }
        let location = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first, error == nil {
                    self?.sharableUserLocation = [placemark.name].compactMap { $0 }.joined(separator: ", ")
                    print("✅ My location updated: \(self?.sharableUserLocation ?? "")")
                } else {
                    print("❌ Error reverse geocoding My Location: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func reverseGeocodeFriendLocation() {
        guard let friendCoord = friendLocation else {
            print("❌ Friend location is nil, skipping reverse geocoding")
            return
        }
        let location = CLLocation(latitude: friendCoord.latitude, longitude: friendCoord.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first, error == nil {
                    self?.sharableFriendLocation = [placemark.name].compactMap { $0 }.joined(separator: ", ")
                    print("✅ Friend location updated: \(self?.sharableFriendLocation ?? "")")
                } else {
                    print("❌ Error reverse geocoding Friend Location: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func geocodeAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print("Geocoding error (\(address)): \(error.localizedDescription)")
                completion(nil)
                return
            }
            let coord = placemarks?.first?.location?.coordinate
            completion(coord)
        }
    }
    
    func geocodeAndSetLocations(userAddress: String, friendAddress: String) {
        let geocoder = CLGeocoder()
        var userCoord: CLLocationCoordinate2D?
        var friendCoord: CLLocationCoordinate2D?
        
        let group = DispatchGroup()
        print("Starting geocoding for: \(userAddress) and \(friendAddress)")
        
        group.enter()
        geocoder.geocodeAddressString(userAddress) { placemarks, error in
            if let error = error {
                print("User location geocode failed: \(error.localizedDescription)")
            }
            if let placemark = placemarks?.first, let coord = placemark.location?.coordinate {
                userCoord = coord
                print("User location geocoded: \(coord.latitude), \(coord.longitude)")
            } else {
                print("User address not found.")
            }
            group.leave()
        }
        
        group.enter()
        geocoder.geocodeAddressString(friendAddress) { placemarks, error in
            if let error = error {
                print("Friend location geocode failed: \(error.localizedDescription)")
            }
            if let placemark = placemarks?.first, let coord = placemark.location?.coordinate {
                friendCoord = coord
                print("Friend location geocoded: \(coord.latitude), \(coord.longitude)")
            } else {
                print("Friend address not found.")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let userCoord = userCoord, let friendCoord = friendCoord {
                print("Both locations geocoded successfully.")
                self.userLocation = userCoord
                self.friendLocation = friendCoord
                self.centerMapOnMidpoint()
                self.searchNearbyPlaces()
            } else {
                print("Geocoding failed for at least one location.")
            }
        }
    }
}
