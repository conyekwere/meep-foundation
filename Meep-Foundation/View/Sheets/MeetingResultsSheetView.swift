//
//  MeetingResultsSheetView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/22/25.
//


import SwiftUI

import MapKit
import PostHog

// PreferenceKey to track scroll offset
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MeetingResultsSheetView: View {
    @ObservedObject var viewModel: MeepViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showDirectionsOptions: Bool = false
    @State private var selectedPointForDirections: MeetingPoint? = nil
    @AppStorage("lastDirectedVenueID") private var lastDirectedVenueID: String = ""
    @AppStorage("lastDirectedVenueEmoji") private var lastDirectedVenueEmoji: String = ""
    @AppStorage("lastDirectedTimestamp") private var lastDirectedTimestamp: TimeInterval = 0
    @State private var showFoodTypeAlert: Bool = false
    @State private var showFoodTypeBucket: Bool = false
    private let filterFoodTypeFlagKey = "fake_door_filter_food_type_flag"
    @State private var scrollOffset: CGFloat = 0

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
                .onChange(of: viewModel.selectedCategory) { newCategory in
                    PostHogSDK.shared.capture("category_filtered", properties: [
                        "category_name": newCategory.name,
                        "category_emoji": newCategory.emoji
                    ])
                }

                // Meeting Points List
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        if viewModel.meetingPoints.isEmpty {
                            // Show 3 skeleton loaders while data is being fetched
                            ForEach(0..<5, id: \.self) { _ in
                                SkeletonMeetingPointCard()
                            }
                        } else if viewModel.isLoadingNearbyPlaces {
                            ProgressView("Searching nearby...")
                                  .padding()
                        }
                        else {
                            let filteredPoints = viewModel.meetingPoints.filter {
                                viewModel.selectedCategory.name == "All" || $0.category == viewModel.selectedCategory.name
                            }

                            if filteredPoints.isEmpty {
                                VStack(spacing: 24) {
                                    Text( viewModel.selectedCategory.emoji)
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    Text("No meeting points found for this category.")
                                        .font(.body)
                                    
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    Spacer()
                                    Button(action: {
                                        viewModel.searchNearbyPlacesFiltered()
                                    }) {
                                        Text("Redo Search for this Category")
                                            .fontWeight(.medium)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                            .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.top, 50)
                            } else {
                                ForEach(Array(filteredPoints.enumerated()), id: \.element.id) { index, point in
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
                                            myTransit: viewModel.userTransportMode,
                                            viewModel: viewModel
                                        )
                                        .frame(maxWidth: UIScreen.main.bounds.width * 0.95)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .coordinateSpace(name: "scrollView")
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scrollView")).minY)
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
                .padding(.bottom, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
            .ignoresSafeArea(edges: .bottom)
            .confirmationDialog(
                "Get Directions",
                isPresented: $showDirectionsOptions,
                titleVisibility: .visible
            ) {
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
        .overlay(
            Group {
                if  viewModel.selectedCategory.name == "restaurant"  && showFoodTypeBucket {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                PostHogSDK.shared.capture("fake_door_filter_food_type_clicked")
                                showFoodTypeAlert = true
                            }) {
                                Text("Filter")
                                    .font(.subheadline)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(24)
                            }
                            .padding(.bottom, 20)
                            .padding(.trailing, 20)
                        }
                    }
                }
            }
        )
        .alert("🍕 Filter by Food Type", isPresented: $showFoodTypeAlert) {
            Button("👍 Upvote") {
                PostHogSDK.shared.capture("fake_door_filter_food_type_upvote_clicked")
            }
            Button("👎 Downvote", role: .destructive) {
                PostHogSDK.shared.capture("fake_door_filter_food_type_downvote_clicked")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Coming Soon! Let us know if you'd like priority by upvoting, or not with a downvote.")
        }
        .onAppear {
            // Evaluate feature flag for showing the food-type button
            showFoodTypeBucket = PostHogSDK.shared.isFeatureEnabled(filterFoodTypeFlagKey)
            if showFoodTypeBucket {
                PostHogSDK.shared.capture("fake_door_filter_food_type_exposed")
            }
        }
    }
}

#Preview {
    MeetingResultsSheetView(viewModel: MeepViewModel())
        .previewLayout(.sizeThatFits)
}
