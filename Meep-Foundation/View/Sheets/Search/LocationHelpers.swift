//
//  LocationHelpers.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/6/25.
//
import SwiftUI
import MapKit
import CoreLocation

// A separate utility class for location helper functions
// This avoids access issues with private properties in MeetingSearchSheetView
class LocationHelpers {
    
    // MARK: - Address Validation
    
    /// Checks if a string represents coordinate values
    static func isLikelyCoordinates(_ text: String) -> Bool {
        // Simple check for comma-separated numbers
        let components = text.components(separatedBy: ",")
        guard components.count == 2 else { return false }
        
        let trimmedComponents = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Check if both parts are numeric
        return Double(trimmedComponents[0]) != nil && Double(trimmedComponents[1]) != nil
    }
    
    /// Formats coordinates as a readable string
    static func formatCoordinates(_ coordinates: CLLocationCoordinate2D) -> String {
        let latitude = String(format: "%.5f", coordinates.latitude)
        let longitude = String(format: "%.5f", coordinates.longitude)
        return "\(latitude), \(longitude)"
    }
    
    /// Generic function to validate if an address string is valid
    static func validateAddress(_ address: String,
                               completer: LocalSearchCompleterDelegate,
                               savedLocations: [SavedLocation],
                               existingCoordinate: CLLocationCoordinate2D?) -> Bool {
        // Empty addresses are not valid
        if address.isEmpty {
            return false
        }
        
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if this might be coordinates
        if isLikelyCoordinates(trimmed) {
            return true
        }
        
        // Check if it matches any saved location
        for location in savedLocations {
            if location.address.lowercased() == trimmed.lowercased() {
                return true
            }
        }
        
        // Check against autocomplete suggestions - perfect match
        let perfectMatch = completer.completions.contains { suggestion in
            let suggestionAddress = "\(suggestion.title) \(suggestion.subtitle)"
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            return suggestionAddress.lowercased() == trimmed.lowercased()
        }
        
        if perfectMatch {
            return true
        }
        
        // Check against autocomplete suggestions - partial match (if long enough)
        if trimmed.count >= 5 && !completer.completions.isEmpty {
            let partialMatch = completer.completions.contains { suggestion in
                let suggestionTitle = suggestion.title
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                
                let suggestionAddress = "\(suggestion.title) \(suggestion.subtitle)"
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                    
                return suggestionAddress.contains(trimmed) ||
                       trimmed.contains(suggestionTitle) ||
                       (suggestion.subtitle.lowercased().contains(trimmed) && trimmed.count > 8)
            }
            
            if partialMatch {
                return true
            }
        }
        
        // If there's already coordinates associated with this address
        if existingCoordinate != nil {
            return true
        }
        
        return false
    }
    
    // MARK: - Geocoding Functions
    
    /// Geocodes an address string to coordinates
    static func geocodeAddress(_ address: String,
                             completion: @escaping (CLLocationCoordinate2D?, String?) -> Void) {
        let geocoder = CLGeocoder()
        
        // Check if address is coordinates
        if isLikelyCoordinates(address) {
            let components = address.components(separatedBy: ",")
            let trimmedComponents = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            if let lat = Double(trimmedComponents[0]), let lon = Double(trimmedComponents[1]) {
                let coords = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                
                // Reverse geocode to get a more readable address
                let location = CLLocation(latitude: lat, longitude: lon)
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let placemark = placemarks?.first, error == nil {
                        let formattedAddress = [
                            placemark.name,
                            placemark.thoroughfare,
                            placemark.locality,
                            placemark.administrativeArea
                        ]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                        
                        completion(coords, formattedAddress)
                    } else {
                        // Return coordinates but no formatted address
                        completion(coords, nil)
                    }
                }
            } else {
                completion(nil, nil)
            }
        } else {
            // Regular address geocoding
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let placemark = placemarks?.first, let location = placemark.location {
                    // Format the full address
                    let formattedAddress = [
                        placemark.name,
                        placemark.thoroughfare,
                        placemark.locality,
                        placemark.administrativeArea
                    ]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                    
                    completion(location.coordinate, formattedAddress)
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
    
    /// Geocodes an MKLocalSearchCompletion item
    static func geocodeCompletion(_ completion: MKLocalSearchCompletion,
                                completionHandler: @escaping (CLLocationCoordinate2D?, String?) -> Void) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let response = response, let item = response.mapItems.first else {
                completionHandler(nil, nil)
                return
            }
            
            // Get coordinate
            let coordinate = item.placemark.coordinate
            
            // Format address with more complete information
            let placemark = item.placemark
            
            // Get a nicely formatted street address
            let streetAddress = [
                placemark.subThoroughfare,
                placemark.thoroughfare
            ].compactMap { $0 }.joined(separator: " ")
            
            // Get a nicely formatted city, state
            let cityState = [
                placemark.locality,
                placemark.administrativeArea
            ].compactMap { $0 }.joined(separator: ", ")
            
            // Combine all parts, prioritizing the street number and name
            var addressComponents: [String] = []
            
            if !streetAddress.isEmpty {
                addressComponents.append(streetAddress)
            } else if let name = placemark.name, !name.isEmpty {
                addressComponents.append(name)
            }
            
            if !cityState.isEmpty {
                addressComponents.append(cityState)
            }
            
            let formattedAddress = addressComponents.joined(separator: ", ")
            
            completionHandler(coordinate, formattedAddress.isEmpty ? nil : formattedAddress)
        }
    }
    
    // MARK: - String Formatting Helpers
    
    /// Formats an address for display
    static func formatAddress(from placemark: CLPlacemark) -> String {
        let components = [
            placemark.name,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ].compactMap { $0 }
        
        return components.joined(separator: ", ")
    }
}


