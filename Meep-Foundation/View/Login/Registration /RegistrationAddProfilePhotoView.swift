//
//  RegistrationAddProfilePhotoView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/15/25.
//

import SwiftUI
import FirebaseAuth
import Firebase

struct RegistrationAddProfilePhotoView: View {
    
    @State private var isImagePickerPresented: Bool = false
    @State private var showPhotoOptions: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var isUploading = false
    var onContinue: (UIImage) -> Void
    var fullName: String
    var body: some View {
 

        VStack(spacing: 0) {
         
                    
                    // Title and Description
                    VStack(alignment: .center, spacing: 8) {
                        
                        Text("Add a Profile Photo")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .fontWidth(.expanded)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .lineSpacing(16)
                            
                        

                        
                        Text("Add Profile photo to be discovered by others.")
                            .font(.title3)
                            .foregroundColor(.white).opacity(0.8)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                    }
                    

            Spacer()
                
                    // Profile Photo Placeholder
                    Button(action: {
                        showPhotoOptions.toggle()
                    }) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                            
                                .overlay(
                                    ZStack {
                                        Circle()
                                            .stroke(Color(.black), lineWidth: 6)
                                            .fill(.black.opacity(0.9))
                                            .frame(width: 32, height:32)
                                  
                                        
                                        Image(systemName: "plus.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .fontWeight(.semibold)
                                            .font(.callout)
                                            .foregroundColor(.white)
                                            .frame(width: 32, height:32)
                                    }    .offset(x: 50, y: 48)
                                
                                )
                        } else {
                            
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(#colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)),
                                                Color(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1))
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 140, height: 140)

                            }
                            .overlay(
                                Text(String(fullName.prefix(1)))
                                    .font(.system(size: 44)) 
                                    .fontWeight(.semibold)
                                    .fontWidth(.expanded)
                                    .foregroundColor(.white)
                            )

                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .confirmationDialog(
                        "Choose a Photo",
                        isPresented: $showPhotoOptions,
                        titleVisibility: .visible
                    ) {
                        Button("Photo Gallery") {
                            isImagePickerPresented = true
                        }
                        Button("Camera") {
                            // Camera functionality can be added here
                            isImagePickerPresented = true
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                    
                    Spacer()
                    
        
            
                    // Continue Button
                    if let image = selectedImage {
                        VStack {

                            Button(action: {
                                Task {
                                    isUploading = true
                                    if let uploadedImageUrl = try? await ImageUploadService().uploadImage(image: image) {
                                        isUploading = false
                                        onContinue(image)
                                    } else {
                                        isUploading = false
                                        // Handle failure if needed
                                    }
                                }
                            }) {
                                
                                if isUploading {
                                    Text("Uploading...")
                                        .font(.headline)
                                        .padding(.vertical, 8)
                                        .foregroundColor(Color(UIColor.systemBackground))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isUploading ? Color.gray : Color.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 32))
                                        .padding(.horizontal)
                                }
                                else{
                                    Text("Continue")
                                        .font(.headline)
                                        .padding(.vertical, 8)
                                        .foregroundColor(Color(UIColor.systemBackground))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isUploading ? Color.gray : Color.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 32))
                                        .padding(.horizontal)
                                }
                            }
                            .disabled(isUploading)
                        }
                        .padding(.bottom, 48)
                        .accessibilityLabel("Continue to next section")
                        .accessibilityHint("Proceed after adding a profile photo")
                    }
                    else{
                        Button(action: {
                            showPhotoOptions.toggle()
                        }) {
                                Text("Add Photo")
                                    .font(.headline)
                                    .padding(.vertical, 8)
                                    .foregroundColor(Color(UIColor.systemBackground))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isUploading ? Color.gray : Color.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                                    .padding(.horizontal)
                            
                        }
                        .padding(.bottom, 48)
                        .accessibilityLabel("Add Profile photo to be discovered by others.")
                        .accessibilityHint("Proceed after adding a profile photo")
                    }
            
                }

                .padding(.top, 8)
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
    }
}

#Preview {
    RegistrationAddProfilePhotoView(onContinue: { _ in },fullName: "Chima")
}
