//
//  SearchTextFieldRow.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/1/25.
//

import SwiftUI

struct SearchTextFieldRow: View {
    let leadingIcon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let isDirty: Bool
    @Binding var selectedMode: TransportMode?
    var isValid: Bool? = nil
    

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Leading Icon
            if let isValid = isValid {
                Image(systemName: isValid ? leadingIcon : "exclamationmark.square")
                    .foregroundColor(isDirty ? (isValid ? .blue : .red) : Color(.label).opacity(0.4))
                    .font(.headline)
                    .padding(.leading, 16)
            } else {
                // Default icon when no validation state is provided
                Image(systemName: leadingIcon)
                    .foregroundColor(isDirty ? .blue : Color(.label).opacity(0.4))
                    .font(.headline)
                    .padding(.leading, 16)
            }

            // TextField with Dynamic Placeholder
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color(.systemGray4))
                        .offset(y: 2)
                }

                TextField("", text: $text)
                    .foregroundColor(.primary)
                    .frame(height: 50, alignment: .leading)
                    .offset(y: 2)
                    .padding(.vertical, 8)
                    .focused($isTextFieldFocused)
            }
            
            if isDirty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }

            // Trailing Icon with TAP-based Menu
            // Trailing Icon with a Menu
            Menu {
                ForEach(TransportMode.allCases) { mode in
                    Button {
                        // Update the binding when a mode is tapped.
                        selectedMode = mode
                        print("\(mode.title) selected")
                    } label: {
                        HStack {
                            // Show a checkmark if this mode is selected.
                            if selectedMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                            Label(mode.title, systemImage: mode.systemImageName)
                        }
                    }
                }
            } label: {
                // The trailing icon shows the selected mode’s image,
                // or a default image if nothing has been selected yet.
                Image(systemName: selectedMode?.systemImageName ?? "tram.fill")
                    .foregroundColor(Color(.label).opacity(0.4))
                    .font(.subheadline)
                    .padding(.trailing, 16)
            }
        }
    }
}
//
//
//
//struct SearchTextFieldRow: View {
//    let leadingIcon: String
//    let title: String
//    let placeholder: String
//    @Binding var text: String
//    let isDirty: Bool
//    @Binding var selectedMode: TransportMode?
//    var isValid: Bool? = nil  // New parameter, optional to maintain backward compatibility
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            // Title
//            Text(title)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .padding(.horizontal, 16)
//            
//            // Input row
//            HStack(spacing: 12) {
//                // Leading icon
//                Image(systemName: leadingIcon)
//                    .foregroundColor(isValid == false ? .red : .blue)
//                    .font(.headline)
//                
//                // Text field
//                TextField(placeholder, text: $text)
//                    .autocapitalization(.none)
//                    .disableAutocorrection(true)
//                
//                // Clear button (when text isn't empty)
//                if isDirty {
//                    Button(action: {
//                        text = ""
//                    }) {
//                        Image(systemName: "xmark.circle.fill")
//                            .foregroundColor(.gray)
//                    }
//                }
//                
//                // Optional validation indicator
//                if let isValid = isValid {
//                    Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
//                        .foregroundColor(isValid ? .green : .red)
//                        .opacity(isDirty ? 1.0 : 0.0) // Only show if field has content
//                }
//                
//                // Transport mode selector
//                Menu {
//                    ForEach(TransportMode.allCases) { mode in
//                        Button {
//                            // Update the binding when a mode is tapped.
//                            selectedMode = mode
//                            print("\(mode.title) selected")
//                        } label: {
//                            HStack {
//                                // Show a checkmark if this mode is selected.
//                                if selectedMode == mode {
//                                    Image(systemName: "checkmark")
//                                        .foregroundColor(.blue)
//                                }
//                                Label(mode.title, systemImage: mode.systemImageName)
//                            }
//                        }
//                    }
//                } label: {
//                    // The trailing icon shows the selected mode’s image,
//                    // or a default image if nothing has been selected yet.
//                    Image(systemName: selectedMode?.systemImageName ?? "tram.fill")
//                        .foregroundColor(Color(.label).opacity(0.4))
//                        .font(.subheadline)
//                        .padding(.trailing, 16)
//                }
//
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 12)
//        }
//    }
//}
