import SwiftUI

struct OfficeTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var section: OfficeSection = .accounting

    enum OfficeSection: String, CaseIterable, Identifiable {
        case accounting = "Accounting"
        case calculator = "Commission"
        case complaints = "Complaints"
        case billing = "AI Billing"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .accounting: "dollarsign.circle.fill"
            case .calculator: "function"
            case .complaints: "exclamationmark.bubble.fill"
            case .billing: "creditcard.fill"
            }
        }
    }

    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                officeSectionPicker
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        switch section {
                        case .accounting:
                            AccountingSectionView()
                        case .calculator:
                            CommissionCalculatorView()
                        case .complaints:
                            ComplaintsSectionView()
                        case .billing:
                            AutonomousBillingView()
                        }
                    }
                    .padding()
                }
            }
            .appBackground()
            .navigationTitle("Office")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ScriptMakerView()
                    } label: {
                        Label("Scripts", systemImage: "text.book.closed.fill")
                    }
                }
            }
            .onAppear {
                appState.office.load(for: userId)
                appState.office.syncFromAudit(userId: userId, orders: appState.audit.closedOrders)
                appState.billingAgent.load(for: userId)
            }
        }
    }

    private var officeSectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(OfficeSection.allCases) { tab in
                    CRMViewModeChip(
                        title: tab.rawValue,
                        icon: tab.icon,
                        isSelected: section == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) { section = tab }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }
}

