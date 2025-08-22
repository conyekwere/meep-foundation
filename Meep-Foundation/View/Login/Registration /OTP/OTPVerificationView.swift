//
//  OTPVerificationView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/6/25.
//

import SwiftUI
import FirebaseAuth

struct OTPVerificationView: View {
    // Properties
    var phoneNumber: String
    @Binding var isCreatingAccount: Bool // Updated to Binding
    
    // State
    @State private var otpFields = Array(repeating: "", count: 6) // Use 6 digits for OTP
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var countdown = 30
    @State private var isCountdownFinished = false
    @State private var showErrorModal = false // New local state property
    @State private var showNoAccountModal = false // New local state property
    @State private var showAccountExistsModal = false // New modal for existing account during creation
    @State private var showLoginSuccessModal = false // New modal for successful login
    
    // Environment
    @Environment(\.colorScheme) var colorScheme
    
    // Focus state
    @FocusState private var focusedField: Int?
    
    // Firebase service
    @StateObject private var firebaseService = FirebaseService.shared
    
    // Callback when verification is complete
    var onComplete: (Bool) -> Void
    
    var body: some View {
        
        ScrollView {
            // Content remains the same
            VStack(spacing: 16) {
                // Header
                
                VStack(alignment: .center, spacing: 8) {
                    
                    VStack(alignment: .center, spacing: 8) {
                        Text("Enter the code we texted you")
                            .font(.headline)
                            .fontWeight(.medium)
                            .fontWidth(.expanded)
                            .foregroundColor(.white)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text("on \(phoneNumber)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .fontWidth(.expanded)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 72)
                    
                    // Error message
                    if let errorMessage = errorMessage,
                       !(errorMessage.localizedCaseInsensitiveContains("code") || errorMessage.localizedCaseInsensitiveContains("verification")) {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    // OTP Input fields
                    OTPInputFields(otpFields: $otpFields, focusedField: _focusedField)
                        .padding(.top, 16)
                    
                    
                    // Continue button or countdown
                    if isOtpComplete() {
                        Button(action: verifyOTP) {
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
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                                    .padding(.horizontal)
                            }
                        }
                        .disabled(isLoading)
                        .padding(.vertical, 24)
                        .accessibilityLabel("Continue to next section")
                    }
                    if isCountdownFinished {
                        Button(action: resendCode) {
                            HStack(alignment: .center, spacing: 4) {
                                Text("Do you need a new code?")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2.0)
                                
                                Text("Send New Code")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2.0)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 48)
                        .accessibilityLabel("Resend the OTP code")
                    } else {
                        Text("You can ask for a new code in \(countdown) seconds.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2.0)
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                            .padding(.bottom, 48)
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)
        .onAppear {
            startCountdown()
            focusedField = 0
        }
        .sheet(isPresented: $showErrorModal) { // New sheet for error modal
            VStack(spacing: 32) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .frame(width:60, height: 60)
                    .foregroundColor(.red)

                Text("Incorrect Code. Please try again.")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()

                Button(action: {
                    showErrorModal = false
                }) {
                    Text("OK")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
            }
            .padding()
            .presentationDetents([.fraction(0.4)])
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showNoAccountModal) { // Sheet for no account modal
            VStack(spacing: 32) {
                Image(systemName: "person.crop.circle.badge.question")
                    .resizable()
                    .frame(width:90, height: 90)
                    .foregroundColor(.orange)
                    
                
                VStack(spacing: 8) {
                    Text("Account does not exists!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                    
                    Text("No account found for this phone number. Would you like to create one?")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .lineLimit(nil)
                }


                Button(action: {
                    isCreatingAccount = true // Updated to set isCreatingAccount
                    showNoAccountModal = false
                    onComplete(true) // Trigger onComplete
                }) {
                    Text("Create account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button(action: {
                    showNoAccountModal = false
                }) {
                    Text("Dismiss")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
            .presentationDetents([.fraction(0.4)])
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showAccountExistsModal) { // New sheet for account exists during creation
            VStack(spacing: 32) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width:90, height: 90)
                    .foregroundColor(.green)
                
                VStack(spacing: 8) {
                    Text("Account already exists!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                    
                    Text("We found an existing account with this phone number. You've been logged in successfully.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                Button(action: {
                    showAccountExistsModal = false
                    onComplete(true) // Navigate to home
                }) {
                    Text("Continue to Home")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
            .presentationDetents([.fraction(0.5)])
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showLoginSuccessModal) { // New sheet for successful login
            VStack(spacing: 32) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width:90, height: 90)
                    .foregroundColor(.green)
                
                VStack(spacing: 8) {
                    Text("Welcome back!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                    
                    Text("You've been successfully logged in.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                Button(action: {
                    showLoginSuccessModal = false
                    onComplete(true) // Navigate to home
                }) {
                    Text("Continue to Home")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
            .presentationDetents([.fraction(0.45)])
            .interactiveDismissDisabled()
        }
    }
    
    // Verify OTP code
    private func verifyOTP() {
        isLoading = true
        errorMessage = nil
        
        let otpCode = otpFields.joined()
        
        // Get verification ID from service
        if let verificationID = firebaseService.verificationID {
            // Direct phonesignin3 approach
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: otpCode
            )
            
            // Remove [weak self] since this is a struct (error fix)
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    isLoading = false
                    let message = error.localizedDescription
                    errorMessage = message

                    if message.localizedCaseInsensitiveContains("code") || message.localizedCaseInsensitiveContains("verification") {
                        showErrorModal = true
                    }
                    return
                }
                
                // Authentication successful, now check if user exists
                guard let currentUser = authResult?.user else {
                    isLoading = false
                    errorMessage = "Failed to get user information"
                    return
                }
                
                // Use loadUser to check if profile exists
                firebaseService.loadUser(uid: currentUser.uid) { exists in
                    isLoading = false
                    
                    if exists {
                        // User exists
                        if isCreatingAccount {
                            // User tried to create account but already exists
                            showAccountExistsModal = true
                        } else {
                            // Normal login success
                            showLoginSuccessModal = true
                        }
                    } else {
                        // User doesn't exist
                        if isCreatingAccount {
                            // Continue with account creation
                            onComplete(true)
                        } else {
                            // Tried to login but no account
                            showNoAccountModal = true
                        }
                    }
                }
            }
        } else {
            // Fallback to original approach if no verification ID found
            errorMessage = "Verification ID not found. Please try again."
            isLoading = false
        }
    }
    
    // Check if OTP is complete
    private func isOtpComplete() -> Bool {
        return otpFields.allSatisfy { $0.count == 1 }
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
    
    // Resend verification code
    private func resendCode() {
        isLoading = true
        errorMessage = nil
        
        // Using the approach from phonesignin3
        // Remove [weak self] since this is a struct (error fix)
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
                showErrorModal = true
                return
            }
            
            guard let verificationID = verificationID else {
                errorMessage = "Verification ID not received"
                return
            }
            
            // Store verification ID in service
            firebaseService.verificationID = verificationID
            
            // Reset fields and countdown
            otpFields = Array(repeating: "", count: otpFields.count)
            resetCountdown()
            focusedField = 0
        }
    }
}

#Preview {
    OTPVerificationView(phoneNumber: "+15712140016", isCreatingAccount: .constant(false)) { success in
        print("OTP completed: \(success)")
    }
}
