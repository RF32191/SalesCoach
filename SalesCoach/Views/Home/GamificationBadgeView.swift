import SwiftUI

struct GamificationBadgeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.electricBlueBright.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: "flame.fill")
                    .foregroundStyle(AppTheme.warningOrange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Momentum")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                Text("Keep logging contacts and training to climb the leaderboard.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(appState.training.averageScore(for: userId))")
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.tealGreen)
                Text("Avg Score")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .cardStyle()
    }
}
