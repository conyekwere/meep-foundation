//
//  SubwayMapOverlayManager.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/7/25.
//

import Foundation
import MapKit
import SwiftUI

class SubwayMapOverlayManager: ObservableObject {
    @Published var subwayPolylines: [MKPolyline] = []
    @Published var subwayAnnotations: [MKPointAnnotation] = []
    @Published var isLoading = false
    @Published var hasLoadedData = false
    
    
    var lineAnnotations: [SubwayLineAnnotation] {
        subwayPolylines.map { SubwayLineAnnotation(polyline: $0) }
    }
    
    // Store line metadata for color mapping
    private var lineMetadata: [String: String] = [:] // polyline ID -> line name
    
    // Colors mapped to train lines (from MTA design)
    private let lineColors: [String: Color] = [
        "1": Color(hex: "EE352E"), "2": Color(hex: "EE352E"), "3": Color(hex: "EE352E"),
        "4": Color(hex: "00933C"), "5": Color(hex: "00933C"), "6": Color(hex: "00933C"), "6X": Color(hex: "00933C"),
        "A": Color(hex: "2850AD"), "C": Color(hex: "2850AD"), "E": Color(hex: "2850AD"),
        "B": Color(hex: "FF6319"), "D": Color(hex: "FF6319"), "F": Color(hex: "FF6319"), "M": Color(hex: "FF6319"),
        "G": Color(hex: "6CBE45"),
        "J": Color(hex: "996633"), "Z": Color(hex: "996633"),
        "L": Color(hex: "A7A9AC"),
        "N": Color(hex: "FCCC0A"), "Q": Color(hex: "FCCC0A"), "R": Color(hex: "FCCC0A"), "W": Color(hex: "FCCC0A"),
        "S": Color(hex: "808183"),
        "7": Color(hex: "B933AD"), "7X": Color(hex: "B933AD"),
        "SIR": Color(hex: "2850AD"), // Staten Island Railway
        
        // Grand Central Shuttle
        "GS": Color(hex: "808183"),
        "FS": Color(hex: "808183"), // Franklin Avenue Shuttle
        "H": Color(hex: "808183"), // Rockaway Park Shuttle
        
        // Express variants (removed duplicates)
        "4X": Color(hex: "00933C"), "5X": Color(hex: "00933C"),
        "QX": Color(hex: "FCCC0A"), "FX": Color(hex: "FF6319")
    ]
    
