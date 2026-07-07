import Foundation

@MainActor
@Observable
final class CommissionService {
    private(set) var settings = QuotaSettings.default
    private var storageKey: String { "salescoach_quota_settings" }

    func load(for userId: String) {
        let key = "\(storageKey)_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode(QuotaSettings.self, from: data) else {
            settings = .default
            return
        }
        settings = stored
    }

    func save(for userId: String) {
        let key = "\(storageKey)_\(userId)"
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func updateMonthlyTarget(_ value: Double, for userId: String) {
        settings.monthlyRevenueTarget = value
        save(for: userId)
    }

    func updateCommissionRate(_ rate: Double, for userId: String) {
        settings.defaultCommissionRate = rate
        save(for: userId)
    }

    func commission(for order: ClosedOrder) -> Double {
        order.finalValue * order.commissionRate
    }

    func commissionThisMonth(orders: [ClosedOrder], userId: String) -> Double {
        let calendar = Calendar.current
        return orders
            .filter { $0.ownerId == userId && calendar.isDate($0.closedAt, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + commission(for: $1) }
    }

    func revenueThisMonth(orders: [ClosedOrder], userId: String) -> Double {
        let calendar = Calendar.current
        return orders
            .filter { $0.ownerId == userId && calendar.isDate($0.closedAt, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + $1.finalValue }
    }

    func quotaProgress(orders: [ClosedOrder], userId: String) -> Double {
        let revenue = revenueThisMonth(orders: orders, userId: userId)
        guard settings.monthlyRevenueTarget > 0 else { return 0 }
        return min(1, revenue / settings.monthlyRevenueTarget)
    }

    struct CommissionCalculation: Equatable {
        let dealValue: Double
        let discountPercent: Double
        let commissionRate: Double
        let splitPercent: Double
        let spiff: Double
        let netDealValue: Double
        let grossCommission: Double
        let yourCommission: Double
        let totalPayout: Double
        let quotaTarget: Double
        let closedRevenueThisMonth: Double
        let quotaProgressAfterClose: Double
        let dealsNeededForQuota: Int?
    }

    func calculate(
        dealValue: Double,
        discountPercent: Double = 0,
        commissionRate: Double? = nil,
        splitPercent: Double = 100,
        spiff: Double = 0,
        closedRevenueThisMonth: Double = 0
    ) -> CommissionCalculation {
        let rate = commissionRate ?? settings.defaultCommissionRate
        let netDeal = dealValue * (1 - discountPercent / 100)
        let gross = netDeal * rate
        let share = gross * (splitPercent / 100)
        let total = share + spiff
        let target = settings.monthlyRevenueTarget
        let progress = target > 0 ? min(1, (closedRevenueThisMonth + netDeal) / target) : 0
        let remaining = max(0, target - closedRevenueThisMonth)
        let dealsNeeded: Int? = {
            guard target > 0, netDeal > 0, remaining > 0 else { return target > 0 && remaining <= 0 ? 0 : nil }
            return Int(ceil(remaining / netDeal))
        }()

        return CommissionCalculation(
            dealValue: dealValue,
            discountPercent: discountPercent,
            commissionRate: rate,
            splitPercent: splitPercent,
            spiff: spiff,
            netDealValue: netDeal,
            grossCommission: gross,
            yourCommission: share,
            totalPayout: total,
            quotaTarget: target,
            closedRevenueThisMonth: closedRevenueThisMonth,
            quotaProgressAfterClose: progress,
            dealsNeededForQuota: dealsNeeded
        )
    }
}
