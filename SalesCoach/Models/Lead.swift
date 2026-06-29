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
        self.location = location
        self.activities = activities
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, ownerId, name, company, phone, email, dealValue, dealStage, notes
        case lastContactedDate, nextFollowUpDate, probabilityOfClosing, aiRecommendedAction
        case leadSource, location, activities, createdAt, updatedAt
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
        location = try container.decodeIfPresent(LeadLocation.self, forKey: .location) ?? LeadLocation()
        activities = try container.decodeIfPresent([LeadActivity].self, forKey: .activities) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
    }
}
