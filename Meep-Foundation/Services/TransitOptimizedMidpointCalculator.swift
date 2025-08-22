//
//  TransitOptimizedMidpointCalculator.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/12/25.
//


import Foundation
import CoreLocation



class TransitOptimizedMidpointCalculator {
    
    /// Safely convert Double to Int; returns 0 if value is NaN or infinite.
    private func safeInt(_ value: Double) -> Int {
        return value.isFinite ? Int(value) : 0
    }
    
    private let directionsService = GoogleDirectionsService()
    private let googleBudgetManager = GoogleAPIBudgetManager.shared
    private let hereBudgetManager = HereAPIBudgetManager.shared
    
    // MARK: - Main Transit Midpoint Calculation
    
    /// Calculate the optimal transit midpoint using Google Directions
    func calculateTransitMidpoint(userLocation: CLLocationCoordinate2D,
                                  friendLocation: CLLocationCoordinate2D) async -> CLLocationCoordinate2D {
        
        print("🎯 === CALCULATING TRANSIT-OPTIMIZED MIDPOINT ===")
        print("   User location: (\(userLocation.latitude), \(userLocation.longitude))")
        print("   Friend location: (\(friendLocation.latitude), \(friendLocation.longitude))")
        
        // Check Google budget first
        if googleBudgetManager.shouldUseGoogleForMidpoint(userLocation: userLocation,
                                                          friendLocation: friendLocation) {
            // Step 1: Identify major transit hubs between the two locations
            let candidateHubs = getTransitHubCandidates(from: userLocation, to: friendLocation)
            print("📍 Transit hub candidates: \(candidateHubs.map { $0.name })")
            
            // Step 2: Test each hub to find the optimal one
            var bestHub: TransitHub?
            var bestScore = Double.infinity
            
            for hub in candidateHubs {
                do {
                    let score = try await evaluateTransitHub(
                        hub: hub,
                        userLocation: userLocation,
                        friendLocation: friendLocation
                    )
                    
                    print("🚇 \(hub.name): Score = \(safeInt(score/60))min total, balance = \(safeInt(abs(score - bestScore)/60))min")
                    
                    if score < bestScore {
                        bestScore = score
                        bestHub = hub
                    }
                } catch {
                    print("⚠️ Failed to evaluate \(hub.name): \(error)")
                    continue
                }
            }
            
            if let optimalHub = bestHub {
                print("✅ OPTIMAL TRANSIT MIDPOINT: \(optimalHub.name)")
                print("   Total travel time: \(Int(bestScore/60)) minutes")
                return optimalHub.coordinate
            } else {
                print("❌ No viable transit hubs found, using geographic midpoint")
                return GeographicAnalyzer.calculateGeographicMidpoint(userLocation, friendLocation)
            }
        } else {
            print("💡 Google budget limit reached, using HERE’s hub-based solver")
            // Use the same hub candidate list as Google branch
            let candidateHubs = getTransitHubCandidates(from: userLocation, to: friendLocation)
            print("📍 Transit hub candidates: \(candidateHubs.map { $0.name })")

            var bestHub: TransitHub?
            var bestScore = Double.infinity

            // Evaluate each hub via HERE
            for hub in candidateHubs {
                do {
                    let userResp = try await HereDirectionsService.shared.getDirections(
                        origin: userLocation,
                        destination: hub.coordinate
                    )
                    let friendResp = try await HereDirectionsService.shared.getDirections(
                        origin: friendLocation,
                        destination: hub.coordinate
                    )
                    guard let uRoute = userResp.routes.first,
                          let fRoute = friendResp.routes.first else {
                        throw TransitMidpointError.noTransitRoute
                    }

                    // Use the parsed durationValue (in seconds) from HERE routes
                    let uTime: TimeInterval = uRoute.durationValue
                    let fTime: TimeInterval = fRoute.durationValue
                    let uTransfers = HereRouteAnalyzer.countTransfers(in: uRoute)
                    let fTransfers = HereRouteAnalyzer.countTransfers(in: fRoute)

                    var score = uTime + fTime
                    score += abs(uTime - fTime) * 3
                    score += Double(uTransfers + fTransfers) * 300
                    if hub.importance == .major { score -= 300 }

                    print("🚇 \(hub.name): Score = \(safeInt(score/60))min")

                    if score < bestScore {
                        bestScore = score
                        bestHub = hub
                    }
                } catch {
                    print("⚠️ HERE evaluation failed for \(hub.name): \(error)")
                    continue
                }
            }

            if let optimalHub = bestHub {
                print("✅ HERE-hub midpoint: \(optimalHub.name)")
                return optimalHub.coordinate
            } else {
                print("❌ HERE couldn’t find a viable hub, falling back to in-house solver")
            }

            // In-house fallback: geographic midpoint then transit-hub evaluation
            print("💡 Trying in-house transit-hub solver")
            let geoMid = GeographicAnalyzer.calculateGeographicMidpoint(userLocation, friendLocation)
            do {
                let geoHub = TransitHub(
                    name: "Geographic Midpoint",
                    coordinate: geoMid,
                    lines: [],
                    importance: .local
                )
                let geoScore = try await evaluateTransitHub(
                    hub: geoHub,
                    userLocation: userLocation,
                    friendLocation: friendLocation
                )
                print("📍 Geographic midpoint viable: Score = \(safeInt(geoScore/60))min")
                return geoMid
            } catch {
                print("⚠️ Geographic midpoint not viable (\(error)), evaluating station candidates")
            }

            let inhouseHubs = getTransitHubCandidates(from: userLocation, to: friendLocation)
            var inhouseBest: TransitHub?
            var inhouseScore = Double.infinity
            for hub in inhouseHubs {
                do {
                    let score = try await evaluateTransitHub(
                        hub: hub,
                        userLocation: userLocation,
                        friendLocation: friendLocation
                    )
                    print("🚇 \(hub.name): Score = \(safeInt(score/60))min")
                    if score < inhouseScore {
                        inhouseScore = score
                        inhouseBest = hub
                    }
                } catch {
                    print("⚠️ Failed to evaluate \(hub.name): \(error)")
                    continue
                }
            }
            if let inhouse = inhouseBest {
                print("✅ In-house optimal transit midpoint: \(inhouse.name)")
                return inhouse.coordinate
            } else {
                print("❌ No viable station hubs, returning geographic midpoint")
                return geoMid
            }
        }
    }
    
