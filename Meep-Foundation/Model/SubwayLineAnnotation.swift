//
//  SubwayLineAnnotation.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/7/25.
//


import MapKit

struct SubwayLineAnnotation: Identifiable {
    let id = UUID()
    let polyline: MKPolyline
}