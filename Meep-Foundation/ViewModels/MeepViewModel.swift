//
//  MeepViewModel.swift
//  Meep-Foundation
//
//  Fully restored, optimized, and integrated with Apple Maps + Google Places + Google Directions.
//  - Apple Maps for location search & navigation
//  - Google Places SDK for metadata (images, ratings, etc.)
//  - Google Directions for enhanced transit routing
//
//  Created by Chima Onyekwere on 1/21/25.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation
import Combine
import GooglePlaces
import PostHog

// MARK: – Google Photo Limits & Auto‐Load Config
private var googlePhotoCallCount = 20
private let googlePhotoDailyCap = 3000
private let maxAutoPhotosPerSearch = 0

class MeepViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - App Launch & Calculation Timestamps
    @AppStorage("firstLaunchTimestamp") private var firstLaunchTimestamp: Double = 0
    @AppStorage("firstCalculationTimestamp") private var firstCalculationTimestamp: Double?

    // MARK: - Visited Places Persistence

    private let visitedPlacesKey = "visitedPlaceIDs"

    /// IDs of meeting points the user has visited.
    var visitedPlaceIDs: [String] {
        get {
            UserDefaults.standard.stringArray(forKey: visitedPlacesKey) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: visitedPlacesKey)
        }
    }

    /// Marks a meeting point as visited, storing its ID.
    func markVisited(_ point: MeetingPoint) {
        var ids = visitedPlaceIDs
        let idString = point.id.uuidString
        if !ids.contains(idString) {
            ids.append(idString)
            visitedPlaceIDs = ids
        }
    }
    
    // MARK: - 🌍 Map & Meeting Point Management
    @Published var mapRegion: MKCoordinateRegion = .init(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    weak var subwayManager: OptimizedSubwayMapManager?
    

    
    // MARK: - 🎯 Midpoint Calculation & Filtering
    
    @Published var meetingPoints: [MeetingPoint] = [
        MeetingPoint(name: "McSorley's Old Ale House", emoji: "🍺", category: "Bar",
                     coordinate: CLLocationCoordinate2D(latitude: 40.728838, longitude: -73.9896487),
                     imageUrl: "https://thumbs.6sqft.com/wp-content/uploads/2017/03/10104443/02McSorleysInterior5Center72900.jpg?w=900&format=webp"),
        
        MeetingPoint(name: "Izakaya Toribar", emoji: "🍴", category: "Restaurant",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7596279, longitude: -73.9685453),
                     imageUrl: "https://i0.wp.com/izakayatoribar.com/wp-content/uploads/2020/02/FAA09132.jpg?resize=1024%2C683&ssl=1"),
        
        MeetingPoint(name: "Central Park", emoji: "🌳", category: "Park",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7943199, longitude: -73.9548079),
                     imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg/1599px-Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg"),
        
        MeetingPoint(name: "The Oasis Cafe", emoji: "☕", category: "Coffee shop",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7671355, longitude: -73.9866929),
                     imageUrl: "https://lh5.googleusercontent.com/p/AF1QipPCLsIFjbErCOILrg-jnMWBFmNG3RdSuEKsWd8E=w800-h500-k-no"),
        
        MeetingPoint(name: "Museum of Art", emoji: "🎨", category: "Museum",
                     coordinate: CLLocationCoordinate2D(latitude: 40.7794, longitude: -73.9632),
                     imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Metropolitan_Museum_of_Art_%28The_Met%29_-_Central_Park%2C_NYC.jpg/500px-Metropolitan_Museum_of_Art_%28The_Met%29_-_Central_Park%2C_NYC.jpg")
    ]
    
    @Published var categories: [Category] = [
        Category(emoji: "", name: "All", hidden: false),
        Category(emoji: "🍴", name: "Restaurant", hidden: false),
        Category(emoji: "🍺", name: "Bar", hidden: false),
        Category(emoji: "🌳", name: "Park", hidden: false),
        Category(emoji: "☕", name: "Coffee shop", hidden: false)
    ]
    
    @Published var hiddenCategories: [Category] = [
        Category(emoji: "✈️", name: "Airport", hidden: true),
        Category(emoji: "🍞", name: "Bakery", hidden: true),
        Category(emoji: "🏖", name: "Beach", hidden: true),
        Category(emoji: "🏋️", name: "Gym", hidden: true),
        Category(emoji: "🍎", name: "Groceries", hidden: true),
        Category(emoji: "🏨", name: "Hotel", hidden: true),
        Category(emoji: "📚", name: "Library", hidden: true),
        Category(emoji: "🎭", name: "Theater", hidden: true),
        Category(emoji: "🎨", name: "Museum", hidden: true),
        Category(emoji: "🏞", name: "National Park", hidden: true),
        Category(emoji: "🪩", name: "Nightlife", hidden: true),
        Category(emoji: "🚉", name: "Public Transport", hidden: true),
        Category(emoji: "🏟", name: "Stadium", hidden: true),
        Category(emoji: "🎓", name: "University", hidden: true),
        Category(emoji: "🍷", name: "Winery", hidden: true),
        Category(emoji: "🦁", name: "Zoo", hidden: true)
    ]
    
    // Mapping from MKLocalSearch place types to our categories.
    let categoryMapping: [String: (category: String, emoji: String)] = [
        // Apple MKPointOfInterestCategory (alphabetical)
        "mkpoicategoryairport": ("Airport", "✈️"),
        "mkpoicategoryamusementpark": ("Amusement Park", "🎢"),
        "mkpoicategoryaquarium": ("Aquarium", "🐠"),
        "mkpoicategoryatm": ("ATM", "🏧"),
        "mkpoicategorybakery": ("Bakery", "🍞"),
        "mkpoicategorybank": ("Bank", "🏦"),
        "mkpoicategorybeach": ("Beach", "🏖"),
        "mkpoicategorybrewery": ("Brewery", "🍺"),
        "mkpoicategorycafe": ("Cafe", "☕"),
        "mkpoicategorycampground": ("Campground", "🏕"),
        "mkpoicategorycarrental": ("Car Rental", "🚗"),
        "mkpoicategoryevcharger": ("EV Charger", "🔌"),
        "mkpoicategoryfirestation": ("Fire Station", "🚒"),
        "mkpoicategoryfitnesscenter": ("Gym", "🏋️"),
        "mkpoicategoryfoodmarket": ("Groceries", "🍎"),
        "mkpoicategorygasstation": ("Gas Station", "⛽️"),
        "mkpoicategoryhospital": ("Hospital", "🏥"),
        "mkpoicategoryhotel": ("Hotel", "🏨"),
        "mkpoicategorylaundry": ("Laundry", "🧺"),
        "mkpoicategorylibrary": ("Library", "📚"),
        "mkpoicategorymarina": ("Marina", "🚤"),
        "mkpoicategorymovietheater": ("Movie Theater", "🎬"),
        "mkpoicategorymuseum": ("Museum", "🎨"),
        "mkpoicategorynationalpark": ("National Park", "🏞"),
        "mkpoicategorynightlife": ("Bar", "🍺"),
        "mkpoicategorypark": ("Park", "🌳"),
        "mkpoicategoryparking": ("Parking", "🅿️"),
        "mkpoicategorypharmacy": ("Pharmacy", "💊"),
        "mkpoicategorypolice": ("Police", "🚓"),
        "mkpoicategorypostoffice": ("Post Office", "📮"),
        "mkpoicategorypublictransport": ("Public Transport", "🚉"),
        "mkpoicategoryrestaurant": ("Restaurant", "🍴"),
        "mkpoicategoryrestroom": ("Restroom", "🚻"),
        "mkpoicategoryschool": ("School", "🏫"),
        "mkpoicategorystadium": ("Stadium", "🏟"),
        "mkpoicategorystore": ("Store", "🛍"),
        "mkpoicategorytheater": ("Theater", "🎭"),
        "mkpoicategoryuniversity": ("University", "🎓"),
        "mkpoicategorywinery": ("Winery", "🍷"),
        "mkpoicategoryzoo": ("Zoo", "🦁"),
        // Other generic/legacy mappings
        "airport": ("Airport", "✈️"),
        "art gallery": ("Museum", "🎨"),
        "bakery": ("Bakery", "🍞"),
        "bar": ("Bar", "🍺"),
        "brewery": ("Bar", "🍺"),
        "bus station": ("Public Transport", "🚉"),
        "cafe": ("Coffee shop", "☕"),
        "department store": ("Retail", "🛍"),
        "fitness center": ("Gym", "🏋️"),
        "food market": ("Groceries", "🍎"),
        "grocery store": ("Groceries", "🍎"),
        "gym": ("Gym", "🏋️"),
        "hotel": ("Hotel", "🏨"),
        "library": ("Library", "📚"),
        "movie theater": ("Theater", "🎭"),
        "museum": ("Museum", "🎨"),
        "national park": ("National Park", "🏞"),
        "night club": ("Bar", "🍺"),
        "nightlife": ("Bar", "🍺"),
        "park": ("Park", "🌳"),
        "restaurant": ("Restaurant", "🍴"),
        "resort": ("Hotel", "🏨"),
        "stadium": ("Stadium", "🏟"),
        "supermarket": ("Groceries", "🍎"),
        "theater": ("Theater", "🎭"),
        "train station": ("Public Transport", "🚉"),
        "winery": ("Winery", "🍷"),
        "zoo": ("Zoo", "🦁"),
        // Custom/legacy values
        "mkpoicategorymusicvenue": ("Music Venue", "🎶"),
        "mkpoicategoryfood-market":("Groceries", "🍎")
    ]
    
    @Published var selectedAnnotation: MeepAnnotation? = nil
    // Using a comma-separated query for better compatibility.
    private let searchQuery = "restaurant"
    
    @Published var activeFilterCount: Int = 0
    @Published var searchRadius: Double = 0.2  // Default: lowest value (1/5 mile)
    @Published var departureTime: Date? = nil    // nil means "Now"
    
    // MARK: - Filtering & Floating Card
    @Published var selectedCategory: Category = Category(emoji: "", name: "All", hidden: false)
    @Published var selectedPoint: MeetingPoint? = nil
    @Published var isFloatingCardVisible: Bool = false
    @Published var sharableUserLocation: String = "My Location"
    @Published var sharableFriendLocation: String = "Friend's Location"
    
    // MARK: - Location Properties
    private var locationManager: CLLocationManager?
    @Published var isLocationAccessGranted: Bool = false
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var friendLocation: CLLocationCoordinate2D?
    @Published var meetingPoint: CLLocationCoordinate2D?
    @Published var userTransportMode: TransportMode = .train
    @Published var friendTransportMode: TransportMode = .train
    @Published var isUserInteractingWithMap = false
    @Published var isCalculatingMidpoint: Bool = false
    
    // MARK: - Annotations
    @Published var sampleAnnotations: [MeepAnnotation] = []
    @Published var searchResults: [MeepAnnotation] = []

    // MARK: - Loading State for Nearby Places
    @Published var isLoadingNearbyPlaces: Bool = false
    
    // MARK: - Google Directions Integration
    private var directionsService: GoogleDirectionsService {
        return GoogleDirectionsService()
    }
    
    
    let budgetManager = GoogleAPIBudgetManager.shared
    
    // Cache for Google-optimized midpoint
    @Published private var cachedGoogleMidpoint: CLLocationCoordinate2D?
    
    // MARK: - Toast Management for Transit Fallback
    @Published var showTransitFallbackToast = false
    @Published var currentToast: TransitFallbackToast?
    private var toastDismissTimer: Timer?
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    
    private func safeInt(_ value: Double) -> Int {
        return value.isFinite ? Int(value) : 0
    }
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        setupGoogleDirectionsIntegration()
    }
    
    // MARK: - 📌 Annotations & Search
    
    var annotations: [MeepAnnotation] {
        var results: [MeepAnnotation] = []
        
        if userLocation != nil && friendLocation != nil {
            let midpoint = enhancedMidpoint
            if !results.contains(where: { $0.coordinate.latitude == midpoint.latitude && $0.coordinate.longitude == midpoint.longitude }) {
                results.append(MeepAnnotation(coordinate: midpoint, title: midpointTitle, type: .midpoint))
            }
        }
        
        if let uLoc = userLocation {
            results.append(MeepAnnotation(coordinate: uLoc, title: "You", type: .user))
        }
        if let fLoc = friendLocation {
            results.append(MeepAnnotation(coordinate: fLoc, title: "Friend", type: .friend))
        }
        
        results.append(contentsOf: searchResults.filter {
            selectedCategory.name == "All" || getCategory(for: $0.type.emoji) == selectedCategory.name
        })
        return results
    }
    
    // MARK: - 🎯 Enhanced Midpoint Calculation with Google Directions
    
    /// Enhanced midpoint calculation using Google Directions transit data
    var enhancedMidpoint: CLLocationCoordinate2D {
        guard let userLoc = userLocation, let friendLoc = friendLocation else {
            return CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855) // Default to Times Square
        }

        // If we have a cached Google-optimized midpoint, use it
        if let cachedMidpoint = cachedGoogleMidpoint {
            return cachedMidpoint
        }

        // If either participant is using transit, avoid bouncing to geographic midpoint;
        // keep the current map center until optimization completes
        if userTransportMode == .train || friendTransportMode == .train {
            return mapRegion.center
        }

        // Otherwise, fallback to geographic midpoint for non-transit modes
        return calculateGeographicMidpoint(userLoc, friendLoc)
    }
    
    
    
    /// Skip authentication and enter the app in demo mode
    func skipAuthAndEnterDemo() {
        let demoUser = MeepUser(
            id: "demo",
            displayName: "Demo User",
            username: "demo",
            profileImageUrl: "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Logo-CTSh56ETSnD9ussJzfSa5Vm8JHsceV.png" // Optional image
        )

        DispatchQueue.main.async {
            FirebaseService.shared.meepUser = demoUser
            self.userLocation = CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855) // Times Square
            self.friendLocation = CLLocationCoordinate2D(latitude: 40.730610, longitude: -73.935242) // Brooklyn
            self.cachedGoogleMidpoint = self.calculateGeographicMidpoint(self.userLocation!, self.friendLocation!)
            self.searchNearbyPlaces()
        }
    }
    
    func resetMidpoint() {
        self.cachedGoogleMidpoint = nil
        self.meetingPoint = enhancedMidpoint
        self.searchNearbyPlaces()
    }
    
    /// Calculate Google-optimized midpoint in background
    func calculateGoogleOptimizedMidpoint() {
        guard let userLoc = userLocation, let friendLoc = friendLocation else { return }
        
        Task {
            if let subwayManager = subwayManager {
                let optimizedMidpoint = await getGoogleOptimizedMidpoint(
                    userLocation: userLoc,
                    friendLocation: friendLoc
                )
                
                DispatchQueue.main.async { [weak self] in
                    self?.cachedGoogleMidpoint = optimizedMidpoint
                    self?.centerMapOnMidpoint()
                    self?.searchNearbyPlaces()
                }
            }
        }
    }
    
    /// Helper to calculate geographic midpoint (used as fallback)
    private func calculateGeographicMidpoint(_ point1: CLLocationCoordinate2D, _ point2: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat1 = point1.latitude * .pi / 180
        let lon1 = point1.longitude * .pi / 180
        let lat2 = point2.latitude * .pi / 180
        let lon2 = point2.longitude * .pi / 180
        
        let Bx = cos(lat2) * cos(lon2 - lon1)
        let By = cos(lat2) * sin(lon2 - lon1)
        let midLat = atan2(sin(lat1) + sin(lat2),
                           sqrt((cos(lat1) + Bx) * (cos(lat1) + Bx) + By * By))
        let midLon = lon1 + atan2(By, cos(lat1) + Bx)
        
        return CLLocationCoordinate2D(
            latitude: midLat * 180 / .pi,
            longitude: midLon * 180 / .pi
        )
    }
    
    private func sortMeetingPointsByMidpoint() {
        let midLoc = CLLocation(latitude: enhancedMidpoint.latitude, longitude: enhancedMidpoint.longitude)
        meetingPoints.sort {
            let locA = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            let locB = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
            return locA.distance(from: midLoc) < locB.distance(from: midLoc)
        }
    }
    
    private func centerMapOnMidpoint() {
        guard !isUserInteractingWithMap else { return } // ✅ Prevent updates while user moves the map
        withAnimation {
            mapRegion = MKCoordinateRegion(
                center: enhancedMidpoint,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
    }
    
    // MARK: - Enhanced Optimal Meeting Point Calculation with Google Directions
    
    /// Enhanced optimal meeting point calculation with Google Directions
    private func calculateOptimalMeetingPointWithGoogle() {

        guard let userLoc = userLocation, let friendLoc = friendLocation else {
            print("❌ Missing one or both locations")
            return
        }

        let targetMidpoint = enhancedMidpoint

        Task {
            // Get Google Directions for both users
            async let userDirections = fetchGoogleTravelTime(
                from: userLoc,
                to: targetMidpoint,
                mode: userTransportMode,
                departureTime: departureTime
            )
            
            async let friendDirections = fetchGoogleTravelTime(
                from: friendLoc,
                to: targetMidpoint,
                mode: friendTransportMode,
                departureTime: departureTime
            )
            
            let (userResponse, friendResponse) = await (userDirections, friendDirections)
            
            // Process results
            await processGoogleDirectionsResults(
                userResponse: userResponse,
                friendResponse: friendResponse,
                userLoc: userLoc,
                friendLoc: friendLoc,
                targetMidpoint: targetMidpoint
            )
        }
    }
    
    
    
    private func analyzeGoogleTransitData(_ data: GoogleTransitAnalysis) -> (userViable: Bool, friendViable: Bool, reason: String, confidence: Double) {
        
        var userViable = true
        var friendViable = true
        var reasons: [String] = []
        var confidence = 0.95 // High confidence with Google data
        
        // User analysis
        if let userTransitRoute = data.userTransit.routes.first,
           let userWalkingRoute = data.userWalking.routes.first {
            
            let transitTime = userTransitRoute.duration.value
            let walkingTime = userWalkingRoute.duration.value
            
            // If walking is significantly faster, recommend against transit
            if walkingTime < transitTime * 0.75 {
                userViable = false
                reasons.append("Walking is \(safeInt((transitTime - walkingTime) / 60)) minutes faster for user")
            }
            
            // Check for excessive transfer requirements
            let transfers = RouteAnalyzer.countTransfers(in: userTransitRoute)
            if transfers >= 3 {
                userViable = false
                reasons.append("User route requires \(transfers) transfers")
            }
            
            // Check for excessive walking within transit route
            let walkingSteps = userTransitRoute.legs.flatMap { $0.steps.filter { $0.travelMode == "WALKING" } }
            let totalWalkingInTransit = walkingSteps.reduce(0) { $0 + $1.duration.value }
            
            if totalWalkingInTransit > walkingTime * 0.8 {
                userViable = false
                reasons.append("Transit route is mostly walking for user")
            }
            
        } else if data.userTransit.routes.isEmpty {
            userViable = false
            reasons.append("No transit routes available for user")
        } else {
            // No walking data available, reduce confidence
            confidence *= 0.8
        }
        
        // Friend analysis (same logic)
        if let friendTransitRoute = data.friendTransit.routes.first,
           let friendWalkingRoute = data.friendWalking.routes.first {
            
            let transitTime = friendTransitRoute.duration.value
            let walkingTime = friendWalkingRoute.duration.value
            
            if walkingTime < transitTime * 0.75 {
                friendViable = false
                reasons.append("Walking is \(safeInt((transitTime - walkingTime) / 60)) minutes faster for friend")
            }
            
            let transfers = RouteAnalyzer.countTransfers(in: friendTransitRoute)
            if transfers >= 3 {
                friendViable = false
                reasons.append("Friend route requires \(transfers) transfers")
            }
            
            let walkingSteps = friendTransitRoute.legs.flatMap { $0.steps.filter { $0.travelMode == "WALKING" } }
            let totalWalkingInTransit = walkingSteps.reduce(0) { $0 + $1.duration.value }
            
            if totalWalkingInTransit > walkingTime * 0.8 {
                friendViable = false
                reasons.append("Transit route is mostly walking for friend")
            }
            
        } else if data.friendTransit.routes.isEmpty {
            friendViable = false
            reasons.append("No transit routes available for friend")
        } else {
            confidence *= 0.8
        }
        
        let combinedReason = reasons.isEmpty ?
            "Transit is efficient based on Google Directions" :
            reasons.joined(separator: "; ")
        
        return (userViable, friendViable, combinedReason, confidence)
    }
    
    /// Enhanced travel time calculation using Google Directions
    private func fetchGoogleTravelTime(from origin: CLLocationCoordinate2D,
                                     to destination: CLLocationCoordinate2D,
                                     mode: TransportMode,
                                     departureTime: Date? = nil) async -> GoogleDirectionsResponse? {
        
        let googleMode: GoogleTransportMode
        switch mode {
        case .walk:
            googleMode = .walking
        case .car:
            googleMode = .driving
        case .bike:
            googleMode = .bicycling
        case .train:
            googleMode = .transit
        }
        
        let request = GoogleDirectionsRequest(
            origin: origin,
            destination: destination,
            mode: googleMode,
            departureTime: departureTime
        )
        
        do {
            let response = try await directionsService.getDirections(request)
            
            if response.status == "OK" && !response.routes.isEmpty {
                return response
            } else {
                print("⚠️ Google Directions API: \(response.status)")
                return nil
            }
        } catch {
            print("❌ Google Directions error: \(error)")
            return nil
        }
    }
    
    @MainActor
    private func processGoogleDirectionsResults(userResponse: GoogleDirectionsResponse?,
                                              friendResponse: GoogleDirectionsResponse?,
                                              userLoc: CLLocationCoordinate2D,
                                              friendLoc: CLLocationCoordinate2D,
                                              targetMidpoint: CLLocationCoordinate2D) {
        
        

        
        
        var userTime: TimeInterval = 900 // 15 min default
        var friendTime: TimeInterval = 900
        var hasGoogleData = false
        
        // Extract travel times from Google responses
        if let userRoute = userResponse?.routes.first {
            userTime = userRoute.duration.value
            hasGoogleData = true
            print("🗺️ Google user time: \(safeInt(userTime/60)) minutes via \(userTransportMode)")
            
            // Check for transit fallback suggestions
            if userTransportMode == .train {
                checkGoogleTransitFallback(response: userResponse!, isUser: true)
            }
        }
        
        if let friendRoute = friendResponse?.routes.first {
            friendTime = friendRoute.duration.value
            hasGoogleData = true
            print("🗺️ Google friend time: \(safeInt(friendTime/60)) minutes via \(friendTransportMode)")
            
            if friendTransportMode == .train {
                checkGoogleTransitFallback(response: friendResponse!, isUser: false)
            }
        }
        
        // If we have Google data, use it; otherwise fallback to Apple Maps
        if hasGoogleData {
            processTravelTimes(userTime: userTime, friendTime: friendTime, targetMidpoint: targetMidpoint)
        } else {
            print("⚠️ No Google Directions data, falling back to Apple Maps")
            fallbackToAppleMapsCalculation(userLoc: userLoc, friendLoc: friendLoc, targetMidpoint: targetMidpoint)
        }
    }
    
    /// Check if Google suggests transit fallback and show appropriate toast
    private func checkGoogleTransitFallback(response: GoogleDirectionsResponse, isUser: Bool) {
        guard let route = response.routes.first else { return }
        
        var hasSubwaySteps = false
        var totalWalkingTime: TimeInterval = 0
        var transitSteps: [GoogleStep] = []
        
        // Analyze the route steps
        for leg in route.legs {
            for step in leg.steps {
                if step.travelMode == "TRANSIT" {
                    if let transitDetails = step.transitDetails {
                        // Check if it's subway (vs bus)
                        if transitDetails.line.vehicle.type == "SUBWAY" {
                            hasSubwaySteps = true
                            transitSteps.append(step)
                        }
                    }
                } else if step.travelMode == "WALKING" {
                    totalWalkingTime += step.duration.value
                }
            }
        }
        
        // If Google suggests mostly walking or no subway, consider fallback
        let totalTime = route.duration.value
        let walkingPercentage = totalTime > 0 ? totalWalkingTime / totalTime : 0
        
        if !hasSubwaySteps && walkingPercentage > 0.95 {
            let reason = !hasSubwaySteps ?
                "No subway routes found - Google suggests walking/bus" :
                "Route is mostly walking (\(safeInt(walkingPercentage * 100))%)"
            
            showGoogleBasedFallbackToast(reason: reason, isUser: isUser)
        }
    }
    
    /// Show fallback toast based on Google Directions analysis
    private func showGoogleBasedFallbackToast(reason: String, isUser: Bool) {
        let userType = isUser ? "your" : "friend's"
        let fullReason = "Google suggests alternatives for \(userType) location: \(reason)"

        // Haptic feedback before showing toast
        // let generator = UINotificationFeedbackGenerator()
        // generator.notificationOccurred(.warning)
        print("⚠️ Toast triggered due to Google suggestion: \(fullReason)")

        currentToast = TransitFallbackToast.create(for: fullReason)
        showTransitFallbackToast = true

        // Auto-dismiss after 6 seconds
        toastDismissTimer?.invalidate()
        toastDismissTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { _ in
            DispatchQueue.main.async { [weak self] in
                withAnimation(.easeOut(duration: 0.3)) {
                    self?.showTransitFallbackToast = false
                    self?.currentToast = nil
                }
            }
        }

        // 👇 Auto-suggestion for fallback transport is muted for now
        // if reason.contains("mostly walking") {
        //     if isUser {
        //         userTransportMode = .walk
        //     } else {
        //         friendTransportMode = .walk
        //     }
        // }
    }
    
    /// Process travel times and determine optimal meeting point
    private func processTravelTimes(userTime: TimeInterval, friendTime: TimeInterval, targetMidpoint: CLLocationCoordinate2D) {
        
        // If times are reasonably balanced (within 10 minutes), use the target midpoint
        let timeDifference = abs(userTime - friendTime)
        
        if timeDifference <= 600 { // 10 minutes
            self.meetingPoint = targetMidpoint
            print("✅ Balanced travel times - using target midpoint")
        } else {
            // Times are unbalanced, try to find a better midpoint
            print("⚖️ Unbalanced times: User \(Int(userTime/60))m, Friend \(Int(friendTime/60))m")
            optimizeMidpointForBalance(userTime: userTime, friendTime: friendTime, currentMidpoint: targetMidpoint)
        }
        
        // Trigger place search at the final midpoint
        searchNearbyPlaces()
    }
    
    /// Optimize midpoint to balance travel times
    private func optimizeMidpointForBalance(userTime: TimeInterval, friendTime: TimeInterval, currentMidpoint: CLLocationCoordinate2D) {
        guard let userLoc = userLocation, let friendLoc = friendLocation else { return }
        
        // Calculate weighted midpoint based on travel time difference
        let totalTime = userTime + friendTime
        let userWeight = friendTime / totalTime  // If friend takes longer, move closer to user
        let friendWeight = userTime / totalTime
        
        let balancedMidpoint = CLLocationCoordinate2D(
            latitude: userLoc.latitude * userWeight + friendLoc.latitude * friendWeight,
            longitude: userLoc.longitude * userWeight + friendLoc.longitude * friendWeight
        )
        
        print("🎯 Calculated balanced midpoint: \(balancedMidpoint)")
        self.meetingPoint = balancedMidpoint
        
        // Update map region to show the new midpoint
        withAnimation {
            mapRegion = MKCoordinateRegion(
                center: balancedMidpoint,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
    }
    
    /// Fallback to Apple Maps calculation if Google fails
    private func fallbackToAppleMapsCalculation(userLoc: CLLocationCoordinate2D, friendLoc: CLLocationCoordinate2D, targetMidpoint: CLLocationCoordinate2D) {
        
        fetchTravelTime(from: userLoc, to: targetMidpoint, mode: userTransportMode, departureTime: departureTime) { [weak self] userTime in
            guard let self = self else { return }
            
            self.fetchTravelTime(from: friendLoc, to: targetMidpoint, mode: self.friendTransportMode, departureTime: self.departureTime) { friendTime in
                DispatchQueue.main.async {
                    self.processTravelTimes(userTime: userTime, friendTime: friendTime, targetMidpoint: targetMidpoint)
                }
            }
        }
    }
    
    
    
    // MARK: - Enhanced Transport Mode Management
    
    func setUserTransportMode(_ mode: TransportMode) {
        let oldMode = userTransportMode
        userTransportMode = mode
        
        if oldMode != mode {
            print("🔄 User transport mode changed: \(oldMode) → \(mode)")
            
            // Clear cached midpoint when transport mode changes
            cachedGoogleMidpoint = nil
            
            // Recalculate everything with Google Directions
            if userLocation != nil && friendLocation != nil {
                calculateGoogleOptimizedMidpoint()
                checkSubwayViabilityWithGoogle()
                calculateOptimalMeetingPointWithGoogle()
            }
        }
    }
    
    func setFriendTransportMode(_ mode: TransportMode) {
        let oldMode = friendTransportMode
        friendTransportMode = mode
        
        if oldMode != mode {
            print("🔄 Friend transport mode changed: \(oldMode) → \(mode)")
            
            // Clear cached midpoint when transport mode changes
            cachedGoogleMidpoint = nil
            
            // Recalculate everything with Google Directions
            if userLocation != nil && friendLocation != nil {
                calculateGoogleOptimizedMidpoint()
                checkSubwayViabilityWithGoogle()
                calculateOptimalMeetingPointWithGoogle()
            }
        }
    }
    
    // MARK: - Enhanced Subway Integration
    
    private func adjustMidpointForSubway(from coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard let subwayManager = subwayManager,
              let nearestStation = subwayManager.findNearestStation(to: coordinate, maxDistance: 0.01) else {
            return coordinate
        }
        
        let adjustedLat = coordinate.latitude * 0.7 + nearestStation.coordinate.latitude * 0.3
        let adjustedLon = coordinate.longitude * 0.7 + nearestStation.coordinate.longitude * 0.3
        
        return CLLocationCoordinate2D(latitude: adjustedLat, longitude: adjustedLon)
    }
    
    func getSubwayLinesNear(coordinate: CLLocationCoordinate2D, radius: Double = 0.005) -> [String] {
        guard let manager = subwayManager else { return [] }
        return manager.getLinesNear(coordinate: coordinate, radius: radius)
    }
    
    var midpointTitle: String {
        if userTransportMode == .train || friendTransportMode == .train {
            let lines = getSubwayLinesNear(coordinate: enhancedMidpoint)
            print("🚇 DEBUG: Found \(lines.count) subway lines: \(lines)")
            if !lines.isEmpty {
                return "Midpoint • Lines: \(lines.joined(separator: ", "))"
            } else {
                return "Midpoint"
            }
        }
        return "Midpoint"
    }
    
    /// Enhanced subway viability check with Google Directions
    func checkSubwayViabilityWithGoogle() {
        guard let userLoc = userLocation, let friendLoc = friendLocation else { return }
        guard let subwayManager = subwayManager else { return }

        // Only check if someone wants to use subway
        guard userTransportMode == .train || friendTransportMode == .train else { return }

        Task {
            // Check both users' subway viability with Google
            var userViable = true
            var friendViable = true
            var reasons: [String] = []

            if userTransportMode == .train {
                let (viable, reason, _, _) = await shouldUseSubwayWithGoogleDirections(
                    from: userLoc,
                    to: enhancedMidpoint
                )
                userViable = viable
                if !viable {
                    reasons.append("User: \(reason)")
                }
            }

            if friendTransportMode == .train {
                let (viable, reason, _, _) = await shouldUseSubwayWithGoogleDirections(
                    from: friendLoc,
                    to: enhancedMidpoint
                )
                friendViable = viable
                if !viable {
                    reasons.append("Friend: \(reason)")
                }
            }

            DispatchQueue.main.async { [weak self] in
                // Don't automatically switch transport modes based solely on fallback toast.
                // Instead, just show the toast and preserve subway validity for user/friend.
                let combinedReason = reasons.joined(separator: "; ")
                if !userViable || !friendViable {
                    self?.showGoogleBasedFallbackToast(reason: combinedReason, isUser: !userViable)
                }
                // Optionally, you may want to recalculate meeting point if needed, but do not forcibly change modes.
                // If you want to allow fallback, guard it behind explicit user action or additional checks.
            }

            // Invoke the more comprehensive analysis if available
            let basicAnalysis = (userViable, friendViable, reasons.joined(separator: "; "))
            Task {
                let fullAnalysis = await self.analyzeSubwayViabilityWithGoogle(
                    userLocation: userLoc,
                    friendLocation: friendLoc,
                    midpoint: enhancedMidpoint,
                    basicAnalysis: basicAnalysis
                )
                print("🚇 Full subway viability analysis:", fullAnalysis)
            }
        }
    }
    
    func debugSubwayConnection() {
        print("🚇 DEBUG Subway Connection:")
        print("   - Subway manager exists: \(subwayManager != nil)")
        print("   - Has loaded data: \(subwayManager?.hasLoadedData ?? false)")
        print("   - User transport: \(userTransportMode)")
        print("   - Friend transport: \(friendTransportMode)")
        print("   - Midpoint: \(enhancedMidpoint)")
        
        if let manager = subwayManager {
            let lines = manager.getLinesNear(coordinate: enhancedMidpoint, radius: 0.005)
            print("   - Lines near midpoint: \(lines)")
            
            let nearestStation = manager.findNearestStation(to: enhancedMidpoint, maxDistance: 0.01)
            print("   - Nearest station: \(nearestStation?.lineName ?? "none")")
        }
    }
    
    // MARK: - 📌 Search Nearby Places (Apple Maps + Google Places)
    
    func searchNearbyPlaces() {
        guard userLocation != nil && friendLocation != nil else {
            print("⚠️ Skipping search — both user and friend locations are not available.")
            return
        }
        
        // Instrument time to first midpoint calculation
        if firstCalculationTimestamp == nil {
            let delta = Date().timeIntervalSince1970 - firstLaunchTimestamp
            PostHogSDK.shared.capture("time_to_first_midpoint", properties: ["seconds": delta])
            firstCalculationTimestamp = Date().timeIntervalSince1970
        }
        
        PostHogSDK.shared.capture("midpoint_calculated", properties: [
            "user_transport": userTransportMode.rawValue,
            "friend_transport": friendTransportMode.rawValue,
            "search_radius": searchRadius,
            "has_departure_time": departureTime != nil,
            "user_location": sharableUserLocation,
            "friend_location": sharableFriendLocation
        ])
        self.isLoadingNearbyPlaces = true

        // Use more reasonable search radius (1 miles max)
        let adjustedSearchRadius = min(searchRadius, 1.0)
        let delta = adjustedSearchRadius * 0.0145

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.region = MKCoordinateRegion(
            center: enhancedMidpoint,
            span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        )

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }

            if let error = error {
                print("Apple Maps search error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingNearbyPlaces = false
                }
                return
            }

            guard let response = response else {
                print("No places found.")
                DispatchQueue.main.async {
                    self.isLoadingNearbyPlaces = false
                }
                return
            }

            let fetchedMeetingPoints = response.mapItems.compactMap { self.convert(mapItem: $0) }
            let sortedPoints = fetchedMeetingPoints.sorted {
                let locA = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
                let locB = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
                let midLoc = CLLocation(latitude: self.enhancedMidpoint.latitude, longitude: self.enhancedMidpoint.longitude)
                return locA.distance(from: midLoc) < locB.distance(from: midLoc)
            }

            DispatchQueue.main.async {
                self.meetingPoints = sortedPoints
                self.searchResults = sortedPoints.map {
                    MeepAnnotation(coordinate: $0.coordinate, title: $0.name, type: .place(emoji: $0.emoji))
                }
                self.updateCategoriesFromSearchResults()
                self.fetchPhotosForTopFive()
                self.isLoadingNearbyPlaces = false
            }
        }
    }

    /// Search nearby places using selectedCategory for category-specific filtering.
    func searchNearbyPlacesFiltered() {
        guard userLocation != nil && friendLocation != nil else {
            print("⚠️ Skipping filtered search — both user and friend locations are not available.")
            return
        }

        self.isLoadingNearbyPlaces = true

        let adjustedSearchRadius = min(searchRadius, 1.0)
        let delta = adjustedSearchRadius * 0.0145

        let query = selectedCategory.name == "All" ? searchQuery : selectedCategory.name

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: enhancedMidpoint,
            span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        )

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }

            if let error = error {
                print("Apple Maps filtered search error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingNearbyPlaces = false
                }
                return
            }

            guard let response = response else {
                print("No filtered places found.")
                DispatchQueue.main.async {
                    self.isLoadingNearbyPlaces = false
                }
                return
            }

            let fetchedMeetingPoints = response.mapItems.compactMap { self.convert(mapItem: $0) }
            let sortedPoints = fetchedMeetingPoints.sorted {
                let locA = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
                let locB = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
                let midLoc = CLLocation(latitude: self.enhancedMidpoint.latitude, longitude: self.enhancedMidpoint.longitude)
                return locA.distance(from: midLoc) < locB.distance(from: midLoc)
            }

            DispatchQueue.main.async {
                self.meetingPoints = sortedPoints
                self.searchResults = sortedPoints.map {
                    MeepAnnotation(coordinate: $0.coordinate, title: $0.name, type: .place(emoji: $0.emoji))
                }
                self.updateCategoriesFromSearchResults()
                self.fetchPhotosForTopFive()
                self.isLoadingNearbyPlaces = false
            }
        }
    }
    
    // MARK: - Category Management
    
    /// Returns the category name for a given emoji.
    func getCategory(for emoji: String) -> String {
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // First check our known categories
        if let category = (categories + hiddenCategories).first(where: { $0.emoji == trimmedEmoji }) {
            return category.name
        }
        
        // If not found in our categories, search the category mapping
        for (_, mapping) in categoryMapping where mapping.emoji == trimmedEmoji {
            return mapping.category
        }
        
        // If still not found, check if this is a system-provided place type
        // This handles cases where we get places from Apple Maps with types we haven't mapped
        if let originalPlaceType = getOriginalPlaceType(for: trimmedEmoji) {
            return "📍 \(originalPlaceType.capitalized)"  // Return with prefix to indicate it's unmapped
        }
        
        // Complete fallback
        return "📍 Unknown"
    }

    // Helper method to track original place types
    private func getOriginalPlaceType(for emoji: String) -> String? {
        // Look through the meeting points for matching emoji and original place type
        for meetingPoint in meetingPoints where meetingPoint.emoji == emoji && meetingPoint.originalPlaceType != nil {
            return meetingPoint.originalPlaceType
        }
        
        return nil
    }
    
    func recordUnknownPlaceType(emoji: String, placeType: String) {
        // Save this mapping for future reference
        print("⚠️ Recorded unknown place type: \(placeType) with emoji: \(emoji)")
        
        // Here you could add to a persistent store or a dictionary
        // that tracks these for later classification
        
        // You might also want to add this to hiddenCategories automatically
        if !hiddenCategories.contains(where: { $0.emoji == emoji }) &&
           !categories.contains(where: { $0.emoji == emoji }) {
            
            DispatchQueue.main.async { [weak self] in
                self?.hiddenCategories.append(Category(
                    emoji: emoji,
                    name: placeType.capitalized,
                    hidden: true
                ))
            }
        }
    }
    
    // MARK: – 🔢 Fetch Google Photos for Only Top N Results
    private func fetchPhotosForTopFive() {
        let placesClient = GMSPlacesClient.shared()
        let firstBatch = self.meetingPoints.prefix(maxAutoPhotosPerSearch)
        for (index, place) in firstBatch.enumerated() {
            guard googlePhotoCallCount < googlePhotoDailyCap else {
                print("🚫 Google photo daily cap reached; skipping remaining auto‐loads.")
                return
            }
            googlePhotoCallCount += 1
            if let placeID = place.googlePlaceID {
                self.fetchPlaceDetails(placesClient, placeID: placeID, meetingPointIndex: index)
            } else {
                self.findNearbyPlace(placesClient, place: place, index: index)
            }
        }
    }
    
    // MARK: - 🔄 Convert Apple Maps Search Result to MeetingPoint
    
    private func convert(mapItem: MKMapItem) -> MeetingPoint? {
        guard let coordinate = mapItem.placemark.location?.coordinate else {
            return nil
        }
        
        // Get the original place type from the item
        var originalPlaceType = "unknown"
        if let poiCategory = mapItem.pointOfInterestCategory?.rawValue {
            originalPlaceType = poiCategory.lowercased()
        }
        
        // Default emoji and category
        var emoji = "📍"
        var category = originalPlaceType.capitalized
        
        // Try to match with our category mapping
        if let mapping = categoryMapping[originalPlaceType] {
            emoji = mapping.emoji
            category = mapping.category
        } else {
            // If no direct match, try partial matching for more flexibility
            for (key, value) in categoryMapping {
                if originalPlaceType.contains(key) {
                    emoji = value.emoji
                    category = value.category
                    print("✅ Partial category match: \(originalPlaceType) contains \(key) -> \(category) \(emoji)")
                    break
                }
            }
            
            // If we're still using the default emoji, record this unknown place type
            if emoji == "📍" {
                print("⚠️ Unknown category: \(originalPlaceType)")
                recordUnknownPlaceType(emoji: emoji, placeType: originalPlaceType)
            }
        }
        
        return MeetingPoint(
            name: mapItem.name ?? "Unknown Place",
            emoji: emoji,
            category: category,
            coordinate: coordinate,
            imageUrl: "",  // Will be updated with Google Places photo
            googlePlaceID: nil,
            originalPlaceType: originalPlaceType
        )
    }
    
    // Add a function to update and sync categories from search results
    func updateCategoriesFromSearchResults() {
        // Get all unique categories from meeting points
        let uniqueCategories = Set(meetingPoints.map { $0.category })
        
        // For each unique category, ensure it exists in our category lists
        for category in uniqueCategories {
            // Skip if it's unknown
            if category.lowercased() == "unknown" {
                continue
            }
            
            // Check if exists in visible categories
            let existsInVisible = categories.contains(where: { $0.name.lowercased() == category.lowercased() })
            
            // Check if exists in hidden categories
            let existsInHidden = hiddenCategories.contains(where: { $0.name.lowercased() == category.lowercased() })
            
            // If it doesn't exist in either list, add it to hidden categories
            if !existsInVisible && !existsInHidden {
                // Find matching emoji from category mapping
                var emoji = "📍"
                for (_, mapping) in categoryMapping {
                    if mapping.category.lowercased() == category.lowercased() {
                        emoji = mapping.emoji
                        break
                    }
                }
                
                hiddenCategories.append(Category(emoji: emoji, name: category, hidden: true))
            }
        }
    }
    
    // MARK: - Apple Maps Travel Time (Fallback)
    
    private func fetchTravelTime(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        mode: TransportMode,
        departureTime: Date? = nil,
        completion: @escaping (TimeInterval) -> Void
    ) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))

        switch mode {
        case .walk:
            request.transportType = .walking
        case .car:
            request.transportType = .automobile
        case .bike:
            request.transportType = .walking // Approximate cycling with walking time
            request.requestsAlternateRoutes = true
        case .train:
            request.transportType = .transit
            if let depTime = departureTime {
                request.departureDate = depTime
            }
        }

        MKDirections(request: request).calculate { response, error in
            if let travelTime = response?.routes.first?.expectedTravelTime, error == nil {
                let adjustedTravelTime = mode == .bike ? travelTime / 3 : travelTime
                completion(adjustedTravelTime)
            } else if mode == .train {
                print("❌ Apple Transit failed, falling back to Google")

                self.directionsService.getTransitTime(
                    from: origin,
                    to: destination
                ) { googleTime in
                    if let googleTime = googleTime {
                        DispatchQueue.main.async {
                            self.showTransitFallbackToast = true
                            completion(googleTime)
                        }
                    } else {
                        print("❌ Google Transit also failed, falling back to walk")
                        self.showTransitFallbackToast = true
                        self.fetchTravelTime(from: origin, to: destination, mode: .walk, completion: completion)
                    }
                }
            } else {
                completion(15 * 60) // default fallback: 15 minutes
            }
        }
    }

    // MARK: - 📍 Update Active FilterCount
    func updateActiveFilterCount(myTransit: TransportMode, friendTransit: TransportMode, searchRadius: Double, departureTime: Date?) {
        var count = 0

        if myTransit != .train { count += 1 } // Example: Default is `train`, so any change counts as a filter
        if friendTransit != .train { count += 1 }
        if searchRadius != 0.2 { count += 1 } // Default search radius is 0.2 miles
        if departureTime != nil { count += 1 }

        activeFilterCount = count
    }
    
    // MARK: - Location Manager Delegate (Enhanced)
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationAccessGranted = true
        case .denied:
            isLocationAccessGranted = false
        default:
            isLocationAccessGranted = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else {
            print("didUpdateLocations: No locations found.")
            return
        }

        let newCoordinate = loc.coordinate
        let oldCoordinate = userLocation

        // Check if location changed significantly (more than 100 meters)
        let significantChange: Bool
        if let oldLoc = oldCoordinate {
            let distance = CLLocation(latitude: oldLoc.latitude, longitude: oldLoc.longitude)
                .distance(from: loc)
            significantChange = distance > 100
        } else {
            significantChange = true
        }

        print("Location updated: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
        // Haptic warning if outside NYC
        if !isWithinNYC(newCoordinate) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
        DispatchQueue.main.async { [weak self] in
            self?.userLocation = newCoordinate

            if significantChange {
                self?.mapRegion = MKCoordinateRegion(
                    center: newCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )

                // Clear cached Google midpoint on significant location change
                self?.cachedGoogleMidpoint = nil

                // Trigger Google-based recalculation
                if self?.friendLocation != nil {
                    self?.calculateGoogleOptimizedMidpoint()
                    self?.checkSubwayViabilityWithGoogle()
                }
            }
        }

        locationManager?.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    /// Requests permission and location if needed. Use this only for first-time requests.
    func requestUserLocation() {
        if locationManager?.authorizationStatus == .notDetermined {
            locationManager?.requestWhenInUseAuthorization()
        } else if locationManager?.authorizationStatus == .authorizedWhenInUse ||
                  locationManager?.authorizationStatus == .authorizedAlways {
            locationManager?.requestLocation()
        }
    }
    
    // MARK: - 📍 Reverse Geocoding
    
    func reverseGeocodeUserLocation() {
        guard let userCoord = userLocation else { return }
        let location = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first, error == nil {
                DispatchQueue.main.async {
                    self?.sharableUserLocation = placemark.name ?? "Unknown Location"
                }
            }
        }
    }

    func reverseGeocodeFriendLocation() {
        guard let friendCoord = friendLocation else { return }
        let location = CLLocation(latitude: friendCoord.latitude, longitude: friendCoord.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first, error == nil {
                DispatchQueue.main.async {
                    self?.sharableFriendLocation = placemark.name ?? "Unknown Location"
                }
            }
        }
    }

    func geocodeAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            completion(placemarks?.first?.location?.coordinate)
        }
    }
    
    var searchFieldsAreEmpty: Bool {
        userLocation == nil && friendLocation == nil
    }
    
    // MARK: - 📸 Google Places Photo Handling

    func fetchPhotoWithReference(photoReference: String, maxWidth: Int = 800, completion: @escaping (UIImage?) -> Void) {
        // Replace "YOUR_API_KEY" with your actual Google Places API key
        // This is typically passed in from your app configuration
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GooglePlacesAPIKey") as? String else {
            print("❌ Missing Google Places API Key")
            completion(nil)
            return
        }
        
        let urlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=\(maxWidth)&photoreference=\(photoReference)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Photo download error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            if let image = UIImage(data: data) {
                completion(image)
            } else {
                print("❌ Could not create image from data")
                completion(nil)
            }
        }.resume()
    }
    
    // Helper method to load photos directly from Google Places
    private func loadPhotoDirectly(_ placesClient: GMSPlacesClient, photo: GMSPlacePhotoMetadata, meetingPointIndex: Int) {
        placesClient.loadPlacePhoto(photo) { [weak self] (image, error) in
            guard let self = self, let image = image, error == nil else {
                print("⚠️ Error loading photo: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Convert UIImage to data and create a data URL for immediate display
            if let imageData = image.jpegData(compressionQuality: 0.7) {
                let base64String = imageData.base64EncodedString()
                
                DispatchQueue.main.async {
                    if meetingPointIndex < self.meetingPoints.count {
                        self.meetingPoints[meetingPointIndex].imageUrl = "data:image/jpeg;base64,\(base64String)"
                        print("✅ Loaded direct photo for \(self.meetingPoints[meetingPointIndex].name)")
                    }
                }
            }
        }
    }

    // Fallback method to search by text
    private func searchPlaceByText(_ placesClient: GMSPlacesClient, placeName: String, meetingPointIndex: Int) {
        // Create a filter with the place name as the query
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        
        // Use the Autocomplete API to search for the place by name
        placesClient.findAutocompletePredictions(
            fromQuery: placeName,
            filter: filter,
            sessionToken: nil
        ) { [weak self] (predictions, error) in
            guard let self = self, let predictions = predictions, !predictions.isEmpty, error == nil else {
                print("⚠️ No autocomplete results for: \(placeName)")
                return
            }
            
            // Get the place ID from the first prediction
            let placeID = predictions[0].placeID
            
            // Fetch the place details to get photos
            self.fetchPhotoForExistingPlaceID(placesClient, placeID: placeID, meetingPointIndex: meetingPointIndex)
        }
    }

    // Main function to load and update photos
    func loadAndUpdatePhoto(_ placesClient: GMSPlacesClient, photo: GMSPlacePhotoMetadata, meetingPointIndex: Int) {
        // Load the actual photo
        placesClient.loadPlacePhoto(photo) { [weak self] (image, error) in
            if let error = error {
                print("⚠️ Error loading photo: \(error.localizedDescription)")
                return
            }
            
            guard let self = self, let downloadedImage = image else {
                return
            }
            
            // Update on main thread with the downloaded image
            OperationQueue.main.addOperation {
                guard meetingPointIndex < self.meetingPoints.count else { return }
                
                // Convert the image to a data URL for immediate display
                if let imageData = downloadedImage.jpegData(compressionQuality: 0.7) {
                    let base64String = imageData.base64EncodedString()
                    let dataURL = "data:image/jpeg;base64,\(base64String)"
                    
                    // Update the image URL
                    self.meetingPoints[meetingPointIndex].imageUrl = dataURL
                    
                    print("✅ Updated with direct image for \(self.meetingPoints[meetingPointIndex].name)")
                }
            }
        }
    }

    // MARK: – 🔄 Overload for Single Photo Fetch (Floating Card)
    func fetchPlaceDetails(_ placesClient: GMSPlacesClient, placeID: String, meetingPointIndex: Int? = nil) {
        let fields: GMSPlaceField = [.name, .photos, .formattedAddress]
        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil) { [weak self] place, error in
            guard let self = self else { return }
            if let error = error {
                print("⚠️ Error fetching place details: \(error.localizedDescription)")
                return
            }
            guard let place = place else {
                print("⚠️ No place details found for ID: \(placeID)")
                return
            }
            if let idx = meetingPointIndex, idx < self.meetingPoints.count {
                if let photos = place.photos, !photos.isEmpty {
                    self.loadAndUpdatePhoto(placesClient, photo: photos[0], meetingPointIndex: idx)
                }
            } else {
                if let photos = place.photos, !photos.isEmpty {
                    placesClient.loadPlacePhoto(photos[0]) { image, error in
                        guard let uiImg = image, error == nil else {
                            print("⚠️ Could not load single photo for selectedPoint: \(error?.localizedDescription ?? "Unknown")")
                            return
                        }
                        if let imgData = uiImg.jpegData(compressionQuality: 0.7) {
                            let base64 = imgData.base64EncodedString()
                            DispatchQueue.main.async {
                                if let sel = self.selectedPoint {
                                    self.selectedPoint?.imageUrl = "data:image/jpeg;base64,\(base64)"
                                    print("✅ Fetched single‐photo for \(sel.name)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: – 🔄 Fetch Exactly One Photo on Demand
    func fetchSinglePhotoFor(point: MeetingPoint) {
        let placesClient = GMSPlacesClient.shared()
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        var searchQuery = point.name
        if point.category.lowercased() != "unknown" {
            searchQuery += " \(point.category)"
        }
        let midpointLoc = CLLocation(latitude: enhancedMidpoint.latitude, longitude: enhancedMidpoint.longitude)
        CLGeocoder().reverseGeocodeLocation(midpointLoc) { [weak self] placemarks, _ in
            guard let self = self else { return }
            var finalQuery = searchQuery
            if let city = placemarks?.first?.locality {
                finalQuery += " \(city)"
            }
            placesClient.findAutocompletePredictions(fromQuery: finalQuery, filter: filter, sessionToken: nil) { [weak self] predictions, error in
                guard let self = self else { return }
                if let error = error {
                    print("⚠️ Autocomplete failed for \(point.name): \(error.localizedDescription)")
                    return
                }
                guard let preds = predictions, !preds.isEmpty else {
                    print("⚠️ No autocomplete results for \(point.name)")
                    return
                }
                let placeID = preds[0].placeID
                self.fetchPlaceDetails(placesClient, placeID: placeID, meetingPointIndex: nil)
            }
        }
    }
    

    // Helper to find place and fetch its details
    func findNearbyPlace(_ placesClient: GMSPlacesClient, place: MeetingPoint, index: Int) {
        // Use text search for better matching
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        
        // Create a more specific search query with both name and category
        var searchQuery = place.name
        if place.category != "Unknown" && !place.category.starts(with: "📍") {
            searchQuery += " \(place.category)"
        }
        
        // Try to add location context if possible
        let midpointLoc = CLLocation(latitude: enhancedMidpoint.latitude, longitude: enhancedMidpoint.longitude)
        CLGeocoder().reverseGeocodeLocation(midpointLoc) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            var updatedQuery = searchQuery
            if let city = placemarks?.first?.locality {
                updatedQuery += " \(city)"
            }
            
            // Search for the place
            placesClient.findAutocompletePredictions(
                fromQuery: updatedQuery,
                filter: filter,
                sessionToken: nil
            ) { [weak self] (predictions, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("⚠️ Error finding place: \(error.localizedDescription)")
                    return
                }
                
                guard let predictions = predictions, !predictions.isEmpty else {
                    print("⚠️ No autocomplete results for: \(place.name)")
                    return
                }
                
                // Get place ID from the first prediction
                let placeID = predictions[0].placeID
                
                // Store the ID and fetch details
                OperationQueue.main.addOperation {
                    if index < self.meetingPoints.count {
                        self.meetingPoints[index].googlePlaceID = placeID
                    }
                    
                    // Fetch place details including photos
                    self.fetchPlaceDetails(placesClient, placeID: placeID, meetingPointIndex: index)
                }
            }
        }
    }

    // Main function to fetch metadata for all meeting points
    func fetchGooglePlacesMetadata(for places: [MeetingPoint]) {
        print("🔍 Fetching Google Places metadata for \(places.count) places")
        let placesClient = GMSPlacesClient.shared()
        
        // Process each meeting point
        for (index, place) in places.enumerated() {
            // If we already have a Google Place ID, use it directly
            if let placeID = place.googlePlaceID {
                fetchPlaceDetails(placesClient, placeID: placeID, meetingPointIndex: index)
            } else {
                // Otherwise search for the place first
                findNearbyPlace(placesClient, place: place, index: index)
            }
        }
    }

    // Helper method to fetch photo for an existing Google Place ID
    func fetchPhotoForExistingPlaceID(_ placesClient: GMSPlacesClient, placeID: String, meetingPointIndex: Int) {
        placesClient.fetchPlace(
            fromPlaceID: placeID,
            placeFields: .photos,
            sessionToken: nil
        ) { [weak self] (place, error) in
            guard let self = self, let place = place, error == nil,
                  let photos = place.photos, !photos.isEmpty else {
                print("⚠️ No photos found for place ID: \(placeID)")
                return
            }
            
            // Get the first photo
            self.loadAndUpdatePhoto(placesClient, photo: photos[0], meetingPointIndex: meetingPointIndex)
        }
    }

    // MARK: - Google Directions Integration Setup
    
    /// Setup Google Directions integration (call this in your view's onAppear)
    private func setupGoogleDirectionsIntegration() {
        // Add observers for location and transport mode changes
        Publishers.CombineLatest4($userLocation, $friendLocation, $userTransportMode, $friendTransportMode)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main) // Debounce rapid changes
            .sink { [weak self] userLoc, friendLoc, userMode, friendMode in
                guard let self = self else { return }
                
                if userLoc != nil && friendLoc != nil {
                    print("🔄 Location/transport change detected - triggering Google optimization")
                    
                    self.calculateGoogleOptimizedMidpoint()
                    self.checkSubwayViabilityWithGoogle()
                    
                    // Delay the main calculation to allow midpoint to be optimized first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.calculateOptimalMeetingPointWithGoogle()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    
    // MARK: - Google Integration Methods
    
    /// Calculate true transit-optimized midpoint
    private func calculateTrueTransitMidpoint() async {

        guard let userLoc = userLocation, let friendLoc = friendLocation else { return }
        
        // Only use transit optimization if someone wants to use transit
        guard userTransportMode == .train || friendTransportMode == .train else {
            // For non-transit modes, geographic midpoint is fine
            return
        }
        
        let calculator = TransitOptimizedMidpointCalculator()
        let transitMidpoint = await calculator.calculateTransitMidpoint(
            userLocation: userLoc,
            friendLocation: friendLoc
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.cachedGoogleMidpoint = transitMidpoint
            
            // Update the map to show the transit-optimized location
            withAnimation(.easeInOut(duration: 1.0)) {
                self?.mapRegion = MKCoordinateRegion(
                    center: transitMidpoint,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            }
            
            // Search for places near the true transit midpoint
            self?.searchNearbyPlaces()

        }
    }
    
    
    var realTransitMidpoint: CLLocationCoordinate2D {
           guard let userLoc = userLocation, let friendLoc = friendLocation else {
               return CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855)
           }
           
           // Get the base midpoint (either cached Google-optimized or geographic)
           let baseMidpoint: CLLocationCoordinate2D
           
           if let cachedMidpoint = cachedGoogleMidpoint {
               baseMidpoint = cachedMidpoint
           } else {
               // For transit modes, trigger background calculation
               if userTransportMode == .train || friendTransportMode == .train {
                   Task {
                       await calculateTrueTransitMidpoint()
                   }
               }
               // Use geographic midpoint while transit optimization runs
               baseMidpoint = calculateGeographicMidpoint(userLoc, friendLoc)
           }
           
           // Apply subway adjustment if someone is using transit
           if userTransportMode == .train || friendTransportMode == .train {
               return adjustMidpointForSubway(from: baseMidpoint)
           }
           
           return baseMidpoint
       }
    
    
    
    
    
    func analyzeSubwayViabilityWithGoogle(userLocation: CLLocationCoordinate2D,
                                        friendLocation: CLLocationCoordinate2D,
                                        midpoint: CLLocationCoordinate2D,
                                        basicAnalysis: (userViable: Bool, friendViable: Bool, reason: String)) async -> TransitAnalysisResult {
        
        // If geographic analysis already rules out subway, return early
        if !basicAnalysis.userViable || !basicAnalysis.friendViable {
            return TransitAnalysisResult(
                userViable: basicAnalysis.userViable,
                friendViable: basicAnalysis.friendViable,
                reason: basicAnalysis.reason,
                confidence: 0.9, // High confidence in geographic constraints
                googleData: nil
            )
        }
        
        // Get Google Directions for both users
        async let userTransitCheck = directionsService.getDirections(GoogleDirectionsRequest(
            origin: userLocation,
            destination: midpoint,
            mode: .transit,
            departureTime: Date().addingTimeInterval(300)
        ))
        
        async let friendTransitCheck = directionsService.getDirections(GoogleDirectionsRequest(
            origin: friendLocation,
            destination: midpoint,
            mode: .transit,
            departureTime: Date().addingTimeInterval(300)
        ))
        
        async let userWalkingCheck = directionsService.getDirections(GoogleDirectionsRequest(
            origin: userLocation,
            destination: midpoint,
            mode: .walking
        ))
        
        async let friendWalkingCheck = directionsService.getDirections(GoogleDirectionsRequest(
            origin: friendLocation,
            destination: midpoint,
            mode: .walking
        ))
        
        do {
            let (userTransit, friendTransit, userWalking, friendWalking) = try await (
                userTransitCheck, friendTransitCheck, userWalkingCheck, friendWalkingCheck
            )
            
            let googleData = GoogleTransitAnalysis(
                userTransit: userTransit,
                friendTransit: friendTransit,
                userWalking: userWalking,
                friendWalking: friendWalking
            )
            
            // Analyze the Google results
            let (userViable, friendViable, reason, confidence) = analyzeGoogleTransitData(googleData)
            
            return TransitAnalysisResult(
                userViable: userViable,
                friendViable: friendViable,
                reason: reason,
                confidence: confidence,
                googleData: googleData
            )
            
        } catch {
            print("❌ Google Directions analysis failed: \(error)")
            
            // Fallback to basic analysis with lower confidence
            return TransitAnalysisResult(
                userViable: basicAnalysis.userViable,
                friendViable: basicAnalysis.friendViable,
                reason: basicAnalysis.reason + " (Google verification failed)",
                confidence: 0.6,
                googleData: nil
            )
        }
    }
    
    func shouldUseSubwayWithGoogleDirections(from origin: CLLocationCoordinate2D,
                                           to destination: CLLocationCoordinate2D) async -> (viable: Bool, reason: String, transitTime: TimeInterval?, walkingTime: TimeInterval?) {
        
        do {
            // Get both transit and walking directions
            let transitRequest = GoogleDirectionsRequest(
                origin: origin,
                destination: destination,
                mode: .transit,
                departureTime: Date().addingTimeInterval(300)
            )
            
            let walkingRequest = GoogleDirectionsRequest(
                origin: origin,
                destination: destination,
                mode: .walking
            )
            
            async let transitDirections = directionsService.getDirections(transitRequest)
            async let walkingDirections = directionsService.getDirections(walkingRequest)
            
            let (transitResponse, walkingResponse) = try await (transitDirections, walkingDirections)
            
            let transitTime = transitResponse.routes.first?.duration.value
            let walkingTime = walkingResponse.routes.first?.duration.value
            
            // If walking is faster or transit time is unreasonable, recommend walking
            if let transitTime = transitTime,
               let walkingTime = walkingTime {
                
                if walkingTime <= transitTime * 0.8 {
                    return (false, "Walking is faster than transit", transitTime, walkingTime)
                }
                
                if transitTime > 45 * 60 { // More than 45 minutes
                    return (false, "Transit time too long", transitTime, walkingTime)
                }
                
                return (true, "Transit is efficient", transitTime, walkingTime)
            }
            
            return (false, "No transit routes available", nil, walkingTime)
            
        } catch {
            print("❌ Google Directions error: \(error)")
            return (false, "Unable to get directions", nil, nil)
        }
    }
    
    func getGoogleOptimizedMidpoint(userLocation: CLLocationCoordinate2D,
                                  friendLocation: CLLocationCoordinate2D) async -> CLLocationCoordinate2D {
        
        do {
            let optimizedMidpoint = try await directionsService.getTransitOptimizedMidpoint(
                userLocation: userLocation,
                friendLocation: friendLocation,
                searchRadius: 800 // 800 meter search radius
            )
            
            print("🎯 Google-optimized midpoint: \(optimizedMidpoint)")
            return optimizedMidpoint
            
        } catch {
            print("❌ Failed to get Google-optimized midpoint: \(error)")
            // Fallback to geographic midpoint
            return MidpointCalculator.calculateGeographicMidpoint(userLocation, friendLocation)
        }
    }
    
    /// Fetch photos with budget management
    private func fetchPhotosForTopFiveWithBudget() {
        let budgetManager = GoogleAPIBudgetManager.shared
        
        // Check if we should fetch photos
        guard budgetManager.shouldFetchPhotoFromGoogle() else {
            print("💡 Google Photos: Preserving budget, skipping photo fetches")
            return
        }
        
        let placesClient = GMSPlacesClient.shared()
        let maxPhotosToFetch = min(5, budgetManager.remainingRequests) // Don't exceed remaining budget
        let firstBatch = self.meetingPoints.prefix(maxPhotosToFetch)
        
        for (index, place) in firstBatch.enumerated() {
            if let placeID = place.googlePlaceID {
                self.fetchPlaceDetails(placesClient, placeID: placeID, meetingPointIndex: index)
                budgetManager.recordPhotoCall()
            } else {
                self.findNearbyPlace(placesClient, place: place, index: index)
                budgetManager.recordPhotoCall()
            }
        }
    }
    
    
    /// Enhanced midpoint calculation with budget management
    var smartEnhancedMidpoint: CLLocationCoordinate2D {
        guard let userLoc = userLocation, let friendLoc = friendLocation else {
            return CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855)
        }
        
        // Use cached Google-optimized midpoint if available
        if let cachedMidpoint = cachedGoogleMidpoint {
            return cachedMidpoint
        }
        
        // Check budget before making Google calls
        let budgetManager = GoogleAPIBudgetManager.shared
        if budgetManager.shouldUseGoogleForMidpoint(userLocation: userLoc, friendLocation: friendLoc) {
            // Trigger Google optimization in background
            Task {
                await calculateGoogleOptimizedMidpointWithBudget()
            }
        } else {
            print("💡 Using geographic midpoint to preserve Google API budget")
        }
        
        // Return geographic midpoint while Google optimization runs
        return calculateGeographicMidpoint(userLoc, friendLoc)
    }
    
    /// Google-optimized midpoint calculation with budget management
    private func calculateGoogleOptimizedMidpointWithBudget() async {
        guard let userLoc = userLocation, let friendLoc = friendLocation else { return }
        
        if let subwayManager = subwayManager {
            do {
                let directionsService = GoogleDirectionsService()
                let optimizedMidpoint = try await directionsService.getTransitOptimizedMidpointWithBudget(
                    userLocation: userLoc,
                    friendLocation: friendLoc
                )
                
                DispatchQueue.main.async { [weak self] in
                    self?.cachedGoogleMidpoint = optimizedMidpoint
                    self?.centerMapOnMidpoint()
                    self?.searchNearbyPlaces()
                }
            } catch {
                print("❌ Google-optimized midpoint failed: \(error)")
                // Continue with geographic midpoint - no need to update since that's what we're already using
            }
        }
    }
    
    /// Enhanced Google Directions calculation with budget management
    private func fetchGoogleTravelTimeWithBudget(from origin: CLLocationCoordinate2D,
                                                to destination: CLLocationCoordinate2D,
                                                mode: TransportMode,
                                                departureTime: Date? = nil) async -> GoogleDirectionsResponse? {
        
        let budgetManager = GoogleAPIBudgetManager.shared
        
        // For transit analysis, be a bit more lenient
        guard budgetManager.shouldUseGoogleForTransitAnalysis() else {
            print("💡 Google Directions: Preserving budget, skipping call")
            return nil
        }
        
        let googleMode: GoogleTransportMode
        switch mode {
        case .walk: googleMode = .walking
        case .car: googleMode = .driving
        case .bike: googleMode = .bicycling
        case .train: googleMode = .transit
        }
        
        let request = GoogleDirectionsRequest(
            origin: origin,
            destination: destination,
            mode: googleMode,
            departureTime: departureTime
        )
        
        do {
            let directionsService = GoogleDirectionsService()
            return try await directionsService.getDirectionsWithBudget(request)
        } catch {
            print("❌ Google Directions error: \(error)")
            return nil
        }
    }
    
// MARK: - Location Permission Utilities

/// This should ONLY get location if permission already granted
func getCurrentLocationIfAuthorized() {
    guard locationManager?.authorizationStatus == .authorizedWhenInUse ||
          locationManager?.authorizationStatus == .authorizedAlways else {
        return // Don't request, just return
    }
    locationManager?.requestLocation()
    // MARK: - NYC Geofencing

    /// Handles out-of-NYC behavior: switches to car mode and shows a beta warning toast.
    func handleOutOfNYCBehavior(userLoc: CLLocationCoordinate2D?, friendLoc: CLLocationCoordinate2D?) {
        guard let userLoc = userLoc, let friendLoc = friendLoc else { return }

        if !isWithinNYC(userLoc) || !isWithinNYC(friendLoc) {
            print("⚠️ Outside NYC - switching to car and showing beta warning")
//            userTransportMode = .car
//            friendTransportMode = .car

            currentToast = TransitFallbackToast(
                icon: "car.fill",
                title: "Beta only works in NYC",
                message: "Try at your own risk",
                primaryColor: .red,
                secondaryColor: .red.opacity(0.8)
            )
            showTransitFallbackToast = true

            toastDismissTimer?.invalidate()
            toastDismissTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    self.showTransitFallbackToast = false
                    self.currentToast = nil
                }
            }
        } else if realTransitMidpoint.latitude != 0 {
            registerGeofence(at: realTransitMidpoint, identifier: "midpoint")
        }
    }
}

    /// Handles behavior when the user or friend is outside NYC
    @MainActor
    func handleOutOfNYCBehavior(userLoc: CLLocationCoordinate2D?, friendLoc: CLLocationCoordinate2D?) {
        guard let userLoc = userLoc, let friendLoc = friendLoc else { return }

        let nycBounds = (
            north: 40.917577,
            south: 40.477399,
            east: -73.700272,
            west: -74.259090
        )

        let isUserInNYC = (nycBounds.south...nycBounds.north).contains(userLoc.latitude) &&
                          (nycBounds.west...nycBounds.east).contains(userLoc.longitude)

        let isFriendInNYC = (nycBounds.south...nycBounds.north).contains(friendLoc.latitude) &&
                            (nycBounds.west...nycBounds.east).contains(friendLoc.longitude)

        if !isUserInNYC || !isFriendInNYC {
            self.showTransitFallbackToast = true
            self.currentToast = TransitFallbackToast.create(for: "Meep is only available within New York City.")
        }
    }
// MARK: - NYC Bounding Box Helper
private func isWithinNYC(_ coordinate: CLLocationCoordinate2D) -> Bool {
    let nycBoundingBox = (
        minLat: 40.4774, maxLat: 40.9176,
        minLon: -74.2591, maxLon: -73.7004
    )
    return coordinate.latitude >= nycBoundingBox.minLat &&
           coordinate.latitude <= nycBoundingBox.maxLat &&
           coordinate.longitude >= nycBoundingBox.minLon &&
           coordinate.longitude <= nycBoundingBox.maxLon
}


    /// Registers a geofence at the given coordinate if it is within NYC.
    func registerGeofence(at coordinate: CLLocationCoordinate2D, identifier: String) {
        guard isWithinNYC(coordinate) else {
            print("🚫 Geofence not registered: Outside NYC")
            return
        }

        let region = CLCircularRegion(
            center: coordinate,
            radius: 100,
            identifier: identifier
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false

        locationManager?.startMonitoring(for: region)
        print("✅ Geofence registered for: \(identifier)")
    }

    /// This should ONLY request permission (call from privacy disclosure)
    func requestLocationPermission() {
        locationManager?.requestWhenInUseAuthorization()
    }
    
}

// MARK: - AnnotationType Emoji Extension
extension AnnotationType {
    var emoji: String {
        if case .place(let emoji) = self { return emoji }
        return ""
    }
}


