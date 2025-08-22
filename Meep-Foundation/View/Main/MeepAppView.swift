//
//  MeepAppView.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 1/21/25.
//


import SwiftUI
import MapKit
import PostHog

enum UIState {
    case onboarding, searching, results, floatviingResults
}

struct MeepAppView: View {
    @State private var showLocationPrivacyDisclosure: Bool = false
    @StateObject private var subwayOverlayManager = OptimizedSubwayMapManager()
    
    @StateObject private var viewModel = MeepViewModel()

    @State private var showErrorModal: Bool = false
    @AppStorage("lastDirectedVenueName") private var lastDirectedVenueName: String?
    @AppStorage("lastDirectedVenueID") private var lastDirectedVenueID: String?
    @AppStorage("lastDirectedVenueEmoji") private var lastDirectedVenueEmoji: String = ""
    @AppStorage("lastDirectedTimestamp") private var lastDirectedTimestamp: Double?
    @AppStorage("firstLaunchTimestamp") private var firstLaunchTimestamp: Double = 0
    @AppStorage("firstCalculationTimestamp") private var firstCalculationTimestamp: Double?
    @State private var showMeetingConfirmationModal: Bool = false
    
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
    
    @State private var currentToast: TransitFallbackToast?
    
    @State private var toastDismissTimer: Timer? = nil
    @State private var showLocationDisclosure: Bool = false

    // Loading overlay state
    @State private var isLoading: Bool = false
    
    @State private var loadingMessage: String = "Loading..."
    
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
    

