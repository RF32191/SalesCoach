import AppIntents
import Foundation

// MARK: - App Enum bridges

enum ScenarioAppEnum: String, AppEnum {
    case coldCall = "Cold Call"
    case doorToDoor = "Door-to-Door"
    case followUp = "Follow-Up Call"
    case closing = "Closing Call"
    case objectionHandling = "Objection Handling"
    case upsell = "Upsell Practice"
    case renewal = "Renewal Call"
    case lostCustomer = "Lost Customer Recovery"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Practice Scenario")
    }

    static var caseDisplayRepresentations: [ScenarioAppEnum: DisplayRepresentation] {
        [
            .coldCall: DisplayRepresentation(title: "Cold Call"),
            .doorToDoor: DisplayRepresentation(title: "Door-to-Door"),
            .followUp: DisplayRepresentation(title: "Follow-Up Call"),
            .closing: DisplayRepresentation(title: "Closing Call"),
            .objectionHandling: DisplayRepresentation(title: "Objection Handling"),
            .upsell: DisplayRepresentation(title: "Upsell Practice"),
            .renewal: DisplayRepresentation(title: "Renewal Call"),
            .lostCustomer: DisplayRepresentation(title: "Lost Customer Recovery")
        ]
    }

    var trainingScenario: TrainingScenario {
        switch self {
        case .coldCall: .coldCall
        case .doorToDoor: .doorToDoor
        case .followUp: .followUp
        case .closing: .closing
        case .objectionHandling: .objectionHandling
        case .upsell: .upsell
        case .renewal: .renewal
        case .lostCustomer: .lostCustomer
        }
    }
}

enum PersonalityAppEnum: String, AppEnum {
    case angry = "Angry Customer"
    case budgetConscious = "Budget-Conscious"
    case interested = "Interested Customer"
    case skeptical = "Skeptical Customer"
    case busyExecutive = "Busy Executive"
    case competitorLoyal = "Competitor-Loyal"
    case firstTimeBuyer = "First-Time Buyer"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Customer Personality")
    }

    static var caseDisplayRepresentations: [PersonalityAppEnum: DisplayRepresentation] {
        [
            .angry: DisplayRepresentation(title: "Angry Customer"),
            .budgetConscious: DisplayRepresentation(title: "Budget-Conscious"),
            .interested: DisplayRepresentation(title: "Interested Customer"),
            .skeptical: DisplayRepresentation(title: "Skeptical Customer"),
            .busyExecutive: DisplayRepresentation(title: "Busy Executive"),
            .competitorLoyal: DisplayRepresentation(title: "Competitor-Loyal"),
            .firstTimeBuyer: DisplayRepresentation(title: "First-Time Buyer")
        ]
    }

    var customerPersonality: CustomerPersonality {
        switch self {
        case .angry: .angry
        case .budgetConscious: .budgetConscious
        case .interested: .interested
        case .skeptical: .skeptical
        case .busyExecutive: .busyExecutive
        case .competitorLoyal: .competitorLoyal
        case .firstTimeBuyer: .firstTimeBuyer
        }
    }
}

enum TrainingTabAppEnum: String, AppEnum {
    case roleplay = "Roleplay"
    case chat = "Team Sales Log"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Training Tab")
    }

    static var caseDisplayRepresentations: [TrainingTabAppEnum: DisplayRepresentation] {
        [
            .roleplay: DisplayRepresentation(title: "Roleplay"),
            .chat: DisplayRepresentation(title: "Team Sales Log")
        ]
    }

    var aiTab: AITrainingTab {
        switch self {
        case .roleplay: .roleplay
        case .chat: .chat
        }
    }
}

// MARK: - Intents

struct StartPracticeScenarioIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Practice Scenario"
    static var description = IntentDescription("Start a voice AI roleplay practice session.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Scenario")
    var scenario: ScenarioAppEnum

    @Parameter(title: "Customer Type", default: .interested)
    var personality: PersonalityAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Practice \(\.$scenario) with a \(\.$personality)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await SiriNavigationCenter.shared.open(
            .practiceScenario(scenario.trainingScenario, personality.customerPersonality)
        )
        return .result(dialog: "Starting \(scenario.rawValue) practice.")
    }
}

struct OpenAITrainingIntent: AppIntent {
    static var title: LocalizedStringResource = "Open AI Training"
    static var description = IntentDescription("Open AI Training in Sales Coach.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Tab", default: .roleplay)
    var tab: TrainingTabAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$tab) in Sales Coach")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await SiriNavigationCenter.shared.open(.aiTraining(tab.aiTab))
        return .result(dialog: "Opening \(tab.rawValue).")
    }
}

struct OpenTeamSalesLogIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Team Sales Log"
    static var description = IntentDescription("Open the team sales log to share a win with your company team.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await SiriNavigationCenter.shared.open(.teamSalesLog(prefill: nil, autoSend: false))
        return .result(dialog: "Opening team sales log.")
    }
}

struct LogTeamSaleIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Team Sale"
    static var description = IntentDescription("Log a closed sale to your company team feed.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Client or Company")
    var client: String

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) sale with \(\.$client)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let formatted = amount >= 1000 ? String(format: "$%.0fK", amount / 1000) : String(format: "$%.0f", amount)
        let message = "Closed \(formatted) with \(client)"
        await SiriNavigationCenter.shared.open(.teamSalesLog(prefill: message, autoSend: true))
        return .result(dialog: "Logging sale with \(client).")
    }
}

struct StartObjectionPracticeIntent: AppIntent {
    static var title: LocalizedStringResource = "Practice Objection Handling"
    static var description = IntentDescription("Start an objection handling roleplay with a skeptical customer.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await SiriNavigationCenter.shared.open(
            .practiceScenario(.objectionHandling, .skeptical)
        )
        return .result(dialog: "Starting objection handling practice.")
    }
}

struct LogVoiceNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Log CRM Voice Note"
    static var description = IntentDescription("Log a call, email, or visit to a client using your voice.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Activity Note")
    var note: String

    static var parameterSummary: some ParameterSummary {
        Summary("Log CRM activity: \(\.$note)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await SiriNavigationCenter.shared.open(.voiceLog(prefill: note, autoSave: true))
        return .result(dialog: "Logging your CRM activity.")
    }
}
