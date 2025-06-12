//
//  TransitFallbackToastView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/11/25.
//

import SwiftUI

struct TransitFallbackToastView: View {
    let toast: TransitFallbackToast
    let isVisible: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        if isVisible {
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    // Icon with colored background
                    ZStack {
                        Circle()
                            .fill(toast.primaryColor.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: toast.icon)
                            .foregroundColor(toast.primaryColor)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(toast.title)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .font(.callout)
                        
                        Text(toast.message)
                            .foregroundColor(.white.opacity(0.85))
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // Optional dismiss button
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.9),
                                    Color.black.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(toast.primaryColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
            .zIndex(10)
            .onTapGesture {
                onDismiss()
            }
        }
    }
}
