//
//  OTPInputFields.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/9/25.
//

import SwiftUI

struct OTPInputFields: View {
    @Binding var otpFields: [String]
    @FocusState var focusedField: Int?
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<otpFields.count, id: \.self) { index in
                TextField("", text: $otpFields[index])
                    .keyboardType(.numberPad)
                    .textContentType(index == 0 ? .oneTimeCode : .none)
                    .font(.title)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .frame(width: 45, height: 56)
                    .foregroundColor(Color.white)
                    .background {
                        let isEmpty = otpFields[index].isEmpty
                        if isEmpty {
                            Color(.white).opacity(0.9)
                        } else {
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "1AB874"), Color(hex: "0B3F62")]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    }
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                    .shadow(
                        color: otpFields[index].isEmpty
                        ? Color.clear
                        : Color.black.opacity(0.2),
                        radius: 4, x: 0, y: 2
                    )
                    .focused($focusedField, equals: index)
                    .onChange(of: otpFields[index]) { _, newValue in
                        handleFieldChange(index: index, value: newValue)
                    }
                    .accessibilityLabel("OTP digit \(index + 1)")
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

#Preview {
    struct OTPPreviewWrapper: View {
        @State private var otp = Array(repeating: "", count: 6)
        @FocusState private var focusedField: Int?

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                OTPInputFields(otpFields: $otp, focusedField: _focusedField)
            }
        }
    }

    return OTPPreviewWrapper()
}
