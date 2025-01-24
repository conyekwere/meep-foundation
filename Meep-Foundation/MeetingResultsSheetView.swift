//
//  MeetingResultsSheetView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/22/25.
//


import SwiftUI

struct MeetingResultsSheetView: View {
    @ObservedObject var viewModel: MeepViewModel
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        ZStack{
            VisualEffectBlur(blurStyle: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
                .cornerRadius(16)
                .ignoresSafeArea(edges: .bottom)
            
        VStack(spacing: 16) {
            
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(Color(.lightGray).opacity(0.4))
            
            // Filter Bar
            FilterBarView(
                selectedCategory: $viewModel.selectedCategory,
                categories: viewModel.categories,
                hiddenCategories: viewModel.hiddenCategories
            )
            .padding(.horizontal)
            
            // Meeting Points List
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.meetingPoints.filter {
                        viewModel.selectedCategory == "All" || $0.category == viewModel.selectedCategory
                    }, id: \.id) { point in
                        VStack(alignment: .leading, spacing: 8) {
                            Image("placeholder-image") // Replace with point image
                                .resizable()
                                .frame(height: 200)
                                .cornerRadius(12)
                            Text(point.name)
                                .font(.headline)
                            HStack {
                                Text(point.category)
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                Spacer()
                                Text("\(point.distance, specifier: "%.2f") miles away")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Button(action: {
                                // Handle directions logic
                            }) {
                                Text("Get Directions")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
        .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    MeetingResultsSheetView(viewModel: MeepViewModel())
        .previewLayout(.sizeThatFits)
}
