//
//  LandingView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.
//

import SwiftUI
import FirebaseAuth

struct LandingView: View {
    // State
    @State private var showLoginView = false
    @State private var showCreateAccountView = false
    
    // Environment
    @Environment(\.colorScheme) var colorScheme
    
    // Firebase service
    @StateObject private var firebaseService = FirebaseService.shared
    
    // App coordinator to handle navigation
    @EnvironmentObject private var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {

            // Background image with overlay
            LandingVideoBackgroundView()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.80)) // optional dimming overlay
            
            // Main content
            VStack(spacing: 30) {
                Spacer()
                
                // Logo and tagline
                VStack(spacing: 10) {
                    Text("Meep")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .lineSpacing(16)
                    
                    Text("Find the ideal meeting point")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                // Mascot image
                Image("meep-mascot")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    // Create account button
                    Button(action: {
                        showCreateAccountView = true
                    }) {
                        Text("Create account")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.white)
                            .cornerRadius(40)
                    }
                    .padding(.horizontal, 20)
                    
                    // Sign in button
                    Button(action: {
                        showLoginView = true
                    }) {
                        Text("Sign In")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.black)
                            .cornerRadius(40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(Color.gray, lineWidth: 0.1)
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Terms and conditions
                    ZStack {
                        Text("By tapping 'Sign in' / 'Create account' you agree to our ")
                            .font(.footnote) +
                        Text("Terms")
                            .font(.footnote)
                            .fontWeight(.bold) +
                        Text(" and ")
                            .font(.footnote) +
                        Text("Privacy Policy")
                            .font(.footnote)
                            .fontWeight(.bold)
                    } .padding(.horizontal, 20)
                    
                    
                }
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)
            }
            
            if showLoginView {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    .zIndex(4)

                LoginView(onDismiss: { success in
                    showLoginView = false
                    if success {
                        coordinator.showMainApp()
                    }
                })
                .transition(.move(edge: .bottom))
                .zIndex(5)
            }

            if showCreateAccountView {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    .zIndex(4)

                LoginView(onDismiss: { success in
                    showCreateAccountView = false
                    if success {
                        coordinator.showMainApp()
                    }
                }, createAccount: true)
                .transition(.move(edge: .bottom))
                .zIndex(5)
            }
        }
        .onAppear {
            // Check if user is already logged in
            if Auth.auth().currentUser != nil {
                coordinator.showMainApp()
            }
        }
    }
}

#Preview {
    LandingView()
        .environmentObject(AppCoordinator())
}
