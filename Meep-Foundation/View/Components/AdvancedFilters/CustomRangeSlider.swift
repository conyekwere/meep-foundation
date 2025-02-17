//
//  CustomRangeSlider.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/17/25.
//

import SwiftUI

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
