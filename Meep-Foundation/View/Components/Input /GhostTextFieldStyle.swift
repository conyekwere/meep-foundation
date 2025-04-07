//
//  GhostTextFieldStyle.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.
//


import SwiftUI

/// A custom text field style with a minimalist appearance
struct GhostTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.largeTitle)
            .fontDesign(.rounded)
            .foregroundColor(.primary)
            .opacity(0.8)
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .frame(height: 2)
                    .padding(.top, 35),
                alignment: .bottom
            )
    }
}

extension TextField {
    func ghostStyle() -> some View {
        self.modifier(GhostTextFieldModifier())
    }
}

/// A modifier to apply the ghost style to any view
struct GhostTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
                    .background(Color(.systemBackground))
            )
            .cornerRadius(8)
    }
}

