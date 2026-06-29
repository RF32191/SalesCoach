import Foundation

@MainActor
@Observable
final class TrainingService {
    var sessions: [TrainingSession] = []
    var activeSession: TrainingSession?
    var lastCompletedSession: TrainingSession?
    var isProcessing = false
    var errorMessage: String?

    private let storageKey = "salescoach_sessions"

    func loadSessions(for userId: String) {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([TrainingSession].self, from: data) else {
            sessions = []
            return
        }
        sessions = stored.filter { $0.userId == userId }.sorted {
            ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
        }
    }

    func startSession(userId: String, scenario: TrainingScenario, personality: CustomerPersonality) -> TrainingSession {
        let session = TrainingSession(userId: userId, scenario: scenario, personality: personality)
        activeSession = session
        return session
    }

    func addUserMessage(_ text: String) {
        guard var session = activeSession, !text.isEmpty else { return }
        session.transcript.append(RoleplayTranscriptEntry(speaker: "You", text: text))
        activeSession = session
    }

    func addAIMessage(_ text: String) {
        guard var session = activeSession else { return }
        session.transcript.append(RoleplayTranscriptEntry(speaker: "Customer", text: text))
        activeSession = session
    }

    func applyTurnResult(_ result: RoleplayTurnResult) {
        guard var session = activeSession else { return }
        session.closingProgress = min(100, max(0, session.closingProgress + result.closingProgressDelta))
        session.currentSuggestion = result.suggestion
        activeSession = session
    }

    func setInitialSuggestion(_ suggestion: String) {
        guard var session = activeSession else { return }
        session.currentSuggestion = suggestion
        activeSession = session
    }

    func getAIResponse() async -> String? {
        guard let session = activeSession else { return nil }
        isProcessing = true
        defer { isProcessing = false }

        do {
            let result = try await OpenAIService.shared.roleplayTurn(
                scenario: session.scenario,
                personality: session.personality,
                transcript: session.transcript,
                closingProgress: session.closingProgress
            )
            applyTurnResult(result)
            return result.customerReply
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func completeSession(durationSeconds: Int) async -> TrainingScoreReport? {
        guard var session = activeSession else { return nil }
        isProcessing = true
        defer { isProcessing = false }

        session.durationSeconds = durationSeconds
        session.completedAt = .now

        do {
            let report = try await OpenAIService.shared.scoreSession(
                scenario: session.scenario,
                personality: session.personality,
                transcript: session.transcript
            )
            var scoredReport = report
            scoredReport.sessionId = session.id
            session.scoreReport = scoredReport
            lastCompletedSession = session
            activeSession = nil
            sessions.insert(session, at: 0)
            saveSessions()
            return scoredReport
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func averageScore(for userId: String) -> Int {
        let userSessions = sessions.filter { $0.userId == userId && $0.scoreReport != nil }
        guard !userSessions.isEmpty else { return 0 }
        let total = userSessions.compactMap { $0.scoreReport?.overallScore }.reduce(0, +)
        return total / userSessions.count
    }

    func completedCount(for userId: String) -> Int {
        sessions.filter { $0.userId == userId && $0.completedAt != nil }.count
    }

    func bestClosingScore(for userId: String) -> Int {
        sessions
            .filter { $0.userId == userId }
            .compactMap { $0.scoreReport?.categories.first { $0.name == "Closing Ability" }?.score }
            .max() ?? 0
    }

    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
