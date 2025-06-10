//
//  NativeMapView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/9/25.
//


import SwiftUI
import MapKit

struct NativeMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let annotations: [MeepAnnotation]
    let showSubwayLines: Bool
    @ObservedObject var subwayManager: OptimizedSubwayMapManager
    var selectedAnnotationID: UUID?
    var onAnnotationSelected: (MeepAnnotation) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.mapType = .mutedStandard
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsTraffic = false
        mapView.showsBuildings = false
        
        return mapView
    }
    
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if not dragging
        if !context.coordinator.isDragging {
            mapView.setRegion(region, animated: true)
        }
        
        // Update annotations
        updateAnnotations(mapView)
        
        // Update subway overlays
        updateSubwayOverlays(mapView)
    }
    
    private func updateAnnotations(_ mapView: MKMapView) {
        // Remove existing annotations (except user location)
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        // Add new annotations
        for annotation in annotations {
            let mkAnnotation = MeepMapAnnotation()
            mkAnnotation.coordinate = annotation.coordinate
            mkAnnotation.title = annotation.title
            mkAnnotation.meepAnnotation = annotation
            mapView.addAnnotation(mkAnnotation)
        }
    }
    
    private func updateSubwayOverlays(_ mapView: MKMapView) {
        // Remove existing overlays
        mapView.removeOverlays(mapView.overlays)
        
        // Add subway lines if enabled
        if showSubwayLines && !subwayManager.visiblePolylines.isEmpty {
            mapView.addOverlays(subwayManager.visiblePolylines)
            
            // Add station circles when zoomed in
            if !subwayManager.visibleStationCircles.isEmpty {
                mapView.addOverlays(subwayManager.visibleStationCircles)
                print("📍 Added \(subwayManager.visibleStationCircles.count) station circles to map")
            }
        }
    }

    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NativeMapView
        var isDragging = false
        
        // Cache for hosting controllers to prevent memory leaks
        private var hostingControllers: [String: UIHostingController<AnyView>] = [:]
        
        init(_ parent: NativeMapView) {
            self.parent = parent
        }
        
        deinit {
            // Clean up hosting controllers
            hostingControllers.removeAll()
        }
        
        // Render annotations
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let meepAnnotation = annotation as? MeepMapAnnotation,
                  let annotation = meepAnnotation.meepAnnotation else {
                return nil
            }
            
            let identifier = "MeepAnnotation"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ?? MKAnnotationView(annotation: annotation as? MKAnnotation, reuseIdentifier: identifier)
            
            // Create unique key for this annotation
            let annotationKey = annotation.id.uuidString
            
            // Reuse or create hosting controller (memory optimization)
            let hostingController: UIHostingController<AnyView>
            if let existingController = hostingControllers[annotationKey] {
                hostingController = existingController
                // Update the selection state
                hostingController.rootView = AnyView(annotation.annotationView(
                    isSelected: .constant(annotation.id == parent.selectedAnnotationID)
                ))
            } else {
                // Create SwiftUI view for annotation
                hostingController = UIHostingController(
                    rootView: AnyView(annotation.annotationView(
                        isSelected: .constant(annotation.id == parent.selectedAnnotationID)
                    ))
                )
                hostingController.view.backgroundColor = .clear
                hostingControllers[annotationKey] = hostingController
            }
            
            // Size the view
            let size = hostingController.sizeThatFits(in: CGSize(width: 200, height: 200))
            hostingController.view.frame = CGRect(origin: .zero, size: size)
            
            // Clear previous subviews
            annotationView.subviews.forEach { $0.removeFromSuperview() }
            
            // Add the SwiftUI view
            annotationView.addSubview(hostingController.view)
            annotationView.frame = hostingController.view.frame
            annotationView.centerOffset = CGPoint(x: 0, y: -size.height/2)
            
            return annotationView
        }
        
        // Render subway lines
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                // Get line color from manager
                if let lineName = polyline.title {
                    renderer.strokeColor = parent.subwayManager.getLineColor(for: lineName)
                } else {
                    renderer.strokeColor = .systemGray
                }
                
                // Style to match StreetEasy
                let zoomLevel = parent.subwayManager.getZoomLevel(from: parent.region)
                renderer.lineWidth = parent.subwayManager.getLineWidth(for: polyline.title ?? "", zoomLevel: zoomLevel)
                renderer.lineCap = .round
                renderer.lineJoin = .round
                renderer.alpha = 0.9
                
                return renderer
            }
            else if let polygon = overlay as? MKPolygon {
                // Render station circles
                let renderer = MKPolygonRenderer(polygon: polygon)
                
                // Get station colors from manager
                if let lineName = polygon.title {
                    let colors = parent.subwayManager.getStationColor(for: lineName)
                    renderer.fillColor = colors.fill
                    renderer.strokeColor = colors.stroke
                } else {
                    renderer.fillColor = .white
                    renderer.strokeColor = .systemGray
                }
                
                renderer.lineWidth = 1.5
                renderer.alpha = 0.9
                
                print("🎨 Rendering station circle for line: \(polygon.title ?? "Unknown")")
                
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
        
        // Handle selection
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let meepAnnotation = view.annotation as? MeepMapAnnotation,
               let annotation = meepAnnotation.meepAnnotation {
                parent.onAnnotationSelected(annotation)
            }
        }
        
        // Track dragging
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            isDragging = true
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            isDragging = false
            parent.region = mapView.region
            
            // Update subway station visibility when region changes
            if parent.showSubwayLines && parent.subwayManager.hasLoadedData {
                parent.subwayManager.updateVisibleElements(for: mapView.region)
            }
        }
        
        // Clean up annotation views when they're removed (memory management)
        func mapView(_ mapView: MKMapView, didRemove views: [MKAnnotationView]) {
            for view in views {
                if let meepAnnotation = view.annotation as? MeepMapAnnotation,
                   let annotationID = meepAnnotation.meepAnnotation?.id.uuidString {
                    hostingControllers.removeValue(forKey: annotationID)
                }
            }
        }
    }
}

// Custom annotation class to hold MeepAnnotation reference
class MeepMapAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var title: String?
    var meepAnnotation: MeepAnnotation?
}
