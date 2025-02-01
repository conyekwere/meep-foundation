//
//  MeetingPointCard.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//


import SwiftUI

struct MeetingPointCard: View {
    let meetingPoint: MeetingPoint

    var body: some View {
        VStack(alignment: .leading) {
            Text(meetingPoint.name)
                .font(.headline)
                .lineLimit(2)

            Text("\(meetingPoint.distance, specifier: "%.2f") miles away")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text(meetingPoint.emoji)
                .font(.largeTitle)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
