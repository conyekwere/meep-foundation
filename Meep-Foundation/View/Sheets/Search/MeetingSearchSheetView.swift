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

struct MeetingSearchSheetView: View {
    
    // MARK: - Dependencies
    @ObservedObject var viewModel: MeepViewModel
    @StateObject private var firebaseService = FirebaseService.shared
    @ObservedObject private var locationsManager = UserLocationsManager.shared
    @EnvironmentObject private var onboardingManager: OnboardingManager
    @Binding var isSearchActive: Bool
    
    // MARK: - Location State
    @State private var myLocation: String = ""
    @State private var friendLocation: String = ""
    @State private var isMyLocationValid: Bool = false
    @State private var isFriendsLocationValid: Bool = false
    @State private var myLocationHistory: [String] = []
    @State private var friendLocationHistory: [String] = []
    @State private var locationHistoryText: String = ""
    @State private var locationToSave = ""
    @State private var tempCoordinate: CLLocationCoordinate2D? = nil
    
    // MARK: - Geocode Error State
    @State private var geocodeError: String? = nil
    @State private var showGeocodeErrorAlert: Bool = false
    
    // MARK: - Transport State
    @State private var selectedMyTransport: TransportMode? = nil
    @State private var selectedFriendTransport: TransportMode? = nil
    @State private var friendTransportManuallyChanged: Bool = false
    
    // MARK: - Focus State
    @FocusState private var isMyLocationFocused: Bool
    @FocusState private var isFriendsLocationFocused: Bool
    
    // MARK: - Search State
    @StateObject private var mySearchCompleter = LocalSearchCompleterDelegate()
    @StateObject private var friendSearchCompleter = LocalSearchCompleterDelegate()
    @State private var myDebounceWorkItem: DispatchWorkItem? = nil
    @State private var friendDebounceWorkItem: DispatchWorkItem? = nil
    @State private var didSelectMySuggestion = false
    @State private var didSelectFriendSuggestion = false
    
    // MARK: - Geocoding State
    @State private var isGeocodingInProgress = false
    @State private var geocodingQueue = 0
    
    // MARK: - Sheet State
    @State private var showSaveLocationSheet = false
    @State private var showCustomLocationsSheet = false
    @State private var showAddHomeAddressSheet = false
    @State private var showAddWorkAddressSheet = false
    @State private var showAddCustomAddressSheet = false
    @State private var showContactPermissionAlert = false
    
    // MARK: - UI State
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardShow: Bool = false
    @State private var isShowingContactPicker = false
    @State private var selectedContact: CNContact? = nil
    @State private var showingContactArrowPointer = false
    @State private var showingShareArrowPointer = false
    @State private var arrowOffsetY: CGFloat = 0
    @State private var longPressTimer: Timer? = nil
    
    // MARK: - Completion Handlers
    var onDismiss: () -> Void
    var onDone: () -> Void
    
