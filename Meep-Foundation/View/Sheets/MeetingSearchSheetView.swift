//
//  MeetingSearchSheetView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/24/25.
//

import SwiftUI
import CoreLocation
import MapKit

struct MeetingSearchSheetView: View {
    @State private var myLocation: String = ""
    @State private var friendLocation: String = ""
    
    @ObservedObject var viewModel: MeepViewModel
    @Binding var isSearchActive: Bool
    
    // Focus states for the two text fields.
    @FocusState private var isMyLocationFocused: Bool
    @FocusState private var isFriendsLocationFocused: Bool
    
    // Completion handlers for dismissing and completing the search.
    var onDismiss: () -> Void
    var onDone: () -> Void
    
    // Two separate local search completer instances:
    @StateObject private var mySearchCompleter = LocalSearchCompleterDelegate()
    @StateObject private var friendSearchCompleter = LocalSearchCompleterDelegate()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Input Section
                VStack(spacing: 0) {
                    // "My Location" Input Row
                    SearchTextFieldRow(
                        leadingIcon: "dot.square.fill",
                        title: "My Location",
                        placeholder: "What’s your location?",
                        trailingIcon: "tram.fill",
                        text: $myLocation,
                        isDirty: !myLocation.isEmpty,
                        onTrailingIconTap: { }
                    )
                    .focused($isMyLocationFocused)
                    .onSubmit { isMyLocationFocused = false }
                    .overlay(
                        Rectangle()
                            .fill(Color(#colorLiteral(red: 0.971, green: 0.971, blue: 0.971, alpha: 1)))
                            .frame(height: 2),
                        alignment: .bottom
                    )
                    
                    // "Friend's Location" Input Row
                    SearchTextFieldRow(
                        leadingIcon: "dot.square.fill",
                        title: "Friend's Location",
                        placeholder: "What's your friend's location?",
                        trailingIcon: "tram.fill",
                        text: $friendLocation,
                        isDirty: !friendLocation.isEmpty,
                        onTrailingIconTap: { print("Trailing icon tapped") }
                    )
                    .focused($isFriendsLocationFocused)
                    .onSubmit { isFriendsLocationFocused = false }
                }
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(#colorLiteral(red: 0.971, green: 0.971, blue: 0.971, alpha: 1)), lineWidth: 2)
                )
                .padding(.horizontal, 16)
                
                
                if friendLocation.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 || myLocation.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 {
                    // Autocomplete for "My Location"
                    if isMyLocationFocused && myLocation.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 && !mySearchCompleter.completions.isEmpty {
                        
                        
                        ScrollView(.vertical) {
                            VStack(alignment:.leading,spacing: 24) {
                                ForEach(mySearchCompleter.completions, id: \.title) { completion in
                                    Button(action: {
                                        myLocation = "\(completion.title) \(completion.subtitle)".trimmingCharacters(in: .whitespaces)
                                        isMyLocationFocused = false
                                        isFriendsLocationFocused = true
                                    }) {
                                        HStack(spacing: 16) {
                                            Image(systemName: "mappin.circle")
                                                .font(.callout)
                                                .foregroundColor(.blue)
                                                .frame(width: 40, height: 40)
                                                .background(Color(hex: "E8F0FE"))
                                                .clipShape(Circle())
                                            VStack(alignment: .leading) {
                                                Text(completion.title)
                                                    .foregroundColor(.primary)
                                                    .font(.body)
                                                Text(completion.subtitle)
                                                    .font(.callout)
                                                    .foregroundColor(Color(.darkGray))
                                                    .lineLimit(1)
                                            }
                                        }.padding(.horizontal,16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            
                            
                        }
                        .scrollIndicators(.hidden)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        
                        
                    }
                    
                    // Autocomplete for "Friend's Location"
                    if isFriendsLocationFocused && friendLocation.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 && !friendSearchCompleter.completions.isEmpty {
                        
                        ScrollView(.vertical) {
                            VStack(alignment:.leading,spacing: 24) {
                                ForEach(friendSearchCompleter.completions, id: \.title) { completion in
                                    Button(action: {
                                        friendLocation = "\(completion.title) \(completion.subtitle)".trimmingCharacters(in: .whitespaces)
                                        isFriendsLocationFocused = false
                                    }) {
                                        HStack(spacing: 16) {
                                            Image(systemName: "mappin.circle")
                                                .font(.callout)
                                                .foregroundColor(.blue)
                                                .frame(width: 40, height: 40)
                                                .background(Color(hex: "E8F0FE"))
                                                .clipShape(Circle())
                                            VStack(alignment: .leading) {
                                                Text(completion.title)
                                                    .foregroundColor(.primary)
                                                    .font(.body)
                                                Text(completion.subtitle)
                                                    .font(.callout)
                                                    .foregroundColor(Color(.darkGray))
                                                    .lineLimit(1)
                                            }
                                        }.padding(.horizontal,16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                
                                }
                            }
                        
                        }
                        .scrollIndicators(.hidden)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                    }
                }
                
                else {
                    // MARK: Suggestion Buttons Section
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            if isMyLocationFocused {
                                SuggestionButton(icon: "house", title: "Set location", label: "Home", action: { print("Home tapped") })
                                SuggestionButton(icon: "briefcase", title: "Set location", label: "Work", action: { print("Work tapped") })
                                SuggestionButton(icon: "ellipsis", title: "", label: "More", action: { print("More tapped") })
                            }
                           else if isFriendsLocationFocused {
                                SuggestionButton(icon: "plus", title: "Add another friend", label: "More friends?", action: { print("Add friend tapped") })
                                SuggestionButton(icon: "text.badge.plus", title: "Add contacts", label: "Searching for friends?", action: { print("Add contacts tapped") })
                                SuggestionButton(icon: "person.circle", title: "Set location", label: "Close Friend", action: { print("Close friend tapped") })
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 24)
                    .scrollTargetLayout()
                    .safeAreaPadding(.trailing, 16)
                    .scrollIndicators(.hidden)
                    .scrollClipDisabled(true)
                    
                    // MARK: Autocomplete & Additional Options Section
                    ScrollView(.vertical, showsIndicators: false) {
                        // Additional Options Section
                        LazyVStack(spacing: 40) {
                            if isMyLocationFocused {
                                // Current Location Button
                                Button(action: {
                                    print("Current Location selected")
                                    viewModel.requestUserLocation()
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "location")
                                            .font(.callout)
                                            .foregroundColor(.blue)
                                            .frame(width: 40, height: 40)
                                            .background(Color(hex: "E8F0FE"))
                                            .clipShape(Circle())
                                        Text("Current Location")
                                            .foregroundColor(.primary)
                                            .font(.body)
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            // Ask for Friend's Location Button
                            Button(action: {
                                print("Ask for friend's location selected")
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "message")
                                        .font(.callout)
                                        .foregroundColor(.blue)
                                        .frame(width: 40, height: 40)
                                        .background(Color(hex: "E8F0FE"))
                                        .clipShape(Circle())
                                    VStack(alignment: .leading) {
                                        Text("Ask for a friend's location")
                                            .foregroundColor(.primary)
                                            .font(.body)
                                        Text("Exact coordinates are hidden")
                                            .font(.callout)
                                            .foregroundColor(Color(.darkGray))
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .scrollClipDisabled(true)
                    .padding(.top, 40)
                }
                Spacer()
            }
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        print("DEBUG: Back Button Tapped")
                        onDismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(12)
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color(.gray))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color(.systemGray6), lineWidth: 2)
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Set meeting point")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 8)
                }
                ToolbarItem(placement: .topBarTrailing) {
                   // if myLocation   && friendLocation is valid address
                    Button(action: {
                        // Trigger geocoding with the input addresses.
                        viewModel.geocodeAndSetLocations(userAddress: myLocation, friendAddress: friendLocation)
                        onDone()
                    }) {
                        Text("Done")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                // Update autocomplete queries for both fields.
                mySearchCompleter.updateQuery(myLocation)
                friendSearchCompleter.updateQuery(friendLocation)
                
                // If userLocation is available, reverse geocode to get a human-readable address.
                if let userLoc = viewModel.userLocation {
                    let location = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
                    CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                        if let placemark = placemarks?.first, error == nil {
                            let address = [
                                placemark.name,
                                placemark.locality,
                                placemark.administrativeArea
                            ]
                            .compactMap { $0 }
                            .joined(separator: ", ")
                            DispatchQueue.main.async {
                                myLocation = address
                                isFriendsLocationFocused = true
                            }
                        } else {
                            myLocation = String(format: "%.4f, %.4f", userLoc.latitude, userLoc.longitude)
                            isMyLocationFocused = true
                        }
                    }
                } else {
                    viewModel.requestUserLocation()
                    isMyLocationFocused = true
                }
            }
            .onChange(of: myLocation) { newValue in
                mySearchCompleter.updateQuery(newValue)
            }
            .onChange(of: friendLocation) { newValue in
                friendSearchCompleter.updateQuery(newValue)
            }
        }
    }
}

#Preview {
    MeetingSearchSheetView(
        viewModel: MeepViewModel(),
        isSearchActive: .constant(false),
        onDismiss: { print("Back button tapped") },
        onDone: { print("Done tapped") }
    )
}
