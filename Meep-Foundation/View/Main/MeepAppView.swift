//
//  MeepAppView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//


import SwiftUI
import MapKit

enum UIState {
    case onboarding, searching, results, floatingResults
}

struct MeepAppView: View {
    @StateObject private var viewModel = MeepViewModel()
    
    
    @State private var departureTime: Date? = nil // ✅ Fix: Add departureTime
    
    // Overall UI state for top search bars etc.
    @State private var uiState: UIState = .onboarding
    // Separate state variable to control the fullScreenCover presentation.
    @State private var isSearching: Bool = false
    
    // Separate state variable to control the fullScreenCover presentation.
    @State private var isProfilePresented: Bool = false
    
    @State private var isAdvancedFiltersPresented: Bool  = false
    
    // Sheet height constants
    private let sheetMin: CGFloat = 90
    private let sheetMid: CGFloat = UIScreen.main.bounds.height * 0.4
    private let sheetMax: CGFloat = UIScreen.main.bounds.height * 0.8

    // Offsets for the draggable sheets along with last offset values
    @State private var onboardingOffset: CGFloat = UIScreen.main.bounds.height * 0.5
    @State private var lastOnboardingDragOffset: CGFloat = UIScreen.main.bounds.height * 0.5

    @State private var meetingResultsOffset: CGFloat = UIScreen.main.bounds.height * 0.82
    @State private var lastMeetingResultsDragOffset: CGFloat = UIScreen.main.bounds.height * 0.82
    
    @State private var myTransit: TransportMode = .train
    @State private var friendTransit: TransportMode = .train
    @State private var searchRadius: Double = 2
    
