//
//  FilterBarView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//


import SwiftUI

struct FilterBarView: View {
    @Binding var selectedCategory: String
    let categories: [String]
    let hiddenCategories: [String]

    @State private var showMore: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.1))
                            .foregroundColor(selectedCategory == category ? .white : .black)
                            .cornerRadius(8)
                    }
                }

                // "More" Button
                Button(action: {
                    showMore = true
                }) {
                    Text("More")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showMore) {
            MoreCategoriesView(
                hiddenCategories: hiddenCategories,
                selectedCategory: $selectedCategory,
                showMore: $showMore
            )
        }
    }
}

#Preview {
    FilterBarView(
        selectedCategory: .constant("All"), // Use .constant() for Binding
        categories: ["All", "Park", "Cafe", "Museum"],
        hiddenCategories: ["Restaurant", "Gym", "Library"]
    )
}

