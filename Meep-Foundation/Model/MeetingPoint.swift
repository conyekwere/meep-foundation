//
//  MeetingPoint.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import CoreLocation
import Foundation

struct MeetingPoint: Identifiable {
    let id = UUID()
    let name: String
    var emoji: String
    var category: String
    let coordinate: CLLocationCoordinate2D
    var imageUrl: String
    var googlePlaceID: String?
    var originalPlaceType: String? // To track the raw place type
    var photoReference: String? // For Google Places photo API
    var openingHours: [String]? // Optional array of opening hours strings
    
    
    func distance(from userLocation: CLLocationCoordinate2D?) -> Double {
           guard let userLocation = userLocation else { return 0.0 }
           
           let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
           let pointLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
           
           return userLoc.distance(from: pointLoc) / 1609.34  // Convert meters to miles
       }
    
    // Add initializers to maintain compatibility with existing code
    init(name: String, emoji: String, category: String, coordinate: CLLocationCoordinate2D, imageUrl: String) {
        self.name = name
        self.emoji = emoji
        self.category = category
        self.coordinate = coordinate
        self.imageUrl = imageUrl
        self.googlePlaceID = nil
        self.originalPlaceType = nil
        self.photoReference = nil
    }
    
    init(name: String, emoji: String, category: String, coordinate: CLLocationCoordinate2D,
            imageUrl: String, googlePlaceID: String? = nil, originalPlaceType: String? = nil,
            photoReference: String? = nil, openingHours: [String]? = nil) {
           self.name = name
           self.emoji = emoji
           self.category = category
           self.coordinate = coordinate
           self.imageUrl = imageUrl
           self.googlePlaceID = googlePlaceID
           self.originalPlaceType = originalPlaceType
           self.photoReference = photoReference
           self.openingHours = openingHours
       }
}
