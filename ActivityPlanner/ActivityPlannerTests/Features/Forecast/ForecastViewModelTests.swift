//
//  ForecastViewModelTests.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/4/26.
//

import Foundation
import XCTest
@testable import ActivityPlanner

import XCTest
@testable import ActivityPlanner

final class MockWeatherForecastService: WeatherForecastServiceProtocol {

    var forecastToReturn: WeatherForecast?
    var errorToThrow: Error?

    private(set) var receivedLocations: [GeocodedLocation] = []

    func fetchForecast(
        for location: GeocodedLocation
    ) async throws -> WeatherForecast {

        receivedLocations.append(location)

        if let errorToThrow {
            throw errorToThrow
        }

        guard let forecastToReturn else {
            throw MockForecastError.noForecastConfigured
        }

        return forecastToReturn
    }
}

private enum MockForecastError: LocalizedError {
    case noForecastConfigured
    case failed

    var errorDescription: String? {
        switch self {
        case .noForecastConfigured:
            return "No forecast configured"
        case .failed:
            return "Forecast request failed"
        }
    }
}

@MainActor
final class ForecastViewModelTests: XCTestCase {

    private var mockService: MockWeatherForecastService!
    private var forecastViewModel: ForecastViewModel!
    private var suitabilityScoringEngine: SuitabilityScoringEngine!

    override func setUp() {
        super.setUp()

        mockService = MockWeatherForecastService()
        suitabilityScoringEngine = WeatherSuitabilityScorer()

        forecastViewModel = ForecastViewModel(
            location: makeLocation(),
            forecastService: mockService, suitabilityScoringEngine: suitabilityScoringEngine
        )
    }

    func testInitialStateIsIdle() {
        if case .idle = forecastViewModel.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected initial state to be idle")
        }
    }

    func testSuccessfulRequestPublishesForecast() async {
        let expectedForecast = makeForecast()
        mockService.forecastToReturn = expectedForecast

        forecastViewModel.loadForecast()

        let completed = await waitUntil {
            if case .loaded = self.forecastViewModel.state {
                return true
            }
            return false
        }

        XCTAssertTrue(completed)

        if case let .loaded(forecast) = forecastViewModel.state {
            XCTAssertEqual(forecast.timezone, "Asia/Kolkata")
            XCTAssertEqual(forecast.days.count, 1)
        } else {
            XCTFail("Expected loaded state")
        }

        XCTAssertEqual(mockService.receivedLocations.count, 1)
        XCTAssertEqual(
            mockService.receivedLocations.first?.name,
            "Mumbai"
        )
    }

    func testFailedRequestPublishesError() async {
        mockService.errorToThrow = MockForecastError.failed

        forecastViewModel.loadForecast()

        let completed = await waitUntil {
            if case .failed = self.forecastViewModel.state {
                return true
            }
            return false
        }

        XCTAssertTrue(completed)

        if case let .failed(message) = forecastViewModel.state {
            XCTAssertEqual(message, "Forecast request failed")
        } else {
            XCTFail("Expected failed state")
        }
    }

    func testCancelLoadingReturnsStateToIdle() {
        forecastViewModel.loadForecast()
        forecastViewModel.cancelLoading()

        if case .idle = forecastViewModel.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected idle state after cancellation")
        }
    }

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

    private func makeForecast() -> WeatherForecast {
        WeatherForecast(
            latitude: 19.076,
            longitude: 72.8777,
            timezone: "Asia/Kolkata",
            days: [
                ForecastDay(
                    date: "2026-11-04",
                    weatherCode: 1,
                    temperatureMax: 31.5,
                    temperatureMin: 24.0,
                    precipitationSum: 2.5,
                    precipitationProbabilityMax: 40,
                    snowfallSum: 0,
                    windSpeedMax: 18,
                    windGustsMax: 25
                )
            ],
            hours: []
        )
    }

    private func waitUntil(
        timeout: Duration = .seconds(2),
        condition: @escaping @MainActor () -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while clock.now < deadline {
            if condition() {
                return true
            }

            try? await Task.sleep(for: .milliseconds(10))
        }

        return condition()
    }
}
