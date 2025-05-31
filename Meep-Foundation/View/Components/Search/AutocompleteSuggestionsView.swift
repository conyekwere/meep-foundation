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
    @Binding var didSelectSuggestion: Bool
    
    // Optional binding for the selected address
    var selectedAddress: Binding<MKLocalSearchCompletion?>?
    
    // Optional geocode function
    var geocodeAddress: ((MKLocalSearchCompletion) -> Void)?
    
    // Optional completion handler
    var onSuggestionSelected: (() -> Void)?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(completions.indices, id: \.self) { index in
                    let completion = completions[index]
                    Button(action: {
                        handleSuggestionTap(completion: completion)
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
    
    // MARK: - Helper Methods
    private func handleSuggestionTap(completion: MKLocalSearchCompletion) {
        // Mark that a suggestion was deliberately selected
        didSelectSuggestion = true
        
        // Update the text with the primary title only (cleaner approach)
        text = completion.title
        
        // Update selected address if binding is provided
        if let selectedAddressBinding = selectedAddress {
            selectedAddressBinding.wrappedValue = completion
        }
        
        // Call geocode function if provided
        if let geocodeFunc = geocodeAddress {
            geocodeFunc(completion)
        }
        
        // Call completion handler if provided
        if let onComplete = onSuggestionSelected {
            onComplete()
        }
    }
}

// Preview provider
struct AutocompleteSuggestionsView_Previews: PreviewProvider {
    @State static var text = "Sample text"
    @State static var didSelectSuggestion = false

    static var previews: some View {
        AutocompleteSuggestionsView(
            completions: [],
            text: $text,
            didSelectSuggestion: $didSelectSuggestion,
            onSuggestionSelected: {}
        )
    }
}
