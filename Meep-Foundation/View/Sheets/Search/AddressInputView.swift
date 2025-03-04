//
//  AddressInputView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/1/25.
//


import SwiftUI
import MapKit
import CoreLocation



struct AddressInputView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var locationManager = UserLocationsManager.shared
    @StateObject private var searchCompleter = LocalSearchCompleterDelegate()
    
    @ObservedObject var viewModel: MeepViewModel
    
    
    @State private var addressText = ""
    @State private var selectedAddress: MKLocalSearchCompletion?
    @State private var customLocationName = ""
    @State private var showSuccessScreen = false
    @State private var geocodedLocation: CLLocationCoordinate2D?
    @State private var fullAddress = ""
    
    let addressType: AddressType
    let onSave: ((SavedLocation) -> Void)?
    
    var body: some View {
        ZStack {
            if showSuccessScreen, let coordinate = geocodedLocation {

                AddressConfirmationView(
                    viewModel: viewModel,
                    addressType: addressType,
                    address: fullAddress,
                    coordinate: coordinate,
                    customName: addressType == .custom ? customLocationName : addressType.rawValue,
                    onDone: {
                        // Save location based on type
                        switch addressType {
                        case .home:
                            locationManager.saveHomeLocation(address: fullAddress, coordinate: coordinate)
                        case .work:
                            locationManager.saveWorkLocation(address: fullAddress, coordinate: coordinate)
                        case .custom:
                            let newLocation = SavedLocation(
                                id: UUID().uuidString,
                                name: customLocationName,
                                address: fullAddress,
                                latitude: coordinate.latitude,
                                longitude: coordinate.longitude
                            )
                            locationManager.addCustomLocation(newLocation)
                            if let onSave = onSave {
                                onSave(newLocation)
                            }
                        }
                        presentationMode.wrappedValue.dismiss()
                    },
                    onSuggestEdit: {
                        showSuccessScreen = false
                    }
                )
            } else {
                NavigationStack {
                    VStack(spacing: 0) {
                        // Search field
                        VStack(spacing: 0) {
                            HStack {
                                
                                Button(action: {
        
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.gray)
                                }
                                
                                TextField("Enter \(addressType.rawValue.lowercased()) address", text: $addressText)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(.leading, 12)
                                
                                if !addressText.isEmpty {
                                    Button(action: {
                                        addressText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                

                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            
                            if addressType == .custom && !addressText.isEmpty {
                                TextField("Location name (e.g., Gym, School)", text: $customLocationName)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray5), lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.vertical, 16)
                        

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
                        
                        
                        // Autocomplete suggestions
                        if !searchCompleter.completions.isEmpty {
                            List {
                                ForEach(searchCompleter.completions, id: \.self) { completion in
                                    Button(action: {
                                        // Handle selection of autocomplete suggestion
                                        selectedAddress = completion
                                        addressText = "\(completion.title) \(completion.subtitle)".trimmingCharacters(in: .whitespaces)
                                        
                                        // Geocode the address to get coordinates
                                        geocodeAddress(completion)
                                    }) {
                                        HStack(spacing: 16) {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.title3)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(completion.title)
                                                    .foregroundColor(.primary)
                                                
                                                Text(completion.subtitle)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                        
                        Spacer()
                    }
                    .navigationBarTitle("", displayMode: .inline)
                    .navigationBarItems(
                        leading: Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.primary)
                        },
                        trailing: Button("Done") {
                            if let selected = selectedAddress {
                                geocodeAddress(selected)
                            } else if !addressText.isEmpty {
                                // Geocode manually entered text
                                let geocoder = CLGeocoder()
                                geocoder.geocodeAddressString(addressText) { placemarks, error in
                                    if let placemark = placemarks?.first, let location = placemark.location {
                                        self.geocodedLocation = location.coordinate
                                        
                                        // Format the full address
                                        var addressComponents: [String?] = [
                                            placemark.name,
                                            placemark.locality,
                                            placemark.administrativeArea,
                                        ]
                                        self.fullAddress = addressComponents.compactMap { $0 }.joined(separator: ", ")
                                        
                                        showSuccessScreen = true
                                    }
                                }
                            }
                        }
                        .disabled(addressText.isEmpty || (addressType == .custom && customLocationName.isEmpty))
                    )
                }
            }
        }
        .onChange(of: addressText) { newValue in
            searchCompleter.updateQuery(newValue)
        }
    }
    
    private func geocodeAddress(_ completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let response = response, let item = response.mapItems.first else {
                return
            }
            
            self.geocodedLocation = item.placemark.coordinate
            
            // Create a properly formatted address
            let placemark = item.placemark
            var addressComponents: [String?] = [
                placemark.thoroughfare,
                placemark.locality,
                placemark.administrativeArea
                
            ]
            self.fullAddress = addressComponents.compactMap { $0 }.joined(separator: ", ")
            
            // If no custom name is provided for custom locations, use the title
            if addressType == .custom && customLocationName.isEmpty {
                customLocationName = completion.title
            }
            
            showSuccessScreen = true
        }
    }
}

#Preview {
    AddressInputView(
         viewModel: MeepViewModel(),
         addressType: .home,
        onSave: { savedLocation in
            // Preview handler does nothing
            print("Saved location: \(savedLocation.address)")
        }
    )
}
