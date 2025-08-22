//
//  HereAPIBudgetManager.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 7/9/25.
//

import Foundation

class HereAPIBudgetManager {
    static let shared = HereAPIBudgetManager()
    
    // MARK: - Budget Configuration
    private let monthlyBudgetDollars: Double = 80.0
    
    // HERE Transit API is FREE up to 250K requests/month
    private let freeMonthlyRequests: Int = 250_000
    private let costPerRequestAfterFree: Double = 0.001 // Estimate after free tier
    
    // MARK: - Storage Keys
    private let requestCountKey = "HereAPIRequestCountThisMonth"
    private let spendKey = "HereAPISpendThisMonth"
    private let lastResetKey = "HereAPILastResetDate"
    
    // MARK: - Request Tracking
    private var currentRequestCount: Int {
        get { UserDefaults.standard.integer(forKey: requestCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: requestCountKey) }
    }
    
    private var currentSpend: Double {
        get { UserDefaults.standard.double(forKey: spendKey) }
        set { UserDefaults.standard.set(newValue, forKey: spendKey) }
    }
    
    private var lastResetDate: Date {
        get { UserDefaults.standard.object(forKey: lastResetKey) as? Date ?? Date() }
        set { UserDefaults.standard.set(newValue, forKey: lastResetKey) }
    }
    
    // MARK: - Public Interface
    
    /// Returns true and increments usage if under budget
    func canMakeRoutingCall() -> Bool {
        resetIfNeeded()
        
        // Calculate cost for this request
        let newRequestCount = currentRequestCount + 1
        let newCost: Double
        
        if newRequestCount <= freeMonthlyRequests {
            newCost = 0.0 // Still in free tier
        } else {
            newCost = currentSpend + costPerRequestAfterFree
        }
        
        // Check if this would exceed budget
        guard newCost <= monthlyBudgetDollars else {
            print("❌ HERE Budget exceeded: Would cost $\(String(format: "%.2f", newCost))")
            return false
        }
        
        // Update counters
        currentRequestCount = newRequestCount
        currentSpend = newCost
        
        logUsage()
        return true
    }
    
    var remainingBudget: Double {
        resetIfNeeded()
        return max(0, monthlyBudgetDollars - currentSpend)
    }
    
    var remainingFreeRequests: Int {
        resetIfNeeded()
        return max(0, freeMonthlyRequests - currentRequestCount)
    }
    
    // MARK: - Private Helpers
    
    private func resetIfNeeded() {
        let now = Date()
        let cal = Calendar.current
        if !cal.isDate(now, equalTo: lastResetDate, toGranularity: .month) {
            currentRequestCount = 0
            currentSpend = 0
            lastResetDate = now
            print("🔄 HERE Budget: New month, resetting counters")
        }
    }
    
    private func logUsage() {
        if currentRequestCount <= freeMonthlyRequests {
            // Still in free tier
            let freeUsagePercent = Double(currentRequestCount) / Double(freeMonthlyRequests) * 100
            print(String(format: "📊 HERE Usage: %d/%d free requests (%.1f%%)",
                         currentRequestCount, freeMonthlyRequests, freeUsagePercent))
            
            if freeUsagePercent >= 90 {
                print("🚨 HERE Warning: Using 90%+ of free tier!")
            } else if freeUsagePercent >= 80 {
                print("⚠️ HERE Warning: Using 80%+ of free tier")
            }
        } else {
            // In paid tier
            let budgetPercent = (currentSpend / monthlyBudgetDollars) * 100
            print(String(format: "📊 HERE Usage: %d requests, $%.2f/%.2f budget (%.1f%%)",
                         currentRequestCount, currentSpend, monthlyBudgetDollars, budgetPercent))
            
            if budgetPercent >= 90 {
                print("🚨 HERE Budget: Above 90%!")
            } else if budgetPercent >= 80 {
                print("⚠️ HERE Budget: Above 80%!")
            }
        }
    }
}
