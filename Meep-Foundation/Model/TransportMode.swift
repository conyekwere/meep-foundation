//
//  TransportMode.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/5/25.
//
import Foundation

enum TransportMode: String, CaseIterable, Identifiable {
    case walk, bike, train, car

    var id: String { rawValue }
    
    /// Returns the SF Symbol name for the transport mode.
    var systemImageName: String {
        switch self {
        case .walk:  return "figure.walk"
        case .bike:  return "bicycle"
        case .train: return "tram.fill"
        case .car:   return "car.fill"
        }
    }
    
    /// Returns a capitalized title for display.
    var title: String {
        rawValue.capitalized
    }
}
