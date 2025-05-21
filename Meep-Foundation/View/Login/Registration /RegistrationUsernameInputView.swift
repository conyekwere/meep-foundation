//
//  RegistrationUsernameInputView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/15/25.
//

import SwiftUI

struct RegistrationUsernameInputView: View {

    @Binding var username: String
    @FocusState private var isUsernameFocused: Bool
    
    let maxCharacterCount = 18 // Maximum username length
    let minCharacterCount = 3 // Minimum username length
    let onContinue: () -> Void // Closure property
    
    var isFormComplete: Bool {
        username.count >= minCharacterCount && username.count <= maxCharacterCount
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Title and Input
                VStack(alignment: .center, spacing: 8) {
                    // Title
                    Text("What’s your username?")
                        .font(.headline)
                        .fontWeight(.medium)
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .lineSpacing(16)
                        .padding(.bottom, 8)
                    
                    // Username Input Field
                    VStack(alignment: .trailing) {
                        HStack(alignment: .center, spacing: 4) {
                            Spacer()
                            Text("@")
                                .font(.largeTitle)
                                .fontDesign(.rounded)
                                .foregroundColor(.white)
                            
                            TextField("yeetmachine", text: $username)
                                .textFieldStyle(GhostTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .multilineTextAlignment(.center)
                                .keyboardType(.default)
                                .focused($isUsernameFocused)
                                .frame(maxWidth: 230)
                                .onChange(of: username) { newValue in
                                    username = filterUsername(newValue)
                                }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Character count feedback
                    Text("\(username.count)/\(maxCharacterCount) characters")
                        .font(.footnote)
                        .foregroundColor(username.count > maxCharacterCount ? .red : .gray)
                        .padding(.top, 4)
                }
                .padding(.top, 88)
                
                Spacer()
                
                // Continue Button
                if isFormComplete {
                    Button(action: {
                        onContinue() // Call the closure
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
                    .accessibilityHint("Proceed after entering your username")
                }
            }
        }

        .onAppear {
            isUsernameFocused = true
        }
    }
    
    // Filter to allow valid username characters and enforce character limit
    private func filterUsername(_ input: String) -> String {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        return String(input.prefix(maxCharacterCount).unicodeScalars.filter { allowedCharacters.contains($0) })
    }
}

#Preview {
    RegistrationUsernameInputView(username: .constant(""), onContinue: {})
}
