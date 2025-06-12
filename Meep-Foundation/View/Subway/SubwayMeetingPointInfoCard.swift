//
//  SubwayMeetingPointInfoCard.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/11/25.
//

import SwiftUI
import CoreLocation

struct SubwayMeetingPointInfoCard: View {
    let point: MeetingPoint
    let subwayLines: [String]
    let userLocation: CLLocationCoordinate2D?
    let subwayManager: OptimizedSubwayMapManager?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with subway icon and title
            HStack(spacing:16) {
   
                Image(systemName: "stop.circle.fill")
                    .font(.title2)
                    .foregroundColor(.primary.opacity(0.55))
                    .overlay(Circle().stroke(Color(.white), lineWidth: 4))
                    .shadow(color: .black.opacity(0.10), radius: 2, x: 0, y: 2)
                    
                    .padding(10)
                    .background(.black.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color(.lightGray).opacity(0.5), lineWidth: 1)
                         
                    )
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meeting Point")
                        .font(.headline)
                        
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.label).opacity(0.8))
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    
                    if let userLoc = userLocation {
                        let distance = point.distance(from: userLoc)
                        Text("\(String(format: "%.1f", distance)) mi away by train")
                            .font(.caption)
                            .foregroundColor(Color(.label).opacity(0.8))
                            
                    } else {
                        Text("Subway accessible")
                            .font(.footnote)
                            .foregroundColor(Color(.label).opacity(0.8))
                            
                    }
                }
                
                Spacer()
                
                // Subway lines display (horizontal like in your image)
                SubwayLinesDisplay(lines: subwayLines, subwayManager: subwayManager)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.95)
        .background(Color(.systemBackground))

        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.lightGray).opacity(0.3), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview with Real Subway Data

#Preview {
    let subwayManager = OptimizedSubwayMapManager()
    
    // Sample meeting point (using Times Square coordinates)
    let samplePoint = MeetingPoint(
        name: "Times Square Meeting Point",
        emoji: "🚇",
        category: "Transit Hub",
        coordinate: CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855),
        imageUrl: ""
    )
    
    // Sample user location (Bryant Park)
    let userLocation = CLLocationCoordinate2D(latitude: 40.7536, longitude: -73.9832)
    
    // Lines that would be available at Times Square
    let availableLines = ["4", "5", "6", "N", "Q", "R", "W", "S"]
    
    return VStack(spacing: 20) {
        SubwayMeetingPointInfoCard(
            point: samplePoint,
            subwayLines: Array(availableLines.prefix(4)), // Show first 4 lines
            userLocation: userLocation,
            subwayManager: subwayManager
        )
        
        SubwayMeetingPointInfoCard(
            point: samplePoint,
            subwayLines: availableLines, // Show all lines (will have +X overflow)
            userLocation: userLocation,
            subwayManager: subwayManager
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
