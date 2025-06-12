//
//  SubwayLineInfoBadge.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/11/25.
//
import SwiftUI
import CoreLocation

struct SubwayLineInfoBadge: View {
    let lineName: String
    let subwayManager: OptimizedSubwayMapManager?
    
    // Reuse colors from the subway manager
    private var lineColor: Color {
        guard let manager = subwayManager else {
            return Color.gray
        }
        
        let uiColor = manager.getLineColor(for: lineName)
        return Color(uiColor)
    }
    
    var body: some View {
        Text(lineName)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background(lineColor)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}
