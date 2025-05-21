//
//  LoginView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.



import SwiftUI
import FirebaseAuth

struct LoginView: View {
    // Environment
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    // Callback when login/registration is complete
    var onDismiss: (Bool) -> Void
    
    // Whether this is for account creation or just login
    @Binding var createAccount: Bool
    
    enum AuthStep {
        case phone
        case otp
        case registerFullName, registerDob, registerGender, registerUsername, registerEmail, registerPhoto, locationAccess, registrationComplete
    }
    
    @State private var step: AuthStep = .phone
    @State private var verifiedPhoneNumber: String = ""
    
    // State
    @State private var fullName = ""
    @State private var email = ""
    @State private var username = ""
    @State private var dateOfBirth = ""
    @State private var gender = ""
    @State private var showEmailVerification = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var profileImageUrl: String = ""

    private var progressBarWidth: CGFloat {
        let steps: [AuthStep] = [
            .phone, .otp, .registerFullName, .registerDob, .registerGender,
            .registerUsername, .registerEmail, .registerPhoto, .locationAccess, .registrationComplete
        ]
        guard let currentIndex = steps.firstIndex(of: step) else { return 0 }
        return UIScreen.main.bounds.width * CGFloat(currentIndex + 1) / CGFloat(steps.count)
    }
    
    // Firebase service
    @StateObject private var firebaseService = FirebaseService.shared
    
    @ObservedObject var viewModel: MeepViewModel
    
    var body: some View {
        ZStack {
            
            Image("blur-background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
                .opacity(0.3)
            
            // First layer: Dark blur effect
            VisualEffectBlur(blurStyle: .systemThinMaterialDark)
                .edgesIgnoringSafeArea(.all)

            // Second layer: Gradient background
            
            if step != .registrationComplete {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(#colorLiteral(red: 0.1019607843, green: 0.1254901961, blue: 0.1882352941, alpha: 1.0)),
                        Color(#colorLiteral(red: 0.0470588244497776, green: 0.09803921729326248, blue: 0.26274511218070984, alpha: 1.0))
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(#colorLiteral(red: 0.1541360021, green: 0.1520293355, blue: 0.03064562194, alpha: 1)),
                        Color(#colorLiteral(red: 0.9868736863, green: 0.9987526536, blue: 0.1394103169, alpha: 1))
                      
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.15)
                .edgesIgnoringSafeArea(.all)
            }
            
            
            // Content layer
            ZStack {
                VStack {
                    // Progress bar at the top
                    
                    if createAccount || step != .registrationComplete {
                        
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 4)
                                    .overlay(
                                        Capsule()
                                            .fill(Color.white)
                                            .frame(width: progressBarWidth / 2, height: 4),
                                        alignment: .leading
                                    )
                                Spacer()
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 60)
                        }
                    }
                    
                    // Custom back button
                    HStack {
                        Button(action: {
                            let allSteps: [AuthStep] = [
                                .phone, .otp, .registerFullName, .registerDob, .registerGender,
                                .registerUsername, .registerEmail, .registerPhoto, .locationAccess, .registrationComplete
                            ]
                            if let currentIndex = allSteps.firstIndex(of: step), currentIndex > 0 {
                                step = allSteps[currentIndex - 1]
                            } else {
                                onDismiss(false)
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 12, height: 12)
                                .padding(14)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Main content
                    switch step {
                    case .phone:

                        
                        
                        PhoneVerificationView(
                            isCreatingAccount: createAccount,
                            onComplete: { verified, formattedPhoneNumber in
                                if verified {
                                    self.verifiedPhoneNumber = formattedPhoneNumber
                                    step = .otp
                                }
                            }
                        )
                        .environmentObject(ThemeSettings(disableBackgrounds: true))

                    case .otp:
                        OTPVerificationView(
                            phoneNumber: verifiedPhoneNumber,
                            isCreatingAccount: $createAccount
                        ) { success in
                            if success {
                                if createAccount {
                                    step = .registerFullName
                                } else {
                                    onDismiss(true)
                                }
                            }
                        }
                        .environmentObject(ThemeSettings(disableBackgrounds: true))

                    case .registerFullName:
                        RegistrationFullNameInputView(fullName: $fullName, onContinue: { step = .registerDob })

                    case .registerDob:
                        RegistrationDobInputView(dateOfBirth: $dateOfBirth, onContinue: { step = .registerGender })

                    case .registerGender:
                        RegistrationGenderInputView(gender: $gender, onContinue: { step = .registerUsername })

                    case .registerUsername:
                        RegistrationUsernameInputView(username: $username, onContinue: { step = .registerEmail })

                    case .registerEmail:
                        RegistrationEmailInputView(email: $email, onContinue: { step = .registerPhoto })

                    case .registerPhoto:
                        RegistrationAddProfilePhotoView(onContinue: { image in
                            Task {
                                if let url = try? await ImageUploadService().uploadImage(image: image) {
                                    profileImageUrl = url
                                    step = .locationAccess
                                } else {
                                    errorMessage = "Failed to upload profile image"
                                }
                            }
                        }, fullName: fullName)
                    case .locationAccess:
                        LocationPermissionView(onContinue: {
                            viewModel.requestUserLocation()
                            
                            step = .registrationComplete
                        },fullName: fullName)
                    
                    case .registrationComplete:
                        CelebrationScreenView(onComplete: {
                            Task {
                                completeRegistration(profileImageUrl: profileImageUrl)
                                onDismiss(true)
                            }
                        })
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }
    
    private func completeRegistration(profileImageUrl: String) {
        isLoading = true
        errorMessage = nil
        
        let phoneNumber = firebaseService.currentUser?.phoneNumber ?? ""
        
        // Create user profile
        firebaseService.createUserProfile(
            fullName: fullName,
            email: email,
            username: username,
            phoneNumber: phoneNumber,
            profileImageUrl: profileImageUrl,
            gender: gender,
            dateOfBirth: dateOfBirth,
            completion: { success, error in
                isLoading = false
                if success {
                    // Registration successful
                    onDismiss(true)
                } else if let error = error {
                    errorMessage = error
                }
            }
        )
    }
    
}

// Add this to your project to manage theme settings
class ThemeSettings: ObservableObject {
    @Published var disableBackgrounds: Bool = false
    
    init(disableBackgrounds: Bool = false) {
        self.disableBackgrounds = disableBackgrounds
    }
}

#Preview {
    LoginView(onDismiss: { success in
        print("Login completed: \(success)")
    }, createAccount: .constant(false), viewModel: MeepViewModel())

}
