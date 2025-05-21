//
//  MeetingSearchSheetView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/24/25.
//

import SwiftUI
import CoreLocation
import MapKit
import Contacts
import ContactsUI


struct ShareSheetPointerView: View {
    @State private var arrowOffsetY: CGFloat = 0
    @State private var showArrow: Bool = false
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay to darken the screen
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Position arrow at the bottom pointing upward to the share sheet
            VStack(spacing:32)
            {
                // Add explanatory text above the arrow
                Text("Tap a contact to share your meeting request.")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    .blendMode(.hardLight)
                
                Image(systemName: "chevron.down")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .shadow(color: .black.opacity(1), radius: 1, x: 0, y: 1)
                    .offset(y: arrowOffsetY)
                    .opacity(showArrow ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, UIScreen.main.bounds.height * 0.60)
            .onAppear {
                // Fade in the arrow with a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        showArrow = true
                    }
                    
                    // Start the bouncing animation
                    withAnimation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                    ) {
                        arrowOffsetY = -15
                    }
                }
            }
        }
    }
}

struct ArrowPointerView: View {
    @State private var arrowOffsetY: CGFloat = 0
    @State private var showArrow: Bool = false
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay to darken the screen
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Bouncing arrow pointing upward
            VStack {
   
                
                Image(systemName: "chevron.up")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.top, UIScreen.main.bounds.height * 0.4) // 30% of screen height instead of fixed 240
                    .padding(.leading, UIScreen.main.bounds.width * 0.35) // 35% of screen width instead of fixed 140

                    .fontWeight(.bold)
                    .shadow(color: .black.opacity(0.80), radius: 1, x: 0, y: 1)
                    .textCase(.uppercase)
                    .shadow(color: Color(UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)), radius: 4, x: 0, y: 4)
                    .offset(y: arrowOffsetY)
                    .opacity(showArrow ? 1 : 0) // Control visibility with a state variable
                    .onAppear {
                        // Delay the appearance to match contact permissions modal
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1 second delay
                            withAnimation(.easeIn(duration: 0.5)) {
                                showArrow = true // Fade in the arrow
                            }
                            
                            // Start the bouncing animation after it appears
                            withAnimation(
                                Animation.easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true)
                            ) {
                                arrowOffsetY = -15
                            }
                        }
                    }
            }
        }
    }
}



struct MeetingSearchSheetView: View {
    @State private var myLocation: String = ""
    @State private var friendLocation: String = ""
    
    @ObservedObject var viewModel: MeepViewModel
    @ObservedObject private var locationsManager = UserLocationsManager.shared
    @EnvironmentObject private var onboardingManager: OnboardingManager
    
    
    @Binding var isSearchActive: Bool
    
    // Focus states for the two text fields.
    @FocusState private var isMyLocationFocused: Bool
    @FocusState private var isFriendsLocationFocused: Bool
    
    // Completion handlers for dismissing and completing the search.
    var onDismiss: () -> Void
    var onDone: () -> Void
    
    // Two separate local search completer instances:
    @StateObject private var mySearchCompleter = LocalSearchCompleterDelegate()
    @StateObject private var friendSearchCompleter = LocalSearchCompleterDelegate()
    
    
    @State private var isGeocodingInProgress = false
    @State private var geocodingQueue = 0
    
    @State private var isShowingContactPicker = false
    @State private var selectedContact: CNContact? = nil
    @State private var showingContactArrowPointer = false
    
    @State private var isMyLocationValid: Bool = false
    @State private var isFriendsLocationValid: Bool = false
    
    
    // Add state for the selected transport mode for each row.
    @State private var selectedMyTransport: TransportMode? = nil
    @State private var selectedFriendTransport: TransportMode? = nil
    
    // Flag to detect whether the friend’s transport was manually changed.
       @State private var friendTransportManuallyChanged: Bool = false

