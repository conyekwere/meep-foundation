//
//  OptimizedSubwayMapManager.swift
//  Meep-Foundation
//
//  Enhanced with GTFS routing capabilities while maintaining all existing functionality
//

import Foundation
import MapKit
import SwiftUI
import os.log

// MARK: - GTFS Data Structures

struct GTFSStop {
    let stopId: String
    let stopName: String
    let latitude: Float
    let longitude: Float
    let parentStation: String?
    let locationType: Int
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
    }
    
    var isStation: Bool {
        locationType == 1 || parentStation != nil
    }
}

struct GTFSRoute {
    let routeId: String
    let routeShortName: String
    let routeColor: String
    let routeType: Int
    
    var isSubway: Bool {
        routeType == 1
    }
}

struct GTFSTrip {
    let tripId: String
    let routeId: String
    let directionId: Int
    let shapeId: String?
}

struct GTFSStopTime {
    let tripId: String
    let stopId: String
    let stopSequence: Int
}

struct RouteDirection {
    let routeId: String
    let directionId: Int
    let orderedStops: [String]
}




struct SpatialIndex {
    private var grid: [Int: [GTFSStop]] = [:]
    private let gridSize: Double = 0.01
    
    mutating func addStop(_ stop: GTFSStop) {
        let key = gridKey(for: stop.coordinate)
        if grid[key] == nil {
            grid[key] = []
        }
        grid[key]?.append(stop)
    }
    
    func findStopsNear(_ coordinate: CLLocationCoordinate2D, radius: Double) -> [GTFSStop] {
        let centerKey = gridKey(for: coordinate)
        let centerLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        var nearbyStops: [GTFSStop] = []
        let gridRadius = Int(ceil(radius / (gridSize * 111000))) + 1
        
        for dx in -gridRadius...gridRadius {
            for dy in -gridRadius...gridRadius {
                let key = centerKey + dx + (dy * 10000)
                
                if let stopsInCell = grid[key] {
                    for stop in stopsInCell {
                        let stopLocation = CLLocation(latitude: Double(stop.latitude),
                                                     longitude: Double(stop.longitude))
                        let distance = centerLocation.distance(from: stopLocation)
                        
                        if distance <= radius {
                            nearbyStops.append(stop)
                        }
                    }
                }
            }
        }
        
        return nearbyStops
    }
    
    private func gridKey(for coordinate: CLLocationCoordinate2D) -> Int {
        let x = Int(coordinate.longitude / gridSize)
        let y = Int(coordinate.latitude / gridSize)
        return x + (y * 10000)
    }
}

// MARK: - Enhanced Data Structures

struct SubwayTrackPoint: Hashable {
    let latitude: Double
    let longitude: Double
    let sequence: Int
    let stationId: String?
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var isStation: Bool {
        return stationId != nil && !stationId!.isEmpty
    }
    
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
    let stations: [SubwayTrackPoint]
    
    var displayName: String {
        return baseLine
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(routeId)
        hasher.combine(baseLine)
        hasher.combine(variant)
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

// MARK: - Utility Classes

class GeographicAnalyzer {
    
    static func isInFinancialDistrict(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.704 && coord.latitude <= 40.712 &&
               coord.longitude >= -74.017 && coord.longitude <= -74.005
    }

    static func isInBatteryPark(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.703 && coord.latitude <= 40.706 &&
               coord.longitude >= -74.020 && coord.longitude <= -74.015
    }

    static func isInBrookynHeights(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.694 && coord.latitude <= 40.700 &&
               coord.longitude >= -73.998 && coord.longitude <= -73.990
    }

    static func isInDUMBO(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.701 && coord.latitude <= 40.705 &&
               coord.longitude >= -73.991 && coord.longitude <= -73.986
    }

    static func isInLowerEastSide(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.714 && coord.latitude <= 40.722 &&
               coord.longitude >= -73.994 && coord.longitude <= -73.982
    }

    static func isInChinatown(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.714 && coord.latitude <= 40.720 &&
               coord.longitude >= -74.005 && coord.longitude <= -73.994
    }

    static func isInLittleItaly(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.718 && coord.latitude <= 40.723 &&
               coord.longitude >= -74.000 && coord.longitude <= -73.994
    }

    static func isInEastVillage(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.722 && coord.latitude <= 40.732 &&
               coord.longitude >= -73.994 && coord.longitude <= -73.979
    }

    static func isInUpperEastSide(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.768 && coord.latitude <= 40.799 &&
               coord.longitude >= -73.966 && coord.longitude <= -73.945
    }

    static func isInUpperWestSide(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.768 && coord.latitude <= 40.799 &&
               coord.longitude >= -73.989 && coord.longitude <= -73.968
    }

    static func isOnRooseveltIsland(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.751 && coord.latitude <= 40.766 &&
               coord.longitude >= -73.955 && coord.longitude <= -73.948
    }

    static func isInStatenIsland(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.477 && coord.latitude <= 40.651 &&
               coord.longitude >= -74.259 && coord.longitude <= -74.052
    }

    static func isInFarQueens(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.754 && coord.latitude <= 40.794 &&
               coord.longitude >= -73.817 && coord.longitude <= -73.774
    }

    static func isInWilliamsburg(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.701 && coord.latitude <= 40.721 &&
               coord.longitude >= -73.968 && coord.longitude <= -73.936
    }

    static func isInRedHook(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude >= 40.674 && coord.latitude <= 40.686 &&
               coord.longitude >= -74.020 && coord.longitude <= -74.000
    }
    
    static func calculateGeographicMidpoint(_ point1: CLLocationCoordinate2D,
                                           _ point2: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat1 = point1.latitude * .pi / 180
        let lon1 = point1.longitude * .pi / 180
        let lat2 = point2.latitude * .pi / 180
        let lon2 = point2.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        
        let Bx = cos(lat2) * cos(dLon)
        let By = cos(lat2) * sin(dLon)
        
        let lat3 = atan2(sin(lat1) + sin(lat2), sqrt((cos(lat1) + Bx) * (cos(lat1) + Bx) + By * By))
        let lon3 = lon1 + atan2(By, cos(lat1) + Bx)
        
        return CLLocationCoordinate2D(
            latitude: lat3 * 180 / .pi,
            longitude: lon3 * 180 / .pi
        )
    }
    
    static func isWrongDirection(userLocation: CLLocationCoordinate2D,
                                friendLocation: CLLocationCoordinate2D,
                                midpoint: CLLocationCoordinate2D,
                                onLine: String) -> Bool {
        let userToMidpoint = userLocation.latitude - midpoint.latitude
        let friendToMidpoint = friendLocation.latitude - midpoint.latitude
        
        if (userToMidpoint > 0.01 && friendToMidpoint < -0.01) ||
           (userToMidpoint < -0.01 && friendToMidpoint > 0.01) {
            return true
        }
        
        return false
    }
}

class TransferAnalyzer {
    
    private static let majorTransferHubs: [String: [String]] = [
        "Times Square": ["1", "2", "3", "7", "N", "Q", "R", "W"],
        "Union Square": ["4", "5", "6", "L", "N", "Q", "R", "W"],
        "14th St-Union Sq": ["4", "5", "6", "L", "N", "Q", "R", "W"],
        "42nd St-Times Sq": ["1", "2", "3", "7", "N", "Q", "R", "W"],
        "59th St-Columbus Circle": ["A", "B", "C", "D", "1"],
        "125th St": ["4", "5", "6", "A", "B", "C", "D"],
        "Fulton St": ["4", "5", "6", "A", "C", "J", "Z", "R", "W"],
        "Atlantic Ave": ["B", "D", "N", "Q", "R", "W", "2", "3", "4", "5"],
        "Lexington Ave/59th St": ["4", "5", "6", "N", "Q", "R", "W"],
        "14th St-8th Ave": ["A", "C", "E", "L"],
        "West 4th St": ["A", "B", "C", "D", "E", "F", "M"],
        "Canal St": ["J", "Z", "N", "Q", "R", "W", "6"],
        "96th St": ["1", "2", "3", "B", "C"]
    ]
    
    private static let hubCoordinates: [String: CLLocationCoordinate2D] = [
        "Times Square": CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855),
        "Union Square": CLLocationCoordinate2D(latitude: 40.7359, longitude: -73.9906),
        "14th St-Union Sq": CLLocationCoordinate2D(latitude: 40.7359, longitude: -73.9906),
        "42nd St-Times Sq": CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855),
        "59th St-Columbus Circle": CLLocationCoordinate2D(latitude: 40.7677, longitude: -73.9811),
        "125th St": CLLocationCoordinate2D(latitude: 40.8075, longitude: -73.9370),
        "Fulton St": CLLocationCoordinate2D(latitude: 40.7095, longitude: -74.0066),
        "Atlantic Ave": CLLocationCoordinate2D(latitude: 40.6840, longitude: -73.9769),
        "Lexington Ave/59th St": CLLocationCoordinate2D(latitude: 40.7625, longitude: -73.9673),
        "14th St-8th Ave": CLLocationCoordinate2D(latitude: 40.7394, longitude: -74.0020),
        "West 4th St": CLLocationCoordinate2D(latitude: 40.7323, longitude: -74.0004),
        "Canal St": CLLocationCoordinate2D(latitude: 40.7185, longitude: -74.0057),
        "96th St": CLLocationCoordinate2D(latitude: 40.7947, longitude: -73.9724)
    ]
    
