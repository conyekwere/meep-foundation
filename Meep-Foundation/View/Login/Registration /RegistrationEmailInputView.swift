//
//  RegistrationEmailInputView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/15/25.
//

import SwiftUI

struct RegistrationEmailInputView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var email: String
    @FocusState private var isEmailFocused: Bool
    var onContinue: () -> Void
    
    var isFormComplete: Bool {
        !email.isEmpty && isValidEmail(email)
    }
    
    var body: some View {
        
        ScrollView  {
            VStack(spacing: 16) {
                // Title and Input
                VStack(alignment: .center, spacing: 8) {
                    // Title
                    Text("What’s your email?")
                        .font(.headline)
                        .fontWeight(.medium)
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .lineSpacing(16)
                        .padding(.bottom, 8)
                    
                    // Email Input Field
                    TextField("email@example" + ".com", text: $email)
                        .textFieldStyle(GhostTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .multilineTextAlignment(.center)
                        .focused($isEmailFocused)
                        .padding(.horizontal, 16)
                        .onSubmit {
                            isEmailFocused = false
                        }
                    
                    
                    // Error Text
                    if !isFormComplete && !email.isEmpty {
                        Text("Enter a valid email address")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "FF9A9A"))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .padding(.top, 88)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Continue Button
                if isFormComplete {
                    Button(action: {
                        onContinue()
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .foregroundColor(Color(UIColor.systemBackground))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 32))
                            .padding(.horizontal)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                    .accessibilityLabel("Continue to next section")
                    .accessibilityHint("Proceed after entering your email")
                }
            }
            .padding(.top, 32)
            
            .onAppear {
                isEmailFocused = true
            }
        }
    }
    
    // Validate email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    RegistrationEmailInputView(email: .constant(""), onContinue: {})
}