    // Sheet states
    @State private var showSaveLocationSheet = false
    @State private var showCustomLocationsSheet = false
    @State private var showAddHomeAddressSheet = false
    @State private var showAddWorkAddressSheet = false
    @State private var showAddCustomAddressSheet = false
    @State private var locationToSave = ""
    @State private var tempCoordinate: CLLocationCoordinate2D? = nil
    @State private var longPressTimer: Timer? = nil
    
    
    @State private var myLocationHistory: [String] = []
    @State private var friendLocationHistory: [String] = []
    @State private var locationHistoryText: String = ""
    
    
    @State private var arrowOffsetY : CGFloat = 0
    
    
    @State private var showingShareArrowPointer = false
    
    
    func areFieldsEmpty() -> Bool {
        return myLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               friendLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    

    
    private func saveLocationRequest(requestID: String, contactName: String, contactId: String?) {
        // Create request data
        let requestData: [String: Any] = [
            "requestID": requestID,
            "userID": UserDefaults.standard.string(forKey: "userId") ?? UUID().uuidString,
            "userName": UserDefaults.standard.string(forKey: "userName") ?? "Ashley Dee",
            "contactName": contactName, // Use directly, not as optional
            "contactId": contactId ?? "anonymous",
            "status": "pending",
            "createdAt": Date().timeIntervalSince1970
        ]
        
        // For Firebase implementation:
        /*
        let db = Firestore.firestore()
        db.collection("locationRequests").document(requestID).setData(requestData) { error in
            if let error = error {
                print("Error saving location request: \(error.localizedDescription)")
            } else {
                print("Location request saved successfully")
            }
        }
        */
        
        // For now, just print the data
        print("Saving location request: \(requestData)")
    }
    
    // Function to safely start and end geocoding operations
    private func performGeocoding(action: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.isGeocodingInProgress = true
            self.geocodingQueue += 1
            
            action()
        }
    }

    private func geocodingCompleted() {
        DispatchQueue.main.async {
            self.geocodingQueue -= 1
            if self.geocodingQueue <= 0 {
                self.geocodingQueue = 0
                self.isGeocodingInProgress = false
                
                // After all geocoding is complete, check if any field still contains coordinate formats
                let myLocationTrimmed = self.myLocation.trimmingCharacters(in: .whitespacesAndNewlines)
                let friendLocationTrimmed = self.friendLocation.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // If either field still contains coordinates, clear it
                if LocationHelpers.isLikelyCoordinates(myLocationTrimmed) {
                    self.myLocation = ""
                    self.viewModel.userLocation = nil
                    self.isMyLocationValid = false
                }
                
                if LocationHelpers.isLikelyCoordinates(friendLocationTrimmed) {
                    self.friendLocation = ""
                    self.viewModel.friendLocation = nil
                    self.isFriendsLocationValid = false
                }
            }
        }
    }
    
    // Replace your current validateAddress method with:
    private func validateAddress(_ address: String, using completer: LocalSearchCompleterDelegate) -> Bool {
        let allSavedLocations = [locationsManager.homeLocation, locationsManager.workLocation]
            .compactMap { $0 }
            + locationsManager.customLocations
        
        return LocationHelpers.validateAddress(
            address,
            completer: completer,
            savedLocations: allSavedLocations,
            existingCoordinate: address == myLocation ? viewModel.userLocation : viewModel.friendLocation
        )
    }
    
