import Foundation

enum DealStage: String, Codable, CaseIterable, Identifiable {
    case newLead = "New Lead"
    case contacted = "Contacted"
    case qualified = "Qualified"
    case proposalSent = "Proposal Sent"
    case negotiation = "Negotiation"
    case won = "Won"
    case lost = "Lost"

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .newLead: 0
        case .contacted: 1
        case .qualified: 2
        case .proposalSent: 3
        case .negotiation: 4
        case .won: 5
        case .lost: 6
        }
    }
}

enum LeadPriority: String, Codable, CaseIterable, Identifiable {
    case hot = "Hot"
    case warm = "Warm"
    case cold = "Cold"

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .hot: 0
        case .warm: 1
        case .cold: 2
        }
    }
}

struct Lead: Codable, Identifiable, Equatable {
    var id: String
    var ownerId: String
    var name: String
    var company: String
    var phone: String
    var email: String
    var dealValue: Double
    var dealStage: DealStage
    var notes: String
    var lastContactedDate: Date?
    var nextFollowUpDate: Date?
    var probabilityOfClosing: Int
    var aiRecommendedAction: String
    var leadSource: String
    var priority: LeadPriority
    var tags: [String]
    var contactIntel: ContactIntel
    var referralSource: String
    var competitorName: String
    var objectionTags: [String]
    var lostReason: String
    var dealEvents: [DealEvent]
    var location: LeadLocation
    var activities: [LeadActivity]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        ownerId: String,
        name: String,
        company: String = "",
        phone: String = "",
        email: String = "",
        dealValue: Double = 0,
        dealStage: DealStage = .newLead,
        notes: String = "",
        lastContactedDate: Date? = nil,
        nextFollowUpDate: Date? = nil,
        probabilityOfClosing: Int = 20,
        aiRecommendedAction: String = "Send an introductory email to establish rapport.",
        leadSource: String = "Manual",
        priority: LeadPriority = .warm,
        tags: [String] = [],
        contactIntel: ContactIntel = ContactIntel(),
        referralSource: String = "",
        competitorName: String = "",
        objectionTags: [String] = [],
        lostReason: String = "",
        dealEvents: [DealEvent] = [],
        location: LeadLocation = LeadLocation(),
        activities: [LeadActivity] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.company = company
        self.phone = phone
        self.email = email
        self.dealValue = dealValue
        self.dealStage = dealStage
        self.notes = notes
        self.lastContactedDate = lastContactedDate
        self.nextFollowUpDate = nextFollowUpDate
        self.probabilityOfClosing = probabilityOfClosing
        self.aiRecommendedAction = aiRecommendedAction
        self.leadSource = leadSource
        self.priority = priority
        self.tags = tags
        self.contactIntel = contactIntel
        self.referralSource = referralSource
        self.competitorName = competitorName
        self.objectionTags = objectionTags
        self.lostReason = lostReason
        self.dealEvents = dealEvents
        self.location = location
        self.activities = activities
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, ownerId, name, company, phone, email, dealValue, dealStage, notes
        case lastContactedDate, nextFollowUpDate, probabilityOfClosing, aiRecommendedAction
        case leadSource, priority, tags, contactIntel, referralSource, competitorName, objectionTags, lostReason, dealEvents, location, activities, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        name = try container.decode(String.self, forKey: .name)
        company = try container.decodeIfPresent(String.self, forKey: .company) ?? ""
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        dealValue = try container.decodeIfPresent(Double.self, forKey: .dealValue) ?? 0
        dealStage = try container.decodeIfPresent(DealStage.self, forKey: .dealStage) ?? .newLead
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        lastContactedDate = try container.decodeIfPresent(Date.self, forKey: .lastContactedDate)
        nextFollowUpDate = try container.decodeIfPresent(Date.self, forKey: .nextFollowUpDate)
        probabilityOfClosing = try container.decodeIfPresent(Int.self, forKey: .probabilityOfClosing) ?? 20
        aiRecommendedAction = try container.decodeIfPresent(String.self, forKey: .aiRecommendedAction)
            ?? "Send an introductory email to establish rapport."
        leadSource = try container.decodeIfPresent(String.self, forKey: .leadSource) ?? "Manual"
        priority = try container.decodeIfPresent(LeadPriority.self, forKey: .priority) ?? .warm
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        contactIntel = try container.decodeIfPresent(ContactIntel.self, forKey: .contactIntel) ?? ContactIntel()
        referralSource = try container.decodeIfPresent(String.self, forKey: .referralSource) ?? ""
        competitorName = try container.decodeIfPresent(String.self, forKey: .competitorName) ?? ""
        objectionTags = try container.decodeIfPresent([String].self, forKey: .objectionTags) ?? []
        lostReason = try container.decodeIfPresent(String.self, forKey: .lostReason) ?? ""
        dealEvents = try container.decodeIfPresent([DealEvent].self, forKey: .dealEvents) ?? []
        location = try container.decodeIfPresent(LeadLocation.self, forKey: .location) ?? LeadLocation()
        activities = try container.decodeIfPresent([LeadActivity].self, forKey: .activities) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
    }

    var timelineEvents: [DealEvent] {
        let activityEvents = activities.map { activity in
            DealEvent(type: Self.eventType(for: activity.type), summary: activity.summary, date: activity.date)
        }
        return (dealEvents + activityEvents).sorted { $0.date > $1.date }
    }

    private static func eventType(for type: LeadActivityType) -> DealEventType {
        switch type {
        case .call: return .call
        case .email: return .email
        case .meeting: return .note
        case .visit: return .visit
        case .note: return .note
        }
    }
}
