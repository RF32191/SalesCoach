import Foundation

struct TeamMember: Codable, Identifiable, Equatable {
    var id: String
    var teamId: String
    var userId: String
    var fullName: String
    var email: String
    var role: TeamRole
    var averageScore: Int
    var roleplaysCompleted: Int
    var closingScore: Int
    var improvementDelta: Int
    var assignedScenarios: [TrainingScenario]
    var joinedAt: Date

    init(
        id: String = UUID().uuidString,
        teamId: String,
        userId: String,
        fullName: String,
        email: String,
        role: TeamRole = .rep,
        averageScore: Int = 0,
        roleplaysCompleted: Int = 0,
        closingScore: Int = 0,
        improvementDelta: Int = 0,
        assignedScenarios: [TrainingScenario] = [],
        joinedAt: Date = .now
    ) {
        self.id = id
        self.teamId = teamId
        self.userId = userId
        self.fullName = fullName
        self.email = email
        self.role = role
        self.averageScore = averageScore
        self.roleplaysCompleted = roleplaysCompleted
        self.closingScore = closingScore
        self.improvementDelta = improvementDelta
        self.assignedScenarios = assignedScenarios
        self.joinedAt = joinedAt
    }
}

enum TeamRole: String, Codable, CaseIterable {
    case manager = "Manager"
    case rep = "Sales Rep"
}

struct LeaderboardEntry: Identifiable, Equatable {
    var id: String { userId }
    var userId: String
    var name: String
    var value: Int
    var subtitle: String
    var rank: Int
}

enum FollowUpType: String, CaseIterable, Identifiable {
    case coldEmail = "Cold Email"
    case followUpEmail = "Follow-Up Email"
    case text = "Follow-Up Text"
    case meetingConfirm = "Meeting Confirm"
    case proposalEmail = "Proposal Email"
    case thankYou = "Thank You"
    case renewal = "Renewal Email"
    case callScript = "Call Script"
    case closingMessage = "Closing Message"
    case objectionResponse = "Objection Response"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .coldEmail: "envelope.badge.fill"
        case .followUpEmail, .proposalEmail, .renewal, .thankYou, .meetingConfirm: "envelope.fill"
        case .text: "message.fill"
        case .callScript: "phone.fill"
        case .closingMessage: "checkmark.seal.fill"
        case .objectionResponse: "bubble.left.and.exclamationmark.bubble.right.fill"
        }
    }
}
