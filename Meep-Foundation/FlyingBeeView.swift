import SwiftUI
import Lottie

struct FlyingBeeView: View {
    @State private var yOffset: CGFloat = 400
    @State private var xOffset: CGFloat = -100
    @State private var isFlying: Bool = false

    var body: some View {
        DotLottieAnimation(
            webURL: "https://lottie.host/52039a64-669d-4f19-8fb1-5d039e6f1939/ErcuQsDX9U.lottie"
        )
        .playbackMode(.loop)
        .frame(width: 80, height: 80)
        .offset(x: xOffset, y: yOffset)
        .opacity(isFlying ? 1 : 0)
        .onAppear {
            startFlightLoop()
        }
        .allowsHitTesting(false)
    }

    private func startFlightLoop() {
        withAnimation(.easeInOut(duration: 10)) {
            yOffset = -600
            xOffset = CGFloat.random(in: -60...60)
            isFlying = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            isFlying = false
            yOffset = 400
            xOffset = -100
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startFlightLoop()
            }
        }
    }
}