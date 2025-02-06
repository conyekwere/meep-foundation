//
//  ProfileBottomSheet.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/5/25.
//


import SwiftUI

struct ProfileBottomSheet: View {
    var imageUrl: String
    @State private var showAccountActions = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Drag Handle - Always Visible
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(Color(.lightGray).opacity(0.3))
//                .padding(.top, 10)
            
            // Profile Info
            VStack(spacing: 8) {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color(.lightGray).opacity(0.3))
                        .frame(width: 80, height: 80)
                }
                VStack(spacing: 2){
                    Text("Ashley Dee")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.gray))
                        .fontWidth(.expanded)
                    
                    Text("@Adhdee")
                        .font(.body)
                        .foregroundColor(Color(.gray))
                        .fontWidth(.expanded)
                }
            }
            .padding(.horizontal)
            
            // Menu Options
            VStack(spacing: 12) {
                ProfileMenuItem(icon: "plus", title: "Meep Plus", subtitle: "Get access to time-saving features", isRotated: false)
                ProfileMenuItem(icon: "pencil.tip", title: "Give Feedback", subtitle: "Help us improve with your thoughts", isRotated: false)
                Button(action: { showAccountActions = true }) {
                    ProfileMenuItem(icon: "slider.horizontal.3", title: "Manage Account", subtitle: "Profile and preferences",isRotated: true)
                }.buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            
    
            
            // Terms & Privacy
            // Terms & Privacy Links
            HStack(spacing: 12) {
                Link("Terms", destination: URL(string: "https://yourapp.com/terms")!)
                    .font(.footnote)
                
                    .foregroundColor(.gray)
                
                Text("·")
                    .foregroundColor(.gray)
                
                Link("Privacy", destination: URL(string: "https://yourapp.com/privacy")!)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .font(.footnote)
            .fontWidth(.expanded)
            .foregroundColor(.gray)
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .ignoresSafeArea(edges: .bottom)
        .confirmationDialog("Account Actions", isPresented: $showAccountActions, titleVisibility: .visible) {
            Button("Logout", role: .cancel) { print("User logged out") }
            Button("Delete Account", role: .destructive) { print("Account deleted") }
            Button("Cancel", role: .cancel) { }
        }
    }
}


#Preview {
    ProfileBottomSheet(imageUrl: "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1")

}
