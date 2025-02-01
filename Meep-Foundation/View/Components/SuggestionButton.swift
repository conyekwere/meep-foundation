//
//  SuggestionButton.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/1/25.
//

import SwiftUI

struct SuggestionButton: View {
    let icon: String
    let title: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundColor(.blue)
                 
                    .foregroundColor(Color(.gray))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "E8F0FE"))
                    .clipShape(Circle())
                   
                if title.isEmpty{
                    Text(label)
                        .font(.callout)
                        .foregroundColor(.primary)
                }
                else{
                    VStack(alignment: .leading) {
                        Text(label)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text(title)
                            .font(.callout)
                            .foregroundColor(Color(.darkGray))
                    }
                }
                
            }
        }
    }
}
