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
        let name = combinedName()
        let stage = mappedStage()
        let priority = LeadPriority.allCases.first {
            $0.rawValue.localizedCaseInsensitiveContains(field("priority", "lead priority") ?? "")
        } ?? .warm
        let value = Double(field("value", "amount", "deal value", "deal amount", "annual revenue")?.filter { $0.isNumber || $0 == "." } ?? "") ?? 0
        let probability = Int(field("probability", "close probability", "win probability")?.filter(\.isNumber) ?? "") ?? 20
        let followUp: Date? = {
            guard let raw = field("next follow-up", "nextfollowup", "follow up date", "follow-up date"), !raw.isEmpty else { return nil }
            return ISO8601DateFormatter().date(from: raw) ?? ISO8601DateFormatter().date(from: raw + "T12:00:00Z")
        }()
        let source = field("source", "lead source", "original source", "record source") ?? "CRM Import"
        var notes = field("notes", "description", "about") ?? ""
        if let title = field("title", "job title", "jobtitle"), !title.isEmpty {
            notes = notes.isEmpty ? title : "\(title)\n\(notes)"
        }
        return Lead(
            ownerId: ownerId,
            name: name.isEmpty ? "Imported Contact" : name,
            company: field("company", "company name", "account name", "organization", "org") ?? "",
            phone: field("phone", "phone number", "mobile phone", "mobile", "work phone", "telephone") ?? "",
            email: field("email", "email address", "work email", "e-mail") ?? "",
            dealValue: value,
            dealStage: stage,
            notes: notes,
            nextFollowUpDate: followUp,
            probabilityOfClosing: min(100, max(0, probability)),
            leadSource: source,
            priority: priority
        )
    }

    private func combinedName() -> String {
        if let full = field("name", "full name", "contact name"), !full.isEmpty { return full }
        let first = field("first name", "firstname", "first_name") ?? ""
        let last = field("last name", "lastname", "last_name") ?? ""
        return [first, last].filter { !$0.isEmpty }.joined(separator: " ")
    }

    private func mappedStage() -> DealStage {
        let raw = field("stage", "deal stage", "dealstage", "pipeline stage", "lifecycle stage", "status") ?? ""
        if raw.isEmpty { return .newLead }
        let normalized = raw.lowercased()
        if normalized.contains("closed won") || normalized == "won" { return .won }
        if normalized.contains("closed lost") || normalized == "lost" { return .lost }
        if normalized.contains("proposal") { return .proposalSent }
        if normalized.contains("negotiat") { return .negotiation }
        if normalized.contains("procure") { return .procurement }
        if normalized.contains("legal") { return .legal }
        if normalized.contains("demo") { return .demo }
        if normalized.contains("discover") { return .discovery }
        if normalized.contains("qualif") { return .qualified }
        if normalized.contains("contact") { return .contacted }
        return DealStage.allCases.first { $0.rawValue.localizedCaseInsensitiveContains(raw) } ?? .newLead
    }

    private func field(_ keys: String...) -> String? {
        for key in keys {
            let lowered = key.lowercased()
            if let exact = fields[lowered], !exact.isEmpty { return exact }
            if let match = fields.first(where: { $0.key.replacingOccurrences(of: "_", with: " ") == lowered && !$0.value.isEmpty })?.value {
                return match
            }
        }
        return nil
    }
}
