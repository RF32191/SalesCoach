import SwiftUI

struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let icon: String
    var accentColor: Color = AppTheme.electricBlueBright

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                Spacer()
            }
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        }
        .cardStyle()
    }
}

struct FeatureCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String
    let icon: String
    var accentColor: Color = AppTheme.electricBlueBright

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.28), accentColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.35))
                .padding(8)
                .background(accentColor.opacity(0.15))
                .clipShape(Circle())
        }
        .cardStyle()
    }
}

struct SectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "See All"

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppTheme.brandGradient)
                .frame(width: 4, height: 18)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Spacer()
            if let action {
                Button(actionTitle, action: action)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.electricBlueBright)
            }
        }
    }
}

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.electricBlueBright.opacity(0.5))
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
