//
//  AppClipView.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/23/25.
//

import SwiftUI
import CoreLocation
import AppClip

struct AppClipView: View {
    
    let initialURL: URL?
    
    // State variables
    @State private var userName: String = "Someone"
    @State private var requestID: String = UUID().uuidString
    @State private var userId: String = ""
    @State private var isRequestingLocation = false
    @State private var showManualEntry = false
    @State private var locationSent = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Location Manager - FIXED: Removed duplicate declaration
    @StateObject private var locationManager = LocationManager()
    
    // Environment objects
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if !locationSent {
                mainContent
            } else {
                successView
            }
            
            if isRequestingLocation {
                loadingOverlay
            }
        }
        .onAppear {
            if let url = initialURL {
                parseURL(url)
            }
        }
        .onChange(of: initialURL) { newURL in
            if let url = newURL {
                parseURL(url)
            }
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
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Views
    
    private var mainContent: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Location Request")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            // Request info card
            VStack(spacing: 12) {
                Text("\(userName) wants to meet up!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("Share your location to help find a convenient meeting point. Your exact location will be kept private.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 2)
            .padding(.horizontal)
            
            Spacer()
            
            // Action buttons
            actionButtons
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: requestCurrentLocation) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Share Current Location")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(isRequestingLocation)
            
            Button(action: { showManualEntry = true }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Enter Location Manually")
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
            }
            
            Button(action: { dismiss() }) {
                Text("Not Now")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 40)
    }
    
    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Location Shared!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your location has been shared with \(userName)")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Done") {
                dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.top, 20)
        }
    }
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Getting location...")
                        .foregroundColor(.white)
                        .padding(.top, 10)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
            )
    }
    
    // MARK: - Functions
    
    private func parseURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return }

        // Prefer the `username` param over `userName` for display
        for item in queryItems {
            switch item.name {
            case "username":
                userName = item.value ?? userName
            case "userName":
                if userName == "Someone" { userName = item.value ?? "Someone" }
            case "requestID":
                requestID = item.value ?? UUID().uuidString
            case "userId":
                userId = item.value ?? ""
            default:
                break
            }
        }

        print("Parsed - userName: \(userName), requestID: \(requestID), userId: \(userId)")
    }
    
    private func requestCurrentLocation() {
        isRequestingLocation = true
        
        locationManager.requestLocation { result in
            isRequestingLocation = false
            
            switch result {
            case .success(let coordinate):
                sendLocationToBackend(location: coordinate)
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func sendLocationToBackend(location: CLLocationCoordinate2D) {
        // Add some random offset to hide exact location (±500m)
        let latOffset = Double.random(in: -0.0045...0.0045)
        let lonOffset = Double.random(in: -0.0045...0.0045)
        
        let obfuscatedLocation = CLLocationCoordinate2D(
            latitude: location.latitude + latOffset,
            longitude: location.longitude + lonOffset
        )
        
        // Prepare data
        let data: [String: Any] = [
            "requestID": requestID,
            "latitude": obfuscatedLocation.latitude,
            "longitude": obfuscatedLocation.longitude,
            "timestamp": Date().timeIntervalSince1970,
            "responderId": UUID().uuidString
        ]
        
        // TODO: Implement actual Firebase call here
        print("Sending location data: \(data)")
        
        // Simulate success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                self.locationSent = true
            }
        }
    }
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationCompletion: ((Result<CLLocationCoordinate2D, Error>) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation(completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void) {
        locationCompletion = completion
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            completion(.failure(LocationError.denied))
        @unknown default:
            completion(.failure(LocationError.unknown))
        }
    }
    
    // CLLocationManagerDelegate methods
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            locationCompletion?(.failure(LocationError.denied))
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationCompletion?(.success(location.coordinate))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationCompletion?(.failure(error))
    }
}

enum LocationError: LocalizedError {
    case denied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .denied:
            return "Location access denied. Please enable location services in Settings."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

#Preview {
    AppClipView(initialURL: URL(string: "https://meep.earth/share?userName=TestUser&requestID=test123"))
}
