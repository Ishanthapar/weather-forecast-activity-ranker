//
//  ActivityType.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/4/26.
//

import Foundation

enum ActivityType: String, CaseIterable, Identifiable {
    case skiing
    case surfing
    case outdoorSightseeing
    case indoorSightseeing
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .skiing:
            return "Skiing"
            
        case .surfing:
            return "Surfing"
            
        case .outdoorSightseeing:
            return "Outdoor sightseeing"
            
        case .indoorSightseeing:
            return "Indoor sightseeing"
        }
    }
}
