import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAddClient = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    TokenMeterView(
                        used: appState.subscription.usage.aiTokensUsedThisMonth,
                        limit: appState.subscription.usage.tier.monthlyTokenLimit
                    )
                    modulesSection
                    crmSection
                    statsSection
                    recentActivitySection
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Sales Coach")
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
            .sheet(isPresented: $showAddClient) {
                AddLeadView()
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 14) {
            AppLogo(size: 52, showGlow: false, cornerRadius: 12)

            VStack(alignment: .leading, spacing: 4) {
                if let category = appState.auth.currentUser?.salesCategory {
                    Label(category.teamWorkspaceTitle, systemImage: category.icon)
                        .font(.caption.bold())
                        .foregroundStyle(category.accentColor)
                } else {
                    HStack(spacing: 6) {
                        Text("Welcome back,")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        TierCrownIcon(tier: appState.subscription.usage.tier, size: 12)
                    }
                }
                Text(appState.auth.currentUser?.fullName ?? "Sales Rep")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                if let category = appState.auth.currentUser?.salesCategory {
                    Text(category.homeHeadline)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
            }

            Spacer()

            AIStatusBadge()
        }
    }

    private var modulesSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Choose Your Mode")

            NavigationLink {
                AITrainingRootView()
            } label: {
                FeatureCard(
                    title: "AI Training Studio",
                    subtitle: "Voice roleplay, natural AI voices, and live coaching chat",
                    icon: "mic.circle.fill",
                    accentColor: AppTheme.electricBlueBright
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                CRMHubView()
            } label: {
                FeatureCard(
                    title: "Field Sales & CRM",
                    subtitle: "Track clients, map prospects, GPS alerts, and pipeline",
                    icon: "map.fill",
                    accentColor: AppTheme.tealGreen
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                UltimateSalesHubView()
            } label: {
                FeatureCard(
                    title: "Ultimate Sales Toolkit",
                    subtitle: "Route planner, forecasts, certifications, skill gaps, and team drills",
                    icon: "star.circle.fill",
                    accentColor: AppTheme.warningOrange
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var crmSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: userCategory.map { "\($0.rawValue) CRM" } ?? "Client CRM")

            HStack(spacing: 10) {
                Button {
                    showAddClient = true
                } label: {
                    Label("Add \(userCategory?.clientLabel.capitalized ?? "Client")", systemImage: "person.badge.plus")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(userCategory?.accentColor ?? AppTheme.electricBlueBright)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                NavigationLink {
                    if let category = userCategory {
                        CompanyDiscoveryView(initialCategory: category)
                    } else {
                        CRMView(initialViewMode: .map)
                    }
                } label: {
                    Label("Find Nearby", systemImage: "location.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(AppTheme.tealGreen)
                        .background(AppTheme.tealGreen.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            if let category = userCategory {
                NavigationLink {
                    CompanyDiscoveryView(initialCategory: category)
                } label: {
                    FeatureCard(
                        title: "Find \(category.clientLabel.capitalized)",
                        subtitle: category.subtitle,
                        icon: category.icon,
                        accentColor: category.accentColor
                    )
                }
                .buttonStyle(.plain)
            }

            NavigationLink {
                CRMView()
            } label: {
                HStack {
                    Text("View all \(appState.crm.leads.count) \(userCategory?.clientLabel ?? "clients")")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.electricBlueBright)
                }
                .cardStyle()
            }
            .buttonStyle(.plain)

            if appState.crm.leads.isEmpty {
                EmptyStateView(
                    icon: userCategory?.icon ?? "person.crop.rectangle.stack",
                    title: "No \(userCategory?.clientLabel ?? "clients") yet",
                    message: "Add a contact with location and personal notes to get smart proximity briefings."
                )
            } else {
                ForEach(appState.crm.leads.prefix(3)) { lead in
                    NavigationLink {
                        LeadDetailView(lead: lead)
                    } label: {
                        LeadRow(lead: lead)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var userCategory: SalesCategory? {
        appState.auth.currentUser?.salesCategory
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
                title: "Pinned Leads",
                value: "\(appState.crm.pinnedLeadCount())",
                icon: "mappin.and.ellipse",
                accentColor: AppTheme.tealGreen
            )
        }
    }

    private var recentActivitySection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Recent Training")

            if appState.training.sessions.isEmpty {
                EmptyStateView(
                    icon: "mic.slash",
                    title: "No sessions yet",
                    message: "Open AI Training Studio to start your first roleplay."
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

struct HomeCategoryChip: View {
    let category: SalesCategory

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundStyle(category.accentColor)
            Text(category.rawValue)
                .font(.caption2.bold())
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 88)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(AppTheme.navyCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}
