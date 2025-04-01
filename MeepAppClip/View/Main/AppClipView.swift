//
//  AppClipView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/23/25.
//


import SwiftUI
import CoreLocation

struct AppClipView: View {
    // State variables
    @State private var userName: String = ""
    @State private var requestID: String = ""
    @State private var locationManager = CLLocationManager()
    @State private var isRequestingLocation = false
    @State private var showManualEntry = false
    @State private var locationSent = false
    
    // Environment objects
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background color or image
            Color.gray.opacity(0.2)
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 20) {
                // User image
                Image("profile_placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .padding(.top, 40)
                
                // Request text
                Text("\(userName) would like to access your location range to find a meeting point?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text("Your exact coordinates will be hidden but this will allow \(userName.split(separator: " ").first ?? "") to find potential places to meet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                // Location sharing buttons
                VStack(spacing: 12) {
                    Button(action: {
                        requestCurrentLocation()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.white)
                            Text("Current Location")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showManualEntry = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.black)
                            Text("Enter Manually")
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            parseURLParameters()
        }
        .sheet(isPresented: $showManualEntry) {
            ManualLocationEntryView(
                userName: userName,
                requestID: requestID,
                onLocationSelected: { location in
                    sendLocationToBackend(location: location)
                }
            )
        }
        .alert("Location Shared", isPresented: $locationSent) {
            Button("OK", role: .cancel) {
                // Close the App Clip
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        } message: {
            Text("Your location has been shared with \(userName).")
        }
    }
    
    // Parse URL parameters from the App Clip invocation
    private func parseURLParameters() {
        guard let urlString = UserDefaults.standard.string(forKey: "AppClipURL"),
              let url = URL(string: urlString) else {
            // For testing purposes, use placeholder values
            userName = "Ashley Dee"
            requestID = UUID().uuidString
            return
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        if let items = components?.queryItems {
            for item in items {
                switch item.name {
                case "userName":
                    userName = item.value ?? "Someone"
                case "requestID":
                    requestID = item.value ?? UUID().uuidString
                default:
                    break
                }
            }
        }
    }
    
    // Request current location
    private func requestCurrentLocation() {
        locationManager.delegate = LocationDelegate(completion: { location in
            sendLocationToBackend(location: location)
        })
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    // Send location to backend
    private func sendLocationToBackend(location: CLLocationCoordinate2D) {
        // Prepare data
        let data: [String: Any] = [
            "requestID": requestID,
            "latitude": location.latitude,
            "longitude": location.longitude,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // For Firebase implementation:
        /*
        let db = Firestore.firestore()
        db.collection("locationResponses").document(requestID).setData(data) { error in
            if let error = error {
                print("Error sending location: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.locationSent = true
                }
            }
        }
        */
        
        // For now, just print and simulate success
        print("Sending location data: \(data)")
        DispatchQueue.main.async {
            self.locationSent = true
        }
    }
}

// Location delegate to handle location updates
class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var completion: (CLLocationCoordinate2D) -> Void
    
    init(completion: @escaping (CLLocationCoordinate2D) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        completion(location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
