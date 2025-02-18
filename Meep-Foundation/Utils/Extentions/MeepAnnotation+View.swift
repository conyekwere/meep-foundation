//
//  MeepAnnotation+View.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/1/25.
//

import SwiftUI

extension MeepAnnotation {
    /// A computed property that returns a SwiftUI view for each annotation type.
    /// Using @ViewBuilder lets us return different view structs without type errors.
    @ViewBuilder
    var annotationView: some View {
        switch type {
        case .user:
            UserAnnotationView(title: title)
        case .friend:
            FriendAnnotationView(title: title)
        case .midpoint:
            MidpointAnnotationView(title: title)
        case .place(let emoji):
            PlaceAnnotationView(title: title, emoji: emoji)
        }
    }
}

// MARK: - Custom subviews for each annotation type

/// A user annotation (e.g. "You") with a blue person icon.
private struct UserAnnotationView: View {
    let title: String
    
    var body: some View {
        HStack(alignment: .top,spacing: 4){

            VStack {
                Image(systemName: "dot.square.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .overlay(RoundedRectangle(cornerRadius:4).stroke(Color(.white), lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
                
                Text("You")
                    .font(.footnote)
                    .foregroundColor(Color(.label).opacity(0.8))
                    .fontWidth(.expanded)
                    .fontWeight(.regular)
                    .padding(4)
            .background(Color.white.opacity(0.9))
                .cornerRadius(4)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
            }
                
            AnnotationLabel(title: title)
                
        }
    }
}

/// A friend annotation with a purple person icon.
private struct FriendAnnotationView: View {
    let title: String
    
    var body: some View {
        HStack(alignment: .top,spacing: 4){

            VStack {
                Image(systemName: "dot.square.fill")
                    .font(.title2)
                    .foregroundColor(.primary.opacity(0.55))
                    .overlay(RoundedRectangle(cornerRadius:4).stroke(Color(.white), lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
                
                Text("Friend")
                    .font(.footnote)
                    .foregroundColor(Color(.label).opacity(0.8))
                    .fontWidth(.expanded)
                    .fontWeight(.regular)
                    .padding(4)
            .background(Color.white.opacity(0.9))
                .cornerRadius(4)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
            }
                
            AnnotationLabel(title: title)
                
        }
    }
}

/// A midpoint annotation with a red map pin icon.
private struct MidpointAnnotationView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
                
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            PinPointer()
            AnnotationLabel(title: title)
        }
    }
}

/// A place annotation with a custom emoji in a white circle.
private struct PlaceAnnotationView: View {
    let title: String
    let emoji: String
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
                
                Text(emoji)
                    .font(.title2)
            }
            PinPointer()
            AnnotationLabel(title: title)
        }
    }
}

// MARK: - Shared subviews

/// The small pointer triangle under the circle.
private struct PinPointer: View {
    var body: some View {
        Image(systemName: "triangle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 8)
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
            .rotationEffect(.degrees(180))
            .offset(y: -1)
    }
}

/// The text label below the annotation circle.
private struct AnnotationLabel: View {
    let title: String
    
    var body: some View {
        

            Text(title)
            .font(.footnote)
            .foregroundColor(.primary)
            .padding(6)
            .background(Color.white.opacity(0.9))
            .cornerRadius(4)
            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
        
    }
}


 

#Preview {
    VStack(spacing: 20) {
        UserAnnotationView(title: "City Hall, New York, NY 10007")
        FriendAnnotationView(title: "Church Ave, Brooklyn, NY 11203")
        MidpointAnnotationView(title: "Midpoint")
        PlaceAnnotationView(title: "McSorley's", emoji: "🍺")
        PlaceAnnotationView(title: "Central Park", emoji: "🌳")
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
