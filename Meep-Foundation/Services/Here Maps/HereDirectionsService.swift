//
//  HereDirectionsService.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 7/9/25.
//

import Foundation
import CoreLocation

class HereDirectionsService {
    
    static let shared = HereDirectionsService()
    
    // HERE API Configuration - Use API Key instead of OAuth2
    private let apiKey = HereAPIConfig.apiKey
    private let transitBaseURL = "https://transit.router.hereapi.com/v8"
    
    // ✅ Rate limiting to prevent 429 errors
    private let maxConcurrentRequests = 2 // HERE allows limited concurrent requests
    private let requestDelay: TimeInterval = 0.5 // 500ms between requests
    private var lastRequestTime: Date = Date.distantPast
    private let requestQueue = DispatchQueue(label: "here.api.requests", qos: .userInitiated)
    
    private init() {
        print("🚇 HERE Directions Service initialized (REST API)")
        
        // Validate API key
        guard !apiKey.isEmpty else {
            print("❌ HERE API Key is missing!")
            return
        }
        print("✅ HERE API Key loaded: \(String(apiKey.prefix(8)))...")
    }

    /// Fetch public-transit directions between two points using REST API
    func getDirections(origin: CLLocationCoordinate2D,
                       destination: CLLocationCoordinate2D) async throws -> HereDirectionsResponse {
        
        // Check budget first using your existing budget manager
        guard HereAPIBudgetManager.shared.canMakeRoutingCall() else {
            throw HereDirectionsError.budgetExceeded
        }
        
        // ✅ Rate limiting - wait if needed
        try await enforceRateLimit()
        
        print("🗺️ HERE REST API Transit call")
        print("📍 From: (\(origin.latitude), \(origin.longitude))")
        print("📍 To: (\(destination.latitude), \(destination.longitude))")
        
        // Build URL with API key
        let url = try buildTransitURL(origin: origin, destination: destination)
        print("🔗 Request URL: \(url)")
        
        // Make request with API key authentication
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Meep/1.0", forHTTPHeaderField: "User-Agent")
        request.httpMethod = "GET"
        request.timeoutInterval = 30.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw HereDirectionsError.networkError
            }
            
            print("📡 HTTP Status: \(httpResponse.statusCode)")
            
