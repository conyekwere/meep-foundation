//
//  LocationRequest.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/5/25.
//

import Foundation

struct LocationRequest: Identifiable {
    let id: String
    let senderID: String
    let senderName: String
    let recipientID: String
    let status: String
    let createdAt: Date
}
