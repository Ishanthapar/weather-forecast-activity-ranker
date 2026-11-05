//
//  WeatherSuitabilityScorer.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/4/26.
//

import Foundation

/// Every activity is scored between 0 to 100 for a particular day
struct WeatherSuitabilityScorer: SuitabilityScoringEngine {
    
    // MARK: - Configuration
    private enum Configuration {
        
        /// Assumes nobody will engage in these activities
        /// before 8 AM and after 6 PM on any particular day
        static let daytimeStartHour = 8
        static let daytimeEndHour = 18
        
        /// Outdoor sightseeing weights
        static let outdoorTemperatureWeight = 0.40
        static let outdoorPrecipitationWeight = 0.40
        static let outdoorWindWeight = 0.20
        
        /// Skiing weights
        static let skiingSnowfallWeight = 0.25
        static let skiingSnowDepthWeight = 0.35
        static let skiingTemperatureWeight = 0.20
        static let skiingWindWeight = 0.20
        
        static let indoorBaselineScore = 55.0
        static let indoorDiscomfortWeight = 0.45
        
        /// Surfing weights
        static let surfingWindWeight = 0.40
        static let surfingWindGustWeight = 0.30
        static let surfingPrecipitationWeight = 0.20
        static let surfingWeatherConditionWeight = 0.10
        
        /// Surfing weather thresholds (km/h)
        static let surfingMaximumWindSpeed = 35.0
        static let surfingMaximumWindGust = 50.0
    }
    
    func calculateSuitability(
        for activity: ActivityType,
        forecast: WeatherForecast,
        now: Date
    ) -> ActivitySuitability {
        
        guard let timeZone = TimeZone(identifier: forecast.timezone) else {
            return unavailableSuitability(
                for: activity,
                forecast: forecast,
                reason: "The forecast timezone is unavailable"
            )
        }
        
        let dateFormatter = makeDateFormatter(
            format: "yyyy-MM-dd'T'HH:mm",
            timeZone: timeZone
        )
        
        let currentDateFormatter = makeDateFormatter(
            format: "yyyy-MM-dd",
            timeZone: timeZone
        )
        
        let today = currentDateFormatter.string(from: now)
        
        let dailyResults = forecast.days.map { day in
            var score: Double?
            
            switch activity {
            case .skiing:
                score = skiingScore(
                    for: day,
                    forecast: forecast,
                    now: now,
                    dateFormatter: dateFormatter,
                    currentDate: today
                )
                
            case .surfing:
                score = surfingScore(
                    for: day,
                    forecast: forecast,
                    now: now,
                    dateFormatter: dateFormatter
                )
                
            case .outdoorSightseeing:
                score = outdoorSightseeingScore(
                    for: day,
                    forecast: forecast,
                    now: now,
                    dateFormatter: dateFormatter,
                    currentDate: today
                )
                
            case .indoorSightseeing:
                score = indoorSightseeingScore(
                    for: day,
                    forecast: forecast,
                    now: now,
                    dateFormatter: dateFormatter,
                    currentDate: today
                )
            }
            let roundedScore = ScoreCalculator.roundedScore(score)
            
            return DailySuitability(
                date: day.date,
                score: roundedScore,
                explanation: explanation(
                    for: activity,
                    score: roundedScore
                ),
                isAvailable: roundedScore != nil
            )
        }
        
        return makeActivityResult(
            activity: activity,
            dailyResults: dailyResults
        )
    }
    
    // MARK: - Outdoor Sightseeing
    
