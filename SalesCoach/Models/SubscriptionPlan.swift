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

    var hasUnlimitedChat: Bool {
        self != .free
    }

    var hasTeamDashboard: Bool {
        self == .team || self == .enterprise
    }

    var hasCRM: Bool {
        self == .team || self == .enterprise || self == .pro
    }

    var features: [String] {
        switch self {
        case .free:
            ["3 AI roleplays per month", "Basic AI chat (limited)", "Training scenarios"]
        case .pro:
            ["Unlimited AI chat", "30 voice roleplays/month", "Full CRM access", "AI scoring reports"]
        case .team:
            ["Everything in Pro", "Manager dashboard", "Team accounts", "CRM & analytics", "Leaderboard"]
        case .enterprise:
            ["Everything in Team", "Custom pricing", "Dedicated support", "SSO & compliance"]
        }
    }
}

struct SubscriptionUsage: Codable {
    var tier: SubscriptionTier
    var roleplaysUsedThisMonth: Int
    var chatMessagesUsedThisMonth: Int
    var resetDate: Date

    var roleplaysRemaining: Int? {
        guard let limit = tier.roleplayLimit else { return nil }
        return max(0, limit - roleplaysUsedThisMonth)
    }

    func canStartRoleplay() -> Bool {
        guard let remaining = roleplaysRemaining else { return true }
        return remaining > 0
    }
}
