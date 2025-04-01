//
//  ManualLocationEntryView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/23/25.
//


// ManualLocationEntryView.swift
import SwiftUI
import MapKit
import CoreLocation

struct ManualLocationEntryView: View {
    var userName: String
    var requestID: String
    var onLocationSelected: (CLLocationCoordinate2D) -> Void
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("Search for a location", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .onChange(of: searchText) { _ in
                        searchLocations()
                    }
                
                // Results list
                List(searchResults, id: \.self) { result in
                    Button(action: {
                        if let coordinate = result.placemark.location?.coordinate {
                            onLocationSelected(coordinate)
                            dismiss()
                        }
                    }) {
                        VStack(alignment: .leading) {
                            Text(result.name ?? "Unknown Location")
                                .font(.headline)
                            
                            Text(formatAddress(result.placemark))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Enter Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Search for locations
    private func searchLocations() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.searchResults = response.mapItems
            }
        }
    }
    
    // Format address from placemark
    private func formatAddress(_ placemark: MKPlacemark) -> String {
        let components = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode,
            placemark.country
        ].compactMap { $0 }
        
        return components.joined(separator: ", ")
    }
}