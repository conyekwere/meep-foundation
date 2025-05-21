//
//  RegistrationFullNameInputView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/15/25.
//

import SwiftUI

struct RegistrationFullNameInputView: View {

    @Binding var fullName: String
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case firstName, lastName
    }
    
    var onContinue: () -> Void
    
    var isFormComplete: Bool {
        !fullName.isEmpty
    }
    
    var body: some View {
        
        ScrollView  {
            VStack(spacing: 16) {
                // Title and Input Fields
                VStack(alignment: .center, spacing: 8) {
                    // Title
                    Text("What’s your name?")
                        .font(.headline)
                        .fontWeight(.medium)
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .lineSpacing(16)
                        .padding(.bottom, 8)
                    
                    // Input Fields
                    TextField("First name", text: Binding(
                        get: { fullName.components(separatedBy: " ").first ?? "" },
                        set: { fullName = "\($0) \(fullName.components(separatedBy: " ").dropFirst().joined(separator: " "))" }
                    ))
                        .textFieldStyle(GhostTextFieldStyle())
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .firstName)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .lastName
                        }
                    
                    TextField("Last name", text: Binding(
                        get: { fullName.components(separatedBy: " ").dropFirst().joined(separator: " ") },
                        set: { fullName = "\(fullName.components(separatedBy: " ").first ?? "") \($0)" }
                    ))
                        .textFieldStyle(GhostTextFieldStyle())
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .lastName)
                        .submitLabel(.done)
                    
                }
                .padding(.top, 88)
                .padding(.horizontal, 16)
                
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
                    .accessibilityHint("Proceed after entering full name")
                }
            }
            
            .padding(.top, 32)
            .onAppear {
                focusedField = .firstName
            }
        }
    }
}

#Preview {
    RegistrationFullNameInputView(fullName: .constant(""), onContinue: {})
}
