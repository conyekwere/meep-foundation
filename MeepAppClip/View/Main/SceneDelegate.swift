//
//  SceneDelegate.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 3/23/25.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Process the URL if present
        if let userActivity = connectionOptions.userActivities.first {
            if let url = userActivity.webpageURL {
                UserDefaults.standard.set(url.absoluteString, forKey: "AppClipURL")
            }
        }
        
        // Create the SwiftUI view and set it as the root view
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: AppClipView())
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Process the URL from continued activity
        if let url = userActivity.webpageURL {
            UserDefaults.standard.set(url.absoluteString, forKey: "AppClipURL")
        }
    }
}
