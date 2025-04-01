//
//  AppDelegate.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/23/25.
//


import UIKit
import CoreLocation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }
    
    // Handle incoming URLs
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        // Store URL for parsing later
        if let url = userActivity.webpageURL {
            UserDefaults.standard.set(url.absoluteString, forKey: "AppClipURL")
        }
        
        return true
    }
}
