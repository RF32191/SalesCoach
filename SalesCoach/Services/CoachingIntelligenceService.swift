import Foundation

@MainActor
final class CoachingIntelligenceService {
    static let shared = CoachingIntelligenceService()

    func objectionStats(from leads: [Lead]) -> [ObjectionStat] {
        var counts: [String: Int] = [:]
        var wins: [String: Int] = [:]
        var totals: [String: Int] = [:]

        for lead in leads {
            for tag in lead.objectionTags {
                let key = tag.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !key.isEmpty else { continue }
                counts[key, default: 0] += 1
                totals[key, default: 0] += 1
                if lead.dealStage == .won { wins[key, default: 0] += 1 }
            }
        }

        return counts.keys.sorted { counts[$0, default: 0] > counts[$1, default: 0] }.map { objection in
            let total = totals[objection, default: 0]
            let winCount = wins[objection, default: 0]
            let rate = total > 0 ? Double(winCount) / Double(total) * 100 : 0
            return ObjectionStat(
                objection: objection,
                count: counts[objection, default: 0],
                winRate: rate,
                suggestedResponse: defaultRebuttal(for: objection)
            )
        }
    }

    func battleCard(for competitor: String, category: SalesCategory?) -> BattleCard {
        let name = competitor.isEmpty ? "Unknown Competitor" : competitor
        return BattleCard(
            id: name.lowercased(),
            competitor: name,
            strengths: ["Established brand", "Existing customer relationships"],
            weaknesses: ["Less personalized service", "Slower implementation"],
            talkTrack: "Many teams switch from \(name) when they need faster support and a rep who knows their business — that's exactly what we deliver for \(category?.clientLabel ?? "clients").",
            proofPoints: (category?.notableCRMTargets.prefix(3).map { "Reference wins with accounts like \($0)." } ?? ["Share a customer story with similar needs."])
        )
    }

    func teamWinHighlights(from feed: [TeamFeedItem], limit: Int = 12) -> [TeamWinHighlight] {
        feed.compactMap { item -> TeamWinHighlight? in
            guard case .sale(let sale) = item else { return nil }
            return TeamWinHighlight(
                id: sale.id,
                repName: sale.repName,
                clientLabel: sale.company.isEmpty ? sale.clientName : sale.company,
                amount: sale.amount,
                loggedAt: sale.loggedAt,
                summary: "Closed \(sale.clientName) for $\(Int(sale.amount))"
            )
        }
        .prefix(limit)
        .map { $0 }
    }

    func generateWinAutopsy(for lead: Lead, finalValue: Double) async -> WinLossAutopsy {
        if AppConfig.isAIConfigured,
           let autopsy = try? await OpenAIService.shared.requestWinLossAutopsy(lead: lead, won: true, finalValue: finalValue) {
            return autopsy
        }
        return WinLossAutopsy(
            headline: "Strong close on \(lead.company.isEmpty ? lead.name : lead.company)",
            whatWorked: ["Maintained momentum through \(lead.dealStage.rawValue)", "Handled \(lead.objectionTags.first ?? "key") objections", "Clear next steps each touch"],
            whatToImprove: ["Document discovery notes earlier", "Confirm economic buyer sooner"],
            playbookSnippet: "When prospects mention \(lead.objectionTags.first ?? "budget"), lead with ROI and a low-risk next step.",
            recommendedDrill: "Practice \(lead.competitorName.isEmpty ? "closing" : "competitive") scenarios",
            nextActions: ["Add win to team playbook", "Ask for referral", "Schedule 30-day check-in"]
        )
    }

    func generateLossAutopsy(for lead: Lead, reason: String) async -> WinLossAutopsy {
        if AppConfig.isAIConfigured,
           let autopsy = try? await OpenAIService.shared.requestWinLossAutopsy(lead: lead, won: false, finalValue: lead.dealValue, reason: reason) {
            return autopsy
        }
        return WinLossAutopsy(
            headline: "Learning from \(lead.name)",
            whatWorked: lead.activities.isEmpty ? ["Initial contact established"] : ["Stayed engaged through \(lead.activities.count) touchpoints"],
            whatToImprove: [reason.isEmpty ? "Capture loss reason earlier" : "Address: \(reason)", "Practice top objection: \(lead.objectionTags.first ?? "budget")"],
            playbookSnippet: "For similar \(lead.leadSource) deals, validate timeline before sending proposal.",
            recommendedDrill: "Objection handling with skeptical buyer",
            nextActions: ["Log competitor intel", "Schedule nurture follow-up in 90 days", "Share loss pattern with team"]
        )
    }

    func assignDrillFromSkillGap(weakestSkill: String, teamGoals: TeamGoalsService, userId: String) {
        let scenario: TrainingScenario = weakestSkill.lowercased().contains("objection") ? .objectionHandling : .followUp
        let drill = ManagerDrill(
            title: "Focus: \(weakestSkill)",
            scenario: scenario,
            personality: .skeptical,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now,
            assignedBy: "Skill Gap Coach"
        )
        teamGoals.drills.insert(drill, at: 0)
        teamGoals.save(for: userId)
    }

    private func defaultRebuttal(for objection: String) -> String {
        let lower = objection.lowercased()
        if lower.contains("price") || lower.contains("budget") {
            return "Anchor on ROI and cost of inaction — compare monthly value vs. investment."
        }
        if lower.contains("time") || lower.contains("busy") {
            return "Offer a 15-minute micro-demo with a clear agenda and easy out."
        }
        if lower.contains("competitor") {
            return "Ask what they wish their current vendor did better, then bridge to your differentiator."
        }
        return "Acknowledge, clarify, and reframe around their priority outcome."
    }
}
