import Foundation

@MainActor
@Observable
final class OfficeService {
    private(set) var accountingEntries: [AccountingEntry] = []
    private(set) var complaints: [ClientComplaint] = []

    private let accountingKey = "salescoach_accounting"
    private let complaintsKey = "salescoach_complaints"

    func load(for userId: String) {
        accountingEntries = decode(AccountingEntry.self, key: accountingKey)
            .filter { $0.userId == userId }
            .sorted { $0.loggedAt > $1.loggedAt }
        complaints = decode(ClientComplaint.self, key: complaintsKey)
            .filter { $0.userId == userId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func syncFromAudit(userId: String, orders: [ClosedOrder]) {
        let linked = Set(accountingEntries.compactMap { entry -> String? in
            entry.note.hasPrefix("order:") ? String(entry.note.dropFirst(6).split(separator: " ").first ?? "") : nil
        })
        for order in orders where order.ownerId == userId && !linked.contains(order.id) {
            addAccountingEntry(AccountingEntry(
                userId: userId,
                leadId: order.leadId,
                type: .commission,
                amount: order.finalValue * order.commissionRate,
                note: "order:\(order.id) · Closed \(order.clientName)"
            ))
        }
    }

    func addAccountingEntry(_ entry: AccountingEntry) {
        accountingEntries.insert(entry, at: 0)
        saveAccounting()
    }

    func addComplaint(_ complaint: ClientComplaint) {
        complaints.insert(complaint, at: 0)
        saveComplaints()
    }

    func updateComplaint(_ complaint: ClientComplaint) {
        guard let index = complaints.firstIndex(where: { $0.id == complaint.id }) else { return }
        var updated = complaint
        updated.updatedAt = .now
        complaints[index] = updated
        saveComplaints()
    }

    func deleteComplaint(_ complaint: ClientComplaint) {
        complaints.removeAll { $0.id == complaint.id }
        saveComplaints()
    }

    func openComplaints() -> [ClientComplaint] {
        complaints.filter { $0.status != .resolved }
    }

    func revenueThisMonth(userId: String) -> Double {
        monthTotal(userId: userId, types: [.commission, .payment])
    }

    func expensesThisMonth(userId: String) -> Double {
        monthTotal(userId: userId, types: [.expense])
    }

    func netThisMonth(userId: String) -> Double {
        revenueThisMonth(userId: userId) - expensesThisMonth(userId: userId)
    }

    private func monthTotal(userId: String, types: [AccountingEntryType]) -> Double {
        let calendar = Calendar.current
        return accountingEntries
            .filter { $0.userId == userId && types.contains($0.type) && calendar.isDate($0.loggedAt, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode([T].self, from: data) else { return [] }
        return stored
    }

    private func saveAccounting() {
        var all = decode(AccountingEntry.self, key: accountingKey)
        let userIds = Set(accountingEntries.map(\.userId))
        all.removeAll { userIds.contains($0.userId) }
        all.append(contentsOf: accountingEntries)
        if let data = try? JSONEncoder().encode(all) { UserDefaults.standard.set(data, forKey: accountingKey) }
    }

    private func saveComplaints() {
        var all = decode(ClientComplaint.self, key: complaintsKey)
        let userIds = Set(complaints.map(\.userId))
        all.removeAll { userIds.contains($0.userId) }
        all.append(contentsOf: complaints)
        if let data = try? JSONEncoder().encode(all) { UserDefaults.standard.set(data, forKey: complaintsKey) }
    }
}
