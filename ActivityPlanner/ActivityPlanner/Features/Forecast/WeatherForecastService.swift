//
//  WeatherForecastService.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/3/26.
//

import Foundation


protocol WeatherForecastServiceProtocol {
    func fetchForecast(
        for location: GeocodedLocation
    ) async throws -> WeatherForecast
}

struct WeatherForecastService: WeatherForecastServiceProtocol {
    
    private let apiClient: APIClientProtocol!
    
    private let baseURL = URL(string: "https://api.open-meteo.com/v1/forecast")!
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func fetchForecast(
        for location: GeocodedLocation
    ) async throws -> WeatherForecast {
        
        guard var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw URLError(.badURL)
        }
        
        let dailyVariables = [
            "weather_code",
            "temperature_2m_max",
            "temperature_2m_min",
            "precipitation_sum",
            "precipitation_probability_max",
            "snowfall_sum",
            "wind_speed_10m_max",
            "wind_gusts_10m_max"
        ]
        
        let hourlyVariables = [
            "temperature_2m",
            "apparent_temperature",
            "precipitation_probability",
            "precipitation",
            "rain",
            "snowfall",
            "snow_depth",
            "weather_code",
            "wind_speed_10m",
            "wind_gusts_10m"
        ]
        
        components.queryItems = [
            URLQueryItem(
                name: "latitude",
                value: String(location.latitude)
            ),
            URLQueryItem(
                name: "longitude",
                value: String(location.longitude)
            ),
            URLQueryItem(
                name: "daily",
                value: dailyVariables.joined(separator: ",")
            ),
            URLQueryItem(
                name: "hourly",
                value: hourlyVariables.joined(separator: ",")
            ),
            URLQueryItem(
                name: "forecast_days",
                value: "7"
            ),
            URLQueryItem(
                name: "timezone",
                value: location.timezone ?? "auto"
            ),
            URLQueryItem(
                name: "temperature_unit",
                value: "celsius"
            ),
            URLQueryItem(
                name: "wind_speed_unit",
                value: "kmh"
            ),
            URLQueryItem(
                name: "precipitation_unit",
                value: "mm"
            )
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let response = try await apiClient.get(
            WeatherForecastResponse.self,
            from: url
        )
        
        return response.toDomainModel()
        
    }
}
