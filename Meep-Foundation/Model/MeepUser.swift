///  MeepUser.swift
///  Meep-Foundation
///
///  Created by Chima Onyekwere on 4/4/25.

import Foundation
import FirebaseAuth

/// Model representing a Meep app user
struct MeepUser: Identifiable, Codable {
    var id: String
    var displayName: String
    var username: String
    var email: String
    var phoneNumber: String
    var profileImageUrl: String
    var createdAt: Date
    var updatedAt: Date
    var gender: String
    var dateOfBirth: String
    var profileImageThumbnailUrl: String? // Optional lower-quality thumbnail for App Clip

    // Initialize from Firebase User
    init(from user: User, username: String = "", profileImageUrl: String = "", profileImageThumbnailUrl: String? = nil) {
        self.id = user.uid
        self.displayName = user.displayName ?? "Meep User"
        self.username = username.isEmpty ? (user.email?.components(separatedBy: "@").first ?? "user") : username
        self.email = user.email ?? ""
        self.phoneNumber = user.phoneNumber ?? ""
        self.profileImageUrl = profileImageUrl
        self.profileImageThumbnailUrl = profileImageThumbnailUrl
        self.createdAt = user.metadata.creationDate ?? Date()
        self.updatedAt = user.metadata.lastSignInDate ?? Date()
        self.gender = ""
        self.dateOfBirth = ""
    }

    // Custom initializer for preview and testing
    init(id: String = UUID().uuidString,
         displayName: String = "John Doe",
         username: String = "johndoe",
         email: String = "john@example.com",
         phoneNumber: String = "+1 (555) 123-4567",
         profileImageUrl: String = "",
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         gender: String = "Other",
         dateOfBirth: String = "2000-01-01",
         profileImageThumbnailUrl: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.email = email
        self.phoneNumber = phoneNumber
        self.profileImageUrl = profileImageUrl
        self.profileImageThumbnailUrl = profileImageThumbnailUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.gender = gender
        self.dateOfBirth = dateOfBirth
    }
}
