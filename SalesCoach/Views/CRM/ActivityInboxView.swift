import SwiftUI

struct ActivityInboxView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var filter: InboxFilter = .all

    enum InboxFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case due = "Due"
        case calls = "Calls"
        case emails = "Emails"

        var id: String { rawValue }
    }

    private var dueLeads: [Lead] {
        let overdue = appState.crm.overdueFollowUps()
        let today = appState.crm.followUpsToday()
        let stale = appState.crm.staleLeads()
        var seen = Set<String>()
        return (overdue + today + stale).filter { seen.insert($0.id).inserted }
    }

    private var recentItems: [CommunicationActivityItem] {
        let items = appState.crm.recentCommunicationActivities(limit: 50)
        switch filter {
        case .all: return items
        case .due: return []
        case .calls: return items.filter { $0.activity.type == .call }
        case .emails: return items.filter { $0.activity.type == .email }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                inboxHeader

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(InboxFilter.allCases) { tab in
                            FilterChip(title: tab.rawValue, isSelected: filter == tab) {
                                filter = tab
                            }
                        }
                    }
                }

                if filter == .due || filter == .all {
                    dueSection
                }

                if filter != .due {
                    recentSection
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
    }

    private var inboxHeader: some View {
        CRMGradientHeader(
            title: "Communication Hub",
            subtitle: "HubSpot-style activity feed — call, email, and follow up from one place.",
            icon: "tray.full.fill",
            accent: AppTheme.electricBlueBright
        )
    }

    private var dueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Due for Contact")
            if dueLeads.isEmpty {
                Text("No overdue follow-ups. You're caught up.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                    .cardStyle()
            } else {
                ForEach(dueLeads.prefix(8)) { lead in
                    ActivityDueCard(lead: lead) {
                        logAndOpenCall(lead)
                    } onEmail: {
                        logAndOpenEmail(lead)
                    }
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Calls & Emails")

            if recentItems.isEmpty {
                EmptyStateView(
                    icon: "phone.connection",
                    title: "No communications yet",
                    message: "Calls and emails you log from client records appear here."
                )
            } else {
                ForEach(recentItems.prefix(20)) { item in
                    if let lead = appState.crm.leads.first(where: { $0.id == item.leadId }) {
                        NavigationLink {
                            LeadDetailView(lead: lead)
                        } label: {
                            ActivityInboxRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func logAndOpenCall(_ lead: Lead) {
        LeadCommunicationService.call(lead: lead) {
            appState.crm.logContact(for: lead.id, type: .call, summary: "Called \(lead.name)")
            Haptic.success()
        }
    }

    private func logAndOpenEmail(_ lead: Lead) {
        LeadCommunicationService.email(lead: lead) {
            appState.crm.logContact(for: lead.id, type: .email, summary: "Emailed \(lead.name)")
            Haptic.success()
        }
    }
}

struct ActivityDueCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let lead: Lead
    let onCall: () -> Void
    let onEmail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lead.company.isEmpty ? lead.name : lead.company)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    Text(lead.displayAIAction)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        .lineLimit(2)
                }
                Spacer()
                if lead.isFollowUpOverdue {
                    Label("Overdue", systemImage: "exclamationmark.circle.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.dangerRed)
                }
            }

            LeadContactLinkRow(
                lead: lead,
                onCall: onCall,
                onEmail: onEmail,
                compact: true
            )

            NavigationLink {
                LeadDetailView(lead: lead)
            } label: {
                Text("View Record")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.electricBlueBright)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.borderColor(for: colorScheme), lineWidth: 1)
        )
    }
}

struct ActivityInboxRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let item: CommunicationActivityItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(rowColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: item.activity.type.icon)
                    .foregroundStyle(rowColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.leadLabel)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                Text(item.activity.summary)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)
            }

            Spacer()

            Text(item.activity.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(12)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var rowColor: Color {
        item.activity.type == .call ? AppTheme.successGreen : AppTheme.electricBlueBright
    }
}

struct CRMRootTabView: View {
    @State private var showAddLead = false

    var body: some View {
        NavigationStack {
            CRMView(initialViewMode: .pipeline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddLead = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppTheme.tealGreen)
                        }
                        .accessibilityLabel("Add Client")
                    }
                }
                .sheet(isPresented: $showAddLead) {
                    AddLeadView()
                }
        }
    }
}
