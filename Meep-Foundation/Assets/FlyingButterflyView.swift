import SwiftUI
import Lottie

struct FlyingButterflyView: View {
    @State private var yOffset: CGFloat = 300
    @State private var xOffset: CGFloat = 120
    @State private var isFlying: Bool = false

    var body: some View {
        DotLottieAnimation(
            webURL: "https://lottie.host/d6297a51-239e-4e43-97a2-94235c9ca92b/emkxr03yQu.lottie"
        )
        .playbackMode(.loop)
        .frame(width: 100, height: 100)
        .offset(x: xOffset, y: yOffset)
        .opacity(isFlying ? 1 : 0)
        .onAppear {
            startFlightLoop()
        }
        .allowsHitTesting(false)
    }

    private func startFlightLoop() {
        withAnimation(.easeInOut(duration: 8)) {
            yOffset = -600
            xOffset = CGFloat.random(in: -30...30)
            isFlying = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            isFlying = false
            yOffset = 300
            xOffset = 120
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startFlightLoop()
            }
        }
    }
}