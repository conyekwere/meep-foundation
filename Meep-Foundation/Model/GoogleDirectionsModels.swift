//
//  GoogleDirectionsModels.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/12/25.
//

import Foundation
import CoreLocation

// MARK: - Request Models

struct GoogleDirectionsRequest {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let mode: GoogleTransportMode
    let departureTime: Date?
    let alternatives: Bool
    
    init(origin: CLLocationCoordinate2D,
         destination: CLLocationCoordinate2D,
         mode: GoogleTransportMode,
         departureTime: Date? = nil,
         alternatives: Bool = true) {
        self.origin = origin
        self.destination = destination
        self.mode = mode
        self.departureTime = departureTime
        self.alternatives = alternatives
    }
}

enum GoogleTransportMode: String {
    case driving = "driving"
    case walking = "walking"
    case bicycling = "bicycling"
    case transit = "transit"
}

// MARK: - Response Models

struct GoogleDirectionsResponse {
    let routes: [GoogleRoute]
    let status: String
    let errorMessage: String?
}

struct GoogleRoute {
    let legs: [GoogleLeg]
    let summary: String
    let overviewPolyline: String
    let duration: GoogleDuration
    let distance: GoogleDistance
    let fare: GoogleFare?
    let warnings: [String]
}

struct GoogleLeg {
    let startAddress: String
    let endAddress: String
    let startLocation: CLLocationCoordinate2D
    let endLocation: CLLocationCoordinate2D
    let duration: GoogleDuration
    let distance: GoogleDistance
    let steps: [GoogleStep]
}

struct GoogleStep {
    let htmlInstructions: String
    let distance: GoogleDistance
    let duration: GoogleDuration
    let startLocation: CLLocationCoordinate2D
    let endLocation: CLLocationCoordinate2D
    let polyline: String
    let travelMode: String
    let transitDetails: GoogleTransitDetails?
}

// MARK: - Transit Models

struct GoogleTransitDetails {
    let arrivalStop: GoogleTransitStop
    let departureStop: GoogleTransitStop
    let arrivalTime: GoogleTime
    let departureTime: GoogleTime
    let headsign: String
    let headway: Int?
    let numStops: Int
    let line: GoogleTransitLine
}

struct GoogleTransitStop {
    let name: String
    let location: CLLocationCoordinate2D
}

struct GoogleTransitLine {
    let name: String
    let shortName: String?
    let color: String?
    let agencies: [GoogleTransitAgency]
    let vehicle: GoogleTransitVehicle
}

struct GoogleTransitAgency {
    let name: String
    let url: String?
}

struct GoogleTransitVehicle {
    let name: String
    let type: String
    let icon: String?
}

// MARK: - Utility Models

struct GoogleTime {
    let value: Date
    let text: String
    let timeZone: String
}

struct GoogleDuration {
    let value: TimeInterval  // seconds
    let text: String
}

struct GoogleDistance {
    let value: Double  // meters
    let text: String
}

struct GoogleFare {
    let currency: String
    let value: Double
    let text: String
}

// MARK: - Analysis Models

struct TransitAnalysisResult {
    let userViable: Bool
    let friendViable: Bool
    let reason: String
    let confidence: Double // 0.0 to 1.0
    let googleData: GoogleTransitAnalysis?
}

struct GoogleTransitAnalysis {
    let userTransit: GoogleDirectionsResponse
    let friendTransit: GoogleDirectionsResponse
    let userWalking: GoogleDirectionsResponse
    let friendWalking: GoogleDirectionsResponse
}

// MARK: - Error Types

enum GoogleDirectionsError: Error, LocalizedError {
    
    static let budgetExceeded = GoogleDirectionsError.networkError
    
    case invalidURL
    case networkError
    case invalidResponse
    case noRoutesFound
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for Google Directions API"
        case .networkError:
            return "Network error calling Google Directions API"
        case .invalidResponse:
            return "Invalid response from Google Directions API"
        case .noRoutesFound:
            return "No routes found"
        case .apiKeyMissing:
            return "Google Directions API key missing"
        }
    }
}
