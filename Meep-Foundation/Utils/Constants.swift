//
//  Constants.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/15/25.
//



import Foundation
import FirebaseFirestore


struct FirestoreConstants {
    static let Root = Firestore.firestore()
    
    static let UsersCollection = Root.collection("users")
}

struct Constants {
    static let authToken: String = "AUTH_TOKEN"
}
