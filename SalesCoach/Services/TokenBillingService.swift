import Foundation

@MainActor
@Observable
final class TokenBillingService {
    private(set) var charges: [TokenChargeRecord] = []
    private let storageKey = "salescoach_token_charges"

    func load(for userId: String) {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([TokenChargeRecord].self, from: data) else {
            charges = []
            return
        }
        charges = stored.filter { $0.userId == userId }.sorted { $0.createdAt > $1.createdAt }
    }

    func canUseFeature(_ feature: AIBillingFeature, subscription: SubscriptionService) -> Bool {
        subscription.canUseAI(estimatedTokens: feature.estimatedTokens)
    }

    @discardableResult
    func charge(
        feature: AIBillingFeature,
        tokensUsed: Int,
        userId: String,
        subscription: SubscriptionService,
        office: OfficeService
    ) -> TokenChargeRecord {
        let billable = feature.billableTokens(actual: tokensUsed)
        let cost = feature.dollarCost(forTokens: billable)
        let record = TokenChargeRecord(
            userId: userId,
            feature: feature,
            tokensUsed: tokensUsed,
            billableTokens: billable,
            dollarCost: cost
        )
        charges.insert(record, at: 0)
        persist(for: userId)

        office.addAccountingEntry(AccountingEntry(
            userId: userId,
            type: .tokenCharge,
            amount: cost,
            note: "\(feature.rawValue): \(billable.formatted()) tokens · $\(String(format: "%.4f", cost))"
        ))

        return record
    }

    func tokensThisMonth(userId: String) -> Int {
        let calendar = Calendar.current
        return charges
            .filter { $0.userId == userId && calendar.isDate($0.createdAt, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + $1.billableTokens }
    }

    func costThisMonth(userId: String) -> Double {
        let calendar = Calendar.current
        return charges
            .filter { $0.userId == userId && calendar.isDate($0.createdAt, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + $1.dollarCost }
    }

    func projectedOverageCost(subscription: SubscriptionService) -> Double {
        guard let limit = subscription.usage.tier.monthlyTokenLimit else { return 0 }
        let over = max(0, subscription.usage.aiTokensUsedThisMonth - limit)
        return Double(over) / 1000.0 * TokenBillingRates.costPerThousandTokens
    }

    private func persist(for userId: String) {
        var all = (UserDefaults.standard.data(forKey: storageKey)
            .flatMap { try? JSONDecoder().decode([TokenChargeRecord].self, from: $0) }) ?? []
        all.removeAll { $0.userId == userId }
        all.append(contentsOf: charges)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
