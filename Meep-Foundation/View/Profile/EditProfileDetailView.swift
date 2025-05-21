//
//  EditProfileDetailView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 5/17/25.
//

import SwiftUI

struct EditProfileDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var value = ""
    let option: EditProfileOptions
    let user: MeepUser
    var body: some View {
        VStack(alignment:.leading) {
           
            HStack {
                TextField("Add your information", text: $value)
                Spacer()
                if !value.isEmpty {
                    Button {
                        value = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            Divider()
            Text("Tell us a little bit about yourself")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top,8)
            Spacer()
            
        }
        .padding()
        .navigationTitle(option.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onAppear{onViewAppear()}
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel"){ dismiss()}
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save"){ dismiss()}
            }
        }
    }
    
}

private extension EditProfileDetailView{
    var navigationTitle:String {
        switch option{
        case .name:
            return "Your full name can only be changed once every 7 days"
        case .username:
            return "Usernames can contain only letters, numbers, underscores and periods"
        @unknown default:
            return ""
        }
    }
    
    
    func onViewAppear() {
        switch option {
            
        case .name:
            value = user.displayName
            
        case .username:
            value = user.username
            
        @unknown default:
            value = ""
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileDetailView(option: .name,user: DeveloperPreview.meepUser)
            .tint(.primary)
    }
}