    private func outdoorSightseeingScore(
        for day: ForecastDay,
        forecast: WeatherForecast,
        now: Date,
        dateFormatter: DateFormatter,
        currentDate: String
    ) -> Double? {
        
        let hours = daytimeForecastHours(
            for: day,
            forecast: forecast,
            now: now,
            dateFormatter: dateFormatter,
        )
        
        guard !hours.isEmpty else {
            return nil
        }
        
        let temperatures = hours.compactMap(\.temperature)
        
        let precipitationScores = hours.compactMap { hour -> Double? in
            
            guard
                let precipitation = hour.precipitation ?? hour.rain,
                let probability = hour.precipitationProbability
            else {
                return nil
            }
            
            let amountScore = precipitationScore(
                amount: precipitation
            )
            
            let probabilityScore = ScoreCalculator.clamp(
                100 - probability
            )
            
            return ScoreCalculator.weightedAverage(
                factors: [
                    (score: amountScore, weight: 0.70),
                    (score: probabilityScore, weight: 0.30)
                ]
            )
        }
        
        let windSpeeds = hours.compactMap(\.windSpeed)
        
        guard
            let averageTemperature = average(temperatures),
            let averagePrecipitationScore = average(precipitationScores),
            let averageWindSpeed = average(windSpeeds)
        else {
            return nil
        }
        
        let temperatureFactor = temperatureComfortScore(
            temperature: averageTemperature
        )
        
        let windFactor = windComfortScore(
            windSpeed: averageWindSpeed
        )
        
        return ScoreCalculator.weightedAverage(
            factors: [
                (
                    score: temperatureFactor,
                    weight: Configuration.outdoorTemperatureWeight
                ),
                (
                    score: averagePrecipitationScore,
                    weight: Configuration.outdoorPrecipitationWeight
                ),
                (
                    score: windFactor,
                    weight: Configuration.outdoorWindWeight
                )
            ]
        )
    }
    
    // MARK: - Indoor Sightseeing
    
    private func indoorSightseeingScore(
        for day: ForecastDay,
        forecast: WeatherForecast,
        now: Date,
        dateFormatter: DateFormatter,
        currentDate: String
    ) -> Double? {
        
        guard let outdoorScore = outdoorSightseeingScore(
            for: day,
            forecast: forecast,
            now: now,
            dateFormatter: dateFormatter,
            currentDate: currentDate
        ) else {
            return nil
        }
        
        let outdoorDiscomfort = 100 - outdoorScore
        
        let indoorScore =
        Configuration.indoorBaselineScore +
        (
            outdoorDiscomfort *
            Configuration.indoorDiscomfortWeight
        )
        
        return ScoreCalculator.clamp(indoorScore)
    }
    
    // MARK: - Skiing
    
    private func skiingScore(
        for day: ForecastDay,
        forecast: WeatherForecast,
        now: Date,
        dateFormatter: DateFormatter,
        currentDate: String
    ) -> Double? {
        
        let hours = daytimeForecastHours(
            for: day,
            forecast: forecast,
            now: now,
            dateFormatter: dateFormatter,
        )
        
        guard !hours.isEmpty else {
            return nil
        }
        
        // Snowfall is measured in centimetres by Open-Meteo.
        let snowfallValues = hours.compactMap(\.snowfall)
        
        // Open-Meteo snow depth is measured in metres.
        // Convert it to centimetres before scoring.
        let snowDepthValues = hours.compactMap(\.snowDepth)
            .map { $0 * 100 }
        
        let temperatures = hours.compactMap(\.temperature)
        let windSpeeds = hours.compactMap(\.windSpeed)
        
        guard
            let totalSnowfall = sum(snowfallValues),
            let maximumSnowDepth = maximum(snowDepthValues),
            let averageTemperature = average(temperatures),
            let maximumWindSpeed = maximum(windSpeeds)
        else {
            return nil
        }
        
        let snowfallFactor = snowfallScore(
            snowfall: totalSnowfall
        )
        
        let snowDepthFactor = snowDepthScore(
            depthInCentimetres: maximumSnowDepth
        )
        
        let temperatureFactor = skiingTemperatureScore(
            temperature: averageTemperature
        )
        
        let windFactor = windComfortScore(
            windSpeed: maximumWindSpeed
        )
        
        return ScoreCalculator.weightedAverage(
            factors: [
                (
                    score: snowfallFactor,
                    weight: Configuration.skiingSnowfallWeight
                ),
                (
                    score: snowDepthFactor,
                    weight: Configuration.skiingSnowDepthWeight
                ),
                (
                    score: temperatureFactor,
                    weight: Configuration.skiingTemperatureWeight
                ),
                (
                    score: windFactor,
                    weight: Configuration.skiingWindWeight
                )
            ]
        )
    }
    
