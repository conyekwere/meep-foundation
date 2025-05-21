//
//  EditProfileOptionRowView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 5/16/25.
//

import SwiftUI

struct EditProfileOptionRowView: View {
    let option: EditProfileOptions
    let value: String
    var body: some View {
        NavigationLink(value: option){
            
            Text(option.title)
                .foregroundStyle(Color.primary)
                
            Spacer()
            Text(value)
                .foregroundStyle(Color.primary)
                
        }
    }
}


#Preview {
    EditProfileOptionRowView(option: .bio, value: "enter your Bio")
}
