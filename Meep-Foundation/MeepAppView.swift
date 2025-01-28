//
//  MeepAppView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//
import SwiftUI
import MapKit

struct MeepAppView: View {
    @StateObject private var viewModel = MeepViewModel()
    @State private var showOnboardingSheet: Bool = true
    @State private var showMeetingResultsSheet: Bool = false
    @State private var showMeetingSearchSheet: Bool = false

    // Define heights for snapping points
    private let BottomSheetMinHeight: CGFloat = 50
    private let BottomSheetMiddleHeight: CGFloat = UIScreen.main.bounds.height * 0.5
    private let BottomSheetMaxHeight: CGFloat = UIScreen.main.bounds.height * 0.8

    // Independent offsets for each sheet
    @State private var OnboardingSheetOffset: CGFloat = UIScreen.main.bounds.height * 0.5
    @State private var lastOnboardingDragOffset: CGFloat = UIScreen.main.bounds.height * 0.5

    @State private var MeetingResultsSheetOffset: CGFloat = UIScreen.main.bounds.height * 0.82
    @State private var lastResultsDragOffset: CGFloat = UIScreen.main.bounds.height * 0.82

    // MARK: - Gestures
    
    
    private func onboardingDragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                let newOffset = lastOnboardingDragOffset + value.translation.height
                if newOffset >= BottomSheetMinHeight && newOffset <= BottomSheetMaxHeight {
                    OnboardingSheetOffset = newOffset
                }
            }
            .onEnded { value in
                let dragAmount = value.translation.height
                let threshold = UIScreen.main.bounds.height * 0.15 // Sensitivity threshold for snapping

                withAnimation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 1)) {
                    if dragAmount < -threshold {
                        // Dragging up: Snap to the closest higher position
                        if OnboardingSheetOffset <= BottomSheetMiddleHeight {
                            OnboardingSheetOffset = BottomSheetMinHeight
                        } else {
                            OnboardingSheetOffset = BottomSheetMiddleHeight
                        }
                    } else if dragAmount > threshold {
                        // Dragging down: Snap to the closest lower position
                        if OnboardingSheetOffset >= BottomSheetMiddleHeight {
                            OnboardingSheetOffset = BottomSheetMaxHeight
                        } else {
                            OnboardingSheetOffset = BottomSheetMiddleHeight
                        }
                    } else {
                        // Snap to the **nearest** point based on offset
                        let middleDistance = abs(OnboardingSheetOffset - BottomSheetMiddleHeight)
                        let minDistance = abs(OnboardingSheetOffset - BottomSheetMinHeight)
                        let maxDistance = abs(OnboardingSheetOffset - BottomSheetMaxHeight)

                        if middleDistance < minDistance && middleDistance < maxDistance {
                            OnboardingSheetOffset = BottomSheetMiddleHeight
                        } else if minDistance < maxDistance {
                            OnboardingSheetOffset = BottomSheetMinHeight
                        } else {
                            OnboardingSheetOffset = BottomSheetMaxHeight
                        }
                    }
                }
                lastOnboardingDragOffset = OnboardingSheetOffset
            }
    }

    private func meetingResultsDragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                let newOffset = lastResultsDragOffset + value.translation.height
                if newOffset >= BottomSheetMinHeight && newOffset <= BottomSheetMaxHeight {
                    MeetingResultsSheetOffset = newOffset
                }
            }
            .onEnded { value in
                let dragAmount = value.translation.height
                let threshold = UIScreen.main.bounds.height * 0.15 // Sensitivity threshold for snapping

                withAnimation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 1)) {
                    if dragAmount < -threshold {
                        if MeetingResultsSheetOffset <= BottomSheetMiddleHeight {
                            MeetingResultsSheetOffset = BottomSheetMinHeight
                        } else {
                            MeetingResultsSheetOffset = BottomSheetMiddleHeight
                        }
                    } else if dragAmount > threshold {
                        if MeetingResultsSheetOffset >= BottomSheetMiddleHeight {
                            MeetingResultsSheetOffset = BottomSheetMaxHeight
                        } else {
                            MeetingResultsSheetOffset = BottomSheetMiddleHeight
                        }
                    } else {
                        let middleDistance = abs(MeetingResultsSheetOffset - BottomSheetMiddleHeight)
                        let minDistance = abs(MeetingResultsSheetOffset - BottomSheetMinHeight)
                        let maxDistance = abs(MeetingResultsSheetOffset - BottomSheetMaxHeight)

                        if middleDistance < minDistance && middleDistance < maxDistance {
                            MeetingResultsSheetOffset = BottomSheetMiddleHeight
                        } else if minDistance < maxDistance {
                            MeetingResultsSheetOffset = BottomSheetMinHeight
                        } else {
                            MeetingResultsSheetOffset = BottomSheetMaxHeight
                        }
                    }
                }
                lastResultsDragOffset = MeetingResultsSheetOffset
            }
    }
    
    
    var body: some View {
        ZStack {
            // MARK: - Map
            Map(
                coordinateRegion: $viewModel.mapRegion,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: viewModel.annotations
            ) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(annotation.type == .place ? .red : .blue)
                        Text(annotation.title)
                            .font(.caption)
                            .foregroundColor(.black)
                            .padding(4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(5)
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                viewModel.requestUserLocation()
            }
            
            // MARK: - Meeting Search Sheet
            
            .fullScreenCover(isPresented: $showMeetingSearchSheet) {
                MeetingSearchSheetView(
                    viewModel: viewModel,
                    isSearchActive: $showMeetingSearchSheet, onDismiss: {
                        showMeetingSearchSheet = false
                        showOnboardingSheet = true
                        showMeetingResultsSheet = false
                    }, onDone: {
                        showMeetingSearchSheet = false
                        showOnboardingSheet = false
                        showMeetingResultsSheet = true
                    }
                )
                .background(Color(.tertiarySystemBackground))
            }
            
            
            // MARK: - SearchBarWithAction
            VStack {
                if showMeetingResultsSheet {
                    SearchBarWithAction(
                        title: "35 Meeting Points",
                        subtitle: "777 Broadway · 210 E 121st St",
                        leadingIcon: "chevron.left",
                        trailingIcon: "slider.horizontal.3",
                        isDirty: true,
                        onLeadingIconTap: {
                            showMeetingSearchSheet = false
                            showOnboardingSheet = true
                            showMeetingResultsSheet = false
                        },
                        onTrailingIconTap: {
                            print("Filters tapped")
                        },
                        onContainerTap: {
                            print("Edit Search Bar tapped")
                        }
                    )
                    .padding()
                    .frame( height: 60)
                    .background(Color.white)
                    .cornerRadius(34)
                    .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.23999999463558197)), radius:16, x:0, y:3)
                }

                if showOnboardingSheet  {
                    SearchBarWithAction(
                        title: "Find where to meet",
                        subtitle: "My Location · Friends location",
                        leadingIcon: "magnifyingglass",
                        trailingIcon:"https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
                        isDirty: false,
                        onLeadingIconTap: {
                            showMeetingResultsSheet = false
                            showOnboardingSheet = false
                            showMeetingSearchSheet = true
                        },
                        onTrailingIconTap: {
                            print("User profile tapped")
                        },
                        onContainerTap: {
                            showMeetingResultsSheet = false
                            showOnboardingSheet = false
                            showMeetingSearchSheet = true
                        }
                    )
                    .padding()
                    .frame( height: 60)
                    .background(Color.white)
                    .cornerRadius(34)
                    .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.23999999463558197)), radius:16, x:0, y:3)
                }
                Spacer()
            }.padding()
                .zIndex(3)
            
            
            

            // MARK: - Onboarding Sheet
            if showOnboardingSheet {
                 VStack {
                     OnboardingSheetView(
                         viewModel: viewModel,
                         isLocationAllowed: $viewModel.isLocationAccessGranted,
                         searchRequest: $showMeetingSearchSheet
                     )
                     .background(Color(.tertiarySystemBackground))
                     .cornerRadius(OnboardingSheetOffset == BottomSheetMinHeight ? 0 : 24)
                     .shadow(color: Color.black.opacity(0.24), radius: OnboardingSheetOffset == BottomSheetMinHeight ? 0 : 30, x: 0, y: 3)
                     .offset(y: OnboardingSheetOffset)
                     .gesture(onboardingDragGesture())
                 }
                 .zIndex(2)
             }

            // MARK: - Meeting Results Sheet
            if showMeetingResultsSheet {
                VStack {
                    MeetingResultsSheetView(viewModel: viewModel)
                        .background(
                            Color(.tertiarySystemBackground)
                                .opacity(MeetingResultsSheetOffset == BottomSheetMinHeight ? 1 : 0.3)
                        )
                        .cornerRadius(MeetingResultsSheetOffset == BottomSheetMinHeight ? 0 : 24)
                        .shadow(color: Color.black.opacity(0.24), radius: MeetingResultsSheetOffset == BottomSheetMinHeight ? 0 : 30, x: 0, y: 3)
                        .offset(y: MeetingResultsSheetOffset)
                        .gesture(meetingResultsDragGesture())
                }
                .zIndex(1)
            }
            

            

            // MARK: - Floating Card for Selected Point
            if let selectedPoint = viewModel.selectedPoint,
               viewModel.isFloatingCardVisible {
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
