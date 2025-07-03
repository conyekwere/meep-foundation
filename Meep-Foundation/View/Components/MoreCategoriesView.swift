//
//  MoreCategoriesView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import SwiftUI

struct MoreCategoriesSheetView: View {
    let hiddenCategories: [Category]
    @Binding var selectedCategory: Category

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(hiddenCategories) { category in
                Button(action: {
                    selectedCategory = category
                    dismiss()
                }) {
                    HStack {
                        Text("\(category.emoji) \(category.name)")
                        Spacer()
                        if selectedCategory == category {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("More Categories")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    @State var selectedCategory = Category(emoji: "🎨", name: "Museum", hidden: true)
    return MoreCategoriesSheetView(
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
        ],
        selectedCategory: $selectedCategory
    )
}
