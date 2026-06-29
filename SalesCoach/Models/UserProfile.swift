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
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        email: String,
        fullName: String,
        accountType: AccountType = .individual,
        companyName: String? = nil,
        authProvider: AuthProvider = .email,
        teamId: String? = nil,
        isManager: Bool = false,
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
        self.createdAt = createdAt
    }
}
