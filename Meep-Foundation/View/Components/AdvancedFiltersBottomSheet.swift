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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                
                // My Transit Selection
                TransportModePicker(title: "My Transit", selectedMode: $myTransit)
                    .padding(.top,32)
                
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
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                
                Spacer()
            }
            .padding()
        
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
        }
    }
}

// ✅ **Updated Custom Range Slider (Acts as Slider)**
struct CustomRangeSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        GeometryReader { geometry in
            let stepWidth = (geometry.size.width - 32) / CGFloat(range.upperBound - range.lowerBound)
            let totalSteps = Int((range.upperBound - range.lowerBound) / step)

            VStack(spacing: 8) {
                ZStack(alignment: .center) {
                    // Tick marks for reference
                    HStack(spacing: stepWidth) {
                        ForEach(0...totalSteps, id: \.self) { index in
                            Rectangle()
                                .fill(index == Int((value - range.lowerBound) / step) ? Color.blue : Color.gray.opacity(0.4))
                                .frame(width: index % 5 == 0 ? 2 : 1, height: index % 5 == 0 ? 20 : 12)
                        }
                    }

                    // **Draggable Blue Indicator**
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 6, height: 40)
                        .offset(x: -geometry.size.width / 2 + (CGFloat(value - range.lowerBound) / step * stepWidth) + 16)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    let rawValue = range.lowerBound + Double(gesture.location.x / stepWidth) * step
                                    let snappedValue = (rawValue / step).rounded() * step
                                    value = min(max(snappedValue, range.lowerBound), range.upperBound)
                                }
                        )

                        // **Tap Gesture to Select Value**
                        .onTapGesture { location in
                            let rawValue = range.lowerBound + Double(location.x / stepWidth) * step
                            let snappedValue = (rawValue / step).rounded() * step
                            value = min(max(snappedValue, range.lowerBound), range.upperBound)
                        }
                }
                .frame(height: 50)
            }
        }
        .frame(height: 60)
    }
}


// ✅ **Updated TransportModePicker with FilterBarView Styling**
struct TransportModePicker: View {
    let title: String
    @Binding var selectedMode: TransportMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.regular)
                .fontWidth(.expanded)
                .padding(.bottom,16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TransportMode.allCases) { mode in
                        Button(action: {
                            selectedMode = mode
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: mode.systemImageName)
                                    .font(.body)
                                Text(mode.title)
                                    .font(.body)
                                    .foregroundColor(Color(.label).opacity(0.8))
                                    .fontWidth(.expanded)
                            }
                            .frame(minWidth: 90, maxWidth: 150)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(selectedMode == mode ? Color.gray.opacity(0.1) : Color.white)
                            .foregroundColor(selectedMode == mode ? Color(.label) : .black)
                            .fontWeight(selectedMode == mode ? .medium : .regular)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .scrollClipDisabled(true)
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
