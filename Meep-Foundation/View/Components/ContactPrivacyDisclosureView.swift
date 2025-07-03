//
//  ContactPrivacyDisclosureView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/17/25.
//

import SwiftUI


struct ContactPrivacyDisclosureView: View {
    @Binding var showDisclosure: Bool
    var onAllow: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Contact Access")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("Easily invite friends to meet up")
                        .font(.body)
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("Contact information is never stored on our servers")
                        .font(.body)
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    Text("Only accessed when you choose to send invitations")
                        .font(.body)
                }
            }
            
            Text("We respect your privacy. Contacts are only used for invitations and never shared with third parties.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("View Privacy Policy") {
                if let url = URL(string: "https://meep.earth/#/privacy") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.caption)
            .foregroundColor(.blue)

            VStack(spacing: 12) {
                Button("Allow Contact Access") {
                    showDisclosure = false
                    onAllow()
                }
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green)
                .cornerRadius(10)

                Button("Not Now") {
                    showDisclosure = false
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
}

