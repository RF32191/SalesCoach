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

struct CRMImportResult: Equatable {
    let imported: Int
    let skipped: Int
    let duplicates: Int
    let errors: [String]
}

struct CSVLeadRow {
    let fields: [String: String]

    func makeLead(ownerId: String) -> Lead {
        let stage = DealStage.allCases.first {
            $0.rawValue.localizedCaseInsensitiveContains(fields["stage"] ?? "")
        } ?? .newLead
        let priority = LeadPriority.allCases.first {
            $0.rawValue.localizedCaseInsensitiveContains(fields["priority"] ?? "")
        } ?? .warm
        let value = Double(fields["value"]?.filter { $0.isNumber || $0 == "." } ?? "") ?? 0
        let probability = Int(fields["probability"]?.filter(\.isNumber) ?? "") ?? 20
        let followUp: Date? = {
            guard let raw = fields["next follow-up"] ?? fields["nextfollowup"], !raw.isEmpty else { return nil }
            return ISO8601DateFormatter().date(from: raw) ?? ISO8601DateFormatter().date(from: raw + "T12:00:00Z")
        }()
        return Lead(
            ownerId: ownerId,
            name: fields["name"] ?? "Imported Contact",
            company: fields["company"] ?? "",
            phone: fields["phone"] ?? "",
            email: fields["email"] ?? "",
            dealValue: value,
            dealStage: stage,
            nextFollowUpDate: followUp,
            probabilityOfClosing: min(100, max(0, probability)),
            leadSource: fields["source"] ?? "CSV Import",
            priority: priority
        )
    }
}
