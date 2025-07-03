//
//  BlockUsersEmptyStateView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 7/3/25.
//



import SwiftUI

struct BlockUsersEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("You haven't blocked anyone.")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("To block a user, tap the top right "+" icon.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

#Preview {
    BlockUsersEmptyStateView()
}
