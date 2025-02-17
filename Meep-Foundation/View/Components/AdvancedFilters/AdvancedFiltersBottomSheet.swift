//
//  AdvancedFiltersBottomSheet.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/8/25.
//
import SwiftUI

struct AdvancedFiltersBottomSheet: View {
    @Binding var myTransit: TransportMode
    @Binding var friendTransit: TransportMode
    @Binding var searchRadius: Double
    @Environment(\.dismiss) var dismiss

    @State private var isNowSelected = true // Default to "Now"
    @State private var startDate = Date()
    @State private var showDatePicker = false // Controls overlay visibility

    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2025, month: 1, day: 1)
        let endComponents = DateComponents(year: 2030, month: 12, day: 31, hour: 59, second: 59)
        return calendar.date(from: startComponents)! ... calendar.date(from: endComponents)!
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Time Selection
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Departure Time")
                            .font(.headline)
                            .fontWeight(.regular)
                            .fontWidth(.expanded)
                        
                        HStack(spacing: 10) {
                            Button(action: { isNowSelected = true }) {
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

                        // Show Selected Time if "Leave" is selected
                        if !isNowSelected {
                            Button(action: { showDatePicker.toggle() }) {
                                HStack {
                                    Text("Leave At")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .fontWeight(.regular)
                                        .fontWidth(.expanded)

                                    Spacer()

                                    // ✅ Show both date and time if the selected date is NOT today
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

                    // Search Range Interactive Indicator (Acts as Slider)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search Range (\(Int(searchRadius)) miles)")
                            .font(.headline)
                            .fontWeight(.regular)
                            .fontWidth(.expanded)

                        CustomRangeSlider(value: $searchRadius, range: 1...20, step: 1)
                    }
                    .padding(.top, 4)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))

                }
                .padding()
                .padding(.top, -32)
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
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
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Filters")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .fontWidth(.expanded)
                            .foregroundColor(.primary).opacity(0.7)
                    }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerTransitSheet(startDate: $startDate)
            }
        }
    }

    // ✅ **Helper Function to Format Date Dynamically**
    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short // Show only time if today
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium // Show date
            formatter.timeStyle = .short // Show time
            return formatter.string(from: date)
        }
    }
}


#Preview {
    @State var myTransit: TransportMode = .train
    @State var friendTransit: TransportMode = .train
    @State var searchRadius: Double = 10

    return AdvancedFiltersBottomSheet(
        myTransit: $myTransit,
        friendTransit: $friendTransit,
        searchRadius: $searchRadius
    )
}
