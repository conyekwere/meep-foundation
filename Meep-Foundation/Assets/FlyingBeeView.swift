//
//  FlyingBeeView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 5/11/25.
//

import SwiftUI

struct FlyingBeeView: View {
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var isFlying: Bool = false

    var body: some View {
        LottieBeeView()
            .frame(width: 150, height: 150)
            .offset(x: xOffset, y: yOffset)
            .opacity(isFlying ? 1 : 0)
            .rotationEffect(.degrees(isFlying ? 30 : 0))
            .onAppear {
                startFlightLoop()
            }
            .allowsHitTesting(false)
    }

    private func startFlightLoop() {
        // Animate upward with gentle x drift
        withAnimation(.easeInOut(duration: 16)) {
            yOffset =  -100
            xOffset = 200
            isFlying = true
        }

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 16) {
            isFlying = false
            yOffset = -10
            xOffset = 20

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startFlightLoop()
            }
        }
    }
}


#Preview {
    FlyingBeeView()
}
