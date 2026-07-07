import Foundation

enum AccountingEntryType: String, Codable, CaseIterable, Identifiable {
    case commission = "Commission"
    case expense = "Expense"
    case invoice = "Invoice Sent"
    case payment = "Payment Received"
    case adjustment = "Adjustment"
    case tokenCharge = "AI Token Charge"

    var id: String { rawValue }
}

enum AIBillingFeature: String, Codable, CaseIterable, Identifiable {
    case scriptGeneration = "Script Generation"
    case complaintResponse = "Complaint Response"
    case billingAgentReview = "Billing Agent Review"
    case managerBrief = "Manager Brief"
    case chatCoach = "Chat Coach"
    case roleplay = "Roleplay"
    case crmAssist = "CRM Assist"

    var id: String { rawValue }

    var minimumTokens: Int {
        switch self {
        case .scriptGeneration: 180
        case .complaintResponse: 120
        case .billingAgentReview: 250
        case .managerBrief: 300
        case .chatCoach: 80
        case .roleplay: 200
        case .crmAssist: 100
        }
    }

    var estimatedTokens: Int {
        switch self {
        case .scriptGeneration: 400
        case .complaintResponse: 250
        case .billingAgentReview: 500
        case .managerBrief: 600
        case .chatCoach: 150
        case .roleplay: 350
        case .crmAssist: 200
        }
    }

    func billableTokens(actual: Int) -> Int {
        max(minimumTokens, actual)
    }

    func dollarCost(forTokens tokens: Int) -> Double {
        Double(tokens) / 1000.0 * TokenBillingRates.costPerThousandTokens
    }
}

enum TokenBillingRates {
    static let costPerThousandTokens = 0.002
}

struct TokenChargeRecord: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var feature: AIBillingFeature
    var tokensUsed: Int
    var billableTokens: Int
    var dollarCost: Double
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        feature: AIBillingFeature,
        tokensUsed: Int,
        billableTokens: Int,
        dollarCost: Double,
        createdAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.feature = feature
        self.tokensUsed = tokensUsed
        self.billableTokens = billableTokens
        self.dollarCost = dollarCost
        self.createdAt = createdAt
    }
}

struct AccountingEntry: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var leadId: String?
    var type: AccountingEntryType
    var amount: Double
    var note: String
    var loggedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        leadId: String? = nil,
        type: AccountingEntryType,
        amount: Double,
        note: String,
        loggedAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.leadId = leadId
        self.type = type
        self.amount = amount
        self.note = note
        self.loggedAt = loggedAt
    }
}

enum ComplaintStatus: String, Codable, CaseIterable, Identifiable {
    case open = "Open"
    case investigating = "Investigating"
    case resolved = "Resolved"
    case escalated = "Escalated"

    var id: String { rawValue }
}

enum ComplaintPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var id: String { rawValue }
}

struct ClientComplaint: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var leadId: String?
    var clientName: String
    var company: String
    var summary: String
    var details: String
    var status: ComplaintStatus
    var priority: ComplaintPriority
    var aiSuggestedResponse: String?
    var resolutionNotes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        leadId: String? = nil,
        clientName: String,
        company: String = "",
        summary: String,
        details: String = "",
        status: ComplaintStatus = .open,
        priority: ComplaintPriority = .medium,
        aiSuggestedResponse: String? = nil,
        resolutionNotes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.leadId = leadId
        self.clientName = clientName
        self.company = company
        self.summary = summary
        self.details = details
        self.status = status
        self.priority = priority
        self.aiSuggestedResponse = aiSuggestedResponse
        self.resolutionNotes = resolutionNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum ScriptType: String, Codable, CaseIterable, Identifiable {
    case coldCall = "Cold Call"
    case followUp = "Follow-Up"
    case objection = "Objection Response"
    case closing = "Closing"
    case voicemail = "Voicemail"
    case email = "Email"
    case discovery = "Discovery"

    var id: String { rawValue }
}

struct SalesScript: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var title: String
    var scriptType: ScriptType
    var leadId: String?
    var body: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        title: String,
        scriptType: ScriptType,
        leadId: String? = nil,
        body: String,
        tags: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.scriptType = scriptType
        self.leadId = leadId
        self.body = body
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct RepDNASkill: Identifiable, Equatable {
    let name: String
    let score: Int
    let trend: String

    var id: String { name }
}

struct RepDNAProfile: Equatable {
    let headline: String
    let strongestSkill: String
    let weakestSkill: String
    let skills: [RepDNASkill]
    let dailyDrillTitle: String
    let dailyDrillScenario: TrainingScenario
    let weeklyChallenge: WeeklyChallenge
}

struct WeeklyChallenge: Codable, Equatable {
    var contactsTarget: Int
    var roleplaysTarget: Int
    var contactsDone: Int
    var roleplaysDone: Int

    var isComplete: Bool {
        contactsDone >= contactsTarget && roleplaysDone >= roleplaysTarget
    }

    var progressText: String {
        "\(contactsDone)/\(contactsTarget) contacts · \(roleplaysDone)/\(roleplaysTarget) roleplays"
    }
}

enum BillingAgentActionType: String, Codable, CaseIterable, Identifiable {
    case recommendUpgrade = "Recommend Upgrade"
    case optimizeUsage = "Optimize Usage"
    case invoiceDraft = "Invoice Draft"
    case paymentReminder = "Payment Reminder"
    case costAlert = "Cost Alert"
    case autoApplied = "Auto Applied"

    var id: String { rawValue }
}

struct BillingAgentAction: Codable, Identifiable, Equatable {
    var id: String
    var type: BillingAgentActionType
    var title: String
    var detail: String
    var suggestedTier: SubscriptionTier?
    var estimatedSavings: Double?
    var autoExecuted: Bool
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        type: BillingAgentActionType,
        title: String,
        detail: String,
        suggestedTier: SubscriptionTier? = nil,
        estimatedSavings: Double? = nil,
        autoExecuted: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.detail = detail
        self.suggestedTier = suggestedTier
        self.estimatedSavings = estimatedSavings
        self.autoExecuted = autoExecuted
        self.createdAt = createdAt
    }
}

struct BillingAgentReport: Equatable {
    let summary: String
    let actions: [BillingAgentAction]
    let recommendedPlan: SubscriptionTier
    let monthlyEstimate: String
    let autonomousNote: String
}

struct DealReplayEvent: Identifiable, Equatable {
    let id: String
    let date: Date
    let title: String
    let detail: String
    let icon: String
    let coachingTip: String?
}

struct ManagerMorningBrief: Equatable {
    let headline: String
    let repHighlights: [String]
    let coachingAssignments: [String]
    let pipelineAlerts: [String]
    let teamWins: [String]
}

struct SmartRouteStop: Identifiable, Equatable {
    let id: String
    let lead: Lead
    let order: Int
    let coachingNote: String
}
