//
//  EditProfileOptions.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 5/16/25.
//

import Foundation

enum EditProfileOptions: Hashable {
    case name
    case username
    case bio
    
    var title: String {
        switch self {
        case .name:
            return "Name"
        case .username:
            return "Username"
        case .bio:
            return "Bio"
        }
    }
}
