//
//  MeepMapView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/24/25.
//
import SwiftUI
import GoogleMaps
import GooglePlaces

struct MeepMapView: UIViewRepresentable {
    @ObservedObject var viewModel: MeepViewModel

    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: MeepMapView

        init(parent: MeepMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let annotation = marker.userData as? MeepAnnotation {
                withAnimation(.spring()) {
                    parent.viewModel.selectedAnnotation = annotation
                    parent.viewModel.isFloatingCardVisible = true
                }
            }
            return true
        }

        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            parent.viewModel.isUserInteractingWithMap = false
            parent.viewModel.searchNearbyPlaces()
        }

        func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
            if gesture {
                parent.viewModel.isUserInteractingWithMap = true
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: viewModel.mapRegion.center.latitude,
                                              longitude: viewModel.mapRegion.center.longitude,
                                              zoom: 14)
        let mapView = GMSMapView(frame: .zero, camera: camera)
        mapView.delegate = context.coordinator
        mapView.isMyLocationEnabled = true
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true

        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()

        for annotation in viewModel.annotations {
            let marker = GMSMarker(position: annotation.coordinate)
            marker.title = annotation.title
            marker.userData = annotation
            
            switch annotation.type {
            case .user:
                marker.icon = createUserMarker()
            case .friend:
                marker.icon = createFriendMarker()
            case .midpoint:
                marker.icon = createMidpointMarker()
            case .place(let emoji):
                marker.icon = createEmojiMarker(emoji: emoji)
            }

            marker.map = mapView
        }
    }

    private func createUserMarker() -> UIImage? {
        return createStyledMarker(icon: "dot.square.fill", color: .blue, label: "You")
    }
    
    private func createFriendMarker() -> UIImage? {
        return createStyledMarker(icon: "dot.square.fill", color: .gray, label: "Friend")
    }
    
    private func createMidpointMarker() -> UIImage? {
        return createStyledMarker(icon: "stop.circle.fill", color: .darkGray, label: "Midpoint")
    }
    
    private func createStyledMarker(icon: String, color: UIColor, label: String) -> UIImage? {
        let size = CGSize(width: 60, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        let rect = CGRect(origin: .zero, size: size)
        context?.setFillColor(UIColor.white.cgColor)
        context?.fillEllipse(in: rect)

        let imageView = UIImageView(frame: rect)
        imageView.image = UIImage(systemName: icon)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = color
        imageView.draw(rect)
        
        let labelRect = CGRect(x: 0, y: 30, width: size.width, height: 10)
        let labelView = UILabel(frame: labelRect)
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 8)
        labelView.textAlignment = .center
        labelView.draw(labelRect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
    
    private func createEmojiMarker(emoji: String) -> UIImage? {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let rect = CGRect(origin: .zero, size: size)

        let label = UILabel(frame: rect)
        label.text = emoji
        label.font = UIFont.systemFont(ofSize: 32)
        label.textAlignment = .center
        label.draw(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