    // MARK: - Transit Hub Candidates
    
    private func getTransitHubCandidates(from userLocation: CLLocationCoordinate2D,
                                       to friendLocation: CLLocationCoordinate2D) -> [TransitHub] {
        
        // NYC Major Transit Hubs with their connectivity
        let majorHubs: [TransitHub] = [
            // Manhattan Core
            TransitHub(name: "Union Square", coordinate: CLLocationCoordinate2D(latitude: 40.7359, longitude: -73.9906),
                      lines: ["4", "5", "6", "L", "N", "Q", "R", "W"], importance: .major),
            
            TransitHub(name: "Times Square", coordinate: CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855),
                      lines: ["1", "2", "3", "7", "N", "Q", "R", "W", "S"], importance: .major),
            
            TransitHub(name: "14th St-8th Ave", coordinate: CLLocationCoordinate2D(latitude: 40.7394, longitude: -74.0020),
                      lines: ["A", "C", "E", "L"], importance: .major),
            
            TransitHub(name: "West 4th St", coordinate: CLLocationCoordinate2D(latitude: 40.7323, longitude: -74.0004),
                      lines: ["A", "B", "C", "D", "E", "F", "M"], importance: .major),
            
            // Cross-Borough Connections
            TransitHub(name: "Atlantic Ave-Barclays", coordinate: CLLocationCoordinate2D(latitude: 40.6840, longitude: -73.9769),
                      lines: ["B", "D", "N", "Q", "R", "W", "2", "3", "4", "5"], importance: .major),
            
            TransitHub(name: "Jay St-MetroTech", coordinate: CLLocationCoordinate2D(latitude: 40.6924, longitude: -73.9874),
                      lines: ["A", "C", "F", "R"], importance: .secondary),
            
            // East Side Connections
            TransitHub(name: "Lexington Ave/59th St", coordinate: CLLocationCoordinate2D(latitude: 40.7625, longitude: -73.9673),
                      lines: ["4", "5", "6", "N", "Q", "R", "W"], importance: .major),
            
            TransitHub(name: "Grand Central", coordinate: CLLocationCoordinate2D(latitude: 40.7527, longitude: -73.9772),
                      lines: ["4", "5", "6", "7", "S"], importance: .major),
            
            // Brooklyn-Manhattan Bridge Connections
            TransitHub(name: "Canal St", coordinate: CLLocationCoordinate2D(latitude: 40.7185, longitude: -74.0057),
                      lines: ["J", "Z", "N", "Q", "R", "W", "6"], importance: .secondary),
            
            // Upper Manhattan
            TransitHub(name: "125th St", coordinate: CLLocationCoordinate2D(latitude: 40.8075, longitude: -73.9370),
                      lines: ["4", "5", "6", "A", "B", "C", "D"], importance: .major),
            
            // Key L train connections (important for Williamsburg)
            TransitHub(name: "Lorimer St", coordinate: CLLocationCoordinate2D(latitude: 40.7140, longitude: -73.9502),
                      lines: ["L"], importance: .secondary),
            
            TransitHub(name: "Graham Ave", coordinate: CLLocationCoordinate2D(latitude: 40.7148, longitude: -73.9439),
                      lines: ["L"], importance: .secondary)
        ]
        