    // MARK: - Helper Methods
    func areFieldsEmpty() -> Bool {
        return myLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               friendLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handleDoneButtonTap() {
        if isMyLocationValid && isFriendsLocationValid &&
           viewModel.userLocation != nil && viewModel.friendLocation != nil {
            processBothLocations {
                onDone()
            }
        }
    }
    
    private func handleMyLocationLongPress() {
        guard isMyLocationValid && !myLocation.isEmpty else { return }
        
        locationToSave = myLocation
        viewModel.geocodeAddress(myLocation) { coordinate in
            if let coordinate = coordinate {
                tempCoordinate = coordinate
                showSaveLocationSheet = true
            }
        }
    }

    private func handleFriendLocationLongPress() {
        guard isFriendsLocationValid && !friendLocation.isEmpty else { return }
        
        locationToSave = friendLocation
        viewModel.geocodeAddress(friendLocation) { coordinate in
            if let coordinate = coordinate {
                tempCoordinate = coordinate
                showSaveLocationSheet = true
            }
        }
    }
    
    private func handleMyLocationGeocoding(_ completion: MKLocalSearchCompletion) {
        LocationHelpers.geocodeCompletion(completion) { coordinate, formattedAddress in
            DispatchQueue.main.async {
                if let coordinate = coordinate {
                    self.viewModel.userLocation = coordinate
                    self.isMyLocationValid = true
                }

                if let formattedAddress = formattedAddress {
                    self.myLocation = formattedAddress
                }
            }
        }
    }

    private func handleFriendLocationGeocoding(_ completion: MKLocalSearchCompletion) {
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
    }

    private func handleMyLocationSelected() {
        isMyLocationFocused = false
        isFriendsLocationFocused = true
        isMyLocationValid = true
    }

    private func handleFriendLocationSelected() {
        isFriendsLocationFocused = false
        isFriendsLocationValid = true
    }
    
    private func handleCurrentLocationRequest() {
        viewModel.requestUserLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let userCoord = viewModel.userLocation else { return }

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
                    }
                } else {
                    DispatchQueue.main.async {
                        let fallback = String(format: "%.4f, %.4f", userCoord.latitude, userCoord.longitude)
                        self.myLocation = fallback
                        self.isMyLocationValid = true
                        self.viewModel.userLocation = userCoord
                    }
                }
            }
        }
    }
    
    // MARK: - Contact Permission and Share Flow
    private func requestContactAccess(completion: @escaping (Bool) -> Void) {
        let contactStore = CNContactStore()
        
        // Check current authorization status
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        switch status {
        case .authorized:
            // Already have permission, proceed directly
            completion(true)
            
        case .denied, .restricted:
            // Permission was denied, show an alert
            showContactPermissionDeniedAlert()
            completion(false)
            
        case .notDetermined:
            // Show the arrow pointer for the permission dialog
            showingContactArrowPointer = true
            
            // Request permission
            contactStore.requestAccess(for: .contacts) { granted, error in
                DispatchQueue.main.async {
                    // Hide the contact arrow pointer
                    self.showingContactArrowPointer = false
                    
                    if granted {
                        // Wait a moment before showing share sheet pointer
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            completion(true)
                        }
                    } else {
                        completion(false)
                    }
                }
            }
            
        @unknown default:
            completion(false)
        }
    }
    
    private func showContactPermissionDeniedAlert() {
        showContactPermissionAlert = true
    }

    func presentShareSheet() {
        // Generate the request data
        let fullName = firebaseService.meepUser?.displayName ??
                       UserDefaults.standard.string(forKey: "userName") ?? "User"
        let firstName = fullName.components(separatedBy: " ").first ?? fullName
        let userId = firebaseService.currentUser?.uid ??
                     UserDefaults.standard.string(forKey: "userId") ?? UUID().uuidString
        let requestID = UUID().uuidString
        
        // Create deep link URL
        var components = URLComponents()
        components.scheme = "https"
        components.host = "aasa.meep.earth"
        components.path = "/share"
        components.queryItems = [
            URLQueryItem(name: "requestID", value: requestID),
            URLQueryItem(name: "userName", value: fullName),
            URLQueryItem(name: "username", value: firstName),
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "profileImageUrl", value: firebaseService.meepUser?.profileImageUrl ?? "")
        ]
        
        guard let url = components.url else {
            print("Failed to create URL")
            showingShareArrowPointer = false
            return
        }
        
        // Create message
        let message = "\(firstName) wants to figure out where to meet."
        
        // Find the top-most presented controller to present on
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Could not find root view controller")
            showingShareArrowPointer = false
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
        
        // Set completion handler before presenting
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            // Hide the share arrow pointer when share sheet is dismissed
            DispatchQueue.main.async {
                withAnimation {
                    self.showingShareArrowPointer = false
                }
                
                // If sharing was completed successfully, save the request
                if completed {
                    self.saveLocationRequest(
                        requestID: requestID,
                        contactName: "Friend",
                        contactId: nil
                    )
                }
            }
        }
        
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
            topController.present(activityVC, animated: true)
        }
    }
    
    private func saveLocationRequest(requestID: String, contactName: String, contactId: String?) {
        // Extract full name and first name
        let fullName = firebaseService.meepUser?.displayName ?? UserDefaults.standard.string(forKey: "userName") ?? "user name"
        let firstName = fullName.components(separatedBy: " ").first ?? fullName
        let requestData: [String: Any] = [
            "requestID": requestID,
            "userID": firebaseService.currentUser?.uid ?? UserDefaults.standard.string(forKey: "userId") ?? UUID().uuidString,
            "userName": fullName,
            "username": firstName,
            "contactName": contactName,
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
    
    // MARK: - Refactored processBothLocations Methods
    private func processBothLocations(completion: @escaping () -> Void) {
        geocodeMyLocationIfNeeded {
            self.geocodeFriendLocationIfNeeded {
                self.finalizeAndSearch(completion: completion)
            }
        }
    }

    private func geocodeMyLocationIfNeeded(completion: @escaping () -> Void) {
        guard viewModel.userLocation == nil else {
            completion()
            return
        }
        
        LocationHelpers.cancelGeocoding()
        LocationHelpers.geocodeAddress(myLocation) { coordinate, _ in
            guard let userCoord = coordinate else {
                self.geocodeError = "Failed to find your location. Please try again."
                self.showGeocodeErrorAlert = true
                completion()
                return
            }
            
            DispatchQueue.main.async {
                self.viewModel.userLocation = userCoord
                completion()
            }
        }
    }

    private func geocodeFriendLocationIfNeeded(completion: @escaping () -> Void) {
        guard viewModel.friendLocation == nil else {
            completion()
            return
        }
        
        LocationHelpers.cancelGeocoding()
        LocationHelpers.geocodeAddress(friendLocation) { coordinate, _ in
            guard let friendCoord = coordinate else {
                self.geocodeError = "Failed to find your friend's location. Please try again."
                self.showGeocodeErrorAlert = true
                completion()
                return
            }
            
            DispatchQueue.main.async {
                self.viewModel.friendLocation = friendCoord
                completion()
            }
        }
    }

    private func finalizeAndSearch(completion: @escaping () -> Void) {
        // Update the shareable strings with the actual addresses
        viewModel.sharableUserLocation = myLocation
        viewModel.sharableFriendLocation = friendLocation
        
        // Update location history
        updateLocationHistory()
        
        // Then proceed with the rest
        viewModel.reverseGeocodeUserLocation()
        viewModel.reverseGeocodeFriendLocation()
        viewModel.searchNearbyPlaces()
        completion()
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
            LocationHelpers.cancelGeocoding()
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
    
    // MARK: - UI Components
    private var navigationToolbar: some ToolbarContent {
        Group {
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
                let isReadyToSearch = isMyLocationValid && isFriendsLocationValid &&
                                      viewModel.userLocation != nil && viewModel.friendLocation != nil

                Button(action: handleDoneButtonTap) {
                    Text(isGeocodingInProgress ? "Loading..." : "Done")
                        .foregroundColor(isReadyToSearch && !isGeocodingInProgress ? .primary : .gray)
                }
                .disabled(!isReadyToSearch || isGeocodingInProgress)
            }
        }
    }
    
    @ViewBuilder
    private var locationInputSection: some View {
        VStack(spacing: 0) {
            // "My Location" Input Row
            SearchTextFieldRow(
                leadingIcon: "dot.square.fill",
                title: "My Location",
                placeholder: "What's your location?",
                text: $myLocation,
                isDirty: !myLocation.isEmpty,
                selectedMode: $selectedMyTransport,
                isValid: !myLocation.isEmpty ? isMyLocationValid : nil
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
                handleMyLocationLongPress()
            }
            
            // "Friend's Location" Input Row
            SearchTextFieldRow(
                leadingIcon: "dot.square.fill",
                title: "Friend's Location",
                placeholder: "What's your friend's location?",
                text: $friendLocation,
                isDirty: !friendLocation.isEmpty,
                selectedMode: $selectedFriendTransport,
                isValid: !friendLocation.isEmpty ? isFriendsLocationValid : nil
            )
            .focused($isFriendsLocationFocused)
            .onSubmit { isFriendsLocationFocused = false }
            .onLongPressGesture(minimumDuration: 0.5) {
                handleFriendLocationLongPress()
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(#colorLiteral(red: 0.971, green: 0.971, blue: 0.971, alpha: 1)), lineWidth: 2)
        )
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var autocompleteSuggestionsView: some View {
        if myLocation.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 && isMyLocationFocused && !mySearchCompleter.completions.isEmpty {
            
            AutocompleteSuggestionsView(
                completions: mySearchCompleter.completions,
                text: $myLocation,
                didSelectSuggestion: $didSelectMySuggestion,
                geocodeAddress: handleMyLocationGeocoding,
                onSuggestionSelected: handleMyLocationSelected
            )
        } else if friendLocation.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 && isFriendsLocationFocused && !friendSearchCompleter.completions.isEmpty {
            AutocompleteSuggestionsView(
                completions: friendSearchCompleter.completions,
                text: $friendLocation,
                didSelectSuggestion: $didSelectFriendSuggestion,
                geocodeAddress: handleFriendLocationGeocoding,
                onSuggestionSelected: handleFriendLocationSelected
            )
        } else {
            suggestionButtonsSection
        }
    }
    
    @ViewBuilder
    private var suggestionButtonsSection: some View {
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
                    
//                    SuggestionButton(
//                        icon: "plus",
//                        title: "Add another friend",
//                        label: "More friends?",
//                        action: { print("Add friend tapped") }
//                    )
//
//                    SuggestionButton(
//                        icon: "text.badge.plus",
//                        title: "Add contacts",
//                        label: "Searching for friends?",
//                        action: { print("Add contacts tapped") }
//                    )
//
//                    SuggestionButton(
//                        icon: "person.circle",
//                        title: "Set location",
//                        label: "Close Friend",
//                        action: { print("Close friend tapped") }
//                    )
                    
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
        .padding(.top, isFriendsLocationFocused ? -10 : 40)
        .scrollTargetLayout()
        .safeAreaPadding(.trailing, 16)
        .scrollIndicators(.hidden)
        .scrollClipDisabled(true)
    }
    
    @ViewBuilder
    private var additionalOptionsSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 40) {
                if isMyLocationFocused {
                    // Current Location Button when My Location is focused
                    Button(action: handleCurrentLocationRequest) {
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
//                Button(action: {
//                    requestContactAccess { granted in
//                        if granted {
//                            // Show share sheet pointer and present share sheet
//                            withAnimation {
//                                self.showingShareArrowPointer = true
//                            }
//                            self.presentShareSheet()
//                        }
//                    }
//                }) {
//                    HStack(spacing: 16) {
//                        Image(systemName: "message")
//                            .font(.callout)
//                            .foregroundColor(.blue)
//                            .frame(width: 40, height: 40)
//                            .background(Color(hex: "E8F0FE"))
//                            .clipShape(Circle())
//
//                        VStack(alignment: .leading) {
//                            Text("Ask for a Friend's Location")
//                                .foregroundColor(.primary)
//                                .font(.body)
//                            Text("Exact coordinates are hidden")
//                                .font(.callout)
//                                .foregroundColor(Color(.darkGray))
//                                .lineLimit(1)
//                        }
//                    }
//                    .padding(.horizontal, 16)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                }
                
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
                locationHistorySection
            }
        }
        .scrollClipDisabled(true)
        .padding(.top, 40)
    }
    
    @ViewBuilder
    private var locationHistorySection: some View {
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
            .padding(.top, onboardingManager.shouldShowOnboardingElement() ? -36 : 0)
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
            .padding(.top, onboardingManager.shouldShowOnboardingElement() ? -36 : 0)
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
            .padding(.top, onboardingManager.shouldShowOnboardingElement() ? -36 : 0)
        }
    }
    
    // MARK: - Main Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Input Section
                locationInputSection
                    .padding(.top, isKeyboardShow ? 60 : 0)
                // MARK: Main Content Section
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 0) {
                            // MARK: Autocomplete Section (Only shows when typing)
                            autocompleteSuggestionsView
                            
                            // MARK: Additional Options Section
                            additionalOptionsSection
                        }
                    }
                }
                
                Spacer().frame(height: keyboardHeight)
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
            .toolbar { navigationToolbar }
            .onAppear {
                setupInitialState()
            }
            .onChange(of: myLocation) { newValue in
                handleMyLocationChange(newValue)
            }
            .onChange(of: friendLocation) { newValue in
                handleFriendLocationChange(newValue)
            }
            .onChange(of: selectedMyTransport) { newValue in
                handleMyTransportChange(newValue)
            }
            .onChange(of: selectedFriendTransport) { newValue in
                handleFriendTransportChange(newValue)
            }
            .sheet(isPresented: $showSaveLocationSheet) {
                saveLocationSheet
            }
            .fullScreenCover(isPresented: $showCustomLocationsSheet) {
                customLocationSheet
            }
            .fullScreenCover(isPresented: $showAddHomeAddressSheet) {
                homeAddressSheet
            }
            .fullScreenCover(isPresented: $showAddWorkAddressSheet) {
                workAddressSheet
            }
            .fullScreenCover(isPresented: $showAddCustomAddressSheet) {
                customAddressSheet
            }
            .alert("Contacts Permission Required", isPresented: $showContactPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable contacts access in Settings to share your location request with friends.")
            }
            .alert("Geocoding Failed", isPresented: $showGeocodeErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(geocodeError ?? "Unable to find location.")
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
    
    // MARK: - Setup and Event Handlers
    private func setupInitialState() {
        viewModel.requestUserLocation()
        setupKeyboardObservers()
        setupInitialLocation()
        setupSearchCompleters()
        loadLocationHistory()
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation {
                    keyboardHeight = UIScreen.main.bounds.height - frame.origin.y
                    isKeyboardShow = true
                }
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            withAnimation {
                keyboardHeight = 0
                isKeyboardShow = false
            }
        }
    }
    
    private func setupInitialLocation() {
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
        
        // Setup existing locations if available
        if let userLoc = viewModel.userLocation {
            setupUserLocation(userLoc)
        }
        
        if let friendLoc = viewModel.friendLocation {
            setupFriendLocation(friendLoc)
        }
    }
    
    private func setupUserLocation(_ userLoc: CLLocationCoordinate2D) {
        if myLocation.isEmpty || myLocation.contains(",") {
            let formattedCoords = LocationHelpers.formatCoordinates(userLoc)
            LocationHelpers.geocodeAddress(formattedCoords) { _, formattedAddress in
                DispatchQueue.main.async {
                    if let address = formattedAddress {
                        self.myLocation = address
                        self.isMyLocationValid = true
                        
                        if self.friendLocation.isEmpty {
                            self.isFriendsLocationFocused = true
                        }
                    } else {
                        if self.myLocation.isEmpty {
                            self.myLocation = formattedCoords
                            self.isMyLocationFocused = true
                        }
                    }
                }
            }
        }
    }
    
    private func setupFriendLocation(_ friendLoc: CLLocationCoordinate2D) {
        if friendLocation.isEmpty || friendLocation.contains(",") {
            let formattedCoords = LocationHelpers.formatCoordinates(friendLoc)
            LocationHelpers.geocodeAddress(formattedCoords) { _, formattedAddress in
                DispatchQueue.main.async {
                    if let address = formattedAddress {
                        self.friendLocation = address
                        self.isFriendsLocationValid = true
                    } else {
                        if self.friendLocation.isEmpty {
                            self.friendLocation = formattedCoords
                        }
                    }
                }
            }
        } else {
            isFriendsLocationValid = true
        }
    }
    
    private func setupSearchCompleters() {
        mySearchCompleter.updateQuery(myLocation)
        friendSearchCompleter.updateQuery(friendLocation)
    }
    
    private func loadLocationHistory() {
        myLocationHistory = LocationHistoryManager.shared.getLocationHistory(isMyLocation: true)
        friendLocationHistory = LocationHistoryManager.shared.getLocationHistory(isMyLocation: false)
        locationHistoryText = LocationHistoryManager.shared.getCombinedHistoryText()
    }
    
    private func handleMyLocationChange(_ newValue: String) {
        // Skip processing if this change was due to a suggestion selection
        if didSelectMySuggestion {
            didSelectMySuggestion = false
            return
        }
        
        myDebounceWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            mySearchCompleter.updateQuery(newValue)
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
                            self.geocodingCompleted()
                        }
                    }
                }
            } else {
                isMyLocationValid = validateAddress(newValue, using: mySearchCompleter)
                if isMyLocationValid && viewModel.userLocation == nil {
                    geocodeIfNeeded(newValue, isMyLocation: true)
                }
            }
        }
        myDebounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    private func handleFriendLocationChange(_ newValue: String) {
        // Skip processing if this change was due to a suggestion selection
        if didSelectFriendSuggestion {
            didSelectFriendSuggestion = false
            return
        }
        
        friendDebounceWorkItem?.cancel()
        let workItem = DispatchWorkItem {
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
                isFriendsLocationValid = validateAddress(newValue, using: friendSearchCompleter)
                if isFriendsLocationValid && viewModel.friendLocation == nil {
                    geocodeIfNeeded(newValue, isMyLocation: false)
                }
            }
        }
        friendDebounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    private func handleMyTransportChange(_ newValue: TransportMode?) {
        if !friendTransportManuallyChanged {
            selectedFriendTransport = newValue
        }
    }
    
    private func handleFriendTransportChange(_ newValue: TransportMode?) {
        if newValue != selectedMyTransport {
            friendTransportManuallyChanged = true
        } else {
            friendTransportManuallyChanged = false
        }
    }
    
    // MARK: - Sheet Views
    @ViewBuilder
    private var saveLocationSheet: some View {
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
    
    @ViewBuilder
    private var customLocationSheet: some View {
        CustomLocationSheet(
            isPresented: $showCustomLocationsSheet,
            onLocationSelected: { location in
                if isMyLocationFocused {
                    myLocation = location.address
                    isMyLocationValid = true
                    viewModel.userLocation = location.coordinate
                    
                    isMyLocationFocused = false
                    isFriendsLocationFocused = true
                } else if isFriendsLocationFocused {
                    friendLocation = location.address
                    isFriendsLocationValid = true
                    viewModel.friendLocation = location.coordinate
                    
                    isFriendsLocationFocused = false
                }
            }
        )
    }
    
    @ViewBuilder
    private var homeAddressSheet: some View {
        AddressInputView(
            viewModel: viewModel,
            addressType: .home
        ) { savedLocation in
            handleSavedLocation(savedLocation)
        }
    }
    
    @ViewBuilder
    private var workAddressSheet: some View {
        AddressInputView(
            viewModel: viewModel,
            addressType: .work
        ) { savedLocation in
            handleSavedLocation(savedLocation)
        }
    }
    
    @ViewBuilder
    private var customAddressSheet: some View {
        AddressInputView(
            viewModel: viewModel,
            addressType: .custom
        ) { savedLocation in
            handleSavedLocation(savedLocation)
        }
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

