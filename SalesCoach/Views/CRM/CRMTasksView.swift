import SwiftUI

struct CRMTasksView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var overdue: [Lead] { appState.crm.overdueFollowUps() }
    private var today: [Lead] { appState.crm.followUpsToday() }
    private var upcoming: [Lead] {
        appState.crm.upcomingFollowUps(withinDays: 7)
            .filter { !$0.isFollowUpToday && !$0.isFollowUpOverdue }
    }
    private var hotLeads: [Lead] { appState.crm.hotLeads() }

    private var stale: [Lead] { appState.crm.staleLeads() }
    private var overdueTasks: [CRMTask] { appState.crm.overdueTasks() }
    private var todayTasks: [CRMTask] { appState.crm.tasksDueToday() }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                summaryStrip

                if !overdueTasks.isEmpty || !todayTasks.isEmpty {
                    crmTaskSection
                }

                if !overdue.isEmpty {
                    taskSection(title: "Overdue", subtitle: "Needs immediate action", icon: "exclamationmark.triangle.fill", color: AppTheme.dangerRed, leads: overdue)
                }

                if !today.isEmpty {
                    taskSection(title: "Due Today", subtitle: "Follow up before end of day", icon: "calendar.badge.clock", color: AppTheme.warningOrange, leads: today)
                }

                if !hotLeads.isEmpty {
                    taskSection(title: "Hot Leads", subtitle: "High-priority active deals", icon: "flame.fill", color: AppTheme.dangerRed, leads: hotLeads)
                }

                if !stale.isEmpty {
                    taskSection(title: "Going Cold", subtitle: "No contact in 14+ days", icon: "thermometer.snowflake", color: AppTheme.electricBlueBright, leads: stale)
                }

                if !upcoming.isEmpty {
                    taskSection(title: "This Week", subtitle: "Upcoming follow-ups", icon: "calendar", color: AppTheme.electricBlueBright, leads: upcoming)
                }

                if overdue.isEmpty && today.isEmpty && upcoming.isEmpty && hotLeads.isEmpty && stale.isEmpty && overdueTasks.isEmpty && todayTasks.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "You're caught up",
                        message: "No overdue follow-ups. Add next steps to your clients to stay on top of deals."
                    )
                    .padding(.top, 24)
                }
            }
            .padding()
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 10) {
            TaskStatChip(label: "Overdue", value: "\(overdue.count)", color: AppTheme.dangerRed)
            TaskStatChip(label: "Today", value: "\(today.count)", color: AppTheme.warningOrange)
            TaskStatChip(label: "Cold", value: "\(stale.count)", color: AppTheme.electricBlueBright)
            TaskStatChip(label: "Hot", value: "\(hotLeads.count)", color: AppTheme.successGreen)
        }
    }

    private var crmTaskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .foregroundStyle(AppTheme.tealGreen)
                Text("Deal Tasks")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            }

            ForEach(overdueTasks + todayTasks) { task in
                if let lead = appState.crm.leads.first(where: { $0.id == task.leadId }) {
                    NavigationLink {
                        LeadDetailView(lead: lead)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                Text(lead.company.isEmpty ? lead.name : lead.company)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            }
                            Spacer()
                            Text(task.dueDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2.bold())
                                .foregroundStyle(task.isOverdue ? AppTheme.dangerRed : AppTheme.warningOrange)
                        }
                        .padding(12)
                        .background(AppTheme.elevatedBackground(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func taskSection(title: String, subtitle: String, icon: String, color: Color, leads: [Lead]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
                Spacer()
                Text("\(leads.count)")
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.15))
                    .clipShape(Capsule())
            }

            ForEach(leads) { lead in
                NavigationLink {
                    LeadDetailView(lead: lead)
                } label: {
                    CRMTaskRow(lead: lead, accent: color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct TaskStatChip: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CRMTaskRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let lead: Lead
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            DealHealthRing(score: lead.dealHealthScore, size: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(lead.company.isEmpty ? lead.name : lead.company)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                Text(lead.displayAIAction)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)
                HStack(spacing: 8) {
                    PriorityBadge(priority: lead.priority)
                    StageBadge(stage: lead.dealStage)
                }
            }

            Spacer()

            if let date = lead.nextFollowUpDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2.bold())
                        .foregroundStyle(lead.isFollowUpOverdue ? AppTheme.dangerRed : accent)
                    Text("$\(Int(lead.dealValue))")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.successGreen)
                }
            }
        }
        .padding(12)
        .background(AppTheme.elevatedBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PriorityBadge: View {
    let priority: LeadPriority

    var body: some View {
        Label(priority.rawValue, systemImage: priority.icon)
            .font(.caption2.bold())
            .foregroundStyle(priority.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(priority.color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct DealHealthRing: View {
    let score: Int
    var size: CGFloat = 48

    private var color: Color {
        switch score {
        case 75...: AppTheme.successGreen
        case 50..<75: AppTheme.warningOrange
        default: AppTheme.dangerRed
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.caption2.bold())
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}

struct CRMQuickActionsBar: View {
    let lead: Lead
    var onCall: (() -> Void)? = nil
    var onEmail: (() -> Void)? = nil
    var onLogCall: () -> Void
    var onLogEmail: () -> Void
    var onScheduleFollowUp: () -> Void
    var onGenerateFollowUp: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                QuickActionButton(title: "Call", icon: "phone.fill", color: AppTheme.successGreen) {
                    onCall?() ?? onLogCall()
                }
                QuickActionButton(title: "Email", icon: "envelope.fill", color: AppTheme.electricBlueBright) {
                    onEmail?() ?? onLogEmail()
                }
                QuickActionButton(title: "Schedule", icon: "calendar.badge.plus", color: AppTheme.warningOrange, action: onScheduleFollowUp)
                QuickActionButton(title: "AI Draft", icon: "sparkles", color: AppTheme.tealGreen, action: onGenerateFollowUp)
            }

            HStack(spacing: 10) {
                if !lead.phone.isEmpty,
                   let url = URL(string: "tel://\(lead.phone.filter { $0.isNumber || $0 == "+" })") {
                    Link(destination: url) {
                        Label("Dial", systemImage: "phone.connection")
                            .font(.caption2.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundStyle(AppTheme.successGreen)
                            .background(AppTheme.successGreen.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                if !lead.email.isEmpty, let url = URL(string: "mailto:\(lead.email)") {
                    Link(destination: url) {
                        Label("Mail", systemImage: "envelope")
                            .font(.caption2.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundStyle(AppTheme.electricBlueBright)
                            .background(AppTheme.electricBlueBright.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.caption2.bold())
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
