//
//  OTPVerificationView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/6/25.
//


import SwiftUI

struct OTPVerificationView: View {
    // Properties
    var phoneNumber: String
    var isCreatingAccount: Bool = false
    
    // State
    @State private var otpFields = Array(repeating: "", count: 4)
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var countdown = 15 // Changed from 30 to 15 to match Syce style
    @State private var isCountdownFinished = false
    @State private var showRegistration = false
    
    // Environment
    @Environment(\.colorScheme) var colorScheme
    
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
                            .font(.headline)
                            .fontWeight(.medium)
                            .fontWidth(.expanded)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .lineSpacing(16)
                        
                        Text("on \(phoneNumber)")
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
                    
                    Spacer()
                    
                    // Continue button
                    if isOtpComplete() {
                        Button(action: verifyOTP) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                                    .padding(.horizontal)
                            } else {
                                Text("Continue")
                                    .font(.headline)
                                    .foregroundColor(Color(UIColor.systemBackground))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                                    .padding(.horizontal)
                            }
                        }
                        .disabled(isLoading)
                        .padding(.top, 24)
                        .padding(.bottom, 48)
                        .accessibilityLabel("Continue to next section")
                    } else {
                        if isCountdownFinished {
                            Button(action: resendCode) {
                                Text("Send New Code")
                                    .font(.headline)
                                    .foregroundColor(Color(UIColor.systemBackground))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                                    .padding(.horizontal)
                            }
                            .padding(.bottom, 48)
                            .accessibilityLabel("Resend the OTP code")
                        } else {
                            Text("You can ask for a new code in \(countdown) seconds.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2.0)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 48)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                startCountdown()
                focusedField = 0
            }
            .background(
                ZStack {
                    Color(#colorLiteral(red: 0.0470588244497776, green: 0.09803921729326248, blue: 0.26274511218070984, alpha: 0.20000000298023224)).opacity(0.2)
                    Color(#colorLiteral(red: 1, green: 0.364705890417099, blue: 0.20392157137393951, alpha: 0.20000000298023224)).opacity(0.2)
                    VisualEffectBlur(blurStyle: colorScheme == .dark ? .systemUltraThinMaterialLight : .systemUltraThinMaterialDark)
                }
            )
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
        countdown = 15 // Changed from 30 to 15 to match Syce style
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