    @State private var selectedAnnotation: MeepAnnotation? = nil
    
    
    private func setSelectedMeetingPoint(for annotation: MeepAnnotation) {
        // Extract emoji from annotation
        let emoji: String
        if case let .place(emojiValue) = annotation.type {
            emoji = emojiValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            emoji = "📍"
        }
        
        // Dynamically get category
        let category = viewModel.getCategory(for: emoji)
        
        // Look for matching meeting point in viewModel's data to get its image URL
        if let existingPoint = viewModel.meetingPoints.first(where: {
            // Match by name and approximate coordinate (within small radius)
            $0.name == annotation.title &&
            abs($0.coordinate.latitude - annotation.coordinate.latitude) < 0.0001 &&
            abs($0.coordinate.longitude - annotation.coordinate.longitude) < 0.0001
        }) {
            // Use the existing point with its real image URL
            viewModel.selectedPoint = existingPoint
            viewModel.isFloatingCardVisible = true
            print("✅ Found existing meeting point: \(existingPoint.name) with image: \(existingPoint.imageUrl)")
        } else {
            // Create a new point with placeholder image
            viewModel.selectedPoint = MeetingPoint(
                name: annotation.title,
                emoji: emoji,
                category: category,
                coordinate: annotation.coordinate,
                imageUrl: "https://via.placeholder.com/400x300?text=Loading+Image"
            )
            viewModel.isFloatingCardVisible = true
            
            // Try to fetch image from Google Places API
            print("🔍 New meeting point - attempting to fetch image for: \(annotation.title)")
            
            // Create a temporary array with just this point
            let tempPoint = viewModel.selectedPoint!
            viewModel.fetchGooglePlacesMetadata(for: [tempPoint])
            
            // After a delay, update the selected point with any new image that was found
            // Using a capture list without 'weak' since MeepAppView is a struct
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [viewModel] in
                // Find the meeting point in the array that matches our selected point
                if let updatedPoint = viewModel.meetingPoints.first(where: {
                    $0.name == tempPoint.name &&
                    abs($0.coordinate.latitude - tempPoint.coordinate.latitude) < 0.0001 &&
                    abs($0.coordinate.longitude - tempPoint.coordinate.longitude) < 0.0001
                }) {
                    // Update our selected point with the new image URL and other metadata
                    viewModel.selectedPoint?.imageUrl = updatedPoint.imageUrl
                    
                    // Also update other metadata if available
                    if let placeID = updatedPoint.googlePlaceID {
                        viewModel.selectedPoint?.googlePlaceID = placeID
                    }
                    
                    if let originalType = updatedPoint.originalPlaceType {
                        viewModel.selectedPoint?.originalPlaceType = originalType
                    }
                    
                    if let hours = updatedPoint.openingHours {
                        viewModel.selectedPoint?.openingHours = hours
                    }
                    
                    print("✅ Updated selected point image to: \(updatedPoint.imageUrl)")
                }
            }
        }
    }
    

    var body: some View {
        ZStack {

            Map(coordinateRegion: $viewModel.mapRegion,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: viewModel.annotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        annotation.annotationView(isSelected: Binding(
                            get: { selectedAnnotation?.id == annotation.id },
                            set: { newValue in
                                withAnimation(.spring()) {
                                    if newValue {
                                        selectedAnnotation = annotation
                                        setSelectedMeetingPoint(for: annotation)
                                    } else {
                                        selectedAnnotation = nil
                                        viewModel.isFloatingCardVisible = false
                                    }
                                }
                            }
                        ))
                    }
                }
                .mapStyle(.standard(elevation: .flat,
                                                pointsOfInterest: .excludingAll,
                                                showsTraffic: false))
            
                .gesture(
                    DragGesture()
                        .onChanged { _ in viewModel.isUserInteractingWithMap = true } // ✅ Start Tracking Drag
                        .onEnded { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                viewModel.isUserInteractingWithMap = false // ✅ Only Recalculate AFTER Drag Stops
                                viewModel.searchNearbyPlaces() // ✅ Refresh Search When Drag Ends
                            }
                        }
                )
            .ignoresSafeArea()

            
            // MARK: Top Search Bars Based on UIState
            VStack {
                if uiState == .results {
                    SearchBarWithAction(
                        title: "\(viewModel.meetingPoints.count) Meeting Points",
                        subtitle: "\(viewModel.sharableUserLocation) · \(viewModel.sharableFriendLocation)",
                        leadingIcon: "chevron.left",
                        trailingIcon: "slider.horizontal.3",
                        isDirty: true,
                        filterCount: viewModel.activeFilterCount, // ✅ Add this to track filter count
                        onLeadingIconTap: { isSearching = true
                            viewModel.activeFilterCount = 0 },
                        onTrailingIconTap: { isAdvancedFiltersPresented.toggle() },
                        onContainerTap: { isSearching = true
                            viewModel.activeFilterCount = 0 }
                    )
                    .padding()
                    .frame(height: 60)
                    .background(Color.white)
                    .cornerRadius(34)
                    .shadow(radius: 16)
                }
                
                if uiState == .onboarding {
                    SearchBarWithAction(
                        title: "Find where to meet",
                        subtitle: "\(viewModel.sharableUserLocation) · \(viewModel.sharableFriendLocation)",
                        leadingIcon: "magnifyingglass",
                        trailingIcon: "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
                        isDirty: false,
                        filterCount: viewModel.activeFilterCount,
                        onLeadingIconTap: { isSearching = true },
                        onTrailingIconTap: {
                            isProfilePresented.toggle()
                            print("User profile tapped")
                        },
                        onContainerTap: { isSearching = true }
                    )
                    .padding()
                    .frame(height: 60)
                    .background(Color.white)
                    .cornerRadius(34)
                    .shadow(radius: 16)
                }
                Spacer()
            }
            .padding()
            .zIndex(3)
            
            // MARK: Onboarding Sheet (Draggable)
            if uiState == .onboarding {
                OnboardingSheetView(
                    viewModel: viewModel,
                    isLocationAllowed: $viewModel.isLocationAccessGranted,
                    searchRequest: .constant(false)
                )
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(onboardingOffset == sheetMin ? 0 : 24)
                .shadow(color: Color.black.opacity(0.24),
                        radius: onboardingOffset == sheetMin ? 0 : 30, x: 0, y: 3)
                .offset(y: onboardingOffset)
                .draggableSheet(offset: $onboardingOffset,
                                lastOffset: $lastOnboardingDragOffset,
                                minOffset: sheetMin,
                                midOffset: sheetMid,
                                maxOffset: sheetMax)
                .zIndex(2)
            }
            
            // MARK: Meeting Results Sheet (Draggable)
            if uiState == .results {
                MeetingResultsSheetView(viewModel: viewModel)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(meetingResultsOffset == sheetMin ? 0 : 24)
                    .shadow(color: Color.black.opacity(0.24),
                            radius: meetingResultsOffset == sheetMin ? 0 : 30, x: 0, y: 3)
                    .offset(y: meetingResultsOffset)
                    .draggableSheet(offset: $meetingResultsOffset,
                                    lastOffset: $lastMeetingResultsDragOffset,
                                    minOffset: sheetMin,
                                    midOffset: sheetMid,
                                    maxOffset: sheetMax)
                    .zIndex(1)
            }
            
            // MARK: Floating Card for Selected Point
            if let selectedPoint = viewModel.selectedPoint, viewModel.isFloatingCardVisible {
                Spacer()
                FloatingCardView(meetingPoint: selectedPoint) {
                    withAnimation {
                        viewModel.isFloatingCardVisible = false
                        viewModel.selectedPoint = nil
                        selectedAnnotation = nil // Deselect annotation when closing
                    }
                }
                .padding(.horizontal)
                .transition(.move(edge: .bottom))
                .zIndex(3)
            }
        }
        
        // MARK: Full-Screen Search Sheet
        .fullScreenCover(isPresented: $isSearching) {
            MeetingSearchSheetView(
                viewModel: viewModel,
                isSearchActive: .constant(true),
                onDismiss: {
                    isSearching = false
                    
                    // Only reset the view model if explicitly requested or if the search sheet is canceled
                    // without setting any locations
                    if viewModel.userLocation == nil && viewModel.friendLocation == nil {
                        uiState = .onboarding
                        
                        // Reset view model locations and shareable strings.
                        viewModel.userLocation = nil
                        viewModel.friendLocation = nil
                        viewModel.sharableUserLocation = "My Location"
                        viewModel.sharableFriendLocation = "Friend's Location"
                    } else {
                        // Maintain the current UI state
                        // This will preserve the results view when returning from search
                        // with existing locations
                    }
                },
                onDone: {
                    isSearching = false
                    uiState = .results
                }
            )
            .background(Color(.tertiarySystemBackground))
        }
        
        .sheet(isPresented: $isProfilePresented) {
            ProfileBottomSheet(imageUrl: "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1")
                .presentationDetents([.fraction(0.65)])
                .presentationDragIndicator(.hidden)
        }
        
        
        .sheet(isPresented: $isAdvancedFiltersPresented) {
            AdvancedFiltersBottomSheet(
                myTransit: $myTransit,
                friendTransit: $friendTransit,
                searchRadius: $searchRadius,
                departureTime: $departureTime,
                viewModel: viewModel // ✅ Pass ViewModel from Parent
            )
            .presentationDetents([.fraction(0.85)])
        }
    }
}

#Preview {
    MeepAppView()
}
