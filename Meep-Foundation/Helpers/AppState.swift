//
//  AppState.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.
//
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
    case launching
    case landing
    case main(isNewUser: Bool)
}

/// Coordinator for handling app-wide navigation and state
class AppCoordinator: ObservableObject {
    static let shared = AppCoordinator()
    /// Current app state determining which view to show
    @Published var currentState: AppState = .launching

    /// Firebase service for authentication
    private let firebaseService = FirebaseService.shared

    init() {
        checkAuthState()
    }

    /// Check if user is already logged in and update app state accordingly
    func checkAuthState() {
        if let user = Auth.auth().currentUser {
            firebaseService.loadUser(uid: user.uid) { [weak self] success in
                DispatchQueue.main.async {
                    if success {
                        self?.showMainApp(isNewUser: user.metadata.creationDate == user.metadata.lastSignInDate)
                    } else {
                        self?.showLanding()
                    }
                }
            }
        } else {
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
            case .launching:
                LaunchScreenView()
            case .landing:
                LandingView()
                    .environmentObject(coordinator)
            case .main(let isNewUser):
                MeepAppView(isNewUser: isNewUser)
                    .environmentObject(coordinator)
            }
        }
        .onAppear {
            coordinator.checkAuthState()
        }
        .onOpenURL { url in
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
