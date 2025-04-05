//
//  ProfileMenuItem.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/5/25.
//

import SwiftUI

struct ProfileMenuItem: View {
    var icon: String
    var title: String
    var subtitle: String
    var isRotated: Bool
    
    var body: some View {
        HStack(spacing:16) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(.darkGray))
                .frame(width: 30, height: 30)
                .rotationEffect(isRotated ? .degrees(-90) : .degrees(0))
                .background(Color(.white).opacity(0.8))
                .overlay(
                    Circle()
                        .strokeBorder(Color(.systemGray5), lineWidth: 1)
                )
                .clipShape(Circle())

            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .fontWidth(.expanded)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .fontWidth(.expanded)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(.systemGray6), lineWidth: 1)
        )
    }
}

#Preview {
    ProfileMenuItem(icon: "slider.horizontal.3", title: "Manage Account", subtitle: "Profile and preferences", isRotated: true)
}
