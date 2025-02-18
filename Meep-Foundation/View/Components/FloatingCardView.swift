//
//  FloatingCardView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//


import SwiftUI
import MapKit

struct FloatingCardView: View {
    let meetingPoint: MeetingPoint
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            // Dismiss Button
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                }
            }
            .padding(.top)

            // Meeting Point Image
            AsyncImage(url: URL(string: meetingPoint.imageUrl ?? "")) { image in
                image.resizable()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(height: 150)
            .cornerRadius(10)

            // Meeting Point Name & Category
            Text(meetingPoint.name)
                .font(.title2)
                .bold()
            HStack {
                Text(meetingPoint.emoji)
                Text(meetingPoint.category)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // Distance Info
//            Text("\(meetingPoint.distance ?? 0.0, specifier: "%.2f") miles away")
//                .font(.subheadline)
//                .foregroundColor(.gray)


            // "Get Directions" Button
            Button(action: {
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: meetingPoint.coordinate))
                mapItem.name = meetingPoint.name
                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
            }) {
                HStack {
                    Image(systemName: "tram.fill")
                    Text("Get Directions")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}