    var activeMapAnnotations: [MeepAnnotation] {
            var results: [MeepAnnotation] = []
            
            // Make sure this only adds ONE midpoint annotation
        
//            if viewModel.userLocation != nil && viewModel.friendLocation != nil {
//                results.append(MeepAnnotation(
//                    coordinate: viewModel.enhancedMidpoint,
//                    title: viewModel.midpointTitle,
//                    type: .midpoint
//                ))
//            }
        
//
        if viewModel.userLocation != nil && viewModel.friendLocation != nil {
            results.append(MeepAnnotation(
                coordinate: viewModel.realTransitMidpoint, // ✅ Use the real transit midpoint
                title: viewModel.midpointTitle,
                type: .midpoint
            ))
        }
//
        
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
        print("   - Midpoint: \(viewModel.enhancedMidpoint)")
        
        if let manager = viewModel.subwayManager {
            let userRoutes = manager.getHelpfulSubwayRoutesToward(midpoint: viewModel.enhancedMidpoint, from: viewModel.userLocation ?? CLLocationCoordinate2D())
            let friendRoutes = manager.getHelpfulSubwayRoutesToward(midpoint: viewModel.enhancedMidpoint, from: viewModel.friendLocation ?? CLLocationCoordinate2D())
            print("   - User routes: \(userRoutes.count)")
            print("   - Friend routes: \(friendRoutes.count)")
        }
        print("=========================")
    }


    
    private func handleSubwayDataLoad() {
        print("🚇 handleSubwayDataLoad called:")
        print("   - hasLoadedData: \(subwayOverlayManager.hasLoadedData)")
        print("   - myTransit: \(myTransit), friendTransit: \(friendTransit)")
        guard subwayOverlayManager.hasLoadedData,
              (myTransit == .train || friendTransit == .train),
              let userLoc = viewModel.userLocation,
              let friendLoc = viewModel.friendLocation,
              uiState == .results else { return }
        
        let midpoint = viewModel.enhancedMidpoint
        print("🎯 Checking subway viability to midpoint: \(midpoint)")
        
        // 1) Run the special-case connectivity analysis first:
        let connectivityAnalysis = subwayOverlayManager.analyzeSubwayConnectivity(
            userLocation: userLoc,
            friendLocation: friendLoc,
            midpoint: midpoint
        )
        
        var didFallback = false
        var fallbackMessage = ""
        
        // If the analysis says “not viable” (e.g. East ⇄ West Harlem), fallback immediately:
        if myTransit == .train && !connectivityAnalysis.userViable {
            print("⚠️ Crosstown inefficiency detected: \(connectivityAnalysis.reason)")
            myTransit = .walk
            viewModel.userTransportMode = .walk
            didFallback = true
            fallbackMessage = connectivityAnalysis.reason
        }
        if friendTransit == .train && !connectivityAnalysis.friendViable {
            print("⚠️ Crosstown inefficiency detected for friend: \(connectivityAnalysis.reason)")
            friendTransit = .walk
            viewModel.friendTransportMode = .walk
            if !didFallback {
                didFallback = true
                fallbackMessage = connectivityAnalysis.reason
            }
        }
        
        // 2) Only if no special-case ran, fall back on “zero real routes”:
        if !didFallback {
            let userRoutes   = subwayOverlayManager.getHelpfulSubwayRoutesToward(midpoint: midpoint, from: userLoc)
            let friendRoutes = subwayOverlayManager.getHelpfulSubwayRoutesToward(midpoint: midpoint, from: friendLoc)
            print("📊 Found routes – User: \(userRoutes.count), Friend: \(friendRoutes.count)")
            
            if myTransit == .train && userRoutes.isEmpty {
                print("⚠️ No routes from user – fallback")
                myTransit = .walk
                viewModel.userTransportMode = .walk
                didFallback = true
                fallbackMessage = "No direct subway from your location"
            }
            if friendTransit == .train && friendRoutes.isEmpty {
                print("⚠️ No routes from friend – fallback")
                friendTransit = .walk
                viewModel.friendTransportMode = .walk
                if !didFallback {
                    didFallback = true
                    fallbackMessage = "No direct subway from friend's location"
                }
            }
        }
        
        // 3) Show toast if anything fell back
        if didFallback {
            print("🚨 Triggering fallback toast: \(fallbackMessage)")
            currentToast = TransitFallbackToast.create(for: fallbackMessage)
            self.showTransitFallbackToast = true
            toastDismissTimer?.invalidate()
            toastDismissTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    showTransitFallbackToast = false
                    currentToast = nil
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.searchNearbyPlaces()
            }
        }
    }

    // Update the loadSubwayDataIfNeeded function to skip if already loaded

    private func loadSubwayDataIfNeeded() {
        print("🔄 loadSubwayDataIfNeeded called")
        print("   - Transit modes: user=\(myTransit), friend=\(friendTransit)")
        print("   - Locations: user=\(viewModel.userLocation != nil), friend=\(viewModel.friendLocation != nil)")
        print("   - UI state: \(uiState)")
        print("   - Subway data already loaded: \(subwayOverlayManager.hasLoadedData)")
        loadingMessage = "Loading subway data..."
        // Skip if subway data is already loaded
        if subwayOverlayManager.hasLoadedData {
            print("✅ Subway data already loaded, triggering fallback check immediately")
            handleSubwayDataLoad()
            return
        }

        guard (myTransit == .train || friendTransit == .train),
              viewModel.userLocation != nil,
              viewModel.friendLocation != nil,
              uiState == .results else {
            print("❌ Subway data not needed")
            return
        }

        // Connect subway manager once
        if viewModel.subwayManager == nil {
            viewModel.subwayManager = subwayOverlayManager
        }

        print("📡 Loading subway data...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if !subwayOverlayManager.hasLoadedData {
                isLoading = true
                loadingMessage = "Loading subway data..."
            }
        }

        subwayOverlayManager.loadSubwayData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
        }
    }
    

    
    
    private
    func clearAnnotations() {
        viewModel.searchResults.removeAll()
        viewModel.meetingPoints.removeAll()
        viewModel.userLocation = nil
        viewModel.friendLocation = nil
    }
    
    private func setSelectedMeetingPoint(for annotation: MeepAnnotation) {
        PostHogSDK.shared.capture("venue_selected", properties: [
            "venue_name": annotation.title,
            "venue_category": viewModel.getCategory(for: annotation.type.emoji),
            "venue_emoji": annotation.type.emoji
        ])
        
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
            
     
            loadingMessage = "Finding meeting spots..."
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
    
    

    // Computed property for transit fallback toast view
    private var transitFallbackToastView: some View {
        TransitFallbackToastView(
            toast: currentToast ?? TransitFallbackToast.create(for: ""),
            isVisible: showTransitFallbackToast && currentToast != nil,
            onDismiss: {
                withAnimation(.easeOut(duration: 0.3)) {
                    showTransitFallbackToast = false
                    currentToast = nil
                }
                toastDismissTimer?.invalidate()
            }
        )
    }

    var body: some View {

        ZStack {

            // Loading overlay
            if isLoading {
                Group {
                    switch loadingMessage {
                    case "Finding meeting spots...":
                        MeepLoadingStateView.findingMeetingSpots()
                    case "Loading subway data...":
                        MeepLoadingStateView.loadingSubwayData()
                    default:
                        MeepLoadingStateView(
                            title: loadingMessage,
                            subtitle: nil,
                            progressSteps: ["Processing..."]
                            
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.thinMaterial)
                .transition(.opacity)
                .zIndex(10)
            }


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
            .blur(radius: (uiState == .onboarding || uiState == .results) && (showTransitFallbackToast || viewModel.isFloatingCardVisible) ? 4 : 0)
           .gesture(
                DragGesture()
                    .onChanged { _ in viewModel.isUserInteractingWithMap = true }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            viewModel.isUserInteractingWithMap = false
                            viewModel.searchNearbyPlaces()
                        }
                    }
            )
            
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
            
//            if showLocationDisclosure {
//                LocationPrivacyDisclosureView(showDisclosure: $showLocationDisclosure) {
//                    viewModel.getCurrentLocationIfAuthorized()
//                }
//            }
            
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
                if let toast = currentToast {
                    TransitFallbackToastView(toast: toast, isVisible: true) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showTransitFallbackToast = false
                            currentToast = nil
                        }
                        toastDismissTimer?.invalidate()
                    }
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                } else {
                    TransitFallbackToastView(
                        toast: TransitFallbackToast(
                            icon: "exclamationmark.triangle.fill",
                            title: "NYC Only",
                            message: "Meep works best in New York City.",
                            primaryColor: .red,
                            secondaryColor: .orange
                        ),
                        isVisible: true
                    ) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showTransitFallbackToast = false
                        }
                        toastDismissTimer?.invalidate()
                    }
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                }
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
      
      
                    }
                    
                    
                },
                onDone: {
                    isSearching = false
                    isLoading = true
                    loadingMessage = "Finding meeting spots..."
                    uiState = .results

                    viewModel.subwayManager = subwayOverlayManager
                    
                    // Reset midpoint title + midpoint
                    viewModel.resetMidpoint()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        debugSubwayState()
                        loadSubwayDataIfNeeded()
                    }
                    // Refresh locations
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.handleOutOfNYCBehavior(userLoc: viewModel.userLocation, friendLoc: viewModel.friendLocation)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        debugSubwayState()
                        loadSubwayDataIfNeeded()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        loadingMessage = "Loading subway data..."
                     
                    }
                    
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        isLoading = true
                     
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
                viewModel: viewModel,
                onTransitChecker: {
                    
                    if (myTransit == .train || friendTransit == .train),
                          viewModel.userLocation != nil,
                          viewModel.friendLocation != nil
                     {
                        loadSubwayDataIfNeeded()
                    }
                    
                }
            )
            .presentationDetents([.large])
        }
        
        .sheet(isPresented: $showErrorModal) {
            VStack(spacing: 32) {
                Text("⚠️ \(viewModel.sharableUserLocation.isEmpty ? "This location" : viewModel.sharableUserLocation) isn’t supported yet.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    showErrorModal = false
                    if let url = URL(string: "https://tally.so/r/wvbPWd") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Join the Waitlist", systemImage: "envelope.fill")
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
        // Add this to your MeepAppView's .onAppear modifier

        .onAppear {
            viewModel.getCurrentLocationIfAuthorized()
            if firstLaunchTimestamp == 0 {
                firstLaunchTimestamp = Date().timeIntervalSince1970
            }
            if let ts = lastDirectedTimestamp, Date().timeIntervalSince1970 - ts > 86400 {
                lastDirectedVenueName = nil
                lastDirectedVenueID = nil
                lastDirectedVenueEmoji = ""
                lastDirectedTimestamp = nil
            }
            
            let userLoc = viewModel.userLocation
            let friendLoc = viewModel.friendLocation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let strongViewModel = viewModel
                strongViewModel.handleOutOfNYCBehavior(userLoc: userLoc, friendLoc: friendLoc)
            }
            self.searchRadius = viewModel.searchRadius
            
            // Sync transport modes with ViewModel
            self.myTransit = viewModel.userTransportMode
            self.friendTransit = viewModel.friendTransportMode
            
            // Connect subway manager early
            if viewModel.subwayManager == nil {
                viewModel.subwayManager = subwayOverlayManager
            }
            
            // 🚇 PRELOAD SUBWAY DATA ON LAUNCH
            // Since both default to train mode, load subway data immediately
            if !subwayOverlayManager.hasLoadedData {
                print("🚇 Preloading subway data on app launch...")
                
    
                
                // Load the subway data
                subwayOverlayManager.loadSubwayData()
                

            }
            
            if lastDirectedVenueName != nil {
                showMeetingConfirmationModal = true
            }
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
        .overlay(
            Group {
                if showLocationPrivacyDisclosure {
                    LocationPrivacyDisclosureView(showDisclosure: $showLocationPrivacyDisclosure) {
                        viewModel.requestUserLocation()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4).ignoresSafeArea())
                }
            }
        )
        .alert(
            "Did you meet at \(lastDirectedVenueEmoji) \(lastDirectedVenueName ?? "the suggested location")?",
            isPresented: $showMeetingConfirmationModal
        ) {
            Button("Yes") {
                PostHogSDK.shared.capture("meeting_confirmed", properties: [
                    "venue_name": lastDirectedVenueName ?? "",
                    "venue_id": lastDirectedVenueID ?? ""
                ])
                PostHogSDK.shared.capture("place_visited", properties: [
                    "venue_name": lastDirectedVenueName ?? "",
                    "venue_id": lastDirectedVenueID ?? "",
                    "visited_at": Date().timeIntervalSince1970
                ])
                lastDirectedVenueName = nil
                lastDirectedVenueID = nil
                lastDirectedVenueEmoji = ""
                lastDirectedTimestamp = nil
            }
            Button("Remind me later") {
                showMeetingConfirmationModal = false
            }
            Button("No", role: .cancel) {
                lastDirectedVenueName = nil
                lastDirectedVenueID = nil
                lastDirectedVenueEmoji = ""
                lastDirectedTimestamp = nil
            }
        }
    }
    
}


struct MeepAppView_Previews: PreviewProvider {
    static var previews: some View {
        MeepAppView(isNewUser: true)
            .environment(\.colorScheme, .light) // optional: simulate light mode
    }
}
