//
//  RouteComplexity.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/12/25.
//
import CoreLocation
import Foundation

struct RouteComplexity {
    let transfers: Int
    let walkingRatio: Double // 0.0 to 1.0
    let totalDuration: TimeInterval
    let totalDistance: Double
}

struct RouteComparison {
    let route1Score: Double
    let route2Score: Double
    let timeDifference: TimeInterval
    let transferDifference: Int
    let recommendation: RouteRecommendation
}

enum RouteRecommendation {
    case route1Better
    case route2Better
    case equivalent
}
