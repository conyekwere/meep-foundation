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
    
    // Optional binding for the selected address
    var selectedAddress: Binding<MKLocalSearchCompletion?>?
    
    // Optional geocode function
    var geocodeAddress: ((MKLocalSearchCompletion) -> Void)?
    
    // Optional completion handler
    var onSuggestionSelected: (() -> Void)?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(completions, id: \.self) { completion in
                    Button(action: {
                        // Update the text field
                        text = "\(completion.title) \(completion.subtitle)".trimmingCharacters(in: .whitespaces)
                        
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

// Preview provider
struct AutocompleteSuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        AutocompleteSuggestionsView(
            completions: [],
            text: .constant("Sample text"),
            onSuggestionSelected: {}
        )
    }
}
