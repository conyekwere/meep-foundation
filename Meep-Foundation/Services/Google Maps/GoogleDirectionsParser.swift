//
//  GoogleDirectionsParser.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/12/25.
//


import Foundation
import CoreLocation

class GoogleDirectionsParser {
    
    // MARK: - Main Response Parsing
    
    static func parseResponse(_ data: Data) throws -> GoogleDirectionsResponse {
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        let status = json["status"] as! String
        let errorMessage = json["error_message"] as? String
        
        var routes: [GoogleRoute] = []
        
        if let routesArray = json["routes"] as? [[String: Any]] {
            routes = try routesArray.map { try parseRoute($0) }
        }
        
        return GoogleDirectionsResponse(
            routes: routes,
            status: status,
            errorMessage: errorMessage
        )
    }
    
    // MARK: - Route Parsing
    
    private static func parseRoute(_ json: [String: Any]) throws -> GoogleRoute {
        let summary = json["summary"] as? String ?? ""
        let overviewPolyline = (json["overview_polyline"] as? [String: Any])?["points"] as? String ?? ""
        
        let duration = try parseDuration(json["duration"] as? [String: Any])
        let distance = try parseDistance(json["distance"] as? [String: Any])
        
        let fare = json["fare"] as? [String: Any]
        let warnings = json["warnings"] as? [String] ?? []
        
        var legs: [GoogleLeg] = []
        if let legsArray = json["legs"] as? [[String: Any]] {
            legs = try legsArray.map { try parseLeg($0) }
        }
        
        return GoogleRoute(
            legs: legs,
            summary: summary,
            overviewPolyline: overviewPolyline,
            duration: duration,
            distance: distance,
            fare: fare != nil ? try parseFare(fare!) : nil,
            warnings: warnings
        )
    }
    
    private static func parseLeg(_ json: [String: Any]) throws -> GoogleLeg {
        let startAddress = json["start_address"] as? String ?? ""
        let endAddress = json["end_address"] as? String ?? ""
        
        let startLocation = try parseLocation(json["start_location"] as! [String: Any])
        let endLocation = try parseLocation(json["end_location"] as! [String: Any])
        
        let duration = try parseDuration(json["duration"] as? [String: Any])
        let distance = try parseDistance(json["distance"] as? [String: Any])
        
        var steps: [GoogleStep] = []
        if let stepsArray = json["steps"] as? [[String: Any]] {
            steps = try stepsArray.map { try parseStep($0) }
        }
        
        return GoogleLeg(
            startAddress: startAddress,
            endAddress: endAddress,
            startLocation: startLocation,
            endLocation: endLocation,
            duration: duration,
            distance: distance,
            steps: steps
        )
    }
    
    private static func parseStep(_ json: [String: Any]) throws -> GoogleStep {
        let htmlInstructions = json["html_instructions"] as? String ?? ""
        let travelMode = json["travel_mode"] as? String ?? ""
        
        let duration = try parseDuration(json["duration"] as? [String: Any])
        let distance = try parseDistance(json["distance"] as? [String: Any])
        
        let startLocation = try parseLocation(json["start_location"] as! [String: Any])
        let endLocation = try parseLocation(json["end_location"] as! [String: Any])
        
        let polyline = (json["polyline"] as? [String: Any])?["points"] as? String ?? ""
        
        var transitDetails: GoogleTransitDetails?
        if let transitJson = json["transit_details"] as? [String: Any] {
            transitDetails = try parseTransitDetails(transitJson)
        }
        
        return GoogleStep(
            htmlInstructions: htmlInstructions,
            distance: distance,
            duration: duration,
            startLocation: startLocation,
            endLocation: endLocation,
            polyline: polyline,
            travelMode: travelMode,
            transitDetails: transitDetails
        )
    }
    
    // MARK: - Transit Details Parsing
    
