//
//  MeepViewModel.swift
//  Meep-Foundation
//  Handles all location, geocoding, and midpoint logic.
//  Created by Chima onyekwere on 1/21/25.
//


import SwiftUI
import MapKit
import CoreLocation
import Combine

/// ViewModel for the Meep App, handling user location, friend location,
/// map region updates, meeting points, filtering, geocoding, and more.
class MeepViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Map Region & Meeting Points
    
    /// The current region of the map (center + span).
    @Published var mapRegion: MKCoordinateRegion = .init(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    /// The list of meeting points shown on the map.
    @Published var meetingPoints: [MeetingPoint] = [
        MeetingPoint(name: "McSorley's Old Ale House", emoji: "🍺", category: "Bar",
                     coordinate: CLLocationCoordinate2D(latitude: 40.728838, longitude: -73.9896487),
                     imageUrl: "https://thumbs.6sqft.com/wp-content/uploads/2017/03/10104443/02McSorleysInterior5Center72900.jpg?w=900&format=webp"),
        
        MeetingPoint(name: "Izakaya Toribar", emoji: "🍴", category: "Restaurant",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7596279, longitude: -73.9685453),
                     imageUrl: "https://i0.wp.com/izakayatoribar.com/wp-content/uploads/2020/02/FAA09132.jpg?resize=1024%2C683&ssl=1"),
        
        MeetingPoint(name: "Central Park", emoji: "🌳", category: "Park",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7943199, longitude: -73.9548079),
                     imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg/1599px-Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg"),
        
        MeetingPoint(name: "The Oasis Cafe", emoji: "☕", category: "Coffee shop",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7671355, longitude: -73.9866929),
                     imageUrl: "https://lh5.googleusercontent.com/p/AF1QipPCLsIFjbErCOILrg-jnMWBFmNG3RdSuEKsWd8E=w800-h500-k-no"),
        
        MeetingPoint(name: "Museum of Art", emoji: "🎨", category: "Museum",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7794, longitude: -73.9632),
                     imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Metropolitan_Museum_of_Art_%28The_Met%29_-_Central_Park%2C_NYC.jpg/500px-Metropolitan_Museum_of_Art_%28The_Met%29_-_Central_Park%2C_NYC.jpg")
    ]
    
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
        Category(emoji: "🍺", name: "Brewery", hidden: true),
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
        Category(emoji: "🎭", name: "Theater", hidden: true),
        Category(emoji: "🎓", name: "University", hidden: true),
        Category(emoji: "🍷", name: "Winery", hidden: true),
        Category(emoji: "🦁", name: "Zoo", hidden: true)
    ]
    
    
    
    /// ✅ Lookup function for emoji-based categories
    func getCategory(for emoji: String) -> String {
        return (categories + hiddenCategories)
            .first(where: { $0.emoji == emoji })?.name ?? "📍 Unknown"
    }
    
    
    // MARK: - Filtering & Floating Card
    @Published var selectedCategory: Category = Category(emoji: "", name: "All", hidden: false)
    
    
    @Published var selectedPoint: MeetingPoint? = nil
    @Published var isFloatingCardVisible: Bool = false
    
    // Sharable location strings (for UI display)
    @Published var SharableUserLocation: String = "My Location"
    @Published var SharableFriendLocation: String = "Friend's Location"
    
    
    
    // MARK: - Location Properties
    private var locationManager: CLLocationManager?
    @Published var isLocationAccessGranted: Bool = false
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var friendLocation: CLLocationCoordinate2D? = nil
    
    // Compute midpoint (fallback to NYC if either value is nil)
    var midpoint: CLLocationCoordinate2D {
        let uLat = userLocation?.latitude ?? 40.80129
        let uLon = userLocation?.longitude ?? -73.93684
        let fLat = friendLocation?.latitude ?? 40.729713
        let fLon = friendLocation?.longitude ?? -73.992796
        return CLLocationCoordinate2D(latitude: (uLat + fLat) / 2,
                                      longitude: (uLon + fLon) / 2)
    }
    
    @Published var sampleAnnotations: [MeepAnnotation] = []
    
    // Dynamic annotations (midpoint, user, friend)
    var annotations: [MeepAnnotation] {
        var results: [MeepAnnotation] = []

        // Midpoint
        results.append(MeepAnnotation(coordinate: midpoint, title: "Midpoint", type: .midpoint))

        // User location (if available)
        if let uLoc = userLocation {
            results.append(MeepAnnotation(coordinate: uLoc, title: SharableUserLocation, type: .user))
        }

        // Friend location (if available)
        if let fLoc = friendLocation {
            results.append(MeepAnnotation(coordinate: fLoc, title: SharableFriendLocation, type: .friend))
        }

        // Meeting points as place annotations
        results.append(contentsOf: meetingPoints.map {
            MeepAnnotation(coordinate: $0.coordinate, title: $0.name, type: .place(emoji: $0.emoji))
        })
        results.append(contentsOf: sampleAnnotations)
        
        return results
    }
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        // Recalculate midpoint and re-sort meeting points when locations change.
        Publishers.CombineLatest($userLocation, $friendLocation)
            .sink { [weak self] _, _ in
                self?.sortMeetingPointsByMidpoint()
                self?.centerMapOnMidpoint()
            }
            .store(in: &cancellables)
        
        $userLocation
            .sink { [weak self] _ in
                self?.updateMeetingPointDistances()
            }
            .store(in: &cancellables)
        
        // Optionally, load sample meeting points (if not already set)
        // Uncomment if you want to load these on initialization:
        // loadSampleAnnotations()
    }
    
    // MARK: - Helpers
    
    private func updateMeetingPointDistances() {
        objectWillChange.send()  // Ensures SwiftUI updates the UI
    }
    
    private func sortMeetingPointsByMidpoint() {
        let midLoc = CLLocation(latitude: midpoint.latitude, longitude: midpoint.longitude)
        meetingPoints.sort {
            let aLoc = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            let bLoc = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
            return aLoc.distance(from: midLoc) < bLoc.distance(from: midLoc)
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
    

    
    
    func loadSampleAnnotations() {
        sampleAnnotations = [
            MeepAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: 40.728838, longitude: -73.9896487),
                title: "McSorley's Old Ale House",
                type: .place(emoji: "🍺")
            ),
            MeepAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: 40.759628, longitude: -73.968545),
                title: "Izakaya Toribar",
                type: .place(emoji: "🍴")
            ),
            MeepAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: 40.794320, longitude: -73.954808),
                title: "Central Park",
                type: .place(emoji: "🌳")
            )
        ]
    }

    
    // MARK: - Location Permissions
    
    /// Requests “when in use” location permission from the user.
    func requestUserLocation() {
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
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
        guard let loc = locations.last else { return }
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
    
    // MARK: - Apple Maps Directions
    
    /// Opens Apple Maps with directions to the specified meeting point.
    func showDirections(to point: MeetingPoint) {
        let placemark = MKPlacemark(coordinate: point.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = point.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    // MARK: - Reverse Geocoding
    
    /// Reverse geocode the user's location into a sharable address.
    func reverseGeocodeUserLocation() {
        guard let userCoord = userLocation else {
            print("❌ User location is nil, skipping reverse geocoding")
            return
        }
        let userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(userLoc) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first, error == nil {
                    self.SharableUserLocation = [placemark.name].compactMap { $0 }.joined(separator: ", ")
                    print("✅ My location updated: \(self.SharableUserLocation)")
                } else {
                    print("❌ Error reverse geocoding My Location: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    /// Reverse geocode the friend's location into a sharable address.
    func reverseGeocodeFriendLocation() {
        guard let friendCoord = friendLocation else {
            print("❌ friendLocation is nil, skipping Friend Location reverse geocode")
            return
        }
        let friendLoc = CLLocation(latitude: friendCoord.latitude, longitude: friendCoord.longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(friendLoc) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first, error == nil {
                    self.SharableFriendLocation = [placemark.name].compactMap { $0 }.joined(separator: ", ")
                    print("✅ Friend location updated: \(self.SharableFriendLocation)")
                } else {
                    print("❌ Error reverse geocoding Friend Location: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // MARK: - Geocoding
    
    /// Geocode two addresses concurrently and update user and friend locations.
    func geocodeAndSetLocations(userAddress: String, friendAddress: String) {
        let geocoder = CLGeocoder()
        var userCoord: CLLocationCoordinate2D?
        var friendCoord: CLLocationCoordinate2D?
        
        let group = DispatchGroup()
        
        print("Starting geocoding for: \(userAddress) and \(friendAddress)")
        
        // Geocode "My Location"
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
        
        // Geocode "Friend's Location"
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
        
        // When both are done, update the locations.
        group.notify(queue: .main) {
            if let userCoord = userCoord, let friendCoord = friendCoord {
                print("Both locations geocoded successfully.")
                self.userLocation = userCoord
                self.friendLocation = friendCoord
                self.centerMapOnMidpoint()
            } else {
                print("Geocoding failed for at least one location.")
            }
        }
    }
    
    /// Geocode a single address string.
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
}
