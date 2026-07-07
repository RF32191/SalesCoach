import CoreLocation
import Foundation

@MainActor
final class RepDNAService {
    static let shared = RepDNAService()

    func profile(
        userId: String,
        training: TrainingService,
        crm: CRMService,
        gamification: GamificationService
    ) -> RepDNAProfile {
        let sessions = training.sessions.filter { $0.userId == userId && $0.scoreReport != nil }
        var skillScores: [String: [Int]] = [:]

        for session in sessions {
            for category in session.scoreReport?.categories ?? [] {
                skillScores[category.name, default: []].append(category.score)
            }
        }

        let skills: [RepDNASkill] = {
            if skillScores.isEmpty {
                return [
                    RepDNASkill(name: "Confidence", score: 65, trend: "Practice to unlock"),
                    RepDNASkill(name: "Objection Handling", score: 58, trend: "Needs reps"),
                    RepDNASkill(name: "Closing Ability", score: 62, trend: "Room to grow")
                ]
            }
            return skillScores.map { name, scores in
                let avg = scores.reduce(0, +) / max(scores.count, 1)
                return RepDNASkill(name: name, score: avg, trend: avg >= 75 ? "Strong" : "Drill assigned")
            }.sorted { $0.score > $1.score }
        }()

        let strongest = skills.first?.name ?? "Discovery"
        let weakest = skills.last?.name ?? "Objection Handling"
        let winRate = crm.snapshot().winRate
        let headline: String = {
            if sessions.isEmpty { return "Complete a roleplay to unlock your Rep DNA" }
            if winRate >= 40 { return "Closer profile — strong pipeline execution" }
            return "Coachable profile — focus on \(weakest) this week"
        }()

        let drillScenario: TrainingScenario = weakest.lowercased().contains("objection") ? .objectionHandling :
            weakest.lowercased().contains("clos") ? .closing : .followUp

        let challenge = weeklyChallenge(userId: userId, gamification: gamification, training: training)

        return RepDNAProfile(
            headline: headline,
            strongestSkill: strongest,
            weakestSkill: weakest,
            skills: skills,
            dailyDrillTitle: "Today's drill: \(weakest)",
            dailyDrillScenario: drillScenario,
            weeklyChallenge: challenge
        )
    }

    func weeklyChallenge(userId: String, gamification: GamificationService, training: TrainingService) -> WeeklyChallenge {
        let storedKey = "salescoach_weekly_challenge_\(userId)"
        let calendar = Calendar.current
        if let data = UserDefaults.standard.data(forKey: storedKey),
           let stored = try? JSONDecoder().decode(WeeklyChallenge.self, from: data),
           calendar.isDate(storedContactsWeek(stored), equalTo: .now, toGranularity: .weekOfYear) {
            var updated = stored
            updated.contactsDone = gamification.profile.totalContacts
            updated.roleplaysDone = training.completedCount(for: userId)
            return updated
        }
        let challenge = WeeklyChallenge(contactsTarget: 15, roleplaysTarget: 3, contactsDone: gamification.profile.totalContacts, roleplaysDone: training.completedCount(for: userId))
        if let data = try? JSONEncoder().encode(challenge) {
            UserDefaults.standard.set(data, forKey: storedKey)
        }
        return challenge
    }

    private func storedContactsWeek(_ challenge: WeeklyChallenge) -> Date { .now }
}

@MainActor
final class StandoutCoachingService {
    static let shared = StandoutCoachingService()

