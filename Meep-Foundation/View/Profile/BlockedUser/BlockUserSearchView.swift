//
//  BlockUserSearchView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 7/3/25.
//

import SwiftUI


struct BlockUserSearchView: View {
    let onUserSelected: (MeepUser) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var searchResults: [MeepUser] = []
    @State private var isSearching = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    
    private let firebaseService = FirebaseService.shared
    
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 0) {
                // Search field - similar to AddressInputView
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.gray)
                        }
                        
                        TextField("Search username or name", text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.leading, 12)
                            .onSubmit {
                                searchUsers()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                
                // Search results
                if isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    // No results found
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "person.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("No users found")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("No users found for \"\(searchText)\"")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                    }
                } else if !searchResults.isEmpty {
                    BlockUserSearchList(
                        users: searchResults,
                        onUserSelected: { user in
                            onUserSelected(user)
                            dismiss()
                        }
                    )
                } else {
                    // Initial state - before searching
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("Search for Users")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Enter a username or name to find users to block")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Search Users")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { showAlert = false }
        } message: {
            Text(alertMessage ?? "Unknown error")
        }
        .onChange(of: searchText) { newValue in
            // Auto-search as user types (with a small delay)
            if !newValue.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if searchText == newValue { // Only search if text hasn't changed
                        searchUsers()
                    }
                }
            } else {
                searchResults = []
            }
        }
    }
    
    private func searchUsers() {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        print("[🔎 SearchView] searching for: “\(q)”")
        guard !q.isEmpty else { return }
        
        isSearching = true
        
        // Firebase user search
        firebaseService.searchUsers(query: q) { users, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[🔎 SearchView] got error:", error)
                    alertMessage = "Search failed: \(error.localizedDescription)"
                    showAlert = true
                    isSearching = false
                } else {
                    print("[🔎 SearchView] got \(users.count) users back")
                    self.searchResults = users
                    isSearching = false
                }
            }
        }
    }
}

#Preview {
    BlockUserSearchView { user in
        print("Selected user: \(user.displayName)")
    }
}
