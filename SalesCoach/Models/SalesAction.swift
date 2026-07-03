import Foundation

enum SalesActionType: String, Codable {
    case logContact
    case createLead
    case updateStage
    case closeDeal
    case scheduleFollowUp
    case logSale
}

struct SalesAction: Codable, Equatable, Identifiable {
    var id: String
    let type: SalesActionType
    let leadMatch: String?
    let name: String?
    let company: String?
    let phone: String?
    let email: String?
    let dealValue: Double?
    let activityType: String?
    let summary: String?
    let stage: String?
    let won: Bool?
    let lostReason: String?
    let followUpDays: Int?

    init(
        id: String = UUID().uuidString,
        type: SalesActionType,
        leadMatch: String? = nil,
        name: String? = nil,
        company: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        dealValue: Double? = nil,
        activityType: String? = nil,
        summary: String? = nil,
        stage: String? = nil,
        won: Bool? = nil,
        lostReason: String? = nil,
        followUpDays: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.leadMatch = leadMatch
        self.name = name
        self.company = company
        self.phone = phone
        self.email = email
        self.dealValue = dealValue
        self.activityType = activityType
        self.summary = summary
        self.stage = stage
        self.won = won
        self.lostReason = lostReason
        self.followUpDays = followUpDays
    }
}

struct ChatCRMResponse: Equatable {
    let reply: String
    let actions: [SalesAction]
    let actionResults: [String]
}

struct ChatActionPayload: Codable {
    let reply: String
    let actions: [SalesAction]
}