    private func processBothLocations(completion: @escaping () -> Void) {
        // Ensure we have coordinates for both locations before proceeding
        let processLocationResults = {
                if self.viewModel.userLocation != nil && self.viewModel.friendLocation != nil {
                    // Update the shareable strings with the actual addresses
                    self.viewModel.sharableUserLocation = self.myLocation
                    self.viewModel.sharableFriendLocation = self.friendLocation
                    
                    
                    // Update location history
                    self.updateLocationHistory()
                    
                    // Then proceed with the rest
                    self.viewModel.reverseGeocodeUserLocation()
                    self.viewModel.reverseGeocodeFriendLocation()
                    self.viewModel.searchNearbyPlaces()
                    completion()
                }
            }
        
        // First check if we need to geocode the user location
        if viewModel.userLocation == nil {
            LocationHelpers.geocodeAddress(myLocation) { coordinate, _ in
                guard let userCoord = coordinate else {
                    print("❌ Failed to geocode My Location: \(self.myLocation)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.viewModel.userLocation = userCoord
                    
                    // Now check if we need to geocode the friend location
                    if self.viewModel.friendLocation == nil {
                        LocationHelpers.geocodeAddress(self.friendLocation) { coordinate, _ in
                            guard let friendCoord = coordinate else {
                                print("❌ Failed to geocode Friend's Location: \(self.friendLocation)")
                                return
                            }
                            
                            DispatchQueue.main.async {
                                self.viewModel.friendLocation = friendCoord
                                processLocationResults()
                            }
                        }
                    } else {
                        processLocationResults()
                    }
                }
            }
        }
        // If user location is already known, check friend location
        else if viewModel.friendLocation == nil {
            LocationHelpers.geocodeAddress(friendLocation) { coordinate, _ in
                guard let friendCoord = coordinate else {
                    print("❌ Failed to geocode Friend's Location: \(self.friendLocation)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.viewModel.friendLocation = friendCoord
                    processLocationResults()
                }
            }
        }
        // Both locations already have coordinates
        else {
            processLocationResults()
        }
    }
    
    
    private func clearCoordinateFormats() {
        // Check My Location field
        if LocationHelpers.isLikelyCoordinates(myLocation.trimmingCharacters(in: .whitespacesAndNewlines)) {
            myLocation = ""
            viewModel.userLocation = nil
            isMyLocationValid = false
        }
        
        // Check Friend's Location field
        if LocationHelpers.isLikelyCoordinates(friendLocation.trimmingCharacters(in: .whitespacesAndNewlines)) {
            friendLocation = ""
            viewModel.friendLocation = nil
            isFriendsLocationValid = false
        }
    }
    
    
    private func handleSavedLocation(_ savedLocation: SavedLocation) {
        // Set the location based on the current focus
        if isMyLocationFocused {
            myLocation = savedLocation.address
            isMyLocationValid = true
            viewModel.userLocation = savedLocation.coordinate
            
            // Move focus to friend location field
            isMyLocationFocused = false
            isFriendsLocationFocused = true
        } else if isFriendsLocationFocused {
            friendLocation = savedLocation.address
            isFriendsLocationValid = true
            viewModel.friendLocation = savedLocation.coordinate
            
            // Remove focus from location fields
            isFriendsLocationFocused = false
            isMyLocationFocused = false
        }
        
        // Close any open sheets
        showAddHomeAddressSheet = false
        showAddWorkAddressSheet = false
        showAddCustomAddressSheet = false
    }
    
    


    // Function to proactively geocode an address if it's valid but doesn't have coordinates yet
    private func geocodeIfNeeded(_ address: String, isMyLocation: Bool) {
        let isValid = isMyLocation ? isMyLocationValid : isFriendsLocationValid
        let hasCoordinates = isMyLocation ? (viewModel.userLocation != nil) : (viewModel.friendLocation != nil)
        
        if isValid && !hasCoordinates {
            LocationHelpers.geocodeAddress(address) { coordinate, formattedAddress in
                DispatchQueue.main.async {
                    if let coordinate = coordinate {
                        if isMyLocation {
                            self.viewModel.userLocation = coordinate
                        } else {
                            self.viewModel.friendLocation = coordinate
                        }
                    }
                    
                    if let formattedAddress = formattedAddress {
                        if isMyLocation {
                            self.myLocation = formattedAddress
                        } else {
                            self.friendLocation = formattedAddress
                        }
                    }
                }
            }
        }
    }
    
    
    private func updateLocationHistory() {
        // Only add valid locations to history
        if isMyLocationValid && !myLocation.isEmpty {
            LocationHistoryManager.shared.addLocationToHistory(address: myLocation, isMyLocation: true)
        }
        
        if isFriendsLocationValid && !friendLocation.isEmpty {
            LocationHistoryManager.shared.addLocationToHistory(address: friendLocation, isMyLocation: false)
        }
        
        // Update the local history arrays
        myLocationHistory = LocationHistoryManager.shared.getLocationHistory(isMyLocation: true)
        friendLocationHistory = LocationHistoryManager.shared.getLocationHistory(isMyLocation: false)
        
        // Update the combined history text
        locationHistoryText = LocationHistoryManager.shared.getCombinedHistoryText()
    }
    
    private func requestContactAccess(completion: @escaping (Bool) -> Void) {
        showingContactArrowPointer = true
        
        let contactStore = CNContactStore()
        contactStore.requestAccess(for: .contacts) { granted, error in
            // After permission dialog completes, wait a moment before showing share sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showingContactArrowPointer = false
               
               // Show the share sheet pointer
                withAnimation {
                    self.showingShareArrowPointer = true
                }
                self.presentShareSheet()

            }
        }
    }
    


     func presentShareSheet() {
        // Generate the request data
        let userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
        let userId = UserDefaults.standard.string(forKey: "userId") ?? UUID().uuidString
        let requestID = UUID().uuidString
        
        // Create deep link URL
        var components = URLComponents()
        components.scheme = "https"
        components.host = "meep.earth"
        components.path = "/share"
        components.queryItems = [
            URLQueryItem(name: "requestID", value: requestID),
            URLQueryItem(name: "userName", value: userName),
            URLQueryItem(name: "userId", value: userId)
        ]
        
        guard let url = components.url else {
            print("Failed to create URL")
            return
        }
        
        // Create message
        let message = "\(userName) wants to figure out where to meet."
        
        // Find the top-most presented controller to present on
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Could not find root view controller")
            return
        }
        
        // Find the topmost presented controller
        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }
        
        // Create the share sheet
        let activityVC = UIActivityViewController(
            activityItems: [message, url],
            applicationActivities: nil
        )
        
