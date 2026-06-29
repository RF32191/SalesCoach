import Foundation

enum AppConfig {
    static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
    static let openAIAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    static let railwayAPIURL = ProcessInfo.processInfo.environment["RAILWAY_API_URL"] ?? ""
    static let railwayAPIKey = ProcessInfo.processInfo.environment["RAILWAY_API_KEY"] ?? ""

    static var isSupabaseConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
    }

    static var isRailwayConfigured: Bool {
        !railwayAPIURL.isEmpty && railwayAPIURL.hasPrefix("http")
    }

    static var isOpenAIConfigured: Bool {
        !openAIAPIKey.isEmpty
    }

    static var isAIConfigured: Bool {
        isRailwayConfigured || isOpenAIConfigured
    }

    static let appName = "Sales Coach"
    static let demoModeEnabled = true
}
