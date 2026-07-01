import SwiftUI

struct SubscriptionView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                crownHeader
                usageCard

                ForEach(SubscriptionTier.allCases) { tier in
                    PlanCard(
                        tier: tier,
                        isCurrentPlan: appState.subscription.usage.tier == tier
                    ) {
                        appState.subscription.upgrade(to: tier)
                    }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Plans")
        .navigationBarTitleDisplayMode(.large)
    }

    private var crownHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                appState.subscription.usage.tier.crownGlowColor.opacity(0.35),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)

                TierCrownIcon(tier: appState.subscription.usage.tier, size: 44)
            }

            Text("Choose Your Crown")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))

            Text("Unlock more AI coaching, roleplays, and team tools.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TierCrownIcon(tier: appState.subscription.usage.tier, size: 20)
                Text("Current: \(appState.subscription.usage.tier.rawValue)")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            }

            if let remaining = appState.subscription.usage.roleplaysRemaining {
                HStack {
                    Text("Roleplays remaining")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    Spacer()
                    Text("\(remaining)")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.electricBlueBright)
                }
            } else {
                Text("Unlimited roleplays")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.tealGreen)
            }

            if !appState.subscription.usage.tier.hasUnlimitedChat {
                HStack {
                    Text("Chat messages used")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    Spacer()
                    Text("\(appState.subscription.usage.chatMessagesUsedThisMonth)/20")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.electricBlueBright)
                }
            }

            if let tokenLimit = appState.subscription.usage.tier.monthlyTokenLimit {
                HStack {
                    Text("AI tokens used")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    Spacer()
                    Text("\(appState.subscription.usage.aiTokensUsedThisMonth.formatted()) / \(tokenLimit.formatted())")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.electricBlueBright)
                }
            } else {
                Text("Unlimited AI tokens")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.tealGreen)
            }
        }
        .cardStyle()
    }
}

struct PlanCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let tier: SubscriptionTier
    let isCurrentPlan: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                TierCrownIcon(tier: tier, size: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.rawValue)
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    Text(tier.tagline)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    Text("\(tier.monthlyPrice)/mo")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.electricBlueBright)
                }

                Spacer()

                if isCurrentPlan {
                    Label("Active", systemImage: "checkmark.seal.fill")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.tealGreen)
                }
            }

            ForEach(tier.features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.tealGreen)
                    Text(feature)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
            }

            if !isCurrentPlan {
                PrimaryButton(title: tier == .enterprise ? "Contact Sales" : "Upgrade") {
                    onSelect()
                }
            }
        }
        .cardStyle()
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isCurrentPlan ? tier.crownGradient : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                    lineWidth: isCurrentPlan ? 2 : 0
                )
        }
    }
}
