import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CRMImportView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showImporter = false
    @State private var importResult: CRMImportResult?
    @State private var importError: String?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.tealGreen)
            Text("Import leads from CSV")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Text("Use columns: Name, Company, Phone, Email, Stage, Value, Probability, Priority, Source, Next Follow-Up")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)

            PrimaryButton(title: "Choose CSV File", icon: "doc.badge.plus") {
                showImporter = true
            }

            if let result = importResult {
                VStack(spacing: 8) {
                    Text("Imported \(result.imported) lead\(result.imported == 1 ? "" : "s")")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.successGreen)
                    if result.duplicates > 0 {
                        Text("\(result.duplicates) duplicate\(result.duplicates == 1 ? "" : "s") skipped")
                            .font(.caption)
                            .foregroundStyle(AppTheme.warningOrange)
                    }
                }
                .cardStyle()
            }

            if let importError {
                Text(importError)
                    .font(.caption)
                    .foregroundStyle(AppTheme.dangerRed)
            }
        }
        .padding()
        .appBackground()
        .navigationTitle("Import CRM")
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importError = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Could not access the selected file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                guard let userId = appState.auth.currentUser?.id else { return }
                let outcome = appState.crm.importCSV(text, ownerId: userId)
                importResult = outcome
                if outcome.imported > 0 {
                    appState.gamification.record(.leadAdded, userId: userId)
                    Haptic.success()
                }
                importError = outcome.errors.first
            } catch {
                importError = error.localizedDescription
            }
        }
    }
}

struct CRMDataView: View {
    var body: some View {
        List {
            NavigationLink {
                CRMImportView()
            } label: {
                Label("Import CSV", systemImage: "tray.and.arrow.down.fill")
            }
            NavigationLink {
                CRMExportView()
            } label: {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("CRM Data")
    }
}

struct BusinessCardScanView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showManualAdd = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.electricBlueBright)
            Text("Business Card Scanner")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Text("Point your camera at a business card to capture name, company, phone, and email into a new lead.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)

            Label("Coming in next update — Vision OCR", systemImage: "sparkles")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.warningOrange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.warningOrange.opacity(0.12))
                .clipShape(Capsule())

            PrimaryButton(title: "Add Lead Manually", icon: "person.badge.plus") {
                showManualAdd = true
            }
        }
        .padding()
        .appBackground()
        .navigationTitle("Scan Card")
        .sheet(isPresented: $showManualAdd) {
            AddLeadView()
        }
    }
}

struct AutomationWorkflowsView: View {
    @Environment(\.colorScheme) private var colorScheme

    private let templates: [(String, String, String)] = [
        ("New Lead Created", "Assign rep → Send welcome email → Schedule follow-up", "person.badge.plus"),
        ("Deal Stage Changed", "Notify manager → Generate AI briefing → Create task", "arrow.triangle.branch"),
        ("Follow-Up Overdue", "Send reminder → Draft AI email → Escalate to manager", "clock.badge.exclamationmark"),
        ("Deal Won", "Send thank-you → Create onboarding task → Update forecast", "checkmark.seal.fill")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "Automation Workflows",
                    subtitle: "Visual triggers and actions — preview templates below. Full builder coming soon.",
                    icon: "arrow.triangle.branch",
                    accent: AppTheme.warningOrange
                )

                ForEach(Array(templates.enumerated()), id: \.offset) { _, template in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(template.0, systemImage: template.2)
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        Text(template.1)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        Text("Preview — connect Zapier or native workflows in a future release")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Automations")
    }
}

