//
//  Meep_FoundationApp.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 1/21/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleMaps
import GooglePlaces

@main
struct MeepApp: App {
    // Register app delegate for Firebase setup
    @StateObject private var onboardingManager = OnboardingManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environmentObject(OnboardingManager.shared)
                .onAppear {
                    OnboardingManager.shared.incrementAppLaunch()
                }
            
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Maps API
        if let mapsAPIKey = Bundle.main.object(forInfoDictionaryKey: "GMS_MAPS_API_KEY") as? String,
           !mapsAPIKey.isEmpty {
            GMSServices.provideAPIKey(mapsAPIKey)
            print("✅ Google Maps API Key Loaded")
        } else {
            fatalError("❌ Google Maps API Key is missing or invalid")
        }

        // Configure Google Places API
        if let placesAPIKey = Bundle.main.object(forInfoDictionaryKey: "GMS_PLACES_API_KEY") as? String,
           !placesAPIKey.isEmpty {
            GMSPlacesClient.provideAPIKey(placesAPIKey)
            print("✅ Google Places API Key Loaded")
        } else {
            fatalError("❌ Google Places API Key is missing or invalid")
        }

        configureAppAppearance()
        return true
    }
    
    private func configureAppAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}
