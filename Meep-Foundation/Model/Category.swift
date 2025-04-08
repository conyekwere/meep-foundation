//
//  Category.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/3/25.
//

import Foundation

struct Category: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let name: String
    let hidden: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
}
