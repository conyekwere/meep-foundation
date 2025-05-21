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
    case main(isNewUser: Bool)
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
        if let user = Auth.auth().currentUser {
            // User is already logged in
            showMainApp(isNewUser: user.metadata.creationDate == user.metadata.lastSignInDate)
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
    func showMainApp(isNewUser: Bool) {
        guard firebaseService.meepUser != nil else {
            showLanding()
            return
        }
        withAnimation {
            currentState = .main(isNewUser: isNewUser)
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
            case .main(let isNewUser):
                MeepAppView(isNewUser: isNewUser)
                    .environmentObject(coordinator)
            }
        }
        .onOpenURL { url in
            // Handle deep links here if needed
            print("Received deep link: \(url)")
        }
    }
}

struct AppCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AppCoordinatorView()
                .environment(\.colorScheme, .dark)
            
            AppCoordinatorView()
                .environment(\.colorScheme, .light)
        }
    }
}
