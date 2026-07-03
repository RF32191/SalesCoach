import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAddClient = false

    private var userId: String { appState.auth.currentUser?.id ?? "" }
    private var snapshot: CRMSnapshot { appState.crm.snapshot() }
    private var recommendations: [AIRecommendation] {
        AIRecommendationEngine.recommendations(
            leads: appState.crm.leads,
            overdueFollowUps: appState.crm.overdueFollowUps(),
            followUpsToday: appState.crm.followUpsToday(),
            hotLeads: appState.crm.hotLeads(),
            overdueTasks: appState.crm.overdueTasks().count,
            roleplayCount: appState.training.completedCount(for: userId),
            averageScore: appState.training.averageScore(for: userId),
            pipelineValue: appState.crm.totalPipelineValue()
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    headerSection
                    GamificationBadgeView()
                    DailyMotivationCard(
                        message: AIRecommendationEngine.dailyMotivation(for: userCategory)
                    )
                    todaySection
                    AIRecommendationsCard(recommendations: recommendations)
                    quickAccessSection
                    performanceSection
                    priorityClientsSection
                    recentTrainingSection
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Sales Coach")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.background(for: colorScheme).opacity(0.85), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        ProductGuideView()
                    } label: {
                        Image(systemName: "book.fill")
                            .foregroundStyle(AppTheme.tealGreen)
                    }
                    .accessibilityLabel("Product Guide")
                }
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
                if let category = userCategory {
                    Label(category.teamWorkspaceTitle, systemImage: category.icon)
                        .font(.caption.bold())
                        .foregroundStyle(category.accentColor)
                }
                Text(appState.auth.currentUser?.fullName ?? "Sales Rep")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                Text(userCategory?.homeHeadline ?? "Your AI sales operating system")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }

            Spacer()

            AIStatusBadge()
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today at a Glance")
            TodayGlanceBar(
                followUpsDue: appState.crm.followUpsToday().count + appState.crm.overdueFollowUps().count,
                hotDeals: appState.crm.hotLeads().count,
                pipelineValue: snapshot.pipelineValue,
                winRate: Int(snapshot.winRate),
                roleplayScore: appState.training.averageScore(for: userId),
                revenueThisMonth: appState.audit.revenueThisMonth(for: userId)
            )
        }
    }

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Access")

            HStack(spacing: 10) {
                NavigationLink {
                    AITrainingRootView()
                } label: {
                    CompactModuleButton(title: "AI Training", icon: "mic.fill", color: AppTheme.electricBlueBright)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    CRMHubView()
                } label: {
                    CompactModuleButton(title: "Field CRM", icon: "map.fill", color: AppTheme.tealGreen)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    UltimateSalesHubView()
                } label: {
                    CompactModuleButton(title: "Toolkit", icon: "star.fill", color: AppTheme.warningOrange)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button {
                    showAddClient = true
                } label: {
                    Label("Add Client", systemImage: "person.badge.plus")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(userCategory?.accentColor ?? AppTheme.electricBlueBright)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                NavigationLink {
                    CRMView(initialViewMode: .tasks)
                } label: {
                    Label("Tasks", systemImage: "checklist")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(AppTheme.tealGreen)
                        .background(AppTheme.tealGreen.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Performance")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "Avg Score",
                    value: "\(appState.training.averageScore(for: userId))",
                    icon: "star.fill",
                    accentColor: AppTheme.tealGreen
                )
                StatCard(
                    title: "Roleplays",
                    value: "\(appState.training.completedCount(for: userId))",
                    icon: "mic.fill"
                )
                StatCard(
                    title: "Pipeline",
                    value: formatShortCurrency(snapshot.pipelineValue),
                    icon: "dollarsign.circle.fill",
                    accentColor: AppTheme.successGreen
                )
                StatCard(
                    title: "Win Rate",
                    value: "\(Int(snapshot.winRate))%",
                    icon: "trophy.fill",
                    accentColor: AppTheme.warningOrange
                )
            }
        }
    }

    private var priorityClientsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: userCategory.map { "Priority \($0.clientLabel.capitalized)" } ?? "Priority Clients")

            if appState.crm.leads.isEmpty {
                EmptyStateView(
                    icon: userCategory?.icon ?? "person.crop.rectangle.stack",
                    title: "No clients yet",
                    message: "Add a contact with location and notes to unlock proximity briefings and AI coaching."
                )
            } else {
                ForEach(priorityLeads) { lead in
                    NavigationLink {
                        LeadDetailView(lead: lead)
                    } label: {
                        LeadRow(lead: lead)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    CRMView()
                } label: {
                    HStack {
                        Text("View all \(appState.crm.leads.count) clients")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.electricBlueBright)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recentTrainingSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Recent Training")

            if appState.training.sessions.isEmpty {
                EmptyStateView(
                    icon: "mic.slash",
                    title: "No sessions yet",
                    message: "Open AI Training to start your first roleplay."
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

    private var priorityLeads: [Lead] {
        let hot = appState.crm.hotLeads()
        if !hot.isEmpty { return Array(hot.prefix(3)) }
        return Array(appState.crm.leads.prefix(3))
    }

    private var userCategory: SalesCategory? {
        appState.auth.currentUser?.salesCategory
    }
}

private func formatShortCurrency(_ value: Double) -> String {
    if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
    if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
    return String(format: "$%.0f", value)
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
