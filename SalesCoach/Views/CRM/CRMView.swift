import SwiftUI

struct CRMView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAddLead = false
    @State private var searchText = ""
    @State private var filterStage: DealStage?
    @State private var listFilter: CRMListFilter = .all
    @State private var sortOption: LeadSortOption = .recentlyUpdated
    @State private var viewMode: CRMViewMode

    init(initialViewMode: CRMViewMode = .dashboard) {
        _viewMode = State(initialValue: initialViewMode)
    }

    enum CRMViewMode: String, CaseIterable {
        case dashboard = "Dashboard"
        case pipeline = "Pipeline"
        case tasks = "Tasks"
        case list = "List"
        case companies = "Companies"
        case map = "Map"
    }

    var filteredLeads: [Lead] {
        appState.crm.filteredLeads(
            search: searchText,
            stage: filterStage,
            listFilter: listFilter,
            sort: sortOption
        )
    }

    private var snapshot: CRMSnapshot { appState.crm.snapshot() }

    var body: some View {
        VStack(spacing: 0) {
            crmHeader

            Picker("View", selection: $viewMode) {
                ForEach(CRMViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            switch viewMode {
            case .dashboard:
                CRMDashboardView()
            case .pipeline:
                CRMPipelineBoardView()
            case .tasks:
                CRMTasksView()
            case .map:
                VStack(spacing: 12) {
                    NavigationLink {
                        CompanyDiscoveryView()
                    } label: {
                        FeatureCard(
                            title: "Find New Companies",
                            subtitle: "Search by category and geo-lock your location",
                            icon: "location.magnifyingglass",
                            accentColor: AppTheme.tealGreen
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    CRMMapView()
                        .padding(.horizontal)
                }
            case .list:
                listContent
            case .companies:
                CRMCompaniesView()
            }
        }
        .appBackground()
        .navigationTitle("CRM")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search clients")
        .toolbar {
            ToolbarItem(placement: .platformTrailing) {
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(LeadSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .foregroundStyle(AppTheme.electricBlue)
                }
            }
            ToolbarItem(placement: .platformTrailing) {
                Button { showAddLead = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppTheme.electricBlue)
                }
            }
        }
        .sheet(isPresented: $showAddLead) {
            AddLeadView()
        }
    }

    private var crmHeader: some View {
        VStack(spacing: 12) {
            CRMGradientHeader(
                title: "Pipeline Overview",
                subtitle: "\(snapshot.activeDeals) active deals · \(snapshot.totalClients) total clients",
                icon: "chart.bar.doc.horizontal.fill",
                accent: AppTheme.successGreen
            )
            .padding(.horizontal)

            HStack(spacing: 8) {
                CRMHeaderPill(label: "Pipeline", value: formatCurrency(snapshot.pipelineValue), color: AppTheme.successGreen)
                CRMHeaderPill(label: "Won", value: formatCurrency(snapshot.wonRevenue), color: AppTheme.tealGreen)
                CRMHeaderPill(label: "Win Rate", value: "\(Int(snapshot.winRate))%", color: AppTheme.warningOrange)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var listContent: some View {
        List {
            Section {
                listFilterChips
                stageFilter
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            ForEach(filteredLeads) { lead in
                NavigationLink {
                    LeadDetailView(lead: lead)
                } label: {
                    LeadRow(lead: lead)
                }
                .listRowBackground(AppTheme.navyCard.opacity(0.35))
                .swipeActions(edge: .leading) {
                    Button {
                        appState.crm.logContact(for: lead.id, type: .call, summary: "Quick call logged")
                    } label: {
                        Label("Call", systemImage: "phone.fill")
                    }
                    .tint(AppTheme.successGreen)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        appState.crm.toggleFavorite(for: lead.id)
                    } label: {
                        Label(lead.isFavorite ? "Unstar" : "Star", systemImage: lead.isFavorite ? "star.slash" : "star.fill")
                    }
                    .tint(AppTheme.warningOrange)

                    Button {
                        appState.crm.moveLead(lead.id, to: .contacted)
                    } label: {
                        Label("Contacted", systemImage: "checkmark")
                    }
                    .tint(AppTheme.electricBlueBright)
                }
            }

            if filteredLeads.isEmpty {
                EmptyStateView(
                    icon: "person.crop.rectangle.stack",
                    title: "No clients found",
                    message: "Add your first client or adjust your filters."
                )
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var listFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CRMListFilter.allCases) { filter in
                    FilterChip(title: filter.rawValue, isSelected: listFilter == filter) {
                        listFilter = filter
                    }
                }
            }
        }
    }

    private var stageFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterStage == nil) { filterStage = nil }
                ForEach(DealStage.allCases) { stage in
                    FilterChip(title: stage.rawValue, isSelected: filterStage == stage) {
                        filterStage = stage
                    }
                }
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return "$\(Int(value))"
    }
}

struct CRMHeaderPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct LeadRow: View {
    let lead: Lead

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(lead.dealStage.pipelineColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(String(lead.name.prefix(1)).uppercased())
                    .font(.headline.bold())
                    .foregroundStyle(lead.dealStage.pipelineColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(lead.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    if lead.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.warningOrange)
                    }
                    PriorityBadge(priority: lead.priority)
                    if lead.isFollowUpOverdue {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.dangerRed)
                    }
                    if lead.location.hasCoordinates {
                        Image(systemName: lead.location.pinReminderEnabled ? "bell.badge.fill" : "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(lead.location.pinReminderEnabled ? AppTheme.tealGreen : AppTheme.electricBlueBright)
                    }
                }
                Text(lead.company)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                HStack(spacing: 8) {
                    StageBadge(stage: lead.dealStage)
                    if lead.isStale {
                        Label("Cold", systemImage: "thermometer.snowflake")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.dangerRed)
                    }
                    if !lead.leadSource.isEmpty {
                        Text(lead.leadSource)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("$\(Int(lead.dealValue))")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.successGreen)
                Text("\(lead.probabilityOfClosing)%")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.electricBlueBright)
                if let followUp = lead.nextFollowUpDate {
                    Text(followUp.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
        }
        .cardStyle()
    }
}

struct StageBadge: View {
    let stage: DealStage

    var body: some View {
        Text(stage.rawValue)
            .font(.caption2.bold())
            .foregroundStyle(stage.pipelineColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(stage.pipelineColor.opacity(0.15))
            .clipShape(Capsule())
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.electricBlue : AppTheme.navyCard)
                .clipShape(Capsule())
        }
    }
}
