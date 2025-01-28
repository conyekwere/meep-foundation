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
    var onDismiss: () -> Void
    
    var onDone: () -> Void
    var body: some View {
        
        NavigationStack {
            VStack(spacing: 40) {
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
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 24) {
                        
                        SuggestionButton(icon: "house", title: "Set location", label: "Home", action: {
                            print("Home tapped")
                        })
                        
                        SuggestionButton(icon: "briefcase", title: "Set location", label: "Work", action: {
                            print("Work tapped")
                        })
                        SuggestionButton(icon: "ellipsis", title: "", label: "More", action: {
                            print("More tapped")
                        })
                    }
                    .padding(.horizontal, 16)
                    
                }
                .scrollTargetLayout()
                .safeAreaPadding(.trailing, 16)
                .scrollIndicators(.hidden)
                .scrollClipDisabled(true)
                
                if isMyLocationFocused {
                    // Current Location Section
                    Button(action: {
                        print("Current Location selected")
                    }) {
                        HStack(spacing:16) {
                            
                            Image(systemName: "location.fill")
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
                // Ask for a Friend's Location Section
                Button(action: {
                    print("Ask for Friend's Location selected")
                }) {
                    HStack(spacing:16) {
                        
                        Image(systemName: "message.fill")
                            .font(.callout)
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color(hex: "E8F0FE"))
                            .clipShape(Circle())
                        
                        Text("Ask for a Friend's Location")
                            .foregroundColor(.primary)
                            .font(.body)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
            .ignoresSafeArea(edges: .bottom)
            .onAppear {
                // Automatically focus on "My Location" when the view appears
                if isSearchActive {
                    isMyLocationFocused = true
                }
            }
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
                            .font(.system(size: 12))
                            .frame(width: 40, height: 40, alignment: .center)
                            .font(.system(size: 16))
                            .foregroundColor(Color(.gray))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color(.systemGray6),    lineWidth: 2)
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Set meeting point")
                            .font(.headline)
                            .fontWidth(.expanded)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary) // Explicitly set the color
                    }
                    .padding(.top, 8)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        onDone()
                    }) {
                        Text("Done")
                            .foregroundColor(.primary)
                    }
                }
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
    let title: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundColor(.blue)
                 
                    .foregroundColor(Color(.gray))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "E8F0FE"))
                    .clipShape(Circle())
                   
                if title.isEmpty{
                    Text(label)
                        .font(.callout)
                        .foregroundColor(.primary)
                }
                else{
                    VStack(alignment: .leading) {
                        Text(label)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text(title)
                            .font(.callout)
                            .foregroundColor(Color(.darkGray))
                    }
                }
                
            }
        }
    }
}

#Preview {
    MeetingSearchSheetView(viewModel: MeepViewModel(), isSearchActive: .constant(false),
                           onDismiss: {
                               print("Back button tapped")
                           },onDone: {
                               print("Done  tapped")
                           } )
}
