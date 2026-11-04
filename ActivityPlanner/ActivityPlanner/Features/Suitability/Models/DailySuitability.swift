//
//  DailySuitability.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/4/26.
//

import Foundation

/// Represents suitability of an activity on one particular day
struct DailySuitability: Identifiable {
    let date: String
    
    /// Scores range from 0 - 100 with 0 being most unsuitable and 100 being most suitable
    /// Optional because necessary weather measurements may not be available
    /// Nil values mean a score could not be assigned because of unavailable data
    let score: Int?
    
    /// Informs the user why an activity was scored a particular way
    let explanation: String
    
    /// True when insufficient data is available to assign a score
    let isAvailable: Bool
    
    var id: String {
        date // implicit for return date
    }
}
