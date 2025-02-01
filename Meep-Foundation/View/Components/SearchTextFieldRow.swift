//
//  SearchTextFieldRow.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/1/25.
//


import SwiftUI

struct SearchTextFieldRow: View {
    let leadingIcon: String
    let title: String
    let placeholder: String
    let trailingIcon: String
    @Binding var text: String
    let isDirty: Bool
    let onTrailingIconTap: () -> Void

    var body: some View {

            HStack(spacing: 16) {
                
                Image(systemName: leadingIcon)
                    .foregroundColor(isDirty ?  .blue : Color(.label).opacity(0.4)  )
                    .font(.headline)
                    .padding(.leading, 16)

                ZStack(alignment: .leading) {
                    TextField(placeholder, text: $text)
                        .foregroundColor(.primary)
                        .frame(height: 50, alignment: .leading)
                        .offset(y:2)
                        .padding(.vertical, 16)
                        .zIndex(1)
                    Text(title)
                        .font(.caption)
                        .fontWidth(.expanded)
                        .foregroundColor(Color(.darkGray))
                        .offset(y:-20)
                        .frame(alignment: .leading)
                }
                Button(action: {
                    onTrailingIconTap()
                }) {
                    
                    Image(systemName: trailingIcon)
                        .foregroundColor( Color(.label).opacity(0.4))
                        .font(.headline)
                        .padding(.trailing, 16)
                }
            }

    }
}
