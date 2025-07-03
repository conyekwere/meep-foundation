
//
//  LocationPrivacyDisclosureView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/16/25.
//

import SwiftUI

struct LocationPrivacyDisclosureView: View {
    @Binding var showDisclosure: Bool
    var onAllow: () -> Void

    var body: some View {
        ZStack {

            // System-style modal dialog
            VStack(spacing: 0) {
                // Main content area
                VStack(spacing: 16) {
                    // Title
                    Text("Allow \"Meep\" to use your location?")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    
                    // Description
                    Text("Your location is used to find meeting points between you and your friends.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        .lineSpacing(2.0)
                }
                
                // Divider
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
                
                // Button area
                HStack(spacing: 0) {
                    // Don't Allow button
                    Button("Don't Allow") {
                        showDisclosure = false
                    }
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    
                    
                    // Vertical divider
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 0.5)
                    
                    // Allow button
                    Button("Continue") {
                        onAllow()
                        showDisclosure = false
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    
                }.frame(height:44)
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
            .frame(width: 270,height: 300) // Standard iOS alert width

            .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 4)
        }
    }
}
