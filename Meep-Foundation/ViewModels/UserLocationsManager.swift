//
//  UserLocationsManager.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/28/25.
//

import SwiftUI
import CoreLocation

// Define SavedLocation struct that matches what CustomLocationSheet expects
struct SavedLocation: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    
    init(id: String = UUID().uuidString, name: String, address: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SavedLocation, rhs: SavedLocation) -> Bool {
        return lhs.id == rhs.id
    }
}

class UserLocationsManager: ObservableObject {
    // Published properties to trigger UI updates when changed
    @Published var homeLocation: SavedLocation?
    @Published var workLocation: SavedLocation?
    @Published var customLocations: [SavedLocation] = []
    
    // UserDefaults keys
    private let homeKey = "user_home_location"
    private let workKey = "user_work_location"
    private let customLocationsKey = "user_custom_locations"
    
    // Singleton instance
    static let shared = UserLocationsManager()
    
    private init() {
        // Load saved locations when initialized
        loadSavedLocations()
    }
    
    // Load saved locations from UserDefaults
    private func loadSavedLocations() {
        if let homeData = UserDefaults.standard.data(forKey: homeKey),
           let savedHome = try? JSONDecoder().decode(SavedLocation.self, from: homeData) {
            self.homeLocation = savedHome
        }
        
        if let workData = UserDefaults.standard.data(forKey: workKey),
           let savedWork = try? JSONDecoder().decode(SavedLocation.self, from: workData) {
            self.workLocation = savedWork
        }
        
        if let customData = UserDefaults.standard.data(forKey: customLocationsKey),
           let savedCustomLocations = try? JSONDecoder().decode([SavedLocation].self, from: customData) {
            self.customLocations = savedCustomLocations
        }
    }
    
    // Save a location as home
    func saveHomeLocation(_ location: SavedLocation) {
        self.homeLocation = location
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(location) {
            UserDefaults.standard.set(encoded, forKey: homeKey)
        }
    }
    
    // Save a location as work
    func saveWorkLocation(_ location: SavedLocation) {
        self.workLocation = location
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(location) {
            UserDefaults.standard.set(encoded, forKey: workKey)
        }
    }
    
    // Add a custom location
    func addCustomLocation(_ location: SavedLocation) {
        customLocations.append(location)
        saveCustomLocations()
    }
    
    // Delete custom locations at the provided IndexSet
    func deleteCustomLocations(at indexSet: IndexSet) {
        customLocations.remove(atOffsets: indexSet)
        saveCustomLocations()
    }
    
    // Helper to save the custom locations array
    private func saveCustomLocations() {
        if let encoded = try? JSONEncoder().encode(customLocations) {
            UserDefaults.standard.set(encoded, forKey: customLocationsKey)
        }
    }
    
    // Save home location with address and coordinate
       func saveHomeLocation(address: String, coordinate: CLLocationCoordinate2D) {
           let homeLocation = SavedLocation(
               id: UUID().uuidString,
               name: "Home",
               address: address,
               latitude: coordinate.latitude,
               longitude: coordinate.longitude
           )
           self.homeLocation = homeLocation
           
           // Save to UserDefaults
           if let encoded = try? JSONEncoder().encode(homeLocation) {
               UserDefaults.standard.set(encoded, forKey: homeKey)
           }
       }
       
       // Save work location with address and coordinate
       func saveWorkLocation(address: String, coordinate: CLLocationCoordinate2D) {
           let workLocation = SavedLocation(
               id: UUID().uuidString,
               name: "Work",
               address: address,
               latitude: coordinate.latitude,
               longitude: coordinate.longitude
           )
           self.workLocation = workLocation
           
           // Save to UserDefaults
           if let encoded = try? JSONEncoder().encode(workLocation) {
               UserDefaults.standard.set(encoded, forKey: workKey)
           }
       }
}



extension SavedLocation {
    // Computed property to provide a CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: self.latitude,
            longitude: self.longitude
        )
    }
    
    // Helper method to validate coordinate
    func isValidCoordinate() -> Bool {
        let coordinate = self.coordinate
        return CLLocationCoordinate2DIsValid(coordinate) &&
               abs(coordinate.latitude) > 0.0001 &&
               abs(coordinate.longitude) > 0.0001
    }
}
