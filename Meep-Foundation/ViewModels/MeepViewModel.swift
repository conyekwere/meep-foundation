//
//  MeepViewModel.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit
import Combine

class MeepViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Map Region
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    // MARK: - Annotations
    // NOTE: We'll generate this dynamically below so we can include midpoint/user/friend.
    // If you have static annotations, you can keep them here. Otherwise, see `var annotations` below.

    // MARK: - Meeting Points
    @Published var meetingPoints: [MeetingPoint] = [
        MeetingPoint(
            name: "Central Park",
            distance: 0.5,
            emoji: "🌳",
            category: "Park",
            coordinate: CLLocationCoordinate2D(latitude: 40.7851, longitude: -73.9683)
        ),
        MeetingPoint(
            name: "Joe's Coffee",
            distance: 1.0,
            emoji: "☕",
            category: "Cafe",
            coordinate: CLLocationCoordinate2D(latitude: 40.7812, longitude: -73.9665)
        ),
        MeetingPoint(
            name: "Museum of Art",
            distance: 2.0,
            emoji: "🎨",
            category: "Museum",
            coordinate: CLLocationCoordinate2D(latitude: 40.7794, longitude: -73.9632)
        )
    ]
    
    
    

    // MARK: - Category Filtering
    @Published var selectedCategory: String = "All"
    @Published var categories: [String] = ["All", "Park", "Cafe", "Museum"]
    @Published var hiddenCategories: [String] = ["Restaurant", "Gym", "Library"]

    // MARK: - Floating Card
    @Published var selectedPoint: MeetingPoint? = nil
    @Published var isFloatingCardVisible = false

    // MARK: - Location Manager
    private var locationManager: CLLocationManager?
    @Published var isLocationAccessGranted: Bool = false
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var showLocationDeniedAlert: Bool = false

    // MARK: - NEW: Friend Location & Midpoint
    /// Make it optional. Start nil so we can see changes when set.
       @Published var friendLocation: CLLocationCoordinate2D? = nil
       
       /// Dynamically compute the midpoint (fallback to NYC if either is nil).
       var midpoint: CLLocationCoordinate2D {
           let userLat = userLocation?.latitude ?? 40.7128
           let userLon = userLocation?.longitude ?? -74.0060

           // If friendLocation is nil, also fallback to NYC:
           let friendLat = friendLocation?.latitude ?? 40.7128
           let friendLon = friendLocation?.longitude ?? -74.0060

           return CLLocationCoordinate2D(
               latitude: (userLat + friendLat) / 2,
               longitude: (userLon + friendLon) / 2
           )
       }

    // MARK: - Annotations
    /// Dynamically build annotations to include the midpoint, user location, friend location, etc.
    var annotations: [MeepAnnotation] {
        var results: [MeepAnnotation] = []

        // 1) Midpoint annotation (optional)
        results.append(
            MeepAnnotation(
                coordinate: midpoint,
                title: "Midpoint",
                type: .place
            )
        )

        // 2) User annotation
        if let userLoc = userLocation {
            results.append(
                MeepAnnotation(
                    coordinate: userLoc,
                    title: "You",
                    type: .user
                )
            )
        }

        // 3) Friend annotation
        if let friendLoc = friendLocation {
            results.append(
                MeepAnnotation(
                    coordinate: friendLoc,
                    title: "Friend",
                    type: .user
                )
            )
        }

        return results
    }

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self

        // Whenever userLocation or friendLocation changes,
        // re-sort the meeting points by proximity to the midpoint, then update the map region
        Publishers.CombineLatest($userLocation, $friendLocation)
            .sink { [weak self] _, _ in
                self?.sortMeetingPointsByMidpoint()
                self?.centerMapOnMidpoint()
            }
            .store(in: &cancellables)
    }

    // MARK: - Sorting
    /// Sort meeting points so closest to the midpoint appear first
    private func sortMeetingPointsByMidpoint() {
        let midLocation = CLLocation(latitude: midpoint.latitude, longitude: midpoint.longitude)

        meetingPoints.sort { a, b in
            let locA = CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude)
            let locB = CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude)
            return locA.distance(from: midLocation) < locB.distance(from: midLocation)
        }
    }

    // MARK: - Center Map on Midpoint
    private func centerMapOnMidpoint() {
        withAnimation {
            mapRegion = MKCoordinateRegion(
                center: midpoint,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
    }

    // MARK: - Request User Location
    func requestUserLocation() {
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationAccessGranted = true
        case .denied:
            isLocationAccessGranted = false
            showLocationDeniedAlert = true
        case .restricted, .notDetermined:
            isLocationAccessGranted = false
        @unknown default:
            isLocationAccessGranted = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Debounce updates to significant location changes
        if let previousLocation = userLocation {
            let distance = location.distance(from: CLLocation(latitude: previousLocation.latitude, longitude: previousLocation.longitude))
            if distance < 50 { return } // Only update if moved 50+ meters
        }

        userLocation = location.coordinate
        mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        locationManager?.stopUpdatingLocation() // Stop updates after first known location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
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

    // MARK: - Get Meeting Point for a Coordinate (if needed)
    func getMeetingPoint(for coordinate: CLLocationCoordinate2D) -> MeetingPoint? {
        meetingPoints.first {
            $0.coordinate.latitude == coordinate.latitude &&
            $0.coordinate.longitude == coordinate.longitude
        }
    }
    
    // MARK: - GeocodeAndSetLocations
    
    func geocodeAndSetLocations(userAddress: String, friendAddress: String) {
        let geocoder = CLGeocoder()
        let group = DispatchGroup()

        var userCoord: CLLocationCoordinate2D?
        var friendCoord: CLLocationCoordinate2D?

        // 1) Geocode user's address
        group.enter()
        geocoder.geocodeAddressString(userAddress) { [weak self] placemarks, error in
            defer { group.leave() }
            if let placemark = placemarks?.first,
               let location = placemark.location {
                userCoord = location.coordinate
            } else {
                print("Error geocoding user address: \(error?.localizedDescription ?? "Unknown Error")")
            }
        }

        // 2) Geocode friend's address
        group.enter()
        geocoder.geocodeAddressString(friendAddress) { [weak self] placemarks, error in
            defer { group.leave() }
            if let placemark = placemarks?.first,
               let location = placemark.location {
                friendCoord = location.coordinate
            } else {
                print("Error geocoding friend address: \(error?.localizedDescription ?? "Unknown Error")")
            }
        }

        // 3) After both geocoding calls finish, update the published coords
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if let uCoord = userCoord, let fCoord = friendCoord {
                // Update the published properties; Combine will auto-trigger midpoint sorting
                self.userLocation = uCoord
                self.friendLocation = fCoord
            } else {
                print("Failed to obtain valid coordinates for both addresses.")
            }
        }
    }
    
}
