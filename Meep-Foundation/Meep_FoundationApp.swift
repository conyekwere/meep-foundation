//
//  Meep_FoundationApp.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 1/21/25.
//

import SwiftUI
import GoogleMaps
import GooglePlaces

@main
struct MeepApp: App {
    @StateObject private var onboardingManager = OnboardingManager.shared
    init() {
        if let mapsAPIKey = Bundle.main.object(forInfoDictionaryKey: "GMS_MAPS_API_KEY") as? String,
           !mapsAPIKey.isEmpty {
            GMSServices.provideAPIKey(mapsAPIKey)
            print("✅ Google Maps API Key Loaded")
        } else {
            fatalError("❌ Google Maps API Key is missing or invalid")
        }

        if let placesAPIKey = Bundle.main.object(forInfoDictionaryKey: "GMS_PLACES_API_KEY") as? String,
           !placesAPIKey.isEmpty {
            GMSPlacesClient.provideAPIKey(placesAPIKey)
            print("✅ Google Places API Key Loaded")
        } else {
            fatalError("❌ Google Places API Key is missing or invalid")
        }
    }

    var body: some Scene {
        WindowGroup {
            MeepAppView()
                .environmentObject(onboardingManager)
                .onAppear {
                    OnboardingManager.shared.incrementAppLaunch()
                }
        }

    }
}
