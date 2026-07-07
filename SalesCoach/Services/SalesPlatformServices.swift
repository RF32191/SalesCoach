import CoreLocation
import Foundation

@MainActor
@Observable
final class CertificationService {
    var earnedLevels: Set<CertificationLevel> = []
    private let storageKey = "salescoach_certifications"

    func load(for userId: String) {
        let key = "\(storageKey)_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode([String].self, from: data) else { return }
        earnedLevels = Set(stored.compactMap { CertificationLevel(rawValue: $0) })
    }

    func evaluate(sessions: [TrainingSession]) {
        for level in CertificationLevel.allCases {
            let match = sessions.contains { session in
                session.scenario == level.scenario &&
                (session.scoreReport?.overallScore ?? 0) >= level.requiredScore
            }
            if match { earnedLevels.insert(level) }
        }
        save()
    }

    func progress(for level: CertificationLevel, sessions: [TrainingSession]) -> Int {
        let best = sessions
            .filter { $0.scenario == level.scenario }
            .compactMap { $0.scoreReport?.overallScore }
            .max() ?? 0
        return min(100, Int(Double(best) / Double(level.requiredScore) * 100))
    }

    private func save() {
        // Persisted per-user via AppState.loadUserData caller
    }

    func save(for userId: String) {
        let key = "\(storageKey)_\(userId)"
        let raw = earnedLevels.map(\.rawValue)
        if let data = try? JSONEncoder().encode(raw) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

@MainActor
@Observable
final class TeamGoalsService {
    var goals: ActivityGoals = .default
    var drills: [ManagerDrill] = []
    var playbooks: [PlaybookEntry] = []

    private let goalsKey = "salescoach_goals"
    private let drillsKey = "salescoach_drills"
    private let playbooksKey = "salescoach_playbooks"

    func load(for userId: String) {
        if let data = UserDefaults.standard.data(forKey: "\(goalsKey)_\(userId)"),
           let stored = try? JSONDecoder().decode(ActivityGoals.self, from: data) {
            goals = stored
        }
        resetWeekIfNeeded()

        if let data = UserDefaults.standard.data(forKey: "\(drillsKey)_\(userId)"),
           let stored = try? JSONDecoder().decode([ManagerDrill].self, from: data) {
            drills = stored
        } else {
            drills = []
        }

        if let data = UserDefaults.standard.data(forKey: "\(playbooksKey)_\(userId)"),
           let stored = try? JSONDecoder().decode([PlaybookEntry].self, from: data) {
            playbooks = stored
        } else {
            playbooks = []
        }

        removeBundledExampleContentIfNeeded(for: userId)
    }

    func loadExampleContent(for userId: String) {
        if drills.isEmpty { drills = ExampleData.exampleDrills() }
        if playbooks.isEmpty { playbooks = ExampleData.examplePlaybooks() }
        save(for: userId)
    }

    func clearExampleContent(for userId: String) {
        drills = []
        playbooks = []
        save(for: userId)
    }

    private func removeBundledExampleContentIfNeeded(for userId: String) {
        let migrationKey = "salescoach_removed_sample_goals_\(userId)"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let exampleDrillTitles = Set(ExampleData.exampleDrills().map(\.title))
        if !drills.isEmpty, Set(drills.map(\.title)) == exampleDrillTitles {
            drills = []
        }

        let examplePlaybookTitles = Set(ExampleData.examplePlaybooks().map(\.title))
        if !playbooks.isEmpty, Set(playbooks.map(\.title)) == examplePlaybookTitles {
            playbooks = []
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
        save(for: userId)
    }

    func save(for userId: String) {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: "\(goalsKey)_\(userId)")
        }
        if let data = try? JSONEncoder().encode(drills) {
            UserDefaults.standard.set(data, forKey: "\(drillsKey)_\(userId)")
        }
        if let data = try? JSONEncoder().encode(playbooks) {
            UserDefaults.standard.set(data, forKey: "\(playbooksKey)_\(userId)")
        }
    }

    func recordCall() { goals.callsCompleted += 1; Haptic.selection() }
    func recordVisit() { goals.visitsCompleted += 1; Haptic.selection() }
    func recordNewLead() { goals.newLeadsCompleted += 1; Haptic.success() }

    func completeDrill(_ drill: ManagerDrill) {
        guard let index = drills.firstIndex(where: { $0.id == drill.id }) else { return }
        drills[index].isCompleted = true
        Haptic.success()
    }

    private func resetWeekIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDate(goals.weekStart, equalTo: .now, toGranularity: .weekOfYear) {
            goals = ActivityGoals(
                weeklyCalls: goals.weeklyCalls,
                weeklyVisits: goals.weeklyVisits,
                weeklyNewLeads: goals.weeklyNewLeads,
                callsCompleted: 0,
                visitsCompleted: 0,
                newLeadsCompleted: 0,
                weekStart: calendar.startOfDay(for: .now)
            )
        }
    }
}