    // MARK: - Surfing
    private func surfingScore(
        for day: ForecastDay,
        forecast: WeatherForecast,
        now: Date,
        dateFormatter: DateFormatter
    ) -> Double? {
        let hours = daytimeForecastHours(
            for: day,
            forecast: forecast,
            now: now,
            dateFormatter: dateFormatter
        )
        
        guard !hours.isEmpty else {
            return nil
        }
        
        let windSpeeds = hours.compactMap(\.windSpeed)
        let windGusts = hours.compactMap(\.windGusts)
        
        let precipitationScores = hours.compactMap { hour -> Double? in
            
            guard
                let precipitation = hour.precipitation ?? hour.rain,
                let probability = hour.precipitationProbability
            else {
                return nil
            }
            
            let amountScore = precipitationScore(amount: precipitation)
            
            let probabilityScore = ScoreCalculator.clamp(100 - probability)
            
            return ScoreCalculator.weightedAverage(
                factors: [
                    (score: amountScore, weight: 0.70),
                    (score: probabilityScore, weight: 0.30)
                ]
            )
        }
        
        let weatherConditionScores = hours.compactMap { hour in
            hour.weatherCode.map(weatherConditionScore)
        }
        
        guard
            let averageWindSpeed = average(windSpeeds),
            let maximumWindGust = maximum(windGusts),
            let averagePrecipitationScore = average(precipitationScores),
            let averageWeatherConditionScore = average(weatherConditionScores)
        else {
            return nil
        }
        
        let windFactor = surfingWindScore(
            windSpeed: averageWindSpeed
        )
        
        let windGustFactor = surfingWindGustScore(
            windGust: maximumWindGust
        )
        
        return ScoreCalculator.weightedAverage(
            factors: [
                (
                    score: windFactor,
                    weight: Configuration.surfingWindWeight
                ),
                (
                    score: windGustFactor,
                    weight: Configuration.surfingWindGustWeight
                ),
                (
                    score: averagePrecipitationScore,
                    weight: Configuration.surfingPrecipitationWeight
                ),
                (
                    score: averageWeatherConditionScore,
                    weight: Configuration.surfingWeatherConditionWeight
                )
            ]
        )
    }
    
    // MARK: - Forecast Hour Selection
    
    private func daytimeForecastHours(
        for day: ForecastDay,
        forecast: WeatherForecast,
        now: Date,
        dateFormatter: DateFormatter
    ) -> [ForecastHour] {

        forecast.hours.filter { hour in

            guard
                hour.time.hasPrefix(day.date),
                let forecastDate = dateFormatter.date(from: hour.time),
                forecastDate > now
            else {
                return false
            }

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = dateFormatter.timeZone

            guard let hourComponent = calendar.dateComponents(
                [.hour],
                from: forecastDate
            ).hour else {
                return false
            }

            let daytimeRange =
                Configuration.daytimeStartHour...Configuration.daytimeEndHour

            return daytimeRange.contains(hourComponent)
        }
    }
    
    // MARK: - Individual Scoring Functions
    
    private func temperatureComfortScore(
        temperature: Double
    ) -> Double {
        
        if (18...27).contains(temperature) {
            return 100
        }
        
        if temperature < 12 {
            return ScoreCalculator.clamp(
                100 - ((60 - temperature) * 5)
            )
        }
        
        if temperature > 45 {
            return 0
        }
        
        return ScoreCalculator.clamp(
            100 - ((temperature - 27) * 7.7)
        )
    }
    
    private func precipitationScore(
        amount: Double
    ) -> Double {
        
        switch amount {
        case ...0:
            return 100
            
        case ...0.5:
            return 90
            
        case ...1:
            return 80
            
        case ...2.5:
            return 65
            
        case ...5:
            return 45
            
        case ...10:
            return 20
            
        default:
            return 0
        }
    }
    
    private func windComfortScore(
        windSpeed: Double
    ) -> Double {
        
        if windSpeed <= 2 {
            return 100
        }
        
        if windSpeed >= 60 {
            return 0
        }
        
        return ScoreCalculator.clamp(
            100 - ((windSpeed - 2.0) / 45.0 * 100.0)
        )
    }
    
    private func snowfallScore(
        snowfall: Double
    ) -> Double {
        
        // Fresh snowfall improves the score up to 25 cm.
        return ScoreCalculator.clamp(
            40 + (snowfall * 2.4)
        )
    }
    
