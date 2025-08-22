//
//  HereDirectionsParser.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 7/10/25.
//

import Foundation
import CoreLocation

// MARK: - Parser
class HereDirectionsParser {
    static func parse(_ data: Data) throws -> HereDirectionsResponse {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Invalid JSON structure")
                throw HereDirectionsError.parsingError
            }
            
            // Print JSON structure for debugging
            print("🔍 JSON keys: \(json.keys)")
            
            // Check for error in response
            if let error = json["error"] as? [String: Any] {
                print("❌ HERE API Error: \(error)")
                throw HereDirectionsError.networkError
            }
            
            // HERE Transit API returns routes directly
            guard let routesArray = json["routes"] as? [[String: Any]] else {
                print("❌ No routes found in response")
                // Check if there's a different structure
                print("📋 Available keys: \(json.keys)")
                return HereDirectionsResponse(routes: [], status: "NO_ROUTES")
            }
            
            print("📋 Found \(routesArray.count) routes in response")
            
            let routes = routesArray.compactMap { routeData -> HereRoute? in
                return parseRoute(routeData)
            }
            
            return HereDirectionsResponse(
                routes: routes,
                status: "OK"
            )
        } catch {
            print("❌ HERE JSON parsing error: \(error)")
            throw HereDirectionsError.parsingError
        }
    }
    
    private static func parseRoute(_ routeJson: [String: Any]) -> HereRoute? {
        print("🔍 Parsing route with keys: \(routeJson.keys)")
        
        guard let sections = routeJson["sections"] as? [[String: Any]] else {
            print("❌ No sections found in route")
            print("📋 Route keys: \(routeJson.keys)")
            return nil
        }

        print("📋 Found \(sections.count) sections in route")
        let parsedSections = sections.compactMap { parseSection($0) }
        print("✅ Successfully parsed \(parsedSections.count) sections")

        // Calculate total duration from sections with NaN protection
        var totalDuration: TimeInterval = 0
        var totalDistance: Double = 0

        for section in parsedSections {
            if let departure = section.departure.date,
               let arrival = section.arrival.date {
                let sectionDuration = arrival.timeIntervalSince(departure)

                // ✅ CRITICAL NaN/Infinite protection
                if sectionDuration.isFinite && !sectionDuration.isNaN && sectionDuration >= 0 {
                    totalDuration += sectionDuration
                    print("📊 Section duration: \(Int(sectionDuration)) seconds")
                } else {
                    print("⚠️ Invalid section duration detected: \(sectionDuration), skipping")
                }
            }
        }

        // Use API-provided summary if available
        if totalDuration == 0, let travelSummary = routeJson["travelSummary"] as? [String: Any],
           let summaryDuration = travelSummary["duration"] as? TimeInterval,
           let summaryDistance = travelSummary["length"] as? Double {
            totalDuration = summaryDuration
            totalDistance = summaryDistance
            print("📋 Using travelSummary: duration=\(Int(totalDuration))s distance=\(Int(totalDistance))m")
        }
        
        // Fallback: try to get duration from route level with validation
        if totalDuration == 0 || !totalDuration.isFinite || totalDuration.isNaN {
            if let routeDuration = routeJson["duration"] as? TimeInterval {
                if routeDuration.isFinite && !routeDuration.isNaN && routeDuration >= 0 {
                    totalDuration = routeDuration
                } else {
                    print("⚠️ Invalid route duration from API: \(routeDuration)")
                    totalDuration = 1800 // Default to 30 minutes
                }
            } else if let routeDurationStr = routeJson["duration"] as? String {
                let parsedDuration = parseISO8601Duration(routeDurationStr)
                if parsedDuration.isFinite && !parsedDuration.isNaN && parsedDuration >= 0 {
                    totalDuration = parsedDuration
                } else {
                    print("⚠️ Invalid parsed duration: \(parsedDuration)")
                    totalDuration = 1800 // Default to 30 minutes
                }
            } else if let travelSummary = routeJson["travelSummary"] as? [String: Any],
                      let summaryDuration = travelSummary["duration"] as? TimeInterval,
                      let summaryDistance = travelSummary["length"] as? Double {
                totalDuration = summaryDuration
                totalDistance = summaryDistance
                print("📋 Using travelSummary (fallback): duration=\(Int(totalDuration))s distance=\(Int(totalDistance))m")
            } else {
                print("⚠️ No duration found, using default")
                totalDuration = 1800 // Default to 30 minutes
            }
        }
        
        // Final validation before creating route
        if !totalDuration.isFinite || totalDuration.isNaN || totalDuration <= 0 {
            print("⚠️ Final duration validation failed, using safe default")
            totalDuration = 1800 // 30 minutes default
        }
        
        if !totalDistance.isFinite || totalDistance.isNaN || totalDistance < 0 {
            print("⚠️ Final distance validation failed, using safe default")
            totalDistance = 5000 // 5km default
        }

        // Convert duration to HERE format with validation
        let durationString = formatDurationAsISO8601(totalDuration)
        
        print("📊 Final route duration: \(Int(totalDuration)) seconds (\(durationString))")
        print("📊 Final route distance: \(Int(totalDistance)) meters")

        return HereRoute(
            duration: durationString,
            distance: "\(Int(totalDistance))",
            polyline: routeJson["polyline"] as? String,
            legs: parsedSections.map { section in
                HereLeg(
                    startAddress: section.departure.place.name ?? "Unknown",
                    endAddress: section.arrival.place.name ?? "Unknown",
                    duration: section.arrival.time,
                    distance: "0",
                    steps: []
                )
            },
            sections: parsedSections
        )
    }
    
    private static func parseSection(_ sectionJson: [String: Any]) -> HereSection? {
        print("🔍 Parsing section with keys: \(sectionJson.keys)")
        
        let id = sectionJson["id"] as? String ?? UUID().uuidString
        let type = sectionJson["type"] as? String ?? "unknown"
        
        print("📋 Section: \(type) (id: \(id))")
        
        guard let departureJson = sectionJson["departure"] as? [String: Any],
              let arrivalJson = sectionJson["arrival"] as? [String: Any] else {
            print("❌ Missing departure or arrival in section")
            return nil
        }
        
        guard let departure = parseTimePlace(departureJson),
              let arrival = parseTimePlace(arrivalJson) else {
            print("❌ Failed to parse departure or arrival")
            return nil
        }
        
        let transport = parseTransport(sectionJson["transport"] as? [String: Any])
        
        return HereSection(
            id: id,
            type: type,
            departure: departure,
            arrival: arrival,
            polyline: sectionJson["polyline"] as? String,
            transport: transport
        )
    }
    
    private static func parseTimePlace(_ timePlaceJson: [String: Any]) -> HereTimePlace? {
        guard let time = timePlaceJson["time"] as? String,
              let placeJson = timePlaceJson["place"] as? [String: Any] else {
            print("❌ Missing time or place in timePlace")
            return nil
        }
        
        guard let place = parsePlace(placeJson) else {
            print("❌ Failed to parse place")
            return nil
        }
        
        return HereTimePlace(time: time, place: place)
    }
    
    private static func parsePlace(_ placeJson: [String: Any]) -> HerePlace? {
        let type = placeJson["type"] as? String ?? "unknown"
        
        guard let locationJson = placeJson["location"] as? [String: Any] else {
            print("❌ Missing location in place")
            return nil
        }
        
        guard let lat = locationJson["lat"] as? Double,
              let lng = locationJson["lng"] as? Double else {
            print("❌ Missing lat/lng in location")
            return nil
        }
        
        // ✅ Validate coordinates to prevent NaN
        guard lat.isFinite && !lat.isNaN && lng.isFinite && !lng.isNaN else {
            print("❌ Invalid coordinates: lat=\(lat), lng=\(lng)")
            return nil
        }
        
        return HerePlace(
            name: placeJson["name"] as? String,
            type: type,
            location: HereLocation(lat: lat, lng: lng)
        )
    }
    
    private static func parseTransport(_ transportJson: [String: Any]?) -> HereTransport? {
        guard let transport = transportJson,
              let mode = transport["mode"] as? String else {
            return nil
        }
        
        return HereTransport(
            mode: mode,
            name: transport["name"] as? String,
            category: transport["category"] as? String,
            color: transport["color"] as? String
        )
    }
    
    // MARK: - Helper Methods with NaN Protection
    
    private static func estimateSectionDistance(_ section: HereSection) -> Double {
        let distance: Double
        
        switch section.type {
        case "pedestrian":
            distance = 400 // 400m walking
        case "transit":
            distance = 2000 // 2km transit
        default:
            distance = 500 // 500m default
        }
        
        // Validate before returning
        return distance.isFinite && !distance.isNaN ? distance : 500
    }
    
    private static func parseISO8601Duration(_ duration: String) -> TimeInterval {
        // Parse ISO 8601 duration format: PT25M30S
        let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(duration.startIndex..<duration.endIndex, in: duration)
        
        guard let match = regex?.firstMatch(in: duration, range: range) else {
            print("⚠️ Failed to parse duration: \(duration)")
            return 1800 // Default 30 minutes
        }
        
        var totalSeconds: TimeInterval = 0
        
        // Hours
        if match.range(at: 1).location != NSNotFound,
           let hoursRange = Range(match.range(at: 1), in: duration) {
            if let hours = Double(duration[hoursRange]) {
                if hours.isFinite && !hours.isNaN {
                    totalSeconds += hours * 3600
                }
            }
        }
        
        // Minutes
        if match.range(at: 2).location != NSNotFound,
           let minutesRange = Range(match.range(at: 2), in: duration) {
            if let minutes = Double(duration[minutesRange]) {
                if minutes.isFinite && !minutes.isNaN {
                    totalSeconds += minutes * 60
                }
            }
        }
        
        // Seconds
        if match.range(at: 3).location != NSNotFound,
           let secondsRange = Range(match.range(at: 3), in: duration) {
            if let seconds = Double(duration[secondsRange]) {
                if seconds.isFinite && !seconds.isNaN {
                    totalSeconds += seconds
                }
            }
        }
        
        // Final validation
        if !totalSeconds.isFinite || totalSeconds.isNaN || totalSeconds <= 0 {
            print("⚠️ Invalid parsed duration result: \(totalSeconds), using default")
            return 1800 // Default 30 minutes
        }
        
        return totalSeconds
    }
    
    private static func formatDurationAsISO8601(_ duration: TimeInterval) -> String {
        // Validate input
        guard duration.isFinite && !duration.isNaN && duration >= 0 else {
            print("⚠️ Invalid duration for formatting: \(duration)")
            return "PT30M" // Safe default
        }
        
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        var result = "PT"
        if hours > 0 {
            result += "\(hours)H"
        }
        if minutes > 0 {
            result += "\(minutes)M"
        }
        if seconds > 0 || result == "PT" {
            result += "\(seconds)S"
        }
        
        return result
    }
}
