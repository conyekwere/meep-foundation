////
////  MeepViewModel.swift
////  Meep-Foundation
////
////  Fully restored, optimized, and integrated with Apple Maps + Google Places.
////  - Apple Maps for location search & navigation
////  - Google Places SDK for metadata (images, ratings, etc.)
////
////  Created by Chima Onyekwere on 1/21/25.
////
//

import SwiftUI
import MapKit
import CoreLocation
import Combine
import GooglePlaces

class MeepViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - 🌍 Map & Meeting Point Management
    @Published var mapRegion: MKCoordinateRegion = .init(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    


    // MARK: - 🎯 Midpoint Calculation & Filtering
    
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
        "nightlife": ("Bar", "🍺"),   // Added for MKPOICategoryNightlife
        "mkpoicategorynightlife": ("Bar", "🍺"),  // Added specifically for your case
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
    
    
    @Published var selectedAnnotation: MeepAnnotation? = nil
    // Using a comma-separated query for better compatibility.
    private let searchQuery = "restaurant"
    
    @Published var activeFilterCount: Int = 0
    
    @Published var searchRadius: Double = 0.005  // Adjust this value as needed
    
    @Published var departureTime: Date? = nil    // nil means "Now"
    
    /// Returns the category name for a given emoji.
    func getCategory(for emoji: String) -> String {
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // First check our known categories
        if let category = (categories + hiddenCategories).first(where: { $0.emoji == trimmedEmoji }) {
            return category.name
        }
        
        // If not found in our categories, search the category mapping
        for (_, mapping) in categoryMapping where mapping.emoji == trimmedEmoji {
            return mapping.category
        }
        
        // If still not found, check if this is a system-provided place type
        // This handles cases where we get places from Apple Maps with types we haven't mapped
        if let originalPlaceType = getOriginalPlaceType(for: trimmedEmoji) {
            return "📍 \(originalPlaceType.capitalized)"  // Return with prefix to indicate it's unmapped
        }
        
        // Complete fallback
        return "📍 Unknown"
    }

    // Helper method to track original place types
    private func getOriginalPlaceType(for emoji: String) -> String? {
        // Look through the meeting points for matching emoji and original place type
        for meetingPoint in meetingPoints where meetingPoint.emoji == emoji && meetingPoint.originalPlaceType != nil {
            return meetingPoint.originalPlaceType
        }
        
        return nil
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
    
    
    
    @Published var isUserInteractingWithMap = false
    
    // MARK: - Annotations
    @Published var sampleAnnotations: [MeepAnnotation] = []
    

    
    func recordUnknownPlaceType(emoji: String, placeType: String) {
        // Save this mapping for future reference
        print("⚠️ Recorded unknown place type: \(placeType) with emoji: \(emoji)")
        
        // Here you could add to a persistent store or a dictionary
        // that tracks these for later classification
        
        // You might also want to add this to hiddenCategories automatically
        if !hiddenCategories.contains(where: { $0.emoji == emoji }) &&
           !categories.contains(where: { $0.emoji == emoji }) {
            
            DispatchQueue.main.async { [weak self] in
                self?.hiddenCategories.append(Category(
                    emoji: emoji,
                    name: placeType.capitalized,
                    hidden: true
                ))
            }
        }
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
    
    
    // MARK: - 📌 Annotations & Search
    @Published var searchResults: [MeepAnnotation] = []

    var annotations: [MeepAnnotation] {
        var results: [MeepAnnotation] = []
        
        results.append(MeepAnnotation(coordinate: midpoint, title: "Midpoint", type: .midpoint))
        
        if let uLoc = userLocation {
            results.append(MeepAnnotation(coordinate: uLoc, title: "You", type: .user))
        }
        if let fLoc = friendLocation {
            results.append(MeepAnnotation(coordinate: fLoc, title: "Friend", type: .friend))
        }
        
        results.append(contentsOf: searchResults)

        return results
    }
    
    
    


    // MARK: - 🎯 Midpoint Calculation
    var midpoint: CLLocationCoordinate2D {
        guard let userLoc = userLocation, let friendLoc = friendLocation else {
            // Use default values if either location is nil
            let uLat = userLocation?.latitude ?? 40.80129
            let uLon = userLocation?.longitude ?? -73.93684
            let fLat = friendLocation?.latitude ?? 40.729713
            let fLon = friendLocation?.longitude ?? -73.992796
            return CLLocationCoordinate2D(latitude: (uLat + fLat) / 2,
                                         longitude: (uLon + fLon) / 2)
        }
        
        // Convert to radians for more accurate geographical midpoint calculation
        let lat1 = userLoc.latitude * .pi / 180
        let lon1 = userLoc.longitude * .pi / 180
        let lat2 = friendLoc.latitude * .pi / 180
        let lon2 = friendLoc.longitude * .pi / 180
        
        // Calculate the midpoint using the Haversine formula
        let Bx = cos(lat2) * cos(lon2 - lon1)
        let By = cos(lat2) * sin(lon2 - lon1)
        let midLat = atan2(sin(lat1) + sin(lat2),
                           sqrt((cos(lat1) + Bx) * (cos(lat1) + Bx) + By * By))
        let midLon = lon1 + atan2(By, cos(lat1) + Bx)
        
        // Convert back to degrees
        return CLLocationCoordinate2D(
            latitude: midLat * 180 / .pi,
            longitude: midLon * 180 / .pi
        )
    }


    
    
    private func sortMeetingPointsByMidpoint() {
        let midLoc = CLLocation(latitude: midpoint.latitude, longitude: midpoint.longitude)
        meetingPoints.sort {
            let locA = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            let locB = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
            return locA.distance(from: midLoc) < locB.distance(from: midLoc)
        }
    }
    
    private func centerMapOnMidpoint() {
        guard !isUserInteractingWithMap else { return } // ✅ Prevent updates while user moves the map
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
        
        // Start with the geographical midpoint
        let initialMidpoint = midpoint
        
        // Pass the departureTime from the advanced filters
        fetchTravelTime(from: userLoc, to: initialMidpoint, mode: userTransportMode, departureTime: departureTime) { [weak self] userTime in
            guard let self = self else { return }
            
            self.fetchTravelTime(from: friendLoc, to: initialMidpoint, mode: self.friendTransportMode, departureTime: self.departureTime) { friendTime in
                DispatchQueue.main.async {
                    // If travel times are already close enough (within 3 minutes), use the midpoint
                    if abs(userTime - friendTime) < 3 * 60 {
                        self.meetingPoint = initialMidpoint
                        print("✅ Travel times balanced: User: \(Int(userTime/60))min, Friend: \(Int(friendTime/60))min")
                    } else {
                        // Calculate a weighted midpoint to balance travel times
                        // The weight is inversely proportional to travel time
                        let totalTime = userTime + friendTime
                        let userWeight = friendTime / totalTime  // User gets higher weight when friend has longer travel time
                        let friendWeight = userTime / totalTime  // Friend gets higher weight when user has longer travel time
                        
                        // Apply weights to coordinates
                        let weightedMidpoint = CLLocationCoordinate2D(
                            latitude: userLoc.latitude * userWeight + friendLoc.latitude * friendWeight,
                            longitude: userLoc.longitude * userWeight + friendLoc.longitude * friendWeight
                        )
                        
                        self.meetingPoint = weightedMidpoint
                        print("✅ Adjusted midpoint - User: \(Int(userTime/60))min, Friend: \(Int(friendTime/60))min")
                        
                        // Verify the improvement by calculating travel times to the new midpoint
                        self.verifyMeetingPoint(userLoc: userLoc, friendLoc: friendLoc, meetingPoint: weightedMidpoint)
                    }
                    
                    // After setting the meeting point, search for nearby places around it
                    self.searchNearbyPlaces()
                }
            }
        }
    }
    
    
    private func verifyMeetingPoint(userLoc: CLLocationCoordinate2D, friendLoc: CLLocationCoordinate2D, meetingPoint: CLLocationCoordinate2D) {
        fetchTravelTime(from: userLoc, to: meetingPoint, mode: userTransportMode, departureTime: departureTime) { [weak self] newUserTime in
            guard let self = self else { return }
            
            self.fetchTravelTime(from: friendLoc, to: meetingPoint, mode: self.friendTransportMode, departureTime: self.departureTime) { newFriendTime in
                print("🔍 Verification - New travel times: User: \(Int(newUserTime/60))min, Friend: \(Int(newFriendTime/60))min")
                print("🔍 Travel time difference: \(abs(Int(newUserTime - newFriendTime)/60))min")
            }
        }
    }
        
    // MARK: - 📌 Search Nearby Places (Apple Maps + Google Places)
    func searchNearbyPlaces() {
        print("🔍 Searching Apple Maps for places near midpoint...")

        let delta = searchRadius * 0.0145  // Roughly converts miles to degrees
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.region = MKCoordinateRegion(
            center: midpoint,
            span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        )

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }

            if let error = error {
                print("Apple Maps search error: \(error.localizedDescription)")
                return
            }

            guard let response = response else {
                print("No places found.")
                return
            }

            let fetchedMeetingPoints = response.mapItems.compactMap { self.convert(mapItem: $0) }

            let sortedPoints = fetchedMeetingPoints.sorted {
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
                self.updateCategoriesFromSearchResults() // Ensure categories are synced
                self.fetchGooglePlacesMetadata(for: sortedPoints)
            }
        }
    }


    
    func fetchPhotoWithReference(photoReference: String, maxWidth: Int = 800, completion: @escaping (UIImage?) -> Void) {
        // Replace "YOUR_API_KEY" with your actual Google Places API key
        // This is typically passed in from your app configuration
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GooglePlacesAPIKey") as? String else {
            print("❌ Missing Google Places API Key")
            completion(nil)
            return
        }
        
        let urlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=\(maxWidth)&photoreference=\(photoReference)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Photo download error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            if let image = UIImage(data: data) {
                completion(image)
            } else {
                print("❌ Could not create image from data")
                completion(nil)
            }
        }.resume()
    }
    
    // Helper method to load photos directly from Google Places
    private func loadPhotoDirectly(_ placesClient: GMSPlacesClient, photo: GMSPlacePhotoMetadata, meetingPointIndex: Int) {
        placesClient.loadPlacePhoto(photo) { [weak self] (image, error) in
            guard let self = self, let image = image, error == nil else {
                print("⚠️ Error loading photo: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Convert UIImage to data and create a data URL for immediate display
            if let imageData = image.jpegData(compressionQuality: 0.7) {
                let base64String = imageData.base64EncodedString()
                
                DispatchQueue.main.async {
                    if meetingPointIndex < self.meetingPoints.count {
                        self.meetingPoints[meetingPointIndex].imageUrl = "data:image/jpeg;base64,\(base64String)"
                        print("✅ Loaded direct photo for \(self.meetingPoints[meetingPointIndex].name)")
                    }
                }
            }
        }
    }


    // Fallback method to search by text
    private func searchPlaceByText(_ placesClient: GMSPlacesClient, placeName: String, meetingPointIndex: Int) {
        // Create a filter with the place name as the query
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        
        // Use the Autocomplete API to search for the place by name
        placesClient.findAutocompletePredictions(
            fromQuery: placeName,
            filter: filter,
            sessionToken: nil
        ) { [weak self] (predictions, error) in
            guard let self = self, let predictions = predictions, !predictions.isEmpty, error == nil else {
                print("⚠️ No autocomplete results for: \(placeName)")
                return
            }
            
            // Get the place ID from the first prediction
            let placeID = predictions[0].placeID
            
            // Fetch the place details to get photos
            self.fetchPhotoForExistingPlaceID(placesClient, placeID: placeID, meetingPointIndex: meetingPointIndex)
        }
    }


    
    
    
    
   
    // MARK: - 🔄 Convert Apple Maps Search Result to MeetingPoint
    
    
    private func convert(mapItem: MKMapItem) -> MeetingPoint? {
        guard let coordinate = mapItem.placemark.location?.coordinate else {
            return nil
        }
        
        // Get the original place type from the item
        var originalPlaceType = "unknown"
        if let poiCategory = mapItem.pointOfInterestCategory?.rawValue {
            originalPlaceType = poiCategory.lowercased()
            print("📍 Place type found: \(poiCategory) -> \(originalPlaceType)")
        }
        
        // Default emoji and category
        var emoji = "📍"
        var category = originalPlaceType.capitalized
        
        // Check if this is potentially a nightlife venue that needs verification
        let isPotentialNightlife = originalPlaceType.contains("nightlife") ||
                                  originalPlaceType.contains("night club") ||
                                  originalPlaceType.contains("bar") ||
                                  originalPlaceType.contains("pub")
        
        // Try to match with our category mapping
        if let mapping = categoryMapping[originalPlaceType] {
            emoji = mapping.emoji
            category = mapping.category
            print("✅ Direct category match: \(originalPlaceType) -> \(category) \(emoji)")
        } else {
            // If no direct match, try partial matching for more flexibility
            for (key, value) in categoryMapping {
                if originalPlaceType.contains(key) {
                    emoji = value.emoji
                    category = value.category
                    print("✅ Partial category match: \(originalPlaceType) contains \(key) -> \(category) \(emoji)")
                    break
                }
            }
            
            // If we're still using the default emoji, record this unknown place type
            if emoji == "📍" {
                print("⚠️ Unknown category: \(originalPlaceType)")
                recordUnknownPlaceType(emoji: emoji, placeType: originalPlaceType)
            }
        }
        
        return MeetingPoint(
            name: mapItem.name ?? "Unknown Place",
            emoji: emoji,
            category: category,
            coordinate: coordinate,
            imageUrl: "",  // Will be updated with Google Places photo
            googlePlaceID: nil,
            originalPlaceType: originalPlaceType
        )
    }


    
    
    // 2. Add a function to update and sync categories from search results
    func updateCategoriesFromSearchResults() {
        // Get all unique categories from meeting points
        let uniqueCategories = Set(meetingPoints.map { $0.category })
        
        // For each unique category, ensure it exists in our category lists
        for category in uniqueCategories {
            // Skip if it's unknown
            if category.lowercased() == "unknown" {
                continue
            }
            
            // Check if exists in visible categories
            let existsInVisible = categories.contains(where: { $0.name.lowercased() == category.lowercased() })
            
            // Check if exists in hidden categories
            let existsInHidden = hiddenCategories.contains(where: { $0.name.lowercased() == category.lowercased() })
            
            // If it doesn't exist in either list, add it to hidden categories
            if !existsInVisible && !existsInHidden {
                // Find matching emoji from category mapping
                var emoji = "📍"
                for (_, mapping) in categoryMapping {
                    if mapping.category.lowercased() == category.lowercased() {
                        emoji = mapping.emoji
                        break
                    }
                }
                
                hiddenCategories.append(Category(emoji: emoji, name: category, hidden: true))
            }
        }
    }

    
    // MARK: -  Fetch Travel Time
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
    
    // MARK: - 🚗 Show Directions
    func showDirections(to point: MeetingPoint) {
        let placemark = MKPlacemark(coordinate: point.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = point.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    // MARK: - 📍 Update Active FilterCount
    func updateActiveFilterCount(myTransit: TransportMode, friendTransit: TransportMode, searchRadius: Double, departureTime: Date?) {
        var count = 0

        if myTransit != .train { count += 1 } // Example: Default is `train`, so any change counts as a filter
        if friendTransit != .train { count += 1 }
        if searchRadius != 2 { count += 1 } // Default search radius is 2 miles
        if departureTime != nil { count += 1 }

        activeFilterCount = count
    }
    
    
    // MARK: - 📍 Reverse Geocoding
    
    
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
    
    func requestUserLocation() {
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
    func reverseGeocodeUserLocation() {
        guard let userCoord = userLocation else { return }
        let location = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first, error == nil {
                DispatchQueue.main.async {
                    self?.sharableUserLocation = placemark.name ?? "Unknown Location"
                }
            }
        }
    }

    func reverseGeocodeFriendLocation() {
        guard let friendCoord = friendLocation else { return }
        let location = CLLocation(latitude: friendCoord.latitude, longitude: friendCoord.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first, error == nil {
                DispatchQueue.main.async {
                    self?.sharableFriendLocation = placemark.name ?? "Unknown Location"
                }
            }
        }
    }

    func geocodeAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            completion(placemarks?.first?.location?.coordinate)
        }
    }
    
    



    // MARK: - 📸 Google Places Photo Handling

    // Main function to load and update photos
    func loadAndUpdatePhoto(_ placesClient: GMSPlacesClient, photo: GMSPlacePhotoMetadata, meetingPointIndex: Int) {
        // Load the actual photo
        placesClient.loadPlacePhoto(photo) { [weak self] (image, error) in
            if let error = error {
                print("⚠️ Error loading photo: \(error.localizedDescription)")
                return
            }
            
            guard let self = self, let downloadedImage = image else {
                return
            }
            
            // Update on main thread with the downloaded image
            OperationQueue.main.addOperation {
                guard meetingPointIndex < self.meetingPoints.count else { return }
                
                // Convert the image to a data URL for immediate display
                if let imageData = downloadedImage.jpegData(compressionQuality: 0.7) {
                    let base64String = imageData.base64EncodedString()
                    let dataURL = "data:image/jpeg;base64,\(base64String)"
                    
                    // Update the image URL
                    self.meetingPoints[meetingPointIndex].imageUrl = dataURL
                    
                    print("✅ Updated with direct image for \(self.meetingPoints[meetingPointIndex].name)")
                }
            }
        }
    }

    // Enhanced function to fetch place details including photos
    func fetchPlaceDetails(_ placesClient: GMSPlacesClient, placeID: String, meetingPointIndex: Int) {
        // Request fields we're interested in
        let fields: GMSPlaceField = [.name, .photos, .formattedAddress]
        
        placesClient.fetchPlace(
            fromPlaceID: placeID,
            placeFields: fields,
            sessionToken: nil
        ) { [weak self] (place, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("⚠️ Error fetching place details: \(error.localizedDescription)")
                return
            }
            
            guard let place = place else {
                print("⚠️ No place details found")
                return
            }
            
            // Update on main thread
            OperationQueue.main.addOperation {
                guard meetingPointIndex < self.meetingPoints.count else { return }
                
                // Update address if available
                if let address = place.formattedAddress {
                    // If you have an address field in MeetingPoint, use it
                    // self.meetingPoints[meetingPointIndex].address = address
                    print("📍 Address: \(address)")
                }
                
                // Load photo if available
                if let photos = place.photos, !photos.isEmpty {
                    self.loadAndUpdatePhoto(placesClient, photo: photos[0], meetingPointIndex: meetingPointIndex)
                }
            }
        }
    }

    // Helper to find place and fetch its details
    func findNearbyPlace(_ placesClient: GMSPlacesClient, place: MeetingPoint, index: Int) {
        // Use text search for better matching
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        
        // Create a more specific search query with both name and category
        var searchQuery = place.name
        if place.category != "Unknown" && !place.category.starts(with: "📍") {
            searchQuery += " \(place.category)"
        }
        
        // Try to add location context if possible
        let midpointLoc = CLLocation(latitude: midpoint.latitude, longitude: midpoint.longitude)
        CLGeocoder().reverseGeocodeLocation(midpointLoc) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            var updatedQuery = searchQuery
            if let city = placemarks?.first?.locality {
                updatedQuery += " \(city)"
            }
            
            // Search for the place
            placesClient.findAutocompletePredictions(
                fromQuery: updatedQuery,
                filter: filter,
                sessionToken: nil
            ) { [weak self] (predictions, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("⚠️ Error finding place: \(error.localizedDescription)")
                    return
                }
                
                guard let predictions = predictions, !predictions.isEmpty else {
                    print("⚠️ No autocomplete results for: \(place.name)")
                    return
                }
                
                // Get place ID from the first prediction
                let placeID = predictions[0].placeID
                
                // Store the ID and fetch details
                OperationQueue.main.addOperation {
                    if index < self.meetingPoints.count {
                        self.meetingPoints[index].googlePlaceID = placeID
                    }
                    
                    // Fetch place details including photos
                    self.fetchPlaceDetails(placesClient, placeID: placeID, meetingPointIndex: index)
                }
            }
        }
    }

    // Main function to fetch metadata for all meeting points
    func fetchGooglePlacesMetadata(for places: [MeetingPoint]) {
        print("🔍 Fetching Google Places metadata for \(places.count) places")
        let placesClient = GMSPlacesClient.shared()
        
        // Process each meeting point
        for (index, place) in places.enumerated() {
            // If we already have a Google Place ID, use it directly
            if let placeID = place.googlePlaceID {
                fetchPlaceDetails(placesClient, placeID: placeID, meetingPointIndex: index)
            } else {
                // Otherwise search for the place first
                findNearbyPlace(placesClient, place: place, index: index)
            }
        }
    }

    // Helper method to fetch photo for an existing Google Place ID
    func fetchPhotoForExistingPlaceID(_ placesClient: GMSPlacesClient, placeID: String, meetingPointIndex: Int) {
        placesClient.fetchPlace(
            fromPlaceID: placeID,
            placeFields: .photos,
            sessionToken: nil
        ) { [weak self] (place, error) in
            guard let self = self, let place = place, error == nil,
                  let photos = place.photos, !photos.isEmpty else {
                print("⚠️ No photos found for place ID: \(placeID)")
                return
            }
            
            // Get the first photo
            self.loadAndUpdatePhoto(placesClient, photo: photos[0], meetingPointIndex: meetingPointIndex)
        }
    }


    // Direct Google Places Photos API implementation
    func fetchPhotoWithReference(photoReference: String, completion: @escaping (UIImage?) -> Void) {
        // Get your API key from Info.plist
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GooglePlacesAPIKey") as? String else {
            print("❌ Missing Google Places API Key in Info.plist")
            completion(nil)
            return
        }
        
        // Construct the Photos API URL
        let urlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=\(photoReference)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL for photo reference")
            completion(nil)
            return
        }
        
        // Create and execute the network request
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Photo download error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            if let image = UIImage(data: data) {
                completion(image)
            } else {
                print("❌ Could not create image from data")
                completion(nil)
            }
        }.resume()
    }
    
    
}
