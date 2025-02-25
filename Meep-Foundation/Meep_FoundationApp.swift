//
//  Meep_FoundationApp.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 1/21/25.
//

import SwiftUI
import GooglePlaces
import GoogleMaps

@main
struct Meep_FoundationApp: App {
    
    init() {
        print("✅ Initializing Google Places and Google Maps")
        GMSPlacesClient.provideAPIKey("YOUR_GOOGLE_PLACES_API_KEY")
        GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
