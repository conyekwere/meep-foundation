//
//  termsAndPrivacyText.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/2/25.
//

import SwiftUI
import FirebaseAuth

struct TermsAndPrivacyText: View {
    var body: some View {
        VStack {
            Text("By tapping 'Sign in' / 'Create account' you agree to our")
                .font(.footnote)
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                Text("Terms")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .onTapGesture {
                        if let url = URL(string: "https://meep.earth/#/terms") {
                            UIApplication.shared.open(url)
                        }
                    }

                Text("and")
                    .font(.footnote)

                Text("Privacy Policy")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .onTapGesture {
                        if let url = URL(string: "https://meep.earth/#/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }
            }
        }
        .multilineTextAlignment(.center)
    }
}