enum RoutePlannerService {
    static func planRoute(from origin: CLLocationCoordinate2D?, leads: [Lead]) -> [RouteStop] {
        let pinned = leads.filter { $0.location.hasCoordinates && $0.dealStage.isActivePipeline }
        let originLocation = origin.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }

        let sorted = pinned.sorted { lhs, rhs in
            let lp = lhs.priority.sortOrder
            let rp = rhs.priority.sortOrder
            if lp != rp { return lp < rp }
            if lhs.isFollowUpOverdue != rhs.isFollowUpOverdue { return lhs.isFollowUpOverdue }
            guard let originLocation,
                  let ll = lhs.location.coordinate,
                  let rl = rhs.location.coordinate else { return false }
            let ld = originLocation.distance(from: CLLocation(latitude: ll.latitude, longitude: ll.longitude))
            let rd = originLocation.distance(from: CLLocation(latitude: rl.latitude, longitude: rl.longitude))
            return ld < rd
        }

        return sorted.enumerated().map { index, lead in
            let distance: Double? = {
                guard let originLocation, let coord = lead.location.coordinate else { return nil }
                return originLocation.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
            }()
            return RouteStop(id: lead.id, lead: lead, order: index + 1, distanceMeters: distance)
        }
    }
}

enum CRMEnhancements {
    static func isDuplicate(_ lead: Lead, in leads: [Lead]) -> Bool {
        leads.contains { existing in
            existing.id != lead.id && (
                (!lead.company.isEmpty && existing.company.lowercased() == lead.company.lowercased()) ||
                (!lead.phone.isEmpty && existing.phone == lead.phone) ||
                (lead.location.hasCoordinates && existing.location.hasCoordinates &&
                 existing.location.latitude == lead.location.latitude &&
                 existing.location.longitude == lead.location.longitude)
            )
        }
    }

    static func forecast(from leads: [Lead]) -> RevenueForecast {
        let calendar = Calendar.current
        let month = calendar.dateInterval(of: .month, for: .now)!
        let active = leads.filter { $0.dealStage.isActivePipeline }
        let weighted = active.reduce(0) { $0 + ($1.dealValue * Double($1.probabilityOfClosing) / 100) }
        let closingSoon = active.filter {
            guard let date = $0.nextFollowUpDate else { return false }
            return month.contains(date) || date < calendar.date(byAdding: .day, value: 7, to: .now)!
        }.count
        return RevenueForecast(
            expectedThisMonth: weighted,
            bestCase: active.reduce(0) { $0 + $1.dealValue },
            pipelineCoverage: weighted,
            dealsClosingSoon: closingSoon
        )
    }

    static func skillGap(training: TrainingService, crm: CRMService) -> SkillGapSnapshot {
        let snapshot = crm.snapshot()
        let allCategories = training.sessions.compactMap { $0.scoreReport?.categories }.flatMap { $0 }
        var grouped: [String: [Int]] = [:]
        for cat in allCategories {
            grouped[cat.name, default: []].append(cat.score)
        }
        let averages = grouped.map { ScoreCategory(name: $0.key, score: $0.value.reduce(0, +) / max($0.value.count, 1)) }
            .sorted { $0.score > $1.score }

        let weakest = averages.last?.name ?? "Discovery Questions"
        let strongest = averages.first?.name ?? "Professionalism"

        return SkillGapSnapshot(
            overallTrainingScore: training.sessions.compactMap { $0.scoreReport?.overallScore }.reduce(0, +) / max(training.sessions.count, 1),
            winRate: snapshot.winRate,
            categoryScores: averages.isEmpty ? defaultCategories() : averages,
            recommendations: [
                "Practice \(weakest) in your next roleplay",
                "Apply training to \(snapshot.activeDeals) active deals in pipeline",
                "Focus follow-ups on \(crm.overdueFollowUps().count) overdue contacts"
            ],
            weakestSkill: weakest,
            strongestSkill: strongest
        )
    }

