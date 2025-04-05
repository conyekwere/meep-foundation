//
//  LoginView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.
//
//
//  LoginView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.
//
import SwiftUI
import FirebaseAuth

struct LoginView: View {
    // Environment
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    // Callback when login/registration is complete
    var onDismiss: (Bool) -> Void
    
    // Navigation states
    @State private var showPhoneVerification = true
    
    // Whether this is for account creation or just login
    var createAccount: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                backgroundGradient
                
                // Show the appropriate view based on navigation state
                if showPhoneVerification {
                    PhoneVerificationView(
                        isCreatingAccount: createAccount,
                        onComplete: { success in
                            if success {
                                onDismiss(true)
                            }
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        onDismiss(false)
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(12)
                            .frame(width: 40, height: 40)
                            .background(Color(.lightGray).opacity(0.1))
                            .foregroundColor(.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color(.systemGray6), lineWidth: 2)
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // Background gradient
    private var backgroundGradient: some View {
        ZStack {
            Color(#colorLiteral(red: 0.0470588244497776, green: 0.09803921729326248, blue: 0.26274511218070984, alpha: 0.20000000298023224)).opacity(0.2)
            Color(#colorLiteral(red: 1, green: 0.364705890417099, blue: 0.20392157137393951, alpha: 0.20000000298023224)).opacity(0.2)
            VisualEffectBlur(blurStyle: colorScheme == .dark ? .systemUltraThinMaterialLight : .systemUltraThinMaterialDark)
        }
        .edgesIgnoringSafeArea(.all)
    }
}





// MARK: - Registration Info View

struct RegistrationInfoView: View {
    // Properties
    var phoneNumber: String
    
    // State
    @State private var fullName = ""
    @State private var email = ""
    @State private var username = ""
    @State private var showEmailVerification = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Focus state
    @FocusState private var currentField: Field?
    
    enum Field {
        case name, email, username
    }
    
    // Firebase service
    @StateObject private var firebaseService = FirebaseService.shared
    
    // Callback when registration is complete
    var onComplete: (Bool) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Complete Your Profile")
                        .font(.title)
                        .fontWeight(.bold)
                        .fontWidth(.expanded)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("Just a few more details to get you started")
                        .font(.body)
                        .foregroundColor(Color(.gray))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 40)
                
                // Error message if any
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // Form fields
                VStack(spacing: 20) {
                    // Full Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("John Smith", text: $fullName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .focused($currentField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit {
                                currentField = .email
                            }
                    }
                    .padding(.horizontal)
                    
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("email@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .focused($currentField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit {
                                currentField = .username
                            }
                    }
                    .padding(.horizontal)
                    
                    // Username
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("johnsmith", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .focused($currentField, equals: .username)
                            .submitLabel(.done)
                            .onChange(of: username) { newValue in
                                username = formatUsername(newValue)
                            }
                    }
                    .padding(.horizontal)
                }
                
                // Continue button
                Button(action: completeRegistration) {
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
                .padding(.top, 24)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentField = .name
            }
        }
    }
    
    // Form validation
    private var isFormValid: Bool {
        return !fullName.isEmpty && isValidEmail(email) && !username.isEmpty
    }
    
    // Email validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // Username formatting
    private func formatUsername(_ input: String) -> String {
        // Allow only alphanumeric characters and underscores
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
        return input.components(separatedBy: allowedCharacters.inverted).joined()
    }
    
    // Complete registration
    private func completeRegistration() {
        isLoading = true
        errorMessage = nil
        
        // Validate username format
        if username.isEmpty || username.count < 3 {
            errorMessage = "Username must be at least 3 characters long"
            isLoading = false
            return
        }
        
        // Create user profile
        firebaseService.createUserProfile(
            fullName: fullName,
            email: email,
            username: username
        ) { success, error in
            isLoading = false
            
            if success {
                // Registration successful
                onComplete(true)
            } else if let error = error {
                errorMessage = error
            }
        }
    }
}