    static func checkTransferConnections(fromLine: String, toLines: [String],
                                        fromStation: CLLocationCoordinate2D,
                                        toMidpoint: CLLocationCoordinate2D) -> Bool {
        
        print("         🔄 Checking transfer connections from \(fromLine) to \(toLines)")
        
        for (hubName, hubLines) in majorTransferHubs {
            if hubLines.contains(fromLine) {
                let destinationLinesAtHub = Set(hubLines).intersection(Set(toLines))
                
                if !destinationLinesAtHub.isEmpty {
                    print("         🚇 Transfer hub '\(hubName)' connects \(fromLine) to \(Array(destinationLinesAtHub))")
                    
                    let hubCoordinate = getTransferHubCoordinate(hubName)
                    let isTransferViable = isTransferGeographicallyViable(
                        from: fromStation,
                        via: hubCoordinate,
                        to: toMidpoint
                    )
                    
                    if isTransferViable {
                        print("         ✅ Transfer via \(hubName) is geographically viable")
                        return true
                    }
                }
            }
        }
        
        print("         ❌ No viable transfer connections found")
        return false
    }
    
    static func getTransferHubCoordinate(_ hubName: String) -> CLLocationCoordinate2D {
        return hubCoordinates[hubName] ?? CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855)
    }
    
    static func isTransferGeographicallyViable(from origin: CLLocationCoordinate2D,
                                              via transfer: CLLocationCoordinate2D,
                                              to destination: CLLocationCoordinate2D) -> Bool {
        
        let directDistance = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
            .distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
        
        let viaTransferDistance =
            CLLocation(latitude: origin.latitude, longitude: origin.longitude)
                .distance(from: CLLocation(latitude: transfer.latitude, longitude: transfer.longitude)) +
            CLLocation(latitude: transfer.latitude, longitude: transfer.longitude)
                .distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
        
        let detourRatio = viaTransferDistance / directDistance
        
        print("           Direct: \(Int(directDistance))m, Via transfer: \(Int(viaTransferDistance))m, Ratio: \(String(format: "%.1f", detourRatio))")
        
        return detourRatio < 2.5
    }
    
    static func hasWeekendServiceLimitations(_ lines: [String]) -> Bool {
        let weekendLimitedLines = ["B", "Z", "W"]
        return lines.contains(where: weekendLimitedLines.contains)
    }
    
    static func isWeekend() -> Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 1 || weekday == 7
    }
    
    static func hasViableTransferConnection(fromLines: [String], toLines: [String],
                                           fromLocation: CLLocationCoordinate2D,
                                           toLocation: CLLocationCoordinate2D) -> Bool {
        
        for fromLine in fromLines {
            if checkTransferConnections(fromLine: fromLine, toLines: toLines,
                                      fromStation: fromLocation, toMidpoint: toLocation) {
                return true
            }
        }
        return false
    }
}


// MARK: - Main Class

class OptimizedSubwayMapManager: ObservableObject {
    // MARK: - Published Properties
    @Published var visiblePolylines: [MKPolyline] = []
    @Published var visibleStations: [MKPointAnnotation] = []
    @Published var visibleStationCircles: [MKPolygon] = []
    @Published var isLoading = false
    @Published var loadingError: SubwayLoadingError?
    @Published var hasLoadedData = false
    
    // MARK: - Private Properties
    private var allPolylines: [MKPolyline] = []
    private var allStations: [MKPointAnnotation] = []
    private var allStationCircles: [MKPolygon] = []
    private var allSubwayStations: [SubwayStation] = []
    private var loadedRoutes: [SubwayRoute] = []
    
    // MARK: - GTFS Data Properties
    private var gtfsStops: [String: GTFSStop] = [:]
    private var gtfsRoutes: [String: GTFSRoute] = [:]
    private var gtfsTrips: [String: GTFSTrip] = [:]
    private var gtfsRouteDirections: [String: [RouteDirection]] = [:]
    private var gtfsSpatialIndex: SpatialIndex = SpatialIndex()
    private var isGTFSLoaded = false
    
    // Helper classes
    
    
    // Performance monitoring
    private let logger = Logger(subsystem: "com.meep.subway", category: "performance")
    
    // MARK: - Route Configuration
    private let routeFiles = [
        "1", "2", "3", "4", "5", "6", "7",
        "B", "C", "E", "F", "G", "J", "L", "M", "Q", "R",
        "A-1", "A-2", "D-1", "D-2", "D-3", "N-1", "N-2",
        "FS", "GS", "H", "SI"
    ]
    
