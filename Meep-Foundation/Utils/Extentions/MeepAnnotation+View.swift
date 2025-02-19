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
        HStack(alignment: .top,spacing: 0){

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
                
        }.offset(x:50)
    }
}

/// A friend annotation with a purple person icon.
private struct FriendAnnotationView: View {
    let title: String
    
    var body: some View {

        HStack(alignment: .top,spacing: 0){

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
                
        }.offset(x:50)
    }
}

/// A midpoint annotation with a red map pin icon.
private struct MidpointAnnotationView: View {
    let title: String
    var body: some View {

        HStack(alignment: .top,spacing: 0){

            VStack {
                Image(systemName: "stop.circle.fill")
                    .font(.title2)
                    .foregroundColor(.primary.opacity(0.55))
                    .overlay(Circle().stroke(Color(.white), lineWidth: 4))
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
                
                Text("Midpoint")
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
                
        }.offset(x:50)
    }
}


private struct PlaceAnnotationView: View {
    let title: String
    let emoji: String

    @State private var isSelected: Bool = false // Track selection state
    @Namespace private var animationNamespace // Matched Geometry Effect namespace

    var body: some View {
        VStack(spacing: 0) {
            if isSelected {
                // 🔵 Active State (Expanded with title)
                HStack(alignment: .center, spacing: 6) {
                    Text(emoji)
                        .font(.callout)
                        .matchedGeometryEffect(id: "emoji", in: animationNamespace)

                    Text(title)
                        .font(.footnote)
                        .foregroundColor(Color(.white))
                        .fontWeight(.regular)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .matchedGeometryEffect(id: "title", in: animationNamespace)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 32)
                .background(Color(.label).opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 100))
                .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color(.white), lineWidth: 2))
                .zIndex(1)
                .matchedGeometryEffect(id: "background", in: animationNamespace)
            } else {
                // ⚪ Default State (Just Emoji)
                ZStack(alignment: .center) {
                    Text(emoji)
                        .font(.callout)
                        .matchedGeometryEffect(id: "emoji", in: animationNamespace)
                }
                .frame(width: 32, height: 32)
                .background(Color.white)
                .clipShape(Circle())
                .zIndex(1)
                .matchedGeometryEffect(id: "background", in: animationNamespace)

                PinPointer()
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
        .onTapGesture {
            withAnimation(.spring()) {
                isSelected.toggle() // Toggle between active/inactive states
            }
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
            .frame(width: 12, height: 10)
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
            .rotationEffect(.degrees(180))
            .offset(y: -1.0)
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
        MidpointAnnotationView(title: "E 88th St, New York, NY 10128")
        PlaceAnnotationView(title: "McSorley's", emoji: "🍺")
        
        PlaceAnnotationView(title: "Central ParkCentral ParkCentral ParkCentral  Park", emoji: "🌳")
        
        PlaceAnnotationView(title: "Cafe", emoji: "☕")
        PlaceAnnotationView(title: "The Grand Central Market", emoji: "🍽")
        PlaceAnnotationView(title: "John's Italian Restaurant", emoji: "🍕")
        PlaceAnnotationView(title: "Broadway Theater, New York", emoji: "🎭")
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
