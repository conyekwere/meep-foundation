//
//  OnboardingManager.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/22/25.
//


import SwiftUI


class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @AppStorage("appLaunchCount") private var appLaunchCount: Int = 0
    
    private init() {
        // Private initializer for singleton
    }

    /// Whether this is the first app launch.
    var isNewUser: Bool {
        return appLaunchCount == 1
    }

    /// Total number of times the app has been launched.
    var launchCount: Int {
        return appLaunchCount
    }
    
    func incrementAppLaunch() {
        appLaunchCount += 1
    }
    
    func shouldShowOnboardingElement(maxShows: Int = 4) -> Bool {
        return appLaunchCount <= maxShows
    }
    
    func resetOnboarding() {
        appLaunchCount = 0
    }
}
