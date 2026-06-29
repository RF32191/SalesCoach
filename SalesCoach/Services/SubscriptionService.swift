import Foundation

@MainActor
@Observable
final class SubscriptionService {
    var usage: SubscriptionUsage
    private let storageKey = "salescoach_subscription"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let stored = try? JSONDecoder().decode(SubscriptionUsage.self, from: data) {
            usage = stored
            resetIfNeeded()
        } else {
            usage = SubscriptionUsage(tier: .free, roleplaysUsedThisMonth: 0, chatMessagesUsedThisMonth: 0, resetDate: .now)
        }
    }

    func upgrade(to tier: SubscriptionTier) {
        usage.tier = tier
        save()
    }

    func recordRoleplay() {
        usage.roleplaysUsedThisMonth += 1
        save()
    }

    func recordChatMessage() {
        if !usage.tier.hasUnlimitedChat {
            usage.chatMessagesUsedThisMonth += 1
        }
        save()
    }

    func canStartRoleplay() -> Bool {
        resetIfNeeded()
        return usage.canStartRoleplay()
    }

    func canSendChat() -> Bool {
        resetIfNeeded()
        if usage.tier.hasUnlimitedChat { return true }
        return usage.chatMessagesUsedThisMonth < 20
    }

    private func resetIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDate(usage.resetDate, equalTo: .now, toGranularity: .month) {
            usage.roleplaysUsedThisMonth = 0
            usage.chatMessagesUsedThisMonth = 0
            usage.resetDate = .now
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(usage) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
