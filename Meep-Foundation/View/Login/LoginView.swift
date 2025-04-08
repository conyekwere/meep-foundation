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
    
    // Navigation states
    @State private var showPhoneVerification = true
    
    // Whether this is for account creation or just login
    var createAccount: Bool = false
    
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
            
            
           
            // Content layer
            ZStack {
                if showPhoneVerification {
                    VStack {
                        // Custom back button
                        HStack {

                            Button(action: {
                                onDismiss(false)
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
                        PhoneVerificationView(
                            isCreatingAccount: createAccount,
                            onComplete: { success in
                                if success {
                                    onDismiss(true)
                                }
                            }
                        )
                        .environmentObject(ThemeSettings(disableBackgrounds: true))
                    }
                }
            }
        }
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
    })
}
