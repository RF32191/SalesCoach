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
        let all = loadAllSessions()
        sessions = all.filter { $0.userId == userId }.sorted {
            let left = $0.completedAt ?? $0.startedAt ?? .distantPast
            let right = $1.completedAt ?? $1.startedAt ?? .distantPast
            return left > right
        }
    }

    func startSession(userId: String, scenario: TrainingScenario, personality: CustomerPersonality) -> TrainingSession {
        if let existing = activeSession, existing.isInProgress {
            upsertSession(existing)
        }
        let session = TrainingSession(userId: userId, scenario: scenario, personality: personality)
        activeSession = session
        upsertSession(session)
        return session
    }

    func resumeSession(_ session: TrainingSession) {
        activeSession = session
    }

    func session(withId id: String) -> TrainingSession? {
        sessions.first { $0.id == id }
    }

    func inProgressSessions(for userId: String) -> [TrainingSession] {
        sessions.filter { $0.userId == userId && $0.isInProgress && !$0.transcript.isEmpty }
    }

    func completedSessions(for userId: String) -> [TrainingSession] {
        sessions.filter { $0.userId == userId && $0.completedAt != nil }
    }

    func addUserMessage(_ text: String) {
        guard var session = activeSession, !text.isEmpty else { return }
        session.transcript.append(RoleplayTranscriptEntry(speaker: "You", text: text))
        activeSession = session
        persistActiveSession()
    }

    func addAIMessage(_ text: String) {
        guard var session = activeSession else { return }
        session.transcript.append(RoleplayTranscriptEntry(speaker: "Customer", text: text))
        activeSession = session
        persistActiveSession()
    }

    func applyTurnResult(_ result: RoleplayTurnResult) {
        guard var session = activeSession else { return }
        session.closingProgress = min(100, max(0, session.closingProgress + result.closingProgressDelta))
        session.currentSuggestion = result.suggestion
        activeSession = session
        persistActiveSession()
    }

    func setInitialSuggestion(_ suggestion: String) {
        guard var session = activeSession else { return }
        session.currentSuggestion = suggestion
        activeSession = session
        persistActiveSession()
    }

    func pauseActiveSession(durationSeconds: Int) {
        guard var session = activeSession else { return }
        session.durationSeconds = durationSeconds
        activeSession = session
        upsertSession(session)
    }

    func persistActiveSession() {
        guard let session = activeSession else { return }
        upsertSession(session)
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

        if AppConfig.isAIConfigured {
            do {
                let report = try await OpenAIService.shared.scoreSession(
                    scenario: session.scenario,
                    personality: session.personality,
                    transcript: session.transcript
                )
                var scoredReport = report
                scoredReport.sessionId = session.id
                session.scoreReport = scoredReport
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        lastCompletedSession = session
        activeSession = nil
        upsertSession(session)
        return session.scoreReport
    }

    func deleteSession(_ session: TrainingSession) {
        sessions.removeAll { $0.id == session.id }
        if activeSession?.id == session.id {
            activeSession = nil
        }
        saveAllSessions()
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

    private func upsertSession(_ session: TrainingSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.insert(session, at: 0)
        }
        saveAllSessions()
    }

    private func loadAllSessions() -> [TrainingSession] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([TrainingSession].self, from: data) else {
            return []
        }
        return stored
    }

    private func saveAllSessions() {
        var all = loadAllSessions()
        let touchedUserIds = Set(sessions.map(\.userId))
        for userId in touchedUserIds {
            all.removeAll { $0.userId == userId }
        }
        all.append(contentsOf: sessions)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
