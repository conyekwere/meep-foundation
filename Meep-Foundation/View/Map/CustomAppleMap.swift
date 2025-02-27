//
//  CustomAppleMap.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/25/25.
//

//
//  CustomAppleMap.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/24/25.
//
//
//import SwiftUI
//import MapKit
//
//struct CustomAppleMap: UIViewRepresentable {
//    @ObservedObject var viewModel: MeepViewModel
//    
//    class Coordinator: NSObject, MKMapViewDelegate {
//        var parent: CustomAppleMap
//
//        init(parent: CustomAppleMap) {
//            self.parent = parent
//        }
//
//        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//            guard let annotation = view.annotation as? MeepAnnotation else { return }
//            withAnimation(.spring()) {
//                parent.viewModel.selectedAnnotation = annotation
//                parent.viewModel.isFloatingCardVisible = true
//            }
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        return Coordinator(parent: self)
//    }
//
//    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
//        mapView.delegate = context.coordinator
//        mapView.mapType = .mutedStandard // Muted style
//        mapView.showsUserLocation = true
//        mapView.pointOfInterestFilter = .excludingAll // Hide unwanted POIs
//        return mapView
//    }
//
//    func updateUIView(_ mapView: MKMapView, context: Context) {
//        mapView.removeAnnotations(mapView.annotations)
//        
//        for annotation in viewModel.annotations {
//            let mapAnnotation = MKPointAnnotation()
//            mapAnnotation.coordinate = annotation.coordinate
//            mapAnnotation.title = annotation.title
//            mapView.addAnnotation(mapAnnotation)
//        }
//    }
//}
