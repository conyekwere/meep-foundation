//
//  OnboardingSheetView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import SwiftUI

struct OnboardingSheetView: View {
    @ObservedObject var viewModel: MeepViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var isLocationAllowed: Bool
    @Binding var searchRequest: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Drag Handle
                Capsule()
                    .frame(width: 40, height: 5)
                    .foregroundColor(Color(.lightGray).opacity(0.4))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // First Card: Allow Location
                        if viewModel.userLocation == nil {
                            OnboardingCardView(
                                title: "Enable location",
                                subtitle: "You‘ll need to enable your location in order to use Meep",
                                gradientColors: [Color(hex: "67DB92"), Color(hex: "41AC99")],
                                icon: AnyView(
                                    ZStack {
                                        Circle()
                                            .fill(Color(#colorLiteral(red: 0.3455161154270172, green: 0.5001650452613831, blue: 0.9254494905471802, alpha: 1)))
                                            .strokeBorder(Color.white, lineWidth: 1)
                                            .frame(width: 16, height: 16)
                                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                                        
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 1)
                                            .frame(width: 60, height: 60)
                                        
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 1)
                                            .frame(width: 108, height: 108)
                                    }
                                ),
                                actionTitle: "Allow Location",
                                action: {
                                    viewModel.requestUserLocation()
                                }
                            )
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                            .frame(height: 360)
                        }
                    

                        // Second Card: Meet Your Friends
                        OnboardingCardView(
                            title: "Meet Your Friends Halfway",
                            subtitle: "Search the Perfect Meeting Point",
                            gradientColors: [Color(hex: "145492"), Color(hex: "3D9FF5")],
                            icon: AnyView(
                                ZStack {
                                    Image(systemName: "mappin.circle")
                                        .resizable()
                                        .frame(width: 34, height: 34)
                                        .foregroundStyle(Color.white)
                                    
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 3, dash: [4, 4]))
                                        .frame(width: 74, height: 74)
                                    
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                                        .frame(width: 108, height: 108)
                                }
                            ),
                            actionTitle: "Search",
                            action: {
                                searchRequest = true
                            }
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        .frame(height: 390)
                        .padding(.bottom, 64)
                  
                        Spacer(minLength: 16)
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .padding(.top, 8)
           

        }
    }
}

#Preview {
    OnboardingSheetView(viewModel: MeepViewModel(), isLocationAllowed: .constant(false), searchRequest: .constant(false))
        .previewLayout(.sizeThatFits)
        .background(Color.gray.opacity(0.2))
        .ignoresSafeArea(edges: .bottom)
}