    private static func parseTransitDetails(_ json: [String: Any]) throws -> GoogleTransitDetails {
        let arrivalStop = try parseTransitStop(json["arrival_stop"] as! [String: Any])
        let departureStop = try parseTransitStop(json["departure_stop"] as! [String: Any])
        let arrivalTime = try parseTime(json["arrival_time"] as! [String: Any])
        let departureTime = try parseTime(json["departure_time"] as! [String: Any])
        
        let headsign = json["headsign"] as? String ?? ""
        let headway = json["headway"] as? Int
        let numStops = json["num_stops"] as? Int ?? 0
        
        let line = try parseTransitLine(json["line"] as! [String: Any])
        
        return GoogleTransitDetails(
            arrivalStop: arrivalStop,
            departureStop: departureStop,
            arrivalTime: arrivalTime,
            departureTime: departureTime,
            headsign: headsign,
            headway: headway,
            numStops: numStops,
            line: line
        )
    }
    
    private static func parseTransitStop(_ json: [String: Any]) throws -> GoogleTransitStop {
        let name = json["name"] as? String ?? ""
        let location = try parseLocation(json["location"] as! [String: Any])
        
        return GoogleTransitStop(name: name, location: location)
    }
    
    private static func parseTransitLine(_ json: [String: Any]) throws -> GoogleTransitLine {
        let name = json["name"] as? String ?? ""
        let shortName = json["short_name"] as? String
        let color = json["color"] as? String
        
        var agencies: [GoogleTransitAgency] = []
        if let agenciesArray = json["agencies"] as? [[String: Any]] {
            agencies = agenciesArray.map { agencyJson in
                GoogleTransitAgency(
                    name: agencyJson["name"] as? String ?? "",
                    url: agencyJson["url"] as? String
                )
            }
        }
        
        let vehicle = try parseTransitVehicle(json["vehicle"] as! [String: Any])
        
        return GoogleTransitLine(
            name: name,
            shortName: shortName,
            color: color,
            agencies: agencies,
            vehicle: vehicle
        )
    }
    
    private static func parseTransitVehicle(_ json: [String: Any]) throws -> GoogleTransitVehicle {
        let name = json["name"] as? String ?? ""
        let type = json["type"] as? String ?? ""
        let icon = json["icon"] as? String
        
        return GoogleTransitVehicle(name: name, type: type, icon: icon)
    }
    
    // MARK: - Utility Parsing
    
    private static func parseTime(_ json: [String: Any]) throws -> GoogleTime {
        let value = json["value"] as! TimeInterval
        let text = json["text"] as? String ?? ""
        let timeZone = json["time_zone"] as? String ?? ""
        
        return GoogleTime(
            value: Date(timeIntervalSince1970: value),
            text: text,
            timeZone: timeZone
        )
    }
    
    private static func parseLocation(_ json: [String: Any]) throws -> CLLocationCoordinate2D {
        let lat = json["lat"] as! Double
        let lng = json["lng"] as! Double
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    private static func parseDuration(_ json: [String: Any]?) throws -> GoogleDuration {
        guard let json = json else {
            return GoogleDuration(value: 0, text: "0 mins")
        }
        
        let value = json["value"] as! TimeInterval
        let text = json["text"] as? String ?? ""
        
        return GoogleDuration(value: value, text: text)
    }
    
    private static func parseDistance(_ json: [String: Any]?) throws -> GoogleDistance {
        guard let json = json else {
            return GoogleDistance(value: 0, text: "0 m")
        }
        
        let value = json["value"] as! Double
        let text = json["text"] as? String ?? ""
        
        return GoogleDistance(value: value, text: text)
    }
    
    private static func parseFare(_ json: [String: Any]) throws -> GoogleFare {
        let currency = json["currency"] as? String ?? "USD"
        let value = json["value"] as! Double
        let text = json["text"] as? String ?? ""
        
        return GoogleFare(currency: currency, value: value, text: text)
    }
}
