import Foundation

struct DeveloperPreview {
    static let meepUser = MeepUser(
        id: UUID().uuidString,
        displayName: "John Doe",
        username: "john.doe",
        email: "john@example.com",
        phoneNumber: "+15555555555",
        profileImageUrl: "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg",
        createdAt: Date(),
        updatedAt: Date(),
        gender: "Male",
        dateOfBirth: "1990-01-01"
    )
}