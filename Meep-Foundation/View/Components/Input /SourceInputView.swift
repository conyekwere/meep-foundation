//
//  SourceInputView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 4/4/25.
//


import SwiftUI

struct SourceInputView: View {
    @Binding var sourceText: String
    var onSubmit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            TextField("Search", text: $sourceText)
                .padding(.vertical, 10)
                .onSubmit(onSubmit)
            
            if !sourceText.isEmpty {
                Button(action: {
                    sourceText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    SourceInputView(sourceText: .constant(""), onSubmit: {})
        .previewLayout(.sizeThatFits)
        .padding()
}