//
//  EditProfileDetailView.swift
//  syce-foundation
//
//  Created by Chima onyekwere on 5/13/24.
//

import SwiftUI

struct EditProfileDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var value = ""
    let option: EditProfileOptions
    let user:User
    var body: some View {
        VStack(alignment:.leading) {
           
            HStack {
                TextField("Add your bio", text: $value)
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
        case .name: "Your full name can only be chnaged once every 7 days"
        case .username: "Usernames can contain only letters, numbers, underscores and periods"
        case .bio: "Tell us a little bit about yourself"
        }
    }
    
    
    func onViewAppear() {
        switch option {
            
        case .name: value = user.fullname
            
        case .username: value = user.username
            
        case .bio: value = user.bio  ?? ""
            
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileDetailView(option: .bio,user: DeveloperPreview.user)
            .tint(.primary)
    }
}