    static func smartFollowUpDate(for lead: Lead) -> Date {
        let calendar = Calendar.current
        switch lead.dealStage {
        case .newLead, .contacted: return calendar.date(byAdding: .day, value: 2, to: .now)!
        case .qualified, .discovery: return calendar.date(byAdding: .day, value: 3, to: .now)!
        case .demo: return calendar.date(byAdding: .day, value: 4, to: .now)!
        case .proposalSent: return calendar.date(byAdding: .day, value: 5, to: .now)!
        case .negotiation, .legal: return calendar.date(byAdding: .day, value: 1, to: .now)!
        case .procurement: return calendar.date(byAdding: .day, value: 2, to: .now)!
        case .won, .lost: return calendar.date(byAdding: .day, value: 14, to: .now)!
        }
    }

    static func exportCSV(leads: [Lead]) -> String {
        var rows = ["Name,Company,Phone,Email,Stage,Value,Probability,Priority,Source,Next Follow-Up"]
        let formatter = ISO8601DateFormatter()
        for lead in leads {
            let followUp = lead.nextFollowUpDate.map { formatter.string(from: $0) } ?? ""
            rows.append([
                lead.name, lead.company, lead.phone, lead.email,
                lead.dealStage.rawValue, String(Int(lead.dealValue)),
                String(lead.probabilityOfClosing), lead.priority.rawValue,
                lead.leadSource, followUp
            ].map { "\"\($0.replacingOccurrences(of: "\"", with: "'"))\"" }.joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    static func parseCSV(_ csv: String, source: CRMImportSource = .genericCSV) -> [CSVLeadRow] {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count >= 2 else { return [] }
        let headers = parseCSVLine(lines[0]).map { normalizeHeader($0, source: source) }
        return lines.dropFirst().compactMap { line in
            let values = parseCSVLine(line)
            guard !values.isEmpty else { return nil }
            var dict: [String: String] = [:]
            for (index, header) in headers.enumerated() where index < values.count {
                dict[header] = values[index]
            }
            if dict["source"] == nil || dict["source"]?.isEmpty == true {
                dict["source"] = source.rawValue
            }
            return CSVLeadRow(fields: dict)
        }
    }

    private static func normalizeHeader(_ header: String, source: CRMImportSource) -> String {
        header
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\"", with: "")
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for char in line {
            if char == "\"" { inQuotes.toggle() }
            else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }

    static func businessHoursHint(for category: SalesCategory?) -> String {
        switch category {
        case .restaurants: "Best visits: 2–4 PM between lunch and dinner rush"
        case .retail: "Best visits: 10 AM–12 PM or after 2 PM weekdays"
        case .b2bServices, .saas, .insurance: "Best visits: Tue–Thu 9–11 AM or 2–4 PM"
        case .healthcare: "Avoid peak patient hours; try early morning"
        case .automotive: "Weekday mornings and Saturday mid-day work well"
        case .homeServices: "Homeowners often available 8–10 AM or 5–7 PM"
        case .realEstate: "Evenings and weekends for buyers; business hours for offices"
        case .fitness: "Visit managers mid-morning or early afternoon"
        case .none: "Visit during standard business hours when decision-makers are present"
        }
    }

    private static func defaultCategories() -> [ScoreCategory] {
        ["Confidence", "Listening", "Closing Ability"].map { ScoreCategory(name: $0, score: 72) }
    }
}

extension SalesCategory {
    var scriptPack: [String] {
        switch self {
        case .b2bServices: ["Open with a business outcome, not features.", "Ask about their current process before pitching.", "Trial close: 'Should we explore this for Q3?'"]
        case .retail: ["Compliment their merchandising or foot traffic.", "Lead with margin or turnover impact.", "Offer a low-risk pilot in one location."]
        case .restaurants: ["Reference peak hours and labor costs.", "Quantify waste or ticket size improvements.", "Ask who owns vendor decisions."]
        case .realEstate: ["Anchor on speed to close or listing volume.", "Use local market proof points.", "Confirm timeline and financing early."]
        case .insurance: ["Lead with risk protection and compliance.", "Use comparison framing, not price alone.", "Ask about renewal dates."]
        case .healthcare: ["Respect patient flow; be concise.", "Focus on outcomes and staff efficiency.", "Offer peer references in healthcare."]
        case .automotive: ["Talk throughput and upsell rate.", "Use F&I or service lane metrics.", "Ask about current vendor pain."]
        case .homeServices: ["Lead with response time and job size.", "Use before/after case studies.", "Confirm decision maker on site."]
        case .saas: ["Lead with ROI and time-to-value.", "Ask about stack and integrations.", "Offer a scoped pilot with success metrics."]
        case .fitness: ["Talk member retention and LTV.", "Reference peak class utilization.", "Ask about expansion plans."]
        }
    }
}
