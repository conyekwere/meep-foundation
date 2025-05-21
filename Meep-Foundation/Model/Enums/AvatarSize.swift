//
//  AvatarSize.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 5/17/25.
//

import Foundation


enum AvatarSize {
    case xxSmall
    case xSmall
    case small
    case medium
    case large
    case largeProfile
    case xLarge
    
    var dimension: CGFloat {
        switch self {
        case .xxSmall: return 28
        case .xSmall: return 32
        case .small: return 40
        case .medium: return 48
        case .large: return 64
        case .largeProfile: return 70
        case .xLarge: return 80
        }
    }
}
