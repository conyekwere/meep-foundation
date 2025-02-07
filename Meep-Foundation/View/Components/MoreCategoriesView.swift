//
//  MoreCategoriesView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//
import SwiftUI

struct MoreCategoriesView: View {
    let hiddenCategories: [Category]
    @Binding var selectedCategory: Category
    @Binding var showMore: Bool

    // Compute if selectedCategory is from hiddenCategories
    var isHiddenCategorySelected: Bool {
        hiddenCategories.contains(where: { $0 == selectedCategory })
    }

    var body: some View {
        Menu {
            ForEach(hiddenCategories) { category in
                Button(action: {
                    selectedCategory = category
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
        } label: {
            HStack {
                if isHiddenCategorySelected {
                    Text("\(selectedCategory.emoji) \(selectedCategory.name)")
                        .foregroundColor(Color(.label).opacity(0.8))
                        .fontWidth(.expanded)
                        .font(.body)
                    
                    Image(systemName: "chevron.down")
                        .font(.footnote)
                    
                } else {
                    Text("More")
                        .foregroundColor(Color(.label).opacity(0.8))
                        .fontWidth(.expanded)
                        .font(.body)
                    
                }
            }
            .frame(minWidth: 32)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isHiddenCategorySelected ? Color.gray.opacity(0.1) : Color.white) // Selected state styling
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
        }
    }
}


#Preview {
    @State var selectedCategory = Category(emoji: "🎨", name: "Museum", hidden: true)
    @State var showMore = false
    
    return MoreCategoriesView(
        hiddenCategories: [
            Category(emoji: "🎨", name: "Museum", hidden: true),
            Category(emoji: "🏋️", name: "Gym", hidden: true),
            Category(emoji: "📚", name: "Library", hidden: true)
        ],
        selectedCategory: $selectedCategory,
        showMore: $showMore
    )
}
