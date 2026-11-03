//
//  LocationSearchViewModel.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/3/26.
//

import Foundation
import Combine

@MainActor
final class LocationSearchViewModel: ObservableObject {
    enum SearchState {
        case idle
        case loading
        case results([GeocodedLocation])
        case empty
        case failed(String)
    }
    
    @Published private(set) var state: SearchState = .idle
    
    @Published private(set) var selectedLocation: GeocodedLocation?
    
    private let geocodingService: any GeocodingServiceProtocol
    
    private var searchTask: Task<Void, Never>?
    
    private let debounceDuration: Duration = .milliseconds(350)
    
    init(geocodingService: any GeocodingServiceProtocol) {
        self.geocodingService = geocodingService
    }
    
    func search(
        query: String,
        debounce: Bool = true
    ) {
        /// Cancel the previous search
        searchTask?.cancel()
        
        selectedLocation = nil
        
        let searchTerm = query.trimmingCharacters(in: .whitespacesAndNewlines
        )
        
        /// Don't search for empty or one-character queries.
        guard searchTerm.count >= 2 else {
            state = .idle
            return
        }
        
        state = .loading
        
        searchTask = Task {
            do {
                /// Wait for the user to finish typing
                if debounce {
                    try await Task.sleep(
                        for: debounceDuration
                    )
                }
                
                /// Stop if this task has been cancelled
                try Task.checkCancellation()
                
                let locations = try await geocodingService.searchLocations(
                    matching: searchTerm
                )
                
                /// Prevent older requests from updating the UI
                guard !Task.isCancelled else {
                    return
                }
                
                if locations.isEmpty {
                    state = .empty
                }
                else {
                    state = .results(locations)
                }
                
            } catch is CancellationError {
                /// Cancellation is expected when a newer query arrives
                return
                
            } catch {
                guard !Task.isCancelled else {
                    /// Ignore errors from cancelled searches
                    return
                }
                
                state = .failed(error.localizedDescription)
            }
        }
    }
    
    func retrySearch(query: String) {
        search(
            query: query,
            debounce: false
        )
    }
    
    func selectedLocation(_ location: GeocodedLocation) {
        selectedLocation = location
    }
}

