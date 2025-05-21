//
//  Secrets.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/15/25.
//



import Foundation
import FirebaseFirestore

enum Secrets {
    static let supabaseURL = URL(string: "https://pqggdnyrsqkbngzfhnhj.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxZ2dkbnlyc3FrYm5nemZobmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODk0OTA5NTgsImV4cCI6MjAwNTA2Njk1OH0.B3hoFN5fPFISb-OANIvgHFpjJnpIRiKSTSuI7YE5wCA"
}

struct FirestoreConstants {
    static let Root = Firestore.firestore()
    
    static let UsersCollection = Root.collection("users")
}

struct Constants {
    static let authToken: String = "AUTH_TOKEN"
}