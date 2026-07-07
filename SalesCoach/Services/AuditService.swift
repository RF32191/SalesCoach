import Foundation

@MainActor
@Observable
final class AuditService {
    private(set) var entries: [AuditEntry] = []
    private(set) var closedOrders: [ClosedOrder] = []

    func load(for userId: String) {}
    func append(_ entry: AuditEntry, for userId: String) { entries.insert(entry, at: 0) }
    func recordClosedOrder(_ order: ClosedOrder, audit: AuditEntry, for userId: String) {
        closedOrders.insert(order, at: 0)
        entries.insert(audit, at: 0)
    }
    func entries(for entityId: String) -> [AuditEntry] { entries.filter { $0.entityId == entityId } }
    func revenueThisMonth(for userId: String) -> Double { 0 }
    func clear(for userId: String) { entries = []; closedOrders = [] }
}
