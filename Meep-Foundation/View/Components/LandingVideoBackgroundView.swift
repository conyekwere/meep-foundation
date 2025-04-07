//
//  LandingVideoBackgroundView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/5/25.
//


import SwiftUI
import AVKit

struct LandingVideoBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        guard let url = Bundle.main.url(forResource: "Hyperlapse", withExtension: "mp4") else {
            fatalError("Video not found")
        }

        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .none
        player.play()

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(playerLayer)

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