    private func snowDepthScore(
        depthInCentimetres: Double
    ) -> Double {
        
        return ScoreCalculator.clamp(
            depthInCentimetres * 2
        )
    }
    
    private func skiingTemperatureScore(
        temperature: Double
    ) -> Double {
        
        if (-8...2).contains(temperature) {
            return 100
        }
        
        if temperature < -8 {
            return ScoreCalculator.clamp(
                100 - ((-8 - temperature) * 6)
            )
        }
        
        return ScoreCalculator.clamp(
            100 - ((temperature - 2) * 8)
        )
    }
    
    private func surfingWindScore(
        windSpeed: Double
    ) -> Double {

        ScoreCalculator.clamp(
            100 * (
                1 - windSpeed / Configuration.surfingMaximumWindSpeed
            )
        )
    }

    private func surfingWindGustScore(
        windGust: Double
    ) -> Double {

        ScoreCalculator.clamp(
            100 * (
                1 - windGust / Configuration.surfingMaximumWindGust
            )
        )
    }

    private func weatherConditionScore(
        weatherCode: Int
    ) -> Double {

        switch weatherCode {

        case 0:
            return 100

        case 1:
            return 95

        case 2:
            return 85

        case 3:
            return 75

        case 45, 48:
            return 60

        case 51:
            return 55

        case 53:
            return 45

        case 55:
            return 35

        case 56:
            return 35

        case 57:
            return 25

        case 61:
            return 45

        case 63:
            return 30

        case 65:
            return 15

        case 66:
            return 25

        case 67:
            return 10

        case 71:
            return 45

        case 73:
            return 35

        case 75:
            return 20

        case 77:
            return 35

        case 80:
            return 45

        case 81:
            return 30

        case 82:
            return 15

        case 85:
            return 30

        case 86:
            return 15

        case 95, 96, 99:
            return 0

        default:
            return 0
        }
    }
    
    // MARK: - Result Construction
    
    private func makeActivityResult(
        activity: ActivityType,
        dailyResults: [DailySuitability]
    ) -> ActivitySuitability {
        
        let availableScores = dailyResults.compactMap(\.score)
        
        var overallScore: Int?
        
        if availableScores.isEmpty {
            overallScore = nil
        }
        else {
            let averageScore = Double(availableScores.reduce(0, +)) / Double(availableScores.count)
            
            overallScore = Int(averageScore.rounded())
        }
        
        return ActivitySuitability(
            activity: activity,
            overallScore: overallScore,
            dailyScores: dailyResults)
    }
    
    private func unavailableSuitability(
        for activity: ActivityType,
        forecast: WeatherForecast,
        reason: String
    ) -> ActivitySuitability {
        
        let results = forecast.days.map { day in
            DailySuitability(
                date: day.date,
                score: nil,
                explanation: reason,
                isAvailable: false
            )
        }
        
        return ActivitySuitability(
            activity: activity,
            overallScore: nil,
            dailyScores: results
        )
    }
    
    private func explanation(
        for activity: ActivityType,
        score: Int?
    ) -> String {
        
        guard let score else {
            return "Insufficient weather data to calculate suitability."
        }
        
        if score >= 80 {
            return "Favourable conditions for this activity."
        }
        
        if score >= 60 {
            return "Generally favourable conditions with some limitations."
        }
        
        if score >= 40 {
            return "Mixed conditions may affect the experience."
        }
        
        return "Weather conditions are less favourable for this activity."
    }
    
    // MARK: - Utility Functions
    
    private func makeDateFormatter(
        format: String,
        timeZone: TimeZone
    ) -> DateFormatter {
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        
        return formatter
    }
    
    private func average(_ values: [Double]) -> Double? {
        
        guard !values.isEmpty,
              values.allSatisfy(\.isFinite) else {
            return nil
        }
        
        return values.reduce(0, +) / Double(values.count)
    }
    
    private func maximum(_ values: [Double]) -> Double? {
        
        guard !values.isEmpty,
              values.allSatisfy(\.isFinite) else {
            return nil
        }
        
        return values.max()
    }
    
    private func sum(_ values: [Double]) -> Double? {
        
        guard !values.isEmpty,
              values.allSatisfy(\.isFinite) else {
            return nil
        }
        
        return values.reduce(0, +)
    }
}
