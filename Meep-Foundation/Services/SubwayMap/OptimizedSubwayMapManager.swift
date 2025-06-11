//
//  OptimizedSubwayMapManager.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/9/25.
//
// Advanced OptimizedSubwayMapManager with route variants support

import Foundation
import MapKit
import SwiftUI
import os.log

// MARK: - Enhanced Data Structures


// MARK: - Also Make SubwayTrackPoint Hashable (if needed)
struct SubwayTrackPoint: Hashable {
    let latitude: Double
    let longitude: Double
    let sequence: Int
    let stationId: String? // Station identifier from CSV
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var isStation: Bool {
        return stationId != nil && !stationId!.isEmpty
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(sequence)
        hasher.combine(stationId)
    }
    
    static func == (lhs: SubwayTrackPoint, rhs: SubwayTrackPoint) -> Bool {
        return lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.sequence == rhs.sequence &&
               lhs.stationId == rhs.stationId
    }
}

struct SubwayRoute: Hashable {
    let routeId: String
    let baseLine: String
    let variant: String?
    let coordinates: [CLLocationCoordinate2D]
    let stations: [SubwayTrackPoint] // Store station points separately
    
    var displayName: String {
        return baseLine
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(routeId)
        hasher.combine(baseLine)
        hasher.combine(variant)
        // Don't hash coordinates and stations arrays as they're expensive
        // routeId should be unique enough
    }
    
    static func == (lhs: SubwayRoute, rhs: SubwayRoute) -> Bool {
        return lhs.routeId == rhs.routeId &&
               lhs.baseLine == rhs.baseLine &&
               lhs.variant == rhs.variant
    }
}

struct SubwayStation {
    let coordinate: CLLocationCoordinate2D
    let stationId: String
    let lineName: String
    let routeId: String
}

class OptimizedSubwayMapManager: ObservableObject {
    // MARK: - Published Properties
    @Published var visiblePolylines: [MKPolyline] = []
    @Published var visibleStations: [MKPointAnnotation] = []
    @Published var visibleStationCircles: [MKPolygon] = [] // Station circles as polygons
    @Published var isLoading = false
    @Published var loadingError: SubwayLoadingError?
    @Published var hasLoadedData = false
    
    // MARK: - Private Properties
    private var allPolylines: [MKPolyline] = []
    private var allStations: [MKPointAnnotation] = []
    private var allStationCircles: [MKPolygon] = [] // Store all station circles
    private var allSubwayStations: [SubwayStation] = [] // Store subway station data
    private var loadedRoutes: [SubwayRoute] = []
    
    // Performance monitoring
    private let logger = Logger(subsystem: "com.meep.subway", category: "performance")
    
    // MARK: - Route Configuration Based on NYC subway List
    private let routeFiles = [
        // Single route lines
        "1", "2", "3", "4", "5", "6", "7",
        "B", "C", "E", "F", "G", "J", "L", "M", "Q", "R",
        
        // Multi-route lines (with variants)
        "A-1", "A-2",              // A train variants
        "D-1", "D-2", "D-3",       // D train variants
        "N-1", "N-2",              // N train variants
        
        // Shuttle services
        "FS",                      // Franklin Ave Shuttle
        "GS",                      // Grand Central Shuttle
        "H",                       // Rockaway Park Shuttle
        
        // Staten Island Railway
        "SI"                       // Staten Island Railway
    ]
    
    // Complete NYC subway line colors matching MTA standards
    private let lineColors: [String: UIColor] = [
        // Red lines (1, 2, 3)
        "1": UIColor(red: 238/255, green: 53/255, blue: 46/255, alpha: 1),
        "2": UIColor(red: 238/255, green: 53/255, blue: 46/255, alpha: 1),
        "3": UIColor(red: 238/255, green: 53/255, blue: 46/255, alpha: 1),
        
        // Green lines (4, 5, 6)
        "4": UIColor(red: 0/255, green: 147/255, blue: 60/255, alpha: 1),
        "5": UIColor(red: 0/255, green: 147/255, blue: 60/255, alpha: 1),
        "6": UIColor(red: 0/255, green: 147/255, blue: 60/255, alpha: 1),
        
        // Purple (7)
        "7": UIColor(red: 185/255, green: 51/255, blue: 173/255, alpha: 1),
        
        // Blue lines (A, C, E)
        "A": UIColor(red: 40/255, green: 80/255, blue: 173/255, alpha: 1),
        "C": UIColor(red: 40/255, green: 80/255, blue: 173/255, alpha: 1),
        "E": UIColor(red: 40/255, green: 80/255, blue: 173/255, alpha: 1),
        
        // Orange lines (B, D, F, M)
        "B": UIColor(red: 255/255, green: 99/255, blue: 25/255, alpha: 1),
        "D": UIColor(red: 255/255, green: 99/255, blue: 25/255, alpha: 1),
        "F": UIColor(red: 255/255, green: 99/255, blue: 25/255, alpha: 1),
        "M": UIColor(red: 255/255, green: 99/255, blue: 25/255, alpha: 1),
        
        // Light Green (G)
        "G": UIColor(red: 108/255, green: 190/255, blue: 69/255, alpha: 1),
        
        // Brown lines (J, Z)
        "J": UIColor(red: 153/255, green: 102/255, blue: 51/255, alpha: 1),
        "Z": UIColor(red: 153/255, green: 102/255, blue: 51/255, alpha: 1),
        
        // Gray (L)
        "L": UIColor(red: 167/255, green: 169/255, blue: 172/255, alpha: 1),
        
        // Yellow lines (N, Q, R, W)
        "N": UIColor(red: 252/255, green: 204/255, blue: 10/255, alpha: 1),
        "Q": UIColor(red: 252/255, green: 204/255, blue: 10/255, alpha: 1),
        "R": UIColor(red: 252/255, green: 204/255, blue: 10/255, alpha: 1),
        "W": UIColor(red: 252/255, green: 204/255, blue: 10/255, alpha: 1),
        
        // Shuttle lines (Gray)
        "FS": UIColor(red: 128/255, green: 129/255, blue: 131/255, alpha: 1),
        "GS": UIColor(red: 128/255, green: 129/255, blue: 131/255, alpha: 1),
        "H": UIColor(red: 128/255, green: 129/255, blue: 131/255, alpha: 1),
        
        // Staten Island Railway (Blue)
        "SI": UIColor(red: 40/255, green: 80/255, blue: 173/255, alpha: 1)
    ]
    
