//
//  FloatingCardView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//


import SwiftUI

struct FloatingCardView: View {
    let meetingPoint: MeetingPoint
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            // Dismiss Handle
            Capsule()
                .frame(width: 40, height: 6)
                .foregroundColor(.gray.opacity(0.5))
                .padding(.top, 8)
                .padding(.bottom, 10)

            // Meeting Point Details
            HStack {
                Text(meetingPoint.name)
                    .font(.headline)
                    .lineLimit(2)
                    .padding(.bottom, 5)

                Spacer()

                Text(meetingPoint.emoji)
                    .font(.largeTitle)
            }

            Text("\(30, specifier: "%.2f") miles away")
                .font(.subheadline)
                .foregroundColor(.gray)

            // "Get Directions" Button
            Button("Get Directions") {
                // e.g., open Apple Maps, etc.
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .onTapGesture {
            // If you want the tap to do something else
        }
    }
}
