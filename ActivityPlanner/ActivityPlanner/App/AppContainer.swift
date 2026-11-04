//
//  AppContainer.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/2/26.
//

import Foundation

struct AppContainer {
    // MARK: - Dependencies
    
    let geocodingService: any GeocodingServiceProtocol
    let weatherForecastService: any WeatherForecastServiceProtocol
    let suitabilityScoringEngine: any SuitabilityScoringEngine
    
    // MARK: - Initialization
    
    init() {
        let apiClient = APIClient()
        
        self.geocodingService = GeocodingService(
            apiClient: apiClient
        )
        
        self.weatherForecastService = WeatherForecastService(
            apiClient: apiClient
        )
        
        self.suitabilityScoringEngine = WeatherSuitabilityScorer()
    }
}
