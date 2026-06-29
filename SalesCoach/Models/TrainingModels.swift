import Foundation

enum CustomerPersonality: String, Codable, CaseIterable, Identifiable {
    case angry = "Angry Customer"
    case budgetConscious = "Budget-Conscious"
    case interested = "Interested Customer"
    case skeptical = "Skeptical Customer"
    case busyExecutive = "Busy Executive"
    case competitorLoyal = "Competitor-Loyal"
    case firstTimeBuyer = "First-Time Buyer"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .angry: "flame.fill"
        case .budgetConscious: "dollarsign.circle.fill"
        case .interested: "star.fill"
        case .skeptical: "questionmark.circle.fill"
        case .busyExecutive: "clock.fill"
        case .competitorLoyal: "shield.fill"
        case .firstTimeBuyer: "sparkles"
        }
    }

    var description: String {
        switch self {
        case .angry: "Frustrated with past experiences, needs empathy fast."
        case .budgetConscious: "Price-sensitive, needs clear ROI."
        case .interested: "Warm lead, ready to learn more."
        case .skeptical: "Doubts claims, needs proof and data."
        case .busyExecutive: "Short on time, wants bottom-line value."
        case .competitorLoyal: "Happy with current vendor, hard to switch."
        case .firstTimeBuyer: "Unsure what they need, needs guidance."
        }
    }
}

enum TrainingScenario: String, Codable, CaseIterable, Identifiable {
    case coldCall = "Cold Call"
    case doorToDoor = "Door-to-Door"
    case followUp = "Follow-Up Call"
    case closing = "Closing Call"
    case objectionHandling = "Objection Handling"
    case upsell = "Upsell Practice"
    case renewal = "Renewal Call"
    case lostCustomer = "Lost Customer Recovery"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .coldCall: "phone.fill"
        case .doorToDoor: "door.left.hand.open"
        case .followUp: "arrow.triangle.2.circlepath"
        case .closing: "checkmark.seal.fill"
        case .objectionHandling: "exclamationmark.bubble.fill"
        case .upsell: "arrow.up.circle.fill"
        case .renewal: "repeat.circle.fill"
        case .lostCustomer: "heart.slash.fill"
        }
    }

    var description: String {
        switch self {
        case .coldCall: "Practice opening cold and earning 30 seconds."
        case .doorToDoor: "Handle in-person objections at the door."
        case .followUp: "Re-engage a warm lead who went quiet."
        case .closing: "Ask for the deal and handle final hesitations."
        case .objectionHandling: "Turn pushback into progress."
        case .upsell: "Expand an existing customer's package."
        case .renewal: "Secure renewal before contract expiry."
        case .lostCustomer: "Win back a churned account."
        }
    }
}

struct RoleplayTranscriptEntry: Codable, Identifiable, Equatable {
    var id: String
    var speaker: String
    var text: String
    var timestamp: Date

    init(id: String = UUID().uuidString, speaker: String, text: String, timestamp: Date = .now) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.timestamp = timestamp
    }
}

struct ScoreCategory: Codable, Identifiable, Equatable {
    var id: String { name }
    var name: String
    var score: Int
    var maxScore: Int = 100
}

struct TrainingScoreReport: Codable, Identifiable, Equatable {
    var id: String
    var sessionId: String
    var overallScore: Int
    var categories: [ScoreCategory]
    var strengths: [String]
    var improvements: [String]
    var betterResponses: [String]
    var scriptSuggestions: [String]
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        sessionId: String,
        overallScore: Int,
        categories: [ScoreCategory],
        strengths: [String],
        improvements: [String],
        betterResponses: [String],
        scriptSuggestions: [String],
        createdAt: Date = .now
    ) {
        self.id = id
        self.sessionId = sessionId
        self.overallScore = overallScore
        self.categories = categories
        self.strengths = strengths
        self.improvements = improvements
        self.betterResponses = betterResponses
        self.scriptSuggestions = scriptSuggestions
        self.createdAt = createdAt
    }
}

struct TrainingSession: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var scenario: TrainingScenario
    var personality: CustomerPersonality
    var transcript: [RoleplayTranscriptEntry]
    var scoreReport: TrainingScoreReport?
    var closingProgress: Int
    var currentSuggestion: String?
    var durationSeconds: Int
    var completedAt: Date?

    init(
        id: String = UUID().uuidString,
        userId: String,
        scenario: TrainingScenario,
        personality: CustomerPersonality,
        transcript: [RoleplayTranscriptEntry] = [],
        scoreReport: TrainingScoreReport? = nil,
        closingProgress: Int = 0,
        currentSuggestion: String? = nil,
        durationSeconds: Int = 0,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.scenario = scenario
        self.personality = personality
        self.transcript = transcript
        self.scoreReport = scoreReport
        self.closingProgress = closingProgress
        self.currentSuggestion = currentSuggestion
        self.durationSeconds = durationSeconds
        self.completedAt = completedAt
    }
}
