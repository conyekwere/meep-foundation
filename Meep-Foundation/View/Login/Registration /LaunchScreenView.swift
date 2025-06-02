//
//  LaunchScreenView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/2/25.
//



import SwiftUI

struct LaunchScreenView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: 8) {
                Image("meep-mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .scaleEffect(animate ? 1.0 : 0.8)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8), value: animate)

                Text("Meep")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 1.0).delay(0.2), value: animate)

            }
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    LaunchScreenView()
}
