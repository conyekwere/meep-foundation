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

    // Define heights for snapping points
    private let BottomSheetMinHeight: CGFloat = 50
    private let BottomSheetMiddleHeight: CGFloat = UIScreen.main.bounds.height * 0.4
    private let BottomSheetMaxHeight: CGFloat = UIScreen.main.bounds.height * 0.8

    @State private var BottomSheetOffset: CGFloat = UIScreen.main.bounds.height * 0.82 // Start at bottom height
    @State private var lastDragOffset: CGFloat = UIScreen.main.bounds.height * 0.82 // Keep track of the last valid drag position

    private func smoothDragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                // Limit rapid updates for smooth movement
                let newOffset = lastDragOffset + value.translation.height
                if newOffset >= BottomSheetMinHeight && newOffset <= BottomSheetMaxHeight {
                    BottomSheetOffset = newOffset
                }
            }
            .onEnded { value in
                let dragAmount = value.translation.height

                withAnimation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 1)) {
                    // Snap to nearest snapping point
                    if dragAmount < -50 {
                        // Dragging up
                        if BottomSheetOffset <= BottomSheetMiddleHeight {
                            BottomSheetOffset = BottomSheetMinHeight // Snap to collapsed
                        } else {
                            BottomSheetOffset = BottomSheetMiddleHeight // Snap to middle
                        }
                    } else if dragAmount > 50 {
                        // Dragging down
                        if BottomSheetOffset >= BottomSheetMiddleHeight {
                            BottomSheetOffset = BottomSheetMaxHeight // Snap to expanded
                        } else {
                            BottomSheetOffset = BottomSheetMiddleHeight // Snap to middle
                        }
                    } else {
                        // Snap to nearest based on the offset
                        if BottomSheetOffset < BottomSheetMiddleHeight / 2 {
                            BottomSheetOffset = BottomSheetMinHeight // Snap to collapsed
                        } else if BottomSheetOffset > BottomSheetMiddleHeight && BottomSheetOffset < BottomSheetMaxHeight {
                            BottomSheetOffset = BottomSheetMiddleHeight // Snap to middle
                        } else {
                            BottomSheetOffset = BottomSheetMaxHeight // Snap to expanded
                        }
                    }
                }

                // Save the new drag position
                lastDragOffset = BottomSheetOffset
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
            
            VStack {
                Button(action: {
                    showMeetingResultsSheet = true
                    showOnboardingSheet = false
                }) {
                    Text("Find Meeting Points")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.bottom, 20)
                }
                Spacer()
            }

            // MARK: - Onboarding Sheet
            if showOnboardingSheet {
                VStack {
                    OnboardingSheetView(viewModel: viewModel, isLocationAllowed: $viewModel.isLocationAccessGranted)
                        .cornerRadius(16)
                        .shadow(radius: 30)
                        .background(Color(.tertiarySystemBackground).opacity(0.9))
                        .offset(y: BottomSheetOffset / 2)
                        .gesture(smoothDragGesture())
                }
                .zIndex(2)
            }

            // MARK: - Meeting Results Sheet
            if showMeetingResultsSheet {
                VStack {
                    MeetingResultsSheetView(viewModel: viewModel)
                        .cornerRadius(BottomSheetOffset == BottomSheetMinHeight ? 16 : 0)
                        .shadow(radius: BottomSheetOffset == BottomSheetMinHeight ? 0 : 30)
                        .background(
                            Color(.tertiarySystemBackground)
                                .opacity(BottomSheetOffset == BottomSheetMinHeight ? 1 : 0.5)
                        )
                        .offset(y: BottomSheetOffset)
                        .gesture(smoothDragGesture())
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
