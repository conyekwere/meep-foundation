//
//  MeetingResultsSheetView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/22/25.
//


import SwiftUI

import MapKit

struct MeetingResultsSheetView: View {
    @ObservedObject var viewModel: MeepViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showDirectionsOptions: Bool = false
    @State private var selectedPointForDirections: MeetingPoint? = nil

    var body: some View {
        ZStack {
            // A background blur, if desired
            // VisualEffectBlur(blurStyle: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
            //     .cornerRadius(16)
            //     .ignoresSafeArea(edges: .bottom)
            
            VStack(spacing: 16) {
                Capsule()
                    .frame(width: 40, height: 5)
                    .foregroundColor(Color(.lightGray).opacity(0.4))

                // Filter Bar
                FilterBarView(
                    selectedCategory: $viewModel.selectedCategory,
                    categories: viewModel.categories,
                    hiddenCategories: viewModel.hiddenCategories
                )
                .padding(.horizontal)

                // Meeting Points List
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        if viewModel.meetingPoints.isEmpty {
                            // Show 3 skeleton loaders while data is being fetched
                            ForEach(0..<3, id: \.self) { _ in
                                SkeletonMeetingPointCard()
                            }
                        } else {
                            ForEach(Array(viewModel.meetingPoints.filter {
                                viewModel.selectedCategory.name == "All" || $0.category == viewModel.selectedCategory.name
                            }.enumerated()), id: \.element.id) { index, point in
                                // Special handling for the first item if it's subway info
                                if index == 0 && (viewModel.userTransportMode == .train || viewModel.friendTransportMode == .train) {
                                    
                                    Button(action: {
                                        selectedPointForDirections = point
                                        showDirectionsOptions = true
                                    }) {
                                        SubwayMeetingPointInfoCard(
                                            point: point,
                                            subwayLines: viewModel.getSubwayLinesNear(coordinate: point.coordinate),
                                            userLocation: viewModel.userLocation,
                                            subwayManager: viewModel.subwayManager
                                        )
                                        .frame(maxWidth: UIScreen.main.bounds.width * 0.95)
                                    }
                                } else {
                                    MeetingPointCard(
                                        point: point,
                                        showDirections: {
                                            selectedPointForDirections = point
                                            showDirectionsOptions = true
                                        },
                                        userLocation: viewModel.userLocation,
                                        myTransit: viewModel.userTransportMode
                                    )
                                    .frame(maxWidth: UIScreen.main.bounds.width * 0.95)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
            .ignoresSafeArea(edges: .bottom)
            .confirmationDialog("Get Directions", isPresented: $showDirectionsOptions, titleVisibility: .visible) {
                if let meetingPoint = selectedPointForDirections {
                    Button("Apple Maps") {
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
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    MeetingResultsSheetView(viewModel: MeepViewModel())
        .previewLayout(.sizeThatFits)
}
