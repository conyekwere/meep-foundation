//
//  MeetingPoint.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import CoreLocation
import Foundation

struct MeetingPoint: Identifiable {
    let id = UUID() // Unique identifier
    let name: String // Name of the meeting point
    let emoji: String  // Emoji representing the category
    let category: String // Category of the meeting point
    let coordinate: CLLocationCoordinate2D // Geographic coordinates
    var imageUrl: String // Store image URLs
    var googlePlaceID: String? // Add Google Place ID
    var originalPlaceType: String? // To track the raw place type
    var photoReference: String? // For Google Places photo API
    
    
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
         imageUrl: String, googlePlaceID: String?, originalPlaceType: String? = nil, photoReference: String? = nil) {
        self.name = name
        self.emoji = emoji
        self.category = category
        self.coordinate = coordinate
        self.imageUrl = imageUrl
        self.googlePlaceID = googlePlaceID
        self.originalPlaceType = originalPlaceType
        self.photoReference = photoReference
    }
}