        // Filter hubs based on geographic relevance
        return filterRelevantHubs(hubs: majorHubs, userLocation: userLocation, friendLocation: friendLocation)
    }
    
    private func filterRelevantHubs(hubs: [TransitHub],
                                  userLocation: CLLocationCoordinate2D,
                                  friendLocation: CLLocationCoordinate2D) -> [TransitHub] {
        
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let friendLoc = CLLocation(latitude: friendLocation.latitude, longitude: friendLocation.longitude)
        
        return hubs.filter { hub ->Bool in
            let hubLoc = CLLocation(latitude: hub.coordinate.latitude, longitude: hub.coordinate.longitude)
            
            let userToHub = userLoc.distance(from: hubLoc)
            let friendToHub = friendLoc.distance(from: hubLoc)
            let userToFriend = userLoc.distance(from: friendLoc)
            
            // Hub should be within reasonable distance of both users
            let maxReasonableDistance = userToFriend * 0.8  // 80% of direct distance
            
            return userToHub < maxReasonableDistance && friendToHub < maxReasonableDistance
        }.sorted { hub1, hub2 in
            // Prioritize major hubs
            if hub1.importance != hub2.importance {
                return hub1.importance.rawValue > hub2.importance.rawValue
            }
            
            // Then by total distance to both users
            let hub1Loc = CLLocation(latitude: hub1.coordinate.latitude, longitude: hub1.coordinate.longitude)
            let hub2Loc = CLLocation(latitude: hub2.coordinate.latitude, longitude: hub2.coordinate.longitude)
            
            let hub1TotalDistance = userLoc.distance(from: hub1Loc) + friendLoc.distance(from: hub1Loc)
            let hub2TotalDistance = userLoc.distance(from: hub2Loc) + friendLoc.distance(from: hub2Loc)
            
            return hub1TotalDistance < hub2TotalDistance
        }.prefix(5).map { $0 } // Test top 5 candidates
    }
    
    // MARK: - Hub Evaluation
    
    private func evaluateTransitHub(hub: TransitHub,
                                  userLocation: CLLocationCoordinate2D,
                                  friendLocation: CLLocationCoordinate2D) async throws -> Double {
        
        // Get transit directions for both users to this hub
        let userRequest = GoogleDirectionsRequest(
            origin: userLocation,
            destination: hub.coordinate,
            mode: .transit,
            departureTime: Date().addingTimeInterval(300)
        )
        
        let friendRequest = GoogleDirectionsRequest(
            origin: friendLocation,
            destination: hub.coordinate,
            mode: .transit,
            departureTime: Date().addingTimeInterval(300)
        )
        
        async let userDirections = directionsService.getDirectionsWithBudget(userRequest)
        async let friendDirections = directionsService.getDirectionsWithBudget(friendRequest)
        
        let (userResponse, friendResponse) = try await (userDirections, friendDirections)
        
        guard let userRoute = userResponse?.routes.first,
              let friendRoute = friendResponse?.routes.first else {
            throw TransitMidpointError.noTransitRoute
        }
        
        let userTime = userRoute.duration.value
        let friendTime = friendRoute.duration.value
        
        // Calculate score based on:
        // 1. Total travel time (lower is better)
        // 2. Balance between users (lower difference is better)
        // 3. Number of transfers (fewer is better)
        // 4. Hub importance (major hubs get bonus)
        
        let totalTime = userTime + friendTime
        let timeDifference = abs(userTime - friendTime)
        let userTransfers = RouteAnalyzer.countTransfers(in: userRoute)
        let friendTransfers = RouteAnalyzer.countTransfers(in: friendRoute)
        let totalTransfers = userTransfers + friendTransfers
        
        // Base score is total travel time
        var score = totalTime
        
        // Heavy penalty for imbalanced travel times (unfairness)
        score += timeDifference * 3
        
        // Penalty for transfers (300 seconds per transfer)
        score += Double(totalTransfers) * 300
        
        // Bonus for major hubs (better amenities, more reliable)
        if hub.importance == .major {
            score -= 300 // 5-minute bonus
        }
        
        print("   \(hub.name): User=\(safeInt(userTime/60))min(\(userTransfers)t), Friend=\(safeInt(friendTime/60))min(\(friendTransfers)t)")
        
        return score
    }
}

// MARK: - Supporting Types

struct TransitHub {
    let name: String
    let coordinate: CLLocationCoordinate2D
    let lines: [String]
    let importance: HubImportance
    
    enum HubImportance: Int {
        case major = 2
        case secondary = 1
        case local = 0
    }
}

enum TransitMidpointError: Error {
    case noTransitRoute
    case budgetExceeded
    case networkError
}


