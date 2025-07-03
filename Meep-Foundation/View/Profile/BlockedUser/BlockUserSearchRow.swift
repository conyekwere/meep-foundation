//
//  BlockUserSearchRow.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 7/3/25.
//

import SwiftUI

struct BlockUserSearchRow: View {
    let user: MeepUser
    @Binding var isBlocked: Bool
    
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
            
            // Block/Unblock Button
            Button {
                isBlocked.toggle()
            } label: {
                let title = isBlocked ? "Unblock" : "Block"
                Text(title)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .frame(width: 72, height: 24)
                    .foregroundColor(isBlocked ? Color(.label) : .white)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isBlocked ? Color(hex: "F9F9F9") : Color(hex: "262627"))
                    )
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

#Preview {
    @State var mockUser = MeepUser(
        id: "1",
        displayName: "John Doe",
        username: "johndoe",
        profileImageUrl: ""
    )
    @State var isBlocked = false

    BlockUserSearchRow(user: mockUser, isBlocked: $isBlocked)
        .padding()
}
