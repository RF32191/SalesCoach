import SwiftUI

struct TierCrownIcon: View {
    let tier: SubscriptionTier
    var size: CGFloat = 28
    var filled: Bool = true

    private var iconName: String {
        filled ? tier.crownIconFilled : tier.crownIconOutline
    }

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(tier.crownGradient)
            .shadow(color: tier.crownGlowColor.opacity(0.45), radius: 6, y: 2)
    }
}

struct CrownButton: View {
    let tier: SubscriptionTier
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            Circle()
                .fill(tier.crownGlowColor.opacity(0.18))
                .frame(width: 40, height: 40)
            TierCrownIcon(tier: tier, size: size)
        }
    }
}

extension SubscriptionTier {
    var crownIconFilled: String {
        switch self {
        case .free: "crown"
        case .pro: "crown.fill"
        case .team: "crown.fill"
        case .enterprise: "crown.circle.fill"
        }
    }

    var crownIconOutline: String {
        switch self {
        case .free: "crown"
        case .pro, .team: "crown"
        case .enterprise: "crown.circle"
        }
    }

    var crownGradient: LinearGradient {
        switch self {
        case .free:
            LinearGradient(
                colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pro:
            LinearGradient(
                colors: [AppTheme.electricBlueBright, AppTheme.electricBlueDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .team:
            LinearGradient(
                colors: [AppTheme.tealGreen, AppTheme.electricBlueBright],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .enterprise:
            LinearGradient(
                colors: [Color.yellow, AppTheme.warningOrange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var crownGlowColor: Color {
        switch self {
        case .free: .gray
        case .pro: AppTheme.electricBlueBright
        case .team: AppTheme.tealGreen
        case .enterprise: .yellow
        }
    }

    var tagline: String {
        switch self {
        case .free: "Get started free"
        case .pro: "For serious reps"
        case .team: "For sales teams"
        case .enterprise: "For organizations"
        }
    }
}
