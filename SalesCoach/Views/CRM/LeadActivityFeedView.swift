import SwiftUI

struct LeadActivityFeedView: View {
    @Environment(\.colorScheme) private var colorScheme
    let lead: Lead
    @Binding var newActivitySummary: String
    @Binding var newActivityType: LeadActivityType
    var onAddActivity: () -> Void

    @State private var filter: ActivityFeedFilter = .all

    enum ActivityFeedFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case calls = "Calls"
        case emails = "Emails"
        case notes = "Notes"
        case meetings = "Meetings"

        var id: String { rawValue }

        func matches(_ type: LeadActivityType) -> Bool {
            switch self {
            case .all: true
            case .calls: type == .call
            case .emails: type == .email
            case .notes: type == .note || type == .visit
            case .meetings: type == .meeting
            }
        }
    }

    private var filteredActivities: [LeadActivity] {
        lead.activities.filter { filter.matches($0.type) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(filteredActivities.count)")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textMuted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ActivityFeedFilter.allCases) { tab in
                        FilterChip(title: tab.rawValue, isSelected: filter == tab) {
                            filter = tab
                        }
                    }
                }
            }

            Picker("Type", selection: $newActivityType) {
                ForEach(LeadActivityType.allCases) { type in
                    Label(type.rawValue, systemImage: type.icon).tag(type)
                }
            }
            .pickerStyle(.menu)

            TextField("Log activity...", text: $newActivitySummary, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(AppTextFieldStyle())

            SecondaryButton(title: "Add Activity", icon: "plus.circle", action: onAddActivity)

            if filteredActivities.isEmpty {
                Text(emptyMessage)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredActivities.prefix(12).enumerated()), id: \.element.id) { index, activity in
                        ActivityTimelineRow(activity: activity, isLast: index == min(filteredActivities.count, 12) - 1)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var emptyMessage: String {
        switch filter {
        case .all: "No activity logged yet. Call, email, or add a note above."
        case .calls: "No calls logged. Tap Call above or use the phone link."
        case .emails: "No emails logged. Tap Email to open Mail and auto-log."
        case .notes: "No notes or site visits yet."
        case .meetings: "No meetings logged yet."
        }
    }
}

struct ActivityTimelineRow: View {
    let activity: LeadActivity
    var isLast: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(activityColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: activity.type.icon)
                        .font(.caption.bold())
                        .foregroundStyle(activityColor)
                }
                if !isLast {
                    Rectangle()
                        .fill(AppTheme.border)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.type.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(activityColor)
                    Spacer()
                    Text(activity.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textMuted)
                }
                Text(activity.summary)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 12)
        }
    }

    private var activityColor: Color {
        switch activity.type {
        case .call: AppTheme.successGreen
        case .email: AppTheme.electricBlueBright
        case .meeting: AppTheme.warningOrange
        case .visit: AppTheme.tealGreen
        case .note: AppTheme.textSecondary
        }
    }
}
