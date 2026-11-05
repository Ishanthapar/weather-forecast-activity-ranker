//
//  MockServices.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/5/26.
//

import Foundation

enum UITestScenario: String {
    case success
    case emptySearch
    case geocodingError
    case forecastError
}

// MARK: - Mock Geocoding Service

struct MockGeocodingService: GeocodingServiceProtocol {
    
    let scenario: UITestScenario
    
    func searchLocations(
        matching query: String
    ) async throws -> [GeocodedLocation] {
        
        switch scenario {
        case .emptySearch:
            return []
            
        case .geocodingError:
            throw URLError(.notConnectedToInternet)
            
        case .success, .forecastError:
            guard query.localizedCaseInsensitiveContains("mumbai") else {
                return []
            }
            
            return [
                GeocodedLocation(
                    id: 1275339,
                    name: "Mumbai",
                    latitude: 19.0760,
                    longitude: 72.8777,
                    country: "India",
                    countryCode: "IN",
                    admin1: "Maharashtra",
                    timezone: "Asia/Kolkata",
                    population: 12691836,
                    featureCode: "PPLA"
                )
            ]
        }
    }
}

// MARK: - Mock Weather Forecast Service

struct MockWeatherForecastService: WeatherForecastServiceProtocol {
    
    let scenario: UITestScenario
    
    func fetchForecast(
        for location: GeocodedLocation
    ) async throws -> WeatherForecast {
        
        if scenario == .forecastError {
            throw URLError(.notConnectedToInternet)
        }
        
        return makeForecast(for: location)
    }
    
    private func makeForecast(
        for location: GeocodedLocation
    ) -> WeatherForecast {
        
        let timezone = TimeZone(
            identifier: location.timezone ?? "UTC"
        ) ?? .current
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        
        let dateformatter = DateFormatter()
        dateformatter.calendar = calendar
        dateformatter.timeZone = timezone
        dateformatter.dateFormat = "yyyy-MM-dd"
        
        let hourFormatter = DateFormatter()
        hourFormatter.calendar = calendar
        hourFormatter.timeZone = timezone
        hourFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        
        let today = calendar.startOfDay(for: Date())
        
        var days: [ForecastDay] = []
        var hours: [ForecastHour] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: today
            ) else {
                continue
            }
            
            days.append(
                ForecastDay(
                    date: dateformatter.string(from: date),
                    weatherCode: 1,
                    temperatureMax: 31,
                    temperatureMin: 24,
                    precipitationSum: 0,
                    precipitationProbabilityMax: 0,
                    snowfallSum: 0,
                    windSpeedMax: 15,
                    windGustsMax: 22
                )
            )
            
            for hour in 0..<24 {
                guard let hourDate = calendar.date(
                    bySettingHour: hour,
                    minute: 0,
                    second: 0,
                    of: date
                ) else {
                    continue
                }
                
                hours.append(
                    ForecastHour(
                        time: hourFormatter.string(from: hourDate),
                        temperature: 27,
                        apparentTemperature: 28,
                        precipitationProbability: 0,
                        precipitation: 0,
                        rain: 0,
                        snowfall: 0,
                        snowDepth: 0,
                        weatherCode: 1,
                        windSpeed: 12,
                        windGusts: 18
                    )
                )
            }
        }
        return WeatherForecast(
            latitude: location.latitude,
            longitude: location.longitude,
            timezone: timezone.identifier,
            days: days,
            hours: hours
        )
    }
}
