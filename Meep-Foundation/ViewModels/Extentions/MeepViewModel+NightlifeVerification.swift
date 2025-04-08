//
//  MeepViewModel+NightlifeVerification.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/26/25.
//



import SwiftUI
import MapKit
import CoreLocation
import GooglePlaces

// MARK: - 🌃 Nightlife Verification
extension MeepViewModel {
    
    // Verify if a place is truly "Nightlife" based on our criteria
    func verifyNightlifeCategory(placemark: MKPlacemark, placeDetails: GMSPlace?) -> Bool {
        // Log the detected region for debugging
        let isNewYork = isInNewYork(placemark: placemark)
        let isNewOrleans = isInNewOrleans(placemark: placemark)
        let isLasVegas = isInLasVegas(placemark: placemark)
        let isMiami = isInMiami(placemark: placemark)
        
        var regionName = "Standard (2AM rule)"
        if isNewYork { regionName = "New York (3AM rule)" }
        if isNewOrleans { regionName = "New Orleans (special case)" }
        if isLasVegas { regionName = "Las Vegas (special case)" }
        if isMiami { regionName = "Miami (special case)" }
        
        print("🌎 Nightlife verification for region: \(regionName)")
        
        // For special locations, we'll be more lenient
        if isNewOrleans || isLasVegas || isMiami {
            return true
        }
        
        // Look for keywords in place types that indicate nightlife
        if let placeDetails = placeDetails, let types = placeDetails.types {
            let nightlifeKeywords = ["night_club", "bar", "pub", "nightlife"]
            
            // Look for opening hours clues if available
            if let openingHours = placeDetails.openingHours {
                // Print the full openingHours object for debugging
                print("📅 Opening hours: \(openingHours)")
                
                // Check if the place has late hours in the week
                let weekdayText = openingHours.weekdayText ?? []
                for text in weekdayText {
                    // Look for late hours indicators in the weekday text
                    if text.lowercased().contains("am") &&
                       (text.contains("2:") || text.contains("3:") || text.contains("4:")) {
                        return true
                    }
                }
            }
            
            // If we're in NY, we need to ensure it's open late enough
            if isNewYork {
                // Unless we have specific late-hour terms in the name or types
                let lateNightKeywords = ["lounge", "club", "dance", "disco"]
                
                for type in types {
                    if lateNightKeywords.contains(where: { type.lowercased().contains($0) }) {
                        return true
                    }
                }
                
                if let name = placeDetails.name,
                   lateNightKeywords.contains(where: { name.lowercased().contains($0) }) {
                    return true
                }
                
                // For NY, be more cautious without clear hours data
                return false
            }
            
            // For other places, check if it has nightlife in its types
            for type in types {
                if nightlifeKeywords.contains(where: { type.lowercased().contains($0) }) {
                    return true
                }
            }
        }
        
        // If we couldn't verify clearly, default to false
        return false
    }
    
    // Helper to determine if a place is in New York
    private func isInNewYork(placemark: MKPlacemark) -> Bool {
        if let administrativeArea = placemark.administrativeArea,
           administrativeArea == "NY" || administrativeArea == "New York" {
            return true
        }
        
        if let locality = placemark.locality,
           locality.lowercased().contains("new york") || locality == "NYC" {
            return true
        }
        
        // Additional check for coordinates
        let coordinate = placemark.coordinate
        let nyBounds = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        
        let isInNYBounds = nyBounds.contains(coordinate)
        return isInNYBounds
    }
    
    // Helper to determine if a place is in New Orleans
    private func isInNewOrleans(placemark: MKPlacemark) -> Bool {
        if let administrativeArea = placemark.administrativeArea,
           administrativeArea == "LA" || administrativeArea == "Louisiana" {
            if let locality = placemark.locality,
               locality.lowercased().contains("new orleans") || locality == "NOLA" {
                return true
            }
        }
        
        // Additional check for coordinates
        let coordinate = placemark.coordinate
        let nolaBounds = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 29.9511, longitude: -90.0715),
            span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )
        
        let isInNOLABounds = nolaBounds.contains(coordinate)
        return isInNOLABounds
    }
    
    // Helper to determine if a place is in Las Vegas
    private func isInLasVegas(placemark: MKPlacemark) -> Bool {
        if let administrativeArea = placemark.administrativeArea,
           administrativeArea == "NV" || administrativeArea == "Nevada" {
            if let locality = placemark.locality,
               locality.lowercased().contains("las vegas") {
                return true
            }
        }
        
        // Additional check for coordinates
        let coordinate = placemark.coordinate
        let vegasBounds = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.1699, longitude: -115.1398),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        
        let isInVegasBounds = vegasBounds.contains(coordinate)
        return isInVegasBounds
    }
    
    // Helper to determine if a place is in Miami
    private func isInMiami(placemark: MKPlacemark) -> Bool {
        // Check by administrative area and locality
        if let administrativeArea = placemark.administrativeArea,
           administrativeArea == "FL" || administrativeArea == "Florida" {
            if let locality = placemark.locality,
               locality.lowercased().contains("miami") {
                return true
            }
        }
        
        // Check for Miami Beach specifically
        if let locality = placemark.locality,
           locality.lowercased().contains("miami beach") {
            return true
        }
        
        // Additional check for coordinates (covering Miami and Miami Beach)
        let coordinate = placemark.coordinate
        let miamiBounds = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.7617, longitude: -80.1918),
            span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
        )
        
        let isInMiamiBounds = miamiBounds.contains(coordinate)
        return isInMiamiBounds
    }
    
    // Helper to recategorize a place based on Google Place types
    func recategorizePlace(index: Int, placeTypes: [String]) {
        // If it's not nightlife, recategorize based on place types
        if placeTypes.contains("bar") {
            meetingPoints[index].category = "Bar"
            meetingPoints[index].emoji = "🍺"
            print("🔄 Reclassified to Bar: \(meetingPoints[index].name)")
        } else if placeTypes.contains("restaurant") {
            meetingPoints[index].category = "Restaurant"
            meetingPoints[index].emoji = "🍴"
            print("🔄 Reclassified to Restaurant: \(meetingPoints[index].name)")
        } else if placeTypes.contains("cafe") {
            meetingPoints[index].category = "Coffee shop"
            meetingPoints[index].emoji = "☕"
            print("🔄 Reclassified to Coffee shop: \(meetingPoints[index].name)")
        } else if placeTypes.contains("bakery") {
            meetingPoints[index].category = "Bakery"
            meetingPoints[index].emoji = "🍞"
            print("🔄 Reclassified to Bakery: \(meetingPoints[index].name)")
        } else {
            // Default fallback - keep original category but log it
            print("⚠️ Unable to reclassify: \(meetingPoints[index].name) with types: \(placeTypes.joined(separator: ", "))")
        }
    }
}

