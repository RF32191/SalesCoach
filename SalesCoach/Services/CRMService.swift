import Foundation

@MainActor
@Observable
final class CRMService {
    var leads: [Lead] = []
    var syncGeofencing: (([Lead]) -> Void)?

    private let storageKey = "salescoach_leads"

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

    func addLead(_ lead: Lead) {
        leads.insert(lead, at: 0)
        saveLeads()
        notifyGeofencingSync()
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

    func pinnedLeadCount() -> Int {
        leads.filter { $0.location.pinReminderEnabled && $0.location.hasCoordinates }.count
    }

    private func saveLeads() {
        if let data = try? JSONEncoder().encode(leads) {
            UserDefaults.standard.set(data, forKey: storageKey)
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
