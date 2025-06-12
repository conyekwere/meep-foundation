//
//  UtilityRouteClasses.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/12/25.
//



import Foundation
import CoreLocation

// MARK: - Midpoint Calculator

class MidpointCalculator {
    
    static func calculateGeographicMidpoint(_ point1: CLLocationCoordinate2D,
                                           _ point2: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat1 = point1.latitude * .pi / 180
        let lon1 = point1.longitude * .pi / 180
        let lat2 = point2.latitude * .pi / 180
        let lon2 = point2.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        
        let Bx = cos(lat2) * cos(dLon)
        let By = cos(lat2) * sin(dLon)
        
        let lat3 = atan2(sin(lat1) + sin(lat2), sqrt((cos(lat1) + Bx) * (cos(lat1) + Bx) + By * By))
        let lon3 = lon1 + atan2(By, cos(lat1) + Bx)
        
        return CLLocationCoordinate2D(
            latitude: lat3 * 180 / .pi,
            longitude: lon3 * 180 / .pi
        )
    }
    
    static func generateTestPoints(around center: CLLocationCoordinate2D,
                                  radius: Double) -> [CLLocationCoordinate2D] {
        var points = [center] // Include the center point
        
        let radiusInDegrees = radius / 111000.0 // Convert meters to degrees (approximate)
        
        // Generate points in a grid pattern
        for xOffset in stride(from: -radiusInDegrees, through: radiusInDegrees, by: radiusInDegrees / 2) {
            for yOffset in stride(from: -radiusInDegrees, through: radiusInDegrees, by: radiusInDegrees / 2) {
                let testPoint = CLLocationCoordinate2D(
                    latitude: center.latitude + yOffset,
                    longitude: center.longitude + xOffset
                )
                points.append(testPoint)
            }
        }
        
        return points
    }
}

// MARK: - Route Analyzer

class RouteAnalyzer {
    
    static func countTransfers(in route: GoogleRoute) -> Int {
        var transfers = 0
        
        for leg in route.legs {
            var lastTransitLine: String?
            
            for step in leg.steps {
                if step.travelMode == "TRANSIT",
                   let transitDetails = step.transitDetails {
                    
                    let currentLine = transitDetails.line.shortName ?? transitDetails.line.name
                    
                    if let lastLine = lastTransitLine, lastLine != currentLine {
                        transfers += 1
                    }
                    
                    lastTransitLine = currentLine
                }
            }
        }
        
        return transfers
    }
    
    static func analyzeRouteComplexity(route: GoogleRoute) -> RouteComplexity {
        let totalDuration = route.duration.value
        let totalDistance = route.distance.value
        let transfers = countTransfers(in: route)
        
        // Calculate walking portion
        var walkingTime: TimeInterval = 0
        var transitTime: TimeInterval = 0
        
        for leg in route.legs {
            for step in leg.steps {
                if step.travelMode == "WALKING" {
                    walkingTime += step.duration.value
                } else if step.travelMode == "TRANSIT" {
                    transitTime += step.duration.value
                }
            }
        }
        
        let walkingRatio = walkingTime / totalDuration
        
        return RouteComplexity(
            transfers: transfers,
            walkingRatio: walkingRatio,
            totalDuration: totalDuration,
            totalDistance: totalDistance
        )
    }
    
    static func compareRouteEfficiency(route1: GoogleRoute, route2: GoogleRoute) -> RouteComparison {
        let complexity1 = analyzeRouteComplexity(route: route1)
        let complexity2 = analyzeRouteComplexity(route: route2)
        
        // Score based on multiple factors
        let score1 = calculateRouteScore(complexity: complexity1)
        let score2 = calculateRouteScore(complexity: complexity2)
        
        return RouteComparison(
            route1Score: score1,
            route2Score: score2,
            timeDifference: abs(route1.duration.value - route2.duration.value),
            transferDifference: abs(complexity1.transfers - complexity2.transfers),
            recommendation: score1 < score2 ? .route1Better : .route2Better
        )
    }
    
    private static func calculateRouteScore(complexity: RouteComplexity) -> Double {
        // Lower score is better
        var score = complexity.totalDuration // Base score is travel time
        score += Double(complexity.transfers) * 300 // 5 minutes penalty per transfer
        score += complexity.walkingRatio * 600 // Penalty for high walking ratio
        
        return score
    }
}
