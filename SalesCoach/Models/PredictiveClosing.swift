import Foundation

struct PredictiveCloseInsight: Equatable {
    let closeProbability: Int
    let expectedRevenue: Double
    let estimatedDaysToClose: Int
    let riskLevel: String
    let riskColor: String
    let explanation: String

    static func from(lead: Lead) -> PredictiveCloseInsight {
        var probability = lead.probabilityOfClosing
        var days = 30
        var risk = "Medium"
        var reasons: [String] = []

        switch lead.dealStage {
        case .newLead: days = 45; probability -= 5
        case .contacted: days = 35
        case .qualified: days = 28; probability += 5
        case .discovery: days = 25; probability += 4
        case .demo: days = 22; probability += 6
        case .proposalSent: days = 21; probability += 8
        case .negotiation: days = 14; probability += 12
        case .legal: days = 10; probability += 15
        case .procurement: days = 7; probability += 18
        case .won: days = 0; probability = 100; risk = "Closed"
        case .lost: days = 0; probability = 0; risk = "Lost"
        }

        if lead.priority == .hot { probability += 8; days -= 5; reasons.append("hot priority") }
        if lead.isFollowUpOverdue { probability -= 12; days += 7; reasons.append("overdue follow-up") }
        if let last = lead.lastContactedDate,
           let gap = Calendar.current.dateComponents([.day], from: last, to: .now).day, gap <= 7 {
            probability += 6
            reasons.append("recent engagement")
        } else if lead.dealStage.isActivePipeline {
            probability -= 8
            reasons.append("stale contact")
        }
        if lead.activities.count >= 3 { probability += 5; days -= 3 }
        if !lead.competitorName.isEmpty { probability -= 6; reasons.append("competitor present") }

        probability = min(100, max(0, probability))
        days = max(0, days)

        if probability >= 70 { risk = "Low" }
        else if probability >= 40 { risk = "Medium" }
        else { risk = "High" }

        let explanation: String
        if lead.dealStage == .won {
            explanation = "Deal closed successfully."
        } else if lead.dealStage == .lost {
            explanation = lead.lostReason.isEmpty ? "Deal marked lost." : "Lost: \(lead.lostReason)"
        } else if reasons.isEmpty {
            explanation = "Based on stage, engagement, and follow-up timing."
        } else {
            explanation = "Adjusted for \(reasons.joined(separator: ", "))."
        }

        return PredictiveCloseInsight(
            closeProbability: probability,
            expectedRevenue: lead.dealValue * Double(probability) / 100,
            estimatedDaysToClose: days,
            riskLevel: risk,
            riskColor: risk,
            explanation: explanation
        )
    }
}
