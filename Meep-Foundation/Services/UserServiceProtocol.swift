////
////  UserServiceProtocol.swift
////  Meep-Foundation
////
////  Created by Chima Onyekwere on 4/15/25.
////
//
//
//
//
//
//import FirebaseAuth
//import FirebaseFirestore
//
//
//protocol UserServiceProtocol{
//    func fetchUsers() async throws  -> [User] 
//}
//struct UserService: UserServiceProtocol{
//    
//    func fetchCurrentUser() async throws  -> User? {
//        guard let currentUid = Auth.auth().currentUser?.uid else {return nil}
//        let currentUser =  try await FirestoreConstants.UsersCollection.document(currentUid).getDocument(as:User.self)
//        print("DEBUG: Current user is \(currentUser)")
//        return currentUser
//    }
//    
//    func uploadUserData(_ user:User) async throws {
//        do {
//            let userData = try Firestore.Encoder().encode(user)
//            try await FirestoreConstants.UsersCollection.document(user.id).setData(userData)
//        } catch{
//            throw error
//        }
//    }
//    
//    
//    func fetchUsers() async throws -> [User] {
//        let snapshot = try await FirestoreConstants.UsersCollection.getDocuments()
//        return snapshot.documents.compactMap({try? $0.data(as:User.self)})
//    }
//    
//}
//
//
//struct MockUserService: UserServiceProtocol {
//    
//    func fetchUsers() async throws -> [User] {
//        return DeveloperPreview.users
//    }
//}
