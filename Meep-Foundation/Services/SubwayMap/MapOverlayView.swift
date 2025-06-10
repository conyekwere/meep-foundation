//
//  MapKitOverlayView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/7/25.
//

import SwiftUI
import MapKit

struct MapKitOverlayView: UIViewRepresentable {
    let polylines: [MKPolyline]
    let mapRegion: MKCoordinateRegion
    @ObservedObject var overlayManager: SubwayMapOverlayManager
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Configure map to be transparent overlay
        mapView.isUserInteractionEnabled = false
        mapView.backgroundColor = .clear
        mapView.alpha = 1.0
        
        // Hide all map elements except overlays
        mapView.mapType = .mutedStandard
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsBuildings = false
        mapView.showsTraffic = false
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.showsUserLocation = false
        
        // Disable all interactions
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Keep overlay synchronized with main map
        DispatchQueue.main.async {
            mapView.setRegion(mapRegion, animated: false)
        }
        
        // Update overlays only if they've changed
        let currentOverlays = mapView.overlays.compactMap { $0 as? MKPolyline }
        
        if currentOverlays.count != polylines.count {
            mapView.removeOverlays(mapView.overlays)
            mapView.addOverlays(polylines)
        }
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
                
                // Get color from overlay manager using polyline ID
                if let polylineID = polyline.title {
                    renderer.strokeColor = overlayManager.getLineColor(for: polylineID)
                } else {
                    renderer.strokeColor = .systemGray
                }
                
                // Configure line appearance
                renderer.lineWidth = 3.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                renderer.alpha = 0.8
                
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
