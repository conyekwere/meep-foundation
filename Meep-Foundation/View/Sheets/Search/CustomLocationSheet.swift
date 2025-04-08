//
//  CustomLocationSheet.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/28/25.
//

import SwiftUI
import CoreLocation
import MapKit

struct CustomLocationSheet: View {
    // Use StateObject to properly access the shared instance
    @StateObject private var locationsManager = UserLocationsManager.shared
    @Binding var isPresented: Bool
    @State private var showAddLocationSheet = false
    @State private var showAddHomeAddressSheet = false
    @State private var showAddWorkAddressSheet = false
    @State private var newLocationName = ""
    @State private var newLocationAddress = ""
    @State private var editMode: EditMode = .inactive
    @FocusState private var focusedField: Field?
    
    var onLocationSelected: (SavedLocation) -> Void
    
    enum Field {
        case name, address
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                if locationsManager.customLocations.isEmpty {
                    // Empty state
                    
                    Spacer()
                    VStack(spacing: 16) {
               
                        Image(systemName: "mappin.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.blue.opacity(0.9))
                            
                        
                        Text("No saved locations")
                            .font(.headline)
                            .foregroundColor(Color(.label)).opacity(0.9)
                            .foregroundColor(.secondary)
                           
                        
                        Text("Add places you visit frequently")
                            .font(.subheadline)
                            .foregroundColor(Color(.label)).opacity(0.8)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            showAddLocationSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add new location")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.top, -80)
                   
                    Spacer()
                } else {
                    // List of custom locations
                    List {
                        Section(header: Text("HOME & WORK")) {
                            if let home = locationsManager.homeLocation {
                                LocationRow(
                                    location: home,
                                    icon: "house.fill",
                                    iconColor: .blue,
                                    onTap: {
                                        onLocationSelected(home)
                                        isPresented = false
                                    }
                                )
                            } else {
                                Button(action: {
                                    showAddHomeAddressSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "house")
                                            .foregroundColor(.gray)
                                        Text("Add home location")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            
                            if let work = locationsManager.workLocation {
                                LocationRow(
                                    location: work,
                                    icon: "briefcase.fill",
                                    iconColor: .blue,
                                    onTap: {
                                        onLocationSelected(work)
                                        isPresented = false
                                    }
                                )
                            } else {
                                Button(action: {
                                    showAddWorkAddressSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "briefcase")
                                            .foregroundColor(.gray)
                                        Text("Add work location")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        
                        Section(header: Text("CUSTOM LOCATIONS")) {
                            ForEach(locationsManager.customLocations) { location in
                                LocationRow(
                                    location: location,
                                    icon: "mappin.circle.fill",
                                    iconColor: .green,
                                    onTap: {
                                        onLocationSelected(location)
                                        isPresented = false
                                    }
                                )
                            }
                            .onDelete { indexSet in
                                // Directly call delete method on the locationsManager
                                locationsManager.deleteCustomLocations(at: indexSet)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }

            .toolbar {
                      ToolbarItem(placement:.navigationBarLeading) {
                          Button(action: {
                              print("DEBUG: Back Button Tapped")
                              isPresented = false
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
                              Text("Saved Locations")
                                  .font(.headline)
                                  .fontWeight(.semibold)
                                  .fontWidth(.expanded)
                                  .foregroundColor(Color(.darkGray))
                          }
                          .padding(.top, 8)
                      }
                      ToolbarItem(placement: .navigationBarTrailing) {
                          if !locationsManager.customLocations.isEmpty {
                              EditButton()
                          }
                          
                      }
                      
                      ToolbarItem(placement: .bottomBar) {
                          if !locationsManager.customLocations.isEmpty {
                              Button(action: {
                                  showAddLocationSheet = true
                              }) {
                                  HStack {
                                      Image(systemName: "plus.circle.fill")
                                      Text("Add new location")
                                  }
                                  .font(.headline)
                              }
                              .padding()
                          }
                      }
                      
                      
                  }
                  .environment(\.editMode, $editMode)
              }
              // Regular custom location sheet
              .sheet(isPresented: $showAddLocationSheet) {
                  AddCustomLocationView(isPresented: $showAddLocationSheet)
              }
              // Home address sheet
              .fullScreenCover(isPresented: $showAddHomeAddressSheet) {
                  AddressInputView(
                      viewModel: MeepViewModel(), // Create a new viewModel or inject from parent
                      addressType: .home,
                      onSave: { savedLocation in
                          locationsManager.saveHomeLocation(
                              address: savedLocation.address,
                              coordinate: CLLocationCoordinate2D(
                                  latitude: savedLocation.latitude,
                                  longitude: savedLocation.longitude
                              )
                          )
                      }
                  )
              }
              // Work address sheet
              .fullScreenCover(isPresented: $showAddWorkAddressSheet) {
                  AddressInputView(
                      viewModel: MeepViewModel(), // Create a new viewModel or inject from parent
                      addressType: .work,
                      onSave: { savedLocation in
                          locationsManager.saveWorkLocation(
                              address: savedLocation.address,
                              coordinate: CLLocationCoordinate2D(
                                  latitude: savedLocation.latitude,
                                  longitude: savedLocation.longitude
                              )
                          )
                      }
                  )
              }
}

// Helper row view for a saved location
    struct LocationRow: View {
        let location: SavedLocation
        let icon: String
        let iconColor: Color
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                        .frame(width: 32, height: 32)
                        .background(iconColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(location.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .contentShape(Rectangle())
            }
        }
    }
}

struct AddCustomLocationView: View {
    @StateObject private var locationsManager = UserLocationsManager.shared
       @Binding var isPresented: Bool
       
       @State private var locationName = ""
       @State private var locationAddress = ""
       @FocusState private var focusedField: Field?
       
       @State private var showAddressSearch = false
       @StateObject private var searchCompleter = LocalSearchCompleterDelegate()
       @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
       @State private var isSearching = false
       @State private var errorMessage: String? = nil
       
       // Add this to force UI refreshes
       @State private var forceRefresh: Bool = false
       
       enum Field {
           case name, address
       }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with title and close button
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
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
                    
                    Spacer()
                    
                    Text("Add New Location")
                        .font(.subheadline)
                          .fontWeight(.semibold)
                          .fontWidth(.expanded)
                          .foregroundColor(Color(.darkGray))
                          .padding(.leading, -24)
                    
                    Spacer()
                    
                    // Add save button in header
                    Button(action: {
                        saveLocation()
                    }) {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundColor(canSave ? .blue : .gray.opacity(0.5))
                    }
                    .disabled(!canSave)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background(Color(.systemBackground))
                
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Information section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name your location")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Add a name that will help you remember this place")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 8)
                            
                            // Name input field
                            TextField("Home, Work, Gym, etc.", text: $locationName)
                                .padding()
                                .cornerRadius(10)
                                .focused($focusedField, equals: .name)
                                
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray6), lineWidth: 2)
                                )
                            
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // Address section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Location address")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Enter an address or search for a place")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 8)
                            
                            // Address search field
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                
                                ZStack(alignment: .leading) {
                                    if locationAddress.isEmpty {
                                        Text("Search for an address")
                                            .foregroundColor(.gray)
                                    }
                                    
                                    TextField("", text: $locationAddress)
                                        .focused($focusedField, equals: .address)
                                        .onChange(of: locationAddress) { newValue in
                                            showAddressSearch = newValue.count > 2
                                            searchCompleter.updateQuery(newValue)
                                            // Reset selected coordinate when address changes
                                            selectedCoordinate = nil
                                        }
                                }
                                
                                if !locationAddress.isEmpty {
                                    Button(action: {
                                        locationAddress = ""
                                        selectedCoordinate = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray6), lineWidth: 2)
                            )
                            .cornerRadius(10)
                            
                            // Display validation or selected address
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            } else if selectedCoordinate != nil {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Address verified")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal)
                        
                        // AutocompleteSuggestionsView integration
                        if showAddressSearch && !searchCompleter.completions.isEmpty {
                            AutocompleteSuggestionsView(
                                completions: searchCompleter.completions,
                                text: $locationAddress,
                                geocodeAddress: { completion in
                                    // Call your existing selectCompletion function
                                    selectCompletion(completion)
                                },
                                onSuggestionSelected: {
                                    showAddressSearch = false
                                    focusedField = nil // Hide keyboard
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                }
                
                // Bottom save button (for larger screens and better UX)
                VStack {
                    Divider()
                    
                    Button(action: {
                        saveLocation()
                    }) {
                        Text("Save New Location")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSave ? Color.blue : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!canSave)
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                focusedField = .name
            }
        }.id(forceRefresh)
    }
    
    private var canSave: Bool {
        let nameValid = !locationName.isEmpty
        let addressValid = !locationAddress.isEmpty
        let coordinateValid = selectedCoordinate != nil
        
        return nameValid && addressValid && coordinateValid
    }
    

    
    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        // Update the text field
        locationAddress = "\(completion.title), \(completion.subtitle)"
        
        // Hide search results
        showAddressSearch = false
        
        // Geocode the selected address
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            if let error = error {
                errorMessage = "Could not find this address: \(error.localizedDescription)"
                return
            }
            
            guard let response = response, let item = response.mapItems.first else {
                errorMessage = "Could not find this address. Please try another."
                return
            }
            
            // Set the coordinate
            selectedCoordinate = item.placemark.coordinate
            
            // Format the address
            let placemark = item.placemark
            var addressComponents: [String] = []
            
            if let streetNumber = placemark.subThoroughfare,
               let streetName = placemark.thoroughfare {
                addressComponents.append("\(streetNumber) \(streetName)")
            } else if let name = placemark.name {
                addressComponents.append(name)
            }
            
            var cityState = ""
            if let city = placemark.locality {
                cityState += city
            }
            
            if let state = placemark.administrativeArea {
                if !cityState.isEmpty {
                    cityState += ", "
                }
                cityState += state
            }
            
            if !cityState.isEmpty {
                addressComponents.append(cityState)
            }
            
            if let country = placemark.country {
                addressComponents.append(country)
            }
            
            // Update with formatted address
            DispatchQueue.main.async {
                locationAddress = addressComponents.joined(separator: ", ")
                forceRefresh.toggle() // Force UI update
            }
        }
    }
    
    private func saveLocation() {
        // Make sure we have name and address
        guard !locationName.isEmpty && !locationAddress.isEmpty else {
            return
        }
        
        // If we already have coordinates, save directly
        if let coordinate = selectedCoordinate {
            let newLocation = SavedLocation(
                id: UUID().uuidString,
                name: locationName,
                address: locationAddress,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            
            locationsManager.addCustomLocation(newLocation)
            isPresented = false
        } else {
            // Need to geocode first
            isSearching = true
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(locationAddress) { placemarks, error in
                DispatchQueue.main.async {
                    isSearching = false
                    
                    if let error = error {
                        errorMessage = "Could not find this address: \(error.localizedDescription)"
                        return
                    }
                    
                    if let placemark = placemarks?.first, let location = placemark.location {
                        let newLocation = SavedLocation(
                            id: UUID().uuidString,
                            name: self.locationName,
                            address: self.locationAddress,
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        )
                        
                        self.locationsManager.addCustomLocation(newLocation)
                        self.isPresented = false
                    } else {
                        self.errorMessage = "Could not find this address. Please try again."
                    }
                }
            }
        }
    }
}

#Preview {
    CustomLocationSheet(
        isPresented: .constant(true),
        onLocationSelected: { _ in }
    )
}
