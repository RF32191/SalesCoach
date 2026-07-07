import Foundation

@MainActor
@Observable
final class TeamSalesService {
    private(set) var sales: [TeamSale] = []
    private(set) var updates: [TeamFeedUpdate] = []

    private let salesKey = "salescoach_team_sales"
    private let updatesKey = "salescoach_team_feed_updates"

    func load(for teamId: String) {
        sales = decodeList(TeamSale.self, key: salesKey)
            .filter { $0.teamId == teamId }
            .sorted { $0.loggedAt > $1.loggedAt }
        updates = decodeList(TeamFeedUpdate.self, key: updatesKey)
            .filter { $0.teamId == teamId }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    func log(_ sale: TeamSale) {
        sales.insert(sale, at: 0)
        persistSales()
    }

    func postUpdate(_ update: TeamFeedUpdate) {
        updates.insert(update, at: 0)
        persistUpdates()
    }

    func feed(for teamId: String) -> [TeamFeedItem] {
        let items: [TeamFeedItem] =
            sales.filter { $0.teamId == teamId }.map { .sale($0) } +
            updates.filter { $0.teamId == teamId }.map { .update($0) }
        return items.sorted { $0.loggedAt > $1.loggedAt }
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

    func clear(for teamId: String) {
        var allSales = decodeList(TeamSale.self, key: salesKey)
        allSales.removeAll { $0.teamId == teamId }
        if let data = try? JSONEncoder().encode(allSales) {
            UserDefaults.standard.set(data, forKey: salesKey)
        }
        var allUpdates = decodeList(TeamFeedUpdate.self, key: updatesKey)
        allUpdates.removeAll { $0.teamId == teamId }
        if let data = try? JSONEncoder().encode(allUpdates) {
            UserDefaults.standard.set(data, forKey: updatesKey)
        }
        sales = []
        updates = []
    }

    private func persistSales() {
        var all = decodeList(TeamSale.self, key: salesKey)
        let teamIds = Set(sales.map(\.teamId))
        all.removeAll { teamIds.contains($0.teamId) }
        all.append(contentsOf: sales)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: salesKey)
        }
    }

    private func persistUpdates() {
        var all = decodeList(TeamFeedUpdate.self, key: updatesKey)
        let teamIds = Set(updates.map(\.teamId))
        all.removeAll { teamIds.contains($0.teamId) }
        all.append(contentsOf: updates)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: updatesKey)
        }
    }

    private func decodeList<T: Decodable>(_ type: T.Type, key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode([T].self, from: data) else { return [] }
        return stored
    }
}
