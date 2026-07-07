import Foundation

struct SalesProposal: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var leadId: String?
    var title: String
    var body: String
    var amount: Double
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        leadId: String? = nil,
        title: String,
        body: String,
        amount: Double,
        createdAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.leadId = leadId
        self.title = title
        self.body = body
        self.amount = amount
        self.createdAt = createdAt
    }
}

struct WorkflowAutomation: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var trigger: String
    var actions: [String]
    var isEnabled: Bool

    init(id: String = UUID().uuidString, name: String, trigger: String, actions: [String], isEnabled: Bool = false) {
        self.id = id
        self.name = name
        self.trigger = trigger
        self.actions = actions
        self.isEnabled = isEnabled
    }

    static let defaults: [WorkflowAutomation] = [
        WorkflowAutomation(name: "New Lead Welcome", trigger: "New lead added", actions: ["Assign rep", "Create task", "Send welcome email"], isEnabled: true),
        WorkflowAutomation(name: "Hot Deal Alert", trigger: "Deal marked Hot", actions: ["Notify manager", "Schedule follow-up", "Generate battle card"]),
        WorkflowAutomation(name: "Stale Deal Revival", trigger: "No contact 14 days", actions: ["Assign revival drill", "Draft re-engagement email"]),
        WorkflowAutomation(name: "Proposal Follow-Up", trigger: "Moved to Proposal", actions: ["Create 3-day follow-up", "Notify AI coach"]),
        WorkflowAutomation(name: "Closed Won Celebration", trigger: "Deal closed won", actions: ["Log commission", "Post team win", "Schedule onboarding"])
    ]
}

struct MarketingCampaign: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var channel: String
    var status: String
    var sent: Int
    var opens: Int

    init(id: String = UUID().uuidString, name: String, channel: String, status: String = "Draft", sent: Int = 0, opens: Int = 0) {
        self.id = id
        self.name = name
        self.channel = channel
        self.status = status
        self.sent = sent
        self.opens = opens
    }

    static let templates: [MarketingCampaign] = [
        MarketingCampaign(name: "Cold Outreach Sequence", channel: "Email", status: "Template"),
        MarketingCampaign(name: "Re-engagement Drip", channel: "Email", status: "Template"),
        MarketingCampaign(name: "Event Follow-Up", channel: "SMS", status: "Template"),
        MarketingCampaign(name: "Newsletter — Product Update", channel: "Email", status: "Template")
    ]
}

struct ContractRecord: Codable, Identifiable, Equatable {
    var id: String
    var leadId: String
    var clientName: String
    var value: Double
    var status: String
    var expiresAt: Date?

    init(id: String = UUID().uuidString, leadId: String, clientName: String, value: Double, status: String = "Draft", expiresAt: Date? = nil) {
        self.id = id
        self.leadId = leadId
        self.clientName = clientName
        self.value = value
        self.status = status
        self.expiresAt = expiresAt
    }
}

struct CompetitorInsight: Identifiable, Equatable {
    let name: String
    let mentionCount: Int
    let activeDeals: Int
    let lostTo: Int
    var id: String { name }
}

struct BusinessIntelResponse: Equatable {
    let question: String
    let answer: String
    let generatedAt: Date
}

enum EmailAssistantType: String, CaseIterable, Identifiable {
    case coldOutreach = "Cold Outreach"
    case followUp = "Follow-Up"
    case meetingSummary = "Meeting Summary"
    case thankYou = "Thank You"
    case proposalEmail = "Proposal Email"
    case negotiation = "Negotiation"
    case renewal = "Renewal Reminder"
    case reengagement = "Re-engagement"

    var id: String { rawValue }
}
