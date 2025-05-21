//
//  PhoneVerificationView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/5/25.
//

import SwiftUI
import FirebaseAuth

struct PhoneVerificationView: View {
    // State
    @State private var phoneNumber = ""
    @State private var countryCode = "+1" // Default to US
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedCountry = Country(name: "United States", code: "+1", flag: "🇺🇸", maxLength: 10)
    @State private var isCountrySelectorPresented = false
    @State private var localVerificationID: String? // Store verification ID locally
    
    // Environment
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeSettings: ThemeSettings
    
    // Focus state
    @FocusState private var phoneFieldFocused: Bool
    
    // Is this for creating an account or login
    var isCreatingAccount: Bool = false
    
    // Firebase service
    @StateObject private var firebaseService = FirebaseService.shared
    
    // Callback when verification is complete
    var onComplete: (Bool, String) -> Void
    
    var body: some View {
        ScrollView {
            // Content remains the same
            VStack(spacing: 16) {
                // Header
                Spacer()
                VStack(alignment: .center, spacing: 8) {
                    // Title
                    Text("What's your phone number?")
                        .font(.headline)
                        .fontWeight(.medium)
                        .fontWidth(.expanded)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .lineSpacing(16)
                        .padding(.bottom, 8)
                
                    // Error message if any
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Phone number input
                    HStack(alignment: .center, spacing: 8) {
                        // Country Code Button
                        Spacer()
                        Button(action: {
                            isCountrySelectorPresented.toggle()
                        }) {
                            Text(selectedCountry.code)
                                .font(.largeTitle)
                                .fontDesign(.rounded)
                                .foregroundColor(.white)
                                .opacity(0.8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(Color.white)
                                        .frame(height: 2)
                                        .padding(.top, 35),
                                    alignment: .bottom
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(minWidth: 60, alignment: .trailing)
                        
                        // Phone Number TextField
                        ZStack(alignment: .leading) {
                            if phoneNumber.isEmpty {
                                Text(selectedCountry.maxLength < 10 ? "212555012" : "(212) 555-0123")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.largeTitle)
                                    .fontDesign(.rounded)
                            }
                            TextField("", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .font(.largeTitle)
                                .fontDesign(.rounded)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .focused($phoneFieldFocused)
                                .onChange(of: phoneNumber) { oldValue, newValue in
                                    phoneNumber = formatPhoneNumber(newValue)
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.leading, selectedCountry.maxLength < 10 ? 20 : 0)
                    .frame(maxWidth: .infinity)
                    
                    // Description Text
                    Text("We'll send you a text with a verification code. Message and data rates may apply.")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .opacity(0.7)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2.0)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                .padding(.top, 88)
                
                Spacer()
                
                // Continue button
                if isFormValid {
                    Button(action: verifyPhoneNumber) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 32))
                                .padding(.horizontal)
                        } else {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(Color.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 32))
                                .padding(.horizontal)
                        }
                    }
                    .disabled(isLoading)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                    .accessibilityLabel("Continue to next section")
                    .accessibilityHint("Proceed to verification code")
                }
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                phoneFieldFocused = true
            }
        }
        .sheet(isPresented: $isCountrySelectorPresented) {
            CountryCodeSelectorView(selectedCountry: $selectedCountry)
                .onDisappear {
                    countryCode = selectedCountry.code
                    phoneNumber = "" // Reset phone number when country changes
                }
        }
        // Only apply background if not disabled by parent
        .background(
            Group {
                if !(themeSettings.disableBackgrounds) {
                    ZStack {
                        Rectangle()
                            .fill(Color(#colorLiteral(red: 0.0470588244497776, green: 0.09803921729326248, blue: 0.26274511218070984, alpha: 1)) .opacity(0.4))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Add blur effect
                        VisualEffectBlur(blurStyle: .dark)
                            .opacity(0.7)
                    }
                }
            }
        )
    }
    
    // Format phone number based on country code
    private func formatPhoneNumber(_ number: String) -> String {
        // Remove all non-digit characters
        let digits = number.filter { $0.isNumber }
        
        // Limit to country's max length
        let limitedDigits = String(digits.prefix(selectedCountry.maxLength))
        
        // Apply formatting only if maxLength is 10 (e.g., for US)
        if selectedCountry.maxLength == 10 {
            var formattedNumber = ""
            
            if limitedDigits.count > 0 {
                formattedNumber += "("
            }
            if limitedDigits.count >= 1 {
                formattedNumber += String(limitedDigits.prefix(3))
            }
            if limitedDigits.count > 3 {
                formattedNumber += ") "
                formattedNumber += String(limitedDigits.dropFirst(3).prefix(3))
            }
            if limitedDigits.count > 6 {
                formattedNumber += "-"
                formattedNumber += String(limitedDigits.dropFirst(6))
            }
            
            return formattedNumber
        } else {
            // For countries with different maxLength, return as-is
            return limitedDigits
        }
    }
    
    // Validation
    private var isFormValid: Bool {
        return phoneNumber.filter { $0.isNumber }.count == selectedCountry.maxLength
    }
    
    // Send verification code
    private func verifyPhoneNumber() {
        isLoading = true
        errorMessage = nil
        
        // Format phone number for Firebase
        let formattedPhone = "\(selectedCountry.code)\(phoneNumber.filter { $0.isNumber })"
        print("Attempting verification for: \(formattedPhone)")
        
        // Direct approach like phonesignin3
        PhoneAuthProvider.provider().verifyPhoneNumber(formattedPhone, uiDelegate: nil) { [self] verificationID, error in
            isLoading = false
            
            if let error = error {
                // Print detailed error information
                print("Firebase Auth Error: \(error)")
                print("Error Domain: \(error.localizedDescription)")
                
                // Get the error code as NSError
                let nsError = error as NSError
                print("Error Code: \(nsError.code)")
                print("Error Domain: \(nsError.domain)")
                print("Error User Info: \(nsError.userInfo)")
                
                errorMessage = "Error: \(error.localizedDescription)"
                return
            }
            
            guard let verificationID = verificationID else {
                errorMessage = "Verification ID not received"
                return
            }
            
            print("Verification ID received successfully: \(verificationID)")
            
            // Store verification ID in the service
            firebaseService.verificationID = verificationID
            onComplete(true, formattedPhone)
        }
    }
}

#Preview {
    PhoneVerificationView(isCreatingAccount: true) { success, number in
        print("Verification complete: \(success) for \(number)")
    }
    .environmentObject(ThemeSettings(disableBackgrounds: true))
}
