//
//  RegistrationGenderInputView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/15/25.
//

import SwiftUI

struct RegistrationGenderInputView: View {

    
    @Binding var gender: String
    
    let genderSuggestions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    let onContinue: () -> Void
    
    var isFormComplete: Bool {
        !gender.isEmpty
    }
    
    var body: some View {
        
        ScrollView {
            VStack(spacing: 16) {
                // Title and Input Fields
                VStack(alignment: .center, spacing: -10) {
                    // Title
                    Text("What’s your gender?")
                        .font(.headline)
                        .fontWeight(.medium)
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        

                    
                    // Gender Input
                    Picker("Select your gender", selection: $gender) {
                        ForEach(genderSuggestions, id: \.self) { suggestion in

                                Text(suggestion)
                                    .tag(suggestion)
                                    .font(.system(size: 18, weight: .medium)) // Large font helps scale visibility
                                    .contentShape(Rectangle())
                                
                        }
                        
                    }
                    .pickerStyle(.wheel)
                    .scaleEffect(1.5)

                    .frame(maxWidth: .infinity)
                    
         
                
                }
                .foregroundColor(.white)
                
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Continue Button
                
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
                    .accessibilityHint("Proceed after entering your gender")
                }
            
            .padding(.top, 32)
        }
    }
}

#Preview {
    RegistrationGenderInputView(gender: .constant(""), onContinue: {})
}
