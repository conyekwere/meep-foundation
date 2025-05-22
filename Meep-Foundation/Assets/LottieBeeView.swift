//
//  LottieBeeView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 5/11/25.
//


import SwiftUI
import Lottie

struct LottieBeeView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView(name: "bee") // Make sure "bee.json" is in your project

        animationView.loopMode = .loop
        animationView.play()
        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
