import SwiftUI

struct MoreView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("salescoach_onboarding_complete") private var onboardingComplete = false
    @State private var showOnboardingTour = false

    var body: some View {
        NavigationStack {
            List {
                Section("Help") {
                    NavigationLink {
                        ProductGuideView()
                    } label: {
                        Label("Product Guide", systemImage: "book.fill")
                    }

                    Button {
                        onboardingComplete = false
                        showOnboardingTour = true
                    } label: {
                        Label("Replay App Tour", systemImage: "arrow.counterclockwise")
                    }
                }

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
            .overlay {
                if showOnboardingTour {
                    Color.black.opacity(0.55).ignoresSafeArea()
                    OnboardingTourView(isPresented: $showOnboardingTour)
                }
            }
            .onChange(of: showOnboardingTour) { _, isShowing in
                if !isShowing { onboardingComplete = true }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showClearDataConfirm = false
    @State private var showRemoveExamplesConfirm = false
    @State private var dataMessage: String?

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

            Section("Data") {
                Button {
                    appState.loadExampleData()
                    dataMessage = "Example clients, team members, drills, and playbooks loaded."
                } label: {
                    Label("Load Example Data", systemImage: "tray.and.arrow.down.fill")
                }

                Button {
                    appState.removeExampleData()
                    dataMessage = "Example data removed. Your real data is unchanged."
                } label: {
                    Label("Remove Example Data Only", systemImage: "trash.slash.fill")
                }

                Button(role: .destructive) {
                    showClearDataConfirm = true
                } label: {
                    Label("Clear All Local CRM Data", systemImage: "trash.fill")
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

            Section("Help") {
                NavigationLink {
                    ProductGuideView()
                } label: {
                    Label("Product Guide", systemImage: "book.fill")
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
        .alert("Clear all CRM data?", isPresented: $showClearDataConfirm) {
            Button("Clear Everything", role: .destructive) {
                appState.clearAllLocalCRMData()
                dataMessage = "All clients and tasks removed from this device."
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes all your leads and tasks. Training history and account settings are kept.")
        }
        .alert("Data Updated", isPresented: .constant(dataMessage != nil)) {
            Button("OK") { dataMessage = nil }
        } message: {
            Text(dataMessage ?? "")
        }
    }
}
