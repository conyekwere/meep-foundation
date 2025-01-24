//
//  MeepAnnotation.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/22/25.
//



import CoreLocation

struct MeepAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let type: AnnotationType
}

enum AnnotationType {
    case user
    case friend
    case midpoint
    case place
}
