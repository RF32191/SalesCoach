import Foundation

@MainActor
@Observable
final class AutonomousBillingService {
    private(set) var latestReport: BillingAgentReport?
    private(set) var actionLog: [BillingAgentAction] = []
    private(set) var autonomousModeEnabled = true
    private(set) var lastRunAt: Date?

    private let logKey = "salescoach_billing_agent"
    private let modeKey = "salescoach_billing_autonomous"

    func load(for userId: String) {
        autonomousModeEnabled = UserDefaults.standard.object(forKey: "\(modeKey)_\(userId)") as? Bool ?? true
        if let data = UserDefaults.standard.data(forKey: "\(logKey)_\(userId)"),
           let stored = try? JSONDecoder().decode([BillingAgentAction].self, from: data) {
            actionLog = stored.sorted { $0.createdAt > $1.createdAt }
        }
    }

    func setAutonomousMode(_ enabled: Bool, for userId: String) {
        autonomousModeEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "\(modeKey)_\(userId)")
    }

    func runAutonomousReview(
        userId: String,
        usage: SubscriptionUsage,
        training: TrainingService,
        subscription: SubscriptionService,
        tokenBilling: TokenBillingService? = nil,
        office: OfficeService? = nil
    ) async {
        let profile = usage
        var actions: [BillingAgentAction] = []

        if let limit = profile.tier.monthlyTokenLimit,
           Double(profile.aiTokensUsedThisMonth) > Double(limit) * 0.85 {
            actions.append(BillingAgentAction(
                type: .costAlert,
                title: "AI usage at \(Int(Double(profile.aiTokensUsedThisMonth) / Double(limit) * 100))%",
                detail: "You're approaching your monthly token cap. Consider upgrading or batching coaching requests.",
                suggestedTier: profile.tier == .free ? .pro : .team
            ))
        }

        if profile.tier == .free && training.completedCount(for: userId) >= 2 {
            actions.append(BillingAgentAction(
                type: .recommendUpgrade,
                title: "Upgrade recommended for active reps",
                detail: "You've completed multiple roleplays on Free. Pro unlocks 30 roleplays/month and 100K tokens.",
                suggestedTier: .pro,
                estimatedSavings: nil
            ))
        }

        if profile.tier.roleplayLimit != nil,
           profile.roleplaysUsedThisMonth >= (profile.tier.roleplayLimit ?? 0) - 1 {
            actions.append(BillingAgentAction(
                type: .paymentReminder,
                title: "Roleplay limit nearly reached",
                detail: "Autonomous billing agent suggests Pro before your next training session.",
                suggestedTier: .pro
            ))
        }

        let monthlyEstimate = profile.tier.monthlyPrice
        var aiSummary = "Usage looks healthy for your \(profile.tier.rawValue) plan."
        var recommended = profile.tier

        if AppConfig.isAIConfigured {
            if let report = try? await OpenAIService.shared.requestBillingAgentReview(
                tier: profile.tier,
                tokensUsed: profile.aiTokensUsedThisMonth,
                roleplaysUsed: profile.roleplaysUsedThisMonth,
                discoveryUsed: profile.discoverySearchesUsedThisMonth
            ) {
                aiSummary = report.summary
                recommended = report.recommendedTier
                actions.insert(contentsOf: report.actions, at: 0)
                if let tokenBilling, let office {
                    tokenBilling.charge(
                        feature: .billingAgentReview,
                        tokensUsed: report.tokensUsed,
                        userId: userId,
                        subscription: subscription,
                        office: office
                    )
                }
            }
        }

        let tokenCostMTD = tokenBilling?.costThisMonth(userId: userId) ?? 0
        if tokenCostMTD > 0 {
            actions.append(BillingAgentAction(
                type: .costAlert,
                title: "Token charges this month: $\(String(format: "%.2f", tokenCostMTD))",
                detail: "AI features billed at $\(String(format: "%.3f", TokenBillingRates.costPerThousandTokens))/1K tokens.",
                estimatedSavings: nil
            ))
        }

        let overage = tokenBilling?.projectedOverageCost(subscription: subscription) ?? 0
        if overage > 0 {
            actions.append(BillingAgentAction(
                type: .paymentReminder,
                title: "Token overage projected: $\(String(format: "%.2f", overage))",
                detail: "Upgrade tier or reduce AI usage to avoid overage charges.",
                suggestedTier: profile.tier == .free ? .pro : .team
            ))
        }

        if autonomousModeEnabled {
            for index in actions.indices {
                if actions[index].type == .recommendUpgrade,
                   actions[index].suggestedTier == .pro,
                   profile.tier == .free,
                   profile.roleplaysUsedThisMonth >= 3 {
                    subscription.upgrade(to: .pro)
                    actions[index] = BillingAgentAction(
                        id: actions[index].id,
                        type: .autoApplied,
                        title: "Auto-upgraded to Pro",
                        detail: "Billing agent detected heavy training usage and applied Pro tier locally.",
                        suggestedTier: .pro,
                        autoExecuted: true,
                        createdAt: actions[index].createdAt
                    )
                    recommended = .pro
                }
            }
        }

        latestReport = BillingAgentReport(
            summary: aiSummary,
            actions: actions,
            recommendedPlan: recommended,
            monthlyEstimate: monthlyEstimate,
            autonomousNote: autonomousModeEnabled
                ? "Autonomous mode ON — agent can apply safe plan changes and draft invoices."
                : "Autonomous mode OFF — review suggestions manually."
        )
        actionLog = actions + actionLog
        lastRunAt = .now
        persistLog(for: userId)
    }

    private func persistLog(for userId: String) {
        let trimmed = Array(actionLog.prefix(40))
        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(data, forKey: "\(logKey)_\(userId)")
        }
    }
}
