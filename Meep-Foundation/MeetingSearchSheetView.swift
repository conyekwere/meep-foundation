//
//  MeetingSearchSheetView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/24/25.
//

import SwiftUI

struct MeetingSearchSheetView: View {
    @State private var myLocation: String = ""
    @State private var friendLocation: String = ""
    @ObservedObject var viewModel: MeepViewModel
    @Binding var isSearchActive: Bool
    @FocusState private var isMyLocationFocused: Bool
    @FocusState private var isFriendsLocationFocused: Bool
    var body: some View {
        VStack(spacing: 16) {
            // Drag Handle
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(Color(.lightGray).opacity(0.4))
                .padding(.top, 8)
            
            
            

                VStack(spacing: 0) {
                    
                    // My Location Input Row
                    SearchTextFieldRow(
                        leadingIcon: "dot.square.fill",
                        title: "My Location",
                        placeholder: "What’s your location?",
                        trailingIcon: "tram.fill",
                        text: $myLocation,
                        isDirty: !myLocation.isEmpty,
                        onTrailingIconTap: {
                            
                        }
                        
                    )
                    .focused($isMyLocationFocused)
                    .onSubmit {
                        isMyLocationFocused = false
                    }
                    .overlay(
                        Rectangle()
                            .fill(Color(#colorLiteral(red: 0.971, green: 0.971, blue: 0.971, alpha: 1)))
                            .frame(height:  2)
                            .offset(y: 0), alignment: .bottom
                    )
                    
                    // Friend's Location Input Row
                    SearchTextFieldRow(
                        leadingIcon: "dot.square.fill",
                        title: "Friends Location",
                        placeholder: "What's your friend's location?",
                        trailingIcon: "tram.fill",
                        text: $friendLocation,
                        isDirty: !friendLocation.isEmpty,
                        onTrailingIconTap: {
                            print("Trailing icon tapped")
                        }
                    )
                    .focused($isFriendsLocationFocused) // Bind focus state
                    .onSubmit {
                        isFriendsLocationFocused = false
                    }
                }.cornerRadius( 12)
                    .overlay(
                        RoundedRectangle(cornerRadius:  12)
                            .strokeBorder( Color(#colorLiteral(red: 0.971, green: 0.971, blue: 0.971, alpha: 1)), lineWidth: 2)
                    )
                    .padding(.horizontal, 16)
                
  
            
            
            
            
            // Suggestion Buttons Section
            HStack(spacing: 16) {
                SuggestionButton(icon: "house.fill", label: "Home", action: {
                    print("Home tapped")
                })
                SuggestionButton(icon: "briefcase.fill", label: "Work", action: {
                    print("Work tapped")
                })
                SuggestionButton(icon: "ellipsis.circle", label: "More", action: {
                    print("More tapped")
                })
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Current Location Section
            Button(action: {
                print("Current Location selected")
            }) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color.blue)
                    Text("Current Location")
                        .foregroundColor(.primary)
                        .font(.headline)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            // Ask for a Friend's Location Section
            Button(action: {
                print("Ask for Friend's Location selected")
            }) {
                HStack {
                    Image(systemName: "message.fill")
                        .foregroundColor(Color.blue)
                    Text("Ask for a Friend's Location")
                        .foregroundColor(.primary)
                        .font(.headline)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            // Automatically focus on "My Location" when the view appears
            if isSearchActive {
                isMyLocationFocused = true
            }
        }
    }
}



// Text Field Row
struct SearchTextFieldRow: View {
    let leadingIcon: String
    let title: String
    let placeholder: String
    let trailingIcon: String
    @Binding var text: String
    let isDirty: Bool
    let onTrailingIconTap: () -> Void

    var body: some View {

            HStack(spacing: 16) {
                
                Image(systemName: leadingIcon)
                    .foregroundColor(isDirty ?  .blue : Color(.label).opacity(0.4)  )
                    .font(.headline)
                    .padding(.leading, 16)

                ZStack(alignment: .leading) {
                    TextField(placeholder, text: $text)
                        .foregroundColor(.primary)
                        .frame(height: 50, alignment: .leading)
                        .offset(y:2)
                        .padding(.vertical, 16)
                        .zIndex(1)
                    Text(title)
                        .font(.caption)
                        .fontWidth(.expanded)
                        .foregroundColor(Color(.darkGray))
                        .offset(y:-20)
                        .frame(alignment: .leading)
                }
                Button(action: {
                    onTrailingIconTap()
                }) {
                    
                    Image(systemName: trailingIcon)
                        .foregroundColor( Color(.label).opacity(0.4))
                        .font(.headline)
                        .padding(.trailing, 16)
                }
            }

    }
}

// Suggestion Button
struct SuggestionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.6))
            .cornerRadius(10)
        }
    }
}

#Preview {
    MeetingSearchSheetView(viewModel: MeepViewModel(), isSearchActive: .constant(false))
}
