//
//  SuitabilityScoringEngine.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/4/26.
//

import Foundation

protocol SuitabilityScoringEngine {
    func calculateSuitability(
        for activity: ActivityType,
        forecast: WeatherForecast,
        now: Date
    ) -> ActivitySuitability
}
