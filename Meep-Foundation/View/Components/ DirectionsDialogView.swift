//
//  DirectionsDialogView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/14/25.
//

import SwiftUI
import MapKit
import PostHog

struct DirectionsDialogView: View {
    @Binding var showDirectionsOptions: Bool
    @Binding var selectedPointForDirections: MeetingPoint?
    let viewModel: MeepViewModel

    @AppStorage("lastDirectedVenueID") private var lastDirectedVenueID: String?
    @AppStorage("lastDirectedVenueEmoji") private var lastDirectedVenueEmoji: String = ""
    @AppStorage("lastDirectedTimestamp") private var lastDirectedTimestamp: Double?



 
    var body: some View {

                if let meetingPoint = selectedPointForDirections {
                    Button("Apple Maps") {
                        PostHogSDK.shared.capture("directions_requested", properties: [
                            "venue_name": meetingPoint.name,
                            "app": "apple_maps",
                            "transport_mode": viewModel.userTransportMode.rawValue
                        ])
                        lastDirectedVenueID = meetingPoint.id.uuidString
                        lastDirectedVenueEmoji = meetingPoint.emoji
                        lastDirectedTimestamp = Date().timeIntervalSince1970
                        viewModel.markVisited(meetingPoint)
                        let placemark = MKPlacemark(coordinate: meetingPoint.coordinate)
                        let mapItem = MKMapItem(placemark: placemark)
                        mapItem.name = meetingPoint.name
                        mapItem.openInMaps(launchOptions: [
                            MKLaunchOptionsDirectionsModeKey: viewModel.userTransportMode.launchOption
                        ])
                    }
                    let googleMapsMode: String = {
                        switch viewModel.userTransportMode {
                        case .walk: return "walking"
                        case .bike: return "bicycling"
                        case .train: return "transit"
                        case .car: return "driving"
                        }
                    }()
                    if let url = URL(string: "comgooglemaps://?daddr=\(meetingPoint.coordinate.latitude),\(meetingPoint.coordinate.longitude)&directionsmode=\(googleMapsMode)"),
                       UIApplication.shared.canOpenURL(url) {
                        Button("Google Maps") {
                            PostHogSDK.shared.capture("directions_requested", properties: [
                                "venue_name": meetingPoint.name,
                                "app": "google_maps",
                                "transport_mode": viewModel.userTransportMode.rawValue
                            ])
                            lastDirectedVenueID = meetingPoint.id.uuidString
                            lastDirectedVenueEmoji = meetingPoint.emoji
                            lastDirectedTimestamp = Date().timeIntervalSince1970
                            viewModel.markVisited(meetingPoint)
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
    
}
