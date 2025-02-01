//
//  MoreCategoriesView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//


import SwiftUI

struct MoreCategoriesView: View {
    let hiddenCategories: [String]
    @Binding var selectedCategory: String
    @Binding var showMore: Bool

    var body: some View {
        NavigationView {
            List(hiddenCategories, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                    showMore = false
                }) {
                    HStack {
                        Text(category)
                        Spacer()
                        if selectedCategory == category {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("More Categories")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showMore = false
                    }
                }
            }
        }
    }
}
