import Foundation
import MapKit
import SwiftUI
import os.log

// MARK: - Enhanced Data Structures
struct SubwayTrackPoint {
    let latitude: Double
    let longitude: Double
    let sequence: Int
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct SubwayRoute {
    let routeId: String
    let baseLine: String
    let variant: String?
    let coordinates: [CLLocationCoordinate2D]
    
    var displayName: String {
        return baseLine
    }
}

class OptimizedSubwayMapManager: ObservableObject {
    // MARK: - Published Properties
    @Published var visiblePolylines: [MKPolyline] = []
    @Published var visibleStations: [MKPointAnnotation] = []
    @Published var isLoading = false
    @Published var loadingError: SubwayLoadingError?
    @Published var hasLoadedData = false
    
    // MARK: - Private Properties
    private var allPolylines: [MKPolyline] = []
    private var allStations: [MKPointAnnotation] = []
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
            }
        }
        
        // Convert routes to polylines
        var tempPolylines: [MKPolyline] = []
        
        for route in allRoutes {
            if route.coordinates.count >= 2 {
                let polyline = MKPolyline(coordinates: route.coordinates, count: route.coordinates.count)
                polyline.title = route.displayName
                tempPolylines.append(polyline)
            }
        }
        
        self.loadedRoutes = allRoutes
        self.allPolylines = tempPolylines
    }
    
    private func parseRouteCSVFile(_ fileName: String, routeId: String) -> SubwayRoute? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            return nil // File doesn't exist
        }
        
        do {
            let csvContent = try String(contentsOf: url)
            let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            var coordinates: [CLLocationCoordinate2D] = []
            
            for (index, line) in lines.enumerated() {
                if let point = parseNYCCSVLine(line, sequence: index) {
                    coordinates.append(point.coordinate)
                }
            }
            
            // Parse route info from routeId
            let (baseLine, variant) = parseRouteId(routeId)
            
            return SubwayRoute(
                routeId: routeId,
                baseLine: baseLine,
                variant: variant,
                coordinates: coordinates
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
        // Components: [0: lineId, 1: latitude, 2: longitude, 3: sequence, 4: empty]
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
        
        return SubwayTrackPoint(
            latitude: latitude,
            longitude: longitude,
            sequence: sequence
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
    
    // MARK: - Public Methods
    
    /// Load subway data (defaults to CSV)
    func loadSubwayData(userLocation: CLLocationCoordinate2D? = nil) {
        loadSubwayDataFromCSV()
    }
    
    /// Update visible elements based on zoom level and region
    func updateVisibleElements(for region: MKCoordinateRegion) {
        guard hasLoadedData else { return }
        
        // Always show all polylines for now
        visiblePolylines = allPolylines
        
        // Show stations only when zoomed in (span < 0.05 degrees)
        if region.span.latitudeDelta < 0.05 {
            // Filter stations within visible region with buffer
            let buffer = region.span.latitudeDelta * 0.2
            let minLat = region.center.latitude - region.span.latitudeDelta/2 - buffer
            let maxLat = region.center.latitude + region.span.latitudeDelta/2 + buffer
            let minLon = region.center.longitude - region.span.longitudeDelta/2 - buffer
            let maxLon = region.center.longitude + region.span.longitudeDelta/2 + buffer
            
            visibleStations = allStations.filter { station in
                station.coordinate.latitude >= minLat &&
                station.coordinate.latitude <= maxLat &&
                station.coordinate.longitude >= minLon &&
                station.coordinate.longitude <= maxLon
            }
        } else {
            visibleStations = []
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
        visiblePolylines.removeAll()
        visibleStations.removeAll()
        loadedRoutes.removeAll()
        hasLoadedData = false
        loadingError = nil
    }
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
