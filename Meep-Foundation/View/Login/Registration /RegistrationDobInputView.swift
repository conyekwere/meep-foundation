//
//  RegistrationDobInputView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/15/25.
//

import SwiftUI

struct RegistrationDobInputView: View {

    @Binding var dateOfBirth: String
    @State private var showError: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var onContinue: () -> Void
    
    var isFormComplete: Bool {
        dateOfBirth.count == 10 // MM DD YYYY format
    }
    
    var body: some View {
        
        ScrollView {
            VStack(spacing: 16) {
                // Title and Input Fields
                VStack(alignment: .center, spacing: 8) {
                    // Title
                    Text("What’s your date of birth?")
                        .font(.headline)
                        .fontWeight(.medium)
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .lineSpacing(16)
                        .padding(.bottom, 8)
                    
                    // Date of Birth Input
                    TextField("MM DD YYYY", text: $dateOfBirth)
                        .textFieldStyle(GhostTextFieldStyle())
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .onChange(of: dateOfBirth) { newValue in
                            dateOfBirth = formatDob(newValue)
                        }
                        .padding(.horizontal, 16)
                    
                    // Description Text
                    Text("You must be over 14 years old to use Syce")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    
                    // Error Text
                    if showError {
                        Text("Enter a valid date of birth")
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
                        validateDateOfBirth()
                        if !showError {
                            onContinue()
                        }
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
                    .accessibilityHint("Proceed after entering your date of birth")
                }
            }
            
            .padding(.top, 32)
            .onAppear {
                isFocused = true
            }
        }
        
    }

    
    //5 Validation Logic
    private func validateDateOfBirth() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM dd yyyy"
        guard let dobDate = formatter.date(from: dateOfBirth) else {
            showError = true // Invalid format or date
            return
        }
        
        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: dobDate, to: Date()).year ?? 0
        if age < 14 {
            showError = true // Underage
        } else {
            showError = false
            print("Valid Date of Birth: \(dateOfBirth)")
        }
    }
    

    // Format input into MM DD YYYY
    private func formatDob(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        var result = ""
        for (index, char) in digits.prefix(8).enumerated() {
            if index == 2 || index == 4 { result.append(" ") }
            result.append(char)
        }
        return result
    }
}


#Preview {
    RegistrationDobInputView(dateOfBirth: .constant(""), onContinue: {})
}
