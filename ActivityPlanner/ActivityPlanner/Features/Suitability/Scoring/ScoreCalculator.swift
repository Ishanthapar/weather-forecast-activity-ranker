//
//  ScoreCalculator.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/4/26.
//

import Foundation

enum ScoreCalculator {
    
    static func clamp(
        _ value: Double,
        minimum: Double = 0,
        maximum: Double = 100
    ) -> Double {
        min(max(value, minimum), maximum)
    }
    
    static func weightedAverage(
        factors: [(score: Double, weight: Double)]
    ) -> Double? {
        guard !factors.isEmpty else {
            return nil
        }
        
        guard factors.allSatisfy({
            $0.score.isFinite &&
            $0.weight.isFinite &&
            $0.weight > 0
        }) else {
            return nil
        }
        
        let totalWeight = factors.reduce(0.0) {
            $0 + $1.weight
        }
        
        guard totalWeight > 0 else {
            return nil
        }
        
        let weightedScore = factors.reduce(0.0) {
            $0 + clamp($1.score) * $1.weight
        }
        
        return clamp(weightedScore / totalWeight)
    }
    
    static func roundedScore(_ score: Double?) -> Int? {
        guard let score, score.isFinite else {
            return nil
        }
        
        return Int(clamp(score).rounded())
    }
}
