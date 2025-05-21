//
//  SkeletonMeetingPointCard.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/4/25.
//


import SwiftUI

struct SkeletonMeetingPointCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Fake image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .shimmer() // Adds a shimmer effect

            // Fake name placeholder
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 180, height: 20)
                .shimmer()

            HStack {
                // Fake category placeholder
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 16)
                    .shimmer()

                Spacer()

                // Fake distance placeholder
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 16)
                    .shimmer()
            }

            // Fake button placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 48)
                .shimmer()
        }
        .padding(24)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.9)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
    }
}

// Adds shimmer effect for skeleton loading
extension View {
    func shimmer() -> some View {
        self.overlay(
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1), Color.gray.opacity(0.3)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .blendMode(.overlay)
            .mask(self)
        )
    }
}