    // Complete NYC subway line colors
    private let lineColors: [String: UIColor] = [
        "1": UIColor(red: 238/255, green: 53/255, blue: 46/255, alpha: 1),
        "2": UIColor(red: 238/255, green: 53/255, blue: 46/255, alpha: 1),
        "3": UIColor(red: 238/255, green: 53/255, blue: 46/255, alpha: 1),
        "4": UIColor(red: 0/255, green: 147/255, blue: 60/255, alpha: 1),
        "5": UIColor(red: 0/255, green: 147/255, blue: 60/255, alpha: 1),
        "6": UIColor(red: 0/255, green: 147/255, blue: 60/255, alpha: 1),
        "7": UIColor(red: 185/255, green: 51/255, blue: 173/255, alpha: 1),
        "A": UIColor(red: 40/255, green: 80/255, blue: 173/255, alpha: 1),
        "C": UIColor(red: 40/255, green: 80/255, blue: 173/255, alpha: 1),
        "E": UIColor(red: 40/255, green: 80/255, blue: 173/255, alpha: 1),
        "B": UIColor(red: 255/255, green: 99/255, blue: 25/255, alpha: 1),
        "D": UIColor(red: 255/255, green: 99/255, blue: 25/255, alpha: 1),
        "F": UIColor(red: 255/255, green: 99/255, blue: 25/255, alpha: 1),
        "M": UIColor(red: 255/255, green: 99/255, blue: 25/255, alpha: 1),
        "G": UIColor(red: 108/255, green: 190/255, blue: 69/255, alpha: 1),
        "J": UIColor(red: 153/255, green: 102/255, blue: 51/255, alpha: 1),
        "Z": UIColor(red: 153/255, green: 102/255, blue: 51/255, alpha: 1),
        "L": UIColor(red: 167/255, green: 169/255, blue: 172/255, alpha: 1),
        "N": UIColor(red: 252/255, green: 204/255, blue: 10/255, alpha: 1),
        "Q": UIColor(red: 252/255, green: 204/255, blue: 10/255, alpha: 1),
        "R": UIColor(red: 252/255, green: 204/255, blue: 10/255, alpha: 1),
        "W": UIColor(red: 252/255, green: 204/255, blue: 10/255, alpha: 1),
        "FS": UIColor(red: 128/255, green: 129/255, blue: 131/255, alpha: 1),
        "GS": UIColor(red: 128/255, green: 129/255, blue: 131/255, alpha: 1),
        "H": UIColor(red: 128/255, green: 129/255, blue: 131/255, alpha: 1),
        "SI": UIColor(red: 40/255, green: 80/255, blue: 173/255, alpha: 1)
    ]
    
