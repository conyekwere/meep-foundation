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
    @State private var showOTPVerification = false
    @State private var selectedCountry = Country(name: "United States", code: "+1", flag: "🇺🇸", maxLength: 10)
    @State private var isCountrySelectorPresented = false
    
    // Focus state
    @FocusState private var phoneFieldFocused: Bool
    
    // Is this for creating an account or login
    var isCreatingAccount: Bool = false
    
    // Firebase service
    @StateObject private var firebaseService = FirebaseService.shared
    
    // Callback when verification is complete
    var onComplete: (Bool) -> Void
    
    var body: some View {
        if showOTPVerification {
            OTPVerificationView(
                phoneNumber: "\(countryCode)\(phoneNumber)",
                isCreatingAccount: isCreatingAccount,
                onComplete: onComplete
            )
        } else {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text(isCreatingAccount ? "Create Your Account" : "Welcome Back")
                            .font(.title)
                            .fontWeight(.bold)
                            .fontWidth(.expanded)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .lineSpacing(16)
                        
                        Text("Enter your phone number to \(isCreatingAccount ? "get started" : "sign in")")
                            .font(.body)
                            .foregroundColor(Color(.gray))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 72)
                    
                    // Error message if any
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Phone number input
                    VStack(spacing: 16) {
                        HStack(alignment: .center, spacing: 8) {
                            // Country Code Button
                            Button(action: {
                                isCountrySelectorPresented.toggle()
                            }) {
                                Text(selectedCountry.code)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Phone Number TextField
                            TextField(selectedCountry.maxLength < 10 ? "212555012" : "(212) 555-0123", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .font(.title3)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .focused($phoneFieldFocused)
                                .onChange(of: phoneNumber) { newValue in
                                    // Format the phone number
                                    phoneNumber = formatPhoneNumber(newValue)
                                }
                        }
                        .padding(.horizontal)
                        
                        Text("Message and data rates may apply")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Continue button
                    Button(action: verifyPhoneNumber) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        } else {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFormValid ? Color.blue : Color.gray)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                    .padding(.top, 16)
                    
                    Spacer(minLength: 40)
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
        }
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
        let formattedPhone = "\(countryCode)\(phoneNumber.filter { $0.isNumber })"
        
        firebaseService.startPhoneAuth(phoneNumber: formattedPhone) { success, error in
            isLoading = false
            
            if success {
                withAnimation {
                    showOTPVerification = true
                }
            } else if let error = error {
                errorMessage = error
            }
        }
    }
}

// MARK: - OTP Verification View

struct OTPVerificationView: View {
    // Properties
    var phoneNumber: String
    var isCreatingAccount: Bool = false
    
    // State
    @State private var otpFields = Array(repeating: "", count: 4)
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var countdown = 30
    @State private var isCountdownFinished = false
    @State private var showRegistration = false
    
    // Focus state
    @FocusState private var focusedField: Int?
    
    // Firebase service
    @StateObject private var firebaseService = FirebaseService.shared
    
    // Callback when verification is complete
    var onComplete: (Bool) -> Void
    
    var body: some View {
        if showRegistration {
            RegistrationInfoView(
                phoneNumber: phoneNumber,
                onComplete: onComplete
            )
        } else {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(alignment: .center, spacing: 8) {
                        Text("Enter the code we texted you")
                            .font(.title2)
                            .fontWeight(.bold)
                            .fontWidth(.expanded)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .lineSpacing(16)
                        
                        Text(phoneNumber)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 72)
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    // OTP Input fields
                    OTPInputFields(otpFields: $otpFields, focusedField: _focusedField)
                        .padding(.top, 16)
                    
                    // Continue button
                    if isOtpComplete() {
                        Button(action: verifyOTP) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            } else {
                                Text("Verify")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }
                        .disabled(isLoading)
                        .padding(.top, 24)
                    } else {
                        if isCountdownFinished {
                            Button(action: resendCode) {
                                Text("Resend Code")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                            .padding(.bottom, 16)
                        } else {
                            Text("You can ask for a new code in \(countdown) seconds")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
            .onAppear {
                startCountdown()
                focusedField = 0
            }
        }
    }
    
    // Countdown timer
    private func startCountdown() {
        isCountdownFinished = false
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                isCountdownFinished = true
                timer.invalidate()
            }
        }
    }
    
    // Reset countdown
    private func resetCountdown() {
        countdown = 30
        startCountdown()
    }
    
    // Check if OTP is complete
    private func isOtpComplete() -> Bool {
        return otpFields.allSatisfy { $0.count == 1 }
    }
    
    // Resend verification code
    private func resendCode() {
        isLoading = true
        errorMessage = nil
        
        firebaseService.startPhoneAuth(phoneNumber: phoneNumber) { success, error in
            isLoading = false
            
            if success {
                // Reset fields and countdown
                otpFields = Array(repeating: "", count: 4)
                resetCountdown()
                focusedField = 0
            } else if let error = error {
                errorMessage = error
            }
        }
    }
    
    // Verify OTP code
    private func verifyOTP() {
        isLoading = true
        errorMessage = nil
        
        let otpCode = otpFields.joined()
        
        firebaseService.verifyPhoneCode(code: otpCode) { success, error in
            isLoading = false
            
            if success {
                // Check if we have user data
                if firebaseService.isAuthenticated && !isCreatingAccount {
                    // User exists, complete flow
                    onComplete(true)
                } else {
                    // New user or explicitly creating account, show registration
                    withAnimation {
                        showRegistration = true
                    }
                }
            } else if let error = error {
                errorMessage = error
            }
        }
    }
}