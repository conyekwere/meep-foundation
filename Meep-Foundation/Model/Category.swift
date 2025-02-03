//
//  Category.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/3/25.
//

import SwiftUI

// Define a structured Category model
struct Category: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let name: String
    let hidden: Bool
}

