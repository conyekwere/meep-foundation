//
//  MeepAnnotation.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/22/25.
//

// MeepAnnotation.swift

import CoreLocation

struct MeepAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let type: AnnotationType


    init(coordinate: CLLocationCoordinate2D, title: String, type: AnnotationType) {
        self.coordinate = coordinate
        self.title = title
        self.type = type
    }
}

enum AnnotationType {
    case user
    case friend
    case midpoint
    case place(emoji: String)
}