        // Set up iPad popover if needed
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topController.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2,
                                       y: UIScreen.main.bounds.height / 2,
                                       width: 0,
                                       height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Present on the main thread
        DispatchQueue.main.async {
            // Present directly on the topmost controller
            topController.present(activityVC, animated: true) {
                // Save the request after presentation
                self.saveLocationRequest(
                    requestID: requestID,
                    contactName: "Friend",
                    contactId: nil
                )
            }
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                withAnimation {
                    self.showingShareArrowPointer = false
                }
            }
        }
    }

    
    
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Input Section
                VStack(spacing: 0) {
                    // "My Location" Input Row
                    SearchTextFieldRow(
                        leadingIcon: "dot.square.fill",
                        title: "My Location",
                        placeholder: "What's your location?",
                        text: $myLocation,
                        isDirty: !myLocation.isEmpty,
                        selectedMode: $selectedMyTransport,
                        isValid: !myLocation.isEmpty ? isMyLocationValid : nil  // Only show validation if not empty
                    )
                    .focused($isMyLocationFocused)
                    .onSubmit { isMyLocationFocused = false }
                    .overlay(
                        Rectangle()
                            .fill(Color(#colorLiteral(red: 0.971, green: 0.971, blue: 0.971, alpha: 1)))
                            .frame(height: 2),
                        alignment: .bottom
                    )
                    .onLongPressGesture(minimumDuration: 0.5) {
                        // Only show save sheet if there's a valid location
                        if isMyLocationValid && !myLocation.isEmpty {
                            locationToSave = myLocation
                            
                            // Geocode the address to get coordinates
                            viewModel.geocodeAddress(myLocation) { coordinate in
                                if let coordinate = coordinate {
                                    tempCoordinate = coordinate
                                    showSaveLocationSheet = true
                                }
                            }
                        }
                    }
                    
                    // "Friend's Location" Input Row
                    SearchTextFieldRow(
                        leadingIcon: "dot.square.fill",
                        title: "Friend's Location",
                        placeholder: "What's your friend's location?",
                        text: $friendLocation,
                        isDirty: !friendLocation.isEmpty,
                        selectedMode: $selectedFriendTransport,
                        isValid: !friendLocation.isEmpty ? isFriendsLocationValid : nil  // Only show validation if not empty
                    )
                    .focused($isFriendsLocationFocused)
                    .onSubmit { isFriendsLocationFocused = false }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        // Only show save sheet if there's a valid location
                        if isFriendsLocationValid && !friendLocation.isEmpty {
                            locationToSave = friendLocation
                            
                            // Geocode the address to get coordinates
                            viewModel.geocodeAddress(friendLocation) { coordinate in
                                if let coordinate = coordinate {
                                    tempCoordinate = coordinate
                                    showSaveLocationSheet = true
                                }
                            }
                        }
                    }
                }
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(#colorLiteral(red: 0.971, green: 0.971, blue: 0.971, alpha: 1)), lineWidth: 2)
                )
                .padding(.horizontal, 16)
                
                
                // MARK: Main Content Section
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // MARK: Autocomplete Section (Only shows when typing)
                        if myLocation.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 && isMyLocationFocused && !mySearchCompleter.completions.isEmpty {
                            AutocompleteSuggestionsView(
                                completions: mySearchCompleter.completions,
                                text: $myLocation,
                                geocodeAddress: { completion in
                                    LocationHelpers.geocodeCompletion(completion) { coordinate, formattedAddress in
                                        DispatchQueue.main.async {
                                            if let coordinate = coordinate {
                                                self.viewModel.userLocation = coordinate
                                                self.isMyLocationValid = true
                                            }
                                            
                                            if let formattedAddress = formattedAddress {
                                                self.myLocation = formattedAddress
                                            }
                                            
                                            self.isMyLocationFocused = false
                                            self.isFriendsLocationFocused = true
                                        }
                                    }
                                },
                                onSuggestionSelected: {
                                    isMyLocationFocused = false
                                    isFriendsLocationFocused = true
                                    isMyLocationValid = true
                                }
                            )
                        } else if friendLocation.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 && isFriendsLocationFocused && !friendSearchCompleter.completions.isEmpty {
                            AutocompleteSuggestionsView(
                                completions: friendSearchCompleter.completions,
                                text: $friendLocation,
                                geocodeAddress: { completion in
                                    LocationHelpers.geocodeCompletion(completion) { coordinate, formattedAddress in
                                        DispatchQueue.main.async {
                                            if let coordinate = coordinate {
                                                self.viewModel.friendLocation = coordinate
                                                self.isFriendsLocationValid = true
                                            }
                                            
                                            if let formattedAddress = formattedAddress {
                                                self.friendLocation = formattedAddress
                                            }
                                            
                                            self.isFriendsLocationFocused = false
                                        }
                                    }
                                },
                                onSuggestionSelected: {
                                    isFriendsLocationFocused = false
                                    isFriendsLocationValid = true
                                }
                            )
                        } else {
                            // MARK: Suggestion Buttons Section
                            // Show when not displaying autocomplete
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 24) {
                                    if isMyLocationFocused {
                                        // My Location buttons when My Location is focused
                                        SuggestionButton(
                                            icon: "house",
                                            title: locationsManager.homeLocation?.address ?? "Set location",
                                            label: "Home",
                                            action: {
                                                guard let home = locationsManager.homeLocation,
                                                      home.isValidCoordinate() else {
                                                    showAddHomeAddressSheet = true
                                                    return
                                                }
                                                
                                                myLocation = home.address
                                                isMyLocationValid = true
                                                viewModel.userLocation = home.coordinate
                                                
                                                isMyLocationFocused = false
                                                isFriendsLocationFocused = true
                                            }
                                        )
                                        
                                        SuggestionButton(
                                            icon: "briefcase",
                                            title: locationsManager.workLocation?.address ?? "Set location",
                                            label: "Work",
                                            action: {
                                                if let work = locationsManager.workLocation {
                                                    myLocation = work.address
                                                    isMyLocationValid = true
                                                    viewModel.userLocation = work.coordinate
                                                    
                                                    isMyLocationFocused = false
                                                    isFriendsLocationFocused = true
                                                } else {
                                                    showAddWorkAddressSheet = true
                                                }
                                            }
                                        )
                                        
                                        SuggestionButton(
                                            icon: "ellipsis",
                                            title: "",
                                            label: "More",
                                            action: {
                                                showCustomLocationsSheet = true
                                            }
                                        )
                                    } else if isFriendsLocationFocused {
                                        // Friend's Location buttons when Friend's Location is focused
                                        SuggestionButton(
                                            icon: "plus",
                                            title: "Add another friend",
                                            label: "More friends?",
                                            action: { print("Add friend tapped") }
                                        )
                                        
                                        SuggestionButton(
                                            icon: "text.badge.plus",
                                            title: "Add contacts",
                                            label: "Searching for friends?",
                                            action: { print("Add contacts tapped") }
                                        )
                                        
                                        SuggestionButton(
                                            icon: "person.circle",
                                            title: "Set location",
                                            label: "Close Friend",
                                            action: { print("Close friend tapped") }
                                        )
                                    } else {
                                        // Default buttons when neither field is focused
                                        SuggestionButton(
                                            icon: "house",
                                            title: locationsManager.homeLocation?.address ?? "Set location",
                                            label: "Home",
                                            action: {
                                                guard let home = locationsManager.homeLocation,
                                                      home.isValidCoordinate() else {
                                                    showAddHomeAddressSheet = true
                                                    return
                                                }
                                                
                                                myLocation = home.address
                                                isMyLocationValid = true
                                                viewModel.userLocation = home.coordinate
                                                
                                                isMyLocationFocused = false
                                                isFriendsLocationFocused = true
                                            }
                                        )
                                        
                                        SuggestionButton(
                                            icon: "briefcase",
                                            title: locationsManager.workLocation?.address ?? "Set location",
                                            label: "Work",
                                            action: {
                                                if let work = locationsManager.workLocation {
                                                    myLocation = work.address
                                                    isMyLocationValid = true
                                                    viewModel.userLocation = work.coordinate
                                                    
                                                    isMyLocationFocused = false
                                                    isFriendsLocationFocused = true
                                                } else {
                                                    showAddWorkAddressSheet = true
                                                }
                                            }
                                        )
                                        
                                        SuggestionButton(
                                            icon: "ellipsis",
                                            title: "",
                                            label: "More",
                                            action: {
                                                showCustomLocationsSheet = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.top, 40)
                            .scrollTargetLayout()
                            .safeAreaPadding(.trailing, 16)
                            .scrollIndicators(.hidden)
                            .scrollClipDisabled(true)
                            
                            // MARK: Additional Options Section
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack(spacing: 40) {
                                    if isMyLocationFocused {
                                        // Current Location Button when My Location is focused
                                        Button(action: {
                                            print("Current Location selected")
                                            viewModel.requestUserLocation()
                                            
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                if let userCoord = viewModel.userLocation {
                                                    let location = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
                                                    CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                                                        if let placemark = placemarks?.first, error == nil {
                                                            let address = [
                                                                placemark.name,
                                                                placemark.locality,
                                                                placemark.administrativeArea
                                                            ]
                                                                .compactMap { $0 }
                                                                .joined(separator: ", ")
                                                            
                                                            DispatchQueue.main.async {
                                                                self.myLocation = address
                                                                self.isMyLocationValid = true
                                                                self.viewModel.userLocation = userCoord
                                                                self.isMyLocationFocused = false
                                                                self.isFriendsLocationFocused = true
                                                            }
                                                        } else {
                                                            DispatchQueue.main.async {
                                                                let fallback = String(format: "%.4f, %.4f", userCoord.latitude, userCoord.longitude)
                                                                self.myLocation = fallback
                                                                self.isMyLocationValid = true
                                                                self.viewModel.userLocation = userCoord
                                                                self.isMyLocationFocused = false
                                                                self.isFriendsLocationFocused = true
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            
                                        }) {
                                            HStack(spacing: 16) {
                                                Image(systemName: "location")
                                                    .font(.callout)
                                                    .foregroundColor(.blue)
                                                    .frame(width: 40, height: 40)
                                                    .background(Color(hex: "E8F0FE"))
                                                    .clipShape(Circle())
                                                Text("Current Location")
                                                    .foregroundColor(.primary)
                                                    .font(.body)
                                            }
                                            .padding(.horizontal, 16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    
                                    // Ask for Friend's Location button (shown for all states)
                                    Button(action: {
                                        
                                        //if Contact  Access has already been requested showingContactArrowPointer = true
                                        
                                        requestContactAccess { granted in
                                            // Regardless of the result, the modal was shown
                                            showingContactArrowPointer = false
                                            
                                        }
                                    }) {
                                        HStack(spacing: 16) {
                                            Image(systemName: "message")
                                                .font(.callout)
                                                .foregroundColor(.blue)
                                                .frame(width: 40, height: 40)
                                                .background(Color(hex: "E8F0FE"))
                                                .clipShape(Circle())
                                            
                                            VStack(alignment: .leading) {
                                                Text("Ask for a Friend's Location")
                                                    .foregroundColor(.primary)
                                                    .font(.body)
                                                Text("Exact coordinates are hidden")
                                                    .font(.callout)
                                                    .foregroundColor(Color(.darkGray))
                                                    .lineLimit(1)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    
                                    if onboardingManager.shouldShowOnboardingElement() {
                                        Image(systemName: "chevron.up")
                                            .font(.title3)
                                            .foregroundColor(.primary)
                                            .padding(.trailing, 16)
                                            .offset(y: arrowOffsetY)
                                            .onAppear {
                                                withAnimation(
                                                    Animation.easeInOut(duration: 0.5)
                                                        .repeatForever(autoreverses: true)
                                                ) {
                                                    arrowOffsetY = -15
                                                }
                                            }
                                    }
                                    // History section based on focus state
                                    if !myLocationHistory.isEmpty && isMyLocationFocused {
                                        // My Location history when My Location is focused
                                        LocationHistoryView(histories: myLocationHistory, onSelectLocation: { address in
                                            myLocation = address
                                            isMyLocationValid = true
                                            
                                            LocationHelpers.geocodeAddress(address) { coordinate, _ in
                                                if let coord = coordinate {
                                                    DispatchQueue.main.async {
                                                        self.viewModel.userLocation = coord
                                                        self.isMyLocationFocused = false
                                                        self.isFriendsLocationFocused = true
                                                    }
                                                }
                                            }
                                        })
                                        .padding(.top,onboardingManager.shouldShowOnboardingElement() ? -36 : 0)
                                    } else if !friendLocationHistory.isEmpty && isFriendsLocationFocused {
                                        // Friend's Location history when Friend's Location is focused
                                        LocationHistoryView(histories: friendLocationHistory, onSelectLocation: { address in
                                            friendLocation = address
                                            isFriendsLocationValid = true
                                            
                                            LocationHelpers.geocodeAddress(address) { coordinate, _ in
                                                if let coord = coordinate {
                                                    DispatchQueue.main.async {
                                                        self.viewModel.friendLocation = coord
                                                        self.isFriendsLocationFocused = false
                                                    }
                                                }
                                            }
                                        })
                                        .padding(.top,onboardingManager.shouldShowOnboardingElement() ? -36 : 0)
                                    } else if !myLocationHistory.isEmpty && !isMyLocationFocused && !isFriendsLocationFocused {
                                        // History when neither field is focused (default to My Location history)
                                        LocationHistoryView(histories: myLocationHistory, onSelectLocation: { address in
                                            myLocation = address
                                            isMyLocationValid = true
                                            
                                            LocationHelpers.geocodeAddress(address) { coordinate, _ in
                                                if let coord = coordinate {
                                                    DispatchQueue.main.async {
                                                        self.viewModel.userLocation = coord
                                                        self.isMyLocationFocused = false
                                                        self.isFriendsLocationFocused = true
                                                    }
                                                }
                                            }
                                        })
                                        .padding(.top,onboardingManager.shouldShowOnboardingElement() ? -36 : 0)
                                    }
                                }
                            }
                            .scrollClipDisabled(true)
                            .padding(.top, 40)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.top, 16)
            .background(Color(.systemBackground))
            .ignoresSafeArea(edges: .bottom)
            .overlay(
                ZStack {
                    if isGeocodingInProgress {
                        Color.black.opacity(0.1)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            
                            Text("Converting coordinates...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                }
            )
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        print("DEBUG: Back Button Tapped")
                        onDismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(12)
                            .frame(width: 40, height: 40)
                            .foregroundColor(isGeocodingInProgress ? Color(.lightGray) : Color(.gray))
                            .foregroundColor(Color(.gray))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color(.systemGray6), lineWidth: 2)
                                    
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isGeocodingInProgress)
                }
                ToolbarItem(placement: .principal) {
                    VStack(alignment: .center, spacing: 2) {
                        Text("Set meeting point")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .fontWidth(.expanded)
                            .foregroundColor(.primary).opacity(0.7)
                    }
                    .padding(.vertical, 8)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isMyLocationValid && isFriendsLocationValid {
                        Button(action: {


                            // Only proceed if both fields are valid after clearing
                            if isMyLocationValid && isFriendsLocationValid {
                                processBothLocations {
                                    onDone()
                                }
                            }
                            

                        }) {
                            Text("Done")
                                .foregroundColor(isGeocodingInProgress ? .gray : .primary)
                        }
                        .disabled(isGeocodingInProgress)
                    }
                }
            }
           
            
            .onAppear {
                
                
                
                // Update autocomplete queries for both fields.
                mySearchCompleter.updateQuery(myLocation)
                friendSearchCompleter.updateQuery(friendLocation)
                
                // If userLocation is available, reverse geocode to get a human-readable address.
                // Inside onAppear, replace the reverse geocoding for user location:
                if let userLoc = viewModel.userLocation {
                    // Check if myLocation is already populated with a good value
                    if myLocation.isEmpty || myLocation.contains(",") {
                        let location = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
                        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                            // Instead, use:
                            let formattedCoords = LocationHelpers.formatCoordinates(userLoc)
                            LocationHelpers.geocodeAddress(formattedCoords) { _, formattedAddress in
                                DispatchQueue.main.async {
                                    if let address = formattedAddress {
                                        self.myLocation = address
                                        self.isMyLocationValid = true
                                        
                                        // Only set focus to friend location if it's empty
                                        if self.friendLocation.isEmpty {
                                            self.isFriendsLocationFocused = true
                                        }
                                    } else {
                                        // Only update if we don't already have a good value
                                        if self.myLocation.isEmpty {
                                            self.myLocation = formattedCoords
                                            self.isMyLocationFocused = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }


                
                // Similar logic for friend location
                if let friendLoc = viewModel.friendLocation {
                    // Check if friendLocation is already populated with a good value
                    if friendLocation.isEmpty || friendLocation.contains(",") {
                        let formattedCoords = LocationHelpers.formatCoordinates(friendLoc)
                        LocationHelpers.geocodeAddress(formattedCoords) { _, formattedAddress in
                            DispatchQueue.main.async {
                                if let address = formattedAddress {
                                    self.friendLocation = address
                                    self.isFriendsLocationValid = true
                                } else {
                                    // Only update if we don't already have a good value
                                    if self.friendLocation.isEmpty {
                                        self.friendLocation = formattedCoords
                                    }
                                }
                            }
                        }
                    } else {
                        // If friendLocation already has a good value, mark it as valid
                        isFriendsLocationValid = true
                    }
                }
                
                
                myLocationHistory = LocationHistoryManager.shared.getLocationHistory(isMyLocation: true)
                friendLocationHistory = LocationHistoryManager.shared.getLocationHistory(isMyLocation: false)
                locationHistoryText = LocationHistoryManager.shared.getCombinedHistoryText()
                
            }
            .onChange(of: myLocation) { newValue in
                mySearchCompleter.updateQuery(newValue)
                
                // Check if it's coordinates
                if LocationHelpers.isLikelyCoordinates(newValue) {
                    isMyLocationValid = true
                    
                    performGeocoding {
                        LocationHelpers.geocodeAddress(newValue) { coordinate, formattedAddress in
                            DispatchQueue.main.async {
                                if let coordinate = coordinate {
                                    self.viewModel.userLocation = coordinate
                                }
                                
                                if let formattedAddress = formattedAddress {
                                    self.myLocation = formattedAddress
                                    self.viewModel.sharableUserLocation = formattedAddress
                                }
                                
                                // Mark this geocoding operation as complete
                                self.geocodingCompleted()
                            }
                        }
                    }
                }
                
                else {
                    // Otherwise use normal validation
                    isMyLocationValid = validateAddress(newValue, using: mySearchCompleter)
                    
                    // If the address is valid but doesn't have coordinates, geocode it
                    if isMyLocationValid && viewModel.userLocation == nil {
                        geocodeIfNeeded(newValue, isMyLocation: true)
                    }
                }
            }
            
            
            .onChange(of: friendLocation) { newValue in
                friendSearchCompleter.updateQuery(newValue)
                
                
                
                if LocationHelpers.isLikelyCoordinates(newValue) {
                    isFriendsLocationValid = true
                    
                    performGeocoding {
                        LocationHelpers.geocodeAddress(newValue) { coordinate, formattedAddress in
                            DispatchQueue.main.async {
                                if let coordinate = coordinate {
                                    self.viewModel.friendLocation = coordinate
                                }
                                
                                if let formattedAddress = formattedAddress {
                                    self.friendLocation = formattedAddress
                                }
                                
                                self.geocodingCompleted()
                            }
                        }
                    }
                } else {
                    // Otherwise use normal validation
                    isFriendsLocationValid = validateAddress(newValue, using: friendSearchCompleter)
                    
                    // If the address is valid but doesn't have coordinates, geocode it
                    if isFriendsLocationValid && viewModel.friendLocation == nil {
                        geocodeIfNeeded(newValue, isMyLocation: false)
                    }
                }
            }
            
            // When "My Transport" changes, update friend's transport (if the friend hasn't been manually changed).
            .onChange(of: selectedMyTransport) { newValue in
                if !friendTransportManuallyChanged {
                    selectedFriendTransport = newValue
                }
            }
            // If the friend’s selection deviates from "My Transport," mark it as manually changed.
            .onChange(of: selectedFriendTransport) { newValue in
                if newValue != selectedMyTransport {
                    friendTransportManuallyChanged = true
                } else {
                    friendTransportManuallyChanged = false
                }
            }
            
            
            // Show save location sheet
               .sheet(isPresented: $showSaveLocationSheet) {
                   if let coordinate = tempCoordinate {
                       SaveLocationOptionSheet(
                           address: locationToSave,
                           onSaveHome: {
                               locationsManager.saveHomeLocation(address: locationToSave, coordinate: coordinate)
                               showSaveLocationSheet = false
                           },
                           onSaveWork: {
                               locationsManager.saveWorkLocation(address: locationToSave, coordinate: coordinate)
                               showSaveLocationSheet = false
                           },
                           onSaveCustom: { name in
                               let customLocation = SavedLocation(
                                   id: UUID().uuidString,
                                   name: name,
                                   address: locationToSave,
                                   latitude: coordinate.latitude,
                                   longitude: coordinate.longitude
                               )
                               locationsManager.addCustomLocation(customLocation)
                               showSaveLocationSheet = false
                           },
                           onCancel: {
                               showSaveLocationSheet = false
                           }
                       )
                   }
               }
               .fullScreenCover(isPresented: $showCustomLocationsSheet) {
                   CustomLocationSheet(
                       isPresented: $showCustomLocationsSheet,
                       onLocationSelected: { location in
                           // Update the active field with the selected location
                           if isMyLocationFocused {
                               myLocation = location.address
                               isMyLocationValid = true
                               viewModel.userLocation = location.coordinate
                               
                               // Move focus to next field
                               isMyLocationFocused = false
                               isFriendsLocationFocused = true
                           } else if isFriendsLocationFocused {
                               friendLocation = location.address
                               isFriendsLocationValid = true
                               viewModel.friendLocation = location.coordinate
                               
                               // Hide keyboard
                               isFriendsLocationFocused = false
                           }
                       }
                   )
               }
            
            .fullScreenCover(isPresented: $showAddHomeAddressSheet) {
                AddressInputView(
                    viewModel: viewModel,
                    addressType: .home
                )
                { savedLocation in
                    handleSavedLocation(savedLocation)
                }
            }
            
            .fullScreenCover(isPresented: $showAddWorkAddressSheet) {
                AddressInputView(
                    viewModel: viewModel,
                    addressType: .work
                )
                { savedLocation in
                    handleSavedLocation(savedLocation)
                }
            }
            
            .fullScreenCover(isPresented: $showAddCustomAddressSheet) {
                AddressInputView(
                    viewModel: viewModel,
                    addressType: .custom
                ) { savedLocation in
                    handleSavedLocation(savedLocation)
                }
            }
        }
        .overlay(
            Group {
                if showingContactArrowPointer {
                    ArrowPointerView()
                        .transition(.opacity)
                }
                
                if showingShareArrowPointer {
                  ShareSheetPointerView()
                    .transition(.opacity)
                }
            }
        )
    }
}

#Preview {
    MeetingSearchSheetView(
        viewModel: MeepViewModel(),
        isSearchActive: .constant(false),
        onDismiss: { print("Back button tapped") },
        onDone: { print("Done tapped") }
    )
}


