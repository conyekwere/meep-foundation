//
//  SubwayLinesDisplay.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/11/25.
//

import SwiftUI
import CoreLocation

struct SubwayLinesDisplay: View {
    let lines: [String]
    let subwayManager: OptimizedSubwayMapManager?
    let maxVisible: Int = 3
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(lines.prefix(maxVisible).enumerated()), id: \.offset) { index, line in
                SubwayLineInfoBadge(lineName: line, subwayManager: subwayManager)
            }
            
            if lines.count > maxVisible {
                Text("+\(lines.count - maxVisible)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
}
