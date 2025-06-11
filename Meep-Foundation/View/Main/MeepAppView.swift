//
//  MeepAppView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//


import SwiftUI
import MapKit

enum UIState {
    case onboarding, searching, results, floatingResults
}

struct MeepAppView: View {
    
    @StateObject private var subwayOverlayManager = OptimizedSubwayMapManager()
    
    @StateObject private var viewModel = MeepViewModel()

    @State private var showErrorModal: Bool = false
    
    @StateObject private var firebaseService = FirebaseService.shared
    
    var isNewUser: Bool = false
    
    @State private var departureTime: Date? = nil
    @State private var searchRequest: Bool = false
    
    // Overall UI state for top search bars etc.
    @State private var uiState: UIState = .onboarding
    // Separate state variable to control the fullScreenCover presentation.
    @State private var isSearching: Bool = false
    
    // Separate state variable to control the fullScreenCover presentation.
    @State private var isProfilePresented: Bool = false
    @State private var didFallbackToWalking: Bool = true
    
    @State private var isAdvancedFiltersPresented: Bool  = false

    // Toast for transit fallback
    @State private var showTransitFallbackToast: Bool = false
    @State private var toastDismissTimer: Timer? = nil
    
    // Sheet height constants
    private let sheetMin: CGFloat = 90
    private let sheetMid: CGFloat = UIScreen.main.bounds.height * 0.4
    private let sheetMax: CGFloat = UIScreen.main.bounds.height * 0.8

    // Offsets for the draggable sheets along with last offset values
    @State private var onboardingOffset: CGFloat = UIScreen.main.bounds.height * 0.82
    @State private var lastOnboardingDragOffset: CGFloat = UIScreen.main.bounds.height * 0.5

    @State private var meetingResultsOffset: CGFloat = UIScreen.main.bounds.height * 0.82
    @State private var lastMeetingResultsDragOffset: CGFloat = UIScreen.main.bounds.height * 0.82
    
    @State private var myTransit: TransportMode = .train
    @State private var friendTransit: TransportMode = .train
    @State private var searchRadius: Double = 0.25 {
        didSet {
            viewModel.searchRadius = searchRadius
        }
    }
    
    @State private var selectedAnnotation: MeepAnnotation? = nil
    @State private var selectedAnnotationID: UUID?
    
    
    
//    var activeMapAnnotations: [MeepAnnotation] {
//        return viewModel.annotations
//    }
    var activeMapAnnotations: [MeepAnnotation] {
        var results: [MeepAnnotation] = []
        
        // Make sure this only adds ONE midpoint annotation
        if viewModel.userLocation != nil && viewModel.friendLocation != nil {
            results.append(MeepAnnotation(
                coordinate: viewModel.midpoint,
                title: viewModel.midpointTitle,  // This should show subway lines
                type: .midpoint
            ))
        }
        
        // Check if viewModel.annotations also contains a midpoint
        // and avoid duplicating it
        
        if let uLoc = viewModel.userLocation {
            results.append(MeepAnnotation(coordinate: uLoc, title: "You", type: .user))
        }
        if let fLoc = viewModel.friendLocation {
            results.append(MeepAnnotation(coordinate: fLoc, title: "Friend", type: .friend))
        }
        
        results.append(contentsOf: viewModel.searchResults)
        return results
    }
    
