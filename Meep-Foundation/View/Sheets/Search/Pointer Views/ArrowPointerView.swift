//
//  ArrowPointerView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 5/22/25.
//

import SwiftUI

struct ArrowPointerView: View {
    @State private var arrowOffsetY: CGFloat = 0
    @State private var showArrow: Bool = false
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay to darken the screen
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Bouncing arrow pointing upward
            VStack {
   
                
                Image(systemName: "chevron.up")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.top, UIScreen.main.bounds.height * 0.4) // 30% of screen height instead of fixed 240
                    .padding(.leading, UIScreen.main.bounds.width * 0.35) // 35% of screen width instead of fixed 140

                    .fontWeight(.bold)
                    .shadow(color: .black.opacity(0.80), radius: 1, x: 0, y: 1)
                    .textCase(.uppercase)
                    .shadow(color: Color(UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)), radius: 4, x: 0, y: 4)
                    .offset(y: arrowOffsetY)
                    .opacity(showArrow ? 1 : 0) // Control visibility with a state variable
                    .onAppear {
                        // Delay the appearance to match contact permissions modal
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1 second delay
                            withAnimation(.easeIn(duration: 0.5)) {
                                showArrow = true // Fade in the arrow
                            }
                            
                            // Start the bouncing animation after it appears
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
}
