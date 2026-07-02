import SwiftUI

struct CRMHubView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var snapshot: CRMSnapshot { appState.crm.snapshot() }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                heroSection
                metricsRow
                prospectingSection
                workspaceSection
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Field Sales & CRM")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .onAppear {
            appState.location.requestAuthorization()
        }
    }

    private var heroSection: some View {
        CRMGradientHeader(
            title: appState.auth.currentUser?.salesCategory?.teamWorkspaceTitle ?? "Sales Command Center",
            subtitle: appState.auth.currentUser?.salesCategory.map {
                "Find \($0.clientLabel), track pipeline, and get proximity briefings in the field."
            } ?? "Track clients, trend acquisitions, find companies on the map, and close deals.",
            icon: appState.auth.currentUser?.salesCategory?.icon ?? "briefcase.fill",
            accent: appState.auth.currentUser?.salesCategory?.accentColor ?? AppTheme.electricBlueBright
        )
    }

    private var metricsRow: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            CRMKPICard(title: "Pipeline", value: formatCurrency(snapshot.pipelineValue), trend: nil, icon: "chart.line.uptrend.xyaxis", color: AppTheme.successGreen)
            CRMKPICard(title: "Clients", value: "\(snapshot.totalClients)", trend: snapshot.acquisitionTrend, icon: "person.2.fill", color: AppTheme.electricBlueBright)
            CRMKPICard(title: "Win Rate", value: "\(Int(snapshot.winRate))%", trend: nil, icon: "trophy.fill", color: AppTheme.warningOrange)
            CRMKPICard(title: "New This Month", value: "\(snapshot.acquisitionsThisMonth)", trend: snapshot.acquisitionTrend, icon: "person.badge.plus", color: AppTheme.tealGreen)
        }
    }

    private var prospectingSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: userCategory.map { "Find \($0.clientLabel.capitalized)" } ?? "Find & Add Companies")

            if let category = userCategory {
                NavigationLink {
                    CompanyDiscoveryView(initialCategory: category)
                } label: {
                    FeatureCard(
                        title: "\(category.rawValue) Map Finder",
                        subtitle: "Geo-lock location and discover \(category.clientLabel) near you",
                        icon: "location.magnifyingglass",
                        accentColor: category.accentColor
                    )
                }
                .buttonStyle(.plain)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(category.quickSearchTerms, id: \.self) { term in
                            NavigationLink {
                                CompanyDiscoveryView(initialCategory: category, initialSearch: term)
                            } label: {
                                Text(term)
                                    .font(.caption2.bold())
                                    .foregroundStyle(category.accentColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(category.accentColor.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                NavigationLink {
                    CompanyDiscoveryView()
                } label: {
                    FeatureCard(
                        title: "Company Map Finder",
                        subtitle: "Geo-lock location, pick sales target type, search companies nearby",
                        icon: "location.magnifyingglass",
                        accentColor: AppTheme.tealGreen
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var userCategory: SalesCategory? {
        appState.auth.currentUser?.salesCategory
    }

    private var workspaceSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "CRM Workspace")

            if !appState.crm.overdueFollowUps().isEmpty || !appState.crm.followUpsToday().isEmpty {
                NavigationLink {
                    CRMView(initialViewMode: .tasks)
                } label: {
                    FeatureCard(
                        title: "Follow-Ups Due",
                        subtitle: "\(appState.crm.overdueFollowUps().count) overdue · \(appState.crm.followUpsToday().count) today",
                        icon: "bell.badge.fill",
                        accentColor: AppTheme.dangerRed
                    )
                }
                .buttonStyle(.plain)
            }

            NavigationLink {
                CRMView(initialViewMode: .tasks)
            } label: {
                FeatureCard(title: "Tasks & Follow-Ups", subtitle: "Overdue, today, hot leads, and weekly queue", icon: "checklist", accentColor: AppTheme.warningOrange)
            }
            .buttonStyle(.plain)

            NavigationLink {
                CRMView(initialViewMode: .dashboard)
            } label: {
                FeatureCard(title: "Analytics Dashboard", subtitle: "Sales trends, acquisitions, pipeline health", icon: "chart.xyaxis.line", accentColor: AppTheme.electricBlueBright)
            }
            .buttonStyle(.plain)

            NavigationLink {
                CRMView(initialViewMode: .pipeline)
            } label: {
                FeatureCard(title: "Pipeline Board", subtitle: "Kanban view by deal stage", icon: "rectangle.split.3x1.fill", accentColor: AppTheme.warningOrange)
            }
            .buttonStyle(.plain)

            NavigationLink {
                CRMView(initialViewMode: .list)
            } label: {
                FeatureCard(title: "Client List", subtitle: "\(appState.crm.leads.count) clients with follow-ups", icon: "person.crop.rectangle.stack.fill", accentColor: AppTheme.tealGreen)
            }
            .buttonStyle(.plain)

            NavigationLink {
                CRMView(initialViewMode: .companies)
            } label: {
                FeatureCard(title: "Companies", subtitle: "Group contacts by organization and pipeline value", icon: "building.2.fill", accentColor: AppTheme.electricBlue)
            }
            .buttonStyle(.plain)

            NavigationLink {
                CRMView(initialViewMode: .map)
            } label: {
                FeatureCard(title: "Pinned Client Map", subtitle: "GPS-tracked leads and proximity alerts", icon: "map.fill", accentColor: AppTheme.successGreen)
            }
            .buttonStyle(.plain)

            NavigationLink {
                UltimateSalesHubView()
            } label: {
                FeatureCard(title: "Ultimate Toolkit", subtitle: "Forecast, route planner, export, certifications, and more", icon: "star.circle.fill", accentColor: AppTheme.warningOrange)
            }
            .buttonStyle(.plain)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return "$\(Int(value))"
    }
}

struct SalesCategoryTile: View {
    @Environment(\.colorScheme) private var colorScheme
    let category: SalesCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(category.accentColor)
            Text(category.rawValue)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                .lineLimit(2)
            Text(category.subtitle)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(category.accentColor.opacity(0.25), lineWidth: 1)
        )
    }
}
