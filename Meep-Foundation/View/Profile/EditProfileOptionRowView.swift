//
//  EditProfileOptionRowView.swift
//  syce-foundation
//
//  Created by Chima onyekwere on 5/13/24.
//

import SwiftUI

struct EditProfileOptionRowView: View {
    let option: EditProfileOptions
    let value: String
    var body: some View {
        NavigationLink(value: option){
            
            Text(option.title)
            Spacer()
            Text(value)
        }
    }
}


#Preview {
    EditProfileOptionRowView(option: .bio, value: "enter your Bio")
}