import Foundation

struct LeadAttachment: Codable, Identifiable, Equatable {
    var id: String
    var fileName: String
    var kind: AttachmentKind
    var addedAt: Date
    var note: String

    enum AttachmentKind: String, Codable, CaseIterable {
        case proposal = "Proposal"
        case contract = "Contract"
        case photo = "Photo"
        case note = "Document"
    }

    init(id: String = UUID().uuidString, fileName: String, kind: AttachmentKind, addedAt: Date = .now, note: String = "") {
        self.id = id
        self.fileName = fileName
        self.kind = kind
        self.addedAt = addedAt
        self.note = note
    }
}

struct EmailTemplate: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var subject: String
    var body: String
    var category: String

    init(id: String = UUID().uuidString, name: String, subject: String, body: String, category: String = "Follow-Up") {
        self.id = id
        self.name = name
        self.subject = subject
        self.body = body
        self.category = category
    }
}

struct CRMSequenceStep: Codable, Identifiable, Equatable {
    var id: String
    var dayOffset: Int
    var channel: SequenceChannel
    var title: String
    var templateBody: String

    enum SequenceChannel: String, Codable, CaseIterable {
        case email = "Email"
        case call = "Call Task"
        case task = "Task"
    }

    init(id: String = UUID().uuidString, dayOffset: Int, channel: SequenceChannel, title: String, templateBody: String) {
        self.id = id
        self.dayOffset = dayOffset
        self.channel = channel
        self.title = title
        self.templateBody = templateBody
    }
}

struct CRMSequence: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var steps: [CRMSequenceStep]
    var isActive: Bool

    init(id: String = UUID().uuidString, name: String, steps: [CRMSequenceStep], isActive: Bool = true) {
        self.id = id
        self.name = name
        self.steps = steps
        self.isActive = isActive
    }
}

struct WinLossAutopsy: Equatable {
    let headline: String
    let whatWorked: [String]
    let whatToImprove: [String]
    let playbookSnippet: String
    let recommendedDrill: String
    let nextActions: [String]
}

struct BattleCard: Identifiable, Equatable {
    let id: String
    let competitor: String
    let strengths: [String]
    let weaknesses: [String]
    let talkTrack: String
    let proofPoints: [String]
}

struct ObjectionStat: Identifiable, Equatable {
    let objection: String
    let count: Int
    let winRate: Double
    let suggestedResponse: String

    var id: String { objection }
}

struct QuotaSettings: Codable, Equatable {
    var monthlyRevenueTarget: Double
    var defaultCommissionRate: Double

    static let `default` = QuotaSettings(monthlyRevenueTarget: 25_000, defaultCommissionRate: 0.10)
}

struct TeamWinHighlight: Identifiable, Equatable {
    let id: String
    let repName: String
    let clientLabel: String
    let amount: Double
    let loggedAt: Date
    let summary: String
}

struct HubSpotSyncSettings: Codable, Equatable {
    var isEnabled: Bool
    var portalId: String
    var lastSyncedAt: Date?
    var contactsPushed: Int
    var dealsPushed: Int

    static let `default` = HubSpotSyncSettings(isEnabled: false, portalId: "", lastSyncedAt: nil, contactsPushed: 0, dealsPushed: 0)
}

struct CRMSetupChecklist: Equatable {
    let items: [CRMSetupItem]

    struct CRMSetupItem: Identifiable, Equatable {
        let id: String
        let title: String
        let isComplete: Bool
        let icon: String
    }
}
