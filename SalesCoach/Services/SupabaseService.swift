import Foundation

struct SupabaseAuthResponse {
    let userId: String
    let accessToken: String?
}

enum SupabaseError: LocalizedError {
    case notConfigured
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY."
        case .invalidResponse: "Invalid response from Supabase."
        case .serverError(let message): message
        }
    }
}

final class SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    func signUp(email: String, password: String) async throws -> SupabaseAuthResponse {
        try await authRequest(path: "signup", body: ["email": email, "password": password])
    }

    func signIn(email: String, password: String) async throws -> SupabaseAuthResponse {
        try await authRequest(path: "token?grant_type=password", body: ["email": email, "password": password])
    }

    private func authRequest(path: String, body: [String: String]) async throws -> SupabaseAuthResponse {
        guard AppConfig.isSupabaseConfigured,
              let url = URL(string: "\(AppConfig.supabaseURL)/auth/v1/\(path)") else {
            throw SupabaseError.notConfigured
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw SupabaseError.invalidResponse }

        if http.statusCode >= 400 {
            let message = String(data: data, encoding: .utf8) ?? "Authentication failed"
            throw SupabaseError.serverError(message)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SupabaseError.invalidResponse
        }

        let userId = (json["user"] as? [String: Any])?["id"] as? String
            ?? json["id"] as? String
            ?? UUID().uuidString
        let token = json["access_token"] as? String

        return SupabaseAuthResponse(userId: userId, accessToken: token)
    }
}