    // MARK: - CSV Loading Methods
    
    /// Load subway data from CSV files using NYC line format
    func loadSubwayDataFromCSV() {
        guard !hasLoadedData && !isLoading else {
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        isLoading = true
        loadingError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.loadAllRoutesFromCSV()
            
            DispatchQueue.main.async {
                self.hasLoadedData = true
                self.isLoading = false
                
                // Show all loaded polylines
                self.visiblePolylines = self.allPolylines
                self.visibleStations = []
            }
        }
    }
    
    private func loadAllRoutesFromCSV() {
        var allRoutes: [SubwayRoute] = []
        
        for routeFile in routeFiles {
            let fileName = "subway_line_\(routeFile)"
            
            if let route = parseRouteCSVFile(fileName, routeId: routeFile) {
                allRoutes.append(route)
                //print("✅ Loaded route \(routeFile): \(route.coordinates.count) coordinates, \(route.stations.count) stations")
            } else {
                print("❌ Failed to load route file: \(fileName)")
            }
        }
        
        print("📊 Total routes loaded: \(allRoutes.count)")
        
        // Convert routes to polylines with offset handling for overlapping lines
        var tempPolylines: [MKPolyline] = []
        
        // Group routes by their display name to handle overlapping lines
        let groupedRoutes = Dictionary(grouping: allRoutes) { $0.displayName }
        
        print("📊 Grouped into \(groupedRoutes.count) line groups")
        
        for (lineName, routes) in groupedRoutes {
            // Check if routes have different colors (only offset if they do)
            let uniqueColors = Set(routes.map { getLineColor(for: $0.displayName) })
            let needsOffset = routes.count > 1 && uniqueColors.count > 1
            
           // print("🚇 Processing line \(lineName): \(routes.count) variants, needs offset: \(needsOffset)")
            
            for (index, route) in routes.enumerated() {
                if route.coordinates.count >= 2 {
                    var offsetCoordinates = route.coordinates
                    
                    // Apply offset only if multiple variants with different colors exist
                    if needsOffset && index > 0 {
                        offsetCoordinates = applyLineOffset(to: route.coordinates,
                                                          offsetIndex: index,
                                                          totalVariants: routes.count)
                    }
                    
                    let polyline = MKPolyline(coordinates: offsetCoordinates, count: offsetCoordinates.count)
                    polyline.title = route.displayName
                    
                    // Store additional metadata for rendering
                    polyline.subtitle = route.routeId // Store full route ID for reference
                    
                    tempPolylines.append(polyline)
                }
                
                // Create station annotations and polygons from route stations
                //print("🚉 Creating stations for route \(route.routeId): \(route.stations.count) track points")
                
                // Deduplicate stations by location (group nearby coordinates)
                let uniqueStations = deduplicateStations(route.stations, tolerance: 0.003) // ~33 meters - more aggressive
               // print("🎯 Deduplicated to \(uniqueStations.count) unique stations")
                
                for station in uniqueStations {
                    let stationAnnotation = MKPointAnnotation()
                    stationAnnotation.coordinate = station.coordinate
                    stationAnnotation.title = route.displayName
                    stationAnnotation.subtitle = station.stationId
                    allStations.append(stationAnnotation)
                    
                    // Create circular polygon for station
                    let stationCircle = createStationCircle(at: station.coordinate,
                                                          lineName: route.displayName,
                                                          stationId: station.stationId ?? "")
                    allStationCircles.append(stationCircle)
                    
                    // Also store in our subway stations array
                    let subwayStation = SubwayStation(
                        coordinate: station.coordinate,
                        stationId: station.stationId ?? "",
                        lineName: route.displayName,
                        routeId: route.routeId
                    )
                    allSubwayStations.append(subwayStation)
                }
            }
        }
        
        self.loadedRoutes = allRoutes
        self.allPolylines = tempPolylines
        
        print("✅ Final results: \(tempPolylines.count) polylines, \(allStations.count) station annotations, \(allStationCircles.count) station circles, \(allSubwayStations.count) subway stations")
    }
    