            // Log response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw Response (\(data.count) bytes): \(responseString.prefix(500))...")
            }
            
            // ✅ Handle rate limiting specifically
            if httpResponse.statusCode == 429 {
                print("⚠️ Rate limited - waiting and retrying...")
                try await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
                throw HereDirectionsError.rateLimited
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ HERE API Error: \(httpResponse.statusCode)")
                if let errorData = String(data: data, encoding: .utf8) {
                    print("Error response: \(errorData)")
                }
                
                switch httpResponse.statusCode {
                case 401:
                    throw HereDirectionsError.authenticationFailed
                case 429:
                    throw HereDirectionsError.rateLimited
                default:
                    throw HereDirectionsError.networkError
                }
            }
            
            // Parse response
            let parsedResponse = try HereDirectionsParser.parse(data)
            print("✅ HERE REST API: \(parsedResponse.routes.count) routes found")
            
            return parsedResponse
            
        } catch let error as HereDirectionsError {
            throw error
        } catch {
            print("❌ Network error: \(error)")
            throw HereDirectionsError.networkError
        }
    }
    
    /// Get an optimized midpoint using HERE transit data with MUCH REDUCED concurrency
    func getTransitOptimizedMidpoint(userLocation: CLLocationCoordinate2D,
                                     friendLocation: CLLocationCoordinate2D,
                                     searchRadius: Double = 1000) async throws -> CLLocationCoordinate2D {
        
        // Use your existing GeographicAnalyzer class
        let geoMid = GeographicAnalyzer.calculateGeographicMidpoint(userLocation, friendLocation)
        
        // ✅ DRASTICALLY reduce candidate points to prevent rate limiting
        let candidates = GeographicAnalyzer.generateTestPoints(around: geoMid, radius: searchRadius)
        let limitedCandidates = Array(candidates.prefix(3)) // Only test 3 points instead of 9
        
        var best = geoMid
        var bestScore = Double.infinity
        
        print("🎯 Evaluating \(limitedCandidates.count) candidate midpoints (rate-limited)...")
        
        // ✅ Sequential processing instead of concurrent to avoid rate limits
        for (index, point) in limitedCandidates.enumerated() {
            do {
                let score = try await evaluateMidpointScoreSequential(userLocation: userLocation,
                                                                      friendLocation: friendLocation,
                                                                      midpoint: point)
                
                let scoreDisplay: String
                if score.isFinite && !score.isNaN {
                    scoreDisplay = "\(Int(score))"
                } else {
                    scoreDisplay = "∞"
                }
                print("📊 Candidate \(index + 1): score = \(scoreDisplay)")
                
                if score < bestScore && score.isFinite && !score.isNaN {
                    bestScore = score
                    best = point
                }
                
                // ✅ Longer delay between evaluations to avoid rate limiting
                if index < limitedCandidates.count - 1 {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second between candidates
                }
                
            } catch {
                print("⚠️ HERE midpoint eval failed at \(point.latitude),\(point.longitude): \(error.localizedDescription)")
            }
        }
        
        // ✅ Safe score printing - handle infinity/NaN values
        let scoreDisplay: String
        if bestScore.isFinite && !bestScore.isNaN {
            scoreDisplay = "\(Int(bestScore))"
        } else {
            scoreDisplay = "∞"
            print("⚠️ No valid routes found, using geographic midpoint")
            return geoMid
        }
        
        print("🎯 HERE optimized midpoint found [score: \(scoreDisplay)]")
        return best
    }
    
    // MARK: - Private Methods
    
    private func evaluateMidpointScoreSequential(userLocation: CLLocationCoordinate2D,
                                                 friendLocation: CLLocationCoordinate2D,
                                                 midpoint: CLLocationCoordinate2D) async throws -> Double {
        
        // ✅ Sequential requests instead of concurrent to avoid rate limiting
        print("🔄 Sequential routing: User -> Midpoint")
        let userResponse = try await getDirections(origin: userLocation, destination: midpoint)
        
        // Wait between requests
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        print("🔄 Sequential routing: Friend -> Midpoint")
        let friendResponse = try await getDirections(origin: friendLocation, destination: midpoint)
        
        guard let uRoute = userResponse.routes.first,
              let fRoute = friendResponse.routes.first else {
            throw HereDirectionsError.noRoute
        }
        
        let userTime = uRoute.durationValue
        let friendTime = fRoute.durationValue
        let userTrans = HereRouteAnalyzer.countTransfers(in: uRoute)
        let friendTrans = HereRouteAnalyzer.countTransfers(in: fRoute)
        
        // ✅ Validate all values before calculation
        guard userTime.isFinite && !userTime.isNaN &&
              friendTime.isFinite && !friendTime.isNaN else {
            print("⚠️ Invalid route times detected")
            return Double.infinity
        }
        
        var score = userTime + friendTime
        score += abs(userTime - friendTime) * 3
        score += Double(userTrans + friendTrans) * 300
        
        return score.isFinite && !score.isNaN ? score : Double.infinity
    }
    
    private func enforceRateLimit() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            requestQueue.async {
                let now = Date()
                let timeSinceLastRequest = now.timeIntervalSince(self.lastRequestTime)
                
                if timeSinceLastRequest < self.requestDelay {
                    let waitTime = self.requestDelay - timeSinceLastRequest
                    print("⏳ Rate limiting: waiting \(Int(waitTime * 1000))ms")
                    Thread.sleep(forTimeInterval: waitTime)
                }
                
                self.lastRequestTime = Date()
                continuation.resume()
            }
        }
    }
    
    private func buildTransitURL(origin: CLLocationCoordinate2D,
                                destination: CLLocationCoordinate2D) throws -> URL {
        
        guard !apiKey.isEmpty else {
            throw HereDirectionsError.authenticationFailed
        }
        
        var components = URLComponents(string: "\(transitBaseURL)/routes")!
        
        // Build query parameters
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "origin", value: "\(origin.latitude),\(origin.longitude)"),
            URLQueryItem(name: "destination", value: "\(destination.latitude),\(destination.longitude)"),
            URLQueryItem(name: "apikey", value: apiKey), // Use API key directly
            URLQueryItem(name: "return", value: "polyline,travelSummary,actions"),
            URLQueryItem(name: "lang", value: "en-US")
        ]
        
        // Add transport modes (simplified list)
        let transportModes = [ "subway", "train"]
        for mode in transportModes {
            queryItems.append(URLQueryItem(name: "modes", value: mode))
        }
        
        // Add routing preferences
        queryItems.append(contentsOf: [
            URLQueryItem(name: "transitRoutingMode", value: "fewerTransfers"),
            URLQueryItem(name: "walkSpeed", value: "normal"),
            URLQueryItem(name: "alternatives", value: "2") // ✅ Reduced alternatives to avoid rate limiting
        ])
        
        // Add departure time (5 minutes from now)
        let departureTime = Date().addingTimeInterval(300)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        queryItems.append(URLQueryItem(name: "departureTime", value: formatter.string(from: departureTime)))
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw HereDirectionsError.invalidURL
        }
        
        return url
    }
}

// MARK: - Supporting Classes (Only the ones you don't already have)

class HereRouteAnalyzer {
    static func countTransfers(in route: HereRoute) -> Int {
        // Count transit sections minus 1 (first transit is not a transfer)
        let transitSections = route.sections.filter { $0.type == "transit" }
        return max(0, transitSections.count - 1)
    }
}

// MARK: - Error Extensions
extension HereDirectionsError {
    // All error cases are now defined in the enum above
}
