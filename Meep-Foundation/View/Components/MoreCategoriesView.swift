//
//  MoreCategoriesView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import SwiftUI

struct MoreCategoriesView: View {
    let hiddenCategories: [Category] // ✅ Updated to accept Category objects
    @Binding var selectedCategory: Category
    @Binding var showMore: Bool

    var body: some View {
        NavigationView {
            List(hiddenCategories) { category in
                Button(action: {
                    selectedCategory = category
                    showMore = false
                }) {
                    HStack {
                        Text("\(category.emoji) \(category.name)") // ✅ Show emoji and name
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
