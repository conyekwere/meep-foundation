//
//  LandingView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.
//

import SwiftUI
import FirebaseAuth
import PostHog

struct LandingView: View {
    // State
    @State private var showLoginView = false
    @State private var showCreateAccountView = false
    @State private var createAccount: Bool = false
    @State private var videoLoaded: Bool = false
    @State private var didCheckAuth = false
    
    // Environment
    @Environment(\.colorScheme) var colorScheme
    
    // Firebase service
    @StateObject private var firebaseService = FirebaseService.shared
    
    // App coordinator to handle navigation
    @EnvironmentObject private var coordinator: AppCoordinator
    @AppStorage("firstLaunchTimestamp") private var firstLaunchTimestamp: Double = 0
    
    var body: some View {
        ZStack {

            // Background image with overlay
            LandingVideoBackgroundView {
                videoLoaded = true
            }
            .ignoresSafeArea()
            .overlay(            LinearGradient(
                gradient: Gradient(colors: [
                    Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)),
                    Color(#colorLiteral(red: 0.1157327518, green: 0.2090111971, blue: 0.1976979971, alpha: 1)),
                    Color(#colorLiteral(red: 0.05121128261, green: 0.09113004059, blue: 0.08617139608, alpha: 1)),
                    Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
                ]),
                startPoint: .top,
                endPoint: .bottom
            ).opacity(0.93))// optional dimming overlay
            
            if !videoLoaded {
                AnimatedMeshGradient()
                .edgesIgnoringSafeArea(.all)
                .overlay(            LinearGradient(
                    gradient: Gradient(colors: [
                        Color(#colorLiteral(red: 0.1019607843, green: 0.1254901961, blue: 0.1882352941, alpha: 1.0)),
                        Color(#colorLiteral(red: 0.0470588244497776, green: 0.09803921729326248, blue: 0.26274511218070984, alpha: 1.0))
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ).opacity(0.80))
                
            }
            
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
          
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    TermsAndPrivacyText()
                        .padding(.horizontal, 24)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .tint(.blue)
                        .environment(\.openURL, OpenURLAction { url in
                            UIApplication.shared.open(url)
                            return .handled
                        })
                    
                    
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
                        coordinator.showMainApp(isNewUser: false)
                    }
                }, createAccount: $createAccount, viewModel: MeepViewModel())
                .transition(.move(edge: .bottom))
                .zIndex(5)
            }

            if showCreateAccountView {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    .zIndex(4)

                LoginView(onDismiss: { success in
                    showCreateAccountView = false
                    if success {
                        coordinator.showMainApp(isNewUser: true)
                    }
                }, createAccount: $createAccount, viewModel: MeepViewModel())
                .transition(.move(edge: .bottom))
                .zIndex(5)
            }
        }
        .onAppear {
            if firstLaunchTimestamp == 0 {
                firstLaunchTimestamp = Date().timeIntervalSince1970
                PostHogSDK.shared.capture("app_first_open", properties: [
                    "timestamp": firstLaunchTimestamp
                ])
            }
        }
}
}


