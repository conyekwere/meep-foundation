//
//  EditProfileView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 5/16/25.
//


import SwiftUI
import PhotosUI

struct EditProfileView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject var vm: EditProfileViewModel
    
    
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                PhotosPicker(selection: $vm.selectedPickerItem, matching: .images) {

                    VStack {
                        if let  image = vm.profileImage  {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width:avatarSizeLg.dimension,height: avatarSizeLg.dimension)
                                .clipShape(Circle())
                        } else {
                            AvatarView(user: vm.user, size: avatarSizeLg)
                        }
            
                        Text("Change Photo")
                            .foregroundStyle(Color.primary)
                            .padding(.top)
                    }
                    
                }
                .font(.system(size: 14))
                .padding()

                VStack(alignment: .leading, spacing: 24) {
                    Text("About You")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)
                    
                    EditProfileOptionRowView(option:EditProfileOptions.name, value: vm.user.displayName)
                    EditProfileOptionRowView(option:EditProfileOptions.username, value: vm.user.username)
                    
                }
                .font(.subheadline)
                .padding()

                Spacer()
            }
            .task (id: vm.selectedPickerItem) {
                await vm.loadImage()
            }
            // with task you can link a task to an id ans when that id item changes you can pasxs a function
            .navigationDestination(for: EditProfileOptions.self, destination: { option in
                EditProfileDetailView(option: option, user: vm.user)
                //Text(option.title)
            })
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        print("DEBUG: Back Button Tapped")
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(12)
                            .font(.system(size: 12))
                            .frame(width: 40, height: 40, alignment: .center)
                            //.background(Color(.lightGray).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color(.systemGray6), lineWidth: 2)
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        vm.doneTapped()
                    }
                }
            }
        }
        .foregroundStyle(Color.primary)
        .onChange(of: vm.dismiss) {
            dismiss()
        }
    }
}

private extension EditProfileView{
    var avatarSizeLg: AvatarSize {
        return .large
    }
}

#Preview {
    EditProfileView(vm: EditProfileViewModel(imageUploader: ImageUploadService(), user: DeveloperPreview.meepUser))
}
