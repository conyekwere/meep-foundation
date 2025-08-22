//
//  GoogleDirectionsService.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/12/25.
//

import Foundation
import CoreLocation

class GoogleDirectionsService {
    static let shared = GoogleDirectionsService()
    private let apiKey: String
    private let baseURL = "https://maps.googleapis.com/maps/api/directions/json"
    
    init() {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GDApiKey") as? String else {
            fatalError("❌ Google Directions API Key not found in Info.plist")
        }
        self.apiKey = key
    }
    
    // MARK: - Main API Methods
    
    /// Get directions between two points
    func getDirections(_ request: GoogleDirectionsRequest) async throws -> GoogleDirectionsResponse {
        let url = try buildURL(for: request)
        
        print("🗺️ Google Directions API call: \(request.mode.rawValue)")
        print("   Origin: \(request.origin)")
        print("   Destination: \(request.destination)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GoogleDirectionsError.networkError
        }
        
        let directionsResponse = try GoogleDirectionsParser.parseResponse(data)
        
        print("✅ Google Directions: \(directionsResponse.routes.count) routes found")
        
        if directionsResponse.status != "OK" {
            print("⚠️ Google Directions API Status: \(directionsResponse.status)")
            if let error = directionsResponse.errorMessage {
                print("   Error: \(error)")
            }
        }
        
        return directionsResponse
    }
    
    /// Get optimal midpoint based on transit routes
    func getTransitOptimizedMidpoint(userLocation: CLLocationCoordinate2D,
                                   friendLocation: CLLocationCoordinate2D,
                                   searchRadius: Double = 1000) async throws -> CLLocationCoordinate2D {
        
        let geographicMidpoint = MidpointCalculator.calculateGeographicMidpoint(userLocation, friendLocation)
        let testPoints = MidpointCalculator.generateTestPoints(around: geographicMidpoint, radius: searchRadius)
        
        var bestMidpoint = geographicMidpoint
        var bestScore = Double.infinity
        
        for testPoint in testPoints {
            do {
                let score = try await evaluateMidpointScore(
                    userLocation: userLocation,
                    friendLocation: friendLocation,
                    midpoint: testPoint
                )
                
                if score < bestScore {
                    bestScore = score
                    bestMidpoint = testPoint
                }
            } catch {
                print("⚠️ Failed to evaluate midpoint: \(error)")
                continue
            }
        }
        
        print("🎯 Optimized midpoint found with score: \(bestScore)")
        return bestMidpoint
    }
    
    /// Test Google Directions integration
    func testGoogleDirectionsIntegration() async {
        let timesSquare = CLLocationCoordinate2D(latitude: 40.758, longitude: -73.9855)
        let unionSquare = CLLocationCoordinate2D(latitude: 40.7359, longitude: -73.9906)
        
        let request = GoogleDirectionsRequest(
            origin: timesSquare,
            destination: unionSquare,
            mode: .transit,
            departureTime: Date().addingTimeInterval(300)
        )
        
        do {
            let response = try await getDirections(request)
            
            print("🧪 Google Directions Test Results:")
            print("   Status: \(response.status)")
            print("   Routes found: \(response.routes.count)")
            
            if let route = response.routes.first {
                print("   Duration: \(route.duration.text)")
                print("   Distance: \(route.distance.text)")
                print("   Summary: \(route.summary)")
                
                for (i, leg) in route.legs.enumerated() {
                    print("   Leg \(i): \(leg.startAddress) → \(leg.endAddress)")
                    
                    for (j, step) in leg.steps.enumerated() {
                        print("     Step \(j): \(step.travelMode) - \(step.duration.text)")
                        
                        if let transit = step.transitDetails {
                            print("       Transit: \(transit.line.shortName ?? transit.line.name)")
                            print("       From: \(transit.departureStop.name)")
                            print("       To: \(transit.arrivalStop.name)")
                        }
                    }
                }
            }
            
        } catch {
            print("❌ Google Directions test failed: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func buildURL(for request: GoogleDirectionsRequest) throws -> URL {
        var components = URLComponents(string: baseURL)!
        
        var queryItems = [
            URLQueryItem(name: "origin", value: "\(request.origin.latitude),\(request.origin.longitude)"),
            URLQueryItem(name: "destination", value: "\(request.destination.latitude),\(request.destination.longitude)"),
            URLQueryItem(name: "mode", value: request.mode.rawValue),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "alternatives", value: request.alternatives ? "true" : "false")
        ]
        
        // Add departure time for transit
        if request.mode == .transit, let departureTime = request.departureTime {
            let timestamp = Int(departureTime.timeIntervalSince1970)
            queryItems.append(URLQueryItem(name: "departure_time", value: "\(timestamp)"))
        }
        
        // Add transit preferences for NYC
        if request.mode == .transit {
            queryItems.append(URLQueryItem(name: "transit_mode", value: "subway|bus"))
            queryItems.append(URLQueryItem(name: "transit_routing_preference", value: "fewer_transfers"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw GoogleDirectionsError.invalidURL
        }
        
        return url
    }
    
    private func evaluateMidpointScore(userLocation: CLLocationCoordinate2D,
                                     friendLocation: CLLocationCoordinate2D,
                                     midpoint: CLLocationCoordinate2D) async throws -> Double {
        
        let userRequest = GoogleDirectionsRequest(
            origin: userLocation,
            destination: midpoint,
            mode: .transit,
            departureTime: Date().addingTimeInterval(300)
        )
        
        let friendRequest = GoogleDirectionsRequest(
            origin: friendLocation,
            destination: midpoint,
            mode: .transit,
            departureTime: Date().addingTimeInterval(300)
        )
        
        async let userDirections = getDirections(userRequest)
        async let friendDirections = getDirections(friendRequest)
        
        let (userResponse, friendResponse) = try await (userDirections, friendDirections)
        
        guard let userRoute = userResponse.routes.first,
              let friendRoute = friendResponse.routes.first else {
            return Double.infinity // No transit routes available
        }
        
        let userTime = userRoute.duration.value
        let friendTime = friendRoute.duration.value
        
        // Score based on:
        // 1. Total travel time
        // 2. Difference in travel times (fairness)
        // 3. Number of transfers
        
        let totalTime = userTime + friendTime
        let timeDifference = abs(userTime - friendTime)
        let userTransfers = RouteAnalyzer.countTransfers(in: userRoute)
        let friendTransfers = RouteAnalyzer.countTransfers(in: friendRoute)
        
        // Weighted scoring
        let score = totalTime + (timeDifference * 2) + Double(userTransfers + friendTransfers) * 300
        
        return score
    }
    
    
    /// Fetch simple transit time using Google Directions API
    func getTransitTime(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        completion: @escaping (TimeInterval?) -> Void
    ) {
        let request = GoogleDirectionsRequest(
            origin: origin,
            destination: destination,
            mode: .transit,
            departureTime: Date().addingTimeInterval(300) // 5 minutes from now
        )

        Task {
            do {
                let response = try await getDirections(request)
                if let route = response.routes.first {
                    completion(route.duration.value)
                } else {
                    print("⚠️ Google returned no routes for transit.")
                    completion(nil)
                }
            } catch {
                print("❌ Google transit fallback failed: \(error)")
                completion(nil)
            }
        }
    }

}

