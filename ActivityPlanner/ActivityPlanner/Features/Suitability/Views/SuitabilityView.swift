//
//  SuitabilityView.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/4/26.
//

import Foundation
import SwiftUI

/// This view is responsible for presenting suitability results
/// of all activities
struct SuitabilityView: View {
    
    let activitySuitabilities: [ActivitySuitability]
    
    private var rankedSuitabilities: [ActivitySuitability] {
        activitySuitabilities
            .enumerated()
            .sorted { lhs, rhs in
                switch(
                    lhs.element.overallScore,
                    rhs.element.overallScore
                ) {
                case let (.some(leftScore), .some(rightScore)):
                    if leftScore == rightScore {
                        return lhs.offset < rhs.offset
                    }
                    return leftScore > rightScore
                    
                case (.some, .none):
                    return false
                    
                case(.none, .some):
                    return false
                    
                case(.none, .none):
                    return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity suitability")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Ranked by weather suitability over the next seven days.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(rankedSuitabilities) { suitability in
                ActivitySuitabilityRow(suitability: suitability)
            }
            
            scoreLegend
            
            Text(
                "Scores are indicative weather-based estimates, not guarantees or safety assessments."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }
    
    private var scoreLegend: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Score guide")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("80–100: Very suitable")
            Text("60–79: Suitable")
            Text("40–59: Moderate")
            Text("0–39: Less suitable")
            Text("—: Insufficient data")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

private struct ActivitySuitabilityRow: View {
    
    let suitability: ActivitySuitability
    
    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(suitability.dailyScores) { dailyScore in
                    dailyScoreRow(dailyScore)
                }
            }
            .padding(.top, 12)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(suitability.activity.title)
                        .font(.headline)
                    
                    if let bestDay = suitability.bestDay {
                        Text("Best day: \(bestDay.date)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    else {
                        Text("No available forecast scores")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                scoreLabel(suitability.overallScore)
            }
            .contentShape(Rectangle())
        }
    }
    
    @ViewBuilder
    private func dailyScoreRow(
        _ dailyScore: DailySuitability
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dailyScore.date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(dailyScore.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            scoreLabel(dailyScore.score)
        }
    }
    
    @ViewBuilder
    private func scoreLabel(_ score: Int?) -> some View {
        if let score {
            Text("\(score)")
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(color(for: score))
                .frame(minWidth: 36, alignment: .trailing)
        } else {
            Text("-")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(minWidth: 36, alignment: .trailing)
        }
    }
    
    private func color(for score: Int) -> Color {
        switch score {
        case 80...100:
            return .green
            
        case 60..<80:
            return .primary
            
        case 40..<60:
            return .orange
            
        default:
            return .red
        }
    }
}
