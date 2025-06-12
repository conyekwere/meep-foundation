//
//  TransitFallbackToast.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 6/11/25.
//



import SwiftUI

struct TransitFallbackToast {
    let icon: String
    let title: String
    let message: String
    let primaryColor: Color
    let secondaryColor: Color
    
    // MARK: - Predefined Toast Configurations
    
    static func create(for reason: String) -> TransitFallbackToast {
        let lowercaseReason = reason.lowercased()
        
        // East/West Harlem case
        if lowercaseReason.contains("east harlem") || lowercaseReason.contains("west harlem") {
            return TransitFallbackToast(
                icon: "car.fill",
                title: "Try taxi or walking",
                message: "East-West Harlem has no direct subway connection",
                primaryColor: .orange,
                secondaryColor: .orange.opacity(0.8)
            )
        }
        
        // Financial District / Battery Park
        else if lowercaseReason.contains("financial district") || lowercaseReason.contains("battery park") {
            return TransitFallbackToast(
                icon: "figure.walk",
                title: "Walking recommended",
                message: "Short distance - faster on foot",
                primaryColor: .green,
                secondaryColor: .green.opacity(0.8)
            )
        }
        
        // Brooklyn Heights / DUMBO
        else if lowercaseReason.contains("brooklyn heights") || lowercaseReason.contains("dumbo") {
            return TransitFallbackToast(
                icon: "car.fill",
                title: "Try taxi or walking",
                message: "Subway requires detour through Manhattan",
                primaryColor: .orange,
                secondaryColor: .orange.opacity(0.8)
            )
        }
        
        // Lower Manhattan neighborhoods
        else if lowercaseReason.contains("lower manhattan") || lowercaseReason.contains("chinatown") {
            return TransitFallbackToast(
                icon: "figure.walk",
                title: "Walking recommended",
                message: "Neighboring areas - subway is overkill",
                primaryColor: .green,
                secondaryColor: .green.opacity(0.8)
            )
        }
        
        // Upper East/West Side crosstown
        else if lowercaseReason.contains("upper east") || lowercaseReason.contains("crosstown") {
            return TransitFallbackToast(
                icon: "bus.fill",
                title: "Try crosstown bus",
                message: "M86 or M79 bus is more direct",
                primaryColor: .blue,
                secondaryColor: .blue.opacity(0.8)
            )
        }
        
        // Roosevelt Island
        else if lowercaseReason.contains("roosevelt island") {
            return TransitFallbackToast(
                icon: "tram.fill",
                title: "Take the tram",
                message: "Roosevelt Island tram or F train only",
                primaryColor: .purple,
                secondaryColor: .purple.opacity(0.8)
            )
        }
        
        // Staten Island
        else if lowercaseReason.contains("staten island") || lowercaseReason.contains("ferry") {
            return TransitFallbackToast(
                icon: "ferry.fill",
                title: "Try ferry or driving",
                message: "Staten Island requires ferry connection",
                primaryColor: .blue,
                secondaryColor: .blue.opacity(0.8)
            )
        }
        
        // Red Hook
        else if lowercaseReason.contains("red hook") {
            return TransitFallbackToast(
                icon: "bus.fill",
                title: "Try bus or taxi",
                message: "Red Hook has no subway service",
                primaryColor: .orange,
                secondaryColor: .orange.opacity(0.8)
            )
        }
        
        // Williamsburg bridge areas
        else if lowercaseReason.contains("williamsburg") || lowercaseReason.contains("bridge") {
            return TransitFallbackToast(
                icon: "bicycle",
                title: "Walk or bike the bridge",
                message: "Bridge crossing is faster than subway",
                primaryColor: .cyan,
                secondaryColor: .cyan.opacity(0.8)
            )
        }
        
        // Far Queens
        else if lowercaseReason.contains("far queens") || lowercaseReason.contains("lirr") {
            return TransitFallbackToast(
                icon: "tram.fill",
                title: "Try LIRR or bus",
                message: "Area not well served by subway",
                primaryColor: .indigo,
                secondaryColor: .indigo.opacity(0.8)
            )
        }
        
        // Late night service
        else if lowercaseReason.contains("late night") || lowercaseReason.contains("limited") {
            return TransitFallbackToast(
                icon: "moon.fill",
                title: "Limited night service",
                message: "Consider taxi or rideshare",
                primaryColor: .purple,
                secondaryColor: .purple.opacity(0.8)
            )
        }
        
        // Same area (both users close)
        else if lowercaseReason.contains("same") && lowercaseReason.contains("area") {
            return TransitFallbackToast(
                icon: "figure.walk",
                title: "You're already close!",
                message: "Walking is faster than subway",
                primaryColor: .green,
                secondaryColor: .green.opacity(0.8)
            )
        }
        
        // No direct routes (general)
        else if lowercaseReason.contains("no direct") || lowercaseReason.contains("no subway") {
            return TransitFallbackToast(
                icon: "figure.walk.motion",
                title: "Switched to walking",
                message: "No direct subway routes available",
                primaryColor: .gray,
                secondaryColor: .gray.opacity(0.8)
            )
        }
        
        // Default case
        else {
            return TransitFallbackToast(
                icon: "figure.walk.motion",
                title: "Switched to walking",
                message: "Subway not optimal for this trip",
                primaryColor: .gray,
                secondaryColor: .gray.opacity(0.8)
            )
        }
    }
    
    
    static func createFromGoogleAnalysis(_ result: TransitAnalysisResult) -> TransitFallbackToast {
           
           // Use confidence to determine toast styling
           let isHighConfidence = result.confidence > 0.8
           
           if result.reason.contains("walking is") && result.reason.contains("faster") {
               return TransitFallbackToast(
                   icon: "figure.walk.motion",
                   title: isHighConfidence ? "Walking is faster" : "Consider walking",
                   message: result.reason,
                   primaryColor: .green,
                   secondaryColor: .green.opacity(0.8)
               )
           }
           
           if result.reason.contains("transfers") {
               return TransitFallbackToast(
                   icon: "arrow.triangle.branch",
                   title: "Too many transfers",
                   message: result.reason,
                   primaryColor: .orange,
                   secondaryColor: .orange.opacity(0.8)
               )
           }
           
           if result.reason.contains("mostly walking") {
               return TransitFallbackToast(
                   icon: "figure.walk.circle",
                   title: "Route is mostly walking",
                   message: "Transit includes significant walking portions",
                   primaryColor: .blue,
                   secondaryColor: .blue.opacity(0.8)
               )
           }
           
           if result.reason.contains("No transit routes") {
               return TransitFallbackToast(
                   icon: "xmark.circle",
                   title: "No transit available",
                   message: result.reason,
                   primaryColor: .red,
                   secondaryColor: .red.opacity(0.8)
               )
           }
           
           // Default Google-based fallback
           return TransitFallbackToast(
               icon: "map",
               title: isHighConfidence ? "Transit not optimal" : "Consider alternatives",
               message: result.reason,
               primaryColor: .gray,
               secondaryColor: .gray.opacity(0.8)
           )
       }
}
