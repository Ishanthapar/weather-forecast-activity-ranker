//
//  ForecastView.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/4/26.
//

import Foundation
import SwiftUI

struct ForecastView: View {
    
    @StateObject private var viewModel: ForecastViewModel
    
    private let location: GeocodedLocation
    
    init(
        location: GeocodedLocation,
        forecastService: any WeatherForecastServiceProtocol,
        suitabilityScoringEngine: any SuitabilityScoringEngine
    ) {
        self.location = location
        
        _viewModel = StateObject(
            wrappedValue: ForecastViewModel(
                location: location,
                forecastService: forecastService,
                suitabilityScoringEngine: suitabilityScoringEngine
            )
        )
    }
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                idleView
                
            case .loading:
                loadingView
                
            case .loaded(let forecast):
                forecastContent(forecast)
                
            case .failed(let message):
                errorView(message)
            }
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadForecast()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            
            Text("Getting the latest forecast...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("forecastLoadingState")
    }
    
    private var idleView: some View {
        ContentUnavailableView(
            "Forecast not loaded",
            systemImage: "cloud.sun",
            description: Text("The weather forecast will appear here")
        )
    }
    
    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label(
                "Unable to load forecast",
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                viewModel.loadForecast()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("retryForecastButton")
        }
    }
    
    private func forecastContent(
        _ forecast: WeatherForecast
    ) -> some View {
        Group {
            if forecast.days.isEmpty {
                ContentUnavailableView(
                    "No forecast available",
                    systemImage: "cloud",
                    description: Text(
                        "No daily weather information was returned for this location"
                    )
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        locationHeader(forecast)
                        
                        SuitabilityView(
                            activitySuitabilities: viewModel.activitySuitabilities
                        )
                        
                        Text("7-day forecast")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(forecast.days) { day in
                                ForecastDayRow(
                                    day: day,
                                    timezone: forecast.timezone
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func locationHeader(
        _ forecast: WeatherForecast
    ) -> some View {
        
        VStack(alignment: .leading, spacing: 6) {
            Text(location.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(locationSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Local time zone: \(forecast.timezone)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var locationSubtitle: String {
        [location.admin1, location.country]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

private struct ForecastDayRow: View {

    let day: ForecastDay
    let timezone: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate)
                        .font(.headline)

                    Text(weatherDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: weatherSymbol)
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                temperatureColumn(
                    title: "Maximum",
                    value: day.temperatureMax
                )

                Spacer()

                temperatureColumn(
                    title: "Minimum",
                    value: day.temperatureMin
                )
            }

            Divider()

            HStack(alignment: .top, spacing: 12) {
                weatherMetric(
                    title: "Precipitation",
                    value: formattedValue(
                        day.precipitationSum,
                        unit: "mm"
                    ),
                    symbol: "cloud.rain"
                )

                weatherMetric(
                    title: "Rain chance",
                    value: formattedValue(
                        day.precipitationProbabilityMax,
                        unit: "%"
                    ),
                    symbol: "drop"
                )

                weatherMetric(
                    title: "Snowfall",
                    value: formattedValue(
                        day.snowfallSum,
                        unit: "cm"
                    ),
                    symbol: "snowflake"
                )
            }

            HStack(alignment: .top, spacing: 12) {
                weatherMetric(
                    title: "Wind",
                    value: formattedValue(
                        day.windSpeedMax,
                        unit: "km/h"
                    ),
                    symbol: "wind"
                )

                weatherMetric(
                    title: "Wind gusts",
                    value: formattedValue(
                        day.windGustsMax,
                        unit: "km/h"
                    ),
                    symbol: "wind"
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
    }

    private func temperatureColumn(
        title: String,
        value: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(formattedValue(value, unit: "°C"))
                .font(.title3)
                .fontWeight(.semibold)
        }
    }

    private func weatherMetric(
        title: String,
        value: String,
        symbol: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedValue(
        _ value: Double?,
        unit: String
    ) -> String {
        guard let value else {
            return "—"
        }

        return "\(value.formatted(.number.precision(.fractionLength(0...1)))) \(unit)"
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: timezone)
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: day.date) else {
            return day.date
        }

        formatter.dateFormat = "EEEE, d MMM"
        return formatter.string(from: date)
    }
    
    private var weatherDescription: String {
        guard let code = day.weatherCode else {
            return "Conditions unavailable"
        }

        switch code {
        case 0:
            return "Clear sky"
            
        case 1:
            return "Mainly clear"
            
        case 2:
            return "Partly cloudy"
            
        case 3:
            return "Overcast"
            
        case 45, 48:
            return "Fog"
            
        case 51, 53, 55:
            return "Drizzle"
            
        case 56, 57:
            return "Freezing drizzle"
            
        case 61, 63, 65:
            return "Rain"
            
        case 66, 67:
            return "Freezing rain"
            
        case 71, 73, 75:
            return "Snowfall"
            
        case 77:
            return "Snow grains"
            
        case 80, 81, 82:
            return "Rain showers"
            
        case 85, 86:
            return "Snow showers"
            
        case 95:
            return "Thunderstorm"
            
        case 96, 99:
            return "Thunderstorm with hail"
            
        default:
            return "Unknown conditions"
        }
    }

    private var weatherSymbol: String {
        guard let code = day.weatherCode else {
            return "questionmark.circle"
        }

        switch code {
        case 0:
            return "sun.max"
            
        case 1, 2:
            return "cloud.sun"
            
        case 3:
            return "cloud"
            
        case 45, 48:
            return "cloud.fog"
            
        case 51...67, 80...82:
            return "cloud.rain"
            
        case 71...77, 85...86:
            return "cloud.snow"
            
        case 95...99:
            return "cloud.bolt.rain"
            
        default:
            return "cloud"
        }
    }
}
