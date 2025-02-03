//
//  MeepViewModel.swift
//  Meep-Foundation
//  Handles all location, geocoding, and midpoint logic.
//  Created by Chima onyekwere on 1/21/25.
//

import Foundation
import CoreLocation
import MapKit
import Combine
import SwiftUI

class MeepViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Map Region & Meeting Points
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    

    @Published var meetingPoints: [MeetingPoint] = [
        MeetingPoint(name: "McSorley's Old Ale House", distance: 0.8, emoji: "🍺", category: "Bar",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7295, longitude: -73.9890),
                     imageUrl: "https://upload.wikimedia.org/wikipedia/commons/6/6b/McSorleys_Bar_NYC.jpg"),

        MeetingPoint(name: "Izakaya Toribar", distance: 1.2, emoji: "🍴", category: "Restaurant",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7282, longitude: -73.9921),
                     imageUrl: "https://example.com/izakaya-toribar.jpg"), // ✅ Fixed missing comma

        MeetingPoint(name: "Central Park", distance: 0.5, emoji: "🌳", category: "Park",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7851, longitude: -73.9683),
                     imageUrl: "https://upload.wikimedia.org/wikipedia/commons/6/6b/McSorleys_Bar_NYC.jpg"),

        MeetingPoint(name: "Joe's Coffee", distance: 1.0, emoji: "☕", category: "Cafe",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7812, longitude: -73.9665),
                     imageUrl: "https://upload.wikimedia.org/wikipedia/commons/6/6b/McSorleys_Bar_NYC.jpg"),

        MeetingPoint(name: "Museum of Art", distance: 2.0, emoji: "🎨", category: "Museum",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7794, longitude: -73.9632),
                     imageUrl: "https://upload.wikimedia.org/wikipedia/commons/6/6b/McSorleys_Bar_NYC.jpg")
    ]
    

        @Published var categories: [Category] = [
            Category(emoji: "🌍", name: "All", hidden: false),
            Category(emoji: "🍴", name: "Restaurant", hidden: false),
            Category(emoji: "🍺", name: "Bar", hidden: false),
            Category(emoji: "🌳", name: "Park", hidden: false),
            Category(emoji: "☕", name: "Cafe", hidden: false),
        ]
        
        @Published var hiddenCategories: [Category] = [
            Category(emoji: "🎨", name: "Museum", hidden: true),
            Category(emoji: "🏋️", name: "Gym", hidden: true),
            Category(emoji: "📚", name: "Library", hidden: true),
        ]
    
    
    // MARK: - Filtering & Floating Card
    @Published var selectedCategory: String = "All"

    
    @Published var selectedPoint: MeetingPoint? = nil
    @Published var isFloatingCardVisible = false
    
    
    
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
    
    // Dynamic annotations (midpoint, user, friend)
    var annotations: [MeepAnnotation] {
        var results: [MeepAnnotation] = []
        results.append(MeepAnnotation(coordinate: midpoint, title: "Midpoint", type: .place))
        if let uLoc = userLocation {
            results.append(MeepAnnotation(coordinate: uLoc, title: "You", type: .user))
        }
        if let fLoc = friendLocation {
            results.append(MeepAnnotation(coordinate: fLoc, title: "Friend", type: .user))
        }
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
    }
    
    // MARK: - Helpers
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
    func showDirections(to point: MeetingPoint) {
        let placemark = MKPlacemark(coordinate: point.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = point.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    
    
    // Reverse geocode the user's location.
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
                    self.SharableUserLocation = [placemark.name]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                    print("✅ My location updated: \(self.SharableUserLocation)")
                } else {
                    print("❌ Error reverse geocoding My Location: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    // Reverse geocode the friend's location.
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
                    self.SharableFriendLocation = [placemark.name]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                    print("✅ Friend location updated: \(self.SharableFriendLocation)")
                } else {
                    print("❌ Error reverse geocoding Friend Location: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }


    
    // MARK: - Geocoding
    /// Geocode two addresses and update locations.
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
        
        // Notify when both requests finish
        group.notify(queue: .main) {
            if let userCoord = userCoord, let friendCoord = friendCoord {
                print("Both locations geocoded successfully.")
                self.userLocation = userCoord
                self.friendLocation = friendCoord
                
                // Ensure mapRegion updates
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
