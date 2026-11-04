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
    
    private let forecastService: any WeatherForecastServiceProtocol
    private let location: GeocodedLocation
    
    private var forecastTask: Task<Void, Never>?
    
    init(
        location: GeocodedLocation,
        forecastService: any WeatherForecastServiceProtocol
    ) {
        self.location = location
        self.forecastService = forecastService
        
    }
    
    func loadForecast() {
        /// Cancel existing request that may already be running
        forecastTask?.cancel()
        
        state = .loading
        
        forecastTask = Task {
            do {
                let forecast = try await forecastService.fetchForecast(
                    for: location
                )
                
                guard !Task.isCancelled else {
                    /// Do nothing here since the
                    /// task in question was cancelled
                    return
                }
                
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
