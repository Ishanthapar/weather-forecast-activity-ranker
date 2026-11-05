//
//  WeatherForecastServiceTests.swift
//  ActivityPlannerTests
//
//  Created by Ishan Thapar on 11/4/26.
//

import Foundation
import XCTest
@testable import ActivityPlanner

final class MockAPIClient: APIClientProtocol {
    var responseData = Data()
    var error: Error?
    private(set) var requestedURL: URL?
    
    func get<T: Decodable>(
        _ type: T.Type,
        from url: URL
    ) async throws -> T {
        requestedURL = url
        
        if let error {
            throw error
        }
        
        return try JSONDecoder().decode(type, from: responseData)
    }
}

final class WeatherForecastServiceTests: XCTestCase {
    
    private var mockAPIClient: MockAPIClient!
    private var weatherForecastService: WeatherForecastService!
    
    override func setUp() {
        super.setUp()
        
        mockAPIClient = MockAPIClient()
        
        weatherForecastService = WeatherForecastService(
            apiClient: mockAPIClient
        )
    }
    
    // MARK: - Test Successful Response
    
    func testFetchForecastDailyAndHourlyData() async throws {
        
        mockAPIClient.responseData = Data(
            Self.validForecastJSON.utf8
        )
        
        let forecast = try await weatherForecastService.fetchForecast(
            for: makeLocation()
        )
        
        XCTAssertEqual(forecast.latitude, 19.076)
        XCTAssertEqual(forecast.longitude, 72.8777)
        XCTAssertEqual(forecast.timezone, "Asia/Kolkata")
        
        XCTAssertEqual(forecast.days.count, 2)
        XCTAssertEqual(forecast.hours.count, 2)
        
        let firstDay = try XCTUnwrap(forecast.days.first)
        
        XCTAssertEqual(firstDay.date, "2026-11-04")
        XCTAssertEqual(firstDay.weatherCode, 1)
        XCTAssertEqual(firstDay.temperatureMax, 31.5)
        XCTAssertEqual(firstDay.temperatureMin, 24.0)
        XCTAssertEqual(firstDay.precipitationSum, 2.5)
        XCTAssertEqual(firstDay.precipitationProbabilityMax, 40.0)
        XCTAssertEqual(firstDay.snowfallSum, 0.0)
        XCTAssertEqual(firstDay.windSpeedMax, 18.0)
        XCTAssertEqual(firstDay.windGustsMax, 25.0)
        
        let firstHour = try XCTUnwrap(forecast.hours.first)
        
        XCTAssertEqual(firstHour.time, "2026-11-04T12:00")
        XCTAssertEqual(firstHour.temperature, 29.5)
        XCTAssertEqual(firstHour.apparentTemperature, 32.0)
        XCTAssertEqual(firstHour.precipitationProbability, 30.0)
        XCTAssertEqual(firstHour.precipitation, 0.2)
        XCTAssertEqual(firstHour.rain, 0.2)
        XCTAssertEqual(firstHour.snowfall, 0.0)
        XCTAssertEqual(firstHour.snowDepth, 0.0)
        XCTAssertEqual(firstHour.weatherCode, 1)
        XCTAssertEqual(firstHour.windSpeed, 15.0)
        XCTAssertEqual(firstHour.windGusts, 21.0)
    }
    
    // MARK: - Helpers
    
    private func makeLocation() -> GeocodedLocation {
        GeocodedLocation(
            id: 1,
            name: "Mumbai",
            latitude: 19.076,
            longitude: 72.8777,
            country: "India",
            countryCode: "IN",
            admin1: "Maharashtra",
            timezone: "Asia/Kolkata",
            population: 1000000,
            featureCode: "PPLA"
        )
    }
    
    private static let validForecastJSON = """
        {
            "latitude": 19.076,
            "longitude": 72.8777,
            "timezone": "Asia/Kolkata",
            "daily": {
                "time": ["2026-11-04", "2026-11-05"],
                "weather_code": [1, 3],
                "temperature_2m_max": [31.5, 30.0],
                "temperature_2m_min": [24.0, 23.5],
                "precipitation_sum": [2.5, 0.0],
                "precipitation_probability_max": [40, 10],
                "snowfall_sum": [0.0, 0.0],
                "wind_speed_10m_max": [18.0, 20.0],
                "wind_gusts_10m_max": [25.0, 28.0]
            },
            "hourly": {
                "time": [
                    "2026-11-04T12:00",
                    "2026-11-04T13:00"
                ],
                "temperature_2m": [29.5, 30.0],
                "apparent_temperature": [32.0, 32.5],
                "precipitation_probability": [30, 40],
                "precipitation": [0.2, 0.5],
                "rain": [0.2, 0.5],
                "snowfall": [0.0, 0.0],
                "snow_depth": [0.0, 0.0],
                "weather_code": [1, 2],
                "wind_speed_10m": [15.0, 16.0],
                "wind_gusts_10m": [21.0, 22.0]
            }
        }
        """
}
