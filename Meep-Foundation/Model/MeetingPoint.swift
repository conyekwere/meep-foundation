//
//  MeetingPoint.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import CoreLocation
import Foundation

struct MeetingPoint: Identifiable {
    let id = UUID()                             // Unique identifier
    let name: String                            // Name of the meeting point
    let emoji: String                           // Emoji representing the category
    let category: String                        // Category of the meeting point
    let coordinate: CLLocationCoordinate2D      // Geographic coordinates
    var imageUrl: String                        // ✅ Store image URLs
    
    
    func distance(from userLocation: CLLocationCoordinate2D?) -> Double {
           guard let userLocation = userLocation else { return 0.0 }
           
           let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
           let pointLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
           
           return userLoc.distance(from: pointLoc) / 1609.34  // Convert meters to miles
       }
}