struct ManagerReportView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var report = ""
    @State private var isLoading = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "AI Manager Report",
                    subtitle: "Weekly coaching digest for your team — pipeline, reps, and opportunities.",
                    icon: "person.3.fill",
                    accent: AppTheme.electricBlueBright
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Team Avg", value: "\(teamAverage)", icon: "star.fill", accentColor: AppTheme.tealGreen)
                    StatCard(title: "Overdue", value: "\(appState.crm.overdueFollowUps().count)", icon: "clock.fill", accentColor: AppTheme.dangerRed)
                    StatCard(title: "Hot Deals", value: "\(appState.crm.hotLeads().count)", icon: "flame.fill", accentColor: AppTheme.warningOrange)
                    StatCard(title: "Pipeline", value: formatShortCurrency(appState.crm.totalPipelineValue()), icon: "chart.bar.fill", accentColor: AppTheme.successGreen)
                }

                PrimaryButton(title: isLoading ? "Generating..." : "Generate Report", icon: "sparkles") {
                    generateReport()
                }
                .disabled(isLoading)

                if !report.isEmpty {
                    Text(report)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Manager Report")
    }

    private var teamAverage: Int {
        guard !appState.team.members.isEmpty else {
            return appState.training.averageScore(for: appState.auth.currentUser?.id ?? "")
        }
        return appState.team.members.reduce(0) { $0 + $1.averageScore } / appState.team.members.count
    }

    private func generateReport() {
        isLoading = true
        let snapshot = appState.crm.snapshot()
        let weaknesses = aggregatedWeaknesses()
        report = """
        Weekly Manager Digest

        Pipeline: \(formatShortCurrency(snapshot.pipelineValue)) across \(snapshot.activeDeals) active deals.
        Win rate: \(Int(snapshot.winRate))% · Overdue follow-ups: \(appState.crm.overdueFollowUps().count).

        Team focus:
        • Push \(appState.crm.hotLeads().count) hot opportunities with same-day next steps.
        • Clear \(appState.crm.overdueFollowUps().count) overdue follow-ups this week.
        • Run roleplay drills on: \(weaknesses.isEmpty ? "objection handling" : weaknesses.joined(separator: ", ")).

        Top performers should share talk tracks in Team Playbooks. Reps below team average need assigned drills in Manager Drills.
        """
        isLoading = false
        Haptic.success()
    }

    private func aggregatedWeaknesses() -> [String] {
        var counts: [String: Int] = [:]
        for session in appState.training.sessions {
            session.scoreReport?.improvements.forEach { item in
                counts[item, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }.prefix(3).map(\.key)
    }
}

struct GamificationBadgeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(AppTheme.brandGradient, lineWidth: 3)
                    .frame(width: 52, height: 52)
                Text("L\(appState.gamification.profile.level)")
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(appState.gamification.profile.levelTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                HStack(spacing: 12) {
                    Label("\(appState.gamification.profile.xp) XP", systemImage: "bolt.fill")
                    Label("\(appState.gamification.profile.dailyStreak)d streak", systemImage: "flame.fill")
                }
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                ProgressView(value: appState.gamification.profile.levelProgress)
                    .tint(AppTheme.tealGreen)
            }
        }
        .cardStyle()
    }
}

private func formatShortCurrency(_ value: Double) -> String {
    if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
    if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
    return String(format: "$%.0f", value)
}

struct OrderAuditView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var segment = 0

    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $segment) {
                Text("Closed Orders").tag(0)
                Text("Audit Log").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if segment == 0 {
                        ordersSection
                    } else {
                        auditSection
                    }
                }
                .padding()
            }
        }
        .appBackground()
        .navigationTitle("Order Audit")
    }

    private var ordersSection: some View {
        Group {
            StatCard(
                title: "Revenue This Month",
                value: formatShortCurrency(appState.audit.revenueThisMonth(for: userId)),
                icon: "dollarsign.circle.fill",
                accentColor: AppTheme.successGreen
            )

            if appState.audit.closedOrders.isEmpty {
                EmptyStateView(
                    icon: "cart.fill",
                    title: "No closed orders yet",
                    message: "Log closed deals in Team Sales Coach or mark deals won in CRM."
                )
            } else {
                ForEach(appState.audit.closedOrders) { order in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(order.clientName).font(.headline).foregroundStyle(AppTheme.primaryText(for: colorScheme))
                            Spacer()
                            Text(formatShortCurrency(order.finalValue))
                                .font(.headline.bold())
                                .foregroundStyle(AppTheme.successGreen)
                        }
                        if !order.company.isEmpty {
                            Text(order.company).font(.caption).foregroundStyle(AppTheme.textSecondary)
                        }
                        HStack {
                            Label(order.closedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                            Spacer()
                            Text(order.source.rawValue).font(.caption2).foregroundStyle(AppTheme.textMuted)
                        }
                        .font(.caption2)
                        if !order.notes.isEmpty {
                            Text(order.notes).font(.caption).foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .cardStyle()
                }
            }
        }
    }

    private var auditSection: some View {
        Group {
            if appState.audit.entries.isEmpty {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "No audit entries",
                    message: "Changes to leads, contacts, and orders appear here automatically."
                )
            } else {
                ForEach(appState.audit.entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(entry.summary).font(.subheadline.bold()).foregroundStyle(AppTheme.primaryText(for: colorScheme))
                            Spacer()
                            Text(entry.source.rawValue).font(.caption2).foregroundStyle(AppTheme.tealGreen)
                        }
                        Text(entry.entityLabel).font(.caption).foregroundStyle(AppTheme.textSecondary)
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2).foregroundStyle(AppTheme.textMuted)
                        if !entry.changes.isEmpty {
                            ForEach(entry.changes) { change in
                                Text("\(change.field): \(change.oldValue) → \(change.newValue)")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.warningOrange)
                            }
                        }
                    }
                    .cardStyle()
                }
            }
        }
    }
}

