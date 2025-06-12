//
//  FloatingCardView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//


import SwiftUI
import MapKit

struct FloatingCardView: View {
    @ObservedObject var viewModel: MeepViewModel
    let meetingPoint: MeetingPoint
    let onClose: () -> Void
    let myTransit: TransportMode

    @State private var isImageLoaded = false
    @State private var showDirectionsOptions = false

    
    
    var body: some View {
        
    VStack(alignment: .leading, spacing: 0) {

        
        HStack{
            // Image section with Google Places or placeholder
            ZStack {
                // If we already have a valid dataURL or remote URL:
                if let url = URL(string: meetingPoint.imageUrl), !meetingPoint.imageUrl.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                Color.gray.opacity(0.2)
                                ProgressView()
                            }
                            .cornerRadius(10)
                            .cornerRadius(10)
                            
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width:112 , height: 112)
                                .clipped()
                                .onAppear {
                                    isImageLoaded = true
                                }
                                .cornerRadius(10)
                            
                        case .failure:
                            ZStack {
                                Color.gray.opacity(0.2)
                                VStack {
                                    Text(meetingPoint.emoji)
                                        .font(.callout)
                                    Text(meetingPoint.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .cornerRadius(10)
                            .frame(width:112 , height: 112)
                            .cornerRadius(10)
                        @unknown default:
                            Color.gray.opacity(0.2)
                                .frame(height: 160)
                        }
                    }
                }
                // If no imageUrl yet, show placeholder:
                else {
                    ZStack {
                        Color.gray.opacity(0.2)
                        VStack {
                            Text(meetingPoint.emoji)
                                .font(.callout)
                            Text(meetingPoint.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .cornerRadius(10)
                    .frame(width:112 , height: 112)
                    .cornerRadius(10)
                }
                
                // Attribution if it was a Google‐loaded photo:
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
            .onAppear {
                // If no imageUrl yet → fetch single photo for selectedPoint
                if meetingPoint.imageUrl.isEmpty {
                    viewModel.fetchSinglePhotoFor(point: meetingPoint)
                }
            }
            

            
            // Place Name & Travel Time
            VStack(alignment: .leading, spacing: 8) {
                Text(meetingPoint.name)
                    .font(.title2)
                    .fontWidth(.expanded)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Example: "15 min away" (you can replace with dynamic text if available)
                Text(String(format: "%.2f miles away", meetingPoint.distance(from: viewModel.userLocation)))
                    .font(.headline)
                    .fontWidth(.expanded)
                    .fontWeight(.regular)
                    .foregroundColor(.primary)
                
                // Category Badge
                HStack(spacing: 4) {
                    Text(meetingPoint.emoji)
                        .font(.caption)
                    Text(meetingPoint.category)
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .fontWidth(.expanded)
                }

                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius:4).stroke(Color(.lightGray).opacity(0.8), lineWidth: 1))

            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
        }
            .padding(.horizontal, 16)


          
        
        // Get Directions Button
        Button(action: {
            showDirectionsOptions = true
        }) {
            HStack {
                Image(systemName: myTransit.systemImageName)
                    .font(.headline)
                Text("Get Directions")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.black)
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .confirmationDialog("Get Directions", isPresented: $showDirectionsOptions, titleVisibility: .visible) {
            Button("Apple Maps") {
                let placemark = MKPlacemark(coordinate: meetingPoint.coordinate)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = meetingPoint.name
                mapItem.openInMaps(launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: myTransit.launchOption
                ])
            }

            let googleMapsMode: String = {
                switch myTransit {
                case .walk: return "walking"
                case .bike: return "bicycling"
                case .train: return "transit"
                case .car: return "driving"
                }
            }()

            if let url = URL(string: "comgooglemaps://?daddr=\(meetingPoint.coordinate.latitude),\(meetingPoint.coordinate.longitude)&directionsmode=\(googleMapsMode)"),
               UIApplication.shared.canOpenURL(url) {
                Button("Google Maps") {
                    UIApplication.shared.open(url)
                }
            }

            Button("Cancel", role: .cancel) {}
        }

    }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 8)
        .overlay {
            // Dismiss Button (top right)
            HStack {
                Spacer()
              
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding (.trailing, 20)
            .offset(y: -90)
            
        }
    }
}


#Preview {
    FloatingCardView(
        viewModel: MeepViewModel(),
        meetingPoint: MeetingPoint(
            name: "Central Park",
            emoji: "🌳",
            category: "Park",
            coordinate: CLLocationCoordinate2D(latitude: 40.785091, longitude: -73.968285),
            imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg/1599px-Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg"
        ),
        onClose: {
            print("FloatingCardView closed")
        },
        myTransit: .bike
    )
}
