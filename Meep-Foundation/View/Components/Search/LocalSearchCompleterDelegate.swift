//
//  LocalSearchCompleterDelegate.swift
//  Meep-Foundation
//
//  Created by Chima onyekwere on 2/1/25.
//

import SwiftUI
import CoreLocation
import MapKit

class LocalSearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    @Published var completions: [MKLocalSearchCompletion] = []
    @Published var isLoading: Bool = false
    private var debounceWorkItem: DispatchWorkItem?
    private var completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func updateQuery(_ query: String) {
        isLoading = true
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.completer.queryFragment = query
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.completions = Array(completer.results.prefix(10))
            self.isLoading = false
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
}
