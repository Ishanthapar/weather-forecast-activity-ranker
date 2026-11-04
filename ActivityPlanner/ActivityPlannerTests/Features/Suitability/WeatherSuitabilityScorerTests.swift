//
//  WeatherSuitabilityScorerTests.swift
//  ActivityPlannerTests
//
//  Created by Ishan Thapar on 11/4/26.
//

import Foundation
import XCTest
@testable import ActivityPlanner

final class WeatherSuitabilityScorerTests: XCTestCase {

    private let scorer = WeatherSuitabilityScorer()

    private let timeZone = TimeZone(
        identifier: "Asia/Kolkata"
    )!

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private func makeDate(
        year: Int = 2026,
        month: Int = 11,
        day: Int = 4,
        hour: Int = 10
    ) -> Date {

        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }

    private func makeForecast(
        hours: [ForecastHour],
        dates: [String] = ["2026-11-04"]
    ) -> WeatherForecast {

        let days = dates.map {
            ForecastDay(
                date: $0,
                weatherCode: 0,
                temperatureMax: 25,
                temperatureMin: 20,
                precipitationSum: 0,
                precipitationProbabilityMax: 0,
                snowfallSum: 0,
                windSpeedMax: 10,
                windGustsMax: 15
            )
        }

        return WeatherForecast(
            latitude: 19.076,
            longitude: 72.8777,
            timezone: "Asia/Kolkata",
            days: days,
            hours: hours
        )
    }

    private func makeHour(
        date: String,
        hour: Int,
        temperature: Double? = 25,
        precipitationProbability: Double? = 0,
        precipitation: Double? = 0,
        snowfall: Double? = 0,
        snowDepth: Double? = 0.3,
        windSpeed: Double? = 10
    ) -> ForecastHour {

        ForecastHour(
            time: String(format: "%@T%02d:00", date, hour),
            temperature: temperature,
            apparentTemperature: temperature,
            precipitationProbability: precipitationProbability,
            precipitation: precipitation,
            rain: precipitation,
            snowfall: snowfall,
            snowDepth: snowDepth,
            weatherCode: 0,
            windSpeed: windSpeed,
            windGusts: windSpeed
        )
    }

    private func makeGoodWeatherHours() -> [ForecastHour] {
        [9, 10, 11, 12, 13, 14, 15, 16, 17, 18].map {
            makeHour(date: "2026-11-04", hour: $0)
        }
    }

    // MARK: - Outdoor Sightseeing

    func testOutdoorSightseeingProducesAvailableScore() {

        let forecast = makeForecast(
            hours: makeGoodWeatherHours()
        )

        let result = scorer.calculateSuitability(
            for: .outdoorSightseeing,
            forecast: forecast,
            now: makeDate()
        )

        XCTAssertEqual(result.dailyScores.count, 1)
        XCTAssertNotNil(result.dailyScores[0].score)
        XCTAssertTrue(result.dailyScores[0].isAvailable)
    }

    func testOutdoorSightseeingReturnsUnavailableWhenRequiredDataIsMissing() {

        let hours = [9, 10, 11].map {
            makeHour(
                date: "2026-11-04",
                hour: $0,
                temperature: nil
            )
        }

        let forecast = makeForecast(hours: hours)

        let result = scorer.calculateSuitability(
            for: .outdoorSightseeing,
            forecast: forecast,
            now: makeDate()
        )

        XCTAssertNil(result.dailyScores[0].score)
        XCTAssertFalse(result.dailyScores[0].isAvailable)
        XCTAssertNil(result.overallScore)
    }

    // MARK: - Indoor Sightseeing

    func testIndoorSightseeingProducesHigherScoreWhenOutdoorConditionsWorsen() {

        let goodWeather = makeForecast(
            hours: makeGoodWeatherHours()
        )

        let poorWeatherHours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18].map {
            makeHour(
                date: "2026-11-04",
                hour: $0,
                temperature: 40,
                precipitationProbability: 100,
                precipitation: 12,
                windSpeed: 55
            )
        }

        let poorWeather = makeForecast(
            hours: poorWeatherHours
        )

        let goodResult = scorer.calculateSuitability(
            for: .indoorSightseeing,
            forecast: goodWeather,
            now: makeDate()
        )

