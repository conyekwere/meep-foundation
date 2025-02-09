//
//  MeepAppView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import SwiftUI
import MapKit

enum UIState {
    case onboarding, searching, results
}

struct MeepAppView: View {
    @StateObject private var viewModel = MeepViewModel()
    
    // Overall UI state for top search bars etc.
    @State private var uiState: UIState = .onboarding
    // Separate state variable to control the fullScreenCover presentation.
    @State private var isSearching: Bool = false
    
    // Separate state variable to control the fullScreenCover presentation.
    @State private var isProfileShown: Bool = false

    // Sheet height constants
    private let sheetMin: CGFloat = 90
    private let sheetMid: CGFloat = UIScreen.main.bounds.height * 0.4
    private let sheetMax: CGFloat = UIScreen.main.bounds.height * 0.8

    // Offsets for the draggable sheets along with last offset values
    @State private var onboardingOffset: CGFloat = UIScreen.main.bounds.height * 0.5
    @State private var lastOnboardingDragOffset: CGFloat = UIScreen.main.bounds.height * 0.5

    @State private var meetingResultsOffset: CGFloat = UIScreen.main.bounds.height * 0.82
    @State private var lastMeetingResultsDragOffset: CGFloat = UIScreen.main.bounds.height * 0.82

    var body: some View {
        ZStack {
            // MARK: Map View with Annotations
            Map(coordinateRegion: $viewModel.mapRegion,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: viewModel.annotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        annotation.annotationView
                    }
                }
            .ignoresSafeArea()
            .onAppear {
                viewModel.requestUserLocation()
            }
            
            // MARK: Top Search Bars Based on UIState
            VStack {
                if uiState == .results {
                    SearchBarWithAction(
                        title: "35 Meeting Points",
                        subtitle: "\(viewModel.SharableUserLocation) · \(viewModel.SharableFriendLocation)",
                        leadingIcon: "chevron.left",
                        trailingIcon: "slider.horizontal.3",
                        isDirty: true,
                        onLeadingIconTap: { isSearching = true }, // Trigger fullScreenCover
                        onTrailingIconTap: { print("Filters tapped") },
                        onContainerTap: { isSearching = true }  // Trigger fullScreenCover
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
                        subtitle: "\(viewModel.SharableUserLocation) · \(viewModel.SharableFriendLocation)",
                        leadingIcon: "magnifyingglass",
                        trailingIcon: "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
                        isDirty: false,
                        onLeadingIconTap: { isSearching = true },   
                        onTrailingIconTap: {
                            isProfileShown = true
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
                    .background(Color(.tertiarySystemBackground) )
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
                FloatingCardView(meetingPoint: selectedPoint) {
                    withAnimation {
                        viewModel.isFloatingCardVisible = false
                        viewModel.selectedPoint = nil
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
                    // When dismissing manually, switch to onboarding.
                    isSearching = false
                    uiState = .onboarding
                    
                    
                    // Reset the viewModel's locations to clear map annotations.
                    viewModel.userLocation = nil
                    viewModel.friendLocation = nil

                    // Reset the shareable location strings to their original values.
                    viewModel.SharableUserLocation = "My Location"
                    viewModel.SharableFriendLocation = "Friend's Location"
                },
                onDone: {
                    // When done, switch to results.
                    isSearching = false
                    uiState = .results
                }
            )
            .background(Color(.tertiarySystemBackground))
        }
        
        .sheet(isPresented: $isProfileShown) {
            ProfileBottomSheet(imageUrl: "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1")
                .presentationDetents([.fraction(0.65)])
                .presentationDragIndicator(.hidden)
        }
    }
}

#Preview {
    MeepAppView()
}
