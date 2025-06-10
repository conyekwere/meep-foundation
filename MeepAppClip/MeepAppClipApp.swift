//
//  MeepAppClipApp.swift
//  MeepAppClip
//
//  Created by Chima Onyekwere on 3/23/25.
//

import SwiftUI

@main
struct MeepAppClipApp: App {
    @State private var urlToProcess: URL?
    
    var body: some Scene {
        WindowGroup {
            AppClipView(initialURL: urlToProcess)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        print("App Clip received URL: \(url)")
                        urlToProcess = url
                        
                        // Also save to UserDefaults as backup
                        UserDefaults.standard.set(url.absoluteString, forKey: "AppClipURL")
                        if let sharedDefaults = UserDefaults(suiteName: "group.meep.earth") {
                            sharedDefaults.set(url.absoluteString, forKey: "AppClipURL")
                        }
                    }
                }
                .onOpenURL { url in
                    print("App Clip opened with URL: \(url)")
                    urlToProcess = url
                }
        }
    }
}


