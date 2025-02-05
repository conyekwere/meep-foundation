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

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Leading Icon
            Image(systemName: leadingIcon)
                .foregroundColor(isDirty ? .blue : Color(.label).opacity(0.4))
                .font(.headline)
                .padding(.leading, 16)

            // TextField with Dynamic Placeholder
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color(.systemGray3))
                        .offset(y: 2)
                }

                TextField("", text: $text)
                    .foregroundColor(.primary)
                    .frame(height: 50, alignment: .leading)
                    .offset(y: 2)
                    .padding(.vertical, 8)
                    .focused($isTextFieldFocused)
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

