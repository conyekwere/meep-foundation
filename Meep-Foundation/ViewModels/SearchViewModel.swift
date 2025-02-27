//
//  SearchViewModel.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/26/25.
//

import MapKit
import Combine
import GooglePlaces

class SearchViewModel: ObservableObject {
    @Published var meetingPoints: [MeetingPoint] = []
    @Published var searchResults: [MeepAnnotation] = []
    
    // Category mapping from Apple Maps place types to our categories
    let categoryMapping: [String: (category: String, emoji: String)] = [
        "restaurant": ("Restaurant", "🍴"),
        "bar": ("Bar", "🍺"),
        "brewery": ("Bar", "🍺"),
        "nightlife": ("Bar", "🍺"),
        "cafe": ("Coffee shop", "☕"),
        "bakery": ("Bakery", "🍞"),
        "night club": ("Nightlife", "🪩"),
        "nightlife": ("Nightlife", "🪩"),   // Added for MKPOICategoryNightlife
        "mkpoicategorynightlife": ("Nightlife", "🪩"),  // Added specifically for your case
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
    
    func searchNearbyPlaces(
        at location: CLLocationCoordinate2D,
        radius: Double,
        departureTime: Date? = nil,
        categories: [String]? = nil
    ) {
        print("🔍 Searching Apple Maps for places near midpoint...")
        
        let delta = radius * 0.0145  // Roughly converts miles to degrees
        let request = MKLocalSearch.Request()
        
        // Form search query based on categories
        var searchQuery = "restaurant"
        if let cats = categories, !cats.isEmpty {
            searchQuery = cats.joined(separator: ", ")
        }
        
        request.naturalLanguageQuery = searchQuery
        request.region = MKCoordinateRegion(
            center: location,
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
                let midLoc = CLLocation(latitude: location.latitude, longitude: location.longitude)
                return locA.distance(from: midLoc) < locB.distance(from: midLoc)
            }
            
            DispatchQueue.main.async {
                self.meetingPoints = sortedPoints
                self.searchResults = sortedPoints.map {
                    MeepAnnotation(coordinate: $0.coordinate, title: $0.name, type: .place(emoji: $0.emoji))
                }
                self.fetchGooglePlacesMetadata(for: sortedPoints)
            }
        }
    }
    
    // MARK: - 📸 Fetch Google Places Metadata (Images, Ratings, etc.)
    func fetchGooglePlacesMetadata(for places: [MeetingPoint]) {
        let placesClient = GMSPlacesClient.shared()
        
        for place in places {
            guard let placeID = place.googlePlaceID else { continue }
            
            placesClient.lookUpPlaceID(placeID) { gmsPlace, error in
                guard let gmsPlace = gmsPlace, error == nil else {
                    print("Google Places API Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                if let metadata = gmsPlace.photos?.first {
                    placesClient.loadPlacePhoto(metadata) { image, error in
                        guard let image = image, error == nil else { return }
                        DispatchQueue.main.async {
                            if let index = self.meetingPoints.firstIndex(where: { $0.name == gmsPlace.name }) {
                                self.meetingPoints[index].imageUrl = image.description
                                print("✅ Updated image for \(gmsPlace.name)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Convert Apple Maps Search Result to MeetingPoint
    private func convert(mapItem: MKMapItem) -> MeetingPoint? {
        guard let coordinate = mapItem.placemark.location?.coordinate else {
            return nil
        }
        
        let placeType = mapItem.pointOfInterestCategory?.rawValue.lowercased() ?? "unknown"
        let categoryInfo = categoryMapping[placeType] ?? ("Unknown", "📍")
        
        return MeetingPoint(
            name: mapItem.name ?? "Unknown Place",
            emoji: categoryInfo.emoji,
            category: categoryInfo.category,
            coordinate: coordinate,
            imageUrl: mapItem.url?.absoluteString ?? "",
            googlePlaceID: nil
        )
    }
}
