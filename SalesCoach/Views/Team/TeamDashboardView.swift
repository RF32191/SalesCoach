import SwiftUI

struct TeamDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddRep = false
    @State private var newRepName = ""
    @State private var newRepEmail = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                teamStats
                teamSalesSection
                weaknessesSection
                membersSection
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Team Dashboard")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .platformTrailing) {
                Button {
                    showAddRep = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .alert("Add Sales Rep", isPresented: $showAddRep) {
            TextField("Full Name", text: $newRepName)
            TextField("Email", text: $newRepEmail)
            Button("Add") {
                if let teamId = appState.auth.currentUser?.teamId {
                    appState.team.addMember(teamId: teamId, fullName: newRepName, email: newRepEmail)
                    newRepName = ""
                    newRepEmail = ""
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var teamStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Team Members", value: "\(appState.team.members.count)", icon: "person.3.fill")
            StatCard(
                title: "Team Sales (Month)",
                value: formatTeamCurrency(teamRevenueThisMonth),
                icon: "cart.fill",
                accentColor: AppTheme.successGreen
            )
            StatCard(title: "Total Roleplays", value: "\(totalRoleplays)", icon: "mic.fill")
            StatCard(title: "Active Leads", value: "\(appState.crm.leads.count)", icon: "person.crop.rectangle.stack.fill")
        }
    }

    private var teamSalesSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Team Sales Feed")
            Text("Reps log closed deals in Team Sales Coach — visible here for the whole team.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if appState.teamSales.sales.isEmpty {
                Text("No team sales logged yet. Try: \"Closed $5k with Acme\" in the AI Coach.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(appState.teamSales.sales.prefix(10)) { sale in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sale.repName)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.tealGreen)
                            Text("\(sale.clientName)\(sale.company.isEmpty ? "" : " · \(sale.company)")")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(sale.loggedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        Spacer()
                        Text(formatTeamCurrency(sale.amount))
                            .font(.headline.bold())
                            .foregroundStyle(AppTheme.successGreen)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .cardStyle()
    }

    private var teamRevenueThisMonth: Double {
        guard let teamId = appState.auth.currentUser?.teamId else { return 0 }
        return appState.teamSales.revenueThisMonth(for: teamId)
    }

    private func formatTeamCurrency(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return String(format: "$%.0f", value)
    }

    private var weaknessesSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Most Common Weaknesses")
            let weaknesses = teamWeaknesses
            if weaknesses.isEmpty {
                Text("Complete team roleplays to surface coaching insights here.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(weaknesses, id: \.self) { weakness in
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.warningOrange)
                        Text(weakness)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .cardStyle()
    }

    private var membersSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Sales Reps")

            if appState.team.members.isEmpty {
                Text("Add reps to your team or load example data from Settings.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                ForEach(appState.team.members) { member in
                    TeamMemberRow(member: member)
                }
            }
        }
    }

    private var teamWeaknesses: [String] {
        let memberIds = Set(appState.team.members.map(\.userId))
        let ids = memberIds.isEmpty
            ? Set([appState.auth.currentUser?.id].compactMap { $0 })
            : memberIds
        return appState.team.mostCommonWeaknesses(from: appState.training.sessions, memberIds: ids)
    }

    private var teamAverageScore: Int {
        guard !appState.team.members.isEmpty else { return 0 }
        return appState.team.members.reduce(0) { $0 + $1.averageScore } / appState.team.members.count
    }

    private var totalRoleplays: Int {
        appState.team.members.reduce(0) { $0 + $1.roleplaysCompleted }
    }
}

struct TeamMemberRow: View {
    @Environment(AppState.self) private var appState
    let member: TeamMember
    @State private var showAssign = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.fullName)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(member.email)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(member.averageScore)")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.successGreen)
                    Text("Avg Score")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textMuted)
                }
            }

            HStack(spacing: 16) {
                MiniStat(label: "Roleplays", value: "\(member.roleplaysCompleted)")
                MiniStat(label: "Closing", value: "\(member.closingScore)")
                MiniStat(label: "Improved", value: "+\(member.improvementDelta)")
            }

            if !member.assignedScenarios.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(member.assignedScenarios, id: \.self) { scenario in
                            Text(scenario.rawValue)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.electricBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.electricBlue.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Button("Assign Training") {
                showAssign = true
            }
            .font(.caption.bold())
            .foregroundStyle(AppTheme.electricBlue)
        }
        .cardStyle()
        .confirmationDialog("Assign Scenario", isPresented: $showAssign) {
            ForEach(TrainingScenario.allCases) { scenario in
                Button(scenario.rawValue) {
                    appState.team.assignScenario(to: member.id, scenario: scenario)
                }
            }
        }
    }
}

struct MiniStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
        }
    }
}
