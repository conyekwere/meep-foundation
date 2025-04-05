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
            Image("city-aerial")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(0.6))
                )
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 30) {
                Spacer()
                
                // Logo and tagline
                VStack(spacing: 10) {
                    Text("Meep")
                        .font(.custom("Futura-Bold", size: 80))
                        .fontWeight(.heavy)
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                    
                    Text("Find the ideal meeting point")
                        .font(.title3)
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
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Terms and conditions
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
                }
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Check if user is already logged in
            if Auth.auth().currentUser != nil {
                coordinator.showMainApp()
            }
        }
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView(onDismiss: { success in
                if success {
                    // User successfully logged in, navigate to main app
                    coordinator.showMainApp()
                }
            })
        }
        .fullScreenCover(isPresented: $showCreateAccountView) {
            // Use the same login view but with createAccount = true
            LoginView(onDismiss: { success in
                if success {
                    // User successfully created account, navigate to main app
                    coordinator.showMainApp()
                }
            }, createAccount: true)
        }
    }
}

#Preview {
    LandingView()
        .environmentObject(AppCoordinator())
}