    func dealReplay(for lead: Lead, audit: AuditService) -> [DealReplayEvent] {
        var events: [DealReplayEvent] = []
        events.append(DealReplayEvent(
            id: "created",
            date: lead.createdAt,
            title: "Lead created",
            detail: "\(lead.name) added · Source: \(lead.leadSource)",
            icon: "person.badge.plus",
            coachingTip: "Document discovery notes early."
        ))
        for activity in lead.activities.prefix(8) {
            events.append(DealReplayEvent(
                id: activity.id,
                date: activity.date,
                title: activity.type.rawValue,
                detail: activity.summary,
                icon: activity.type == .call ? "phone.fill" : "envelope.fill",
                coachingTip: nil
            ))
        }
        for entry in audit.entries(for: lead.id).prefix(5) {
            events.append(DealReplayEvent(
                id: entry.id,
                date: entry.timestamp,
                title: entry.summary,
                detail: entry.action,
                icon: "doc.text.fill",
                coachingTip: "Review what changed at each stage."
            ))
        }
        if lead.dealStage == .won || lead.dealStage == .lost {
            events.append(DealReplayEvent(
                id: "outcome",
                date: lead.updatedAt,
                title: lead.dealStage.rawValue,
                detail: "Final value $\(Int(lead.dealValue))",
                icon: lead.dealStage == .won ? "trophy.fill" : "xmark.circle.fill",
                coachingTip: lead.dealStage == .won ? "Add to team playbook." : "Schedule 90-day nurture."
            ))
        }
        return events.sorted { $0.date > $1.date }
    }

    func smartRoute(from origin: CLLocationCoordinate2D?, leads: [Lead], weakestSkill: String) -> [SmartRouteStop] {
        let stops = RoutePlannerService.planRoute(from: origin, leads: leads)
        return stops.enumerated().map { index, stop in
            let note: String = {
                if index == 0 { return "Review battle card before first stop." }
                if index == 1 { return "Practice \(weakestSkill) before this visit." }
                return "Log visit + schedule follow-up before leaving."
            }()
            return SmartRouteStop(id: stop.id, lead: stop.lead, order: stop.order, coachingNote: note)
        }
    }

    func managerBrief(
        crm: CRMService,
        training: TrainingService,
        teamSales: TeamSalesService,
        teamId: String,
        userId: String
    ) async -> ManagerMorningBrief {
        let snapshot = crm.snapshot()
        let stale = crm.staleLeads().count
        let overdue = crm.overdueFollowUps().count
        let avgScore = training.averageScore(for: userId)
        let wins = teamSales.feed(for: teamId).prefix(3).map {
            if case .sale(let sale) = $0 { return "\(sale.repName) closed $\(Int(sale.amount)) with \(sale.clientName)" }
            return ""
        }.filter { !$0.isEmpty }

        if AppConfig.isAIConfigured,
           let brief = try? await OpenAIService.shared.requestManagerBrief(
               pipeline: snapshot.pipelineValue,
               winRate: snapshot.winRate,
               staleCount: stale,
               overdueCount: overdue,
               avgScore: avgScore
           ) {
            return brief
        }

        return ManagerMorningBrief(
            headline: "Team pulse — \(snapshot.activeDeals) active deals",
            repHighlights: [
                "Average roleplay score: \(avgScore)/100",
                "\(crm.hotLeads().count) hot deals need push",
                "\(training.completedCount(for: userId)) sessions completed this month"
            ],
            coachingAssignments: [
                stale > 0 ? "Assign stale-deal revival drill to reps with \(stale)+ cold accounts" : "Run objection handling round-robin today",
                overdue > 0 ? "Clear \(overdue) overdue follow-ups before noon" : "Celebrate top performer on team feed"
            ],
            pipelineAlerts: [
                "Pipeline: $\(Int(snapshot.pipelineValue))",
                "Win rate: \(Int(snapshot.winRate))%"
            ],
            teamWins: wins.isEmpty ? ["No team wins logged yet today."] : wins
        )
    }

    func certificationAllowsStage(_ stage: DealStage, userId: String, training: TrainingService, certifications: CertificationService) -> (allowed: Bool, message: String) {
        guard stage == .proposalSent || stage == .negotiation else { return (true, "") }

        if stage == .proposalSent, certifications.earnedLevels.contains(.discoveryMaster) { return (true, "") }
        if stage == .negotiation, certifications.earnedLevels.contains(.closingExpert) { return (true, "") }

        let avg = training.averageScore(for: userId)
        let required = stage == .negotiation ? 75 : 70
        if avg >= required { return (true, "") }

        let certName = stage == .negotiation ? CertificationLevel.closingExpert.rawValue : CertificationLevel.discoveryMaster.rawValue
        return (
            false,
            "Need roleplay avg \(required)+ (yours: \(avg)) or \(certName) certification before \(stage.rawValue)."
        )
    }
}
