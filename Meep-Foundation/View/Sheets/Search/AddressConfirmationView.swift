//
//  AddressConfirmationView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/1/25.
//
//
import SwiftUI
import MapKit
import CoreLocation



struct AddressConfirmationView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var viewModel: MeepViewModel
    
    let addressType: AddressType
    let address: String
    let coordinate: CLLocationCoordinate2D
    let customName: String
    let onDone: () -> Void
    let onSuggestEdit: () -> Void
    
    @State private var selectedAnnotation: MeepAnnotation? = nil
    
    // Use a separate region state for this map view
    @State private var region: MKCoordinateRegion
    
    // Create a single-item array of annotations for the confirmed address
    private var locationAnnotations: [MeepAnnotation] {
        let type: AnnotationType
        switch addressType {
        case .home:
            type = .user
        case .work:
            type = .user
        case .custom:
            type = .place(emoji: "📍")
        }
        
        return [MeepAnnotation(coordinate: coordinate, title: address, type: type)]
    }
    
    init(viewModel: MeepViewModel, addressType: AddressType, address: String, coordinate: CLLocationCoordinate2D, customName: String, onDone: @escaping () -> Void, onSuggestEdit: @escaping () -> Void) {
        self.viewModel = viewModel
        self.addressType = addressType
        self.address = address
        self.coordinate = coordinate
        self.customName = customName
        self.onDone = onDone
        self.onSuggestEdit = onSuggestEdit
        
        // Initialize the map region centered on the address with a closer zoom level
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }
    
    private func setSelectedMeetingPoint(for annotation: MeepAnnotation) {
        // Extract emoji from annotation
        let emoji: String
        if case let .place(emojiValue) = annotation.type {
            emoji = emojiValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            emoji = "📍"
        }
        
        // Dynamically get category
        let category = viewModel.getCategory(for: emoji)
        
        // Create a new point
        viewModel.selectedPoint = MeetingPoint(
            name: annotation.title,
            emoji: emoji,
            category: category,
            coordinate: annotation.coordinate,
            imageUrl: "https://via.placeholder.com/400x300?text=Address+Location"
        )
        viewModel.isFloatingCardVisible = true
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title and account info
                VStack(spacing: 8) {
                    Text("Your \(addressType == .custom ? customName : addressType.rawValue.lowercased()) is set")
                        .font(.title3)
                        .padding(.top)
                    
                    Text("Your \(addressType.rawValue.lowercased()) address has been saved in your account and will be used across the app.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom,8)
                
                // Map view with the location annotation
                Map(coordinateRegion: $region,
                    interactionModes: .all,
                    showsUserLocation: true,
                    annotationItems: locationAnnotations) { annotation in
                        MapAnnotation(coordinate: annotation.coordinate) {
                            annotation.annotationView(isSelected: Binding(
                                get: { selectedAnnotation?.id == annotation.id },
                                set: { newValue in
                                    withAnimation(.spring()) {
                                        if newValue {
                                            selectedAnnotation = annotation
                                            setSelectedMeetingPoint(for: annotation)
                                        } else {
                                            selectedAnnotation = nil
                                            viewModel.isFloatingCardVisible = false
                                        }
                                    }
                                }
                            ))
                        }
                    }
                    .mapStyle(.standard(elevation: .flat,
                                       pointsOfInterest: .excludingAll,
                                       showsTraffic: false))
                    .frame(height: 250)
                    .cornerRadius(12)
                    .padding(.top,24)
                
                
                
                // "Pin in wrong location" text and button
                VStack(spacing: 8) {
                    
                    Text(address)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.bottom,24)
                    Text("Pin in the wrong location?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        onSuggestEdit()
                    }) {
                        Text("Suggest an edit")
                            .foregroundColor(.blue)
                            .font(.headline)
                    }
                }
                .padding(.top,48)
                
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

struct AddressConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        AddressConfirmationView(
            viewModel: MeepViewModel(),
            addressType: .home,
            address: "123 Main St, San Francisco, CA",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            customName: "Home",
            onDone: {},
            onSuggestEdit: {}
        )
    }
}
