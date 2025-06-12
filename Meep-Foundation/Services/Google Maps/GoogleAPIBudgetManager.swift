//
//  GoogleAPIBudgetManager.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/12/25.
//



import Foundation
import MapKit

class GoogleAPIBudgetManager {
    static let shared = GoogleAPIBudgetManager()
    
    // MARK: - Budget Configuration
    private let monthlyBudget = 2000
    private let directionsCallCost = 1 // Each directions call costs 1 request
    private let placesPhotoCost = 1   // Each photo call costs 1 request
    
    // MARK: - Storage Keys
    private let requestCountKey = "GoogleAPIRequestCount"
    private let lastResetDateKey = "GoogleAPILastResetDate"
    
    // MARK: - Budget Tracking
    private var currentRequestCount: Int {
        get { UserDefaults.standard.integer(forKey: requestCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: requestCountKey) }
    }
    
    private var lastResetDate: Date {
        get { UserDefaults.standard.object(forKey: lastResetDateKey) as? Date ?? Date() }
        set { UserDefaults.standard.set(newValue, forKey: lastResetDateKey) }
    }
    
    // MARK: - Public Interface
    
    var remainingRequests: Int {
        checkAndResetIfNeeded()
        return max(0, monthlyBudget - currentRequestCount)
    }
    
    var usagePercentage: Double {
        checkAndResetIfNeeded()
        return Double(currentRequestCount) / Double(monthlyBudget)
    }
    
    func canMakeDirectionsCall() -> Bool {
        checkAndResetIfNeeded()
        return remainingRequests >= directionsCallCost
    }
    
    func canMakePhotoCall() -> Bool {
        checkAndResetIfNeeded()
        return remainingRequests >= placesPhotoCost
    }
    
    func recordDirectionsCall() {
        checkAndResetIfNeeded()
        currentRequestCount += directionsCallCost
        logUsage("Directions API call")
    }
    
    func recordPhotoCall() {
        checkAndResetIfNeeded()
        currentRequestCount += placesPhotoCost
        logUsage("Places Photo API call")
    }
    
    // MARK: - Smart Usage Strategies
    
    func shouldUseGoogleForMidpoint(userLocation: CLLocationCoordinate2D, 
                                   friendLocation: CLLocationCoordinate2D) -> Bool {
        // Always allow if we have plenty of budget (less than 50% used)
        if usagePercentage < 0.5 {
            return true
        }
        
        // Be more selective when budget is getting tight (50-80% used)
        if usagePercentage < 0.8 {
            let distance = userLocation.distance(to: friendLocation)
            // Only use Google for longer distances where optimization matters most
            return distance > 2000 // 2km+
        }
        
        // Very conservative when budget is almost depleted (80%+ used)
        if usagePercentage < 0.95 {
            let distance = userLocation.distance(to: friendLocation)
            // Only for very long distances
            return distance > 5000 // 5km+
        }
        
        // Emergency reserve - only use for critical calls
        return false
    }
    
    func shouldUseGoogleForTransitAnalysis() -> Bool {
        // More lenient for transit analysis as it's core functionality
        return usagePercentage < 0.9
    }
    
    func shouldFetchPhotoFromGoogle() -> Bool {
        // Most conservative for photos as they're nice-to-have
        return usagePercentage < 0.7
    }
    
    // MARK: - Private Helpers
    
    private func checkAndResetIfNeeded() {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if we've moved to a new month
        if !calendar.isDate(lastResetDate, equalTo: now, toGranularity: .month) {
            print("🔄 Google API Budget: New month detected, resetting counter")
            currentRequestCount = 0
            lastResetDate = now
        }
    }
    
    private func logUsage(_ action: String) {
        print("📊 Google API Budget: \(action) - Used: \(currentRequestCount)/\(monthlyBudget) (\(String(format: "%.1f", usagePercentage * 100))%)")
        
        // Warning thresholds
        if usagePercentage >= 0.8 {
            print("⚠️ Google API Budget: 80% of monthly budget used!")
        } else if usagePercentage >= 0.9 {
            print("🚨 Google API Budget: 90% of monthly budget used!")
        }
    }
    
    // MARK: - Debug Methods
    
    func debugPrintStatus() {
        checkAndResetIfNeeded()
        print("📊 === GOOGLE API BUDGET STATUS ===")
        print("   Monthly Budget: \(monthlyBudget)")
        print("   Used This Month: \(currentRequestCount)")
        print("   Remaining: \(remainingRequests)")
        print("   Usage: \(String(format: "%.1f", usagePercentage * 100))%")
        print("   Last Reset: \(lastResetDate)")
        print("   Can Make Directions Call: \(canMakeDirectionsCall())")
        print("   Can Make Photo Call: \(canMakePhotoCall())")
        print("================================")
    }
    
    func resetBudgetForTesting() {
        currentRequestCount = 0
        lastResetDate = Date()
        print("🧪 Google API Budget reset for testing")
    }
}

// MARK: - Enhanced GoogleDirectionsService with Budget Management

extension GoogleDirectionsService {
    
    /// Get directions with budget management
    func getDirectionsWithBudget(_ request: GoogleDirectionsRequest) async throws -> GoogleDirectionsResponse? {
        let budgetManager = GoogleAPIBudgetManager.shared
        
        // Check if we can make the call
        guard budgetManager.canMakeDirectionsCall() else {
            print("❌ Google Directions: Budget exceeded, skipping call")
            throw GoogleDirectionsError.budgetExceeded
        }
        
        // Make the call and record usage
        let response = try await getDirections(request)
        budgetManager.recordDirectionsCall()
        
        return response
    }
    
    /// Get optimized midpoint with smart budget usage
    func getTransitOptimizedMidpointWithBudget(userLocation: CLLocationCoordinate2D,
                                             friendLocation: CLLocationCoordinate2D,
                                             searchRadius: Double = 1000) async throws -> CLLocationCoordinate2D {
        
        let budgetManager = GoogleAPIBudgetManager.shared
        
        // Check if we should use Google for this request
        guard budgetManager.shouldUseGoogleForMidpoint(userLocation: userLocation, 
                                                      friendLocation: friendLocation) else {
            print("💡 Google Midpoint: Using geographic fallback to preserve budget")
            return MidpointCalculator.calculateGeographicMidpoint(userLocation, friendLocation)
        }
        
        // Check if we have enough budget for the optimization process (needs multiple calls)
        guard budgetManager.remainingRequests >= 6 else { // Need ~6 calls for optimization
            print("💡 Google Midpoint: Not enough budget for full optimization, using geographic fallback")
            return MidpointCalculator.calculateGeographicMidpoint(userLocation, friendLocation)
        }
        
        // Proceed with Google optimization
        return try await getTransitOptimizedMidpoint(
            userLocation: userLocation,
            friendLocation: friendLocation,
            searchRadius: searchRadius
        )
    }
}

