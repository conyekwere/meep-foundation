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
                    ZStack {
                        // A background blur, if desired
//                        VisualEffectBlur(blurStyle: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
//                            .cornerRadius(16)
//                            .ignoresSafeArea(edges: .bottom)
                        
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
                           ScrollView(.vertical, showsIndicators: false) {
                               VStack(spacing: 24) {
                                   if viewModel.meetingPoints.isEmpty {
                                       // Show 3 skeleton loaders while data is being fetched
                                       ForEach(0..<3, id: \.self) { _ in
                                           SkeletonMeetingPointCard()
                                       }
                                   } else {
                                       ForEach(viewModel.meetingPoints.filter {
                                           viewModel.selectedCategory.name == "All" || $0.category == viewModel.selectedCategory.name
                                       }, id: \.id) { point in
                                           MeetingPointCard(point: point) {
                                               viewModel.showDirections(to: point)
                                           }
                                           .frame(maxWidth: UIScreen.main.bounds.width * 0.95)
                                       }
                                   }
                               }
                               .frame(maxWidth: .infinity)
                           }
                           .padding(.bottom, 20)
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
