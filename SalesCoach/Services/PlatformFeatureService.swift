import Foundation

@MainActor
@Observable
final class PlatformFeatureService {
    private(set) var proposals: [SalesProposal] = []
    private(set) var workflows: [WorkflowAutomation] = WorkflowAutomation.defaults
    private(set) var campaigns: [MarketingCampaign] = MarketingCampaign.templates
    private(set) var contracts: [ContractRecord] = []
    private(set) var lastIntelResponse: BusinessIntelResponse?

    private let proposalsKey = "salescoach_proposals"
    private let workflowsKey = "salescoach_workflows"
    private let contractsKey = "salescoach_contracts"
    private let campaignsKey = "salescoach_campaigns"

    func load(for userId: String) {
        proposals = decode(SalesProposal.self, key: proposalsKey).filter { $0.userId == userId }.sorted { $0.createdAt > $1.createdAt }
        let storedWorkflows = decode(WorkflowAutomation.self, key: workflowsKey)
        if !storedWorkflows.isEmpty { workflows = storedWorkflows }
        contracts = decode(ContractRecord.self, key: contractsKey).sorted { ($0.expiresAt ?? .distantPast) < ($1.expiresAt ?? .distantPast) }
        let storedCampaigns = decode(MarketingCampaign.self, key: campaignsKey)
        if !storedCampaigns.isEmpty {
            campaigns = storedCampaigns
        }
    }

    func saveProposal(_ proposal: SalesProposal, for userId: String) {
        if let index = proposals.firstIndex(where: { $0.id == proposal.id }) {
            proposals[index] = proposal
        } else {
            proposals.insert(proposal, at: 0)
        }
        var all = decode(SalesProposal.self, key: proposalsKey).filter { $0.userId != userId }
        all.append(contentsOf: proposals)
        persist(all, key: proposalsKey)
    }

    func toggleWorkflow(_ id: String) {
        guard let index = workflows.firstIndex(where: { $0.id == id }) else { return }
        workflows[index].isEnabled.toggle()
        persist(workflows, key: workflowsKey)
    }

    func addContract(from lead: Lead) {
        guard !contracts.contains(where: { $0.leadId == lead.id }) else { return }
        contracts.insert(
            ContractRecord(
                leadId: lead.id,
                clientName: lead.name,
                value: lead.dealValue,
                status: lead.dealStage == .won ? "Active" : "Draft",
                expiresAt: Calendar.current.date(byAdding: .year, value: 1, to: .now)
            ),
            at: 0
        )
        persist(contracts, key: contractsKey)
    }

    func competitorInsights(from leads: [Lead]) -> [CompetitorInsight] {
        Dictionary(grouping: leads.filter { !$0.competitorName.isEmpty }, by: \.competitorName)
            .map { name, items in
                CompetitorInsight(
                    name: name,
                    mentionCount: items.count,
                    activeDeals: items.filter { $0.dealStage.isActivePipeline }.count,
                    lostTo: items.filter { $0.dealStage == .lost }.count
                )
            }
            .sorted { $0.mentionCount > $1.mentionCount }
    }

    func storeIntel(question: String, answer: String) {
        lastIntelResponse = BusinessIntelResponse(question: question, answer: answer, generatedAt: .now)
    }

    func createCampaign(name: String, channel: String) {
        campaigns.insert(MarketingCampaign(name: name, channel: channel, status: "Draft"), at: 0)
        persist(campaigns, key: campaignsKey)
    }

    func launchCampaign(_ id: String) {
        guard let index = campaigns.firstIndex(where: { $0.id == id }) else { return }
        campaigns[index].status = "Active"
        campaigns[index].sent = max(campaigns[index].sent, 1)
        persist(campaigns, key: campaignsKey)
    }

    func recordCampaignOpen(_ id: String) {
        guard let index = campaigns.firstIndex(where: { $0.id == id }) else { return }
        campaigns[index].opens += 1
        persist(campaigns, key: campaignsKey)
    }

    func proposals(for userId: String) -> [SalesProposal] {
        proposals.filter { $0.userId == userId }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode([T].self, from: data) else { return [] }
        return stored
    }

    private func persist<T: Encodable>(_ items: [T], key: String) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