    private func debugSubwayState() {
        print("🐛 === SUBWAY DEBUG STATE ===")
        print("   - Subway data loaded: \(subwayOverlayManager.hasLoadedData)")
        print("   - Manager connected: \(viewModel.subwayManager != nil)")
        print("   - User transport: \(myTransit) / VM: \(viewModel.userTransportMode)")
        print("   - Friend transport: \(friendTransit) / VM: \(viewModel.friendTransportMode)")
        print("   - User location: \(viewModel.userLocation?.latitude ?? 0)")
        print("   - Friend location: \(viewModel.friendLocation?.latitude ?? 0)")
        print("   - UI State: \(uiState)")
        print("   - Midpoint: \(viewModel.midpoint)")
        
        if let manager = viewModel.subwayManager {
            let userRoutes = manager.getHelpfulSubwayRoutesToward(midpoint: viewModel.midpoint, from: viewModel.userLocation ?? CLLocationCoordinate2D())
            let friendRoutes = manager.getHelpfulSubwayRoutesToward(midpoint: viewModel.midpoint, from: viewModel.friendLocation ?? CLLocationCoordinate2D())
            print("   - User routes: \(userRoutes.count)")
            print("   - Friend routes: \(friendRoutes.count)")
        }
        print("=========================")
    }

    
    private func handleSubwayDataLoad() {
        print("🚇 handleSubwayDataLoad called:")
        print("   - hasLoadedData: \(subwayOverlayManager.hasLoadedData)")
        print("   - myTransit: \(myTransit), friendTransit: \(friendTransit)")
        print("   - userLocation: \(viewModel.userLocation != nil)")
        print("   - friendLocation: \(viewModel.friendLocation != nil)")
        print("   - uiState: \(uiState)")
        
        // Ensure subway manager is connected FIRST
        viewModel.subwayManager = subwayOverlayManager
        
        guard subwayOverlayManager.hasLoadedData,
              (myTransit == .train || friendTransit == .train),
              let userLoc = viewModel.userLocation,
              let friendLoc = viewModel.friendLocation,
              uiState == .results else {
            print("❌ handleSubwayDataLoad guard failed")
            return
        }

        let midpoint = viewModel.midpoint
        print("🎯 Checking subway routes to midpoint: \(midpoint)")
        // Debug the current detection first
        print("🔍 === USER ROUTE DETECTION ===")
        subwayOverlayManager.debugRouteDetection(midpoint: midpoint, from: userLoc)

        print("🔍 === FRIEND ROUTE DETECTION ===")
        subwayOverlayManager.debugRouteDetection(midpoint: midpoint, from: friendLoc)

        // Use enhanced detection with stricter criteria
        let userRoutes = subwayOverlayManager.getHelpfulSubwayRoutesToward(midpoint: midpoint, from: userLoc)
        let friendRoutes = subwayOverlayManager.getHelpfulSubwayRoutesToward(midpoint: midpoint, from: friendLoc)
        
        print("📊 Found routes - User: \(userRoutes.count), Friend: \(friendRoutes.count)")
        
        var didFallback = false
        var fallbackMessage = ""

        // Check user transit fallback
        if myTransit == .train && userRoutes.isEmpty {
            print("⚠️ No viable subway routes from user location — falling back to walk")
            myTransit = .walk
            viewModel.userTransportMode = .walk
            didFallback = true
            fallbackMessage = "No direct subway from your location"
        }

        // Check friend transit fallback
        if friendTransit == .train && friendRoutes.isEmpty {
            print("⚠️ No viable subway routes from friend location — falling back to walk")
            friendTransit = .walk
            viewModel.friendTransportMode = .walk
            didFallback = true
            
            if fallbackMessage.isEmpty {
                fallbackMessage = "No direct subway from friend's location"
            } else {
                fallbackMessage = "No direct subway routes available"
            }
        }

        // Show fallback toast if needed
        if didFallback {
            print("🚨 Triggering fallback toast: \(fallbackMessage)")
            showTransitFallbackToast = true
            
            // Cancel existing timer
            toastDismissTimer?.invalidate()
            
            // Set new timer
            toastDismissTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    showTransitFallbackToast = false
                }
            }
            
