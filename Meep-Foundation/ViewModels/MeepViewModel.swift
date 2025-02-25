//
//  MeepViewModel.swift
//  Meep-Foundation
//  Handles all location, geocoding, and midpoint logic.
//  Refactored for scalability and enhanced searchNearbyPlaces functionality.
//  Created by Chima onyekwere on 1/21/25.
//

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

import GooglePlaces
import GoogleMaps

class MeepViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Map Region & Meeting Points
    @Published var mapRegion: MKCoordinateRegion = .init(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // List of meeting points found via search.
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
   
    // Using a comma-separated query for better compatibility.
    private let searchQuery = "restaurant"
    
    private let placesClient = GMSPlacesClient.shared()
    
    @Published var activeFilterCount: Int = 0
    
    @Published var searchRadius: Double = 0.02  // ~2km
    
    @Published var departureTime: Date? = nil    // nil means "Now"
    
    /// Returns the category name for a given emoji.
    func getCategory(for emoji: String) -> String {
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        return (categories + hiddenCategories).first(where: { $0.emoji == trimmedEmoji })?.name ?? "📍 Unknown"
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
    
    
    @Published var isUserInteractingWithMap = false
    
    // MARK: - Annotations
    @Published var sampleAnnotations: [MeepAnnotation] = []
    
    @Published var searchResults: [MeepAnnotation] = []
    
    /// Combines user, friend, midpoint, and place annotations.
    var annotations: [MeepAnnotation] {
        guard !isUserInteractingWithMap else { return [] } // Prevent unnecessary re-renders while panning
        var results: [MeepAnnotation] = []
        
        results.append(MeepAnnotation(coordinate: midpoint, title: "Midpoint", type: .midpoint))
        
        if let uLoc = userLocation {
            results.append(MeepAnnotation(coordinate: uLoc, title: sharableUserLocation, type: .user))
        }
        if let fLoc = friendLocation {
            results.append(MeepAnnotation(coordinate: fLoc, title: sharableFriendLocation, type: .friend))
        }
        
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
                DispatchQueue.main.async {
                    self?.sortMeetingPointsByMidpoint()
                    self?.centerMapOnMidpoint()
                    self?.calculateOptimalMeetingPoint()
                }
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
        guard !isUserInteractingWithMap else { return } // Prevent updates while user moves the map
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

        fetchTravelTime(from: userLoc, to: initialMidpoint, mode: userTransportMode, departureTime: departureTime) { [weak self] userTime in
            self?.fetchTravelTime(from: friendLoc, to: initialMidpoint, mode: self?.friendTransportMode ?? .walk, departureTime: self?.departureTime) { friendTime in
                DispatchQueue.main.async {
                    if abs(userTime - friendTime) < 3 * 60 {  // Allow 3-minute difference
                        self?.meetingPoint = initialMidpoint
                    } else {
                        // Weighted midpoint calculation based on time
                        let weight = (userTime / (userTime + friendTime)) * 0.6 + 0.4 // Bias slightly towards center
                        self?.meetingPoint = CLLocationCoordinate2D(
                            latitude: userLoc.latitude * weight + friendLoc.latitude * (1 - weight),
                            longitude: userLoc.longitude * weight + friendLoc.longitude * (1 - weight)
                        )
                    }
                }
            }
        }
    }
    
    
    func updateActiveFilterCount(myTransit: TransportMode, friendTransit: TransportMode, searchRadius: Double, departureTime: Date?) {
        var count = 0

        if myTransit != .train { count += 1 } // Example: Default is train, so any change counts as a filter
        if friendTransit != .train { count += 1 }
        if searchRadius != 2 { count += 1 } // Default search radius is 2 miles
        if departureTime != nil { count += 1 }

        activeFilterCount = count
    }
    
    
    
    /// Modified fetchTravelTime that uses an optional departureTime (for transit routes)
    private func fetchTravelTime(from origin: CLLocationCoordinate2D,
                                 to destination: CLLocationCoordinate2D,
                                 mode: TransportMode,
                                 departureTime: Date? = nil,
                                 completion: @escaping (TimeInterval) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        
        switch mode {
        case .walk:
            request.transportType = .walking
        case .car:
            request.transportType = .automobile
        case .bike:
            request.transportType = .walking // Approximate cycling with walking time
            request.requestsAlternateRoutes = true
        case .train:
            request.transportType = .transit
            // Use the selected departure time if provided (for transit directions)
            if let depTime = departureTime {
                request.departureDate = depTime
            }
        }
        
        MKDirections(request: request).calculate { response, error in
            if let travelTime = response?.routes.first?.expectedTravelTime, error == nil {
                let adjustedTravelTime = mode == .bike ? travelTime / 3 : travelTime
                completion(adjustedTravelTime)
            } else {
                completion(15 * 60) // default fallback: 15 minutes
            }
        }
    }
    
    // MARK: - Search Nearby Places
    /// Searches for nearby places based on the current midpoint.
    func searchNearbyPlaces() {
        print("🔍 Fetching places from Google Places API...")

        let locationBias = GMSPlaceRectangularLocationOption(
            CLLocationCoordinate2D(latitude: midpoint.latitude - 0.05, longitude: midpoint.longitude - 0.05),
            CLLocationCoordinate2D(latitude: midpoint.latitude + 0.05, longitude: midpoint.longitude + 0.05)
        )

        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        filter.locationBias = locationBias

        let searchTypes = ["restaurant", "bar", "cafe", "park", "museum"] // Valid categories
        let group = DispatchGroup()

        DispatchQueue.main.async { self.meetingPoints.removeAll() }

        for type in searchTypes {
            group.enter()
            placesClient.findAutocompletePredictions(fromQuery: type, filter: filter, sessionToken: nil) { [weak self] predictions, error in
                guard let self = self else { return }
                defer { group.leave() }

                if let error = error {
                    print("❌ Google Places Error: \(error.localizedDescription)")
                    return
                }

                guard let predictions = predictions else {
                    print("❌ No places found for type: \(type)")
                    return
                }

                for prediction in predictions {
                    guard let placeID: String? = prediction.placeID else { continue }
                    

                    group.enter()
                    self.fetchPlaceDetails(for: placeID ?? "default value") { meetingPoint in
                        if let meetingPoint = meetingPoint {
                            DispatchQueue.main.async {
                                self.meetingPoints.append(meetingPoint)
                            }
                        }
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) {
            print("✅ Finished fetching places")
        }
    }
    
    
    private func fetchPlaceDetails(for placeID: String, completion: @escaping (MeetingPoint?) -> Void) {
        let fields: GMSPlaceField = [.name, .coordinate, .photos, .types]

        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil) { [weak self] place, error in
            guard let self = self else {
                completion(nil)
                return
            }
            if let error = error {
                print("❌ Error fetching place details: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let place = place else {
                completion(nil)
                return
            }

            // Extract the first type and normalize it
            let rawType = place.types?.first?.lowercased() ?? "unknown"
            let mapping = self.categoryMapping[rawType] ?? (category: rawType.capitalized, emoji: "📍")

            var meetingPoint = MeetingPoint(
                name: place.name ?? "Unknown Place",
                emoji: mapping.emoji,
                category: mapping.category,
                coordinate: place.coordinate,
                imageUrl: "https://via.placeholder.com/400"
            )

            if let photoMetadata = place.photos?.first {
                self.placesClient.loadPlacePhoto(photoMetadata) { (image, error) in
                    if let error = error {
                        print("❌ Error loading place photo: \(error.localizedDescription)")
                    } else if let image = image {
                        DispatchQueue.main.async {
                            meetingPoint.imageUrl = self.convertImageToBase64(image: image)
                        }
                    }
                    completion(meetingPoint)
                }
            } else {
                completion(meetingPoint)
            }
        }
    }
    
    func convertImageToBase64(image: UIImage) -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return "" }
        return "data:image/jpeg;base64," + imageData.base64EncodedString()
    }
    
    
    func getPhotoURL(photoReference: String) -> String {
        if photoReference.isEmpty {
            return "https://via.placeholder.com/400" // Placeholder image
        }
        return "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=\(photoReference)&key=YOUR_GOOGLE_PLACES_API_KEY"
    }
    
    private func convert(mapItem: MKMapItem) -> MeetingPoint? {
        guard let coordinate = mapItem.placemark.location?.coordinate else {
            print("Skipping map item; no coordinate available.")
            return nil
        }
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
        DispatchQueue.main.async {
            self.userLocation = loc.coordinate
            self.mapRegion = MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
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
}
