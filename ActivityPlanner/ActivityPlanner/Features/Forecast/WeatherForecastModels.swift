//
//  WeatherForecastModels.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/3/26.
//

import Foundation

// MARK: - Application Models

struct WeatherForecast {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let days: [ForecastDay]
    let hours: [ForecastHour]
}

struct ForecastDay: Identifiable {
    let date: String
    let weatherCode: Int?
    
    let temperatureMax: Double?
    let temperatureMin: Double?
    
    let precipitationSum: Double?
    let precipitationProbabilityMax: Double?
    
    let snowfallSum: Double?
    
    let windSpeedMax: Double?
    let windGustsMax: Double?
    
    var id: String { date }
}

struct ForecastHour: Identifiable {
    let time: String
    
    let temperature: Double?
    let apparentTemperature: Double?
    
    let precipitationProbability: Double?
    let precipitation: Double?
    let rain: Double?
    
    let snowfall: Double?
    let snowDepth: Double?
    
    let weatherCode: Int?
    
    let windSpeed: Double?
    let windGusts: Double?
    
    var id: String { time }
}

// MARK: - API Response Models

struct WeatherForecastResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    
    let daily: DailyForecastResponse
    let hourly: HourlyForecastResponse
    
    func toDomainModel() -> WeatherForecast {
        let days = daily.time.enumerated().map { index, date in
            ForecastDay(
                date: date,
                weatherCode: daily.weatherCode?[safe: index] ?? nil,
                temperatureMax: daily.temperatureMax?[safe: index] ?? nil,
                temperatureMin: daily.temperatureMin?[safe: index] ?? nil,
                precipitationSum: daily.precipitationSum?[safe: index] ?? nil,
                precipitationProbabilityMax: daily.precipitationProbabilityMax?[safe: index] ?? nil,
                snowfallSum: daily.snowfallSum?[safe: index] ?? nil,
                windSpeedMax: daily.windSpeedMax?[safe: index] ?? nil,
                windGustsMax: daily.windGustsMax?[safe: index] ?? nil
            )
        }
        
        let hours = hourly.time.enumerated().map { index, time in
            ForecastHour(
                time: time,
                temperature: hourly.temperature?[safe: index] ?? nil,
                apparentTemperature: hourly.apparentTemperature?[safe: index] ?? nil,
                precipitationProbability: hourly.precipitationProbability?[safe: index] ?? nil,
                precipitation: hourly.precipitation?[safe: index] ?? nil,
                rain: hourly.rain?[safe: index] ?? nil,
                snowfall: hourly.snowfall?[safe: index] ?? nil,
                snowDepth: hourly.snowDepth?[safe: index] ?? nil,
                weatherCode: hourly.weatherCode?[safe: index] ?? nil,
                windSpeed: hourly.windSpeed?[safe: index] ?? nil,
                windGusts: hourly.windGusts?[safe: index] ?? nil
            )
        }
        
        return WeatherForecast(
            latitude: latitude,
            longitude: longitude,
            timezone: timezone,
            days: days,
            hours: hours
        )
    }
}

struct DailyForecastResponse: Decodable {
    let time: [String]

    let weatherCode: [Int?]?
    let temperatureMax: [Double?]?
    let temperatureMin: [Double?]?

    let precipitationSum: [Double?]?
    let precipitationProbabilityMax: [Double?]?

    let snowfallSum: [Double?]?

    let windSpeedMax: [Double?]?
    let windGustsMax: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case precipitationSum = "precipitation_sum"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case snowfallSum = "snowfall_sum"
        case windSpeedMax = "wind_speed_10m_max"
        case windGustsMax = "wind_gusts_10m_max"
    }
}

struct HourlyForecastResponse: Decodable {
    let time: [String]

    let temperature: [Double?]?
    let apparentTemperature: [Double?]?

    let precipitationProbability: [Double?]?
    let precipitation: [Double?]?
    let rain: [Double?]?

    let snowfall: [Double?]?
    let snowDepth: [Double?]?

    let weatherCode: [Int?]?

    let windSpeed: [Double?]?
    let windGusts: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case precipitationProbability = "precipitation_probability"
        case precipitation
        case rain
        case snowfall
        case snowDepth = "snow_depth"
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
        case windGusts = "wind_gusts_10m"
    }
}

// MARK: - Safe Array Access
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