    // MARK: - CSV Loading Methods
    
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
            } else {
                print("❌ Failed to load route file: \(fileName)")
            }
        }
        
        print("📊 Total CSV routes loaded: \(allRoutes.count)")
        
        var tempPolylines: [MKPolyline] = []
        let groupedRoutes = Dictionary(grouping: allRoutes) { $0.displayName }
        
        for (lineName, routes) in groupedRoutes {
            let uniqueColors = Set(routes.map { getLineColor(for: $0.displayName) })
            let needsOffset = routes.count > 1 && uniqueColors.count > 1
            
            for (index, route) in routes.enumerated() {
                if route.coordinates.count >= 2 {
                    var offsetCoordinates = route.coordinates
                    
                    if needsOffset && index > 0 {
                        offsetCoordinates = applyLineOffset(to: route.coordinates,
                                                          offsetIndex: index,
                                                          totalVariants: routes.count)
                    }
                    
                    let polyline = MKPolyline(coordinates: offsetCoordinates, count: offsetCoordinates.count)
                    polyline.title = route.displayName
                    polyline.subtitle = route.routeId
                    tempPolylines.append(polyline)
                }
                
                let uniqueStations = deduplicateStations(route.stations, tolerance: 0.003)
                
                for station in uniqueStations {
                    let stationAnnotation = MKPointAnnotation()
                    stationAnnotation.coordinate = station.coordinate
                    stationAnnotation.title = route.displayName
                    stationAnnotation.subtitle = station.stationId
                    allStations.append(stationAnnotation)
                    
                    let stationCircle = createStationCircle(at: station.coordinate,
                                                          lineName: route.displayName,
                                                          stationId: station.stationId ?? "")
                    allStationCircles.append(stationCircle)
                    
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
        
        print("✅ CSV loading complete: \(tempPolylines.count) polylines, \(allStations.count) stations")
    }
    
    private func parseRouteCSVFile(_ fileName: String, routeId: String) -> SubwayRoute? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            return nil
        }
        
        do {
            let csvContent = try String(contentsOf: url)
            let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            var coordinates: [CLLocationCoordinate2D] = []
            var stations: [SubwayTrackPoint] = []
            
            for (index, line) in lines.enumerated() {
                if let point = parseNYCCSVLine(line, sequence: index) {
                    coordinates.append(point.coordinate)
                    
                    if point.isStation {
                        stations.append(point)
                    }
                }
            }
            
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
        let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = cleanLine.components(separatedBy: ",")
        
        guard components.count >= 4 else { return nil }
        
        guard let latitude = Double(components[1].trimmingCharacters(in: .whitespacesAndNewlines)),
              let longitude = Double(components[2].trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        
        let isValidNYC = latitude >= 40.4 && latitude <= 41.0 &&
                         longitude >= -74.3 && longitude <= -73.7
        
        guard isValidNYC else { return nil }
        
        let stationId = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        
        return SubwayTrackPoint(
            latitude: latitude,
            longitude: longitude,
            sequence: sequence,
            stationId: stationId.isEmpty ? nil : stationId
        )
    }

    private func parseRouteId(_ routeId: String) -> (baseLine: String, variant: String?) {
        if routeId.contains("-") {
            let parts = routeId.components(separatedBy: "-")
            if parts.count == 2 {
                return (baseLine: parts[0], variant: parts[1])
            }
        }
        
        switch routeId {
        case "SI": return (baseLine: "SIR", variant: nil)
        case "FS": return (baseLine: "FS", variant: nil)
        case "GS": return (baseLine: "GS", variant: nil)
        case "H": return (baseLine: "H", variant: nil)
        default: return (baseLine: routeId, variant: nil)
        }
    }
    
    // MARK: - GTFS Loading Methods
    
    private func loadGTFSDataForRouting() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.loadGTFSStops()
                try self.loadGTFSRoutes()
                try self.loadGTFSTrips()
                try self.loadGTFSStopTimes()
                self.buildGTFSSpatialIndex()
                
                DispatchQueue.main.async {
                    self.isGTFSLoaded = true
                    print("✅ GTFS routing data loaded successfully")
                }
            } catch {
                print("❌ GTFS loading failed: \(error) - using CSV fallback")
            }
        }
    }
    
    private func loadGTFSStops() throws {
        guard let url = Bundle.main.url(forResource: "stops", withExtension: "txt") else {
            throw GTFSError.fileNotFound("stops.txt")
        }
        
        let content = try String(contentsOf: url)
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else { throw GTFSError.invalidFormat }
        
        let headers = parseCSVLine(lines[0])
        guard let stopIdIdx = headers.firstIndex(of: "stop_id"),
              let stopNameIdx = headers.firstIndex(of: "stop_name"),
              let latIdx = headers.firstIndex(of: "stop_lat"),
              let lonIdx = headers.firstIndex(of: "stop_lon"),
              let locationTypeIdx = headers.firstIndex(of: "location_type") else {
            throw GTFSError.invalidFormat
        }
        
        let parentStationIdx = headers.firstIndex(of: "parent_station")
        var tempStops: [String: GTFSStop] = [:]
        
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            let fields = parseCSVLine(line)
            guard fields.count > max(stopIdIdx, stopNameIdx, latIdx, lonIdx, locationTypeIdx) else {
                continue
            }
            
            guard let latitude = Float(fields[latIdx]),
                  let longitude = Float(fields[lonIdx]),
                  let locationType = Int(fields[locationTypeIdx]) else {
                continue
            }
            
            let stopId = fields[stopIdIdx]
            if isSubwayStop(stopId) {
                let stop = GTFSStop(
                    stopId: stopId,
                    stopName: fields[stopNameIdx],
                    latitude: latitude,
                    longitude: longitude,
                    parentStation: parentStationIdx.map { idx in
                        idx < fields.count ? fields[idx] : nil
                    } ?? nil,
                    locationType: locationType
                )
                tempStops[stopId] = stop
            }
        }
        
        self.gtfsStops = tempStops
        print("📊 Loaded \(tempStops.count) GTFS stops")
    }
    
    private func loadGTFSRoutes() throws {
        guard let url = Bundle.main.url(forResource: "routes", withExtension: "txt") else {
            throw GTFSError.fileNotFound("routes.txt")
        }
        
        let content = try String(contentsOf: url)
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else { throw GTFSError.invalidFormat }
        
        let headers = parseCSVLine(lines[0])
        guard let routeIdIdx = headers.firstIndex(of: "route_id"),
              let routeShortNameIdx = headers.firstIndex(of: "route_short_name"),
              let routeTypeIdx = headers.firstIndex(of: "route_type") else {
            throw GTFSError.invalidFormat
        }
        
        let routeColorIdx = headers.firstIndex(of: "route_color")
        var tempRoutes: [String: GTFSRoute] = [:]
        
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            let fields = parseCSVLine(line)
            guard fields.count > max(routeIdIdx, routeShortNameIdx, routeTypeIdx) else {
                continue
            }
            
            guard let routeType = Int(fields[routeTypeIdx]) else { continue }
            
            if routeType == 1 { // Subway only
                let route = GTFSRoute(
                    routeId: fields[routeIdIdx],
                    routeShortName: fields[routeShortNameIdx],
                    routeColor: routeColorIdx.map { idx in
                        idx < fields.count ? fields[idx] : "000000"
                    } ?? "000000",
                    routeType: routeType
                )
                tempRoutes[route.routeId] = route
            }
        }
        
        self.gtfsRoutes = tempRoutes
        print("📊 Loaded \(tempRoutes.count) GTFS routes")
    }
    
    private func loadGTFSTrips() throws {
        guard let url = Bundle.main.url(forResource: "trips", withExtension: "txt") else {
            throw GTFSError.fileNotFound("trips.txt")
        }
        
        let content = try String(contentsOf: url)
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else { throw GTFSError.invalidFormat }
        
        let headers = parseCSVLine(lines[0])
        guard let tripIdIdx = headers.firstIndex(of: "trip_id"),
              let routeIdIdx = headers.firstIndex(of: "route_id"),
              let directionIdIdx = headers.firstIndex(of: "direction_id") else {
            throw GTFSError.invalidFormat
        }
        
        var tempTrips: [String: GTFSTrip] = [:]
        
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            let fields = parseCSVLine(line)
            guard fields.count > max(tripIdIdx, routeIdIdx, directionIdIdx) else {
                continue
            }
            
            let routeId = fields[routeIdIdx]
            
            if gtfsRoutes[routeId] != nil {
                guard let directionId = Int(fields[directionIdIdx]) else { continue }
                
                let trip = GTFSTrip(
                    tripId: fields[tripIdIdx],
                    routeId: routeId,
                    directionId: directionId,
                    shapeId: nil
                )
                tempTrips[trip.tripId] = trip
            }
        }
        
        self.gtfsTrips = tempTrips
        print("📊 Loaded \(tempTrips.count) GTFS trips")
    }
    
    private func loadGTFSStopTimes() throws {
        guard let url = Bundle.main.url(forResource: "stop_times", withExtension: "txt") else {
            throw GTFSError.fileNotFound("stop_times.txt")
        }
        
        let content = try String(contentsOf: url)
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else { throw GTFSError.invalidFormat }
        
        let headers = parseCSVLine(lines[0])
        guard let tripIdIdx = headers.firstIndex(of: "trip_id"),
              let stopIdIdx = headers.firstIndex(of: "stop_id"),
              let stopSequenceIdx = headers.firstIndex(of: "stop_sequence") else {
            throw GTFSError.invalidFormat
        }
        
        var tripStopTimes: [String: [GTFSStopTime]] = [:]
        
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            let fields = parseCSVLine(line)
            guard fields.count > max(tripIdIdx, stopIdIdx, stopSequenceIdx) else {
                continue
            }
            
            let tripId = fields[tripIdIdx]
            let stopId = fields[stopIdIdx]
            
            guard gtfsTrips[tripId] != nil, gtfsStops[stopId] != nil else { continue }
            guard let stopSequence = Int(fields[stopSequenceIdx]) else { continue }
            
            let stopTime = GTFSStopTime(
                tripId: tripId,
                stopId: stopId,
                stopSequence: stopSequence
            )
            
            if tripStopTimes[tripId] == nil {
                tripStopTimes[tripId] = []
            }
            tripStopTimes[tripId]?.append(stopTime)
        }
        
        buildGTFSRouteDirections(from: tripStopTimes)
        print("📊 Processed stop times and built route directions")
    }
    
    private func buildGTFSRouteDirections(from tripStopTimes: [String: [GTFSStopTime]]) {
        var tempDirections: [String: [RouteDirection]] = [:]
        
        let tripsByRoute = Dictionary(grouping: gtfsTrips.values) { $0.routeId }
        
        for (routeId, trips) in tripsByRoute {
            let tripsByDirection = Dictionary(grouping: trips) { $0.directionId }
            var routeDirections: [RouteDirection] = []
            
            for (directionId, directionTrips) in tripsByDirection {
                if let representativeTrip = directionTrips.first,
                   let stopTimes = tripStopTimes[representativeTrip.tripId] {
                    
                    let orderedStops = stopTimes
                        .sorted { $0.stopSequence < $1.stopSequence }
                        .map { $0.stopId }
                    
                    let direction = RouteDirection(
                        routeId: routeId,
                        directionId: directionId,
                        orderedStops: orderedStops
                    )
                    routeDirections.append(direction)
                }
            }
            
            tempDirections[routeId] = routeDirections
        }
        
        self.gtfsRouteDirections = tempDirections
        print("📊 Built directions for \(tempDirections.count) GTFS routes")
    }
    
    private func buildGTFSSpatialIndex() {
        var tempIndex = SpatialIndex()
        
        for (_, stop) in gtfsStops {
            tempIndex.addStop(stop)
        }
        
        self.gtfsSpatialIndex = tempIndex
        print("📊 Built GTFS spatial index with \(gtfsStops.count) stops")
    }
    
    // MARK: - Smart Routing Methods
    
    func shouldUseSubway(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Bool {
        if isGTFSLoaded {
            return shouldUseSubwayGTFS(from: origin, to: destination)
        } else {
            return shouldUseSubwayCSV(from: origin, to: destination)
        }
    }
    
    private func shouldUseSubwayGTFS(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Bool {
        let originStations = gtfsSpatialIndex.findStopsNear(origin, radius: 800)
        let destinationStations = gtfsSpatialIndex.findStopsNear(destination, radius: 800)
        
        guard !originStations.isEmpty && !destinationStations.isEmpty else {
            return false
        }
        
        let viableRoutes = getGTFSViableRoutes(from: origin, to: destination)
        return !viableRoutes.isEmpty
    }
    
    private func shouldUseSubwayCSV(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Bool {
        let helpfulRoutes = getHelpfulSubwayRoutesToward(midpoint: destination, from: origin)
        return !helpfulRoutes.isEmpty
    }
    
    private func getGTFSViableRoutes(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> [String] {
        let originStations = gtfsSpatialIndex.findStopsNear(origin, radius: 800)
        guard !originStations.isEmpty else { return [] }
        
        var viableRoutes: Set<String> = []
        
        for originStation in originStations {
            let routesAtOrigin = getGTFSRoutesForStop(originStation.stopId)
            
            for routeId in routesAtOrigin {
                if gtfsRouteHeadsToward(routeId: routeId, fromStation: originStation.stopId, toward: destination) {
                    if let route = gtfsRoutes[routeId] {
                        viableRoutes.insert(route.routeShortName)
                    }
                }
            }
        }
        
        return Array(viableRoutes)
    }
    
    private func getGTFSRoutesForStop(_ stopId: String) -> [String] {
        var routes: [String] = []
        
        for (routeId, directions) in gtfsRouteDirections {
            for direction in directions {
                if direction.orderedStops.contains(stopId) {
                    routes.append(routeId)
                    break
                }
            }
        }
        
        return routes
    }
    
    private func gtfsRouteHeadsToward(routeId: String, fromStation: String, toward destination: CLLocationCoordinate2D) -> Bool {
        guard let directions = gtfsRouteDirections[routeId] else { return false }
        
        for direction in directions {
            if gtfsDirectionHeadsToward(direction: direction, fromStation: fromStation, toward: destination) {
                return true
            }
        }
        
        return false
    }
    
    private func gtfsDirectionHeadsToward(direction: RouteDirection, fromStation: String, toward destination: CLLocationCoordinate2D) -> Bool {
        guard let startIndex = direction.orderedStops.firstIndex(of: fromStation) else { return false }
        guard startIndex + 2 < direction.orderedStops.count else { return false }
        
        let currentStopId = direction.orderedStops[startIndex]
        let futureStopId = direction.orderedStops[startIndex + 2]
        
        guard let currentStop = gtfsStops[currentStopId],
              let futureStop = gtfsStops[futureStopId] else {
            return false
        }
        
        let routeVector = CGVector(
            dx: Double(futureStop.longitude - currentStop.longitude),
            dy: Double(futureStop.latitude - currentStop.latitude)
        )
        
        let destinationVector = CGVector(
            dx: destination.longitude - Double(currentStop.longitude),
            dy: destination.latitude - Double(currentStop.latitude)
        )
        
        let dot = normalizedDotProduct(routeVector, destinationVector)
        return dot > 0.2
    }
    
    // MARK: - Enhanced Existing Methods
    
    func loadSubwayData(userLocation: CLLocationCoordinate2D? = nil) {
        loadSubwayDataFromCSV()
        loadGTFSDataForRouting()
    }
    
    func getHelpfulSubwayRoutesToward(midpoint: CLLocationCoordinate2D, from userCoordinate: CLLocationCoordinate2D) -> [SubwayRoute] {
        if isGTFSLoaded {
            let gtfsRoutes = getGTFSViableRoutes(from: userCoordinate, to: midpoint)
            if !gtfsRoutes.isEmpty {
                let matchingRoutes = loadedRoutes.filter { route in
                    gtfsRoutes.contains(route.baseLine)
                }
                if !matchingRoutes.isEmpty {
                    print("✅ GTFS found \(matchingRoutes.count) viable routes: \(gtfsRoutes)")
                    return matchingRoutes
                }
            }
        }
        
        guard hasLoadedData else {
            print("❌ No subway data loaded")
            return []
        }

        let nearbyStations = getNearbyStations(to: userCoordinate, maxDistance: 0.015, limit: 8)
        
        print("🔍 CSV fallback route search:")
        print("   📍 User: (\(String(format: "%.6f", userCoordinate.latitude)), \(String(format: "%.6f", userCoordinate.longitude)))")
        print("   🎯 Midpoint: (\(String(format: "%.6f", midpoint.latitude)), \(String(format: "%.6f", midpoint.longitude)))")
        print("   🚉 Nearby stations: \(nearbyStations.count)")

        var helpfulRoutes: [SubwayRoute] = []

        for stationInfo in nearbyStations {
            let station = stationInfo.station
            let distance = stationInfo.distance
            
            print("   🚉 Checking station: \(station.stationId) (\(station.lineName)) - \(Int(distance))m away")
            
            if distance > 1200 {
                print("     ⏭️ Skipping - too far (\(Int(distance))m)")
                continue
            }

            let matchingRoutes = loadedRoutes.filter { route in
                route.displayName == station.lineName &&
                route.stations.contains { routeStation in
                    let stationLoc = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
                    let routeStationLoc = CLLocation(latitude: routeStation.coordinate.latitude, longitude: routeStation.coordinate.longitude)
                    return stationLoc.distance(from: routeStationLoc) < 150
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
                    
                    let isHeadingToward = isSubwayViableSimple(midpoint: midpoint, from: closestRouteStation, in: route)
                    
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
        return Array(Set(helpfulRoutes))
    }
    
    // MARK: - Main Analysis Methods
    
    func updateVisibleElements(for region: MKCoordinateRegion) {
        guard hasLoadedData else { return }
        
        visiblePolylines = allPolylines
        
        if region.span.latitudeDelta < 0.02 {
            let buffer = region.span.latitudeDelta * 0.3
            let minLat = region.center.latitude - region.span.latitudeDelta/2 - buffer
            let maxLat = region.center.latitude + region.span.latitudeDelta/2 + buffer
            let minLon = region.center.longitude - region.span.longitudeDelta/2 - buffer
            let maxLon = region.center.longitude + region.span.longitudeDelta/2 + buffer
            
            let filteredStations = allStations.filter { station in
                station.coordinate.latitude >= minLat &&
                station.coordinate.latitude <= maxLat &&
                station.coordinate.longitude >= minLon &&
                station.coordinate.longitude <= maxLon
            }
            
            let filteredStationCircles = allStationCircles.filter { circle in
                let centerCoord = circle.coordinate
                return centerCoord.latitude >= minLat &&
                       centerCoord.latitude <= maxLat &&
                       centerCoord.longitude >= minLon &&
                       centerCoord.longitude <= maxLon
            }
            
            visibleStations = filteredStations
            visibleStationCircles = filteredStationCircles
        } else {
            visibleStations = []
            visibleStationCircles = []
        }
    }
    
    func getNearbyStations(to coordinate: CLLocationCoordinate2D, maxDistance: Double = 0.015, limit: Int = 8) -> [(station: SubwayStation, distance: Double)] {
        guard hasLoadedData else { return [] }
        
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let maxDistanceMeters = maxDistance * 111000
        
        var nearbyStations: [(station: SubwayStation, distance: Double)] = []
        
        for station in allSubwayStations {
            let stationLocation = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
            let distance = targetLocation.distance(from: stationLocation)
            
            if distance <= maxDistanceMeters {
                nearbyStations.append((station: station, distance: distance))
            }
        }
        
        nearbyStations.sort { $0.distance < $1.distance }
        return Array(nearbyStations.prefix(limit))
    }

    func isSubwayHeadingTowardMidpoint(midpoint: CLLocationCoordinate2D, from station: SubwayTrackPoint, in route: SubwayRoute) -> Bool {
        let current = station.coordinate
        let stationToMidpoint = CLLocation(latitude: current.latitude, longitude: current.longitude)
            .distance(from: CLLocation(latitude: midpoint.latitude, longitude: midpoint.longitude))
        
        print("       🎯 NYC Subway Connection Analysis:")
        print("         Station: (\(String(format: "%.6f", current.latitude)), \(String(format: "%.6f", current.longitude)))")
        print("         Line: \(route.displayName)")
        print("         Midpoint: (\(String(format: "%.6f", midpoint.latitude)), \(String(format: "%.6f", midpoint.longitude)))")
        print("         Distance to midpoint: \(Int(stationToMidpoint))m")
        
        let linesNearMidpoint = getLinesNear(coordinate: midpoint, radius: 0.008)
        print("         Lines near midpoint: \(linesNearMidpoint)")
        
        if linesNearMidpoint.contains(route.displayName) {
            print("         ✅ Direct line connection available")
            return true
        }
        
        let hasViableTransfer = TransferAnalyzer.checkTransferConnections(
            fromLine: route.displayName,
            toLines: linesNearMidpoint,
            fromStation: current,
            toMidpoint: midpoint
        )
        
        if hasViableTransfer {
            print("         ✅ Viable transfer connection found")
            return true
        } else {
            print("         ❌ No viable subway connection to midpoint area")
            return false
        }
    }

    func analyzeSubwayConnectivity(userLocation: CLLocationCoordinate2D,
                                 friendLocation: CLLocationCoordinate2D,
                                 midpoint: CLLocationCoordinate2D) -> (userViable: Bool, friendViable: Bool, reason: String) {
        
        print("🔍 === NYC SUBWAY CONNECTIVITY ANALYSIS ===")
        
        let userLines = getLinesNear(coordinate: userLocation, radius: 0.008)
        let friendLines = getLinesNear(coordinate: friendLocation, radius: 0.008)
        let midpointLines = getLinesNear(coordinate: midpoint, radius: 0.008)
        
        print("   User lines: \(userLines)")
        print("   Friend lines: \(friendLines)")
        print("   Midpoint lines: \(midpointLines)")
        
        var userViable = true
        var friendViable = true
        var reason = ""
        
        // SPECIAL CASE 1: East Harlem ↔ West Harlem (geographic)
        let userIsEastHarlem = userLocation.latitude >= 40.785 && userLocation.latitude <= 40.825 && userLocation.longitude >= -73.95
        let userIsWestHarlem = userLocation.latitude >= 40.785 && userLocation.latitude <= 40.825 && userLocation.longitude < -73.95
        let friendIsEastHarlem = friendLocation.latitude >= 40.785 && friendLocation.latitude <= 40.825 && friendLocation.longitude >= -73.95
        let friendIsWestHarlem = friendLocation.latitude >= 40.785 && friendLocation.latitude <= 40.825 && friendLocation.longitude < -73.95
        
        print("   User in East Harlem: \(userIsEastHarlem), West Harlem: \(userIsWestHarlem)")
        print("   Friend in East Harlem: \(friendIsEastHarlem), West Harlem: \(friendIsWestHarlem)")
        
        if (userIsEastHarlem && friendIsWestHarlem) || (userIsWestHarlem && friendIsEastHarlem) {
            print("   🚨 DETECTED: East Harlem ↔ West Harlem connection")
            reason = "East Harlem  ↔  West Harlem requires inefficient downtown transfer - walking/taxi recommended"
            userViable = false
            friendViable = false
        } else if userIsEastHarlem && friendIsEastHarlem {
            let distance = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                .distance(from: CLLocation(latitude: friendLocation.latitude, longitude: friendLocation.longitude))
            
            if distance < 2000 {
                reason = "Both users in East Harlem area - walking is more efficient"
                userViable = false
                friendViable = false
            }
        } else if userIsWestHarlem && friendIsWestHarlem {
            let distance = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                .distance(from: CLLocation(latitude: friendLocation.latitude, longitude: friendLocation.longitude))
            
            if distance < 2000 {
                reason = "Both users in West Harlem area - walking is more efficient"
                userViable = false
                friendViable = false
            }
        }
        
        // Additional special cases using GeographicAnalyzer
        if GeographicAnalyzer.isInFinancialDistrict(userLocation) && GeographicAnalyzer.isInBatteryPark(friendLocation) ||
           GeographicAnalyzer.isInBatteryPark(userLocation) && GeographicAnalyzer.isInFinancialDistrict(friendLocation) {
            reason += "Financial District to Battery Park is more efficient by foot. "
            userViable = false
            friendViable = false
        }
        
        if GeographicAnalyzer.isInBrookynHeights(userLocation) && GeographicAnalyzer.isInDUMBO(friendLocation) ||
           GeographicAnalyzer.isInDUMBO(userLocation) && GeographicAnalyzer.isInBrookynHeights(friendLocation) {
            reason += "Brooklyn Heights to DUMBO is faster by foot or taxi. "
            userViable = false
            friendViable = false
        }
        
        if (GeographicAnalyzer.isInLowerEastSide(userLocation) && GeographicAnalyzer.isInChinatown(friendLocation)) ||
           (GeographicAnalyzer.isInChinatown(userLocation) && GeographicAnalyzer.isInLittleItaly(friendLocation)) ||
           (GeographicAnalyzer.isInLowerEastSide(userLocation) && GeographicAnalyzer.isInLittleItaly(friendLocation)) {
            reason += "Lower Manhattan neighborhoods are better connected by walking. "
            userViable = false
            friendViable = false
        }
        
        if GeographicAnalyzer.isInUpperEastSide(userLocation) && GeographicAnalyzer.isInUpperWestSide(friendLocation) &&
           (userLocation.latitude > 40.7794 || friendLocation.latitude > 40.7794) {
            reason += "Upper East/West Side crosstown better by bus or taxi above 86th St. "
            userViable = false
            friendViable = false
        }
        
        if GeographicAnalyzer.isOnRooseveltIsland(userLocation) || GeographicAnalyzer.isOnRooseveltIsland(friendLocation) {
            if !midpointLines.contains("F") && !userLines.contains("F") && !friendLines.contains("F") {
                reason += "Roosevelt Island requires F train or tram connection. "
                if GeographicAnalyzer.isOnRooseveltIsland(userLocation) { userViable = false }
                if GeographicAnalyzer.isOnRooseveltIsland(friendLocation) { friendViable = false }
            }
        }
        
        if GeographicAnalyzer.isInStatenIsland(userLocation) || GeographicAnalyzer.isInStatenIsland(friendLocation) {
            reason += "Staten Island requires ferry connection - suggest driving or express bus. "
            if GeographicAnalyzer.isInStatenIsland(userLocation) { userViable = false }
            if GeographicAnalyzer.isInStatenIsland(friendLocation) { friendViable = false }
        }
        
        if GeographicAnalyzer.isInFarQueens(userLocation) || GeographicAnalyzer.isInFarQueens(friendLocation) {
            reason += "Far Queens areas not well served by subway - consider LIRR or driving. "
            if GeographicAnalyzer.isInFarQueens(userLocation) && userLines.isEmpty { userViable = false }
            if GeographicAnalyzer.isInFarQueens(friendLocation) && friendLines.isEmpty { friendViable = false }
        }
        
        if (GeographicAnalyzer.isInWilliamsburg(userLocation) && GeographicAnalyzer.isInLowerEastSide(friendLocation)) ||
           (GeographicAnalyzer.isInLowerEastSide(userLocation) && GeographicAnalyzer.isInWilliamsburg(friendLocation)) ||
           (GeographicAnalyzer.isInWilliamsburg(userLocation) && GeographicAnalyzer.isInEastVillage(friendLocation)) ||
           (GeographicAnalyzer.isInEastVillage(userLocation) && GeographicAnalyzer.isInWilliamsburg(friendLocation)) {
            
            let distance = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                .distance(from: CLLocation(latitude: friendLocation.latitude, longitude: friendLocation.longitude))
            
            if distance < 2500 {
                reason += "Williamsburg to LES/East Village faster via bridge walk/bike. "
                userViable = false
                friendViable = false
            }
        }
        
        if GeographicAnalyzer.isInRedHook(userLocation) || GeographicAnalyzer.isInRedHook(friendLocation) {
            reason += "Red Hook has no subway service - use bus or taxi. "
            if GeographicAnalyzer.isInRedHook(userLocation) { userViable = false }
            if GeographicAnalyzer.isInRedHook(friendLocation) { friendViable = false }
        }
        
        let commonLines = Set(userLines).intersection(Set(friendLines))
        if !commonLines.isEmpty {
            for line in commonLines {
                if GeographicAnalyzer.isWrongDirection(userLocation: userLocation, friendLocation: friendLocation,
                                  midpoint: midpoint, onLine: line) {
                    reason += "Same line but requires inefficient reverse direction travel. "
                }
            }
        }
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        if currentHour >= 1 && currentHour <= 5 {
            let limitedNightLines = ["B", "Z", "W"]
            let hasLimitedService = userLines.contains(where: limitedNightLines.contains) ||
                                   friendLines.contains(where: limitedNightLines.contains)
            
            if hasLimitedService {
                reason += "Limited late night subway service - consider alternatives. "
            }
        }
        
        if reason.isEmpty {
            let userDirectConnections = Set(userLines).intersection(Set(midpointLines))
            let friendDirectConnections = Set(friendLines).intersection(Set(midpointLines))
            
            print("   User direct connections: \(Array(userDirectConnections))")
            print("   Friend direct connections: \(Array(friendDirectConnections))")
            
            if userDirectConnections.isEmpty {
                userViable = false
                if reason.isEmpty {
                    reason = "No direct subway connection from user location to midpoint"
                }
            }
            
            if friendDirectConnections.isEmpty {
                friendViable = false
                if reason.isEmpty {
                    reason = "No direct subway connection from friend location to midpoint"
                } else if !userViable {
                    reason = "No direct subway connections available for this trip"
                }
            }
        }
        
        print("   Result: User viable=\(userViable), Friend viable=\(friendViable)")
        print("   Reason: \(reason.isEmpty ? "Good subway connections available" : reason)")
        print("============================================")
        
        return (userViable, friendViable, reason)
    }
    
    func isSubwayViableSimple(midpoint: CLLocationCoordinate2D, from station: SubwayTrackPoint, in route: SubwayRoute) -> Bool {
        let current = station.coordinate
        let distanceToMidpoint = CLLocation(latitude: current.latitude, longitude: current.longitude)
            .distance(from: CLLocation(latitude: midpoint.latitude, longitude: midpoint.longitude))
        
        let isReasonableDistance = distanceToMidpoint < 25000
        let isInNYC = midpoint.latitude > 40.4 && midpoint.latitude < 41.0 &&
                      midpoint.longitude > -74.3 && midpoint.longitude < -73.7
        
        print("       🎯 Simple check: distance=\(Int(distanceToMidpoint))m, inNYC=\(isInNYC) -> \(isReasonableDistance && isInNYC)")
        
        return isReasonableDistance && isInNYC
    }
    
    // MARK: - Line Offset Methods
    
    private func applyLineOffset(to coordinates: [CLLocationCoordinate2D],
                                offsetIndex: Int,
                                totalVariants: Int) -> [CLLocationCoordinate2D] {
        guard totalVariants > 1 && offsetIndex > 0 else {
            return coordinates
        }
        
        let baseOffsetDistance: Double = 0.00006
        let offsetDistance = baseOffsetDistance * Double(offsetIndex)
        
        return coordinates.compactMap { coord in
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
        
        var directionLat: Double = 0
        var directionLon: Double = 0
        
        if index > 0 && index < coordinates.count - 1 {
            let prevCoord = coordinates[index - 1]
            let nextCoord = coordinates[index + 1]
            directionLat = nextCoord.latitude - prevCoord.latitude
            directionLon = nextCoord.longitude - prevCoord.longitude
        } else if index > 0 {
            let prevCoord = coordinates[index - 1]
            directionLat = coordinate.latitude - prevCoord.latitude
            directionLon = coordinate.longitude - prevCoord.longitude
        } else if index < coordinates.count - 1 {
            let nextCoord = coordinates[index + 1]
            directionLat = nextCoord.latitude - coordinate.latitude
            directionLon = nextCoord.longitude - coordinate.longitude
        } else {
            return coordinate
        }
        
        let magnitude = sqrt(directionLat * directionLat + directionLon * directionLon)
        guard magnitude > 0 else { return coordinate }
        
        directionLat /= magnitude
        directionLon /= magnitude
        
        let perpLat = side == .right ? -directionLon : directionLon
        let perpLon = side == .right ? directionLat : -directionLat
        
        return CLLocationCoordinate2D(
            latitude: coordinate.latitude + perpLat * distance,
            longitude: coordinate.longitude + perpLon * distance
        )
    }
    
    // MARK: - Visual Methods
    
    func getLineWidth(for lineName: String, zoomLevel: Double = 1.0) -> CGFloat {
        let baseWidth: CGFloat = 1.5
        let zoomAdjustedWidth = baseWidth * CGFloat(max(0.2, min(1.0, zoomLevel)))
        
        switch lineName {
        case "FS", "GS", "H":
            return max(0.3, zoomAdjustedWidth * 0.4)
        case "SIR":
            return max(0.4, zoomAdjustedWidth * 0.5)
        default:
            return max(0.4, zoomAdjustedWidth)
        }
    }
    
    func getLineColor(for lineName: String) -> UIColor {
        return lineColors[lineName] ?? UIColor.systemGray
    }
    
    func getStationColor(for lineName: String) -> (fill: UIColor, stroke: UIColor) {
        let lineColor = getLineColor(for: lineName)
        return (fill: lineColor, stroke: lineColor)
    }
    
    private func createStationCircle(at coordinate: CLLocationCoordinate2D,
                                   lineName: String,
                                   stationId: String) -> MKPolygon {
        let radiusInDegrees: Double = 0.000068
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
    
    private func deduplicateStations(_ stations: [SubwayTrackPoint], tolerance: Double) -> [SubwayTrackPoint] {
        var uniqueStations: [SubwayTrackPoint] = []
        
        for station in stations {
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
    
    // MARK: - Utility Methods
    
    private func normalizedDotProduct(_ v1: CGVector, _ v2: CGVector) -> Double {
        let magnitude1 = sqrt(v1.dx * v1.dx + v1.dy * v1.dy)
        let magnitude2 = sqrt(v2.dx * v2.dx + v2.dy * v2.dy)
        
        guard magnitude1 > 0, magnitude2 > 0 else { return 0 }
        
        return (v1.dx * v2.dx + v1.dy * v2.dy) / (magnitude1 * magnitude2)
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i = line.index(after: i)
        }
        
        fields.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
        return fields
    }
    
    private func isSubwayStop(_ stopId: String) -> Bool {
        return !stopId.contains("BUS") && !stopId.hasPrefix("MTABC")
    }
    
    func clearData() {
        allPolylines.removeAll()
        allStations.removeAll()
        allStationCircles.removeAll()
        allSubwayStations.removeAll()
        visiblePolylines.removeAll()
        visibleStations.removeAll()
        visibleStationCircles.removeAll()
        loadedRoutes.removeAll()
        gtfsStops.removeAll()
        gtfsRoutes.removeAll()
        gtfsTrips.removeAll()
        gtfsRouteDirections.removeAll()
        gtfsSpatialIndex = SpatialIndex()
        hasLoadedData = false
        isGTFSLoaded = false
        loadingError = nil
    }
    
    // MARK: - Station and Line Query Methods
    
    func findNearestStation(to coordinate: CLLocationCoordinate2D, maxDistance: Double = 0.01) -> SubwayStation? {
        guard hasLoadedData else { return nil }
        
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var nearestStation: SubwayStation?
        var minDistance: Double = Double.infinity
        
        for station in allSubwayStations {
            let stationLocation = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
            let distance = targetLocation.distance(from: stationLocation)
            
            let maxDistanceMeters = maxDistance * 111000
            
            if distance < maxDistanceMeters && distance < minDistance {
                minDistance = distance
                nearestStation = station
            }
        }
        
        return nearestStation
    }
    
    func getLinesNear(coordinate: CLLocationCoordinate2D, radius: Double = 0.005) -> [String] {
        guard hasLoadedData else { return [] }
        
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let radiusMeters = radius * 111000
        
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
    
    func getZoomLevel(from region: MKCoordinateRegion) -> Double {
        let latitudeDelta = region.span.latitudeDelta
        
        if latitudeDelta > 0.5 {
            return 0.3
        } else if latitudeDelta > 0.1 {
            return 0.6
        } else if latitudeDelta > 0.05 {
            return 1.0
        } else if latitudeDelta > 0.01 {
            return 1.5
        } else {
            return 2.0
        }
    }
    
    func getStationRadius(for zoomLevel: Double) -> CGFloat {
        let baseRadius: CGFloat = 3.0
        let zoomAdjustedRadius = baseRadius * CGFloat(max(0.5, min(2.0, zoomLevel)))
        return max(2.0, zoomAdjustedRadius)
    }
    
    func getStationCircleRadius(for zoomLevel: Double) -> Double {
        let baseRadius: Double = 0.000135
        let zoomAdjustedRadius = baseRadius * max(0.5, min(2.0, zoomLevel))
        return zoomAdjustedRadius
    }
    
    func shouldFallbackToWalking(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, transitTime: TimeInterval, multiplierThreshold: Double = 1.3) -> Bool {
        let fromLoc = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLoc = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distanceInMeters = fromLoc.distance(from: toLoc)
        let miles = distanceInMeters / 1609.34

        let estimatedWalkingTime = miles * 20 * 60

        return transitTime > estimatedWalkingTime * multiplierThreshold
    }
    
    
    // MARK: - Debug Methods
    
    func debugStationData(for region: MKCoordinateRegion? = nil) {
        print("🚇 === SUBWAY STATION DEBUG ===")
        print("📊 Total loaded routes: \(loadedRoutes.count)")
        print("📊 Total polylines: \(allPolylines.count)")
        print("📊 Total station annotations: \(allStations.count)")
        print("📊 Total subway stations: \(allSubwayStations.count)")
        print("📊 Visible stations: \(visibleStations.count)")
        print("🔧 GTFS loaded: \(isGTFSLoaded)")
        
        if let region = region {
            print("🗺 Current map span: \(region.span.latitudeDelta)")
            print("🗺 Station threshold: 0.02 (will show: \(region.span.latitudeDelta < 0.02))")
        }
        
        let stationsByLine = Dictionary(grouping: allSubwayStations) { $0.lineName }
        for (line, stations) in stationsByLine.sorted(by: { $0.key < $1.key }) {
            print("🚇 Line \(line): \(stations.count) stations")
        }
        
        let routesWithStations = loadedRoutes.filter { !$0.stations.isEmpty }
        print("📈 Routes with stations: \(routesWithStations.count)/\(loadedRoutes.count)")
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
            
            let nearestStations = allStations.prefix(3)
            for station in nearestStations {
                print("   🚉 Station: \(station.title ?? "Unknown") at (\(String(format: "%.6f", station.coordinate.latitude)), \(String(format: "%.6f", station.coordinate.longitude)))")
            }
            
            print("🔧 Manually triggering updateVisibleElements...")
            updateVisibleElements(for: region)
        }
    }
    
    func forceUpdateStations(for region: MKCoordinateRegion) {
        print("🔧 Force updating stations...")
        updateVisibleElements(for: region)
        print("🎯 After force update: \(visibleStations.count) visible stations")
    }
    
    func debugRouteDetection(midpoint: CLLocationCoordinate2D, from userCoordinate: CLLocationCoordinate2D) {
        guard hasLoadedData else {
            print("❌ No subway data loaded")
            return
        }
        
        print("🔍 === ENHANCED SUBWAY ROUTE DEBUG ===")
        print("   📍 User location: (\(String(format: "%.6f", userCoordinate.latitude)), \(String(format: "%.6f", userCoordinate.longitude)))")
        print("   🎯 Midpoint: (\(String(format: "%.6f", midpoint.latitude)), \(String(format: "%.6f", midpoint.longitude)))")
        print("   🔧 GTFS loaded: \(isGTFSLoaded)")
        
        if isGTFSLoaded {
            let gtfsViableRoutes = getGTFSViableRoutes(from: userCoordinate, to: midpoint)
            print("   🚇 GTFS viable routes: \(gtfsViableRoutes)")
        }
        
        let nearbyStations = getNearbyStations(to: userCoordinate, maxDistance: 0.015, limit: 5)
        print("   🚉 Found \(nearbyStations.count) nearby stations:")
        
        for (index, stationInfo) in nearbyStations.enumerated() {
            let station = stationInfo.station
            let distance = stationInfo.distance
            print("     \(index + 1). \(station.stationId) (\(station.lineName)) - \(Int(distance))m away")
        }
        
        print("========================================")
    }
}

// MARK: - Error Types

enum GTFSError: LocalizedError {
    case fileNotFound(String)
    case invalidFormat
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "GTFS file not found: \(filename)"
        case .invalidFormat:
            return "Invalid GTFS file format"
        case .unknown:
            return "Unknown GTFS error"
        }
    }
}

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

// MARK: - Useful Extensions (These are appropriate as they extend system types)

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