            // Force recalculation with new transport modes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.searchNearbyPlaces()
            }
        }
    }


    // Helper to load subway data if needed
    private func loadSubwayDataIfNeeded() {
        print("🔄 loadSubwayDataIfNeeded called")
        print("   - Transit modes: user=\(myTransit), friend=\(friendTransit)")
        print("   - Locations: user=\(viewModel.userLocation != nil), friend=\(viewModel.friendLocation != nil)")
        print("   - UI state: \(uiState)")
        
        guard (myTransit == .train || friendTransit == .train),
              viewModel.userLocation != nil,
              viewModel.friendLocation != nil,
              uiState == .results else {
            print("❌ Subway data not needed")
            return
        }
        
        // Connect subway manager IMMEDIATELY
        viewModel.subwayManager = subwayOverlayManager
        
        if !subwayOverlayManager.hasLoadedData {
            print("📡 Loading subway data...")
            subwayOverlayManager.loadSubwayData()
        } else {
            print("✅ Subway data already loaded, running fallback check")
            // Data is already loaded, check fallback immediately
            handleSubwayDataLoad()
        }
    }
    
    private func isWithinNYC(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let minLat = 40.4774
        let maxLat = 40.9176
        let minLon = -74.2591
        let maxLon = -73.7002

        return (coordinate.latitude >= minLat && coordinate.latitude <= maxLat) &&
               (coordinate.longitude >= minLon && coordinate.longitude <= maxLon)
    }

    
    
    private
    func clearAnnotations() {
        viewModel.searchResults.removeAll()
        viewModel.meetingPoints.removeAll()
        viewModel.userLocation = nil
        viewModel.friendLocation = nil
    }
    
    private func setSelectedMeetingPoint(for annotation: MeepAnnotation) {
        // Extract emoji from annotation
        let emoji: String
        if case let .place(emojiValue) = annotation.type {
            emoji = emojiValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            emoji = "📍"
        }
        
        // Dynamically get category
        let category = viewModel.getCategory(for: emoji)
        
        // Look for matching meeting point in viewModel's data to get its image URL
        if let existingPoint = viewModel.meetingPoints.first(where: {
            // Match by name and approximate coordinate (within small radius)
            $0.name == annotation.title &&
            abs($0.coordinate.latitude - annotation.coordinate.latitude) < 0.0001 &&
            abs($0.coordinate.longitude - annotation.coordinate.longitude) < 0.0001
        }) {
            // Use the existing point with its real image URL
            viewModel.selectedPoint = existingPoint
            viewModel.isFloatingCardVisible = true
            print("✅ Found existing meeting point: \(existingPoint.name) with image: \(existingPoint.imageUrl)")
        } else {
            // Create a new point with placeholder image
            viewModel.selectedPoint = MeetingPoint(
                name: annotation.title,
                emoji: emoji,
                category: category,
                coordinate: annotation.coordinate,
                imageUrl: "https://via.placeholder.com/400x300?text=Loading+Image"
            )
            viewModel.isFloatingCardVisible = true
            
            // Try to fetch image from Google Places API
            print("🔍 New meeting point - attempting to fetch image for: \(annotation.title)")
            
            // Create a temporary array with just this point
            let tempPoint = viewModel.selectedPoint!
            viewModel.fetchGooglePlacesMetadata(for: [tempPoint])
            
            // After a delay, update the selected point with any new image that was found
            // Using a capture list without 'weak' since MeepAppView is a struct
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [viewModel] in
                // Find the meeting point in the array that matches our selected point
                if let updatedPoint = viewModel.meetingPoints.first(where: {
                    $0.name == tempPoint.name &&
                    abs($0.coordinate.latitude - tempPoint.coordinate.latitude) < 0.0001 &&
                    abs($0.coordinate.longitude - tempPoint.coordinate.longitude) < 0.0001
                }) {
                    // Update our selected point with the new image URL and other metadata
                    viewModel.selectedPoint?.imageUrl = updatedPoint.imageUrl
                    
                    // Also update other metadata if available
                    if let placeID = updatedPoint.googlePlaceID {
                        viewModel.selectedPoint?.googlePlaceID = placeID
                    }
                    
                    if let originalType = updatedPoint.originalPlaceType {
                        viewModel.selectedPoint?.originalPlaceType = originalType
                    }
                    
                    if let hours = updatedPoint.openingHours {
                        viewModel.selectedPoint?.openingHours = hours
                    }
                    
                    print("✅ Updated selected point image to: \(updatedPoint.imageUrl)")
                }
            }
        }
    }
    
    

    var body: some View {
        ZStack {


            let shouldShowSubwayLines = (myTransit == .train || friendTransit == .train) &&
                                       viewModel.userLocation != nil &&
                                       viewModel.friendLocation != nil
            
            let annotationSelectionHandler: (MeepAnnotation) -> Void = { annotation in
                withAnimation(.spring()) {
                    selectedAnnotationID = annotation.id
                    selectedAnnotation = annotation
                    setSelectedMeetingPoint(for: annotation)
                }
            }

            NativeMapView(
                region: $viewModel.mapRegion,
                annotations: activeMapAnnotations,
                showSubwayLines: shouldShowSubwayLines,
                subwayManager: subwayOverlayManager,
                selectedAnnotationID: selectedAnnotationID,
                onAnnotationSelected: annotationSelectionHandler
            )

            .ignoresSafeArea()
//           .gesture(
//                DragGesture()
//                    .onChanged { _ in viewModel.isUserInteractingWithMap = true }
//                    .onEnded { _ in
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                            viewModel.isUserInteractingWithMap = false
//                            viewModel.searchNearbyPlaces()
//                        }
//                    }
//            )
            
            // MARK: Top Search Bars Based on UIState
            VStack {
                if uiState == .results {
                    SearchBarWithAction(
                        title: "\(viewModel.meetingPoints.count) Meeting Points",
                        subtitle: "\(viewModel.sharableUserLocation) · \(viewModel.sharableFriendLocation)",
                        leadingIcon: "chevron.left",
                        trailingIcon: "slider.horizontal.3",
                        isDirty: true,
                        filterCount: viewModel.activeFilterCount, // ✅ Add this to track filter count
                        onLeadingIconTap: { isSearching = true
                            viewModel.activeFilterCount = 0 },
                        onTrailingIconTap: { isAdvancedFiltersPresented.toggle() },
                        onContainerTap: { isSearching = true
                            viewModel.activeFilterCount = 0 }
                    )
                    .padding()
                    .frame(height: 60)
                    .background(Color.white)
                    .cornerRadius(34)
                    .shadow(radius: 16)
                }
                
                if uiState == .onboarding {
                    SearchBarWithAction(
                        title: "Find where to meet",
                        subtitle: "\(viewModel.sharableUserLocation) · \(viewModel.sharableFriendLocation)",
                        leadingIcon: "magnifyingglass",
                        trailingIcon: firebaseService.meepUser?.profileImageUrl ?? "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
                        isDirty: false,
                        filterCount: viewModel.activeFilterCount,
                        onLeadingIconTap: { isSearching = true },
                        onTrailingIconTap: {
                            isProfilePresented.toggle()
                            print("User profile tapped")
                        },
                        onContainerTap: { isSearching = true }
                    )
                    .padding()
                    .frame(height: 60)
                    .background(Color.white)
                    .cornerRadius(34)
                    .shadow(radius: 16)
                }
                Spacer()

            }
            .padding()
            .zIndex(3)
            
            
            
            // MARK: Onboarding Sheet (Draggable)
            if uiState == .onboarding  && !viewModel.isFloatingCardVisible && !showTransitFallbackToast{
                OnboardingSheetView(
                    viewModel: viewModel,
                    isLocationAllowed: $viewModel.isLocationAccessGranted,
                    searchRequest: $searchRequest
                )
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(onboardingOffset == sheetMin ? 0 : 24)
                .shadow(color: Color.black.opacity(0.24),
                        radius: onboardingOffset == sheetMin ? 0 : 30, x: 0, y: 3)
                .offset(y: onboardingOffset)
                .draggableSheet(offset: $onboardingOffset,
                                lastOffset: $lastOnboardingDragOffset,
                                minOffset: sheetMin,
                                midOffset: sheetMid,
                                maxOffset: sheetMax)
                .zIndex(2)
            }
            
            // MARK: Meeting Results Sheet (Draggable)
            if uiState == .results && !viewModel.isFloatingCardVisible && !showTransitFallbackToast {
                MeetingResultsSheetView(viewModel: viewModel)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(meetingResultsOffset == sheetMin ? 0 : 24)
                    .shadow(color: Color.black.opacity(0.24),
                            radius: meetingResultsOffset == sheetMin ? 0 : 30, x: 0, y: 3)
                    .offset(y: meetingResultsOffset)
                    .draggableSheet(offset: $meetingResultsOffset,
                                    lastOffset: $lastMeetingResultsDragOffset,
                                    minOffset: sheetMin,
                                    midOffset: sheetMid,
                                    maxOffset: sheetMax)
                    .zIndex(1)
            }
            
            // MARK: Toast Overlay (transit fallback)
            if showTransitFallbackToast {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "figure.walk.motion")
                            .foregroundColor(.white)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Switched to walking")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .font(.callout)
                            Text("No direct subway routes for this meetup")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.85))
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showTransitFallbackToast)
                .zIndex(10) // Higher z-index to ensure visibility
            }
            
            // MARK: Floating Card for Selected Point
            if let selectedPoint = viewModel.selectedPoint, viewModel.isFloatingCardVisible {
                VStack {
                    Spacer()
                    FloatingCardView(
                        viewModel: viewModel,
                        meetingPoint: selectedPoint,
                        onClose: {
                            withAnimation {
                                viewModel.isFloatingCardVisible = false
                                viewModel.selectedPoint = nil
                                selectedAnnotation = nil
                                uiState = .results
                            }
                        },
                        myTransit: myTransit
                    )
                    .padding(.horizontal, 8)
                    .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 16)
                    .transition(.move(edge: .bottom))
                    .zIndex(3)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        
        // MARK: Full-Screen Search Sheet
        .fullScreenCover(isPresented: $isSearching) {
            MeetingSearchSheetView(
                viewModel: viewModel,
                isSearchActive: .constant(true),
                onDismiss: {
                    isSearching = false
                    
                    // Get a reference to the sheet view to check its text fields
                    let sheetView = MeetingSearchSheetView(
                        viewModel: viewModel,
                        isSearchActive: .constant(true),
                        onDismiss: { },
                        onDone: { }
                    )
                    
                    // Check if both text fields are empty
                    if sheetView.areFieldsEmpty() || viewModel.searchFieldsAreEmpty {
                        uiState = .onboarding

                        // Reset view model locations and shareable strings
                        clearAnnotations()
                        viewModel.sharableUserLocation = "My Location"
                        viewModel.sharableFriendLocation = "Friend's Location"
                        
                    } else {
                        // Maintain the current UI state
                        // This will preserve the results view when returning from search
                        // with existing locations
                    }
                    
                    
                },
                onDone: {
                    isSearching = false
                    uiState = .results
                    
                    viewModel.subwayManager = subwayOverlayManager
                    
                    // Debug the state right after setting it up
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        debugSubwayState()
                    }
                    
                    // Then load subway data
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        loadSubwayDataIfNeeded()
                    }
                }
            )
            .background(Color(.tertiarySystemBackground))
        }
        
        .sheet(isPresented: $isProfilePresented) {
            ProfileBottomSheet(imageUrl: "https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1")
                .presentationDetents([.fraction(0.65)])
                
        }
        
        
        .sheet(isPresented: $isAdvancedFiltersPresented) {
            AdvancedFiltersBottomSheet(
                myTransit: $myTransit,
                friendTransit: $friendTransit,
                searchRadius: $searchRadius,
                departureTime: $departureTime,
                viewModel: viewModel // ✅ Pass ViewModel from Parent
            )
            .presentationDetents([.large])
        }
        
        .sheet(isPresented: $showErrorModal) {
            VStack(spacing: 32) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.red)

                Text("\(viewModel.sharableUserLocation.isEmpty ? "Location" : viewModel.sharableUserLocation) not supported in Beta")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()

                Button(action: {
                    showErrorModal = false
                    if let url = URL(string: "https://tally.so/r/wvbPWd") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Sign up for waitlist")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
            .presentationDetents([.fraction(0.4)])
            .interactiveDismissDisabled()
        }
        .onAppear {
            viewModel.requestUserLocation()
            if let userLocation = viewModel.userLocation, !isWithinNYC(userLocation) {
                showErrorModal = true
            }
            self.searchRadius = viewModel.searchRadius
        }
        .onChange(of: searchRequest) { newValue in
            if newValue {
                isSearching = true
                searchRequest = false
            }
        }
        .onChange(of: myTransit) { newMode in
            print("🔄 myTransit changed to: \(newMode)")
            viewModel.userTransportMode = newMode
            
            // If switching TO train mode, load subway data
            if newMode == .train && !subwayOverlayManager.hasLoadedData {
                loadSubwayDataIfNeeded()
            }
        }

        .onChange(of: friendTransit) { newMode in
            print("🔄 friendTransit changed to: \(newMode)")
            viewModel.friendTransportMode = newMode
            
            // If switching TO train mode, load subway data
            if newMode == .train && !subwayOverlayManager.hasLoadedData {
                loadSubwayDataIfNeeded()
            }
        }

        .onChange(of: subwayOverlayManager.hasLoadedData) { hasLoaded in
            print("🚇 Subway data loaded state changed: \(hasLoaded)")
            if hasLoaded {
                // Add small delay to ensure all state is settled
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    handleSubwayDataLoad()
                }
            }
        }
        
        .onChange(of: viewModel.mapRegion.center.latitude) { _ in
            // Update subway station visibility when map moves
            if subwayOverlayManager.hasLoadedData {
                subwayOverlayManager.updateVisibleElements(for: viewModel.mapRegion)
            }
        }
        .onChange(of: viewModel.mapRegion.center.longitude) { _ in
            // Update subway station visibility when map moves
            if subwayOverlayManager.hasLoadedData {
                subwayOverlayManager.updateVisibleElements(for: viewModel.mapRegion)
            }
        }
        .onChange(of: viewModel.mapRegion.span.latitudeDelta) { _ in
            // Update subway station visibility when zoom changes
            if subwayOverlayManager.hasLoadedData {
                subwayOverlayManager.updateVisibleElements(for: viewModel.mapRegion)
            }
        }
    }
}


#Preview {
    MeepAppView(isNewUser: true)
}


