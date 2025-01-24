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

class MeepViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Map Region
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    // MARK: - Annotations
    @Published var annotations: [MeepAnnotation] = [
        MeepAnnotation(
            coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            title: "You",
            type: .user
        ),
        MeepAnnotation(
            coordinate: CLLocationCoordinate2D(latitude: 40.7158, longitude: -74.0020),
            title: "Coffee Shop",
            type: .place
        )
    ]

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

    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
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
            showLocationDeniedAlert = true // Trigger alert for denied access
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
            if distance < 50 { return } // Only update if moved 50 meters
        }
        
        userLocation = location.coordinate
        mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        locationManager?.stopUpdatingLocation() // Stop updates after obtaining location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }

    // MARK: - Get Meeting Point for Coordinate
    func getMeetingPoint(for coordinate: CLLocationCoordinate2D) -> MeetingPoint? {
        meetingPoints.first {
            $0.coordinate.latitude == coordinate.latitude &&
            $0.coordinate.longitude == coordinate.longitude
        }
    }
}
