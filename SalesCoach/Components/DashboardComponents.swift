import SwiftUI

struct TodayGlanceBar: View {
    @Environment(\.colorScheme) private var colorScheme
    let followUpsDue: Int
    let hotDeals: Int
    let pipelineValue: Double
    let winRate: Int
    let roleplayScore: Int
    var revenueThisMonth: Double = 0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                GlanceChip(label: "Due Today", value: "\(followUpsDue)", icon: "calendar", color: AppTheme.warningOrange)
                GlanceChip(label: "Hot Deals", value: "\(hotDeals)", icon: "flame.fill", color: AppTheme.dangerRed)
                GlanceChip(label: "Pipeline", value: formatShortCurrency(pipelineValue), icon: "chart.bar.fill", color: AppTheme.successGreen)
                if revenueThisMonth > 0 {
                    GlanceChip(label: "Won (Month)", value: formatShortCurrency(revenueThisMonth), icon: "cart.fill", color: AppTheme.tealGreen)
                }
                GlanceChip(label: "Win Rate", value: "\(winRate)%", icon: "trophy.fill", color: AppTheme.tealGreen)
                GlanceChip(label: "Avg Score", value: "\(roleplayScore)", icon: "star.fill", color: AppTheme.electricBlueBright)
            }
        }
    }
}

private struct GlanceChip: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        }
        .frame(minWidth: 88, alignment: .leading)
        .padding(12)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.25), lineWidth: 1)
        }
    }
}

struct AIRecommendationsCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let recommendations: [AIRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(AppTheme.electricBlueBright)
                Text("AI Recommendations")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            }

            ForEach(recommendations) { item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.tealGreen)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if item.id != recommendations.last?.id {
                    Divider().opacity(0.3)
                }
            }
        }
        .cardStyle()
    }
}

struct DailyMotivationCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.title3)
                .foregroundStyle(AppTheme.tealGreen)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.tealGreen.opacity(colorScheme == .dark ? 0.12 : 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.tealGreen.opacity(0.2), lineWidth: 1)
        }
    }
}

struct CompactModuleButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.22), lineWidth: 1)
        }
    }
}

private func formatShortCurrency(_ value: Double) -> String {
    if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
    if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
    return String(format: "$%.0f", value)
}
