//
//  MeepLoadingStateView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/26/25.
//


import SwiftUI

struct MeepLoadingStateView: View {
    let title: String
    let subtitle: String?
    let progressSteps: [String]
    @State private var currentStep: Int = 0
    @State private var animationProgress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    private let animationDuration: Double = 2.0
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Main loading icon with pulse animation
            ZStack {
                // Outer pulse circles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .scaleEffect(pulseScale + CGFloat(index) * 0.3)
                        .opacity(1.0 - (CGFloat(index) * 0.3))
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                            value: pulseScale
                        )
                }
                
                // Center icon
                Circle()
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                    .scaleEffect(pulseScale)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: pulseScale
                    )
            }
            .frame(width: 120, height: 120)
            .padding(.bottom,24)
            // Progress indicator
//            ProgressView(value: animationProgress, total: 1.0)
//                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
//                .frame(width: 200)
//                .animation(.linear(duration: animationDuration), value: animationProgress)
            
            VStack(spacing: 8) {
                // Main title
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                // Subtitle if provided
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Current step indicator
                if !progressSteps.isEmpty {
                    Text(progressSteps[currentStep])
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .id("step-\(currentStep)") // Force SwiftUI to animate text changes
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start pulse animation
        pulseScale = 1.2
        
        // Start progress animation
        withAnimation(.linear(duration: animationDuration * Double(progressSteps.count))) {
            animationProgress = 1.0
        }
        
        // Cycle through steps
        if !progressSteps.isEmpty {
            Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: true) { timer in
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = (currentStep + 1) % progressSteps.count
                }
            }
        }
    }
}

// MARK: - Preset Loading States

extension MeepLoadingStateView {
    static func findingMeetingSpots() -> MeepLoadingStateView {
        MeepLoadingStateView(
            title: "Finding meeting spots",
            subtitle: "Discovering the perfect places for you and your friend",
            progressSteps: [
                "Analyzing locations...",
                "Calculating transit routes...",
                "Finding nearby venues...",
                "Optimizing recommendations..."
            ]
        )
    }
    
    static func loadingSubwayData() -> MeepLoadingStateView {
        MeepLoadingStateView(
            title: "Loading subway data",
            subtitle: "Getting real-time transit information",
            progressSteps: [
                "Connecting to MTA...",
                "Loading subway lines...",
                "Calculating routes...",
                "Almost ready..."
            ]
        )
    }
    
    static func connectingToFriend() -> MeepLoadingStateView {
        MeepLoadingStateView(
            title: "Connecting to your friend",
            subtitle: "Establishing secure connection",
            progressSteps: [
                "Sending invitation...",
                "Waiting for response...",
                "Syncing locations...",
                "Connected!"
            ]
        )
    }
    
    static func generatingDirections() -> MeepLoadingStateView {
        MeepLoadingStateView(
            title: "Generating directions",
            subtitle: "Creating the best route for both of you",
            progressSteps: [
                "Analyzing traffic...",
                "Checking transit schedules...",
                "Optimizing routes...",
                "Finalizing directions..."
            ]
        )
    }
}

// MARK: - Usage in your MeepAppView

/*
// Replace your current loading overlay with this:

if isLoading {
    // Use appropriate preset based on loadingMessage
    Group {
        switch loadingMessage {
        case "Finding meeting spots...":
            MeepLoadingStateView.findingMeetingSpots()
        case "Loading subway data...":
            MeepLoadingStateView.loadingSubwayData()
        default:
            MeepLoadingStateView(
                title: loadingMessage,
                subtitle: nil,
                progressSteps: ["Processing..."]
            )
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.thinMaterial)
    .transition(.opacity)
    .zIndex(10)
}
*/

#Preview {
    VStack(spacing: 40) {
        MeepLoadingStateView.findingMeetingSpots()
            .frame(height: 300)
            .background(Color(.systemBackground))
        
        Divider()
        
        MeepLoadingStateView.loadingSubwayData()
            .frame(height: 300)
            .background(Color(.systemBackground))
    }
}
