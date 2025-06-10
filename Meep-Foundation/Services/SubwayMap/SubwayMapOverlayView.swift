//
//  SubwayMapOverlayView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/9/25.
//


import SwiftUI
import MapKit

struct SubwayMapOverlayView: UIViewRepresentable {
    let polylines: [MKPolyline]
    let overlayManager: SubwayMapOverlayManager

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(polylines)
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
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                if let id = polyline.title {
                    renderer.strokeColor = overlayManager.getLineColor(for: id)
                } else {
                    renderer.strokeColor = .gray
                }
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
