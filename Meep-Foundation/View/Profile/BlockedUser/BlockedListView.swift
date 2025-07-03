//
//  BlockedListView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 7/3/25.
//

import SwiftUI

struct BlockedListView: View {
    @Environment(\.dismiss) var dismiss
    @State private var blockedUsers: [MeepUser] = []
    @State private var isLoading = false
    @State private var isShowingBlockUserSearch = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if blockedUsers.isEmpty {
                    BlockUsersEmptyStateView()
                } else {
                    BlockUsersListView(
                        blockedUsers: blockedUsers,
                        onUnblock: unblockUser
                    )
                }
            }
            .navigationTitle("Blocked Users")
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color(.systemGray6), lineWidth: 2)
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        print("DEBUG: Add Plus Button")
                        isShowingBlockUserSearch = true
                    }) {
                        Image(systemName: "plus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(12)
                            .font(.system(size: 12))
                            .frame(width: 40, height: 40, alignment: .center)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color(.systemGray6), lineWidth: 2)
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .onAppear {
                loadBlockedUsers()
            }
            .sheet(isPresented: $isShowingBlockUserSearch) {
                BlockUserSearchView { user in
                    blockUser(user)
                }
            }
            .alert("Error", isPresented: $showAlert, actions: {
                Button("OK", role: .cancel) { showAlert = false }
            }, message: {
                if let msg = alertMessage {
                    Text(msg)
                }
            })
        }
    }
    
    // MARK: - Data Methods
    private func loadBlockedUsers() {
        isLoading = true
        firebaseService.getBlockedUsers { users in
            self.blockedUsers = users
            self.isLoading = false
        }
    }
    
    private func blockUser(_ user: MeepUser) {
        firebaseService.blockUser(user.id) { success in
            if success, !blockedUsers.contains(where: { $0.id == user.id }) {
                blockedUsers.append(user)
            } else if !success {
                alertMessage = "Failed to block user. Please try again."
                showAlert = true
            }
        }
    }
    
    private func unblockUser(_ user: MeepUser) {
        firebaseService.unblockUser(user.id) { success in
            if success {
                blockedUsers.removeAll { $0.id == user.id }
            } else {
                alertMessage = "Failed to unblock user. Please try again."
                showAlert = true
            }
        }
    }
}

// MARK: - Previews
#Preview("Empty State") {
    BlockedListView()
}

#Preview("With Blocked Users") {
    BlockedListViewWithMockData()
}

// Helper view for preview with mock data
struct BlockedListViewWithMockData: View {
    @State private var blockedUsers: [MeepUser] = [
        MeepUser(id: "1", displayName: "Vasquez Rodriguez", username: "vasquez_r", profileImageUrl: "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
        MeepUser(id: "2", displayName: "Kyra Mora", username: "kyra_mora", profileImageUrl: "https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
        MeepUser(id: "3", displayName: "Ryan Dires", username: "ryan_dires", profileImageUrl: "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
        MeepUser(id: "4", displayName: "Sammy Rhea", username: "sammyrhea", profileImageUrl: "https://images.pexels.com/photos/3778876/pexels-photo-3778876.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2")
    ]
    
    var body: some View {
        NavigationStack {
            BlockUsersListView(blockedUsers: blockedUsers) { user in
                blockedUsers.removeAll { $0.id == user.id }
            }
            .navigationTitle("Blocked Users")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
