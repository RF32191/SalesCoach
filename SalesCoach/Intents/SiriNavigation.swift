import Foundation

enum SiriDestination: Equatable {
    case practiceScenario(TrainingScenario, CustomerPersonality)
    case aiTraining(AITrainingTab)
    case teamSalesLog(prefill: String?, autoSend: Bool)
    case voiceLog(prefill: String?, autoSave: Bool)
}

enum AITrainingTab: String, Equatable {
    case roleplay
    case chat
}

struct SiriNavigationRequest: Identifiable, Equatable {
    let id: UUID
    let destination: SiriDestination

    init(destination: SiriDestination, id: UUID = UUID()) {
        self.id = id
        self.destination = destination
    }
}

@MainActor
final class SiriNavigationCenter {
    static let shared = SiriNavigationCenter()

    var onNavigate: ((SiriNavigationRequest) -> Void)?
    private(set) var pendingRequest: SiriNavigationRequest?

    private init() {}

    func open(_ destination: SiriDestination) {
        let request = SiriNavigationRequest(destination: destination)
        pendingRequest = request
        onNavigate?(request)
    }

    func consumePending() -> SiriNavigationRequest? {
        defer { pendingRequest = nil }
        return pendingRequest
    }
}