struct AccountingSectionView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddExpense = false
    @State private var expenseAmount = ""
    @State private var expenseNote = ""

    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        VStack(spacing: 16) {
            CRMGradientHeader(
                title: "Sales Accounting",
                subtitle: "Commissions sync from closed deals · track expenses and net income",
                icon: "chart.bar.doc.horizontal.fill",
                accent: AppTheme.successGreen
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                accountingStat("Revenue", appState.office.revenueThisMonth(userId: userId), AppTheme.successGreen)
                accountingStat("Expenses", appState.office.expensesThisMonth(userId: userId), AppTheme.dangerRed)
                accountingStat("Net", appState.office.netThisMonth(userId: userId), AppTheme.tealGreen)
            }

            PrimaryButton(title: "Log Expense", icon: "minus.circle.fill") {
                showAddExpense = true
            }

            NavigationLink {
                CommissionCalculatorView()
            } label: {
                FeatureCard(
                    title: "Commission Calculator",
                    subtitle: "Model payouts, splits, spiffs, and quota",
                    icon: "function",
                    accentColor: AppTheme.tealGreen
                )
            }
            .buttonStyle(.plain)

            SectionHeader(title: "Ledger")
            if appState.office.accountingEntries.isEmpty {
                Text("Closed deals will auto-log commission entries here.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            } else {
                ForEach(appState.office.accountingEntries.prefix(20)) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.type.rawValue).font(.subheadline.bold())
                            Text(entry.note).font(.caption).foregroundStyle(AppTheme.textSecondary).lineLimit(2)
                            Text(entry.loggedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2).foregroundStyle(AppTheme.textMuted)
                        }
                        Spacer()
                        Text(entry.type == .expense || entry.type == .tokenCharge ? "-$\(entry.amount, specifier: "%.2f")" : "$\(entry.amount, specifier: "%.2f")")
                            .font(.subheadline.bold())
                            .foregroundStyle(entry.type == .expense || entry.type == .tokenCharge ? AppTheme.dangerRed : AppTheme.successGreen)
                    }
                    .cardStyle()
                }
            }
        }
        .alert("Log Expense", isPresented: $showAddExpense) {
            TextField("Amount", text: $expenseAmount).keyboardType(.decimalPad)
            TextField("Note", text: $expenseNote)
            Button("Save") {
                if let amount = Double(expenseAmount.filter { $0.isNumber || $0 == "." }), amount > 0 {
                    appState.office.addAccountingEntry(AccountingEntry(
                        userId: userId,
                        type: .expense,
                        amount: amount,
                        note: expenseNote.isEmpty ? "Expense" : expenseNote
                    ))
                }
                expenseAmount = ""
                expenseNote = ""
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func accountingStat(_ label: String, _ value: Double, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text("$\(Int(value))")
                .font(.headline.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ComplaintsSectionView: View {
    @Environment(AppState.self) private var appState
    @State private var showNewComplaint = false
    @State private var clientName = ""
    @State private var company = ""
    @State private var summary = ""
    @State private var details = ""
    @State private var isGenerating = false

    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        VStack(spacing: 16) {
            CRMGradientHeader(
                title: "Client Complaints",
                subtitle: "Track issues, escalate fast, and draft AI-powered responses",
                icon: "exclamationmark.bubble.fill",
                accent: AppTheme.warningOrange
            )

            PrimaryButton(title: "Log Complaint", icon: "plus.circle.fill") {
                showNewComplaint = true
            }

            if appState.office.openComplaints().isEmpty && appState.office.complaints.isEmpty {
                EmptyStateView(
                    icon: "hand.thumbsup.fill",
                    title: "No complaints logged",
                    message: "When a client raises an issue, log it here for tracking and AI response drafts."
                )
            } else {
                ForEach(appState.office.complaints) { complaint in
                    NavigationLink {
                        ComplaintDetailView(complaint: complaint)
                    } label: {
                        complaintRow(complaint)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showNewComplaint) {
            NavigationStack {
                Form {
                    TextField("Client name", text: $clientName)
                    TextField("Company", text: $company)
                    TextField("Summary", text: $summary)
                    TextField("Details", text: $details, axis: .vertical).lineLimit(3...8)
                }
                .navigationTitle("New Complaint")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showNewComplaint = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(isGenerating ? "Saving..." : "Save") {
                            Task { await saveComplaint() }
                        }
                        .disabled(clientName.isEmpty || summary.isEmpty || isGenerating)
                    }
                }
            }
        }
    }

    private func complaintRow(_ complaint: ClientComplaint) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(complaint.clientName).font(.headline)
                Text(complaint.summary).font(.caption).foregroundStyle(AppTheme.textSecondary).lineLimit(2)
                HStack(spacing: 8) {
                    Text(complaint.status.rawValue).font(.caption2.bold()).foregroundStyle(AppTheme.warningOrange)
                    Text(complaint.priority.rawValue).font(.caption2).foregroundStyle(AppTheme.textMuted)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(AppTheme.textMuted)
        }
        .cardStyle()
    }

    private func saveComplaint() async {
        isGenerating = true
        guard appState.tokenBilling.canUseFeature(.complaintResponse, subscription: appState.subscription) else {
            isGenerating = false
            return
        }
        var complaint = ClientComplaint(
            userId: userId,
            clientName: clientName,
            company: company,
            summary: summary,
            details: details
        )
        if AppConfig.isAIConfigured {
            complaint.aiSuggestedResponse = try? await OpenAIService.shared.requestComplaintResponse(complaint: complaint, lead: nil)
            appState.recordTokenCharge(feature: .complaintResponse, tokens: AIBillingFeature.complaintResponse.estimatedTokens)
        }
        appState.office.addComplaint(complaint)
        isGenerating = false
        showNewComplaint = false
        clientName = ""
        company = ""
        summary = ""
        details = ""
    }
}

struct ComplaintDetailView: View {
    @Environment(AppState.self) private var appState
    @State var complaint: ClientComplaint

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(complaint.summary).font(.headline)
                Text(complaint.details.isEmpty ? "No additional details." : complaint.details)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                Picker("Status", selection: $complaint.status) {
                    ForEach(ComplaintStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)

                if let response = complaint.aiSuggestedResponse {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "AI Suggested Response")
                        Text(response).font(.subheadline).cardStyle()
                        ShareLink(item: response) {
                            Label("Share Response", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                PrimaryButton(title: "Mark Resolved", icon: "checkmark.circle.fill") {
                    complaint.status = .resolved
                    appState.office.updateComplaint(complaint)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle(complaint.clientName)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: complaint.status) { _, _ in
            appState.office.updateComplaint(complaint)
        }
    }
}

struct AutonomousBillingView: View {
    @Environment(AppState.self) private var appState
    @State private var isRunning = false

    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        VStack(spacing: 16) {
            CRMGradientHeader(
                title: "AI Billing Agent",
                subtitle: "Autonomous plan optimization, usage alerts, and invoice drafts",
                icon: "sparkles",
                accent: AppTheme.electricBlueBright
            )

            Toggle(isOn: Binding(
                get: { appState.billingAgent.autonomousModeEnabled },
                set: { appState.billingAgent.setAutonomousMode($0, for: userId) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Autonomous Mode").font(.subheadline.bold())
                    Text("Agent can auto-apply safe upgrades when usage patterns warrant it.")
                        .font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
            }
            .tint(AppTheme.tealGreen)
            .cardStyle()

            tokenUsageCard

            HStack(spacing: 10) {
                PrimaryButton(title: isRunning ? "Analyzing..." : "Run Billing Agent", icon: "bolt.fill") {
                    Task {
                        isRunning = true
                        await appState.billingAgent.runAutonomousReview(
                            userId: userId,
                            usage: appState.subscription.usage,
                            training: appState.training,
                            subscription: appState.subscription,
                            tokenBilling: appState.tokenBilling,
                            office: appState.office
                        )
                        isRunning = false
                    }
                }
                .disabled(isRunning)

                NavigationLink {
                    SubscriptionView()
                } label: {
                    Label("Plans", systemImage: "crown.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.warningOrange.opacity(0.15))
                        .foregroundStyle(AppTheme.warningOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            if let report = appState.billingAgent.latestReport {
                VStack(alignment: .leading, spacing: 10) {
                    Text(report.summary).font(.subheadline)
                    Text("Recommended: \(report.recommendedPlan.rawValue) · Est. \(report.monthlyEstimate)/mo")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.tealGreen)
                    Text(report.autonomousNote)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textMuted)
                }
                .cardStyle()
            }

            SectionHeader(title: "Agent Actions")
            if appState.billingAgent.actionLog.isEmpty {
                Text("Run the billing agent to analyze usage and subscription fit.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            } else {
                ForEach(appState.billingAgent.actionLog.prefix(12)) { action in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: action.autoExecuted ? "bolt.circle.fill" : "lightbulb.fill")
                            .foregroundStyle(action.autoExecuted ? AppTheme.successGreen : AppTheme.electricBlueBright)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.title).font(.subheadline.bold())
                            Text(action.detail).font(.caption).foregroundStyle(AppTheme.textSecondary)
                            Text(action.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2).foregroundStyle(AppTheme.textMuted)
                        }
                    }
                    .cardStyle()
                }
            }
        }
    }

    private var tokenUsageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Token-Based Billing")
            HStack {
                Text("Billable tokens (MTD)")
                Spacer()
                Text(appState.tokenBilling.tokensThisMonth(userId: userId).formatted())
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.electricBlueBright)
            }
            .font(.caption)
            HStack {
                Text("AI charges (MTD)")
                Spacer()
                Text("$\(appState.tokenBilling.costThisMonth(userId: userId), specifier: "%.2f")")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.warningOrange)
            }
            .font(.caption)
            if let limit = appState.subscription.usage.tier.monthlyTokenLimit {
                Text("\(appState.subscription.usage.aiTokensUsedThisMonth.formatted()) / \(limit.formatted()) plan tokens used · $\(String(format: "%.3f", TokenBillingRates.costPerThousandTokens))/1K overage rate")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
            }
            if !appState.tokenBilling.charges.isEmpty {
                ForEach(appState.tokenBilling.charges.prefix(5)) { charge in
                    HStack {
                        Text(charge.feature.rawValue).font(.caption2)
                        Spacer()
                        Text("\(charge.billableTokens) tok · $\(charge.dollarCost, specifier: "%.4f")")
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .cardStyle()
    }
}
