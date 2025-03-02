//
//  AddressConfirmationView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/1/25.
//


import SwiftUI
import MapKit
import CoreLocation



struct AddressConfirmationView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let addressType: AddressType
    let address: String
    let coordinate: CLLocationCoordinate2D
    let customName: String
    let onDone: () -> Void
    let onSuggestEdit: () -> Void
    
    @State private var region: MKCoordinateRegion
    
    
    struct LocationMapAnnotation: Identifiable {
         let id = UUID()
         let coordinate: CLLocationCoordinate2D
     }
    
    init(addressType: AddressType, address: String, coordinate: CLLocationCoordinate2D, customName: String, onDone: @escaping () -> Void, onSuggestEdit: @escaping () -> Void) {
        self.addressType = addressType
        self.address = address
        self.coordinate = coordinate
        self.customName = customName
        self.onDone = onDone
        self.onSuggestEdit = onSuggestEdit
        
        // Initialize the map region centered on the address
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title and account info
                VStack(spacing: 16) {
                    Text("Your \(addressType == .custom ? customName : addressType.rawValue.lowercased()) is set")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Your \(addressType.rawValue.lowercased()) address has been saved in your account and will be used across the app.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                
                // Map view with a static annotation
//                Map(coordinateRegion: $region,
//                    annotationItems: [LocationMapAnnotation(coordinate: coordinate)]) { location in
//                    MapMarker(coordinate: location.coordinate, tint: addressType.iconColor)
//                }
//                .frame(height: 250)
//                .cornerRadius(12)
//                .padding()
                
                // Address text
                Text(address)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // "Pin in wrong location" text and button
                VStack(spacing: 8) {
                    Text("Pin in the wrong location?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        onSuggestEdit()
                    }) {
                        Text("Suggest an edit")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                }
                .padding()
                
                Spacer()
                
                // Done button
                Button(action: {
                    onDone()
                }) {
                    Text("Done")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(28)
                        .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Simple model for map annotation
struct MapAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    AddressConfirmationView(
        addressType: .home,
        address: "123 Main St, San Francisco, CA",
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        customName: "Home",
        onDone: {},
        onSuggestEdit: {}
    )
}
