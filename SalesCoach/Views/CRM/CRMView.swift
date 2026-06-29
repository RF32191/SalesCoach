import SwiftUI

struct CRMView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddLead = false
    @State private var searchText = ""
    @State private var filterStage: DealStage?
    @State private var viewMode: CRMViewMode = .list

    enum CRMViewMode: String, CaseIterable {
        case list = "List"
        case map = "Map"
    }

    var filteredLeads: [Lead] {
        appState.crm.leads.filter { lead in
            let matchesSearch = searchText.isEmpty ||
                lead.name.localizedCaseInsensitiveContains(searchText) ||
                lead.company.localizedCaseInsensitiveContains(searchText)
            let matchesStage = filterStage == nil || lead.dealStage == filterStage
            return matchesSearch && matchesStage
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                pipelineSummary

                Picker("View", selection: $viewMode) {
                    ForEach(CRMViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                if viewMode == .map {
                    CRMMapView()
                        .padding(.horizontal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            stageFilter

                            ForEach(filteredLeads) { lead in
                                NavigationLink {
                                    LeadDetailView(lead: lead)
                                } label: {
                                    LeadRow(lead: lead)
                                }
                                .buttonStyle(.plain)
                            }

                            if filteredLeads.isEmpty {
                                EmptyStateView(
                                    icon: "person.crop.rectangle.stack",
                                    title: "No leads found",
                                    message: "Add your first lead to start managing your pipeline."
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .appBackground()
            .navigationTitle("CRM")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search leads")
            .toolbar {
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
    }

    private var pipelineSummary: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Pipeline Value")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text("$\(Int(appState.crm.totalPipelineValue()))")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.successGreen)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Pinned Locations")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text("\(appState.crm.pinnedLeadCount())")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.tealGreen)
            }
        }
        .padding()
        .background(AppTheme.navyElevated)
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
}

struct LeadRow: View {
    let lead: Lead

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(lead.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    if lead.location.hasCoordinates {
                        Image(systemName: lead.location.pinReminderEnabled ? "bell.badge.fill" : "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(lead.location.pinReminderEnabled ? AppTheme.tealGreen : AppTheme.electricBlueBright)
                    }
                }
                Text(lead.company)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                if !lead.location.displayAddress.isEmpty {
                    Text(lead.location.displayAddress)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(lead.dealValue))")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.successGreen)
                StageBadge(stage: lead.dealStage)
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
            .foregroundStyle(AppTheme.electricBlue)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppTheme.electricBlue.opacity(0.15))
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
