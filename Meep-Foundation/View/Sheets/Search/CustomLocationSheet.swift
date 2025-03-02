//
//  CustomLocationSheet.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 2/28/25.
//

import SwiftUI
import CoreLocation

struct CustomLocationSheet: View {
    // Use StateObject to properly access the shared instance
    @StateObject private var locationsManager = UserLocationsManager.shared
    @Binding var isPresented: Bool
    @State private var showAddLocationSheet = false
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
                // Header with drag indicator
                VStack(spacing: 8) {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 5)
                    
                    Text("Saved Locations")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontWidth(.expanded)
                }
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                if locationsManager.customLocations.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.blue.opacity(0.6))
                            .padding(.top, 60)
                        
                        Text("No saved locations")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Add places you visit frequently")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding()
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
                                    // Future implementation: Show add home location sheet
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
                                    // Future implementation: Show add work location sheet
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
                                    iconColor: .red,
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
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
        .sheet(isPresented: $showAddLocationSheet) {
            AddLocationView(isPresented: $showAddLocationSheet)
        }
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

// View for adding a new custom location
struct AddLocationView: View {
    // Use StateObject to properly access the shared instance
    @StateObject private var locationsManager = UserLocationsManager.shared
    @Binding var isPresented: Bool
    
    @State private var locationName = ""
    @State private var locationAddress = ""
    @FocusState private var focusedField: Field?
    
    @State private var showAddressSearch = false
    @StateObject private var searchCompleter = LocalSearchCompleterDelegate()
    
    enum Field {
        case name, address
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("LOCATION DETAILS")) {
                    TextField("Location name", text: $locationName)
                        .focused($focusedField, equals: .name)
                    
                    Button(action: {
                        showAddressSearch = true
                    }) {
                        HStack {
                            if locationAddress.isEmpty {
                                Text("Search address")
                                    .foregroundColor(.gray)
                            } else {
                                Text(locationAddress)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                if showAddressSearch && !searchCompleter.completions.isEmpty {
                    Section(header: Text("SUGGESTIONS")) {
                        ForEach(Array(searchCompleter.completions.enumerated()), id: \.offset) { index, completion in
                            Button(action: {
                                locationAddress = "\(completion.title) \(completion.subtitle)".trimmingCharacters(in: .whitespaces)
                                showAddressSearch = false
                            }) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.red)
                                    VStack(alignment: .leading) {
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
                }
            }
            .navigationTitle("Add New Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !locationName.isEmpty && !locationAddress.isEmpty {
                            // Geocode the address
                            let geocoder = CLGeocoder()
                            geocoder.geocodeAddressString(locationAddress) { placemarks, error in
                                if let placemark = placemarks?.first, let location = placemark.location {
                                    let newLocation = SavedLocation(
                                        id: UUID().uuidString,
                                        name: locationName,
                                        address: locationAddress,
                                        latitude: location.coordinate.latitude,
                                        longitude: location.coordinate.longitude
                                    )
                                    
                                    locationsManager.addCustomLocation(newLocation)
                                }
                                
                                isPresented = false
                            }
                        }
                    }
                    .disabled(locationName.isEmpty || locationAddress.isEmpty)
                }
            }
            .onAppear {
                focusedField = .name
            }
            .onChange(of: showAddressSearch) { newValue in
                if newValue {
                    searchCompleter.updateQuery(locationAddress)
                }
            }
            .onChange(of: locationAddress) { newValue in
                if showAddressSearch {
                    searchCompleter.updateQuery(newValue)
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
