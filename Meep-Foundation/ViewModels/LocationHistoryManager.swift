//
//  LocationHistoryManager.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/21/25.
//

//
//  LocationHistoryManager.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/21/25.
//

import Foundation
import CoreLocation

class LocationHistoryManager {
    // Singleton instance
    static let shared = LocationHistoryManager()
    
    // Maximum number of history items to store
    private let maxHistoryItems = 5
    
    // Keys for UserDefaults
    private let myLocationHistoryKey = "my_location_history"
    private let friendLocationHistoryKey = "friend_location_history"
    
    // Private initializer for singleton
    private init() {}
    
    // Add a location to history
    func addLocationToHistory(address: String, isMyLocation: Bool) {
        let key = isMyLocation ? myLocationHistoryKey : friendLocationHistoryKey
        
        // Get current history
        var history = UserDefaults.standard.stringArray(forKey: key) ?? []
        
        // Don't add if it's already the most recent one
        if let firstItem = history.first, firstItem == address {
            return
        }
        
        // Remove if it exists elsewhere in the history to avoid duplicates
        history.removeAll { $0 == address }
        
        // Add to beginning of array
        history.insert(address, at: 0)
        
        // Trim to maximum size
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }
        
        // Save back to UserDefaults
        UserDefaults.standard.set(history, forKey: key)
    }
    
    // Get location history
    func getLocationHistory(isMyLocation: Bool) -> [String] {
        let key = isMyLocation ? myLocationHistoryKey : friendLocationHistoryKey
        return UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    // Clear location history
    func clearLocationHistory(isMyLocation: Bool) {
        let key = isMyLocation ? myLocationHistoryKey : friendLocationHistoryKey
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // Get combined history for display
    func getCombinedHistoryText() -> String {
        let myHistory = getLocationHistory(isMyLocation: true)
        let friendHistory = getLocationHistory(isMyLocation: false)
        
        // Get unique addresses from both histories
        var combinedHistory = Array(Set(myHistory + friendHistory))
        
        // Sort by recency (this assumes the most recent items are at the beginning)
        combinedHistory.sort { (a, b) -> Bool in
            let aIndexMy = myHistory.firstIndex(of: a) ?? Int.max
            let aIndexFriend = friendHistory.firstIndex(of: a) ?? Int.max
            let bIndexMy = myHistory.firstIndex(of: b) ?? Int.max
            let bIndexFriend = friendHistory.firstIndex(of: b) ?? Int.max
            
            return min(aIndexMy, aIndexFriend) < min(bIndexMy, bIndexFriend)
        }
        
        // Take just the top 2 for display
        let displayHistory = combinedHistory.prefix(2)
        
        // Format as "address1 · address2"
        return displayHistory.joined(separator: " · ")
    }
}
