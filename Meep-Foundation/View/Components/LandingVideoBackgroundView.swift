//
//  LandingVideoBackgroundView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/5/25.
//

import SwiftUI
import AVKit

struct LandingVideoBackgroundView: UIViewRepresentable {
    var onVideoReady: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        guard let url = URL(string: "https://pub-8501576ea78f4acdb159139fa5a38b30.r2.dev/Hyperlapse.mp4") else {
            onVideoReady() // fallback
            return view
        }

        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .none
        player.play()

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(playerLayer)

        NotificationCenter.default.addObserver(forName: .AVPlayerItemNewAccessLogEntry, object: player.currentItem, queue: .main) { _ in
            onVideoReady()
        }

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    LandingView()
        .environmentObject(AppCoordinator())
}
