import Foundation

enum SubscriptionTier: String, Codable, CaseIterable, Identifiable {
    case free = "Free"
    case pro = "Pro"
    case team = "Team"
    case enterprise = "Enterprise"

    var id: String { rawValue }

    var monthlyPrice: String {
        switch self {
        case .free: "$0"
        case .pro: "$19.99"
        case .team: "$49.99"
        case .enterprise: "Custom"
        }
    }

    var roleplayLimit: Int? {
        switch self {
        case .free: 3
        case .pro: 30
        case .team, .enterprise: nil
        }
    }

    var monthlyTokenLimit: Int? {
        switch self {
        case .free: 10_000
        case .pro: 100_000
        case .team: 500_000
        case .enterprise: nil
        }
    }

    var monthlyDiscoverySearches: Int? {
        switch self {
        case .free: 10
        case .pro: 100
        case .team, .enterprise: nil
        }
    }

    var hasUnlimitedChat: Bool {
        self != .free
    }

    var hasTeamDashboard: Bool {
        self == .team || self == .enterprise
    }

    var hasCRM: Bool {
        true
    }

    var features: [String] {
        switch self {
        case .free:
            ["10,000 AI tokens/month", "3 voice roleplays", "AI chat coach", "CRM + map prospecting"]
        case .pro:
            ["100,000 AI tokens/month", "30 voice roleplays/month", "OpenAI natural voices", "Full CRM + GPS pinning"]
        case .team:
            ["500,000 AI tokens/month", "Unlimited roleplays", "Team dashboard", "Unlimited map searches"]
        case .enterprise:
            ["Unlimited AI tokens", "Everything in Team", "Custom pricing", "Dedicated support"]
        }
    }
}

struct SubscriptionUsage: Codable {
    var tier: SubscriptionTier
    var roleplaysUsedThisMonth: Int
    var chatMessagesUsedThisMonth: Int
    var aiTokensUsedThisMonth: Int
    var discoverySearchesUsedThisMonth: Int
    var resetDate: Date

    var roleplaysRemaining: Int? {
        guard let limit = tier.roleplayLimit else { return nil }
        return max(0, limit - roleplaysUsedThisMonth)
    }

    var tokensRemaining: Int? {
        guard let limit = tier.monthlyTokenLimit else { return nil }
        return max(0, limit - aiTokensUsedThisMonth)
    }

    var discoverySearchesRemaining: Int? {
        guard let limit = tier.monthlyDiscoverySearches else { return nil }
        return max(0, limit - discoverySearchesUsedThisMonth)
    }

    func canStartRoleplay() -> Bool {
        guard let remaining = roleplaysRemaining else { return true }
        return remaining > 0
    }

    func canUseTokens(_ amount: Int) -> Bool {
        guard let remaining = tokensRemaining else { return true }
        return remaining >= amount
    }

    func canSearchProspects() -> Bool {
        guard let remaining = discoverySearchesRemaining else { return true }
        return remaining > 0
    }

    init(
        tier: SubscriptionTier,
        roleplaysUsedThisMonth: Int,
        chatMessagesUsedThisMonth: Int,
        aiTokensUsedThisMonth: Int = 0,
        discoverySearchesUsedThisMonth: Int = 0,
        resetDate: Date
    ) {
        self.tier = tier
        self.roleplaysUsedThisMonth = roleplaysUsedThisMonth
        self.chatMessagesUsedThisMonth = chatMessagesUsedThisMonth
        self.aiTokensUsedThisMonth = aiTokensUsedThisMonth
        self.discoverySearchesUsedThisMonth = discoverySearchesUsedThisMonth
        self.resetDate = resetDate
    }

    enum CodingKeys: String, CodingKey {
        case tier, roleplaysUsedThisMonth, chatMessagesUsedThisMonth
        case aiTokensUsedThisMonth, discoverySearchesUsedThisMonth, resetDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tier = try container.decode(SubscriptionTier.self, forKey: .tier)
        roleplaysUsedThisMonth = try container.decodeIfPresent(Int.self, forKey: .roleplaysUsedThisMonth) ?? 0
        chatMessagesUsedThisMonth = try container.decodeIfPresent(Int.self, forKey: .chatMessagesUsedThisMonth) ?? 0
        aiTokensUsedThisMonth = try container.decodeIfPresent(Int.self, forKey: .aiTokensUsedThisMonth) ?? 0
        discoverySearchesUsedThisMonth = try container.decodeIfPresent(Int.self, forKey: .discoverySearchesUsedThisMonth) ?? 0
        resetDate = try container.decodeIfPresent(Date.self, forKey: .resetDate) ?? .now
    }
}
