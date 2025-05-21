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
            .foregroundColor(.white)
    }
}
