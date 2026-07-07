import Foundation

struct TeamFeedUpdate: Codable, Identifiable, Equatable {
    var id: String
    var teamId: String
    var repUserId: String
    var repName: String
    var message: String
    var loggedAt: Date

    init(
        id: String = UUID().uuidString,
        teamId: String,
        repUserId: String,
        repName: String,
        message: String,
        loggedAt: Date = .now
    ) {
        self.id = id
        self.teamId = teamId
        self.repUserId = repUserId
        self.repName = repName
        self.message = message
        self.loggedAt = loggedAt
    }
}

enum TeamFeedItem: Identifiable, Equatable {
    case sale(TeamSale)
    case update(TeamFeedUpdate)

    var id: String {
        switch self {
        case .sale(let sale): sale.id
        case .update(let update): update.id
        }
    }

    var loggedAt: Date {
        switch self {
        case .sale(let sale): sale.loggedAt
        case .update(let update): update.loggedAt
        }
    }
}
