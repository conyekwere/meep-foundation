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
    
    
    @State private var isMyLocationValid: Bool = false
    @State private var isFriendsLocationValid: Bool = false
    
    // Add state for the selected transport mode for each row.
    @State private var selectedMyTransport: TransportMode? = nil
    @State private var selectedFriendTransport: TransportMode? = nil
    
    // Flag to detect whether the friend’s transport was manually changed.
       @State private var friendTransportManuallyChanged: Bool = false

    

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
                        text: $myLocation,
                        isDirty: !myLocation.isEmpty,
                        selectedMode: $selectedMyTransport
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
                        text: $friendLocation,
                        isDirty: !friendLocation.isEmpty,
                        selectedMode: $selectedFriendTransport
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
                
                
                // MARK: Autocomplete Section
                if myLocation.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 || friendLocation.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 {
                    
                    if isMyLocationFocused && myLocation.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 && !mySearchCompleter.completions.isEmpty {
                        AutocompleteSuggestionsView(
                            completions: mySearchCompleter.completions,
                            text: $myLocation,
                            onSuggestionSelected: {
                                isMyLocationFocused = false
                                isFriendsLocationFocused = true
                                isMyLocationValid = true
                            }
                        )
                    }
                    
                    if isFriendsLocationFocused && friendLocation.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 && !friendSearchCompleter.completions.isEmpty {
                        AutocompleteSuggestionsView(
                            completions: friendSearchCompleter.completions,
                            text: $friendLocation,
                            onSuggestionSelected: {
                                isFriendsLocationFocused = false
                                isFriendsLocationValid = true
                            }
                        )
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
                    .padding(.top, 40)
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
            .padding(.top, -24)
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
                    if isMyLocationValid && isFriendsLocationValid {
                        Button(action: {
                            viewModel.geocodeAddress(myLocation) { userCoord in
                                guard let userCoord = userCoord else {
                                    print("❌ Failed to geocode My Location: \(myLocation)")
                                    return
                                }
                                viewModel.userLocation = userCoord
                                print("✅ My Location geocoded: \(userCoord.latitude), \(userCoord.longitude)")
                                
                                
                                viewModel.reverseGeocodeUserLocation()
                                
                                viewModel.geocodeAddress(friendLocation) { friendCoord in
                                    guard let friendCoord = friendCoord else {
                                        print("❌ Failed to geocode Friend's Location: \(friendLocation)")
                                        return
                                    }
                                    viewModel.friendLocation = friendCoord
                                    print("✅ Friend's Location geocoded: \(friendCoord.latitude), \(friendCoord.longitude)")
                                    
                                    DispatchQueue.main.async {
                                        print("🟢 friendLocation before reverse geocode: \(String(describing: viewModel.friendLocation))")
                                        
                                        viewModel.reverseGeocodeFriendLocation()
                                        
                                        onDone()
                                    }
                                    
                                }
                            }
                        }) {
                            Text("Done")
                                .foregroundColor(.primary)
                        }
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
//                                placemark.thoroughfare,
//                                placemark.subThoroughfare,
                                placemark.locality,
                                placemark.administrativeArea,
//                                placemark.postalCode,
//                                placemark.country
                            ]
                            .compactMap { $0 }
                            .joined(separator: ", ")
                            DispatchQueue.main.async {
                                myLocation = address
                                isMyLocationValid = true
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
                // Validate "My Location" based on autocomplete suggestions.
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
            .onChange(of: friendLocation) { newValue in
                friendSearchCompleter.updateQuery(newValue)
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if trimmed.count >= 5, !friendSearchCompleter.completions.isEmpty {
                    let valid = friendSearchCompleter.completions.contains { suggestion in
                        let suggestionAddress = "\(suggestion.title) \(suggestion.subtitle)"
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .lowercased()
                        return suggestionAddress.contains(trimmed) || trimmed.contains(suggestionAddress)
                    }
                    isFriendsLocationValid = valid
                } else {
                    isFriendsLocationValid = false
                }
            }
            
            // When "My Transport" changes, update friend's transport (if the friend hasn't been manually changed).
            .onChange(of: selectedMyTransport) { newValue in
                if !friendTransportManuallyChanged {
                    selectedFriendTransport = newValue
                }
            }
            // If the friend’s selection deviates from "My Transport," mark it as manually changed.
            .onChange(of: selectedFriendTransport) { newValue in
                if newValue != selectedMyTransport {
                    friendTransportManuallyChanged = true
                } else {
                    friendTransportManuallyChanged = false
                }
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