    func loadSubwayData() {
        guard !hasLoadedData && !isLoading else {
            print("📍 Subway data already loaded or loading")
            return
        }
        
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if let linePath = Bundle.main.path(forResource: "Subway_view_5083976324868604013", ofType: "geojson") {
                print("✅ Subway line path: \(linePath)")
            } else {
                print("❌ Subway line path not found")
            }

            if let stationPath = Bundle.main.path(forResource: "SubwayStation_view_-2956341149621885519", ofType: "geojson") {
                print("✅ Subway station path: \(stationPath)")
            } else {
                print("❌ Subway station path not found")
            }
            
            // Clear existing data
            DispatchQueue.main.async {
                self.subwayPolylines.removeAll()
                self.subwayAnnotations.removeAll()
                self.lineMetadata.removeAll()
            }
            
            // Load line data
            self.loadSubwayLines()
            
            // Load station data
            self.loadSubwayStations()
            
            DispatchQueue.main.async {
                self.hasLoadedData = true
                self.isLoading = false
                print("✅ Subway data loaded: \(self.subwayPolylines.count) lines, \(self.subwayAnnotations.count) stations")
            }
        }
    }
    
    private func loadSubwayLines() {
        guard let lineURL = Bundle.main.url(forResource: "Subway_view_5083976324868604013", withExtension: "geojson") else {
            print("❌ Subway lines GeoJSON file not found in bundle")
            return
        }
        
        do {
            let lineData = try Data(contentsOf: lineURL)
            
            guard let geojson = try JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  let features = geojson["features"] as? [[String: Any]] else {
                print("❌ Invalid GeoJSON structure")
                return
            }
            
            print("📊 Processing \(features.count) subway line features")
            
            var tempPolylines: [MKPolyline] = []
            var tempMetadata: [String: String] = [:]
            
            for feature in features {
                guard let geometry = feature["geometry"] as? [String: Any],
                      let properties = feature["properties"] as? [String: Any] else { continue }
                
                // Extract line name from various possible property keys
                let lineName = extractLineName(from: properties)
                
                let type = geometry["type"] as? String
                var segments: [[[Double]]] = []
                
                if type == "MultiLineString", let multi = geometry["coordinates"] as? [[[Double]]] {
                    segments = multi
                } else if type == "LineString", let single = geometry["coordinates"] as? [[Double]] {
                    segments = [single]
                } else {
                    continue
                }
                
                for segment in segments {
                    let points = segment.compactMap { coords -> CLLocationCoordinate2D? in
                        guard coords.count >= 2 else { return nil }
                        return CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
                    }
                    
                    if points.count >= 2 {
                        let polyline = MKPolyline(coordinates: points, count: points.count)
                        let polylineID = UUID().uuidString
                        polyline.title = polylineID // Use unique ID as title
                        
                        tempPolylines.append(polyline)
                        tempMetadata[polylineID] = lineName
                    }
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.subwayPolylines = tempPolylines
                self?.lineMetadata = tempMetadata
                print("✅ Loaded \(tempPolylines.count) subway polylines")
            }
            
        } catch {
            print("❌ Error loading subway lines: \(error)")
        }
    }
    
    private func loadSubwayStations() {
        guard let stationURL = Bundle.main.url(forResource: "SubwayStation_view_-2956341149621885519", withExtension: "geojson") else {
            print("❌ Subway stations GeoJSON file not found in bundle")
            return
        }
        
        do {
            let stationData = try Data(contentsOf: stationURL)
            
            guard let geojson = try JSONSerialization.jsonObject(with: stationData) as? [String: Any],
                  let features = geojson["features"] as? [[String: Any]] else {
                print("❌ Invalid station GeoJSON structure")
                return
            }
            
            print("📊 Processing \(features.count) subway station features")
            
            var tempAnnotations: [MKPointAnnotation] = []
            
            for feature in features {
                guard let geometry = feature["geometry"] as? [String: Any],
                      let coord = geometry["coordinates"] as? [Double],
                      coord.count >= 2,
                      let props = feature["properties"] as? [String: Any] else { continue }
                
                let annotation = MKPointAnnotation()
                annotation.title = props["NAME"] as? String ?? props["name"] as? String ?? "Station"
                annotation.subtitle = props["LINE"] as? String ?? props["line"] as? String ?? ""
                annotation.coordinate = CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
                
                tempAnnotations.append(annotation)
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.subwayAnnotations = tempAnnotations
                print("✅ Loaded \(tempAnnotations.count) subway stations")
            }
            
        } catch {
            print("❌ Error loading subway stations: \(error)")
        }
    }
    
    private func extractLineName(from properties: [String: Any]) -> String {
        // Try different property keys that might contain the line name
        let possibleKeys = ["rt_symbol", "route", "name", "line", "color", "route_id"]
        
        for key in possibleKeys {
            if let value = properties[key] as? String, !value.isEmpty {
                // Clean up the line name
                let cleaned = value.uppercased()
                    .replacingOccurrences(of: "LINE", with: "")
                    .replacingOccurrences(of: "TRAIN", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Return the first valid character/number
                if let firstChar = cleaned.first(where: { $0.isLetter || $0.isNumber }) {
                    return String(firstChar)
                }
            }
        }
        
        return "Unknown"
    }
    
    func getLineColor(for lineName: String) -> UIColor {
        if let color = lineColors[lineName] {
            return UIColor(color)
        }
        
        // Try to extract the first character for the line
        if let firstChar = lineName.first {
            let firstCharString = String(firstChar)
            if let color = lineColors[firstCharString] {
                return UIColor(color)
            }
        }
        
        return UIColor.systemGray
    }
    
    func clearData() {
        subwayPolylines.removeAll()
        subwayAnnotations.removeAll()
        lineMetadata.removeAll()
        hasLoadedData = false
    }
}
