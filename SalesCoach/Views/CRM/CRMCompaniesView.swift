import SwiftUI

struct CRMCompaniesView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""

    private var groups: [CompanyGroup] {
        let all = appState.crm.companiesGrouped()
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.company.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            if groups.isEmpty {
                EmptyStateView(
                    icon: "building.2.fill",
                    title: "No companies yet",
                    message: "Add clients with a company name to group accounts and track total pipeline by organization."
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.leads) { lead in
                            NavigationLink {
                                LeadDetailView(lead: lead)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(lead.name)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                        HStack(spacing: 6) {
                                            StageBadge(stage: lead.dealStage)
                                            Text(lead.contactRole.rawValue)
                                                .font(.caption2)
                                                .foregroundStyle(AppTheme.textMuted)
                                        }
                                    }
                                    Spacer()
                                    Text("$\(Int(lead.dealValue))")
                                        .font(.caption.bold())
                                        .foregroundStyle(AppTheme.successGreen)
                                }
                            }
                            .listRowBackground(AppTheme.navyCard.opacity(0.35))
                        }
                    } header: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.company)
                                    .font(.headline)
                                Text("\(group.activeCount) active · \(group.leads.count) contacts")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textMuted)
                            }
                            Spacer()
                            Text(formatCurrency(group.totalValue))
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.successGreen)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .appBackground()
        .searchable(text: $searchText, prompt: "Search companies")
        .navigationTitle("Companies")
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return "$\(Int(value))"
    }
}

struct LeadTagsEditor: View {
    @Binding var tags: [String]
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tags")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text(tag)
                        Button {
                            tags.removeAll { $0 == tag }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                        }
                    }
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.electricBlueBright)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.electricBlueBright.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            HStack {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(AppTextFieldStyle())
                    .onSubmit { addTag() }
                Button("Add") { addTag() }
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .cardStyle()
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        newTag = ""
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

struct DealOutcomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let lead: Lead
    let onWon: (Double?) -> Void
    let onLost: (String) -> Void

    @State private var finalValue = ""
    @State private var lostReason = ""
    @State private var mode: OutcomeMode = .won

    enum OutcomeMode: String, CaseIterable {
        case won = "Won"
        case lost = "Lost"
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Outcome", selection: $mode) {
                    ForEach(OutcomeMode.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                if mode == .won {
                    Section("Final Deal Value") {
                        TextField("Amount", text: $finalValue)
                            .keyboardType(.numberPad)
                        Text("Current: $\(Int(lead.dealValue))")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                } else {
                    Section("Why was this deal lost?") {
                        TextField("Competitor, budget, timing...", text: $lostReason, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .appBackground()
            .navigationTitle("Close Deal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if mode == .won {
                            let value = Double(finalValue).flatMap { $0 > 0 ? $0 : nil }
                            onWon(value)
                        } else {
                            onLost(lostReason)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LeadTasksSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    let leadId: String

    @State private var newTaskTitle = ""
    @State private var newTaskDueDate = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now

    private var leadTasks: [CRMTask] {
        appState.crm.openTasks(for: leadId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tasks")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            HStack {
                TextField("New task...", text: $newTaskTitle)
                    .textFieldStyle(AppTextFieldStyle())
                DatePicker("", selection: $newTaskDueDate, displayedComponents: .date)
                    .labelsHidden()
            }

            SecondaryButton(title: "Add Task", icon: "plus.circle") {
                guard !newTaskTitle.isEmpty else { return }
                appState.crm.addTask(CRMTask(leadId: leadId, title: newTaskTitle, dueDate: newTaskDueDate))
                newTaskTitle = ""
            }

            ForEach(leadTasks) { task in
                HStack(spacing: 10) {
                    Button {
                        appState.crm.completeTask(task.id)
                    } label: {
                        Image(systemName: task.isOverdue ? "exclamationmark.circle" : "circle")
                            .foregroundStyle(task.isOverdue ? AppTheme.dangerRed : AppTheme.electricBlueBright)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        Text(task.dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(task.isOverdue ? AppTheme.dangerRed : AppTheme.textMuted)
                    }
                    Spacer()
                    Button {
                        appState.crm.deleteTask(task.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
            }
        }
        .cardStyle()
    }
}
