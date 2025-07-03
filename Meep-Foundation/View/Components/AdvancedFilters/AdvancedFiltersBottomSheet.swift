//
//  AdvancedFiltersBottomSheet.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/8/25.
//

import SwiftUI
import PostHog

struct AdvancedFiltersBottomSheet: View {
    @Binding var myTransit: TransportMode
    @Binding var friendTransit: TransportMode
    @Binding var searchRadius: Double
    @Binding var departureTime: Date?
    

    @Environment(\.dismiss) var dismiss

    @State private var isNowSelected = true // Default to "Now"
    @State private var startDate = Date()
    @State private var showDatePicker = false // Controls overlay visibility

    
    @ObservedObject var viewModel: MeepViewModel
    let onTransitChecker: () -> Void
    
    
    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2025, month: 1, day: 1)
        let endComponents = DateComponents(year: 2030, month: 12, day: 31, hour: 59, second: 59)
        return calendar.date(from: startComponents)! ... calendar.date(from: endComponents)!
    }()

    var body: some View {
        ZStack {
            // Center title
            Text("Filters")
                .font(.headline)
                .fontWeight(.semibold)
                .fontWidth(.expanded)
                .foregroundColor(.primary)
                .opacity(0.7)
            
            HStack {
                // Leading Close Button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(12)
                        .frame(width: 40, height: 40)
                        .foregroundColor(Color(.gray))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color(.systemGray6), lineWidth: 2)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .padding(.top, 16)
        .padding(.horizontal, 24)
        Divider()
            ScrollView(.vertical){
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Time Selection
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Departure Time")
                            .font(.headline)
                            .fontWeight(.regular)
                            .fontWidth(.expanded)
                        
                        HStack(spacing: 10) {
                            Button(action: {
                                isNowSelected = true
                                departureTime = nil  // "Now" selected
                            }) {
                                Text("Now")
                                    .fontWeight(.regular)
                                    .fontWidth(.expanded)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(isNowSelected ? Color.gray.opacity(0.1) : Color.white)
                                    .foregroundColor(isNowSelected ? Color(.label) : .black)
                                    .fontWeight(isNowSelected ? .medium : .regular)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            Button(action: {
                                isNowSelected = false
                                showDatePicker.toggle()
                                departureTime = startDate
                            }) {
                                Text("Leave")
                                    .fontWeight(.regular)
                                    .fontWidth(.expanded)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(!isNowSelected ? Color.gray.opacity(0.1) : Color.white)
                                    .foregroundColor(!isNowSelected ? Color(.label) : .black)
                                    .fontWeight(!isNowSelected ? .medium : .regular)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        if !isNowSelected {
                            Button(action: { showDatePicker.toggle() }) {
                                HStack {
                                    Text("Leave At")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .fontWeight(.regular)
                                        .fontWidth(.expanded)
                                    Spacer()
                                    Text(formatDate(startDate))
                                        .fontWeight(.regular)
                                        .fontWidth(.expanded)
                                        .padding(8)
                                        .foregroundColor(.black)
                                        .background(Color(.lightGray).opacity(0.2))
                                        .cornerRadius(8)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.lightGray), lineWidth: 0.5))
                            }
                        }
                    }
                    
                    // My Transit Selection
                    TransportModePicker(title: "My Transit", selectedMode: $myTransit)
                    
                    // Friend's Transit Selection
                    TransportModePicker(title: "Friend's Transit", selectedMode: $friendTransit)
                    
                    // Search Range Slider
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search Range (\(formattedDistance(searchRadius)))")
                            .font(.headline)
                            .fontWeight(.regular)
                            .fontWidth(.expanded)
                            .padding(.leading, 16)
                        CustomRangeSlider(value: $searchRadius, range: 0.2...1.0, step: 0.2)
                        
                        
                    }
                    .padding(.top, 4)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.lightGray).opacity(0.3), lineWidth: 1))
                }
                .padding()
                .padding(.top)
                Spacer()
            }

            Divider()
            HStack {
                Button("Clear All") {
                    myTransit = .train
                    friendTransit = .train
                    searchRadius = 0.2
                    departureTime = nil
                    isNowSelected = true
                    
                    viewModel.activeFilterCount = 0
                    
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .fontWeight(.medium)
                .foregroundColor(.black)
                .cornerRadius(10)

                Button("Show Results") {
                    
                    
                    viewModel.updateActiveFilterCount(myTransit: myTransit, friendTransit: friendTransit, searchRadius: searchRadius, departureTime: departureTime)
                    
                    PostHogSDK.shared.capture("filters_applied", properties: [
                        "my_transit": myTransit.rawValue,
                        "friend_transit": friendTransit.rawValue,
                        "search_radius": searchRadius,
                        "has_departure_time": departureTime != nil,
                        "filter_count": viewModel.activeFilterCount
                    ])
                    

                    viewModel.searchRadius = searchRadius
                    viewModel.searchNearbyPlaces()
                    
                    onTransitChecker()
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.bottom, -20)
            .padding()
            .padding(.trailing, 8)

            .sheet(isPresented: $showDatePicker) {
                DatePickerTransitSheet(startDate: $startDate)
                    .onDisappear {
                        if !isNowSelected {
                            departureTime = startDate
                        }
                    }
            }
        
        .ignoresSafeArea(edges: .bottom)
    }

    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

    func formattedDistance(_ value: Double) -> String {
        
        if abs(value - 0.2) < 0.01 {
            return "⅕ mile"
        } else if abs(value - 0.4) < 0.01 {
            
            return "⅖ mile"
        } else if abs(value - 0.6) < 0.01 {
            
            return "⅗ mile"
        } else if abs(value - 0.8) < 0.01 {
            
            return "⅘ mile"
        } else if abs(value - 1.0) < 0.01 {
            return "1 mile"
        } else {
            
            return String(format: "%.1f miles", value)
        }
    }
}

#Preview {
    AdvancedFiltersBottomSheet(
        myTransit: .constant(.train),
        friendTransit: .constant(.train),
        searchRadius: .constant(0.2), // Default 0.2 miles
        departureTime: .constant(nil), viewModel: MeepViewModel(), onTransitChecker: {}
    )
}
