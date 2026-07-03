import Foundation

struct TeamSale: Codable, Identifiable, Equatable {
    var id: String
    var teamId: String
    var repUserId: String
    var repName: String
    var clientName: String
    var company: String
    var amount: Double
    var notes: String
    var loggedAt: Date
    var source: AuditSource

    init(
        id: String = UUID().uuidString,
        teamId: String,
        repUserId: String,
        repName: String,
        clientName: String,
        company: String = "",
        amount: Double,
        notes: String = "",
        loggedAt: Date = .now,
        source: AuditSource = .chat
    ) {
        self.id = id
        self.teamId = teamId
        self.repUserId = repUserId
        self.repName = repName
        self.clientName = clientName
        self.company = company
        self.amount = amount
        self.notes = notes
        self.loggedAt = loggedAt
        self.source = source
    }
}
