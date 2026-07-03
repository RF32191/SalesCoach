import SwiftUI

struct LeaderboardView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    private let tabs = ["Top Score", "Most Improved", "Most Roleplays", "Best Closer"]

    var body: some View {
        VStack(spacing: 0) {
            Picker("Category", selection: $selectedTab) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Text(tabs[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                LazyVStack(spacing: 12) {
                    if currentEntries.isEmpty {
                        EmptyStateView(
                            icon: "trophy",
                            title: "No scores yet",
                            message: "Complete training roleplays to appear on the leaderboard."
                        )
                    } else {
                        ForEach(currentEntries) { entry in
                            LeaderboardRow(entry: entry)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .appBackground()
        .navigationTitle("Leaderboard")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    private var currentEntries: [LeaderboardEntry] {
        let isTeam = appState.auth.currentUser?.accountType == .team

        if isTeam && !appState.team.members.isEmpty {
            switch selectedTab {
            case 0: return appState.team.leaderboardHighestScore()
            case 1: return appState.team.leaderboardMostImproved()
            case 2: return appState.team.leaderboardMostRoleplays()
            default: return appState.team.leaderboardBestCloser()
            }
        }

        return personalEntries
    }

    private var personalEntries: [LeaderboardEntry] {
        guard let user = appState.auth.currentUser else { return [] }
        let avgScore = appState.training.averageScore(for: user.id)
        let roleplays = appState.training.completedCount(for: user.id)
        let closing = appState.training.bestClosingScore(for: user.id)

        switch selectedTab {
        case 0:
            return [LeaderboardEntry(userId: user.id, name: user.fullName, value: avgScore, subtitle: "Avg Score", rank: 1)]
        case 1:
            let improved = appState.training.sessions
                .filter { $0.userId == user.id }
                .compactMap(\.scoreReport?.overallScore)
            let delta = improved.count >= 2 ? (improved.first ?? 0) - (improved.last ?? 0) : 0
            return improved.isEmpty ? [] : [
                LeaderboardEntry(userId: user.id, name: user.fullName, value: max(0, delta), subtitle: "Points Improved", rank: 1)
            ]
        case 2:
            return [LeaderboardEntry(userId: user.id, name: user.fullName, value: roleplays, subtitle: "Roleplays", rank: 1)]
        default:
            return [LeaderboardEntry(userId: user.id, name: user.fullName, value: closing, subtitle: "Closing Score", rank: 1)]
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color.yellow
        case 2: return Color.gray
        case 3: return Color.orange
        default: return AppTheme.textMuted
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Text("#\(entry.rank)")
                .font(.headline.bold())
                .foregroundStyle(rankColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(entry.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Text("\(entry.value)")
                .font(.title3.bold())
                .foregroundStyle(entry.rank == 1 ? AppTheme.successGreen : AppTheme.electricBlue)
        }
        .cardStyle()
    }
}
