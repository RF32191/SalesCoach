import SwiftUI

struct TokenMeterView: View {
    @Environment(\.colorScheme) private var colorScheme
    let used: Int
    let limit: Int?
    var compact: Bool = false

    private var progress: Double {
        guard let limit, limit > 0 else { return 0 }
        return min(1, Double(used) / Double(limit))
    }

    private var remaining: Int? {
        guard let limit else { return nil }
        return max(0, limit - used)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            HStack {
                Label("AI Tokens", systemImage: "sparkles")
                    .font(compact ? .caption.bold() : .subheadline.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                Spacer()
                if let remaining {
                    Text("\(remaining.formatted()) left")
                        .font(compact ? .caption2 : .caption)
                        .foregroundStyle(remaining < 500 ? AppTheme.warningOrange : AppTheme.secondaryText(for: colorScheme))
                } else {
                    Text("Unlimited")
                        .font(compact ? .caption2 : .caption)
                        .foregroundStyle(AppTheme.successGreen)
                }
            }

            if let limit {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.border.opacity(0.4))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: progress > 0.85
                                        ? [AppTheme.warningOrange, AppTheme.dangerRed]
                                        : [AppTheme.electricBlueBright, AppTheme.tealGreen],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: compact ? 6 : 8)

                Text("\(used.formatted()) / \(limit.formatted()) used this month")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }
        }
        .padding(compact ? 10 : 14)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border.opacity(0.5), lineWidth: 1)
        )
    }
}

struct AIStatusBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppConfig.isAIConfigured ? AppTheme.successGreen : AppTheme.warningOrange)
                .frame(width: 8, height: 8)
            Text(AppConfig.isRailwayConfigured ? "Railway AI" : (AppConfig.isOpenAIConfigured ? "OpenAI" : "Demo Mode"))
                .font(.caption2.bold())
        }
        .foregroundStyle(AppTheme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppTheme.navyCard.opacity(0.8))
        .clipShape(Capsule())
    }
}
