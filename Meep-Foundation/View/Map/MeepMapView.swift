//
//  MeepMapView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/24/25.
//
//
//import SwiftUI
//import GoogleMaps
//import GooglePlaces
//
//struct MeepMapView: UIViewRepresentable {
//    @ObservedObject var viewModel: MeepViewModel
//
//    class Coordinator: NSObject, GMSMapViewDelegate {
//        var parent: MeepMapView
//
//        init(parent: MeepMapView) {
//            self.parent = parent
//        }
//
//        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
//            if let annotation = marker.userData as? MeepAnnotation {
//                withAnimation(.spring()) {
//                    parent.viewModel.selectedAnnotation = annotation
//                    parent.viewModel.isFloatingCardVisible = true
//                }
//            }
//            return true
//        }
//
//        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
//            parent.viewModel.isUserInteractingWithMap = false
//            parent.viewModel.searchNearbyPlaces()
//        }
//
//        func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
//            if gesture {
//                parent.viewModel.isUserInteractingWithMap = true
//            }
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        return Coordinator(parent: self)
//    }
//
//    func makeUIView(context: Context) -> GMSMapView {
//        let camera = GMSCameraPosition.camera(withLatitude: viewModel.mapRegion.center.latitude,
//                                              longitude: viewModel.mapRegion.center.longitude,
//                                              zoom: 10)
//        let mapView = GMSMapView(frame: .zero, camera: camera)
//        mapView.delegate = context.coordinator
//        mapView.isMyLocationEnabled = true
//        mapView.settings.compassButton = false
//        mapView.settings.myLocationButton = false
//        mapView.isBuildingsEnabled = false
//        mapView.isTrafficEnabled = false
//        mapView.mapType = .normal
//        return mapView
//
//    }
//
//    func updateUIView(_ mapView: GMSMapView, context: Context) {
//        mapView.clear()
//
//        
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        stackView.spacing = 8
//        stackView.alignment = .leading
//        
//        
//        // Add Annotations (Markers)
//        for annotation in viewModel.annotations {
//            let marker = GMSMarker(position: annotation.coordinate)
//            marker.title = annotation.title
//            marker.userData = annotation
//            
//            switch annotation.type {
//            case .user:
//                marker.icon = createUserMarker(title: "You", color: .blue)
//            case .friend:
//                marker.icon = createUserMarker(title: "Friend", color: .gray)
//            case .midpoint:
//                marker.icon = createMidpointMarker(title: "Midpoint")
//            case .place(let emoji):
//                marker.icon = createEmojiMarker(emoji: emoji)
//            }
//
//            marker.map = mapView
//            stackView.addArrangedSubview(UIView())
//        }
//    }
//
//    // MARK: - Custom Annotation Marker Creation
//
//    /// Creates a user or friend marker with text label.
//    private func createUserMarker(title: String, color: UIColor) -> UIImage? {
//        let size = CGSize(width: 120, height: 50)
//        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
//
//        let rect = CGRect(x: 40, y: 5, width: 80, height: 30)
//
//        let label = UILabel(frame: rect)
//        label.text = title
//        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
//        label.textColor = .black
//        label.textAlignment = .left
//        label.backgroundColor = UIColor.white.withAlphaComponent(0.9)
//        label.layer.cornerRadius = 4
//        label.layer.masksToBounds = true
//        label.draw(rect)
//
//        let iconRect = CGRect(x: 5, y: 5, width: 30, height: 30)
//        let icon = UIImage(systemName: "dot.square.fill")?
//            .withTintColor(color, renderingMode: .alwaysOriginal)
//        icon?.draw(in: iconRect)
//
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        return image
//    }
//
//    /// Creates the midpoint marker.
//    private func createMidpointMarker(title: String) -> UIImage? {
//        let size = CGSize(width: 120, height: 50)
//        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
//
//        let rect = CGRect(x: 40, y: 5, width: 80, height: 30)
//
//        let label = UILabel(frame: rect)
//        label.text = title
//        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
//        label.textColor = .black
//        label.textAlignment = .left
//        label.backgroundColor = UIColor.white.withAlphaComponent(0.9)
//        label.layer.cornerRadius = 4
//        label.layer.masksToBounds = true
//        label.draw(rect)
//
//        let iconRect = CGRect(x: 5, y: 5, width: 30, height: 30)
//        let icon = UIImage(systemName: "stop.circle.fill")?
//            .withTintColor(.darkGray, renderingMode: .alwaysOriginal)
//        icon?.draw(in: iconRect)
//
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        return image
//    }
//
//    /// Creates an emoji-based marker that visually matches the UI design.
//    private func createEmojiMarker(emoji: String) -> UIImage? {
//        let size = CGSize(width: 50, height: 70)
//        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
//
//        let context = UIGraphicsGetCurrentContext()
//        let rect = CGRect(x: 5, y: 5, width: 40, height: 40)
//        let textRect = CGRect(x: 0, y: 10, width: size.width, height: size.height)
//
//        let label = UILabel(frame: textRect)
//        label.text = emoji
//        label.font = UIFont.systemFont(ofSize: 32)
//        label.textAlignment = .center
//        label.draw(textRect)
//
//        // Create the pointer at the bottom (small triangle)
//        let pointerPath = UIBezierPath()
//        pointerPath.move(to: CGPoint(x: size.width / 2 - 5, y: size.height - 5))
//        pointerPath.addLine(to: CGPoint(x: size.width / 2 + 5, y: size.height - 5))
//        pointerPath.addLine(to: CGPoint(x: size.width / 2, y: size.height))
//        pointerPath.close()
//
//        UIColor.white.setFill()
//        pointerPath.fill()
//
//        context?.setShadow(offset: CGSize(width: 0, height: 1), blur: 2, color: UIColor.black.withAlphaComponent(0.15).cgColor)
//        pointerPath.fill()
//
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        return image
//    }
//}
