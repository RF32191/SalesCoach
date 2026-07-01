import Foundation

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case individual = "Individual"
    case team = "Team / Company"

    var id: String { rawValue }
}

enum AuthProvider: String, Codable {
    case email
    case apple
    case google
}

struct UserProfile: Codable, Identifiable, Equatable {
    var id: String
    var email: String
    var fullName: String
    var accountType: AccountType
    var companyName: String?
    var authProvider: AuthProvider
    var teamId: String?
    var isManager: Bool
    var salesCategory: SalesCategory?
    var createdAt: Date

    var hasSelectedSalesCategory: Bool { salesCategory != nil }

    init(
        id: String = UUID().uuidString,
        email: String,
        fullName: String,
        accountType: AccountType = .individual,
        companyName: String? = nil,
        authProvider: AuthProvider = .email,
        teamId: String? = nil,
        isManager: Bool = false,
        salesCategory: SalesCategory? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.accountType = accountType
        self.companyName = companyName
        self.authProvider = authProvider
        self.teamId = teamId
        self.isManager = isManager
        self.salesCategory = salesCategory
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, email, fullName, accountType, companyName, authProvider, teamId, isManager, salesCategory, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        fullName = try container.decode(String.self, forKey: .fullName)
        accountType = try container.decodeIfPresent(AccountType.self, forKey: .accountType) ?? .individual
        companyName = try container.decodeIfPresent(String.self, forKey: .companyName)
        authProvider = try container.decodeIfPresent(AuthProvider.self, forKey: .authProvider) ?? .email
        teamId = try container.decodeIfPresent(String.self, forKey: .teamId)
        isManager = try container.decodeIfPresent(Bool.self, forKey: .isManager) ?? false
        salesCategory = try container.decodeIfPresent(SalesCategory.self, forKey: .salesCategory)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
    }
}
