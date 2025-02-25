//
//  MeepMapView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/24/25.
//

import SwiftUI
import MapKit

import GooglePlaces
import GoogleMaps

struct MeepMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: 40.7128, longitude: -74.0060, zoom: 12.0)
        let mapView = GMSMapView(frame: .zero, camera: camera)
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {}
}
