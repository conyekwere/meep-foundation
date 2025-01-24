//
//  VisualEffectBlur.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/23/25.
//


import SwiftUI
import UIKit

// Custom VisualEffectBlur using UIKit's UIVisualEffectView
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}
