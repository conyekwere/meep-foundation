//
//  FirebaseService.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var meepUser: MeepUser?
    private var verificationID: String?
    
    private init() {
        // Check if user is already authenticated
        checkAuthStatus()
    }
    
    /// Check if user is authenticated and refresh current user
    func checkAuthStatus() {
        if let user = Auth.auth().currentUser {
            isAuthenticated = true
            currentUser = user
            fetchUserProfile(for: user.uid)
        } else {
            isAuthenticated = false
            currentUser = nil
            meepUser = nil
        }
    }
    
    // MARK: - Phone Authentication
    
    /// Start phone authentication process with Firebase
    /// - Parameters:
    ///   - phoneNumber: Full international phone number
    ///   - completion: Callback with success status and error message
    func startPhoneAuth(phoneNumber: String, completion: @escaping (Bool, String?) -> Void) {
        print("Starting phone auth for number: \(phoneNumber)")
        
        // Firebase phone verification
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            if let error = error {
                print("Phone auth error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            guard let verificationID = verificationID else {
                print("Verification ID not received")
                completion(false, "Verification ID not received")
                return
            }
            
            print("Verification ID received successfully")
            self?.verificationID = verificationID
            completion(true, nil)
        }
    }
    
    /// Verify phone code received via SMS
    /// - Parameters:
    ///   - code: The verification code received
    ///   - completion: Callback with success status and error message
    func verifyPhoneCode(code: String, completion: @escaping (Bool, String?) -> Void) {
        guard let verificationID = verificationID else {
            print("Verification ID not found")
            completion(false, "Verification ID not found")
            return
        }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            if let error = error {
                print("Verification error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            guard let user = authResult?.user else {
                print("Could not get user information")
                completion(false, "Could not get user information")
                return
            }
            
            print("User authenticated: \(user.uid)")
            self?.isAuthenticated = true
            self?.currentUser = user
            
            // Check if user exists in database already
            self?.checkUserExists(uid: user.uid) { exists in
                completion(true, nil)
            }
        }
    }
    
    // MARK: - User Management
    
    /// Check if a user already exists in the database
    /// - Parameters:
    ///   - uid: Firebase UID
    ///   - completion: Callback with boolean indicating if user exists
    private func checkUserExists(uid: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.getDocument { [weak self] document, error in
            if let document = document, document.exists {
                print("User document exists")
                
                // Since the user exists, fetch their profile data
                if let data = document.data() {
                    self?.updateMeepUserFromFirestore(data: data)
                }
                
                completion(true)
            } else {
                print("User document does not exist")
                completion(false)
            }
        }
    }
    
    /// Fetch complete user profile from Firestore
    /// - Parameter uid: User ID to fetch
    func fetchUserProfile(for uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists, let data = document.data() {
                self?.updateMeepUserFromFirestore(data: data)
            } else {
                print("User profile not found in Firestore")
            }
        }
    }
    
    /// Update local MeepUser object from Firestore data
    /// - Parameter data: User data from Firestore
    private func updateMeepUserFromFirestore(data: [String: Any]) {
        // Extract user data from document
        let uid = data["uid"] as? String ?? ""
        let displayName = data["displayName"] as? String ?? "Meep User"
        let username = data["username"] as? String ?? "user"
        let email = data["email"] as? String ?? ""
        let phoneNumber = data["phoneNumber"] as? String ?? ""
        let profileImageUrl = data["profileImageUrl"] as? String ?? ""
        
        // Get timestamps and convert to Date
        let createdTimestamp = data["createdAt"] as? Timestamp
        let updatedTimestamp = data["updatedAt"] as? Timestamp
        
        let createdAt = createdTimestamp?.dateValue() ?? Date()
        let updatedAt = updatedTimestamp?.dateValue() ?? Date()
        
        // Create MeepUser object
        self.meepUser = MeepUser(
            id: uid,
            displayName: displayName,
            username: username,
            email: email,
            phoneNumber: phoneNumber,
            profileImageUrl: profileImageUrl,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    /// Create or update user profile in database
    /// - Parameters:
    ///   - fullName: User's full name
    ///   - email: User's email
    ///   - username: User's username
    ///   - completion: Callback with success status and error message
    func createUserProfile(fullName: String, email: String, username: String, completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, "User not authenticated")
            return
        }
        
        // Create a change request to update the display name
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        
        changeRequest.commitChanges { [weak self] error in
            if let error = error {
                print("Failed to update display name: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            // Update email
            user.updateEmail(to: email) { error in
                if let error = error {
                    // Don't fail if email update fails, as we're not verifying it now
                    print("Email update failed: \(error.localizedDescription)")
                }
                
                // Store additional user data in Firestore
                self?.saveUserData(uid: user.uid, fullName: fullName, email: email, username: username, completion: completion)
            }
        }
    }
    
    /// Save user data to Firestore
    /// - Parameters:
    ///   - uid: Firebase UID
    ///   - fullName: User's full name
    ///   - email: User's email
    ///   - username: User's username
    ///   - completion: Callback with success status and error message
    private func saveUserData(uid: String, fullName: String, email: String, username: String, completion: @escaping (Bool, String?) -> Void) {
        let db = Firestore.firestore()
        
        // First check if username is already taken
        db.collection("usernames").document(username).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                // Username is already taken
                completion(false, "Username is already taken")
                return
            }
            
            // Username is available, proceed with saving
            let userData: [String: Any] = [
                "uid": uid,
                "displayName": fullName,
                "email": email,
                "username": username,
                "phoneNumber": Auth.auth().currentUser?.phoneNumber ?? "",
                "profileImageUrl": "",
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ]
            
            // Save user data
            db.collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    print("Error saving user data: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                    return
                }
                
                // Reserve the username in a separate collection for uniqueness check
                db.collection("usernames").document(username).setData([
                    "uid": uid,
                    "createdAt": Timestamp(date: Date())
                ]) { [weak self] error in
                    if let error = error {
                        print("Error reserving username: \(error.localizedDescription)")
                        completion(false, error.localizedDescription)
                        return
                    }
                    
                    // Create MeepUser object with the new data
                    if let user = Auth.auth().currentUser {
                        self?.meepUser = MeepUser(
                            id: uid,
                            displayName: fullName,
                            username: username,
                            email: email,
                            phoneNumber: user.phoneNumber ?? "",
                            profileImageUrl: "",
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                    }
                    
                    print("User profile created successfully")
                    completion(true, nil)
                }
            }
        }
    }
    
    /// Sign out the current user
    /// - Parameter completion: Callback with success status and error message
    func signOut(completion: @escaping (Bool, String?) -> Void) {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            currentUser = nil
            meepUser = nil
            verificationID = nil
            completion(true, nil)
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            completion(false, error.localizedDescription)
        }
    }
    
    /// Delete the current user's account
    /// - Parameter completion: Callback with success status and error message
    func deleteAccount(completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, "User not authenticated")
            return
        }
        
        // Delete user document from Firestore first
        let db = Firestore.firestore()
        
        // Get username to delete from usernames collection
        db.collection("users").document(user.uid).getDocument { document, error in
            // Get username to delete from usernames collection
            let username = document?.data()?["username"] as? String
            
            // Delete user data
            db.collection("users").document(user.uid).delete { error in
                if let error = error {
                    print("Error deleting user data: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                    return
                }
                
                // Delete username reservation if it exists
                if let username = username {
                    db.collection("usernames").document(username).delete()
                }
                
                // Delete Firebase Auth user
                user.delete { [weak self] error in
                    if let error = error {
                        print("Error deleting user: \(error.localizedDescription)")
                        completion(false, error.localizedDescription)
                        return
                    }
                    
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                    self?.meepUser = nil
                    self?.verificationID = nil
                    
                    print("User account deleted successfully")
                    completion(true, nil)
                }
            }
        }
    }
}
