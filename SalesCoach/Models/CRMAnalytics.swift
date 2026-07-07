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
        case .discovery: AppTheme.electricBlue
        case .demo: AppTheme.warningOrange
        case .proposalSent: AppTheme.warningOrange
        case .negotiation: AppTheme.electricBlue
        case .legal: AppTheme.textSecondary
        case .procurement: AppTheme.textMuted
        case .won: AppTheme.successGreen
        case .lost: AppTheme.dangerRed
        }
    }

    var isActivePipeline: Bool {
        self != .won && self != .lost
    }

    static var pipelineColumns: [DealStage] {
        [.newLead, .contacted, .qualified, .discovery, .demo, .proposalSent, .negotiation, .legal, .procurement]
    }

    var pipelineShortLabel: String {
        switch self {
        case .newLead: "Lead"
        case .contacted: "Contacted"
        case .qualified: "Qualified"
        case .discovery: "Discovery"
        case .demo: "Demo"
        case .proposalSent: "Proposal"
        case .negotiation: "Negotiate"
        case .legal: "Legal"
        case .procurement: "Procure"
        case .won: "Won"
        case .lost: "Lost"
        }
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
        if isFollowUpOverdue { score -= 18 }
        else if isFollowUpToday { score += 5 }
        if priority == .hot { score += 10 }
        else if priority == .cold { score -= 5 }
        if let last = lastContactedDate,
           let days = Calendar.current.dateComponents([.day], from: last, to: .now).day {
            if days <= 3 { score += 10 }
            else if days <= 7 { score += 5 }
            else if days >= 14 { score -= 12 }
        } else if dealStage.isActivePipeline {
            score -= 10
        }
        if !activities.isEmpty { score += min(8, activities.count * 2) }
        if dealEvents.count >= 3 { score += 4 }
        if isStale { score -= 15 }
        return min(100, max(0, score))
    }

    var dealHealthColor: Color {
        switch dealHealthScore {
        case 75...: AppTheme.successGreen
        case 50..<75: AppTheme.warningOrange
        default: AppTheme.dangerRed
        }
    }

    var predictedCloseInsight: PredictiveCloseInsight {
        PredictiveCloseInsight.from(lead: self)
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

    var displayAIAction: String {
        aiRecommendedAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Add client details, then refresh for an AI-recommended next step."
            : aiRecommendedAction
    }
}
