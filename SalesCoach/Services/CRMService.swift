import Foundation

@MainActor
@Observable
final class CRMService {
    var leads: [Lead] = []
    var tasks: [CRMTask] = []
    var syncGeofencing: (([Lead]) -> Void)?
    var onContactLogged: (() -> Void)?
    var onDealWon: (() -> Void)?
    var recordAudit: ((AuditEntry) -> Void)?
    var recordClosedOrder: ((ClosedOrder, AuditEntry) -> Void)?
    var onCalendarFollowUp: ((String, Date, String?) -> Void)?
    var stageChangeGate: ((DealStage, String) -> (allowed: Bool, message: String))?
    private(set) var lastStageChangeBlockMessage: String?
    var defaultCommissionRate: Double = 0.10

    private let storageKey = "salescoach_leads"
    private let tasksStorageKey = "salescoach_crm_tasks"

    func loadLeads(for userId: String) {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([Lead].self, from: data) else {
            leads = []
            removeBundledExampleLeadsIfNeeded(for: userId)
            notifyGeofencingSync()
            return
        }
        leads = stored.filter { $0.ownerId == userId }
        removeBundledExampleLeadsIfNeeded(for: userId)
        notifyGeofencingSync()
    }

    func loadExampleLeads(for userId: String) {
        for lead in ExampleData.exampleLeads(ownerId: userId) {
            guard !CRMEnhancements.isDuplicate(lead, in: leads) else { continue }
            var example = lead
            example.dealEvents.insert(DealEvent(type: .note, summary: "Example client loaded for demo"), at: 0)
            leads.insert(example, at: 0)
        }
        saveLeads()
        notifyGeofencingSync()
    }

    func removeExampleLeads(for userId: String) {
        leads.removeAll { $0.ownerId == userId && ExampleData.isExampleLead($0) }
        saveLeads()
        notifyGeofencingSync()
    }

    func clearAllLeads(for userId: String) {
        let removedIds = Set(leads.filter { $0.ownerId == userId }.map(\.id))
        leads.removeAll { $0.ownerId == userId }
        tasks.removeAll { removedIds.contains($0.leadId) }
        saveLeads()
        saveTasks()
        notifyGeofencingSync()
    }

    private func removeBundledExampleLeadsIfNeeded(for userId: String) {
        let migrationKey = "salescoach_removed_sample_leads_\(userId)"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        leads.removeAll { $0.ownerId == userId && ExampleData.isExampleLead($0) }
        UserDefaults.standard.set(true, forKey: migrationKey)
        saveLeads()
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

    func addLead(_ lead: Lead, source: AuditSource = .manual, actorId: String? = nil) -> Bool {
        guard !CRMEnhancements.isDuplicate(lead, in: leads) else { return false }
        var newLead = lead
        if newLead.nextFollowUpDate == nil {
            newLead.nextFollowUpDate = CRMEnhancements.smartFollowUpDate(for: newLead)
        }
        newLead.dealEvents.insert(DealEvent(type: .note, summary: "Lead added to CRM"), at: 0)
        leads.insert(newLead, at: 0)
        saveLeads()
        notifyGeofencingSync()
        recordAudit?(AuditEntry(
            entityType: .lead,
            entityId: newLead.id,
            entityLabel: newLead.name,
            actorId: actorId ?? newLead.ownerId,
            action: "lead.created",
            summary: "Added \(newLead.name) to CRM",
            source: source
        ))
        Task { await integrations?.notifyZapier(lead: newLead, event: "lead.created") }
        return true
    }

    @discardableResult
    func updateLead(_ lead: Lead, source: AuditSource = .manual, actorId: String? = nil) -> Bool {
        guard let index = leads.firstIndex(where: { $0.id == lead.id }) else { return false }
        let previous = leads[index]
        if lead.dealStage != previous.dealStage, let gate = stageChangeGate {
            let check = gate(lead.dealStage, actorId ?? lead.ownerId)
            if !check.allowed {
                lastStageChangeBlockMessage = check.message
                return false
            }
        }
        var updated = lead
        updated.updatedAt = .now
        if lead.dealStage != previous.dealStage {
            updated.dealEvents.insert(
                DealEvent(type: .stageChange, summary: "Moved from \(previous.dealStage.rawValue) to \(lead.dealStage.rawValue)"),
                at: 0
            )
        }
        leads[index] = updated
        saveLeads()
        notifyGeofencingSync()
        let changes = CRMService.diffLead(previous: previous, updated: updated)
        guard !changes.isEmpty else {
            lastStageChangeBlockMessage = nil
            return true
        }
        recordAudit?(AuditEntry(
            entityType: .lead,
            entityId: lead.id,
            entityLabel: lead.name,
            actorId: actorId ?? lead.ownerId,
            action: lead.dealStage != previous.dealStage ? "deal.stage_changed" : "lead.updated",
            summary: lead.dealStage != previous.dealStage
                ? "\(lead.name): \(previous.dealStage.rawValue) → \(lead.dealStage.rawValue)"
                : "Updated \(lead.name)",
            source: source,
            changes: changes
        ))
        lastStageChangeBlockMessage = nil
        return true
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

    @discardableResult
    func moveLead(_ leadId: String, to stage: DealStage, source: AuditSource = .manual, actorId: String? = nil) -> Bool {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return false }
        let previous = leads[index].dealStage
        guard previous != stage else { return true }
        let lead = leads[index]
        if let gate = stageChangeGate {
            let check = gate(stage, actorId ?? lead.ownerId)
            if !check.allowed {
                lastStageChangeBlockMessage = check.message
                return false
            }
        }
        leads[index].dealStage = stage
        leads[index].dealEvents.insert(
            DealEvent(type: .stageChange, summary: "Moved from \(previous.rawValue) to \(stage.rawValue)"),
            at: 0
        )
        leads[index].updatedAt = .now
        saveLeads()
        recordAudit?(AuditEntry(
            entityType: .lead,
            entityId: leadId,
            entityLabel: lead.name,
            actorId: actorId ?? lead.ownerId,
            action: "deal.stage_changed",
            summary: "\(lead.name): \(previous.rawValue) → \(stage.rawValue)",
            source: source,
            changes: [FieldChange(field: "stage", oldValue: previous.rawValue, newValue: stage.rawValue)]
        ))
        lastStageChangeBlockMessage = nil
        return true
    }

    func updatePriority(for leadId: String, priority: LeadPriority) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        leads[index].priority = priority
        leads[index].updatedAt = .now
        saveLeads()
    }

