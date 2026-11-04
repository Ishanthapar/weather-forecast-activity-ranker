//
//  ContentView.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/2/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let geocodingService: any GeocodingServiceProtocol
    let weatherForecastService: any WeatherForecastServiceProtocol
    let suitabilityScoringEngine: any SuitabilityScoringEngine
    
    var body: some View {
        LocationSearchView(
            geocodingService: geocodingService,
            weatherForecastService: weatherForecastService,
            suitabilityScoringEngine: suitabilityScoringEngine
        )
    }
}

/*#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}*/
