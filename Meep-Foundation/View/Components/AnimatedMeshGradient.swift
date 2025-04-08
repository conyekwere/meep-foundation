//
//  AnimatedMeshGradient.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/7/25.
//

import SwiftUI

struct AnimatedMeshGradient: View {
    @State var appear = false
    @State var appear2 = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [appear2 ? 0.5 : 1.0, 0.0], [1.0, 0.0],
                [0.0, 0.5], appear ? [0.1, 0.5] : [0.8, 0.2], [1.0, -0.5],
                [0.0, 1.0], [1.0, appear2 ? 2.0 : 1.0], [1.0, 1.0]
            ],
            colors: [
                appear2 ? Color.green.opacity(0.8) : Color.mint.opacity(0.7),
                appear2 ? Color.teal.opacity(0.7) : Color.green.opacity(0.6),
                Color.green.opacity(0.4),
                
                appear ? Color.blue.opacity(0.6) : Color.green.opacity(0.5),
                appear ? Color.mint.opacity(0.5) : Color.cyan.opacity(0.4),
                appear ? Color.teal.opacity(0.5) : Color.green.opacity(0.3),
                
                appear ? Color.green.opacity(0.4) : Color.blue.opacity(0.3),
                appear ? Color.mint.opacity(0.5) : Color.teal.opacity(0.5),
                appear2 ? Color.teal.opacity(0.6) : Color.blue.opacity(0.5)
            ]
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                appear.toggle()
            }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                appear2.toggle()
            }
        }
    }
}

#Preview {
    AnimatedMeshGradient()
}