struct ProposalGeneratorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedLeadId: String = ""
    @State private var proposalText = ""
    @State private var isGenerating = false
    @State private var pdfURL: URL?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "AI Proposal Generator",
                    subtitle: "Professional proposals with pricing, scope, and terms — export to PDF.",
                    icon: "doc.richtext.fill",
                    accent: AppTheme.electricBlueBright
                )

                if !appState.crm.leads.isEmpty {
                    Picker("Client", selection: $selectedLeadId) {
                        Text("Select client").tag("")
                        ForEach(appState.crm.leads) { lead in
                            Text(lead.company.isEmpty ? lead.name : "\(lead.name) — \(lead.company)").tag(lead.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                }

                PrimaryButton(title: isGenerating ? "Generating..." : "Generate Proposal", icon: "sparkles") {
                    generateProposal()
                }
                .disabled(isGenerating || appState.crm.leads.isEmpty)

                if !proposalText.isEmpty {
                    Text(proposalText)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()

                    if let pdfURL {
                        ShareLink(item: pdfURL) {
                            Label("Share PDF Proposal", systemImage: "square.and.arrow.up")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundStyle(.white)
                                .background(AppTheme.tealGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Proposals")
        .onAppear {
            selectedLeadId = appState.crm.leads.first?.id ?? ""
        }
    }

    private func generateProposal() {
        guard let lead = appState.crm.leads.first(where: { $0.id == selectedLeadId }) ?? appState.crm.leads.first else { return }
        isGenerating = true
        Task {
            do {
                proposalText = try await OpenAIService.shared.generateFollowUp(type: .proposalEmail, lead: lead)
                pdfURL = ProposalPDFBuilder.makePDF(title: "Proposal — \(lead.company.isEmpty ? lead.name : lead.company)", body: proposalText)
            } catch {
                proposalText = mockProposal(for: lead)
                pdfURL = ProposalPDFBuilder.makePDF(title: "Proposal — \(lead.company.isEmpty ? lead.name : lead.company)", body: proposalText)
            }
            isGenerating = false
        }
    }

    private func mockProposal(for lead: Lead) -> String {
        """
        PROPOSAL FOR \(lead.company.isEmpty ? lead.name.uppercased() : lead.company.uppercased())

        Prepared for: \(lead.name)
        Deal value: $\(Int(lead.dealValue))
        Stage: \(lead.dealStage.rawValue)

        SCOPE
        • Discovery and implementation planning
        • Dedicated onboarding and training
        • Ongoing success support

        PRICING
        Total investment: $\(Int(lead.dealValue))

        TERMS
        Net 30 · 12-month agreement · Cancel with 30 days notice

        Next step: Schedule contract review this week.
        """
    }
}

enum ProposalPDFBuilder {
    static func makePDF(title: String, body: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SalesCoach-Proposal-\(UUID().uuidString).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 22)]
                let bodyAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
                title.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttrs)
                body.draw(in: CGRect(x: 40, y: 90, width: 532, height: 650), withAttributes: bodyAttrs)
            }
            return url
        } catch {
            return nil
        }
    }
}
