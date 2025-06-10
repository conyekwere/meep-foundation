//
//  SubwayPolylineOverlay.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/9/25.
//


// SubwayPolylineOverlay.swift

import SwiftUI
import MapKit

struct SubwayPolylineOverlay: UIViewRepresentable {
    let polylines: [MKPolyline]
    let overlayManager: SubwayMapOverlayManager

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.addOverlays(polylines)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(overlayManager: overlayManager)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        let overlayManager: SubwayMapOverlayManager

        init(overlayManager: SubwayMapOverlayManager) {
            self.overlayManager = overlayManager
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer()
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            if let id = polyline.title {
                renderer.strokeColor = overlayManager.getLineColor(for: id)
            } else {
                renderer.strokeColor = UIColor.systemGray
            }
            renderer.lineWidth = 3
            return renderer
        }
    }
}