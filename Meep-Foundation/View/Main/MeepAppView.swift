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
    @State private var uiState: UIState = .onboarding

    // Sheet height constants
    private let sheetMin: CGFloat = 50
    private let sheetMid: CGFloat = UIScreen.main.bounds.height * 0.5
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
            
            // MARK: Full-Screen Search Sheet (Appears when UIState is .searching)
            .fullScreenCover(isPresented: Binding(get: {
                uiState == .searching
            }, set: { newValue in
                if !newValue { uiState = .onboarding }
            })) {
                MeetingSearchSheetView(
                    viewModel: viewModel,
                    isSearchActive: .constant(true),
                    onDismiss: { uiState = .onboarding },
                    onDone: { uiState = .results }
                )
                .background(Color(.tertiarySystemBackground))
            }
            
            // MARK: Top Search Bars Based on UIState
            VStack {
                if uiState == .results {
                    SearchBarWithAction(
                        title: "35 Meeting Points",
                        subtitle: "777 Broadway · 210 E 121st St",
                        leadingIcon: "chevron.left",
                        trailingIcon: "slider.horizontal.3",
                        isDirty: true,
                        onLeadingIconTap: { uiState = .onboarding },
                        onTrailingIconTap: { print("Filters tapped") },
                        onContainerTap: { print("Edit Search Bar tapped") }
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
                        subtitle: "My Location · Friend's Location",
                        leadingIcon: "magnifyingglass",
                        trailingIcon: "person.fill",
                        isDirty: false,
                        onLeadingIconTap: { uiState = .searching },
                        onTrailingIconTap: { print("User profile tapped") },
                        onContainerTap: {
                            // Trigger geocoding (here with hardcoded addresses for example)
                            
                            viewModel.userLocation = CLLocationCoordinate2D(latitude: 40.80129, longitude: -73.93684)
                                  viewModel.friendLocation = CLLocationCoordinate2D(latitude: 40.729713, longitude: -73.992796)
                            
                            
                            viewModel.geocodeAndSetLocations(userAddress: "210 e 121st st new york ny 10035",
                                                             friendAddress: "770 Broadway, New York, NY 10003")
                            uiState = .results
                        }
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
                    .background(
                        Color(.tertiarySystemBackground)
                            .opacity(meetingResultsOffset == sheetMin ? 1 : 0.3)
                    )
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
    }
}

#Preview {
    MeepAppView()
}
