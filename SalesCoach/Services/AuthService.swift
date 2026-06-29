import Foundation
import AuthenticationServices

@MainActor
@Observable
final class AuthService {
    var currentUser: UserProfile?
    var isAuthenticated: Bool { currentUser != nil }
    var isLoading = false
    var errorMessage: String?

    private let storageKey = "salescoach_user"

    init() {
        loadStoredUser()
    }

    func signInWithApple(
        _ result: Result<ASAuthorization, Error>,
        accountType: AccountType = .individual,
        companyName: String? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Apple Sign In failed."
                return
            }

            if accountType == .team, (companyName ?? "").trimmingCharacters(in: .whitespaces).isEmpty {
                errorMessage = "Enter your company name for a team account."
                return
            }

            let email = credential.email ?? storedEmail(for: credential.user) ?? "apple.user@privaterelay.appleid.com"
            let name = resolvedName(from: credential)
            let user = UserProfile(
                id: credential.user,
                email: email,
                fullName: name,
                accountType: accountType,
                companyName: accountType == .team ? companyName : nil,
                authProvider: .apple,
                teamId: accountType == .team ? UUID().uuidString : nil,
                isManager: accountType == .team
            )
            persistUser(user)
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func persistUser(_ user: UserProfile) {
        currentUser = user
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadStoredUser() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let user = try? JSONDecoder().decode(UserProfile.self, from: data),
              user.authProvider == .apple else { return }
        currentUser = user
    }

    private func storedEmail(for appleUserId: String) -> String? {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let user = try? JSONDecoder().decode(UserProfile.self, from: data),
              user.id == appleUserId else { return nil }
        return user.email
    }

    private func resolvedName(from credential: ASAuthorizationAppleIDCredential) -> String {
        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        if !name.isEmpty { return name }

        if let existing = currentUser?.fullName, !existing.isEmpty {
            return existing
        }

        return "Sales Coach User"
    }
}