    private func parseRouteCSVFile(_ fileName: String, routeId: String) -> SubwayRoute? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            return nil // File doesn't exist
        }
        
        do {
            let csvContent = try String(contentsOf: url)
            let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            var coordinates: [CLLocationCoordinate2D] = []
            var stations: [SubwayTrackPoint] = []
            
           // print("📄 Parsing \(fileName): \(lines.count) lines")
            
            for (index, line) in lines.enumerated() {
                if let point = parseNYCCSVLine(line, sequence: index) {
                    coordinates.append(point.coordinate)
                    
                    // If this point represents a station, add it to stations array
                    if point.isStation {
                        stations.append(point)
                        if index < 5 { // Debug first 5 stations
                          //  print("🚉 Found station \(index): \(point.stationId ?? "nil") at (\(point.latitude), \(point.longitude))")
                        }
                    }
                } else if index < 5 { // Debug first 5 failed parses
                    print("❌ Failed to parse line \(index): '\(line)'")
                }
            }
            
          //  print("📊 \(fileName) results: \(coordinates.count) coordinates, \(stations.count) stations")
            
            // Parse route info from routeId
            let (baseLine, variant) = parseRouteId(routeId)
            
            return SubwayRoute(
                routeId: routeId,
                baseLine: baseLine,
                variant: variant,
                coordinates: coordinates,
                stations: stations
            )
            
        } catch {
            logger.error("Error reading CSV file \(fileName): \(error)")
            return nil
        }
    }
    
    private func parseNYCCSVLine(_ line: String, sequence: Int) -> SubwayTrackPoint? {
        // Clean the line and split by comma
        let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = cleanLine.components(separatedBy: ",")
        
        // Format: "6..N01R,40.713065,-74.004131,0,"
        // Components: [0: lineId/stationId, 1: latitude, 2: longitude, 3: sequence, 4: empty]
        guard components.count >= 4 else {
            return nil
        }
        
        // Parse latitude (component 1) and longitude (component 2)
        guard let latitude = Double(components[1].trimmingCharacters(in: .whitespacesAndNewlines)),
              let longitude = Double(components[2].trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        
        // Validate coordinates are reasonable for NYC area
        let isValidNYC = latitude >= 40.4 && latitude <= 41.0 &&
                         longitude >= -74.3 && longitude <= -73.7
        
        guard isValidNYC else {
            return nil
        }
        
        // Extract station ID from first component (like "6..N01R")
        let stationId = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        
        return SubwayTrackPoint(
            latitude: latitude,
            longitude: longitude,
            sequence: sequence,
            stationId: stationId.isEmpty ? nil : stationId
        )
    }

    private func parseRouteId(_ routeId: String) -> (baseLine: String, variant: String?) {
        // Handle cases like "A-1", "A-2", "D-1", "D-2", "D-3", "N-1", "N-2"
        if routeId.contains("-") {
            let parts = routeId.components(separatedBy: "-")
            if parts.count == 2 {
                return (baseLine: parts[0], variant: parts[1])
            }
        }
        
        // Handle special cases
        switch routeId {
        case "SI":
            return (baseLine: "SIR", variant: nil)
        case "FS":
            return (baseLine: "FS", variant: nil)
        case "GS":
            return (baseLine: "GS", variant: nil)
        case "H":
            return (baseLine: "H", variant: nil)
        default:
            return (baseLine: routeId, variant: nil)
        }
    }
    
    // MARK: - Line Offset Methods for Better Visual Separation
    
    /// Apply slight offset to subway line coordinates to prevent exact overlap
    private func applyLineOffset(to coordinates: [CLLocationCoordinate2D],
                                offsetIndex: Int,
                                totalVariants: Int) -> [CLLocationCoordinate2D] {
        guard totalVariants > 1 && offsetIndex > 0 else {
            return coordinates // No offset needed for first variant or single lines
        }
        
        // Much larger offset distance for clear visual separation
        let baseOffsetDistance: Double = 0.00006 // About 66 meters in NYC - very clear separation
        let offsetDistance = baseOffsetDistance * Double(offsetIndex)
        
        return coordinates.compactMap { coord in
            // Calculate perpendicular offset
            let offsetCoord = calculatePerpendicularOffset(coordinate: coord,
                                                         coordinates: coordinates,
                                                         distance: offsetDistance,
                                                         side: offsetIndex % 2 == 0 ? .right : .left)
            return offsetCoord
        }
    }
    
    private enum OffsetSide {
        case left, right
    }
    
    /// Calculate perpendicular offset for a coordinate along a line
    private func calculatePerpendicularOffset(coordinate: CLLocationCoordinate2D,
                                            coordinates: [CLLocationCoordinate2D],
                                            distance: Double,
                                            side: OffsetSide) -> CLLocationCoordinate2D {
        
        guard let index = coordinates.firstIndex(where: {
            abs($0.latitude - coordinate.latitude) < 0.0000001 &&
            abs($0.longitude - coordinate.longitude) < 0.0000001
        }) else {
            return coordinate
        }
        
        // Find the direction vector for this segment
        var directionLat: Double = 0
        var directionLon: Double = 0
        
        if index > 0 && index < coordinates.count - 1 {
            // Use average of previous and next segments
            let prevCoord = coordinates[index - 1]
            let nextCoord = coordinates[index + 1]
            directionLat = nextCoord.latitude - prevCoord.latitude
            directionLon = nextCoord.longitude - prevCoord.longitude
        } else if index > 0 {
            // Use previous segment
            let prevCoord = coordinates[index - 1]
            directionLat = coordinate.latitude - prevCoord.latitude
            directionLon = coordinate.longitude - prevCoord.longitude
        } else if index < coordinates.count - 1 {
            // Use next segment
            let nextCoord = coordinates[index + 1]
            directionLat = nextCoord.latitude - coordinate.latitude
            directionLon = nextCoord.longitude - coordinate.longitude
        } else {
            return coordinate // Single point, no offset possible
        }
        
        // Normalize the direction vector
        let magnitude = sqrt(directionLat * directionLat + directionLon * directionLon)
        guard magnitude > 0 else { return coordinate }
        
        directionLat /= magnitude
        directionLon /= magnitude
        
        // Calculate perpendicular vector (rotate 90 degrees)
        let perpLat = side == .right ? -directionLon : directionLon
        let perpLon = side == .right ? directionLat : -directionLat
        
        // Apply offset
        return CLLocationCoordinate2D(
            latitude: coordinate.latitude + perpLat * distance,
            longitude: coordinate.longitude + perpLon * distance
        )
    }
    
    /// Get line width for rendering (hairline-thin lines)
    func getLineWidth(for lineName: String, zoomLevel: Double = 1.0) -> CGFloat {
        // Base width - hairline thin like StreetEasy
        let baseWidth: CGFloat = 1.5
        
        // Adjust based on zoom level
        let zoomAdjustedWidth = baseWidth * CGFloat(max(0.2, min(1.0, zoomLevel)))
        
        // Special cases for certain lines
        switch lineName {
        case "FS", "GS", "H": // Shuttle services - ultra hairline
            return max(0.3, zoomAdjustedWidth * 0.4)
        case "SIR": // Staten Island Railway
            return max(0.4, zoomAdjustedWidth * 0.5)
        default:
            return max(0.4, zoomAdjustedWidth)
        }
    }
    
    // MARK: - Public Methods
    
    /// Load subway data (defaults to CSV)
    func loadSubwayData(userLocation: CLLocationCoordinate2D? = nil) {
        loadSubwayDataFromCSV()
    }
    
    /// Update visible elements based on zoom level and region
    func updateVisibleElements(for region: MKCoordinateRegion) {
        guard hasLoadedData else { return }
        
        //print("🔄 Updating visible elements for region span: \(region.span.latitudeDelta)")
        
        // Always show all polylines
        visiblePolylines = allPolylines
        
        // Show stations as circles when zoomed in (span < 0.02 degrees for closer zoom)
        if region.span.latitudeDelta < 0.02 {
           // print("✅ Zoom level allows stations to show")
            
            // Filter stations within visible region with buffer
            let buffer = region.span.latitudeDelta * 0.3
            let minLat = region.center.latitude - region.span.latitudeDelta/2 - buffer
            let maxLat = region.center.latitude + region.span.latitudeDelta/2 + buffer
            let minLon = region.center.longitude - region.span.longitudeDelta/2 - buffer
            let maxLon = region.center.longitude + region.span.longitudeDelta/2 + buffer
            
//            print("🗺 Filtering stations in bounds:")
//            print("   Lat: \(String(format: "%.6f", minLat)) to \(String(format: "%.6f", maxLat))")
//            print("   Lon: \(String(format: "%.6f", minLon)) to \(String(format: "%.6f", maxLon))")
            
            let filteredStations = allStations.filter { station in
                let inBounds = station.coordinate.latitude >= minLat &&
                              station.coordinate.latitude <= maxLat &&
                              station.coordinate.longitude >= minLon &&
                              station.coordinate.longitude <= maxLon
                
                if inBounds {
                    //print("   ✅ Station in bounds: \(station.title ?? "Unknown") at (\(String(format: "%.6f", station.coordinate.latitude)), \(String(format: "%.6f", station.coordinate.longitude)))")
                }
                
                return inBounds
            }
            
            // Filter station circles using the same logic
            let filteredStationCircles = allStationCircles.filter { circle in
                // Get the center coordinate of the circle polygon
                let centerCoord = circle.coordinate
                return centerCoord.latitude >= minLat &&
                       centerCoord.latitude <= maxLat &&
                       centerCoord.longitude >= minLon &&
                       centerCoord.longitude <= maxLon
            }
            
            visibleStations = filteredStations
            visibleStationCircles = filteredStationCircles
            //print("📊 Set \(visibleStations.count) visible stations and \(visibleStationCircles.count) station circles")
            
        } else {
           // print("❌ Zoom level too far out for stations")
            visibleStations = []
            visibleStationCircles = []
        }
        
       // print("🎯 Final visible stations count: \(visibleStations.count), circles: \(visibleStationCircles.count)")
    }
    
    /// Get station circle radius based on zoom level
    func getStationRadius(for zoomLevel: Double) -> CGFloat {
        // Base radius for station circles
        let baseRadius: CGFloat = 3.0
        
        // Adjust based on zoom level
        let zoomAdjustedRadius = baseRadius * CGFloat(max(0.5, min(2.0, zoomLevel)))
        
        return max(2.0, zoomAdjustedRadius)
    }
    
    /// Get station color (same as line color for fill and stroke)
    func getStationColor(for lineName: String) -> (fill: UIColor, stroke: UIColor) {
        let lineColor = getLineColor(for: lineName)
        return (fill: lineColor, stroke: lineColor)
    }
    
    // MARK: - Station Circle Creation
    
    /// Create a circular MKPolygon for a subway station
    private func createStationCircle(at coordinate: CLLocationCoordinate2D,
                                   lineName: String,
                                   stationId: String) -> MKPolygon {
        // Radius in degrees (approximately 15 meters in NYC)
        let radiusInDegrees: Double = 0.000068
        
        // Number of points to create a smooth circle
        let numberOfPoints = 16
        
        var circleCoordinates: [CLLocationCoordinate2D] = []
        
        for i in 0..<numberOfPoints {
            let angle = Double(i) * 2.0 * .pi / Double(numberOfPoints)
            let latOffset = radiusInDegrees * cos(angle)
            let lonOffset = radiusInDegrees * sin(angle)
            
            let circleCoordinate = CLLocationCoordinate2D(
                latitude: coordinate.latitude + latOffset,
                longitude: coordinate.longitude + lonOffset
            )
            circleCoordinates.append(circleCoordinate)
        }
        
        let polygon = MKPolygon(coordinates: circleCoordinates, count: circleCoordinates.count)
        polygon.title = lineName
        polygon.subtitle = stationId
        
        return polygon
    }
    
    /// Get station circle radius based on zoom level (for dynamic sizing)
    func getStationCircleRadius(for zoomLevel: Double) -> Double {
        // Base radius in degrees
        let baseRadius: Double = 0.000135 // About 15 meters
        
        // Adjust based on zoom level
        let zoomAdjustedRadius = baseRadius * max(0.5, min(2.0, zoomLevel))
        
        return zoomAdjustedRadius
    }
    
    // MARK: - Station Deduplication
    
    /// Deduplicate stations that are very close to each other (same station, multiple track points)
    private func deduplicateStations(_ stations: [SubwayTrackPoint], tolerance: Double) -> [SubwayTrackPoint] {
        var uniqueStations: [SubwayTrackPoint] = []
        
        for station in stations {
            // Check if we already have a station very close to this location
            let isDuplicate = uniqueStations.contains { existingStation in
                let latDiff = abs(station.latitude - existingStation.latitude)
                let lonDiff = abs(station.longitude - existingStation.longitude)
                return latDiff < tolerance && lonDiff < tolerance
            }
            
            if !isDuplicate {
                uniqueStations.append(station)
            }
        }
        
        return uniqueStations
    }
    
    /// Calculate zoom level from map region span
    func getZoomLevel(from region: MKCoordinateRegion) -> Double {
        // Convert latitude span to approximate zoom level
        let latitudeDelta = region.span.latitudeDelta
        
        // Zoom level calculation (approximate)
        // Higher zoom = smaller span = more zoomed in
        if latitudeDelta > 0.5 {
            return 0.3 // Very zoomed out
        } else if latitudeDelta > 0.1 {
            return 0.6 // Zoomed out
        } else if latitudeDelta > 0.05 {
            return 1.0 // Normal
        } else if latitudeDelta > 0.01 {
            return 1.5 // Zoomed in
        } else {
            return 2.0 // Very zoomed in
        }
    }
    
    /// Get color for subway line
    func getLineColor(for lineName: String) -> UIColor {
        return lineColors[lineName] ?? UIColor.systemGray
    }
    
    /// Clear all data and reset state
    func clearData() {
        allPolylines.removeAll()
        allStations.removeAll()
        allStationCircles.removeAll()
        allSubwayStations.removeAll()
        visiblePolylines.removeAll()
        visibleStations.removeAll()
        visibleStationCircles.removeAll()
        loadedRoutes.removeAll()
        hasLoadedData = false
        loadingError = nil
    }
    // MARK: - Subway Station Proximity Methods
      
      /// Find the nearest subway station to a given coordinate
      func findNearestStation(to coordinate: CLLocationCoordinate2D, maxDistance: Double = 0.01) -> SubwayStation? {
          guard hasLoadedData else { return nil }
          
          let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
          var nearestStation: SubwayStation?
          var minDistance: Double = Double.infinity
          
          for station in allSubwayStations {
              let stationLocation = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
              let distance = targetLocation.distance(from: stationLocation)
              
              // Convert maxDistance from degrees to meters (approximately)
              let maxDistanceMeters = maxDistance * 111000 // rough conversion
              
              if distance < maxDistanceMeters && distance < minDistance {
                  minDistance = distance
                  nearestStation = station
              }
          }
          
          return nearestStation
      }
      
      /// Get all subway lines near a coordinate within a radius
      func getLinesNear(coordinate: CLLocationCoordinate2D, radius: Double = 0.005) -> [String] {
          guard hasLoadedData else { return [] }
          
          let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
          let radiusMeters = radius * 111000 // Convert degrees to meters
          
          var nearbyLines: Set<String> = []
          
          for station in allSubwayStations {
              let stationLocation = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
              let distance = targetLocation.distance(from: stationLocation)
              
              if distance <= radiusMeters {
                  nearbyLines.insert(station.lineName)
              }
          }
          
          return Array(nearbyLines).sorted()
      }
      
      /// Get the closest station with its distance for a coordinate
      func getClosestStationInfo(to coordinate: CLLocationCoordinate2D) -> (station: SubwayStation, distance: Double)? {
          guard hasLoadedData else { return nil }
          
          let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
          var closestStation: SubwayStation?
          var minDistance: Double = Double.infinity
          
          for station in allSubwayStations {
              let stationLocation = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
              let distance = targetLocation.distance(from: stationLocation)
              
              if distance < minDistance {
                  minDistance = distance
                  closestStation = station
              }
          }
          
          if let station = closestStation {
              return (station: station, distance: minDistance)
          }
          
          return nil
      }
      
      /// Find multiple nearby stations within radius, sorted by distance
        func getNearbyStations(to coordinate: CLLocationCoordinate2D, maxDistance: Double = 0.015, limit: Int = 8) -> [(station: SubwayStation, distance: Double)] {
            guard hasLoadedData else { return [] }
            
            let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let maxDistanceMeters = maxDistance * 111000 // Increased from 0.01 to 0.015 for better coverage
            
            var nearbyStations: [(station: SubwayStation, distance: Double)] = []
            
            for station in allSubwayStations {
                let stationLocation = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
                let distance = targetLocation.distance(from: stationLocation)
                
                if distance <= maxDistanceMeters {
                    nearbyStations.append((station: station, distance: distance))
                }
            }
            
            // Sort by distance and limit results
            nearbyStations.sort { $0.distance < $1.distance }
            return Array(nearbyStations.prefix(limit)) // Increased limit from 5 to 8
        }
    
    
    
    
  
    
    // MARK: - Subway Route Direction Utility

    /// Determine if a subway route is heading toward a given midpoint from a specific station
    func isSubwayHeadingTowardMidpoint(midpoint: CLLocationCoordinate2D, from station: SubwayTrackPoint, in route: SubwayRoute) -> Bool {
        guard let currentIndex = route.stations.firstIndex(where: {
            let stationLoc = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
            let routeStationLoc = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            return stationLoc.distance(from: routeStationLoc) < 100 // Match by proximity
        }) else {
            print("       ❌ Station not found in route stations")
            return false
        }
        
        // Need at least 3 more stations for better direction analysis
        guard currentIndex + 3 < route.stations.count else {
            print("       ❌ Not enough stations to determine direction")
            return false
        }

        let current = route.stations[currentIndex].coordinate
        
        // Use multiple future stations for more robust direction detection
        let station1 = route.stations[currentIndex + 1].coordinate
        let station2 = route.stations[currentIndex + 2].coordinate
        let station3 = route.stations[currentIndex + 3].coordinate

        print("       📐 Direction calculation:")
        print("         Current: (\(String(format: "%.6f", current.latitude)), \(String(format: "%.6f", current.longitude)))")
        print("         Station+1: (\(String(format: "%.6f", station1.latitude)), \(String(format: "%.6f", station1.longitude)))")
        print("         Station+2: (\(String(format: "%.6f", station2.latitude)), \(String(format: "%.6f", station2.longitude)))")
        print("         Station+3: (\(String(format: "%.6f", station3.latitude)), \(String(format: "%.6f", station3.longitude)))")
        print("         Midpoint: (\(String(format: "%.6f", midpoint.latitude)), \(String(format: "%.6f", midpoint.longitude)))")

        // Create multiple direction vectors for more stability
        let vector1 = CGVector(dx: station1.longitude - current.longitude, dy: station1.latitude - current.latitude)
        let vector2 = CGVector(dx: station2.longitude - current.longitude, dy: station2.latitude - current.latitude)
        let vector3 = CGVector(dx: station3.longitude - current.longitude, dy: station3.latitude - current.latitude)
        
        // Average the vectors for overall route direction
        let avgRouteVector = CGVector(
            dx: (vector1.dx + vector2.dx + vector3.dx) / 3,
            dy: (vector1.dy + vector2.dy + vector3.dy) / 3
        )
        
        let toMidpointVector = CGVector(dx: midpoint.longitude - current.longitude, dy: midpoint.latitude - current.latitude)

        // Normalize vectors
        let routeLength = sqrt(pow(avgRouteVector.dx, 2) + pow(avgRouteVector.dy, 2))
        let midpointLength = sqrt(pow(toMidpointVector.dx, 2) + pow(toMidpointVector.dy, 2))
        
        guard routeLength > 0, midpointLength > 0 else {
            print("       ❌ Zero length vector")
            return false
        }

        let dot = (avgRouteVector.dx * toMidpointVector.dx + avgRouteVector.dy * toMidpointVector.dy) / (routeLength * midpointLength)
        
        // Check if the midpoint is reachable
        let distanceToMidpoint = CLLocation(latitude: current.latitude, longitude: current.longitude)
            .distance(from: CLLocation(latitude: midpoint.latitude, longitude: midpoint.longitude))
        
        // 🚇 MUCH MORE LENIENT CRITERIA FOR NYC SUBWAY:
        let isDirectionGood = dot > 0.2        // Very lenient - allows routes that are generally heading in the right direction
        let isDistanceReasonable = distanceToMidpoint < 15000  // 15km - covers most of Manhattan and beyond
        
        // Additional check: Is the midpoint closer than the end of the route?
        let endStation = route.stations.last?.coordinate ?? current
        let distanceToEnd = CLLocation(latitude: current.latitude, longitude: current.longitude)
            .distance(from: CLLocation(latitude: endStation.latitude, longitude: endStation.longitude))
        let midpointIsCloserThanEnd = distanceToMidpoint < distanceToEnd * 1.2 // Allow 20% buffer
        
        print("       📊 dot=\(String(format: "%.3f", dot)), distance=\(Int(distanceToMidpoint))m, endDistance=\(Int(distanceToEnd))m")
        print("       📊 direction=\(isDirectionGood), distance=\(isDistanceReasonable), closerThanEnd=\(midpointIsCloserThanEnd)")
        
        let result = isDirectionGood && isDistanceReasonable && midpointIsCloserThanEnd
        print("       📊 Final result: \(result)")
        
        return result
    }

    // MARK: - Subway Route & Walking Utilities



    // MARK: - Enhanced Debug Methods for Subway Route Detection



    /// Debug method to understand why routes are being found
    func debugRouteDetection(midpoint: CLLocationCoordinate2D, from userCoordinate: CLLocationCoordinate2D) {
        guard hasLoadedData else {
            print("❌ No subway data loaded")
            return
        }
        
        print("🔍 === FIXED SUBWAY ROUTE DEBUG ===")
        print("   📍 User location: (\(String(format: "%.6f", userCoordinate.latitude)), \(String(format: "%.6f", userCoordinate.longitude)))")
        print("   🎯 Midpoint: (\(String(format: "%.6f", midpoint.latitude)), \(String(format: "%.6f", midpoint.longitude)))")
        
        // Find nearby stations using corrected method
        let nearbyStations = getNearbyStations(to: userCoordinate, maxDistance: 0.01, limit: 5)
        print("   🚉 Found \(nearbyStations.count) nearby stations:")
        
        for (index, stationInfo) in nearbyStations.enumerated() {
            let station = stationInfo.station
            let distance = stationInfo.distance
            print("     \(index + 1). \(station.stationId) (\(station.lineName)) at (\(String(format: "%.6f", station.coordinate.latitude)), \(String(format: "%.6f", station.coordinate.longitude))) - \(Int(distance))m away")
        }
        
        print("========================================")
    }

    // MARK: - Enhanced getHelpfulSubwayRoutesToward with better filtering

    /// Enhanced version with stricter criteria and better logging
    func getHelpfulSubwayRoutesToward(midpoint: CLLocationCoordinate2D, from userCoordinate: CLLocationCoordinate2D) -> [SubwayRoute] {
        guard hasLoadedData else {
            print("❌ No subway data loaded")
            return []
        }

        // Use more generous search radius for nearby stations
        let nearbyStations = getNearbyStations(to: userCoordinate, maxDistance: 0.015, limit: 8)
        
        print("🔍 Enhanced route search:")
        print("   📍 User: (\(String(format: "%.6f", userCoordinate.latitude)), \(String(format: "%.6f", userCoordinate.longitude)))")
        print("   🎯 Midpoint: (\(String(format: "%.6f", midpoint.latitude)), \(String(format: "%.6f", midpoint.longitude)))")
        print("   🚉 Nearby stations: \(nearbyStations.count)")

        var helpfulRoutes: [SubwayRoute] = []

        for stationInfo in nearbyStations {
            let station = stationInfo.station
            let distance = stationInfo.distance
            
            print("   🚉 Checking station: \(station.stationId) (\(station.lineName)) at (\(String(format: "%.6f", station.coordinate.latitude)), \(String(format: "%.6f", station.coordinate.longitude))) - \(Int(distance))m away")
            
            // More generous distance threshold for NYC (12-15 minute walk)
            if distance > 1200 {
                print("     ⏭️ Skipping - too far (\(Int(distance))m)")
                continue
            }

            // Find routes that include this station
            let matchingRoutes = loadedRoutes.filter { route in
                route.displayName == station.lineName &&
                route.stations.contains { routeStation in
                    let stationLoc = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
                    let routeStationLoc = CLLocation(latitude: routeStation.coordinate.latitude, longitude: routeStation.coordinate.longitude)
                    return stationLoc.distance(from: routeStationLoc) < 150 // Slightly more generous matching
                }
            }

            print("     🚇 Found \(matchingRoutes.count) matching routes for line \(station.lineName)")

            for route in matchingRoutes {
                if let closestRouteStation = route.stations.min(by: { station1, station2 in
                    let dist1 = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
                        .distance(from: CLLocation(latitude: station1.coordinate.latitude, longitude: station1.coordinate.longitude))
                    let dist2 = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
                        .distance(from: CLLocation(latitude: station2.coordinate.latitude, longitude: station2.coordinate.longitude))
                    return dist1 < dist2
                }) {
                    
                    print("     📍 Using route station at (\(String(format: "%.6f", closestRouteStation.coordinate.latitude)), \(String(format: "%.6f", closestRouteStation.coordinate.longitude)))")
                    
                    // Use the enhanced direction checking
                    let isHeadingToward = isSubwayHeadingTowardMidpoint(
                        midpoint: midpoint,
                        from: closestRouteStation,
                        in: route
                    )
                    
                    if isHeadingToward {
                        print("     ✅ Route \(route.routeId) (\(route.displayName)) is helpful")
                        helpfulRoutes.append(route)
                    } else {
                        print("     ❌ Route \(route.routeId) (\(route.displayName)) not heading toward midpoint")
                    }
                }
            }
        }

        print("   📊 Final helpful routes: \(helpfulRoutes.count)")
        return Array(Set(helpfulRoutes)) // Remove duplicates
    }

    // MARK: - Enhanced direction checking with stricter criteria

    /// Enhanced version of isSubwayHeadingTowardMidpoint with stricter criteria
    func isSubwayHeadingTowardMidpointEnhanced(midpoint: CLLocationCoordinate2D, from station: SubwayTrackPoint, in route: SubwayRoute, userLocation: CLLocationCoordinate2D) -> Bool {
        guard let currentIndex = route.stations.firstIndex(where: {
            $0.stationId == station.stationId
        }) else {
            print("     ❌ Station not found in route")
            return false
        }
        
        // Need at least 2 more stations to determine direction
        guard currentIndex + 2 < route.stations.count else {
            print("     ❌ Not enough stations to determine direction")
            return false
        }

        let current = station.coordinate
        let next = route.stations[currentIndex + 1].coordinate
        let afterNext = route.stations[currentIndex + 2].coordinate

        // Create direction vectors (use next 2 stations for better direction)
        let routeVector1 = CGVector(dx: next.longitude - current.longitude, dy: next.latitude - current.latitude)
        let routeVector2 = CGVector(dx: afterNext.longitude - next.longitude, dy: afterNext.latitude - next.latitude)
        
        // Average the vectors for more stable direction
        let avgRouteVector = CGVector(
            dx: (routeVector1.dx + routeVector2.dx) / 2,
            dy: (routeVector1.dy + routeVector2.dy) / 2
        )
        
        let toMidpointVector = CGVector(dx: midpoint.longitude - current.longitude, dy: midpoint.latitude - current.latitude)

        // Normalize vectors
        let routeLength = sqrt(pow(avgRouteVector.dx, 2) + pow(avgRouteVector.dy, 2))
        let midpointLength = sqrt(pow(toMidpointVector.dx, 2) + pow(toMidpointVector.dy, 2))
        
        guard routeLength > 0, midpointLength > 0 else {
            print("     ❌ Zero length vector")
            return false
        }

        let dot = (avgRouteVector.dx * toMidpointVector.dx + avgRouteVector.dy * toMidpointVector.dy) / (routeLength * midpointLength)
        
        // Also check if the midpoint is actually reachable (not too far from the route)
        let distanceToMidpoint = CLLocation(latitude: current.latitude, longitude: current.longitude)
            .distance(from: CLLocation(latitude: midpoint.latitude, longitude: midpoint.longitude))
        
        // More strict criteria:
        // 1. Direction must be strongly toward midpoint (dot > 0.7 instead of 0.6)
        // 2. Midpoint must be within reasonable distance (< 5km from station)
        let isDirectionGood = dot > 0.7
        let isDistanceReasonable = distanceToMidpoint < 5000 // 5km
        
        print("     📐 Direction check: dot=\(String(format: "%.3f", dot)), distance=\(Int(distanceToMidpoint))m")
        print("     📊 Result: direction=\(isDirectionGood), distance=\(isDistanceReasonable)")
        
        return isDirectionGood && isDistanceReasonable
    }

    // MARK: - Method to replace in MeepAppView for testing

    // In your MeepAppView, replace the route checking in handleSubwayDataLoad with:
    /*
    let userRoutes = subwayOverlayManager.getHelpfulSubwayRoutesTowardEnhanced(midpoint: midpoint, from: userLoc)
    let friendRoutes = subwayOverlayManager.getHelpfulSubwayRoutesTowardEnhanced(midpoint: midpoint, from: friendLoc)

    // Also add debug calls:
    subwayOverlayManager.debugRouteDetection(midpoint: midpoint, from: userLoc)
    subwayOverlayManager.debugRouteDetection(midpoint: midpoint, from: friendLoc)
    */


    // MARK: - Debug Methods
    
    func debugStationData(for region: MKCoordinateRegion? = nil) {
        print("🚇 === SUBWAY STATION DEBUG ===")
        print("📊 Total loaded routes: \(loadedRoutes.count)")
        print("📊 Total polylines: \(allPolylines.count)")
        print("📊 Total station annotations: \(allStations.count)")
        print("📊 Total subway stations: \(allSubwayStations.count)")
        print("📊 Visible stations: \(visibleStations.count)")
        
        if let region = region {
            print("🗺 Current map span: \(region.span.latitudeDelta)")
            print("🗺 Station threshold: 0.02 (will show: \(region.span.latitudeDelta < 0.02))")
        }
        
        // Show station breakdown by line
        let stationsByLine = Dictionary(grouping: allSubwayStations) { $0.lineName }
        for (line, stations) in stationsByLine.sorted(by: { $0.key < $1.key }) {
            print("🚇 Line \(line): \(stations.count) stations")
        }
        
        // Show first few stations for each line
        for (line, stations) in stationsByLine.prefix(3) {
            print("📍 \(line) stations:")
            for station in stations.prefix(3) {
                print("   - \(station.stationId) at (\(String(format: "%.6f", station.coordinate.latitude)), \(String(format: "%.6f", station.coordinate.longitude)))")
            }
        }
        
        // Check if any routes have stations
        let routesWithStations = loadedRoutes.filter { !$0.stations.isEmpty }
        print("📈 Routes with stations: \(routesWithStations.count)/\(loadedRoutes.count)")
        
        for route in routesWithStations.prefix(3) {
            print("🚇 Route \(route.routeId): \(route.stations.count) stations, \(route.coordinates.count) coordinates")
        }
    }
    
    func debugCSVParsing(fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            print("❌ File not found: \(fileName).csv")
            return
        }
        
        do {
            let csvContent = try String(contentsOf: url)
            let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            print("📄 \(fileName).csv analysis:")
            print("   📊 Total lines: \(lines.count)")
            
            var stationCount = 0
            var coordinateCount = 0
            
            for (index, line) in lines.prefix(10).enumerated() {
                if let point = parseNYCCSVLine(line, sequence: index) {
                    coordinateCount += 1
                    if point.isStation {
                        stationCount += 1
                        print("   🚉 Station \(index): \(point.stationId ?? "nil") at (\(point.latitude), \(point.longitude))")
                    } else {
                        print("   📍 Track \(index): at (\(point.latitude), \(point.longitude))")
                    }
                } else {
                    print("   ❌ Failed to parse line \(index): '\(line)'")
                }
            }
            
            print("   📈 Summary: \(coordinateCount) valid points, \(stationCount) stations in first 10 lines")
            
        } catch {
            print("❌ Error reading \(fileName): \(error)")
        }
    }
    
    func debugVisibleStations(in region: MKCoordinateRegion) {
        let shouldShowStations = region.span.latitudeDelta < 0.02
        print("🔍 Station visibility check:")
        print("   🗺 Map span: \(region.span.latitudeDelta)")
        print("   📏 Threshold: 0.02")
        print("   👁 Should show stations: \(shouldShowStations)")
        print("   📊 Total available stations: \(allStations.count)")
        print("   👀 Currently visible stations: \(visibleStations.count)")
        
        if shouldShowStations && visibleStations.isEmpty && !allStations.isEmpty {
            print("⚠️ WARNING: Should show stations but none are visible!")
            
            // Check if any stations are in the region
            let buffer = region.span.latitudeDelta * 0.3
            let minLat = region.center.latitude - region.span.latitudeDelta/2 - buffer
            let maxLat = region.center.latitude + region.span.latitudeDelta/2 + buffer
            let minLon = region.center.longitude - region.span.longitudeDelta/2 - buffer
            let maxLon = region.center.longitude + region.span.longitudeDelta/2 + buffer
            
            let stationsInRegion = allStations.filter { station in
                station.coordinate.latitude >= minLat &&
                station.coordinate.latitude <= maxLat &&
                station.coordinate.longitude >= minLon &&
                station.coordinate.longitude <= maxLon
            }
            
            print("   📍 Stations in region bounds: \(stationsInRegion.count)")
            print("   🗺 Region bounds: lat(\(String(format: "%.6f", minLat)) to \(String(format: "%.6f", maxLat))), lon(\(String(format: "%.6f", minLon)) to \(String(format: "%.6f", maxLon)))")
            
            // Show nearest stations
            let nearestStations = allStations.prefix(3)
            for station in nearestStations {
                print("   🚉 Station: \(station.title ?? "Unknown") at (\(String(format: "%.6f", station.coordinate.latitude)), \(String(format: "%.6f", station.coordinate.longitude)))")
            }
            
            // Try manually updating visible elements
            print("🔧 Manually triggering updateVisibleElements...")
            updateVisibleElements(for: region)
        }
    }
    
    /// Force update visible stations for debugging
    func forceUpdateStations(for region: MKCoordinateRegion) {
        print("🔧 Force updating stations...")
        updateVisibleElements(for: region)
        print("🎯 After force update: \(visibleStations.count) visible stations")
    }
}



    // MARK: - Subway Route Direction Utility

    /// Determine if a subway route is heading toward a given midpoint from a specific station
    func isSubwayHeadingTowardMidpoint(midpoint: CLLocationCoordinate2D, from station: SubwayTrackPoint, in route: SubwayRoute) -> Bool {
        guard let currentIndex = route.stations.firstIndex(where: {
            $0.stationId == station.stationId
        }), currentIndex + 1 < route.stations.count else {
            return false
        }

        let current = station.coordinate
        let next = route.stations[currentIndex + 1].coordinate

        // Create direction vectors
        let routeVector = CGVector(dx: next.longitude - current.longitude, dy: next.latitude - current.latitude)
        let toMidpointVector = CGVector(dx: midpoint.longitude - current.longitude, dy: midpoint.latitude - current.latitude)

        // Normalize vectors
        let routeLength = sqrt(pow(routeVector.dx, 2) + pow(routeVector.dy, 2))
        let midpointLength = sqrt(pow(toMidpointVector.dx, 2) + pow(toMidpointVector.dy, 2))
        guard routeLength > 0, midpointLength > 0 else { return false }

        let dot = (routeVector.dx * toMidpointVector.dx + routeVector.dy * toMidpointVector.dy) / (routeLength * midpointLength)

        return dot > 0.6 // ~cosine(53°); adjust threshold as needed
    }



    /// Estimate walking time and compare to transit time to determine if fallback is better
    func shouldFallbackToWalking(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, transitTime: TimeInterval, multiplierThreshold: Double = 1.3) -> Bool {
        let fromLoc = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLoc = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distanceInMeters = fromLoc.distance(from: toLoc)
        let miles = distanceInMeters / 1609.34

        let estimatedWalkingTime = miles * 20 * 60 // seconds (20 mins per mile)

        return transitTime > estimatedWalkingTime * multiplierThreshold
    }



// MARK: - Error Types
        enum SubwayLoadingError: LocalizedError {
            case fileNotFound(String)
            case invalidCSV
            case noTrackPoints
            case processingError(String)
            
            var errorDescription: String? {
                switch self {
                case .fileNotFound(let filename):
                    return "Subway CSV file '\(filename)' not found in bundle"
                case .invalidCSV:
                    return "Invalid CSV structure"
                case .noTrackPoints:
                    return "No valid track points found"
                case .processingError(let message):
                    return "Processing error: \(message)"
                }
            }
    }

// MARK: - Helper Extensions
extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

extension CLLocationCoordinate2D {
    var isValid: Bool {
        return CLLocationCoordinate2DIsValid(self)
    }
    
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }
}
