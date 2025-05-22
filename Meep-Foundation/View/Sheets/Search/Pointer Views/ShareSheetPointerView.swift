//
//  ShareSheetPointerView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 5/22/25.
//

import SwiftUI

struct ShareSheetPointerView: View {
    @State private var arrowOffsetY: CGFloat = 0
    @State private var showArrow: Bool = false
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay to darken the screen
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Position arrow at the bottom pointing upward to the share sheet
            VStack(spacing:32)
            {
                // Add explanatory text above the arrow
                Text("Tap a contact to share your meeting request.")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    .blendMode(.hardLight)
                
                Image(systemName: "chevron.down")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .shadow(color: .black.opacity(1), radius: 1, x: 0, y: 1)
                    .offset(y: arrowOffsetY)
                    .opacity(showArrow ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, UIScreen.main.bounds.height * 0.60)
            .onAppear {
                // Fade in the arrow with a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        showArrow = true
                    }
                    
                    // Start the bouncing animation
                    withAnimation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                    ) {
                        arrowOffsetY = -15
                    }
                }
            }
        }
    }
}

