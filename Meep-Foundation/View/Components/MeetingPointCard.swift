//
//  MeetingPointCard.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import SwiftUI
import CoreLocation
import Foundation

struct MeetingPointCard: View {
    let point: MeetingPoint
    let showDirections: () -> Void
    let userLocation: CLLocationCoordinate2D?
    let myTransit: TransportMode
    @ObservedObject var viewModel: MeepViewModel

    var body: some View {
        VStack{
            VStack(alignment: .leading, spacing: 16) {
                // ––– Cover area: either an image or an emoji “placeholder” –––
                ZStack {
                    if let url = URL(string: point.imageUrl), !point.imageUrl.isEmpty {
                        // If we have a non‐empty imageUrl, load it
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                // While the image is downloading, show a light gray background
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 200)
                                    .shimmer()
                                
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipped()
                            case .failure:
                                // If loading fails, fall back to an emoji cover
                                coverEmojiView
                            @unknown default:
                                coverEmojiView
                            }
                        }
                        .frame(height: 200)
                        .clipped()
                    } else {
                        // No URL yet → show the emoji as a “cover”
                        coverEmojiView
                    }
                }
                .cornerRadius(12)
                .overlay(
                    Group {
                        if viewModel.visitedPlaceIDs.contains(point.id.uuidString) {
                            Text("Visited")
                                .font(.caption2)
                                .padding(6)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .padding(8),
                    alignment: .topTrailing
                )
                
                // ––– Name –––
                Text(point.name)
                    .font(.title2)
                    .foregroundColor(Color(.label).opacity(0.8))
                    .fontWeight(.semibold)
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                
                // ––– Category + Distance –––
                HStack {
                    HStack(spacing: 4) {
                        Text(point.emoji)
                            .font(.footnote)
                        Text(point.category)
                            .font(.footnote)
                            .foregroundColor(Color(.label).opacity(0.8))
                    }
                    .padding(8)
                    .padding(.horizontal, 9)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.lightGray).opacity(0.3), lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                    
                    let formattedDistance = String(format: "%.2f miles away", point.distance(from: userLocation))
                    Text(formattedDistance)
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                
                // ––– Directions Button –––
                Button(action: {
                    showDirections()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: myTransit.systemImageName)
                            .foregroundColor(.white)
                            .font(.subheadline)
                        Text("Get Directions")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.95)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.lightGray).opacity(0.3), lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // If no photo URL, show a light‐gray box with the emoji centered
    private var coverEmojiView: some View {
        ZStack {
            Color.gray.opacity(0.1)
            Text(point.emoji)
                .font(.system(size: 60))
        }
        .frame(height: 200)
    }
}
