//
//  FloatingCardView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//


import SwiftUI
import MapKit

//struct FloatingCardView: View {
//    let meetingPoint: MeetingPoint
//    let onClose: () -> Void
//
//    var body: some View {
//        
//        
//        VStack(alignment: .leading) {
//            // Dismiss Button
//            HStack {
//                Spacer()
//                Button(action: onClose) {
//                    Image(systemName: "xmark.circle.fill")
//                        .foregroundColor(.gray)
//                        .imageScale(.large)
//                }
//            }
//            .padding(.top)
//
//            // Meeting Point Image
//            AsyncImage(url: URL(string: meetingPoint.imageUrl ?? "")) { image in
//                image.resizable()
//            } placeholder: {
//                Color.gray.opacity(0.3)
//            }
//            .frame(height: 150)
//            .cornerRadius(10)
//
//            // Meeting Point Name & Category
//            Text(meetingPoint.name)
//                .font(.title2)
//                .bold()
//            HStack {
//                Text(meetingPoint.emoji)
//                Text(meetingPoint.category)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//
//            // Distance Info
////            Text("\(meetingPoint.distance ?? 0.0, specifier: "%.2f") miles away")
////                .font(.subheadline)
////                .foregroundColor(.gray)
//
//
//            // "Get Directions" Button
//            Button(action: {
//                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: meetingPoint.coordinate))
//                mapItem.name = meetingPoint.name
//                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
//            }) {
//                HStack {
//                    Image(systemName: "tram.fill")
//                    Text("Get Directions")
//                        .bold()
//                }
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(Color.black)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//            }
//        }
//        .padding()
//        .background(Color.white)
//        .cornerRadius(15)
//        .shadow(radius: 5)
//        .padding(.horizontal)
//    }
//}
//
//
//#Preview {
//    FloatingCardView(meetingPoint: MeetingPoint(
//        name: "Central Park",
//        emoji: "🌳",
//        category: "Park",
//        coordinate: CLLocationCoordinate2D(latitude: 40.785091, longitude: -73.968285),
//        imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg/1599px-Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg"
//    )) {
//        print("FloatingCardView closed")
//    }
//}
//
struct FloatingCardView: View {
    let meetingPoint: MeetingPoint
    let onClose: () -> Void
    
    @State private var isImageLoaded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section with Google Places photo
            ZStack {
                // Image loading with state handling
                AsyncImage(url: URL(string: meetingPoint.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        // Loading state
                        ZStack {
                            Color.gray.opacity(0.2)
                            ProgressView()
                        }
                        .frame(height: 160)
                    case .success(let image):
                        // Successful image load
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 160)
                            .clipped()
                            .onAppear {
                                isImageLoaded = true
                            }
                    case .failure:
                        // Fallback with place emoji
                        ZStack {
                            Color.gray.opacity(0.2)
                            VStack {
                                Text(meetingPoint.emoji)
                                    .font(.system(size: 60))
                                Text(meetingPoint.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(height: 160)
                    @unknown default:
                        Color.gray.opacity(0.2)
                            .frame(height: 160)
                    }
                }
                
                // Attribution overlay (bottom right)
                if let photoRef = meetingPoint.photoReference, !photoRef.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("Photo: Google")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                                .padding(8)
                        }
                    }
                }
            }
            .frame(height: 160)
            
            // Place information
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(meetingPoint.emoji)
                        .font(.title2)
                    
                    Text(meetingPoint.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
                
                HStack {
                    Text(meetingPoint.category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // If we have an original place type and it's different from category, show it
                    if let originalType = meetingPoint.originalPlaceType,
                       originalType.capitalized != meetingPoint.category {
                        Text("(\(originalType.capitalized))")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Action buttons
                HStack(spacing: 12) {
                    ActionButton(
                        icon: "arrow.triangle.turn.up.right.circle.fill",
                        title: "Share",
                        color: .blue
                    )
                    
                    ActionButton(
                        icon: "location.fill",
                        title: "Directions",
                        color: .green
                    )
                    
                    ActionButton(
                        icon: "star",
                        title: "Save",
                        color: .orange
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// Helper view for action buttons
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}

#Preview {
    FloatingCardView(meetingPoint: MeetingPoint(
        name: "Central Park",
        emoji: "🌳",
        category: "Park",
        coordinate: CLLocationCoordinate2D(latitude: 40.785091, longitude: -73.968285),
        imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg/1599px-Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg"
    )) {
        print("FloatingCardView closed")
    }
}