    func scheduleFollowUp(for leadId: String, date: Date, source: AuditSource = .manual, actorId: String? = nil) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        let lead = leads[index]
        leads[index].nextFollowUpDate = date
        leads[index].dealEvents.insert(
            DealEvent(type: .followUpScheduled, summary: "Follow-up scheduled for \(date.formatted(date: .abbreviated, time: .omitted))"),
            at: 0
        )
        leads[index].updatedAt = .now
        saveLeads()
        onCalendarFollowUp?("Follow up: \(lead.name)", date, lead.company)
        recordAudit?(AuditEntry(
            entityType: .lead,
            entityId: leadId,
            entityLabel: lead.name,
            actorId: actorId ?? lead.ownerId,
            action: "followup.scheduled",
            summary: "Follow-up set for \(lead.name)",
            source: source
        ))
    }

    func logContact(for leadId: String, type: LeadActivityType, summary: String, source: AuditSource = .manual, actorId: String? = nil) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        let lead = leads[index]
        let activity = LeadActivity(type: type, summary: summary)
        leads[index].activities.insert(activity, at: 0)
        leads[index].lastContactedDate = .now
        leads[index].updatedAt = .now
        saveLeads()
        onContactLogged?()
        recordAudit?(AuditEntry(
            entityType: .lead,
            entityId: leadId,
            entityLabel: lead.name,
            actorId: actorId ?? lead.ownerId,
            action: "contact.logged",
            summary: "\(type.rawValue): \(summary)",
            source: source
        ))
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

    @discardableResult
    func importCSV(_ csv: String, ownerId: String, source: CRMImportSource = .genericCSV) -> CRMImportResult {
        importRows(CRMImportParser.parse(text: csv, source: source), ownerId: ownerId, source: source)
    }

    @discardableResult
    func importRows(_ rows: [CSVLeadRow], ownerId: String, source: CRMImportSource) -> CRMImportResult {
        guard !rows.isEmpty else {
            return CRMImportResult(imported: 0, skipped: 0, duplicates: 0, errors: ["No valid rows found in file."])
        }
        var imported = 0, skipped = 0, duplicates = 0, errors: [String] = []
        for row in rows {
            let lead = row.makeLead(ownerId: ownerId)
            if CRMEnhancements.isDuplicate(lead, in: leads) {
                duplicates += 1
                continue
            }
            leads.insert(lead, at: 0)
            imported += 1
            Task { await integrations?.notifyZapier(lead: lead, event: "lead.imported") }
        }
        if imported > 0 {
            saveLeads()
            notifyGeofencingSync()
        }
        if duplicates > 0 {
            errors.append("\(duplicates) duplicate contacts skipped.")
        }
        return CRMImportResult(imported: imported, skipped: skipped, duplicates: duplicates, errors: errors)
    }

    var integrations: IntegrationService?

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

    func markWon(_ leadId: String, finalValue: Double? = nil, source: AuditSource = .manual, actorId: String? = nil) {
        closeOrder(
            leadId: leadId,
            finalValue: finalValue,
            notes: "Deal marked won",
            source: source,
            actorId: actorId
        )
    }

    func closeOrder(
        leadId: String,
        finalValue: Double?,
        notes: String,
        source: AuditSource = .manual,
        actorId: String? = nil
    ) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        let lead = leads[index]
        let value = finalValue ?? lead.dealValue
        if let finalValue { leads[index].dealValue = finalValue }
        leads[index].probabilityOfClosing = 100
        moveLead(leadId, to: .won, source: source, actorId: actorId)
        let order = ClosedOrder(
            leadId: leadId,
            ownerId: lead.ownerId,
            clientName: lead.name,
            company: lead.company,
            finalValue: value,
            lineItems: value > 0 ? [OrderLineItem(name: lead.company.isEmpty ? lead.name : lead.company, unitPrice: value)] : [],
            notes: notes,
            source: source,
            commissionRate: defaultCommissionRate
        )
        let auditEntry = AuditEntry(
            entityType: .order,
            entityId: order.id,
            entityLabel: lead.name,
            actorId: actorId ?? lead.ownerId,
            action: "order.closed",
            summary: "Sale closed — \(lead.name) for \(Int(value))",
            source: source,
            changes: [FieldChange(field: "dealValue", oldValue: String(Int(lead.dealValue)), newValue: String(Int(value)))]
        )
        recordClosedOrder?(order, auditEntry)
        onDealWon?()
    }

    func markLost(_ leadId: String, reason: String, source: AuditSource = .manual, actorId: String? = nil) {
        guard let index = leads.firstIndex(where: { $0.id == leadId }) else { return }
        let previous = leads[index].dealStage
        let lead = leads[index]
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
        recordAudit?(AuditEntry(
            entityType: .lead,
            entityId: leadId,
            entityLabel: lead.name,
            actorId: actorId ?? lead.ownerId,
            action: "deal.lost",
            summary: "\(lead.name) marked lost",
            source: source
        ))
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
                lead.email.localizedCaseInsensitiveContains(search) ||
                lead.phone.localizedCaseInsensitiveContains(search) ||
                lead.notes.localizedCaseInsensitiveContains(search) ||
                lead.leadSource.localizedCaseInsensitiveContains(search) ||
                lead.tags.contains { $0.localizedCaseInsensitiveContains(search) } ||
                lead.activities.contains { $0.summary.localizedCaseInsensitiveContains(search) }
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

    func recentCommunicationActivities(limit: Int = 30) -> [CommunicationActivityItem] {
        leads.flatMap { lead in
            lead.activities
                .filter { $0.type == .call || $0.type == .email }
                .map { activity in
                    CommunicationActivityItem(
                        leadId: lead.id,
                        leadName: lead.name,
                        company: lead.company,
                        phone: lead.phone,
                        email: lead.email,
                        activity: activity
                    )
                }
        }
        .sorted { $0.activity.date > $1.activity.date }
        .prefix(limit)
        .map { $0 }
    }

    func persistLeads() {
        saveLeads()
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

    static func diffLead(previous: Lead, updated: Lead) -> [FieldChange] {
        var changes: [FieldChange] = []
        if previous.dealStage != updated.dealStage {
            changes.append(FieldChange(field: "stage", oldValue: previous.dealStage.rawValue, newValue: updated.dealStage.rawValue))
        }
        if Int(previous.dealValue) != Int(updated.dealValue) {
            changes.append(FieldChange(field: "dealValue", oldValue: String(Int(previous.dealValue)), newValue: String(Int(updated.dealValue))))
        }
        if previous.probabilityOfClosing != updated.probabilityOfClosing {
            changes.append(FieldChange(field: "probability", oldValue: String(previous.probabilityOfClosing), newValue: String(updated.probabilityOfClosing)))
        }
        if previous.priority != updated.priority {
            changes.append(FieldChange(field: "priority", oldValue: previous.priority.rawValue, newValue: updated.priority.rawValue))
        }
        return changes
    }
}
