import Foundation

@MainActor
@Observable
final class TeamService {
    var members: [TeamMember] = []
    private let storageKey = "salescoach_team"

    func loadTeam(teamId: String) {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([TeamMember].self, from: data) else {
            members = Self.sampleMembers(teamId: teamId)
            saveTeam()
            return
        }
        members = stored.filter { $0.teamId == teamId }
        if members.isEmpty {
            members = Self.sampleMembers(teamId: teamId)
            saveTeam()
        }
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

    func mostCommonWeaknesses() -> [String] {
        ["Objection Handling", "Discovery Questions", "Closing Ability", "Active Listening"]
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

    static func sampleMembers(teamId: String) -> [TeamMember] {
        [
            TeamMember(teamId: teamId, userId: "rep1", fullName: "Alex Rivera", email: "alex@company.com",
                       averageScore: 82, roleplaysCompleted: 24, closingScore: 78, improvementDelta: 15,
                       assignedScenarios: [.coldCall, .objectionHandling]),
            TeamMember(teamId: teamId, userId: "rep2", fullName: "Jordan Kim", email: "jordan@company.com",
                       averageScore: 91, roleplaysCompleted: 31, closingScore: 88, improvementDelta: 8,
                       assignedScenarios: [.closing]),
            TeamMember(teamId: teamId, userId: "rep3", fullName: "Taylor Brooks", email: "taylor@company.com",
                       averageScore: 74, roleplaysCompleted: 18, closingScore: 65, improvementDelta: 22,
                       assignedScenarios: [.followUp, .renewal]),
            TeamMember(teamId: teamId, userId: "rep4", fullName: "Casey Morgan", email: "casey@company.com",
                       averageScore: 86, roleplaysCompleted: 27, closingScore: 84, improvementDelta: 11,
                       assignedScenarios: [.upsell])
        ]
    }
}
