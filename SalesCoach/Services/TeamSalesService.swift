import Foundation

@MainActor
@Observable
final class TeamSalesService {
    private(set) var sales: [TeamSale] = []
    private let storageKey = "salescoach_team_sales"

    func load(for teamId: String) {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([TeamSale].self, from: data) else {
            sales = []
            return
        }
        sales = stored
            .filter { $0.teamId == teamId }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    func log(_ sale: TeamSale) {
        sales.insert(sale, at: 0)
        save(for: sale.teamId)
    }

    func salesThisMonth(for teamId: String) -> [TeamSale] {
        let calendar = Calendar.current
        return sales.filter {
            $0.teamId == teamId && calendar.isDate($0.loggedAt, equalTo: .now, toGranularity: .month)
        }
    }

    func revenueThisMonth(for teamId: String) -> Double {
        salesThisMonth(for: teamId).reduce(0) { $0 + $1.amount }
    }

    func salesByRep(for teamId: String) -> [(repName: String, total: Double, count: Int)] {
        let monthSales = salesThisMonth(for: teamId)
        var grouped: [String: (total: Double, count: Int)] = [:]
        for sale in monthSales {
            let current = grouped[sale.repName, default: (0, 0)]
            grouped[sale.repName] = (current.total + sale.amount, current.count + 1)
        }
        return grouped
            .map { (repName: $0.key, total: $0.value.total, count: $0.value.count) }
            .sorted { $0.total > $1.total }
    }

    func clear(for teamId: String) {
        sales.removeAll { $0.teamId == teamId }
        save(for: teamId)
    }

    private func save(for teamId: String) {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              var all = try? JSONDecoder().decode([TeamSale].self, from: data) else {
            if let data = try? JSONEncoder().encode(sales) {
                UserDefaults.standard.set(data, forKey: storageKey)
            }
            return
        }
        all.removeAll { $0.teamId == teamId }
        all.append(contentsOf: sales)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
