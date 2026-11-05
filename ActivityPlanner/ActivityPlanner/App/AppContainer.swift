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
    
    init(
        isUITesting: Bool = false,
        uiTestScenario: UITestScenario = .success
    ) {
        self.suitabilityScoringEngine = WeatherSuitabilityScorer()
        
        guard !isUITesting else {
            self.geocodingService = MockGeocodingService(
                scenario: uiTestScenario
            )
            
            self.weatherForecastService = MockWeatherForecastService(scenario: uiTestScenario)
            return
        }
        
        let apiClient = APIClient()
        
        self.geocodingService = GeocodingService(
            apiClient: apiClient
        )
        
        self.weatherForecastService = WeatherForecastService(
            apiClient: apiClient
        )
    }
}
