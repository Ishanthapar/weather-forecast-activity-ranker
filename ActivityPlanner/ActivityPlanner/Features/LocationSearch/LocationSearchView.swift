//
//  LocationSearchView.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/3/26.
//

import Foundation
import SwiftUI

struct LocationSearchView: View {
    @StateObject private var viewModel: LocationSearchViewModel
    @State private var searchQuery = ""
    @FocusState private var isSearchFieldFocused: Bool
    let weatherForecastService: any WeatherForecastServiceProtocol
    let suitabilityScoringEngine: any SuitabilityScoringEngine
    
    init(
        geocodingService: any GeocodingServiceProtocol,
        weatherForecastService: any WeatherForecastServiceProtocol,
        suitabilityScoringEngine: any SuitabilityScoringEngine
    ) {
        self.weatherForecastService = weatherForecastService
        self.suitabilityScoringEngine = suitabilityScoringEngine
        
        _viewModel = StateObject(
            wrappedValue: LocationSearchViewModel(
                geocodingService: geocodingService
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                header
                searchField
                searchContent
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("Activity Planner")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: searchQuery) { _ , newValue in
                viewModel.search(query: newValue)
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where would you like to go?")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(
                "Search for a city or town to explore the weather and suitability of activities over the next seven days."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Search Field
    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search for a city...", text: $searchQuery)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isSearchFieldFocused)
                .accessibilityIdentifier("citySearchField")
            
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear search")
                .accessibilityIdentifier("clearSearch")
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Search Content
    @ViewBuilder
    private var searchContent: some View {
        switch viewModel.state {
        case .idle:
            idleView
            
        case .loading:
            loadingView
            
        case .results(let locations):
            resultsView(locations)
            
        case .empty:
            emptyView
            
        case .failed(let message):
            errorView(message)
        }
    }
    
    // MARK: - Idle State
    private var idleView: some View {
        ContentUnavailableView(
            "Search for a destination",
            systemImage: "map",
            description: Text(
                "Enter at least two characters to find a city or town."
            )
        )
        .accessibilityIdentifier("searchIdleState")
    }
    
    // MARK: - Loading State
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            
            Text("Searching locations...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .accessibilityIdentifier("searchLoadingState")
    }
    
    // MARK: - Results State
    private func resultsView(
        _ locations: [GeocodedLocation]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search results")
                .font(.headline)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(locations) { location in
                        Button {
                            viewModel.selectedLocation(location)
                            isSearchFieldFocused = false
                        } label: {
                            LocationResultRow(
                                location: location,
                                isSelected: viewModel.selectedLocation?.id == location.id
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("locationResult_\(location.id)"
                        )
                        if location.id != locations.last?.id ?? -1 {
                            Divider()
                        }
                    }
                }
            }
            if let selectedLocation = viewModel.selectedLocation {
                selectedLocationView(selectedLocation)
            }
        }
    }
    
    // MARK: - Selected Location
    private func selectedLocationView(
        _ location: GeocodedLocation
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Selected destination")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(location.name)
                        .font(.headline)
                    
                    Text(locationSubtitle(for: location))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            NavigationLink {
                ForecastView(
                    location: location,
                    forecastService: weatherForecastService,
                    suitabilityScoringEngine: suitabilityScoringEngine
                )
            } label: {
                Label(
                    "View 7-day forecast",
                    systemImage: "cloud.sun"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("viewForecastButton")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("selectedLocationView")
    }
    
    // MARK: - Empty State
    private var emptyView: some View {
        ContentUnavailableView.search(text: searchQuery)
            .accessibilityIdentifier("searchEmptyState")
    }
    
    // MARK: - Error State
    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Unable to search locations", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                viewModel.retrySearch(query: searchQuery)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("retrySearchButton")
        }
        .accessibilityIdentifier("searchErrorState")
    }
    
    // MARK: - Helpers
    private func locationSubtitle(
        for location: GeocodedLocation
    ) -> String {
        [
            location.admin1,
            location.country
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}

// MARK: - Location Result Row
private struct LocationResultRow: View {
    
    let location: GeocodedLocation
    let isSelected: Bool
    
    private var subtitle: String {
        [
            location.admin1,
            location.country
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
    
    var body: some View {
        HStack(spacing: 12) {
            
            Image(systemName: "mappin.and.ellipse")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
