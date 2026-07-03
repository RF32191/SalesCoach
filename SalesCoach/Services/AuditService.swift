import Foundation

@MainActor
@Observable
final class AuditService {
    private(set) var entries: [AuditEntry] = []
    private(set) var closedOrders: [ClosedOrder] = []

    private let auditKey = "salescoach_audit"
    private let ordersKey = "salescoach_closed_orders"

    func load(for userId: String) {
        let auditStorage = "\(auditKey)_\(userId)"
        let ordersStorage = "\(ordersKey)_\(userId)"
        if let data = UserDefaults.standard.data(forKey: auditStorage),
           let stored = try? JSONDecoder().decode([AuditEntry].self, from: data) {
            entries = stored.sorted { $0.timestamp > $1.timestamp }
        } else {
            entries = []
        }
        if let data = UserDefaults.standard.data(forKey: ordersStorage),
           let stored = try? JSONDecoder().decode([ClosedOrder].self, from: data) {
            closedOrders = stored.sorted { $0.closedAt > $1.closedAt }
        } else {
            closedOrders = []
        }
    }

    func append(_ entry: AuditEntry, for userId: String) {
        entries.insert(entry, at: 0)
        saveAudit(for: userId)
    }

    func recordClosedOrder(_ order: ClosedOrder, audit: AuditEntry, for userId: String) {
        closedOrders.insert(order, at: 0)
        entries.insert(audit, at: 0)
        saveAudit(for: userId)
        saveOrders(for: userId)
    }

    func entries(for entityId: String) -> [AuditEntry] {
        entries.filter { $0.entityId == entityId }
    }

    func ordersThisMonth(for userId: String) -> [ClosedOrder] {
        let calendar = Calendar.current
        return closedOrders.filter {
            $0.ownerId == userId && calendar.isDate($0.closedAt, equalTo: .now, toGranularity: .month)
        }
    }

    func revenueThisMonth(for userId: String) -> Double {
        ordersThisMonth(for: userId).reduce(0) { $0 + $1.finalValue }
    }

    func clear(for userId: String) {
        entries = []
        closedOrders = []
        saveAudit(for: userId)
        saveOrders(for: userId)
    }

    private func saveAudit(for userId: String) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "\(auditKey)_\(userId)")
        }
    }

    private func saveOrders(for userId: String) {
        if let data = try? JSONEncoder().encode(closedOrders) {
            UserDefaults.standard.set(data, forKey: "\(ordersKey)_\(userId)")
        }
    }
}