        let poorResult = scorer.calculateSuitability(
            for: .indoorSightseeing,
            forecast: poorWeather,
            now: makeDate()
        )

        XCTAssertGreaterThan(
            poorResult.dailyScores[0].score ?? 0,
            goodResult.dailyScores[0].score ?? 0
        )
    }

    // MARK: - Skiing

    func testSkiingProducesAvailableScoreWhenMeasurementsExist() {

        let hours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18].map {
            makeHour(
                date: "2026-11-04",
                hour: $0,
                temperature: -3,
                snowfall: 2,
                snowDepth: 0.5,
                windSpeed: 10
            )
        }

        let forecast = makeForecast(hours: hours)

        let result = scorer.calculateSuitability(
            for: .skiing,
            forecast: forecast,
            now: makeDate()
        )

        XCTAssertNotNil(result.dailyScores[0].score)
        XCTAssertTrue(result.dailyScores[0].isAvailable)
    }

    func testSkiingReturnsUnavailableWhenSnowDepthIsMissing() {

        let hours = [9, 10, 11].map {
            makeHour(
                date: "2026-11-04",
                hour: $0,
                temperature: -3,
                snowfall: 2,
                snowDepth: nil,
                windSpeed: 10
            )
        }

        let forecast = makeForecast(hours: hours)

        let result = scorer.calculateSuitability(
            for: .skiing,
            forecast: forecast,
            now: makeDate()
        )

        XCTAssertNil(result.dailyScores[0].score)
    }

    // MARK: - Surfing

    func testSurfingIsUnavailableWithoutMarineForecast() {

        let forecast = makeForecast(
            hours: makeGoodWeatherHours()
        )

        let result = scorer.calculateSuitability(
            for: .surfing,
            forecast: forecast,
            now: makeDate()
        )

        XCTAssertNil(result.overallScore)
        XCTAssertTrue(
            result.dailyScores.allSatisfy { $0.score == nil }
        )
    }

    // MARK: - Today's Remaining Hours

    func testPastHoursDoNotContributeToTodaysScore() {

        let hours = [
            makeHour(
                date: "2026-11-04",
                hour: 9,
                temperature: 40
            ),
            makeHour(
                date: "2026-11-04",
                hour: 11,
                temperature: 25
            ),
            makeHour(
                date: "2026-11-04",
                hour: 12,
                temperature: 25
            ),
            makeHour(
                date: "2026-11-04",
                hour: 13,
                temperature: 25
            )
        ]

        let forecast = makeForecast(hours: hours)

        let result = scorer.calculateSuitability(
            for: .outdoorSightseeing,
            forecast: forecast,
            now: makeDate()
        )

        XCTAssertEqual(
            result.dailyScores[0].score,
            100
        )
    }

    func testTodayIsUnavailableWhenNoDaytimeHoursRemain() {

        let forecast = makeForecast(
            hours: makeGoodWeatherHours()
        )

        let result = scorer.calculateSuitability(
            for: .outdoorSightseeing,
            forecast: forecast,
            now: makeDate(hour: 19)
        )

        XCTAssertNil(result.dailyScores[0].score)
    }

    // MARK: - Overall Score

    func testOverallScoreUsesOnlyAvailableDays() {

        let dates = [
            "2026-11-04",
            "2026-11-05"
        ]

        let hours = (
            [9, 10, 11, 12, 13, 14, 15, 16, 17, 18].map {
                makeHour(date: dates[0], hour: $0)
            }
            +
            [9, 10, 11, 12, 13, 14, 15, 16, 17, 18].map {
                makeHour(
                    date: dates[1],
                    hour: $0,
                    temperature: nil
                )
            }
        )

        let forecast = makeForecast(
            hours: hours,
            dates: dates
        )

        let result = scorer.calculateSuitability(
            for: .outdoorSightseeing,
            forecast: forecast,
            now: makeDate()
        )

        XCTAssertEqual(result.dailyScores.count, 2)
        XCTAssertNotNil(result.dailyScores[0].score)
        XCTAssertNil(result.dailyScores[1].score)

        XCTAssertEqual(
            result.overallScore,
            result.dailyScores[0].score
        )
    }
}
