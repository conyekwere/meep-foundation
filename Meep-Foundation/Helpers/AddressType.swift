//
//  AddressType.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/1/25.
//

import SwiftUI
import MapKit
import CoreLocation



// Define AddressType directly in this file
enum AddressType: String, CaseIterable {
    case home = "Home"
    case work = "Work"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .custom: return "mappin.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .home: return .blue
        case .work: return .orange
        case .custom: return .red
        }
    }
}
