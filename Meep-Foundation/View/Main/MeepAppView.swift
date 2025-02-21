//
//  MeepAppView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import SwiftUI
import MapKit

enum UIState {
    case onboarding, searching, results,floatingResults
}

struct MeepAppView: View {
    @StateObject private var viewModel = MeepViewModel()
    
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
    @State private var searchRadius: Double = 10
    
    
    
    @State private var selectedAnnotation: MeepAnnotation? = nil
    
    private func setSelectedMeetingPoint(for annotation: MeepAnnotation) {
        let emoji: String
        if case let .place(emojiValue) = annotation.type {
            emoji = emojiValue
        } else {
            emoji = "📍"
        }

        let category = viewModel.getCategory(for: emoji) // ✅ Dynamically get category

        viewModel.selectedPoint = MeetingPoint(
            name: annotation.title,
            emoji: emoji,
            category: category, // ✅ Uses dynamic category lookup
            coordinate: annotation.coordinate,
            imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg/1599px-Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg"
        )
        viewModel.isFloatingCardVisible = true
    }

    

    var body: some View {
        ZStack {
            // MARK: Map View with Annotations
            Map(coordinateRegion: $viewModel.mapRegion,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: viewModel.annotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        annotation.annotationView(isSelected: Binding(
                            get: { selectedAnnotation?.id == annotation.id },
                            set: { newValue in
                                withAnimation(.spring()) {
                                    print("Parent binding setter called with:", newValue)
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


            .ignoresSafeArea()
            .onAppear {
                viewModel.loadSampleAnnotations()
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
                        onTrailingIconTap: {
                            isAdvancedFiltersPresented.toggle()
                        },
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
        
        .sheet(isPresented: $isProfilePresented) {
            ProfileBottomSheet(imageUrl: "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1")
                .presentationDetents([.fraction(0.65)])
                .presentationDragIndicator(.hidden)
        }
        
        .sheet(isPresented: $isAdvancedFiltersPresented) {
            AdvancedFiltersBottomSheet(
                myTransit: $myTransit,
                friendTransit: $friendTransit,
                searchRadius: $searchRadius
            )
            .presentationDetents([.fraction(0.85)])
        }
        
    }
}

#Preview {
    MeepAppView()
}
