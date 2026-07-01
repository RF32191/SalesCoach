import Foundation
import SwiftUI

enum DealEventType: String, Codable, CaseIterable, Identifiable {
    case stageChange = "Stage Change"
    case call = "Call"
    case email = "Email"
    case visit = "Visit"
    case note = "Note"
    case followUpScheduled = "Follow-Up"
    case aiBriefing = "AI Briefing"
    case checkIn = "Check-In"
    case practice = "Roleplay Practice"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .stageChange: "arrow.triangle.2.circlepath"
        case .call: "phone.fill"
        case .email: "envelope.fill"
        case .visit: "figure.walk"
        case .note: "note.text"
        case .followUpScheduled: "calendar"
        case .aiBriefing: "sparkles"
        case .checkIn: "camera.fill"
        case .practice: "mic.fill"
        }
    }
}

struct DealEvent: Codable, Identifiable, Equatable {
    var id: String
    var type: DealEventType
    var summary: String
    var date: Date

    init(id: String = UUID().uuidString, type: DealEventType, summary: String, date: Date = .now) {
        self.id = id
        self.type = type
        self.summary = summary
        self.date = date
    }
}

enum CertificationLevel: String, Codable, CaseIterable, Identifiable {
    case coldCallBasics = "Cold Call Basics"
    case discoveryMaster = "Discovery Master"
    case objectionPro = "Objection Pro"
    case closingExpert = "Closing Expert"
    case fieldElite = "Field Sales Elite"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .coldCallBasics: "phone.arrow.up.right.fill"
        case .discoveryMaster: "questionmark.circle.fill"
        case .objectionPro: "exclamationmark.bubble.fill"
        case .closingExpert: "checkmark.seal.fill"
        case .fieldElite: "map.fill"
        }
    }

    var requiredScore: Int {
        switch self {
        case .coldCallBasics: 70
        case .discoveryMaster: 75
        case .objectionPro: 78
        case .closingExpert: 80
        case .fieldElite: 82
        }
    }

    var scenario: TrainingScenario {
        switch self {
        case .coldCallBasics: .coldCall
        case .discoveryMaster: .followUp
        case .objectionPro: .objectionHandling
        case .closingExpert: .closing
        case .fieldElite: .doorToDoor
        }
    }
}

struct ManagerDrill: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var scenario: TrainingScenario
    var personality: CustomerPersonality
    var dueDate: Date
    var isCompleted: Bool
    var assignedBy: String

    init(
        id: String = UUID().uuidString,
        title: String,
        scenario: TrainingScenario,
        personality: CustomerPersonality,
        dueDate: Date,
        isCompleted: Bool = false,
        assignedBy: String = "Sales Manager"
    ) {
        self.id = id
        self.title = title
        self.scenario = scenario
        self.personality = personality
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.assignedBy = assignedBy
    }
}

struct ActivityGoals: Codable, Equatable {
    var weeklyCalls: Int
    var weeklyVisits: Int
    var weeklyNewLeads: Int
    var callsCompleted: Int
    var visitsCompleted: Int
    var newLeadsCompleted: Int
    var weekStart: Date

    static let `default` = ActivityGoals(
        weeklyCalls: 20,
        weeklyVisits: 8,
        weeklyNewLeads: 5,
        callsCompleted: 0,
        visitsCompleted: 0,
        newLeadsCompleted: 0,
        weekStart: Calendar.current.startOfDay(for: .now)
    )
}

struct PlaybookEntry: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var content: String
    var category: String
    var author: String

    init(id: String = UUID().uuidString, title: String, content: String, category: String, author: String = "Team") {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.author = author
    }
}

struct PreCallBriefing: Equatable {
    let openingLine: String
    let keyPoints: [String]
    let questionsToAsk: [String]
    let closeLine: String
    let personalHooks: [String]
}

struct PostVisitDebrief: Equatable {
    let whatWentWell: [String]
    let improvements: [String]
    let nextStep: String
    let practicePrompt: String
}

struct SkillGapSnapshot: Equatable {
    let overallTrainingScore: Int
    let winRate: Double
    let categoryScores: [ScoreCategory]
    let recommendations: [String]
    let weakestSkill: String
    let strongestSkill: String
}

struct RevenueForecast: Equatable {
    let expectedThisMonth: Double
    let bestCase: Double
    let pipelineCoverage: Double
    let dealsClosingSoon: Int
}

struct RouteStop: Identifiable, Equatable {
    let id: String
    let lead: Lead
    let order: Int
    let distanceMeters: Double?

    var distanceLabel: String? {
        guard let distanceMeters else { return nil }
        if distanceMeters < 1000 { return String(format: "%.0f m", distanceMeters) }
        return String(format: "%.1f mi", distanceMeters / 1609.34)
    }
}

struct CallAnalysisResult: Equatable {
    let talkRatioPercent: Int
    let questionsAsked: Int
    let fillerWordCount: Int
    let overallScore: Int
    let strengths: [String]
    let improvements: [String]
}

struct ArrivalChecklist: Equatable {
    let items: [String]
    let talkTrack: String
    let closeAsk: String
}

enum IntegrationProvider: String, CaseIterable, Identifiable {
    case hubspot = "HubSpot"
    case salesforce = "Salesforce"
    case googleCalendar = "Google Calendar"
    case appleCalendar = "Apple Calendar"
    case zapier = "Zapier"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .hubspot: "h.square.fill"
        case .salesforce: "cloud.fill"
        case .googleCalendar: "calendar"
        case .appleCalendar: "calendar.badge.clock"
        case .zapier: "bolt.fill"
        }
    }
}

extension ArrivalChecklist {
    func asBriefing() -> PreCallBriefing {
        PreCallBriefing(
            openingLine: talkTrack,
            keyPoints: items,
            questionsToAsk: ["What's your top priority this quarter?"],
            closeLine: closeAsk,
            personalHooks: []
        )
    }
}

enum Haptic {
    static func success() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    static func warning() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    static func selection() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}
