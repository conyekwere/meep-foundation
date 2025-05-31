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
            let usableWidth = max(geometry.size.width - 32, 1)
            let totalSteps = Int((range.upperBound - range.lowerBound) / step)
            let stepWidth = usableWidth / CGFloat(totalSteps)

            VStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    // Tick marks for reference
                    HStack(spacing: stepWidth) {
                        ForEach(0...totalSteps, id: \.self) { index in
                            let tickValue = range.lowerBound + Double(index) * step
                            Rectangle()
                                .fill(abs(tickValue - value) < step / 2 ? Color.blue : Color.gray.opacity(0.4))
                                .frame(width: index % 5 == 0 ? 2 : 1, height: index % 5 == 0 ? 20 : 12)
                        }
                    }

                    // Draggable indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 6, height: 40)
                        .offset(x: CGFloat((value - range.lowerBound) / step) * stepWidth - 3)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let locationX = gesture.location.x
                            let rawValue = range.lowerBound + Double(locationX / stepWidth) * step
                            let clampedValue = min(max(rawValue, range.lowerBound), range.upperBound)
                            let snappedValue = (clampedValue / step).rounded() * step
                            value = snappedValue
                        }
                )
                .contentShape(Rectangle())
                .frame(height: 50)
            }
        }
        .frame(height: 60)
    }
}

#Preview {
    @State var sliderValue: Double = 1
    return CustomRangeSlider(value: $sliderValue, range: 1...5, step: 1)
        .padding()
        .previewLayout(.sizeThatFits)
}
