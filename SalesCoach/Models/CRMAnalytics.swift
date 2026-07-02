import Foundation
import SwiftUI

struct CRMMonthlyPoint: Identifiable, Equatable {
    let id: String
    let month: Date
    let label: String
    let acquisitions: Int
    let revenueWon: Double
    let pipelineAdded: Double
}

struct CRMStageMetric: Identifiable, Equatable {
    let stage: DealStage
    var id: String { stage.rawValue }
    let count: Int
    let value: Double
}

struct CRMSourceMetric: Equatable, Identifiable {
    let source: String
    let count: Int
    var id: String { source }
}

struct CRMSnapshot: Equatable {
    let totalClients: Int
    let activeDeals: Int
    let wonDeals: Int
    let lostDeals: Int
    let pipelineValue: Double
    let weightedPipeline: Double
    let wonRevenue: Double
    let winRate: Double
    let avgDealSize: Double
    let acquisitionsThisMonth: Int
    let acquisitionTrend: Double
    let revenueTrend: Double
    let monthlyTrends: [CRMMonthlyPoint]
    let stageMetrics: [CRMStageMetric]
    let topSources: [CRMSourceMetric]
}

extension DealStage {
    var pipelineColor: Color {
        switch self {
        case .newLead: AppTheme.textMuted
        case .contacted: AppTheme.electricBlueBright
        case .qualified: AppTheme.tealGreen
        case .proposalSent: AppTheme.warningOrange
        case .negotiation: AppTheme.electricBlue
        case .won: AppTheme.successGreen
        case .lost: AppTheme.dangerRed
        }
    }

    var isActivePipeline: Bool {
        self != .won && self != .lost
    }

    static var pipelineColumns: [DealStage] {
        [.newLead, .contacted, .qualified, .proposalSent, .negotiation]
    }
}

extension LeadPriority {
    var color: Color {
        switch self {
        case .hot: AppTheme.dangerRed
        case .warm: AppTheme.warningOrange
        case .cold: AppTheme.electricBlueBright
        }
    }

    var icon: String {
        switch self {
        case .hot: "flame.fill"
        case .warm: "thermometer.medium"
        case .cold: "snowflake"
        }
    }
}

extension Lead {
    var isFollowUpOverdue: Bool {
        guard let nextFollowUpDate else { return false }
        return nextFollowUpDate < Calendar.current.startOfDay(for: .now)
    }

    var isFollowUpToday: Bool {
        guard let nextFollowUpDate else { return false }
        return Calendar.current.isDateInToday(nextFollowUpDate)
    }

    var dealHealthScore: Int {
        var score = probabilityOfClosing
        if isFollowUpOverdue { score -= 15 }
        if priority == .hot { score += 8 }
        if let last = lastContactedDate,
           Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0 <= 7 {
            score += 5
        }
        return min(100, max(0, score))
    }

    var dealHealthLabel: String {
        switch dealHealthScore {
        case 75...: return "Strong"
        case 50..<75: return "Needs attention"
        default: return "At risk"
        }
    }

    var daysSinceLastContact: Int? {
        guard let lastContactedDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastContactedDate, to: .now).day
    }

    var isStale: Bool {
        guard dealStage.isActivePipeline else { return false }
        guard let days = daysSinceLastContact else { return true }
        return days >= 14
    }

    var staleLabel: String {
        guard let days = daysSinceLastContact else { return "Never contacted" }
        return "No contact in \(days) days"
    }
}
