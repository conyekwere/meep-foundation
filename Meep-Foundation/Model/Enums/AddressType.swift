//
//  AddressType.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/1/25.
//

import SwiftUI
import MapKit
import CoreLocation




enum AddressType: String {
    case home = "Home"
    case work = "Work"
    case custom = "Custom"
    
    var iconColor: Color {
        switch self {
        case .home: return .blue
        case .work: return .green
        case .custom: return .orange
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .custom: return "mappin.circle.fill"
        }
    }
}
