import FirebaseStorage
import UIKit

struct ImageUploadService {
    func uploadImage(image: UIImage) async throws -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.25) else {return nil}
        //jpegData is a custom object that compresses the photo quality
        let filename = NSUUID().uuidString
        let ref = Storage.storage().reference(withPath: "/profile_images/\(filename)")
        
        do {
            let _ = try await ref.putDataAsync(imageData) //upload image data
            let url = try await ref.downloadURL()  //this will give us a image url
            return url.absoluteString // pass as string value
        } catch {
            print("DEBUG: Failed to upload image with error: \(error)")
            return nil 
        }
    }
    
}