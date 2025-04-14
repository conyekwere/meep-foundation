//
//  ProfileBottomSheet.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/5/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileBottomSheet: View {
    // Optional imageUrl parameter for backward compatibility
    var imageUrl: String?
    
    // Firebase service
    @StateObject private var firebaseService = FirebaseService.shared
    
    // State
    @State private var showAccountActions = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showLoginView = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Environment
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Drag Handle - Always Visible
                Capsule()
                    .frame(width: 40, height: 5)
                    .foregroundColor(Color(.lightGray).opacity(0.3))
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else if firebaseService.isAuthenticated, let user = firebaseService.meepUser {
                    // Authenticated User Profile
                    userProfileSection(user: user)
                    
                    // Menu Options
                    menuOptions()
                    
                    // Terms & Privacy Links
                    termsAndPrivacySection()
                } else {
                    // Not authenticated - show login prompt
                    notAuthenticatedSection()
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .ignoresSafeArea(edges: .bottom)
            .padding(.top, 16)
            
            // Error alert
            if let errorMessage = errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 16)
                }
            }
        }
        .onAppear {
            // Check authentication status when sheet appears
            firebaseService.checkAuthStatus()
        }
        .sheet(isPresented: $showLoginView) {
            LoginView(onDismiss: { success in
                showLoginView = false
                if success {
                    // Refresh the view
                    firebaseService.checkAuthStatus()
                }
            })
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all your data. This action cannot be undone.")
        }
    }
    
    // MARK: - View Components
    
    private func userProfileSection(user: MeepUser) -> some View {
        VStack(spacing: 8) {
            // Profile Image
            AsyncImage(url: URL(string: user.profileImageUrl.isEmpty ? (imageUrl ?? "") : user.profileImageUrl)) { image in
                image.resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } placeholder: {
                Circle()
                    .fill(Color(.lightGray).opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(String(user.displayName.prefix(1)))
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }
            
            // Name and Username
            VStack(spacing: 2) {
                Text(user.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.darkGray))
                    .fontWidth(.expanded)
                
                Text("@\(user.username)")
                    .font(.body)
                    .foregroundColor(Color(.gray))
                    .fontWidth(.expanded)
            }
        }
        .padding(.horizontal)
    }
    
    private func menuOptions() -> some View {
        VStack(spacing: 12) {
            ProfileMenuItem(icon: "plus", title: "Meep Plus", subtitle: "Get access to time-saving features", isRotated: false)
                .onTapGesture {
                    // Implement Meep Plus subscription flow
                }
            
            ProfileMenuItem(icon: "pencil.tip", title: "Give Feedback", subtitle: "Help us improve with your thoughts", isRotated: false)
                .onTapGesture {
                    // Implement feedback submission
                }
            
            ProfileMenuItem(icon: "person.fill", title: "Edit Profile", subtitle: "Update your profile information", isRotated: false)
                .onTapGesture {
                    // Navigate to profile editing
                }
            
            Button(action: { showAccountActions = true }) {
                ProfileMenuItem(icon: "slider.horizontal.3", title: "Manage Account", subtitle: "Profile and preferences", isRotated: true)
            }
            .buttonStyle(PlainButtonStyle())
            .confirmationDialog("Account Actions", isPresented: $showAccountActions, titleVisibility: .visible) {
                Button("Logout", role: .destructive) {
                    showLogoutAlert = true
                }
                Button("Delete Account", role: .destructive) {
                    showDeleteAccountAlert = true
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        .padding(.horizontal)
    }
    
    private func termsAndPrivacySection() -> some View {
        HStack(spacing: 12) {
            Link("Terms", destination: URL(string: "https://meep.earth/terms")!)
                .font(.footnote)
                .foregroundColor(.gray)
            
            Text("·")
                .foregroundColor(.gray)
            
            Link("Privacy", destination: URL(string: "https://meep.earth/privacy")!)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .font(.footnote)
        .fontWidth(.expanded)
        .foregroundColor(.gray)
        .padding(16)
    }
    
    private func notAuthenticatedSection() -> some View {
        VStack(spacing: 24) {

            Text("Session expired. Please login again.")
                .padding()
            
            Button("Logout", role: .destructive) {
                logout()
            }
            .padding()
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 32)
    }
    
    // MARK: - Authentication Methods
    
    private func logout() {
        isLoading = true
        firebaseService.signOut { success, error in
            isLoading = false
            if success {
                dismiss()
            } else if let error = error {
                self.errorMessage = error
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.errorMessage = nil
                }
            }
        }
    }
    
    private func deleteAccount() {
        isLoading = true
        firebaseService.deleteAccount { success, error in
            isLoading = false
            if success {
                dismiss()
            } else if let error = error {
                self.errorMessage = error
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.errorMessage = nil
                }
            }
        }
    }
}

#Preview {
    ProfileBottomSheet(imageUrl: "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1")
}
