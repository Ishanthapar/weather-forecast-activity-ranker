//
//  ForecastViewModel.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/4/26.
//

import Foundation
import Combine

@MainActor
final class ForecastViewModel: ObservableObject {
    
    enum ForecastState {
        case idle
        case loading
        case loaded(WeatherForecast)
        case failed(String)
    }
    
    @Published private(set) var state: ForecastState = .idle
    
    @Published private(set) var activitySuitabilities: [ActivitySuitability] = []
    
    private let forecastService: any WeatherForecastServiceProtocol
    private let location: GeocodedLocation
    private let suitabilityScoringEngine: any SuitabilityScoringEngine
    
    private var forecastTask: Task<Void, Never>?
    
    init(
        location: GeocodedLocation,
        forecastService: any WeatherForecastServiceProtocol,
        suitabilityScoringEngine: any SuitabilityScoringEngine
    ) {
        self.location = location
        self.forecastService = forecastService
        self.suitabilityScoringEngine = suitabilityScoringEngine
    }
    
    func loadForecast() {
        /// Avoid duplicate requests while loading or after success
        if case .loading = state {
            return
        }
        
        if case .loaded = state {
            return
        }
        
        /// Cancel existing request that may already be running
        forecastTask?.cancel()
        
        state = .loading
        activitySuitabilities = []
        
        forecastTask = Task {
            do {
                try Task.checkCancellation()
                
                let forecast = try await forecastService.fetchForecast(
                    for: location
                )
                
                guard !Task.isCancelled else {
                    /// Do nothing here since the
                    /// task in question was cancelled
                    return
                }
                
                let now = Date()
                
                let suitabilityResults = ActivityType.allCases.map { activity in
                    suitabilityScoringEngine.calculateSuitability(
                        for: activity,
                        forecast: forecast,
                        now: now
                    )
                }
                
                activitySuitabilities = suitabilityResults
                state = .loaded(forecast)
                
            } catch is CancellationError {
                /// This is intentional. Do nothing
                return
                
            } catch {
                guard !Task.isCancelled else {
                    /// Do not publish the error since the task in question
                    /// was cancelled
                    return
                }
                
                activitySuitabilities = []
                state = .failed(error.localizedDescription)
            }
        }
    }
    
    func cancelLoading() {
        forecastTask?.cancel()
        forecastTask = nil
        
        if case .loading = state {
            state = .idle
        }
    }
}
