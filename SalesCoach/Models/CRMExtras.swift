import Foundation

enum ContactRole: String, Codable, CaseIterable, Identifiable {
    case decisionMaker = "Decision Maker"
    case influencer = "Influencer"
    case champion = "Champion"
    case gatekeeper = "Gatekeeper"
    case endUser = "End User"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .decisionMaker: "person.fill.checkmark"
        case .influencer: "person.2.fill"
        case .champion: "star.fill"
        case .gatekeeper: "lock.fill"
        case .endUser: "person.fill"
        }
    }
}

enum LeadSortOption: String, CaseIterable, Identifiable {
    case recentlyUpdated = "Recently Updated"
    case followUpDate = "Follow-Up Date"
    case dealValue = "Deal Value"
    case healthScore = "Health Score"
    case name = "Name"

    var id: String { rawValue }
}

enum CRMListFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case favorites = "Favorites"
    case hot = "Hot"
    case stale = "Going Cold"
    case overdue = "Overdue"

    var id: String { rawValue }
}

struct CRMTask: Codable, Identifiable, Equatable {
    var id: String
    var leadId: String
    var title: String
    var dueDate: Date
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        leadId: String,
        title: String,
        dueDate: Date,
        isCompleted: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.leadId = leadId
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    var isOverdue: Bool {
        !isCompleted && dueDate < Calendar.current.startOfDay(for: .now)
    }

    var isDueToday: Bool {
        !isCompleted && Calendar.current.isDateInToday(dueDate)
    }
}

struct CompanyGroup: Identifiable, Equatable {
    let company: String
    let leads: [Lead]

    var id: String { company }
    var totalValue: Double { leads.reduce(0) { $0 + $1.dealValue } }
    var activeCount: Int { leads.filter { $0.dealStage.isActivePipeline }.count }
}
