import Foundation

@MainActor
struct SalesActionExecutor {
    let crm: CRMService
    let audit: AuditService
    let teamSales: TeamSalesService
    let gamification: GamificationService
    let userId: String
    let repName: String
    let teamId: String
    let source: AuditSource

    func execute(_ actions: [SalesAction]) -> [String] {
        actions.compactMap { execute($0) }
    }

    func execute(_ action: SalesAction) -> String? {
        guard action.type == .logSale else { return nil }
        return logTeamSale(action)
    }

    private func logTeamSale(_ action: SalesAction) -> String? {
        let clientName = action.leadMatch ?? action.name ?? "Client"
        let company = action.company ?? ""
        let value = action.dealValue ?? 0
        guard value > 0 else { return "Include a dollar amount, e.g. \"Closed $5k with Acme.\"" }

        let sale = TeamSale(
            teamId: teamId,
            repUserId: userId,
            repName: repName,
            clientName: clientName,
            company: company,
            amount: value,
            notes: action.summary ?? "",
            source: source
        )
        teamSales.log(sale)

        if let lead = findLead(clientName) {
            crm.closeOrder(
                leadId: lead.id,
                finalValue: value,
                notes: action.summary ?? "Logged via team sales chat",
                source: source,
                actorId: userId
            )
        } else {
            recordStandaloneOrder(clientName: clientName, company: company, value: value, notes: action.summary ?? "")
        }

        gamification.record(.dealWon, userId: userId)
        return "Logged \(formatCurrency(value)) sale — \(clientName) — to your team feed."
    }

    private func recordStandaloneOrder(clientName: String, company: String, value: Double, notes: String) {
        let order = ClosedOrder(
            leadId: "",
            ownerId: userId,
            clientName: clientName,
            company: company,
            finalValue: value,
            notes: notes,
            source: source
        )
        let auditEntry = AuditEntry(
            entityType: .order,
            entityId: order.id,
            entityLabel: clientName,
            actorId: userId,
            action: "team.sale.logged",
            summary: "\(repName) logged sale — \(clientName) for \(Int(value))",
            source: source,
            changes: [FieldChange(field: "amount", oldValue: "0", newValue: String(Int(value)))]
        )
        audit.recordClosedOrder(order, audit: auditEntry, for: userId)
    }

    private func findLead(_ match: String) -> Lead? {
        let query = match.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return nil }
        if let exact = crm.leads.first(where: {
            $0.name.lowercased() == query || $0.company.lowercased() == query
        }) { return exact }
        return crm.leads.first(where: {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.company.localizedCaseInsensitiveContains(query)
        })
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1000 { return String(format: "$%.0fK", value / 1000) }
        return String(format: "$%.0f", value)
    }
}
