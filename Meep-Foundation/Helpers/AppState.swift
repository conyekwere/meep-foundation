//
//  AppState.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.
//


import SwiftUI
import FirebaseAuth

/// App state to track which view is currently presented
enum AppState {
    case landing
    case main
}

/// Coordinator for handling app-wide navigation and state
class AppCoordinator: ObservableObject {
    /// Current app state determining which view to show
    @Published var currentState: AppState = .landing
    
    /// Firebase service for authentication
    private let firebaseService = FirebaseService.shared
    
    init() {
        // Check if user is already authenticated at startup
        checkAuthState()
    }
    
    /// Check if user is already logged in and update app state accordingly
    func checkAuthState() {
        if Auth.auth().currentUser != nil {
            // User is already logged in
            showMainApp()
        } else {
            // No user session, show landing page
            showLanding()
        }
    }
    
    /// Show the landing page
    func showLanding() {
        withAnimation {
            currentState = .landing
        }
    }
    
    /// Show the main app
    func showMainApp() {
        withAnimation {
            currentState = .main
        }
    }
    
    /// Handle sign out and return to landing page
    func signOut() {
        let success = firebaseService.signOut { success, _ in
            if success {
                self.showLanding()
            }
        }
    }
}

/// Root view that uses the coordinator to determine which view to show
struct AppCoordinatorView: View {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some View {
        Group {
            switch coordinator.currentState {
            case .landing:
                LandingView()
                    .environmentObject(coordinator)
            case .main:
                MeepAppView()
                    .environmentObject(coordinator)
            }
        }
        .onOpenURL { url in
            // Handle deep links here if needed
            print("Received deep link: \(url)")
        }
    }
}
