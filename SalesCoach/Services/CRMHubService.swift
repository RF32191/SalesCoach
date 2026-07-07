import Foundation

@MainActor
@Observable
final class CRMHubService {
    private(set) var emailTemplates: [EmailTemplate] = []
    private(set) var sequences: [CRMSequence] = []
    private(set) var hubSpotSettings = HubSpotSyncSettings.default

    private let templatesKey = "salescoach_email_templates"
    private let sequencesKey = "salescoach_crm_sequences"
    private let hubspotKey = "salescoach_hubspot_settings"

    func load(for userId: String) {
        loadTemplates(for: userId)
        loadSequences(for: userId)
        loadHubSpot(for: userId)
        if emailTemplates.isEmpty { seedDefaults(for: userId) }
        if sequences.isEmpty { seedSequences(for: userId) }
    }

    func saveTemplates(for userId: String) {
        let key = "\(templatesKey)_\(userId)"
        if let data = try? JSONEncoder().encode(emailTemplates) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func saveSequences(for userId: String) {
        let key = "\(sequencesKey)_\(userId)"
        if let data = try? JSONEncoder().encode(sequences) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func saveHubSpot(for userId: String) {
        let key = "\(hubspotKey)_\(userId)"
        if let data = try? JSONEncoder().encode(hubSpotSettings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func setHubSpotEnabled(_ enabled: Bool, for userId: String) {
        hubSpotSettings.isEnabled = enabled
        saveHubSpot(for: userId)
    }

    func updatePortalId(_ portalId: String, for userId: String) {
        hubSpotSettings.portalId = portalId
        saveHubSpot(for: userId)
    }

    func applySequence(_ sequence: CRMSequence, to lead: inout Lead, crm: CRMService) {
        let base = Calendar.current.startOfDay(for: .now)
        for step in sequence.steps {
            let due = Calendar.current.date(byAdding: .day, value: step.dayOffset, to: base) ?? base
            switch step.channel {
            case .email:
                crm.logContact(for: lead.id, type: .email, summary: "Sequence: \(step.title)")
            case .call:
                crm.logContact(for: lead.id, type: .call, summary: "Sequence call task: \(step.title)")
            case .task:
                crm.addTask(CRMTask(leadId: lead.id, title: step.title, dueDate: due))
            }
            lead.dealEvents.insert(
                DealEvent(type: .followUpScheduled, summary: "Sequence '\(sequence.name)': \(step.title) (Day \(step.dayOffset))"),
                at: 0
            )
        }
        lead.nextFollowUpDate = Calendar.current.date(byAdding: .day, value: sequence.steps.first?.dayOffset ?? 1, to: base)
        crm.updateLead(lead)
    }

    func mergeLeads(primaryId: String, secondaryId: String, crm: CRMService) -> Lead? {
        guard let primaryIndex = crm.leads.firstIndex(where: { $0.id == primaryId }),
              let secondaryIndex = crm.leads.firstIndex(where: { $0.id == secondaryId }) else { return nil }
        var primary = crm.leads[primaryIndex]
        let secondary = crm.leads[secondaryIndex]

        if primary.phone.isEmpty { primary.phone = secondary.phone }
        if primary.email.isEmpty { primary.email = secondary.email }
        if primary.company.isEmpty { primary.company = secondary.company }
        primary.notes = [primary.notes, secondary.notes].filter { !$0.isEmpty }.joined(separator: "\n\n")
        primary.tags = Array(Set(primary.tags + secondary.tags))
        primary.objectionTags = Array(Set(primary.objectionTags + secondary.objectionTags))
        primary.activities = (primary.activities + secondary.activities).sorted { $0.date > $1.date }
        primary.dealEvents = (primary.dealEvents + secondary.dealEvents).sorted { $0.date > $1.date }
        primary.attachments = primary.attachments + secondary.attachments
        primary.dealValue = max(primary.dealValue, secondary.dealValue)
        primary.updatedAt = .now
        primary.dealEvents.insert(DealEvent(type: .note, summary: "Merged duplicate record \(secondary.name)"), at: 0)

        crm.leads[primaryIndex] = primary
        crm.leads.remove(at: secondaryIndex)
        crm.persistLeads()
        return primary
    }

    func findDuplicateGroups(in leads: [Lead]) -> [[Lead]] {
        var groups: [[Lead]] = []
        var used = Set<String>()
        for lead in leads {
            guard !used.contains(lead.id) else { continue }
            let matches = leads.filter { other in
                other.id != lead.id &&
                (other.name.lowercased() == lead.name.lowercased() ||
                 (!lead.company.isEmpty && other.company.lowercased() == lead.company.lowercased()) ||
                 (!lead.phone.isEmpty && other.phone.filter(\.isNumber) == lead.phone.filter(\.isNumber)))
            }
            if !matches.isEmpty {
                let group = [lead] + matches
                group.forEach { used.insert($0.id) }
                groups.append(group)
            }
        }
        return groups
    }

    func parseVoiceLog(_ transcript: String, leads: [Lead]) -> VoiceLogParseResult {
        let lower = transcript.lowercased()
        var matchedLead: Lead?
        for lead in leads {
            if lower.contains(lead.name.lowercased()) ||
                (!lead.company.isEmpty && lower.contains(lead.company.lowercased())) {
                matchedLead = lead
                break
            }
        }

        var activityType: LeadActivityType = .note
        if lower.contains("call") || lower.contains("called") || lower.contains("phone") { activityType = .call }
        if lower.contains("email") || lower.contains("emailed") { activityType = .email }
        if lower.contains("visit") || lower.contains("met") || lower.contains("stopped by") { activityType = .visit }

        var followUpDays: Int?
        if lower.contains("tomorrow") { followUpDays = 1 }
        else if lower.contains("next week") { followUpDays = 7 }
        else if lower.contains("friday") || lower.contains("monday") { followUpDays = 3 }

        return VoiceLogParseResult(
            transcript: transcript,
            matchedLead: matchedLead,
            activityType: activityType,
            summary: transcript,
            followUpDays: followUpDays
        )
    }

    func simulateHubSpotSync(crm: CRMService, userId: String) {
        hubSpotSettings.isEnabled = true
        hubSpotSettings.lastSyncedAt = .now
        hubSpotSettings.contactsPushed = crm.leads.count
        hubSpotSettings.dealsPushed = crm.leads.filter { $0.dealStage == .won }.count
        saveHubSpot(for: userId)
    }

    func setupChecklist(crm: CRMService, calendarEnabled: Bool, aiConfigured: Bool) -> CRMSetupChecklist {
        CRMSetupChecklist(items: [
            .init(id: "leads", title: "Add your first client", isComplete: !crm.leads.isEmpty, icon: "person.badge.plus"),
            .init(id: "pipeline", title: "Move a deal through pipeline", isComplete: crm.leads.contains { $0.dealStage != .newLead }, icon: "rectangle.split.3x1"),
            .init(id: "activity", title: "Log a call or email", isComplete: crm.leads.contains { !$0.activities.isEmpty }, icon: "phone.connection"),
            .init(id: "calendar", title: "Connect Apple Calendar", isComplete: calendarEnabled, icon: "calendar"),
            .init(id: "training", title: "Complete a roleplay", isComplete: false, icon: "mic.fill"),
            .init(id: "ai", title: "Configure AI backend", isComplete: aiConfigured, icon: "sparkles")
        ])
    }

    private func loadTemplates(for userId: String) {
        let key = "\(templatesKey)_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode([EmailTemplate].self, from: data) else {
            emailTemplates = []
            return
        }
        emailTemplates = stored
    }

    private func loadSequences(for userId: String) {
        let key = "\(sequencesKey)_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode([CRMSequence].self, from: data) else {
            sequences = []
            return
        }
        sequences = stored
    }

    private func loadHubSpot(for userId: String) {
        let key = "\(hubspotKey)_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode(HubSpotSyncSettings.self, from: data) else {
            hubSpotSettings = .default
            return
        }
        hubSpotSettings = stored
    }

    private func seedDefaults(for userId: String) {
        emailTemplates = [
            EmailTemplate(name: "Friendly Follow-Up", subject: "Following up — {{company}}", body: "Hi {{name}},\n\nWanted to follow up on our last conversation. Do you have 10 minutes this week?\n\nBest,"),
            EmailTemplate(name: "Proposal Sent", subject: "Proposal for {{company}}", body: "Hi {{name}},\n\nAttached is the proposal we discussed. Happy to walk through any questions.\n\nThanks,"),
            EmailTemplate(name: "Break-Up Email", subject: "Should I close your file?", body: "Hi {{name}},\n\nI haven't heard back and want to respect your time. Should I pause outreach for now?\n\nBest,")
        ]
        saveTemplates(for: userId)
    }

    private func seedSequences(for userId: String) {
        sequences = [
            CRMSequence(name: "New Lead Nurture", steps: [
                CRMSequenceStep(dayOffset: 0, channel: .email, title: "Intro email", templateBody: "Send intro and value prop"),
                CRMSequenceStep(dayOffset: 2, channel: .call, title: "Discovery call", templateBody: "Confirm pain points"),
                CRMSequenceStep(dayOffset: 5, channel: .task, title: "Send case study", templateBody: "Share relevant proof")
            ]),
            CRMSequence(name: "Proposal Follow-Up", steps: [
                CRMSequenceStep(dayOffset: 1, channel: .email, title: "Proposal check-in", templateBody: "Ask if they reviewed proposal"),
                CRMSequenceStep(dayOffset: 3, channel: .call, title: "Negotiation call", templateBody: "Handle objections"),
                CRMSequenceStep(dayOffset: 7, channel: .task, title: "Final follow-up", templateBody: "Confirm decision timeline")
            ])
        ]
        saveSequences(for: userId)
    }
}

struct VoiceLogParseResult {
    let transcript: String
    let matchedLead: Lead?
    let activityType: LeadActivityType
    let summary: String
    let followUpDays: Int?
}
