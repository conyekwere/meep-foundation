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
    let imageUrl: String                        // ✅ Store image URLs
}
