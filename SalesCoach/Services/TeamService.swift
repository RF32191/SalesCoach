import Foundation

@MainActor
@Observable
final class TeamService {
    var members: [TeamMember] = []
    private let storageKey = "salescoach_team"

    func loadTeam(teamId: String) {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([TeamMember].self, from: data) else {
            members = []
            removeBundledExampleMembersIfNeeded(teamId: teamId)
            return
        }
        members = stored.filter { $0.teamId == teamId }
        removeBundledExampleMembersIfNeeded(teamId: teamId)
    }

    func loadExampleTeam(teamId: String) {
        for member in ExampleData.exampleTeamMembers(teamId: teamId) {
            guard !members.contains(where: { $0.email.lowercased() == member.email.lowercased() }) else { continue }
            members.append(member)
        }
        saveTeam()
    }

    func removeExampleTeamMembers(teamId: String) {
        members.removeAll { $0.teamId == teamId && ExampleData.isExampleTeamMember($0) }
        saveTeam()
    }

    func clearTeam(teamId: String) {
        members.removeAll { $0.teamId == teamId }
        saveTeam()
    }

    private func removeBundledExampleMembersIfNeeded(teamId: String) {
        let migrationKey = "salescoach_removed_sample_team_\(teamId)"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        members.removeAll { ExampleData.isExampleTeamMember($0) }
        UserDefaults.standard.set(true, forKey: migrationKey)
        saveTeam()
    }

    func addMember(teamId: String, fullName: String, email: String) {
        let member = TeamMember(teamId: teamId, userId: UUID().uuidString, fullName: fullName, email: email)
        members.append(member)
        saveTeam()
    }

    func assignScenario(to memberId: String, scenario: TrainingScenario) {
        guard let index = members.firstIndex(where: { $0.id == memberId }) else { return }
        if !members[index].assignedScenarios.contains(scenario) {
            members[index].assignedScenarios.append(scenario)
            saveTeam()
        }
    }

    func mostCommonWeaknesses(from sessions: [TrainingSession], memberIds: Set<String>) -> [String] {
        var counts: [String: Int] = [:]
        for session in sessions where memberIds.contains(session.userId) {
            session.scoreReport?.improvements.forEach { counts[$0, default: 0] += 1 }
        }
        return counts.sorted { $0.value > $1.value }.prefix(3).map(\.key)
    }

    func leaderboardHighestScore() -> [LeaderboardEntry] {
        members.sorted { $0.averageScore > $1.averageScore }.enumerated().map { index, member in
            LeaderboardEntry(userId: member.userId, name: member.fullName, value: member.averageScore,
                             subtitle: "Avg Score", rank: index + 1)
        }
    }

    func leaderboardMostImproved() -> [LeaderboardEntry] {
        members.sorted { $0.improvementDelta > $1.improvementDelta }.enumerated().map { index, member in
            LeaderboardEntry(userId: member.userId, name: member.fullName, value: member.improvementDelta,
                             subtitle: "Points Improved", rank: index + 1)
        }
    }

    func leaderboardMostRoleplays() -> [LeaderboardEntry] {
        members.sorted { $0.roleplaysCompleted > $1.roleplaysCompleted }.enumerated().map { index, member in
            LeaderboardEntry(userId: member.userId, name: member.fullName, value: member.roleplaysCompleted,
                             subtitle: "Roleplays", rank: index + 1)
        }
    }

    func leaderboardBestCloser() -> [LeaderboardEntry] {
        members.sorted { $0.closingScore > $1.closingScore }.enumerated().map { index, member in
            LeaderboardEntry(userId: member.userId, name: member.fullName, value: member.closingScore,
                             subtitle: "Closing Score", rank: index + 1)
        }
    }

    private func saveTeam() {
        if let data = try? JSONEncoder().encode(members) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
