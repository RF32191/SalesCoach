import Foundation

enum AuditSource: String, Codable, CaseIterable {
    case manual = "Manual"
    case chat = "AI Chat"
    case pipeline = "Pipeline"
    case importCSV = "Import"
    case system = "System"
}

enum AuditEntityType: String, Codable {
    case lead = "Lead"
    case order = "Order"
    case task = "Task"
}

struct FieldChange: Codable, Equatable, Identifiable {
    var id: String { field }
    let field: String
    let oldValue: String
    let newValue: String
}

struct AuditEntry: Codable, Identifiable, Equatable {
    var id: String
    var entityType: AuditEntityType
    var entityId: String
    var entityLabel: String
    var actorId: String
    var action: String
    var summary: String
    var timestamp: Date
    var source: AuditSource
    var changes: [FieldChange]

    init(
        id: String = UUID().uuidString,
        entityType: AuditEntityType,
        entityId: String,
        entityLabel: String,
        actorId: String,
        action: String,
        summary: String,
        timestamp: Date = .now,
        source: AuditSource = .manual,
        changes: [FieldChange] = []
    ) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.entityLabel = entityLabel
        self.actorId = actorId
        self.action = action
        self.summary = summary
        self.timestamp = timestamp
        self.source = source
        self.changes = changes
    }
}

struct OrderLineItem: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var quantity: Int
    var unitPrice: Double

    init(id: String = UUID().uuidString, name: String, quantity: Int = 1, unitPrice: Double) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
    }

    var total: Double { Double(quantity) * unitPrice }
}

struct ClosedOrder: Codable, Identifiable, Equatable {
    var id: String
    var leadId: String
    var ownerId: String
    var clientName: String
    var company: String
    var finalValue: Double
    var closedAt: Date
    var lineItems: [OrderLineItem]
    var notes: String
    var source: AuditSource

    init(
        id: String = UUID().uuidString,
        leadId: String,
        ownerId: String,
        clientName: String,
        company: String,
        finalValue: Double,
        closedAt: Date = .now,
        lineItems: [OrderLineItem] = [],
        notes: String = "",
        source: AuditSource = .manual
    ) {
        self.id = id
        self.leadId = leadId
        self.ownerId = ownerId
        self.clientName = clientName
        self.company = company
        self.finalValue = finalValue
        self.closedAt = closedAt
        self.lineItems = lineItems
        self.notes = notes
        self.source = source
    }
}
