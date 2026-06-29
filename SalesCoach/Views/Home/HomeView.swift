import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    statsSection
                    quickActionsSection
                    recentActivitySection
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Dashboard")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.background(for: colorScheme).opacity(0.85), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        CrownButton(tier: appState.subscription.usage.tier)
                    }
                }
            }
            #endif
        }
    }

    private var headerSection: some View {
        HStack(spacing: 14) {
            AppLogo(size: 52, showGlow: false, cornerRadius: 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    TierCrownIcon(tier: appState.subscription.usage.tier, size: 12)
                }
                Text(appState.auth.currentUser?.fullName ?? "Sales Rep")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            }

            Spacer()

            Image(systemName: "bell.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.electricBlueBright)
                .padding(10)
                .background(AppTheme.electricBlue.opacity(0.12))
                .clipShape(Circle())
        }
    }

    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Avg Score",
                value: "\(appState.training.averageScore(for: appState.auth.currentUser?.id ?? ""))",
                icon: "star.fill",
                accentColor: AppTheme.tealGreen
            )
            StatCard(
                title: "Roleplays",
                value: "\(appState.training.completedCount(for: appState.auth.currentUser?.id ?? ""))",
                icon: "mic.fill"
            )
            StatCard(
                title: "Pipeline",
                value: "$\(Int(appState.crm.totalPipelineValue()))",
                icon: "dollarsign.circle.fill",
                accentColor: AppTheme.successGreen
            )
            StatCard(
                title: "Active Leads",
                value: "\(appState.crm.leads.count)",
                icon: "person.2.fill"
            )
        }
    }

    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Quick Actions")

            NavigationLink {
                VoiceRoleplaySetupView()
            } label: {
                FeatureCard(
                    title: "Start Voice Roleplay",
                    subtitle: "Practice with AI customers in real time",
                    icon: "mic.circle.fill"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ChatView()
            } label: {
                FeatureCard(
                    title: "Chat with AI Coach",
                    subtitle: "Get scripts, objection handling, and tips",
                    icon: "bubble.left.and.bubble.right.fill"
                )
            }
            .buttonStyle(.plain)

            if appState.subscription.usage.tier.hasCRM {
                NavigationLink {
                    CRMView()
                } label: {
                    FeatureCard(
                        title: "Manage Leads",
                        subtitle: "\(appState.crm.leads.count) leads in pipeline",
                        icon: "person.crop.rectangle.stack.fill"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Recent Training")

            if appState.training.sessions.isEmpty {
                EmptyStateView(
                    icon: "mic.slash",
                    title: "No sessions yet",
                    message: "Complete a roleplay to see your scores here."
                )
            } else {
                ForEach(appState.training.sessions.prefix(3)) { session in
                    if let report = session.scoreReport {
                        NavigationLink {
                            ScoringReportView(report: report, session: session)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.scenario.rawValue)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                    Text(session.personality.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                }
                                Spacer()
                                Text("\(report.overallScore)")
                                    .font(.title3.bold())
                                    .foregroundStyle(AppTheme.tealGreen)
                            }
                            .cardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
