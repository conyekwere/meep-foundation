//
//  MeetingPointImageView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/27/25.
//

import SwiftUI
import GooglePlaces

struct MeetingPointImageView: View {
    let meetingPoint: MeetingPoint
    @ObservedObject var viewModel: MeepViewModel
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(8)
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(8)
                    .overlay(
                        ProgressView()
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(8)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                            Text("No photo available")
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // Check if we have a photo reference
        if let photoReference = meetingPoint.photoReference {
            viewModel.fetchPhotoWithReference(photoReference: photoReference) { fetchedImage in
                DispatchQueue.main.async {
                    self.image = fetchedImage
                    self.isLoading = false
                }
            }
        }
        // Otherwise check if we have a regular URL
        else if meetingPoint.imageUrl.starts(with: "http"), let url = URL(string: meetingPoint.imageUrl) {
            // Correct usage of URLSession dataTask
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let downloadedImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = downloadedImage
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }.resume() // Make sure to call resume()
        } else {
            self.isLoading = false
        }
    }
}
