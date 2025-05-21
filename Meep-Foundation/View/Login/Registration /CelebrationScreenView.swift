//
//  CelebrationScreenView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/16/25.
//

import SwiftUI

struct CelebrationScreenView: View {
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer(minLength: 80)

                Text("Welcome to Meep")
                    .font(.title)
                    .fontWeight(.semibold)
                    .fontWidth(.expanded)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .lineSpacing(16)
                    .padding(.bottom, 32)
                    .zIndex(2)
                Spacer()
                Image("meep-mascot")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .padding(.bottom, 60)
                    .zIndex(3)
                Spacer()

                Button(action: onComplete) {
                    Text("Get Started")
                        .font(.headline)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 18)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(40)
                        .padding(.horizontal)
                        .offset(y:40)
                     
                } .zIndex(1)

                Image("grass-bottom")
                    .resizable()
                    .scaledToFit()
                    .frame(width: .infinity)
                    .offset(y:30)
                    .zIndex(0)
                    
            }

            // Animated creatures
            
            FlyingButterflyView()
                .zIndex(0)
            FlyingBeeView()
                .zIndex(0)
        }
    }
}


#Preview {
    CelebrationScreenView(onComplete: {})
}
