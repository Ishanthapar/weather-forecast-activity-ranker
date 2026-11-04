//
//  ActivitySuitability.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/4/26.
//

import Foundation

/// Represents the result of a particular activity across the seven day forecast
struct ActivitySuitability: Identifiable {
    let activity: ActivityType
    let overallScore: Int?
    let dailyScores: [DailySuitability]
    
    var id: ActivityType {
        activity
    }
    
    var bestDay: DailySuitability? {
        dailyScores
            .filter { $0.score != nil }
            .max { ($0.score ?? 0) < ($1.score ?? 0)}
    }
}
