//
//  OnboardingCardView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/23/25.
//


import SwiftUI

struct OnboardingCardView: View {
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let icon: AnyView?
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 16) {
                if let icon = icon {
                    icon
                        .padding(.bottom, 8)
                }
                
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .fontWidth(.expanded)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .textCase(.uppercase)
                    .lineSpacing(14)
                    .minimumScaleFactor(0.9)
                
                Text(subtitle)
                    .font(.title3)
                    .foregroundColor(Color(.white))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                
                Button(action: action) {
                    Text(actionTitle)
                        .font(.title3)
                        .foregroundColor(Color(.darkGray))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.white))
                        .cornerRadius(10)
                }
                .frame(height: 44)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .padding(24)
        }
    }
}
