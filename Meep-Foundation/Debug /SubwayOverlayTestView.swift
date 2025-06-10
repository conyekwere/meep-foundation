//
//  SubwayOverlayTestView.swift
//  Meep-Foundation
//
//

import SwiftUI
import MapKit

struct SubwayOverlayTestView: View {
    @StateObject private var subwayManager = SubwayMapOverlayManager()
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var showSubway = true
    
    var body: some View {
        ZStack {
            // Base SwiftUI Map
            Map(coordinateRegion: $mapRegion)
                .mapStyle(.standard(elevation: .flat,
                                   pointsOfInterest: .excludingAll,
                                   showsTraffic: false))
                .ignoresSafeArea()
                .overlay(
                    // Subway overlay
                    Group {
                        if showSubway && !subwayManager.subwayPolylines.isEmpty {
                            MapKitOverlayView(
                                polylines: subwayManager.subwayPolylines,
                                mapRegion: mapRegion,
                                overlayManager: subwayManager
                            )
                            .allowsHitTesting(false)
                        }
                    }
                )
            
            // Debug controls
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subway Debug")
                            .font(.headline)
                        Text("Lines: \(subwayManager.subwayPolylines.count)")
                        Text("Stations: \(subwayManager.subwayAnnotations.count)")
                        Text("Loading: \(subwayManager.isLoading ? "Yes" : "No")")
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            showSubway.toggle()
                        }) {
                            Label(showSubway ? "Hide" : "Show", systemImage: "tram.fill")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(showSubway ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            subwayManager.loadSubwayData()
                        }) {
                            Label("Reload", systemImage: "arrow.clockwise")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            subwayManager.clearData()
                        }) {
                            Label("Clear", systemImage: "trash")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                .padding()
                
                Spacer()
                
                // Test different regions
                HStack(spacing: 16) {
                    Button("Manhattan") {
                        withAnimation {
                            mapRegion = MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: 40.7831, longitude: -73.9712),
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            )
                        }
                    }
                    
                    Button("Brooklyn") {
                        withAnimation {
                            mapRegion = MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: 40.6782, longitude: -73.9442),
                                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                            )
                        }
                    }
                    
                    Button("Queens") {
                        withAnimation {
                            mapRegion = MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: 40.7282, longitude: -73.7949),
                                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                            )
                        }
                    }
                    
                    Button("All NYC") {
                        withAnimation {
                            mapRegion = MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                                span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
                            )
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
                .padding()
            }
        }
        .onAppear {
            subwayManager.loadSubwayData()
        }
    }
}

#Preview {
    SubwayOverlayTestView()
}
