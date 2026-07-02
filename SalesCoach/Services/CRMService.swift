import Foundation

@MainActor
@Observable
final class CRMService {
    var leads: [Lead] = []
    var tasks: [CRMTask] = []
    var syncGeofencing: (([Lead]) -> Void)?

    private let storageKey = "salescoach_leads"
    private let tasksStorageKey = "salescoach_crm_tasks"

    func loadLeads(for userId: String) {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([Lead].self, from: data) else {
            leads = Self.sampleLeads(ownerId: userId)
            saveLeads()
            notifyGeofencingSync()
            return
        }
        leads = stored.filter { $0.ownerId == userId }
        if leads.isEmpty {
            leads = Self.sampleLeads(ownerId: userId)
            saveLeads()
        }
        notifyGeofencingSync()
    }

    func loadTasks(for userId: String) {
        guard let data = UserDefaults.standard.data(forKey: tasksStorageKey),
              let stored = try? JSONDecoder().decode([CRMTask].self, from: data) else {
            tasks = []
            return
        }
        let leadIds = Set(leads.map(\.id))
        tasks = stored.filter { leadIds.contains($0.leadId) }
    }

    func addTask(_ task: CRMTask) {
        tasks.insert(task, at: 0)
        saveTasks()
    }

    func completeTask(_ taskId: String) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[index].isCompleted = true
        saveTasks()
    }

    func deleteTask(_ taskId: String) {
        tasks.removeAll { $0.id == taskId }
        saveTasks()
    }

    func openTasks(for leadId: String) -> [CRMTask] {
        tasks.filter { $0.leadId == leadId && !$0.isCompleted }
            .sorted { $0.dueDate < $1.dueDate }
    }

    func overdueTasks() -> [CRMTask] {
        tasks.filter { $0.isOverdue }.sorted { $0.dueDate < $1.dueDate }
    }

    func tasksDueToday() -> [CRMTask] {
        tasks.filter { $0.isDueToday }.sorted { $0.dueDate < $1.dueDate }
    }

    func addLead(_ lead: Lead) -> Bool {
        guard !CRMEnhancements.isDuplicate(lead, in: leads) else { return false }
        var newLead = lead
        if newLead.nextFollowUpDate == nil {
            newLead.nextFollowUpDate = CRMEnhancements.smartFollowUpDate(for: newLead)
        }
        newLead.dealEvents.insert(DealEvent(type: .note, summary: "Lead added to CRM"), at: 0)
        leads.insert(newLead, at: 0)
        saveLeads()
        notifyGeofencingSync()
        return true
    }

    func updateLead(_ lead: Lead) {
        guard let index = leads.firstIndex(where: { $0.id == lead.id }) else { return }
        var updated = lead
        updated.updatedAt = .now
        leads[index] = updated
        saveLeads()
        notifyGeofencingSync()
    }

    func deleteLead(_ lead: Lead) {
        leads.removeAll { $0.id == lead.id }
        saveLeads()
        notifyGeofencingSync()
    }

    func leadsByStage() -> [DealStage: [Lead]] {
        Dictionary(grouping: leads, by: \.dealStage)
    }

    func leadsWithLocations() -> [Lead] {
        leads.filter { $0.location.hasCoordinates }
    }

    func addActivity(to leadId: String, activity: LeadActivity) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        leads[index].activities.insert(activity, at: 0)
        leads[index].updatedAt = .now
        saveLeads()
    }

    func togglePinReminder(for leadId: String) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        leads[index].location.pinReminderEnabled.toggle()
        leads[index].updatedAt = .now
        saveLeads()
        notifyGeofencingSync()
    }

    func totalPipelineValue() -> Double {
        leads.filter { $0.dealStage != .won && $0.dealStage != .lost }.reduce(0) { $0 + $1.dealValue }
    }

    func updateAIRecommendation(for leadId: String, action: String) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        leads[index].aiRecommendedAction = action
        leads[index].updatedAt = .now
        saveLeads()
    }

    func moveLead(_ leadId: String, to stage: DealStage) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        let previous = leads[index].dealStage
        leads[index].dealStage = stage
        leads[index].dealEvents.insert(
            DealEvent(type: .stageChange, summary: "Moved from \(previous.rawValue) to \(stage.rawValue)"),
            at: 0
        )
        leads[index].updatedAt = .now
        saveLeads()
    }

    func updatePriority(for leadId: String, priority: LeadPriority) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        leads[index].priority = priority
        leads[index].updatedAt = .now
        saveLeads()
    }

    func scheduleFollowUp(for leadId: String, date: Date) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        leads[index].nextFollowUpDate = date
        leads[index].updatedAt = .now
        saveLeads()
    }

    func logContact(for leadId: String, type: LeadActivityType, summary: String) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        let activity = LeadActivity(type: type, summary: summary)
        leads[index].activities.insert(activity, at: 0)
        leads[index].lastContactedDate = .now
        leads[index].updatedAt = .now
        let eventType: DealEventType = switch type {
        case .call: .call
        case .email: .email
        case .visit: .visit
        case .meeting, .note: .note
        }
        leads[index].dealEvents.insert(DealEvent(type: eventType, summary: summary), at: 0)
        saveLeads()
    }

    func applySmartFollowUp(to leadId: String) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        let date = CRMEnhancements.smartFollowUpDate(for: leads[index])
        leads[index].nextFollowUpDate = date
        leads[index].dealEvents.insert(
            DealEvent(type: .followUpScheduled, summary: "Smart follow-up scheduled for \(date.formatted(date: .abbreviated, time: .omitted))"),
            at: 0
        )
        leads[index].updatedAt = .now
        saveLeads()
    }

    func exportCSV() -> String {
        CRMEnhancements.exportCSV(leads: leads)
    }

    func revenueForecast() -> RevenueForecast {
        CRMEnhancements.forecast(from: leads)
    }

    func overdueFollowUps() -> [Lead] {
        leads
            .filter { $0.isFollowUpOverdue && $0.dealStage.isActivePipeline }
            .sorted { ($0.nextFollowUpDate ?? .distantPast) < ($1.nextFollowUpDate ?? .distantPast) }
    }

    func followUpsToday() -> [Lead] {
        leads
            .filter { $0.isFollowUpToday && $0.dealStage.isActivePipeline }
            .sorted { ($0.nextFollowUpDate ?? .distantFuture) < ($1.nextFollowUpDate ?? .distantFuture) }
    }

    func upcomingFollowUps(withinDays days: Int = 7) -> [Lead] {
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: .now))!
        return leads
            .filter { lead in
                guard lead.dealStage.isActivePipeline, let date = lead.nextFollowUpDate else { return false }
                return date >= calendar.startOfDay(for: .now) && date <= end
            }
            .sorted { ($0.nextFollowUpDate ?? .distantFuture) < ($1.nextFollowUpDate ?? .distantFuture) }
    }

    func hotLeads() -> [Lead] {
        leads
            .filter { $0.priority == .hot && $0.dealStage.isActivePipeline }
            .sorted { $0.dealHealthScore > $1.dealHealthScore }
    }

    func staleLeads(thresholdDays: Int = 14) -> [Lead] {
        leads
            .filter { lead in
                guard lead.dealStage.isActivePipeline else { return false }
                guard let days = lead.daysSinceLastContact else { return true }
                return days >= thresholdDays
            }
            .sorted { ($0.daysSinceLastContact ?? 999) > ($1.daysSinceLastContact ?? 999) }
    }

    func favoriteLeads() -> [Lead] {
        leads.filter(\.isFavorite).sorted { $0.updatedAt > $1.updatedAt }
    }

    func toggleFavorite(for leadId: String) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        leads[index].isFavorite.toggle()
        leads[index].updatedAt = .now
        saveLeads()
    }

    func snoozeFollowUp(for leadId: String, days: Int) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        let date = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
        leads[index].nextFollowUpDate = date
        leads[index].dealEvents.insert(
            DealEvent(type: .followUpScheduled, summary: "Follow-up snoozed for \(days) day\(days == 1 ? "" : "s")"),
            at: 0
        )
        leads[index].updatedAt = .now
        saveLeads()
    }

    func markWon(_ leadId: String, finalValue: Double? = nil) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        if let finalValue { leads[index].dealValue = finalValue }
        leads[index].probabilityOfClosing = 100
        moveLead(leadId, to: .won)
    }

    func markLost(_ leadId: String, reason: String) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        let previous = leads[index].dealStage
        leads[index].lostReason = reason
        leads[index].probabilityOfClosing = 0
        leads[index].dealStage = .lost
        leads[index].dealEvents.insert(
            DealEvent(type: .stageChange, summary: "Moved from \(previous.rawValue) to Lost"),
            at: 0
        )
        leads[index].dealEvents.insert(
            DealEvent(type: .note, summary: "Lost: \(reason.isEmpty ? "No reason recorded" : reason)"),
            at: 0
        )
        leads[index].updatedAt = .now
        saveLeads()
    }

    func companiesGrouped() -> [CompanyGroup] {
        let grouped = Dictionary(grouping: leads.filter { !$0.company.isEmpty }, by: \.company)
        return grouped
            .map { CompanyGroup(company: $0.key, leads: $0.value.sorted { $0.dealValue > $1.dealValue }) }
            .sorted { $0.totalValue > $1.totalValue }
    }

    func allTags() -> [String] {
        Array(Set(leads.flatMap(\.tags))).sorted()
    }

    func filteredLeads(
        search: String = "",
        stage: DealStage? = nil,
        listFilter: CRMListFilter = .all,
        sort: LeadSortOption = .recentlyUpdated
    ) -> [Lead] {
        var result = leads.filter { lead in
            let matchesSearch = search.isEmpty ||
                lead.name.localizedCaseInsensitiveContains(search) ||
                lead.company.localizedCaseInsensitiveContains(search) ||
                lead.tags.contains { $0.localizedCaseInsensitiveContains(search) }
            let matchesStage = stage == nil || lead.dealStage == stage
            let matchesFilter: Bool = switch listFilter {
            case .all: true
            case .favorites: lead.isFavorite
            case .hot: lead.priority == .hot && lead.dealStage.isActivePipeline
            case .stale: lead.isStale
            case .overdue: lead.isFollowUpOverdue && lead.dealStage.isActivePipeline
            }
            return matchesSearch && matchesStage && matchesFilter
        }

        switch sort {
        case .recentlyUpdated:
            result.sort { $0.updatedAt > $1.updatedAt }
        case .followUpDate:
            result.sort { ($0.nextFollowUpDate ?? .distantFuture) < ($1.nextFollowUpDate ?? .distantFuture) }
        case .dealValue:
            result.sort { $0.dealValue > $1.dealValue }
        case .healthScore:
            result.sort { $0.dealHealthScore > $1.dealHealthScore }
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        return result
    }

    func pinnedLeadCount() -> Int {
        leads.filter { $0.location.pinReminderEnabled && $0.location.hasCoordinates }.count
    }

    func weightedPipelineValue() -> Double {
        leads
            .filter { $0.dealStage.isActivePipeline }
            .reduce(0) { $0 + ($1.dealValue * Double($1.probabilityOfClosing) / 100) }
    }

    func wonRevenue() -> Double {
        leads.filter { $0.dealStage == .won }.reduce(0) { $0 + $1.dealValue }
    }

    func snapshot() -> CRMSnapshot {
        let calendar = Calendar.current
        let now = Date()
        let active = leads.filter { $0.dealStage.isActivePipeline }
        let won = leads.filter { $0.dealStage == .won }
        let lost = leads.filter { $0.dealStage == .lost }
        let closed = won.count + lost.count
        let winRate = closed > 0 ? Double(won.count) / Double(closed) * 100 : 0
        let avgDeal = won.isEmpty ? 0 : won.reduce(0) { $0 + $1.dealValue } / Double(won.count)

        let thisMonth = calendar.dateInterval(of: .month, for: now)!
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonth.start)!
        let lastMonthEnd = thisMonth.start

        let acquiredThisMonth = leads.filter { thisMonth.contains($0.createdAt) }.count
        let acquiredLastMonth = leads.filter { $0.createdAt >= lastMonthStart && $0.createdAt < lastMonthEnd }.count
        let acquisitionTrend = trendPercent(current: acquiredThisMonth, previous: acquiredLastMonth)

        let revenueThisMonth = won.filter { thisMonth.contains($0.updatedAt) }.reduce(0) { $0 + $1.dealValue }
        let revenueLastMonth = won.filter { $0.updatedAt >= lastMonthStart && $0.updatedAt < lastMonthEnd }.reduce(0) { $0 + $1.dealValue }
        let revenueTrend = trendPercent(current: Int(revenueThisMonth), previous: Int(revenueLastMonth))

        let monthlyTrends = buildMonthlyTrends(months: 6)
        let stageMetrics = DealStage.allCases.map { stage in
            let stageLeads = leads.filter { $0.dealStage == stage }
            return CRMStageMetric(stage: stage, count: stageLeads.count, value: stageLeads.reduce(0) { $0 + $1.dealValue })
        }

        let sourceCounts = Dictionary(grouping: leads, by: \.leadSource).map { ($0.key, $0.value.count) }
        let topSources = sourceCounts
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { CRMSourceMetric(source: $0.0, count: $0.1) }

        return CRMSnapshot(
            totalClients: leads.count,
            activeDeals: active.count,
            wonDeals: won.count,
            lostDeals: lost.count,
            pipelineValue: totalPipelineValue(),
            weightedPipeline: weightedPipelineValue(),
            wonRevenue: wonRevenue(),
            winRate: winRate,
            avgDealSize: avgDeal,
            acquisitionsThisMonth: acquiredThisMonth,
            acquisitionTrend: acquisitionTrend,
            revenueTrend: revenueTrend,
            monthlyTrends: monthlyTrends,
            stageMetrics: stageMetrics,
            topSources: topSources
        )
    }

    private func trendPercent(current: Int, previous: Int) -> Double {
        guard previous > 0 else { return current > 0 ? 100 : 0 }
        return (Double(current - previous) / Double(previous)) * 100
    }

    private func buildMonthlyTrends(months: Int) -> [CRMMonthlyPoint] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return (0..<months).reversed().compactMap { offset -> CRMMonthlyPoint? in
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: calendar.date(from: calendar.dateComponents([.year, .month], from: .now))!),
                  let interval = calendar.dateInterval(of: .month, for: monthStart) else { return nil }

            let monthLeads = leads.filter { interval.contains($0.createdAt) }
            let wonInMonth = leads.filter { $0.dealStage == .won && interval.contains($0.updatedAt) }

            return CRMMonthlyPoint(
                id: formatter.string(from: monthStart),
                month: monthStart,
                label: formatter.string(from: monthStart),
                acquisitions: monthLeads.count,
                revenueWon: wonInMonth.reduce(0) { $0 + $1.dealValue },
                pipelineAdded: monthLeads.reduce(0) { $0 + $1.dealValue }
            )
        }
    }

    private func saveLeads() {
        if let data = try? JSONEncoder().encode(leads) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: tasksStorageKey)
        }
    }

    private func notifyGeofencingSync() {
        syncGeofencing?(leads.filter { $0.location.pinReminderEnabled && $0.location.hasCoordinates })
    }

    static func sampleLeads(ownerId: String) -> [Lead] {
        [
            Lead(
                ownerId: ownerId,
                name: "Sarah Chen",
                company: "TechFlow Inc",
                phone: "555-0101",
                email: "sarah@techflow.io",
                dealValue: 45000,
                dealStage: .qualified,
                notes: "Interested in enterprise plan. Decision maker.",
                lastContactedDate: Calendar.current.date(byAdding: .day, value: -3, to: .now),
                nextFollowUpDate: Calendar.current.date(byAdding: .day, value: 2, to: .now),
                probabilityOfClosing: 65,
                aiRecommendedAction: "Send case study from similar SaaS company.",
                priority: .hot,
                contactIntel: ContactIntel(
                    interests: "AI automation, scaling outbound",
                    likes: "San Francisco Giants, craft coffee",
                    kidsNames: "Emma (8), Noah (5)",
                    conversationStarters: "Ask about their Series B hiring push"
                ),
                location: LeadLocation(
                    address: "123 Market St",
                    city: "San Francisco, CA",
                    latitude: 37.7937,
                    longitude: -122.3965,
                    locationLabel: "TechFlow HQ",
                    pinReminderEnabled: true
                )
            ),
            Lead(
                ownerId: ownerId,
                name: "Marcus Johnson",
                company: "BuildRight Co",
                phone: "555-0102",
                email: "marcus@buildright.com",
                dealValue: 12000,
                dealStage: .proposalSent,
                notes: "Waiting on budget approval from CFO.",
                lastContactedDate: Calendar.current.date(byAdding: .day, value: -7, to: .now),
                nextFollowUpDate: Calendar.current.date(byAdding: .day, value: 1, to: .now),
                probabilityOfClosing: 40,
                aiRecommendedAction: "Follow up with ROI calculator for CFO.",
                priority: .warm,
                contactIntel: ContactIntel(
                    likes: "Local basketball, weekend fishing",
                    familyNotes: "Wife named Lisa, renovating their home"
                ),
                location: LeadLocation(
                    address: "555 Bryant St",
                    city: "San Francisco, CA",
                    latitude: 37.7823,
                    longitude: -122.3971,
                    locationLabel: "BuildRight Office"
                )
            ),
            Lead(
                ownerId: ownerId,
                name: "Emily Rodriguez",
                company: "Growth Labs",
                phone: "555-0103",
                email: "emily@growthlabs.co",
                dealValue: 78000,
                dealStage: .negotiation,
                notes: "Negotiating contract terms. Very engaged.",
                lastContactedDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
                nextFollowUpDate: Calendar.current.date(byAdding: .day, value: 3, to: .now),
                probabilityOfClosing: 80,
                aiRecommendedAction: "Schedule final contract review call.",
                priority: .hot,
                location: LeadLocation(
                    address: "680 Folsom St",
                    city: "San Francisco, CA",
                    latitude: 37.7852,
                    longitude: -122.3960,
                    locationLabel: "Growth Labs"
                )
            )
        ]
    }
}
