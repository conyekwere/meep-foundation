//
//  ImageUploadService.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/15/25.
//


import Firebase
import FirebaseStorage
import UIKit

enum UploadType {
    case full
    case thumbnail
}

struct ImageUploadService {
    func uploadImage(image: UIImage, as type: UploadType = .full) async throws -> String? {
        let resizedImage: UIImage
        switch type {
        case .full:
            resizedImage = image
        case .thumbnail:
            resizedImage = image.resized(toMaxDimension: 120)
        }
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.25) else { return nil }
        //jpegData is a custom object that compresses the photo quality
        let filename = NSUUID().uuidString
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        let ref = Storage.storage().reference(withPath: "profile_images/\(uid)/\(filename)")
        
        do {
            let _ = try await ref.putDataAsync(imageData) //upload image data
            let url = try await ref.downloadURL()  //this will give us a image url
            return url.absoluteString // pass as string value
        } catch {
            print("DEBUG: Failed to upload image with error: \(error)")
            return nil 
        }
    }
    
    func uploadImageWithThumbnail(image: UIImage) async throws -> (fullSizeUrl: String, thumbnailUrl: String) {
        async let fullSizeUpload = uploadImage(image: image, as: .full)
        async let thumbnailUpload = uploadImage(image: image, as: .thumbnail)

        let (fullUrl, thumbUrl) = try await (fullSizeUpload, thumbnailUpload)

        guard let full = fullUrl, let thumb = thumbUrl else {
            throw NSError(domain: "ImageUploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }

        return (fullSizeUrl: full, thumbnailUrl: thumb)
    }
}

extension UIImage {
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized ?? self
    }
}
