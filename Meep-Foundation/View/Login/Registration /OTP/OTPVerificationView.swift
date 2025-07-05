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
        .sheet(isPresented: $showNoAccountModal) { // New sheet for no account modal
            VStack(spacing: 32) {
                Text("No account found for this phone number.")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()

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
                isLoading = false
                
                if let error = error {
                    let message = error.localizedDescription
                    errorMessage = message

                    if message.localizedCaseInsensitiveContains("code") || message.localizedCaseInsensitiveContains("verification") {
                        showErrorModal = true
                    }
                    return
                }
                
                guard let user = authResult?.user else {
                    errorMessage = "Authentication failed. Please try again."
                    return
                }

                // Assign user to firebaseService.meepUser if needed
                firebaseService.currentUser = user

                // Continue flow regardless of currentUser state
                onComplete(true)
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
