//
//  OTPInputFields.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.
//

import SwiftUI

struct OTPInputFields: View {
    @Binding var otpFields: [String]
    @FocusState var focusedField: Int?
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<otpFields.count, id: \.self) { index in
                TextField("", text: $otpFields[index])
                    .keyboardType(.numberPad)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .frame(width: 60, height: 80)
                    .foregroundColor(Color(.white))
                    .background(
                        LinearGradient(
                            gradient: otpFields[index].isEmpty
                            ? Gradient(colors: [Color(.systemGray6), Color(.systemGray6)])
                            : Gradient(colors: [Color(hex: "E1BFBF"), Color(hex: "AB67C4"), Color(hex: "7A18C9")]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.5), lineWidth: 0.5)
                    )
                    .shadow(
                        color: otpFields[index].isEmpty
                        ? Color.clear // No shadow for empty fields
                        : Color.black.opacity(0.3), // Shadow for non-empty fields
                        radius: 4, x: 0, y: 4
                    )
                    .focused($focusedField, equals: index)
                    .onChange(of: otpFields[index]) { oldValue, newValue in
                        handleFieldChange(index: index, value: newValue)
                    }
            }
        }
    }
    
    private func handleFieldChange(index: Int, value: String) {
        // If more than one character is entered, keep only the first one
        if value.count > 1 {
            otpFields[index] = String(value.prefix(1))
        }
        
        // Auto-advance to next field
        if value.count == 1 && index < otpFields.count - 1 {
            focusedField = index + 1
        } else if value.isEmpty && index > 0 {
            focusedField = index - 1
        }
    }
}
