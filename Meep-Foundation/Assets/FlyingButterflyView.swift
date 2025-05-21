//
//  FlyingButterflyView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 5/11/25.
//

import SwiftUI

struct FlyingButterflyView: View {
    @State private var yOffset: CGFloat = 860
    @State private var xOffset: CGFloat = 60
    @State private var isFlying: Bool = false

    var body: some View {
        LottieButterflyView()
            .frame(width: 68, height: 68)
            .offset(x: xOffset, y: yOffset)
            .opacity(isFlying ? 1 : 0)
            .rotationEffect(.degrees(isFlying ? -20 : 0))
            .onAppear {
                startFlightLoop()
            }
            .allowsHitTesting(false)
    }

    private func startFlightLoop() {
        // Animate up with random x drift
        withAnimation(.easeInOut(duration: 16)) {
            yOffset = -800
            xOffset = CGFloat.random(in: -30...30)
            isFlying = true
        }

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            isFlying = false
            yOffset = 300
            xOffset = 120

            // Restart after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startFlightLoop()
            }
        }
    }
}

#Preview {
    FlyingButterflyView()
}
