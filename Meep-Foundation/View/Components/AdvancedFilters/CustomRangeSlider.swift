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
    
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(spacing: 16) {
            // Simple slider that just works
            Slider(
                value: Binding(
                    get: { value },
                    set: { newValue in
                        let steps = (range.upperBound - range.lowerBound) / step
                        let stepValue = (newValue - range.lowerBound) / step
                        let roundedStep = stepValue.rounded()
                        let snappedValue = range.lowerBound + (roundedStep * step)
                        
                        if snappedValue != value {
                            haptic.impactOccurred()
                            value = snappedValue
  
                        }
                    }
                ),
                in: range,
                step: step
            )

            .accentColor(.black)
            .padding(.horizontal, 16)
            
            // Labels
            HStack {
                Text("⅕")
                    .font(.footnote)
                    .fontWeight(abs(value - 0.2) < 0.01 ? .semibold : .regular)
                    .foregroundColor(abs(value - 0.2) < 0.01 ? .black : .black.opacity(0.7))
                    .frame(maxWidth: .infinity)
                
                Text("⅖")
                    .font(.footnote)
                    .fontWeight(abs(value - 0.4) < 0.01 ? .semibold : .regular)
                    .foregroundColor(abs(value - 0.4) < 0.01 ? .black : .black.opacity(0.7))
                    .frame(maxWidth: .infinity)
                
                Text("⅗")
                    .font(.footnote)
                    .fontWeight(abs(value - 0.6) < 0.01 ? .semibold : .regular)
                    .foregroundColor(abs(value - 0.6) < 0.01 ?  .black : .black.opacity(0.7))
                    .frame(maxWidth: .infinity)
                
                Text("⅘")
                    .font(.footnote)
                    .fontWeight(abs(value - 0.8) < 0.01 ? .semibold : .regular)
                    .foregroundColor(abs(value - 0.8) < 0.01 ? .black : .black.opacity(0.7))
                    .frame(maxWidth: .infinity)
                
                Text("1")
                    .font(.footnote)
                    .fontWeight(abs(value - 1.0) < 0.01 ? .semibold : .regular)
                    .foregroundColor(abs(value - 1.0) < 0.01 ?  .black : .black.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 60)
    }
}

#Preview {
    @State var sliderValue: Double = 0.2
    
    return VStack(spacing: 20) {
        Text("Search Range (\(sliderValue == 0.2 ? "⅕ mile" : sliderValue == 0.4 ? "⅖ mile" : sliderValue == 0.6 ? "⅗ mile" : sliderValue == 0.8 ? "⅘ mile" : "1 mile"))")
            .font(.headline)
        
        CustomRangeSlider(value: $sliderValue, range: 0.2...1.0, step: 0.2)
            .padding()
    }
    .padding()
}
