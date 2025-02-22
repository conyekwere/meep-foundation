//
//  AutocompleteSuggestionsView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/2/25.
//
import SwiftUI
import MapKit

struct AutocompleteSuggestionsView: View {
    let completions: [MKLocalSearchCompletion]
    @Binding var text: String
    // Closure to call when a suggestion is selected.
    var onSuggestionSelected: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(Array(completions.enumerated()), id: \.offset) { index, completion in
                    Button(action: {
                        // Wrap state update in async dispatch.
                        DispatchQueue.main.async {
                            text = "\(completion.title) \(completion.subtitle)".trimmingCharacters(in: .whitespaces)
                            onSuggestionSelected()
                        }
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
                        }
                        .padding(.horizontal, 16)
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

struct AutocompleteSuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        // For preview purposes, we're using an empty completions array.
        AutocompleteSuggestionsView(completions: [], text: .constant("Sample text"), onSuggestionSelected: {})
    }
}
