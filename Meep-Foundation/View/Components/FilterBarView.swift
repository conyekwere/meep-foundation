//
//  FilterBarView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import SwiftUI
import PostHog

struct FilterBarView: View {
    @Binding var selectedCategory: Category
    let categories: [Category]
    let hiddenCategories: [Category]
    @State private var showMoreSheet = false

    @State private var showWeatherAlert: Bool = false
    @State private var showPeakAlert: Bool = false
    @State private var showHappyHourAlert: Bool = false

    @State private var showWeatherBucket: Bool = false
    @State private var showPeakBucket: Bool = false
    @State private var showHappyBucket: Bool = false

    private let weatherFlagKey = "fake_door_weather_flag"
    private let peakFlagKey = "fake_door_peak_hours_flag"
    private let happyFlagKey = "fake_door_happy_hour_flag"

    // Additional fake-door filters
    @State private var showOpenLateAlert: Bool = false
    @State private var showQuietAlert: Bool = false
    @State private var showBudgetAlert: Bool = false

    @State private var showOpenLateBucket: Bool = false
    @State private var showQuietBucket: Bool = false
    @State private var showBudgetBucket: Bool = false

    private let openLateFlagKey = "fake_door_open_late_flag"
    private let quietFlagKey = "fake_door_quiet_spaces_flag"
    private let budgetFlagKey = "fake_door_budget_friendly_flag"

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Visible Categories with fake-door buttons injected after first real chip
                ForEach(Array(categories.enumerated()), id: \.element.id) { idx, category in
                    // Real category chip
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

                    // Inject fake-door chips after the first real chip
                    if idx == 0 {
                        if showWeatherBucket {
                            Button(action: {
                                PostHogSDK.shared.capture("fake_door_filter_weather_clicked")
                                showWeatherAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("🌧️").font(.body)
                                    Text("Weather")
                                        .font(.body)
                                        .foregroundColor(Color(.label).opacity(0.8))
                                        .fontWidth(.expanded)
                                }
                                .frame(minWidth: 36, maxWidth: 180)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .fontWeight(.regular)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        if showPeakBucket {
                            Button(action: {
                                PostHogSDK.shared.capture("fake_door_filter_peak_clicked")
                                showPeakAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("⏰").font(.body)
                                    Text("Avoid Peak Hours")
                                        .font(.body)
                                        .foregroundColor(Color(.label).opacity(0.8))
                                        .fontWidth(.expanded)
                                }
                                .frame(minWidth: 36, maxWidth: 180)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .fontWeight(.regular)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        if showHappyBucket {
                            Button(action: {
                                PostHogSDK.shared.capture("fake_door_filter_happy_clicked")
                                showHappyHourAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("🍻").font(.body)
                                    Text("Happy hour")
                                        .font(.body)
                                        .foregroundColor(Color(.label).opacity(0.8))
                                        .fontWidth(.expanded)
                                }
                                .frame(minWidth: 36, maxWidth: 180)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .fontWeight(.regular)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        if showOpenLateBucket {
                            Button(action: {
                                PostHogSDK.shared.capture("fake_door_filter_open_late_clicked")
                                showOpenLateAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("🌙").font(.body)
                                    Text("Open Late")
                                        .font(.body)
                                        .foregroundColor(Color(.label).opacity(0.8))
                                        .fontWidth(.expanded)
                                }
                                .frame(minWidth: 36, maxWidth: 180)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .fontWeight(.regular)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        if showQuietBucket {
                            Button(action: {
                                PostHogSDK.shared.capture("fake_door_filter_quiet_spaces_clicked")
                                showQuietAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("🔇").font(.body)
                                    Text("Quiet")
                                        .font(.body)
                                        .foregroundColor(Color(.label).opacity(0.8))
                                        .fontWidth(.expanded)
                                }
                                .frame(minWidth: 36, maxWidth: 180)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .fontWeight(.regular)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        if showBudgetBucket {
                            Button(action: {
                                PostHogSDK.shared.capture("fake_door_filter_budget_friendly_clicked")
                                showBudgetAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("💰").font(.body)
                                    Text("Affordable")
                                        .font(.body)
                                        .foregroundColor(Color(.label).opacity(0.8))
                                        .fontWidth(.expanded)
                                }
                                .frame(minWidth: 36, maxWidth: 180)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .fontWeight(.regular)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }

                Button(action: {
                    showMoreSheet = true
                }) {
                    Text("More")
                        .foregroundColor(Color(.label).opacity(0.8))
                        .fontWidth(.expanded)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                }
                .sheet(isPresented: $showMoreSheet) {
                    MoreCategoriesSheetView(hiddenCategories: hiddenCategories, selectedCategory: $selectedCategory)
                }
            }
        }
        .onAppear {
            showWeatherBucket = PostHogSDK.shared.isFeatureEnabled(weatherFlagKey)
            if showWeatherBucket {
                PostHogSDK.shared.capture("fake_door_filter_weather_exposed")
            }
            showPeakBucket = PostHogSDK.shared.isFeatureEnabled(peakFlagKey)
            if showPeakBucket {
                PostHogSDK.shared.capture("fake_door_filter_peak_hours_exposed")
            }
            showHappyBucket = PostHogSDK.shared.isFeatureEnabled(happyFlagKey)
            if showHappyBucket {
                PostHogSDK.shared.capture("fake_door_filter_happy_hour_exposed")
            }
            showOpenLateBucket = PostHogSDK.shared.isFeatureEnabled(openLateFlagKey)
            if showOpenLateBucket {
                PostHogSDK.shared.capture("fake_door_filter_open_late_exposed")
            }
            showQuietBucket = PostHogSDK.shared.isFeatureEnabled(quietFlagKey)
            if showQuietBucket {
                PostHogSDK.shared.capture("fake_door_filter_quiet_spaces_exposed")
            }
            showBudgetBucket = PostHogSDK.shared.isFeatureEnabled(budgetFlagKey)
            if showBudgetBucket {
                PostHogSDK.shared.capture("fake_door_filter_budget_friendly_exposed")
            }
        }
        .alert("🌧️ Weather", isPresented: $showWeatherAlert) {
            Button("👍 Upvote") { PostHogSDK.shared.capture("fake_door_weather_upvote_clicked") }
            Button("👎 Downvote", role: .destructive) { PostHogSDK.shared.capture("fake_door_weather_downvote_clicked") }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Coming Soon! Upvote if you'd like Weather-Smart Suggestions or downvote if not.")
        }
        .alert("⏰ Avoid Peak Hours", isPresented: $showPeakAlert) {
            Button("👍 Upvote") { PostHogSDK.shared.capture("fake_door_peak_hours_upvote_clicked") }
            Button("👎 Downvote", role: .destructive) { PostHogSDK.shared.capture("fake_door_peak_hours_downvote_clicked") }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Coming Soon! Upvote if you'd like Avoid Peak Hours feature or downvote if not.")
        }
        .alert("🍻 Happy hour", isPresented: $showHappyHourAlert) {
            Button("👍 Upvote") { PostHogSDK.shared.capture("fake_door_happy_hour_upvote_clicked") }
            Button("👎 Downvote", role: .destructive) { PostHogSDK.shared.capture("fake_door_happy_hour_downvote_clicked") }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Coming Soon! Upvote if you'd like Happy Hour filter or downvote if not.")
        }
        .alert("🌙 Open Late", isPresented: $showOpenLateAlert) {
            Button("👍 Upvote") { PostHogSDK.shared.capture("fake_door_open_late_upvote_clicked") }
            Button("👎 Downvote", role: .destructive) { PostHogSDK.shared.capture("fake_door_open_late_downvote_clicked") }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Coming Soon! Upvote if you'd like Open Late filter or downvote if not.")
        }
        .alert("🔇 Quiet", isPresented: $showQuietAlert) {
            Button("👍 Upvote") { PostHogSDK.shared.capture("fake_door_quiet_spaces_upvote_clicked") }
            Button("👎 Downvote", role: .destructive) { PostHogSDK.shared.capture("fake_door_quiet_spaces_downvote_clicked") }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Coming Soon! Upvote if you'd like a Quiet filter or downvote if not.")
        }
        .alert("💰 Affordable", isPresented: $showBudgetAlert) {
            Button("👍 Upvote") { PostHogSDK.shared.capture("fake_door_budget_friendly_upvote_clicked") }
            Button("👎 Downvote", role: .destructive) { PostHogSDK.shared.capture("fake_door_budget_friendly_downvote_clicked") }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Coming Soon! Upvote if you'd like an Affordable filter or downvote if not.")
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
