//
//  FilterBarView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import SwiftUI

struct FilterBarView: View {
    @Binding var selectedCategory: Category
    let categories: [Category]
    let hiddenCategories: [Category]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Visible Categories
                ForEach(categories) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        HStack(spacing: 4) {
                            if !category.emoji.isEmpty {
                                Text(category.emoji)
                                    .font(.body)
                            }

                            Text(category.name)
                                .font(.body)
                                .foregroundColor(Color(.label).opacity(0.8))
                                .fontWidth(.expanded)
                        }
                        .frame(minWidth: 36, maxWidth: 180)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(selectedCategory == category ? Color.gray.opacity(0.1) : Color.white)
                        .foregroundColor(selectedCategory == category ? Color(.label) : .black)
                        .fontWeight(selectedCategory == category ? .medium : .regular)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                // "More" Button - Now Reflects Selected Hidden Category
                MoreCategoriesView(
                    hiddenCategories: hiddenCategories,
                    selectedCategory: $selectedCategory,
                    showMore: .constant(false)
                )
            }
            .padding(.horizontal)
        }
    }
}



#Preview {
    FilterBarView(
        selectedCategory: .constant(Category(emoji: "", name: "All", hidden: false)), // Updated to use Category type
        categories: [
            Category(emoji: "", name: "All", hidden: false),
            Category(emoji: "🍴", name: "Restaurant", hidden: false),
            Category(emoji: "🍺", name: "Bar", hidden: false),
            Category(emoji: "🌳", name: "Park", hidden: false),
            Category(emoji: "☕", name: "Coffee shop", hidden: false),
        ],
        hiddenCategories: [
            Category(emoji: "✈️", name: "Airport", hidden: true),
            Category(emoji: "🍞", name: "Bakery", hidden: true),
            Category(emoji: "🏖", name: "Beach", hidden: true),
            Category(emoji: "🍺", name: "Brewery", hidden: true),
            Category(emoji: "🏋️", name: "Gym", hidden: true),
            Category(emoji: "🍎", name: "Groceries", hidden: true),
            Category(emoji: "🏨", name: "Hotel", hidden: true),
            Category(emoji: "📚", name: "Library", hidden: true),
            Category(emoji: "🎭", name: "Theater", hidden: true),
            Category(emoji: "🎨", name: "Museum", hidden: true),
            Category(emoji: "🏞", name: "National Park", hidden: true),
            Category(emoji: "🪩", name: "Nightlife", hidden: true),
            Category(emoji: "🚉", name: "Public Transport", hidden: true),
            Category(emoji: "🏟", name: "Stadium", hidden: true),
            Category(emoji: "🎭", name: "Theater", hidden: true),
            Category(emoji: "🎓", name: "University", hidden: true),
            Category(emoji: "🍷", name: "Winery", hidden: true),
            Category(emoji: "🦁", name: "Zoo", hidden: true),
        ]
    )
}
