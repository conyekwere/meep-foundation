//
//  HereDirectionsModels.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 7/9/25.
//

import Foundation
import CoreLocation

// Errors for the HERE Directions service
enum HereDirectionsError: Error {
    case networkError
    case invalidURL
    case parsingError
    case budgetExceeded
    case noRoute
    case authenticationFailed
    case rateLimited
}

// MARK: - Response Models
struct HereDirectionsResponse {
    let routes: [HereRoute]
    let status: String
}

struct HereRoute {
    let duration: String
    let distance: String
    let polyline: String?
    let legs: [HereLeg]
    let sections: [HereSection]
    
    var durationValue: TimeInterval {
        // Parse duration from HERE format (e.g., "PT25M" = 25 minutes) with NaN protection
        let parsed = parseDuration(duration)
        
        // ✅ CRITICAL: Protect against NaN/Infinite values
        if parsed.isFinite && !parsed.isNaN && parsed >= 0 {
            return parsed
        } else {
            print("⚠️ Invalid duration parsed: \(parsed), using default")
            return 1800 // Default to 30 minutes
        }
    }
    
    var distanceValue: Double {
        // Parse distance from HERE format with validation
        let parsed = parseDistance(distance)
        
        // ✅ CRITICAL: Protect against NaN/Infinite values
        if parsed.isFinite && !parsed.isNaN && parsed >= 0 {
            return parsed
        } else {
            print("⚠️ Invalid distance parsed: \(parsed), using default")
            return 5000 // Default to 5km
        }
    }
    
    private func parseDuration(_ duration: String) -> TimeInterval {
        // HERE uses ISO 8601 duration format: PT25M30S
        let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(duration.startIndex..<duration.endIndex, in: duration)
        
        guard let match = regex?.firstMatch(in: duration, range: range) else {
            print("⚠️ Failed to parse duration pattern: \(duration)")
            return 1800 // Default 30 minutes
        }
        
        var totalSeconds: TimeInterval = 0
        
        // Hours
        if match.range(at: 1).location != NSNotFound {
            if let hoursRange = Range(match.range(at: 1), in: duration) {
                if let hours = Double(duration[hoursRange]) {
                    // ✅ Validate each component
                    if hours.isFinite && !hours.isNaN && hours >= 0 {
                        totalSeconds += hours * 3600
                    } else {
                        print("⚠️ Invalid hours value: \(hours)")
                    }
                }
            }
        }
        
        // Minutes
        if match.range(at: 2).location != NSNotFound {
            if let minutesRange = Range(match.range(at: 2), in: duration) {
                if let minutes = Double(duration[minutesRange]) {
                    // ✅ Validate each component
                    if minutes.isFinite && !minutes.isNaN && minutes >= 0 {
                        totalSeconds += minutes * 60
                    } else {
                        print("⚠️ Invalid minutes value: \(minutes)")
                    }
                }
            }
        }
        
        // Seconds
        if match.range(at: 3).location != NSNotFound {
            if let secondsRange = Range(match.range(at: 3), in: duration) {
                if let seconds = Double(duration[secondsRange]) {
                    // ✅ Validate each component
                    if seconds.isFinite && !seconds.isNaN && seconds >= 0 {
                        totalSeconds += seconds
                    } else {
                        print("⚠️ Invalid seconds value: \(seconds)")
                    }
                }
            }
        }
        
        // ✅ Final validation
        if !totalSeconds.isFinite || totalSeconds.isNaN || totalSeconds <= 0 {
            print("⚠️ Final duration validation failed: \(totalSeconds)")
            return 1800 // Default 30 minutes
        }
        
        return totalSeconds
    }
    
    private func parseDistance(_ distance: String) -> Double {
        // HERE returns distance as number (meters)
        guard let parsed = Double(distance) else {
            print("⚠️ Failed to parse distance: \(distance)")
            return 5000 // Default 5km
        }
        
        // ✅ Validate parsed distance
        if parsed.isFinite && !parsed.isNaN && parsed >= 0 {
            return parsed
        } else {
            print("⚠️ Invalid distance value: \(parsed)")
            return 5000 // Default 5km
        }
    }
}

struct HereLeg {
    let startAddress: String
    let endAddress: String
    let duration: String
    let distance: String
    let steps: [HereStep]
}

struct HereStep {
    let duration: String
    let distance: String
    let travelMode: String
    let instructions: String
    let polyline: String?
    let transitDetails: HereTransitDetails?
}

struct HereSection {
    let id: String
    let type: String // "pedestrian" or "transit"
    let departure: HereTimePlace
    let arrival: HereTimePlace
    let polyline: String?
    let transport: HereTransport?
}

struct HereTimePlace {
    let time: String
    let place: HerePlace
    
    var date: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: time)
    }
}

struct HerePlace {
    let name: String?
    let type: String
    let location: HereLocation
}

struct HereLocation {
    let lat: Double
    let lng: Double
    
    var coordinate: CLLocationCoordinate2D {
        // ✅ Validate coordinates before creating CLLocationCoordinate2D
        let safeLat = lat.isFinite && !lat.isNaN ? lat : 40.7128 // Default to NYC
        let safeLng = lng.isFinite && !lng.isNaN ? lng : -74.0060 // Default to NYC
        
        return CLLocationCoordinate2D(latitude: safeLat, longitude: safeLng)
    }
}

struct HereTransport {
    let mode: String
    let name: String?
    let category: String?
    let color: String?
}

struct HereTransitDetails {
    let line: HereTransitLine?
    let stopName: String
    let headsign: String?
}

struct HereTransitLine {
    let name: String
    let shortName: String?
    let color: String?
    let agencies: [HereTransitAgency]
}

struct HereTransitAgency {
    let name: String
    let url: String?
}
