//
//  MeetingPointCard.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//

import SwiftUI
import CoreLocation

struct MeetingPointCard: View {
    let point: MeetingPoint
    let showDirections: () -> Void
    let userLocation: CLLocationCoordinate2D?
    
    var body: some View {
       
        VStack{

            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: point.imageUrl)) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                } placeholder: {
                    Color.gray.opacity(0.3)
                        .frame(height: 200)
                }
                .cornerRadius(12)
                
                
                Text(point.name)
                    .font(.title2)
                    .foregroundColor(Color(.label).opacity(0.8))
                    .fontWidth(.expanded)
                    .fontWeight(.semibold)
                
                
                HStack {
                    
                    HStack(spacing:4) {
                        Text(point.emoji)
                            .font(.footnote)
                        
                        Text(point.category)
                            .font(.footnote)
                            .foregroundColor(Color(.label).opacity(0.8))
                            .fontWidth(.expanded)
                            .fontWeight(.regular)
                    }.padding(8)
                        .padding(.horizontal,9)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                    Text("\(point.distance(from: userLocation), specifier: "%.2f") miles away")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                Button(action: {
                    // Use Apple Maps directions
                    showDirections()
                }) {
                    
                    HStack(spacing:8) {
                        Image(systemName: "tram.fill")
                            .foregroundColor( Color(.white))
                            .font(.subheadline)
                        
                        
                        Text("Get Directions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                    }    .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.95) 
            .background(Color.white)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.lightGray).opacity(0.3), lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        }
    }
}
