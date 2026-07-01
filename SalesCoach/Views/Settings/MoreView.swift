import SwiftUI

struct MoreView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        LeaderboardView()
                    } label: {
                        Label("Leaderboard", systemImage: "trophy.fill")
                    }

                    if appState.auth.currentUser?.accountType == .team ||
                       appState.subscription.usage.tier.hasTeamDashboard {
                        NavigationLink {
                            TeamDashboardView()
                        } label: {
                            Label("Team Dashboard", systemImage: "person.3.fill")
                        }
                    }
                }

                Section("Account") {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        Label {
                            Text("Subscription Plans")
                        } icon: {
                            TierCrownIcon(tier: appState.subscription.usage.tier, size: 16)
                        }
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        appState.auth.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .appBackground()
            .navigationTitle("More")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    private var aiBackendStatus: String {
        if AppConfig.isRailwayConfigured { return "Railway" }
        if AppConfig.isOpenAIConfigured { return "OpenAI Direct" }
        return "Mock AI"
    }

    var body: some View {
        List {
            Section("Profile") {
                if let user = appState.auth.currentUser {
                    LabeledContent("Name", value: user.fullName)
                    LabeledContent("Sign In", value: "Apple ID")
                    LabeledContent("Account", value: user.accountType.rawValue)
                    if let company = user.companyName {
                        LabeledContent("Company", value: company)
                    }
                    if let category = user.salesCategory {
                        LabeledContent("Sales Team", value: category.rawValue)
                    }
                }
            }

            Section("Sales Vertical") {
                NavigationLink {
                    SalesTeamSetupView(isChangingCategory: true)
                } label: {
                    Label("Change Sales Team Category", systemImage: "building.2.fill")
                }
            }

            Section("API Configuration") {
                HStack {
                    Text("Supabase")
                    Spacer()
                    Text(AppConfig.isSupabaseConfigured ? "Connected" : "Demo Mode")
                        .foregroundStyle(AppConfig.isSupabaseConfigured ? AppTheme.successGreen : AppTheme.textMuted)
                }
                HStack {
                    Text("AI Backend")
                    Spacer()
                    Text(aiBackendStatus)
                        .foregroundStyle(AppConfig.isAIConfigured ? AppTheme.successGreen : AppTheme.textMuted)
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("App", value: "Sales Coach")
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
