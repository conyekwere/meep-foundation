//
//  Meep_FoundationApp.swift
//  Meep-Foundation
//
//  Created by Chima Onyekwere on 1/21/25.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleMaps
import GooglePlaces
import UserNotifications


@main
struct MeepApp: App {
    // Register app delegate for Firebase setup
    @StateObject private var onboardingManager = OnboardingManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environmentObject(OnboardingManager.shared)
                .onAppear {
                    OnboardingManager.shared.incrementAppLaunch()
                }
                .onOpenURL { url in
                    print("📬 onOpenURL triggered with URL: \(url)")
                    if Auth.auth().canHandle(url) {
                        print("✅ Firebase Auth handled the URL.")
                    } else {
                        print("❌ Firebase Auth could not handle the URL.")
                    }
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
       // Auth.auth().settings?.isAppVerificationDisabledForTesting = true
       // print("⚠️ Firebase reCAPTCHA fallback disabled for testing")
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Configure Google Maps & Places API
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
           !apiKey.isEmpty {
            GMSServices.provideAPIKey(apiKey)
            GMSPlacesClient.provideAPIKey(apiKey)
            print("✅ Google Maps & Places API Key Loaded")
        } else {
            fatalError("❌ Google API Key is missing or invalid")
        }

        configureAppAppearance()

        // Force Light Mode
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = .light }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
                return
            }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("✅ Push notification permission granted")
            } else {
                print("⚠️ Push notification permission denied")
            }
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                print("🔔 Notification authorization status: \(settings.authorizationStatus.rawValue)")
            }
        }

        if let app = FirebaseApp.app() {
            print("✅ Firebase default app configured:")
            print("  Project ID: \(app.options.projectID ?? "nil")")
            print("  App ID: \(app.options.googleAppID)")
            print("  API Key: \(app.options.apiKey)")
            print("  Client ID: \(app.options.clientID ?? "nil")")
        } else {
            print("❌ Firebase default app not configured.")
        }

        print("🔍 All Firebase apps: \(FirebaseApp.allApps ?? [:])")
        
        return true
    }
    
    // Handling device token for push notifications (important for phone auth)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        print("📲 APNs Token registered: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    }
    
    // Method to forward notifications to Firebase Auth
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification notification: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("📥 Received push notification: \(notification)")
        
        if Auth.auth().canHandleNotification(notification) {
            print("✅ Firebase handled the OTP silent push")
            completionHandler(.noData)
            return
        }
        
        print("❌ Firebase could NOT handle push — falling back to captcha")
        completionHandler(.newData)
    }
    
    // Handling deep links for authentication
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        } else {
            // Handle other deep links if needed
            return false
        }
    }
    
    private func configureAppAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    // UNUserNotificationCenterDelegate methods (for handling notifications when app is in foreground)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Display notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification response
        completionHandler()
    }
}
