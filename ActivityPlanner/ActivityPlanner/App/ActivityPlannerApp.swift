//
//  ActivityPlannerApp.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/2/26.
//

import SwiftUI
import SwiftData

@main
struct ActivityPlannerApp: App {
    private let container: AppContainer
    
    init() {
        let arguments = ProcessInfo.processInfo.arguments
        
        let isUITesting = arguments.contains("--uitesting")
        
        let scenarioArgument = arguments.first {
            $0.hasPrefix("--ui-test-scenario")
        }
        
        let scenarioValue = scenarioArgument?
            .components(separatedBy: "=")
            .last
        
        let scenario = scenarioValue.flatMap {
            UITestScenario(rawValue: $0)
        } ?? .success
        
        self.container = AppContainer(
            isUITesting: isUITesting,
            uiTestScenario: scenario
        )
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(
                geocodingService: container.geocodingService,
                weatherForecastService: container.weatherForecastService,
                suitabilityScoringEngine: container.suitabilityScoringEngine
            )
        }
        .modelContainer(sharedModelContainer)
    }
}
