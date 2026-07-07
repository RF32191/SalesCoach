import SwiftUI

struct RevenueOSDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCustomize = false
    @State private var showAddClient = false

    private var userId: String { appState.auth.currentUser?.id ?? "" }
    private var metrics: RevenueOSMetrics { appState.revenueOS.metrics(appState: appState, userId: userId) }
    private var recommendations: [AIRecommendation] {
        AIRecommendationEngine.recommendations(
            leads: appState.crm.leads,
            overdueFollowUps: appState.crm.overdueFollowUps(),
            followUpsToday: appState.crm.followUpsToday(),
            hotLeads: appState.crm.hotLeads(),
            overdueTasks: appState.crm.overdueTasks().count,
            roleplayCount: appState.training.completedCount(for: userId),
            averageScore: appState.training.averageScore(for: userId),
            pipelineValue: metrics.pipelineValue
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                heroHeader
                ForEach(appState.revenueOS.layout.enabledWidgets) { widget in
                    widgetView(for: widget)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showCustomize) {
            DashboardCustomizeView()
        }
        .sheet(isPresented: $showAddClient) {
            AddLeadView()
        }
    }

    private var heroHeader: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                AppLogo(size: 52, showGlow: true, cornerRadius: 12)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sales Coach AI")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.electricBlueBright)
                    Text(appState.auth.currentUser?.fullName ?? "Sales Rep")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    Text("AI Revenue Operating System")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
                Spacer()
                AIStatusBadge()
            }

            HStack(spacing: 10) {
                Button {
                    showCustomize = true
                } label: {
                    Label("Customize", systemImage: "slider.horizontal.3")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.navyCard.opacity(0.8))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PlatformRootView()
                } label: {
                    Label("Platform", systemImage: "square.grid.3x3.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.tealGreen.opacity(0.15))
                        .foregroundStyle(AppTheme.tealGreen)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func widgetView(for widget: DashboardWidgetKind) -> some View {
        switch widget {
        case .heroMetrics:
            heroMetricsWidget
        case .aiRecommendations:
            AIRecommendationsCard(recommendations: recommendations)
        case .todaysPriorities:
            todaysPrioritiesWidget
        case .revenueMetrics:
            revenueMetricsWidget
        case .pipelineForecast:
            pipelineForecastWidget
        case .quotaProgress:
            quotaWidget
        case .hotOpportunities:
            leadListWidget(title: "Hot Opportunities", leads: appState.crm.hotLeads(), empty: "No hot deals — mark priority clients as Hot.")
        case .dealsAtRisk:
            leadListWidget(title: "Deals at Risk", leads: atRiskLeads, empty: "No at-risk deals. Keep momentum going.", accent: AppTheme.dangerRed)
        case .newLeads:
            leadListWidget(title: "New Leads", leads: newLeads, empty: "Add prospects to start building pipeline.")
        case .tasksAndFollowUps:
            tasksWidget
        case .performanceStats:
            performanceWidget
        case .customerHealth:
            customerHealthWidget
        case .recentActivity:
            recentActivityWidget
        case .leaderboard:
            NavigationLink {
                LeaderboardView()
            } label: {
                FeatureCard(title: "Leaderboard", subtitle: "Team rankings and wins", icon: "trophy.fill", accentColor: AppTheme.warningOrange)
            }
            .buttonStyle(.plain)
        case .repDNA:
            repDNAWidget
        case .gamification:
            GamificationBadgeView()
        case .quickAccess:
            quickAccessWidget
        case .dailyMotivation:
            DailyMotivationCard(message: AIRecommendationEngine.dailyMotivation(for: appState.auth.currentUser?.salesCategory))
        }
    }

    private var heroMetricsWidget: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            MetricTile(label: "Revenue Today", value: formatCurrency(metrics.revenueToday), icon: "sun.max.fill", color: AppTheme.warningOrange)
            MetricTile(label: "Pipeline", value: formatShortCurrency(metrics.pipelineValue), icon: "chart.bar.fill", color: AppTheme.successGreen)
            MetricTile(label: "Forecast", value: formatShortCurrency(metrics.weightedForecast), icon: "scope", color: AppTheme.electricBlueBright)
            MetricTile(label: "Win Rate", value: "\(Int(metrics.winRate))%", icon: "trophy.fill", color: AppTheme.tealGreen)
        }
    }

    private var todaysPrioritiesWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today's Priorities")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricTile(label: "Meetings", value: "\(metrics.meetingsToday)", icon: "calendar", color: AppTheme.electricBlueBright)
                MetricTile(label: "Follow-Ups", value: "\(metrics.followUpsToday)", icon: "arrow.clockwise", color: AppTheme.tealGreen)
                MetricTile(label: "Missed", value: "\(metrics.missedFollowUps)", icon: "exclamationmark.circle", color: AppTheme.dangerRed)
                MetricTile(label: "Tasks Due", value: "\(metrics.tasksDueToday)", icon: "checklist", color: AppTheme.warningOrange)
            }
        }
    }

    private var revenueMetricsWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Revenue")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricTile(label: "Today", value: formatCurrency(metrics.revenueToday), icon: "sun.max", color: AppTheme.warningOrange, compact: true)
                MetricTile(label: "Month", value: formatShortCurrency(metrics.revenueMonth), icon: "calendar", color: AppTheme.tealGreen, compact: true)
                MetricTile(label: "Year", value: formatShortCurrency(metrics.revenueYear), icon: "chart.line.uptrend.xyaxis", color: AppTheme.successGreen, compact: true)
            }
        }
    }

    private var pipelineForecastWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Pipeline & Forecast")
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active deals").font(.caption).foregroundStyle(AppTheme.textMuted)
                    Text("\(metrics.activeDeals)").font(.title2.bold()).foregroundStyle(AppTheme.primaryText(for: colorScheme))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Weighted forecast").font(.caption).foregroundStyle(AppTheme.textMuted)
                    Text(formatShortCurrency(metrics.weightedForecast)).font(.title3.bold()).foregroundStyle(AppTheme.electricBlueBright)
                }
            }
            .cardStyle()
        }
    }

    private var quotaWidget: some View {
        NavigationLink {
            CommissionDashboardView()
        } label: {
            QuotaRingView(
                progress: metrics.quotaProgress,
                revenue: metrics.quotaRevenue,
                target: metrics.quotaTarget
            )
        }
        .buttonStyle(.plain)
    }

    private var tasksWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Tasks & Follow-Ups")
            HStack(spacing: 16) {
                taskStat("Overdue Tasks", metrics.tasksOverdue, AppTheme.dangerRed)
                taskStat("Due Today", metrics.tasksDueToday, AppTheme.warningOrange)
                taskStat("Missed Follow-Ups", metrics.missedFollowUps, AppTheme.dangerRed)
            }
            .cardStyle()
            NavigationLink {
                CRMView(initialViewMode: .tasks)
            } label: {
                Text("Open task board")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.electricBlueBright)
            }
            .buttonStyle(.plain)
        }
    }

    private var performanceWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Performance")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricTile(label: "Conversion", value: "\(Int(metrics.conversionRate))%", icon: "arrow.triangle.merge", color: AppTheme.tealGreen, compact: true)
                MetricTile(label: "Avg Deal", value: formatShortCurrency(metrics.avgDealSize), icon: "dollarsign", color: AppTheme.successGreen, compact: true)
                MetricTile(label: "Avg Cycle", value: "\(metrics.avgSalesCycleDays)d", icon: "clock", color: AppTheme.electricBlueBright, compact: true)
                MetricTile(label: "Roleplay Avg", value: "\(appState.training.averageScore(for: userId))", icon: "mic.fill", color: AppTheme.warningOrange, compact: true)
            }
        }
    }

    private var customerHealthWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Customer Health")
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average score").font(.caption).foregroundStyle(AppTheme.textMuted)
                    Text("\(metrics.avgHealthScore)/100").font(.title2.bold()).foregroundStyle(healthColor(metrics.avgHealthScore))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("At risk").font(.caption).foregroundStyle(AppTheme.textMuted)
                    Text("\(metrics.atRiskHealthCount)").font(.title2.bold()).foregroundStyle(AppTheme.dangerRed)
                }
            }
            .cardStyle()
        }
    }

    private var recentActivityWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Activity")
            ForEach(appState.crm.recentCommunicationActivities(limit: 5)) { item in
                if let lead = appState.crm.leads.first(where: { $0.id == item.leadId }) {
                    NavigationLink {
                        LeadDetailView(lead: lead)
                    } label: {
                        ActivityInboxRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            if appState.crm.recentCommunicationActivities(limit: 1).isEmpty {
                Text("Log calls and emails from client records to populate activity.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                    .cardStyle()
            }
        }
    }

    private var repDNAWidget: some View {
        let profile = RepDNAService.shared.profile(
            userId: userId,
            training: appState.training,
            crm: appState.crm,
            gamification: appState.gamification
        )
        return NavigationLink {
            RepDNAView()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Rep DNA")
                Text(profile.headline).font(.subheadline.bold())
                Text("Focus: \(profile.weakestSkill) · \(profile.weeklyChallenge.progressText)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var quickAccessWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Access")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(PlatformDestination.quickAccess) { module in
                    NavigationLink {
                        PlatformRouter.view(for: module)
                            .navigationTitle(module.rawValue)
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        CompactModuleButton(title: moduleShortTitle(module), icon: module.icon, color: quickAccessColor(for: module))
                    }
                    .buttonStyle(.plain)
                }
            }
            Button {
                showAddClient = true
            } label: {
                Label("Add Client", systemImage: "person.badge.plus")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(AppTheme.electricBlueBright)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func moduleShortTitle(_ module: PlatformDestination) -> String {
        switch module {
        case .crm: "CRM"
        case .aiCoach: "Coach"
        case .liveCopilot: "Co-Pilot"
        case .dealHealth: "Health"
        case .proposals: "Quotes"
        case .office: "Office"
        default: module.rawValue.components(separatedBy: " ").first ?? module.rawValue
        }
    }

    private func quickAccessColor(for module: PlatformDestination) -> Color {
        switch module.category {
        case .sell: AppTheme.electricBlueBright
        case .coach: AppTheme.tealGreen
        case .intelligence: AppTheme.warningOrange
        case .enablement: AppTheme.electricBlue
        case .operate: AppTheme.successGreen
        default: AppTheme.dangerRed
        }
    }

    private func leadListWidget(title: String, leads: [Lead], empty: String, accent: Color = AppTheme.warningOrange) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title)
            if leads.isEmpty {
                Text(empty).font(.caption).foregroundStyle(AppTheme.textMuted).cardStyle()
            } else {
                ForEach(Array(leads.prefix(3))) { lead in
                    NavigationLink {
                        LeadDetailView(lead: lead)
                    } label: {
                        HStack {
                            Circle().fill(accent).frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lead.company.isEmpty ? lead.name : lead.company).font(.subheadline.bold())
                                Text(formatShortCurrency(lead.dealValue)).font(.caption).foregroundStyle(AppTheme.textMuted)
                            }
                            Spacer()
                            Text("\(lead.dealHealthScore)").font(.caption.bold()).foregroundStyle(lead.dealHealthColor)
                        }
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func taskStat(_ label: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(AppTheme.textMuted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var atRiskLeads: [Lead] {
        let stale = Set(appState.crm.staleLeads().map(\.id))
        return appState.crm.leads.filter { $0.dealStage.isActivePipeline && ($0.dealHealthScore < 50 || stale.contains($0.id)) }
    }

    private var newLeads: [Lead] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return appState.crm.leads.filter { $0.createdAt >= weekAgo }.sorted { $0.createdAt > $1.createdAt }
    }

    private func healthColor(_ score: Int) -> Color {
        score >= 75 ? AppTheme.successGreen : score >= 50 ? AppTheme.warningOrange : AppTheme.dangerRed
    }

    private func formatCurrency(_ value: Double) -> String {
        value >= 1000 ? formatShortCurrency(value) : String(format: "$%.0f", value)
    }
}

private struct MetricTile: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let value: String
    let icon: String
    let color: Color
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            Image(systemName: icon).font(.caption.bold()).foregroundStyle(color)
            Text(value)
                .font(compact ? .subheadline.bold() : .headline.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 10 : 12)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1)
        }
    }
}

private func formatShortCurrency(_ value: Double) -> String {
    if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
    if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
    return String(format: "$%.0f", value)
}
