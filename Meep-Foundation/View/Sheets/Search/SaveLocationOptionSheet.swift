//
//  SaveLocationOptionSheet.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/28/25.
//
import SwiftUI
import CoreLocation

struct SaveLocationOptionSheet: View {
    let address: String
    var onSaveHome: () -> Void
    var onSaveWork: () -> Void
    var onSaveCustom: (String) -> Void
    var onCancel: () -> Void
    
    @State private var customName: String = ""
    @State private var showCustomField: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Save Location")
                .font(.headline)
                .fontWeight(.semibold)
                .fontWidth(.expanded)
                .padding(.top, 16)
            
            // Address display
            Text(address)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Save options
            VStack(spacing: 16) {
                Button(action: onSaveHome) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.blue)
                        Text("Save as Home")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Button(action: onSaveWork) {
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .foregroundColor(.blue)
                        Text("Save as Work")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    showCustomField = true
                }) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text("Save as Custom Location")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                if showCustomField {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g. Gym, Friend's house", text: $customName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .onAppear {
                                // Request focus when the field appears
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                                }
                            }
                        
                        Button(action: {
                            onSaveCustom(customName)
                        }) {
                            Text("Save")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(customName.isEmpty ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(customName.isEmpty)
                    }
                }
            }
            .padding(.horizontal)
            
            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
//
//#Preview {
//    SaveLocationOptionSheet(
//        address: "123 Main St, New York, NY 10001",
//        onSaveHome: {},
//        onSaveWork: {},
//        onSaveCustom: { _ in },
//        onCancel: {}
//    )
//}
