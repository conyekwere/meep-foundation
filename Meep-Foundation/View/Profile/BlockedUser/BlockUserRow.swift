//
//  BlockUserRow.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 7/3/25.
//


import SwiftUI

struct BlockUserRow: View {
    let user: MeepUser
    let onUnblock: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            AsyncImage(url: URL(string: user.profileImageUrl)) { image in
                image.resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } placeholder: {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(user.displayName.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.gray)
                    )
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Unblock Button
            Button {
                onUnblock()
            } label: {
                Text("Unblock")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .frame(width: 72, height: 24)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(Color(.label))
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "F9F9F9"))
                    )
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

#Preview {
    let mockUser = MeepUser(
        id: "1", 
        displayName: "John Doe", 
        username: "johndoe", 
        profileImageUrl: ""
    )
    
    BlockUserRow(user: mockUser) {
        print("Unblocking user")
    }
    .padding()
}
