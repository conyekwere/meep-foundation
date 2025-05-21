//
//  EditProfileViewModel.swift
//  syce-foundation
//
//  Created by Chima onyekwere on 5/15/24.
//

import Firebase
import UIKit
import SwiftUI
import PhotosUI

class EditProfileViewModel: ObservableObject {
    
    @Published var selectedPickerItem: PhotosPickerItem?
    @Published var profileImage: Image?
    @Published var pickedImage: UIImage?
    @Published var dismiss = false

    private let imageUploader: ImageUploadService
    let user: User

    init(imageUploader: ImageUploadService, user: User) {
        self.imageUploader = imageUploader
        self.user = user
    }
    
    func doneTapped() {
        Task{
            guard let image = pickedImage else { return print("DEBUG: Done Button Tapped") }
            await uploadProfileImage(image)
            let profileImageUrl = try await ImageUploadService().uploadImage(image: image)
            dismiss.toggle()
        }
    }
    
    //tranfer photo from photopicker into edit profile
    func loadImage() async {
        guard let item = selectedPickerItem else { return } // if no  photo selected  found item stop
        guard let data = try? await item.loadTransferable(type: Data.self) else { return } // render photo item as a data type
        guard let uiImage = UIImage(data: data) else {return} // render a swift UI image from UIkit that inputs data
        self.pickedImage = uiImage // add so that this can be refrenced globally based on state value
        profileImage = Image(uiImage: uiImage) // pass UI kit image object into swiftUI image object
        
    }

    func uploadProfileImage(_ uiImage: UIImage) async {
        do{
            let profileImageUrl = try await imageUploader.uploadImage(image: uiImage)
            try await storeUserProfileImageUrl(profileImageUrl)
        } catch {
            print("DEBUG: Handle image upload error here..")
        }
    }
    
    private func storeUserProfileImageUrl(_ imageUrl: String?) async throws {
        guard let imageUrl else { return }
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        try await FirestoreConstants.UsersCollection.document(currentUid).updateData([
            "profileImageUrl": imageUrl
        ])
    }
}