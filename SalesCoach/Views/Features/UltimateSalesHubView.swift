import MessageUI
import SwiftUI

struct UltimateSalesHubView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var category: SalesCategory? { appState.auth.currentUser?.salesCategory }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "Ultimate Sales Toolkit",
                    subtitle: "Training, CRM intelligence, field tools, and team command — all connected.",
                    icon: "star.circle.fill",
                    accent: category?.accentColor ?? AppTheme.electricBlueBright
                )

                section("Training ↔ CRM Loop") {
                    hubLink("Skill Gap Dashboard", "See training scores vs pipeline performance", "chart.bar.xaxis", AppTheme.electricBlueBright) { SkillGapDashboardView() }
                    hubLink("Certification Center", "Earn badges from roleplay scores", "rosette", AppTheme.tealGreen) { CertificationCenterView() }
                    hubLink("Battle Mode", "Timed objection rounds", "bolt.fill", AppTheme.warningOrange) { BattleModeView() }
                    hubLink("Call Analysis", "Paste a call transcript for AI scoring", "waveform", AppTheme.successGreen) { CallAnalysisView() }
                }

                section("Field Sales") {
                    hubLink("Route Planner", "Optimized visit order for today", "map.fill", AppTheme.tealGreen) { RoutePlannerView() }
                    hubLink("Script Pack", "Vertical talk tracks for your team", "text.book.closed.fill", category?.accentColor ?? AppTheme.electricBlue) { ScriptPackView() }
                }

                section("CRM Intelligence") {
                    hubLink("HubSpot CRM Hub", "Templates, sequences, merge, sync profile", "h.square.fill", AppTheme.warningOrange) { HubSpotCRMHubView() }
                    hubLink("Commission & Quota", "Track earnings and monthly target", "percent", AppTheme.successGreen) { CommissionDashboardView() }
                    hubLink("Objection Intelligence", "Team objection heatmap + responses", "exclamationmark.bubble.fill", AppTheme.dangerRed) { ObjectionIntelligenceView() }
                    hubLink("Battle Cards", "Competitive talk tracks", "flag.fill", AppTheme.electricBlue) { BattleCardsView() }
                    hubLink("Voice Activity Log", "Speak to log CRM activity", "waveform.circle.fill", AppTheme.tealGreen) { VoiceLogView() }
                    hubLink("Team Win Library", "Learn from rep wins", "books.vertical.fill", AppTheme.successGreen) { TeamWinLibraryView() }
                    hubLink("Revenue Forecast", "Weighted pipeline projections", "chart.line.uptrend.xyaxis", AppTheme.successGreen) { RevenueForecastView() }
                    hubLink("Activity Goals", "Weekly calls, visits, and new leads", "target", AppTheme.warningOrange) { ActivityGoalsView() }
                    hubLink("Import / Export", "CSV backup and bulk lead import", "arrow.up.arrow.down.circle.fill", AppTheme.tealGreen) { CRMDataView() }
                    hubLink("Order Audit Log", "Closed sales and full change history", "list.bullet.rectangle.portrait.fill", AppTheme.successGreen) { OrderAuditView() }
                    hubLink("Proposal Generator", "AI proposals with PDF export", "doc.richtext.fill", AppTheme.electricBlueBright) { ProposalGeneratorView() }
                    hubLink("Business Cards", "Digital card + scan contacts", "person.text.rectangle.fill", AppTheme.electricBlueBright) { BusinessCardsHubView() }
                    hubLink("Automations", "Workflow templates for leads and deals", "arrow.triangle.branch", AppTheme.warningOrange) { AutomationWorkflowsView() }
                }

                section("Team Command") {
                    hubLink("Manager Coaching Loop", "Skill gap → assigned drills", "person.crop.circle.badge.checkmark", AppTheme.tealGreen) { ManagerCoachingLoopView() }
                    hubLink("Manager Report", "AI weekly coaching digest", "doc.text.magnifyingglass", AppTheme.electricBlueBright) { ManagerReportView() }
                    hubLink("Manager Drills", "Assigned training from your manager", "list.bullet.clipboard.fill", AppTheme.dangerRed) { ManagerDrillsView() }
                    hubLink("Team Playbooks", "Shared winning scripts", "books.vertical.fill", AppTheme.electricBlue) { PlaybooksView() }
                    hubLink("Integrations", "HubSpot, Salesforce, Calendar", "link.circle.fill", AppTheme.textMuted) { IntegrationsView() }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Ultimate Toolkit")
        .navigationBarTitleDisplayMode(.large)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title)
            content()
        }
    }

    private func hubLink<D: View>(_ title: String, _ subtitle: String, _ icon: String, _ color: Color, @ViewBuilder destination: () -> D) -> some View {
        NavigationLink { destination() } label: {
            FeatureCard(title: title, subtitle: subtitle, icon: icon, accentColor: color)
        }
        .buttonStyle(.plain)
    }
}

struct PreCallBriefingView: View {
    @Environment(\.colorScheme) private var colorScheme
    let lead: Lead
    let briefing: PreCallBriefing

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Opening Line").font(.caption.bold()).foregroundStyle(AppTheme.textMuted)
            Text(briefing.openingLine).font(.subheadline).foregroundStyle(AppTheme.primaryText(for: colorScheme))

            bulletSection("Key Points", briefing.keyPoints)
            bulletSection("Questions to Ask", briefing.questionsToAsk)
            if !briefing.personalHooks.isEmpty { bulletSection("Personal Hooks", briefing.personalHooks) }

            Text("Close With").font(.caption.bold()).foregroundStyle(AppTheme.textMuted)
            Text(briefing.closeLine).font(.subheadline.bold()).foregroundStyle(AppTheme.tealGreen)
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func bulletSection(_ title: String, _ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.bold()).foregroundStyle(AppTheme.textMuted)
            ForEach(items, id: \.self) { item in
                Label(item, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            }
        }
    }
}

struct SkillGapDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var gap: SkillGapSnapshot {
        CRMEnhancements.skillGap(training: appState.training, crm: appState.crm)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CRMKPICard(title: "Training Score", value: "\(gap.overallTrainingScore)", trend: nil, icon: "mic.fill", color: AppTheme.electricBlueBright)
                    CRMKPICard(title: "Win Rate", value: "\(Int(gap.winRate))%", trend: nil, icon: "trophy.fill", color: AppTheme.successGreen)
                }
                infoCard("Strongest Skill", gap.strongestSkill, AppTheme.successGreen)
                infoCard("Focus Next", gap.weakestSkill, AppTheme.warningOrange)
                ForEach(gap.categoryScores) { cat in
                    HStack {
                        Text(cat.name).font(.subheadline)
                        Spacer()
                        Text("\(cat.score)").font(.headline.bold()).foregroundStyle(AppTheme.electricBlueBright)
                    }
                    .padding(.vertical, 4)
                }
                .cardStyle()
                ForEach(gap.recommendations, id: \.self) { rec in
                    Label(rec, systemImage: "lightbulb.fill").font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                }
                .cardStyle()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Skill Gap")
    }

    private func infoCard(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title).font(.caption.bold()).foregroundStyle(AppTheme.textMuted)
            Spacer()
            Text(value).font(.subheadline.bold()).foregroundStyle(color)
        }
        .cardStyle()
    }
}

struct CertificationCenterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            ForEach(CertificationLevel.allCases) { level in
                HStack {
                    Image(systemName: level.icon).foregroundStyle(AppTheme.electricBlueBright)
                    VStack(alignment: .leading) {
                        Text(level.rawValue).font(.headline)
                        Text("Score \(level.requiredScore)+ on \(level.scenario.rawValue)")
                            .font(.caption).foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    if appState.certifications.earnedLevels.contains(level) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(AppTheme.successGreen)
                    } else {
                        Text("\(appState.certifications.progress(for: level, sessions: appState.training.sessions))%")
                            .font(.caption.bold())
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Certifications")
    }
}

struct BattleModeView: View {
    @State private var round = 1
    @State private var score = 0
    @State private var objection = "Your price is too high."

    var body: some View {
        VStack(spacing: 20) {
            Text("Round \(round)").font(.caption.bold()).foregroundStyle(AppTheme.textMuted)
            Text("Handle this objection:").font(.headline)
            Text(objection).font(.title3.bold()).multilineTextAlignment(.center).padding().cardStyle()
            Text("Score: \(score)").font(.title2.bold()).foregroundStyle(AppTheme.tealGreen)
            PrimaryButton(title: "I handled it well", icon: "checkmark") {
                score += 10
                round += 1
                objection = ["We already have a vendor.", "Not the right time.", "Send me an email."].randomElement()!
                Haptic.success()
            }
            SecondaryButton(title: "Need a better response", icon: "sparkles") {
                score = max(0, score - 5)
                Haptic.warning()
            }
        }
        .padding()
        .appBackground()
        .navigationTitle("Battle Mode")
    }
}

struct CallAnalysisView: View {
    @State private var transcript = ""
    @State private var result: CallAnalysisResult?
    @State private var isAnalyzing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TextField("Paste call transcript...", text: $transcript, axis: .vertical)
                    .lineLimit(5...12)
                    .textFieldStyle(AppTextFieldStyle())
                PrimaryButton(title: isAnalyzing ? "Analyzing..." : "Analyze Call", icon: "waveform") {
                    isAnalyzing = true
                    Task {
                        result = await DealCoachingService.shared.analyzeCallTranscript(transcript)
                        isAnalyzing = false
                    }
                }
                .disabled(transcript.isEmpty || isAnalyzing)
                if let result {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Score: \(result.overallScore)").font(.title2.bold())
                        Text("Talk ratio: \(result.talkRatioPercent)% · Questions: \(result.questionsAsked) · Fillers: \(result.fillerWordCount)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)

                        SectionHeader(title: "Emotional Intelligence")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            EQChip(label: "Confidence", value: result.confidenceScore)
                            EQChip(label: "Empathy", value: result.empathyScore)
                            EQChip(label: "Energy", value: result.energyScore)
                            EQChip(label: "Professionalism", value: result.professionalismScore)
                        }
                        Text("Pacing: \(result.pacingLabel)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.tealGreen)

                        ForEach(result.strengths, id: \.self) { Label($0, systemImage: "plus.circle.fill") }
                        ForEach(result.improvements, id: \.self) { Label($0, systemImage: "arrow.up.circle.fill") }
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Call Analysis")
    }
}

private struct EQChip: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline.bold())
                .foregroundStyle(AppTheme.electricBlueBright)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(AppTheme.navyElevated.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct RoutePlannerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var etaLabels: [String: String] = [:]

    private var stops: [RouteStop] {
        RoutePlannerService.planRoute(from: appState.location.currentCoordinate, leads: appState.crm.leads)
    }

    private var totalPipeline: Double {
        stops.reduce(0) { $0 + $1.lead.dealValue }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                CRMGradientHeader(
                    title: "Today's Field Route",
                    subtitle: "Optimized visit order by priority, follow-ups, and distance",
                    icon: "map.fill",
                    accent: AppTheme.tealGreen
                )

                GlassMapToolbar(items: [
                    (icon: "mappin.and.ellipse", label: "Stops", value: "\(stops.count)", color: AppTheme.tealGreen),
                    (icon: "dollarsign.circle.fill", label: "Pipeline", value: formatCurrency(totalPipeline), color: AppTheme.successGreen),
                    (icon: "car.fill", label: "Mode", value: "Driving", color: AppTheme.electricBlueBright)
                ])

                if !stops.isEmpty {
                    MultiStopRouteButton(
                        stopCount: stops.count,
                        origin: appState.location.currentCoordinate,
                        stops: stops
                    )
                }

                if let hint = appState.auth.currentUser?.salesCategory {
                    HStack(spacing: 10) {
                        Image(systemName: hint.icon)
                            .foregroundStyle(hint.accentColor)
                        Text(CRMEnhancements.businessHoursHint(for: hint))
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(AppTheme.cardBackground(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if stops.isEmpty {
                    EmptyStateView(
                        icon: "map",
                        title: "No routed stops yet",
                        message: "Pin client locations with GPS to build an optimized multi-stop route."
                    )
                } else {
                    ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                        RouteStopCard(
                            stop: stop,
                            etaLabel: etaLabels[stop.id],
                            origin: appState.location.currentCoordinate,
                            isLast: index == stops.count - 1
                        )
                    }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Route Planner")
        .task(id: stops.map(\.id)) {
            etaLabels = await MapDirectionsService.loadETAs(for: stops, from: appState.location.currentCoordinate)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1000 { return String(format: "$%.0fK", value / 1000) }
        return "$\(Int(value))"
    }
}

struct ScriptPackView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            ForEach(appState.auth.currentUser?.salesCategory?.scriptPack ?? SalesCategory.b2bServices.scriptPack, id: \.self) { line in
                Text(line).font(.subheadline)
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Script Pack")
    }
}

struct RevenueForecastView: View {
    @Environment(AppState.self) private var appState

    private var forecast: RevenueForecast { appState.crm.revenueForecast() }

    var body: some View {
        VStack(spacing: 16) {
            CRMKPICard(title: "Expected This Month", value: formatCurrency(forecast.expectedThisMonth), trend: nil, icon: "dollarsign.circle.fill", color: AppTheme.successGreen)
            CRMKPICard(title: "Best Case Pipeline", value: formatCurrency(forecast.bestCase), trend: nil, icon: "chart.bar.fill", color: AppTheme.electricBlueBright)
            CRMKPICard(title: "Closing Soon", value: "\(forecast.dealsClosingSoon) deals", trend: nil, icon: "calendar.badge.clock", color: AppTheme.warningOrange)
        }
        .padding()
        .appBackground()
        .navigationTitle("Forecast")
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1000 { return String(format: "$%.0fK", value / 1000) }
        return "$\(Int(value))"
    }
}

struct ActivityGoalsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 16) {
            goalRing("Calls", appState.teamGoals.goals.callsCompleted, appState.teamGoals.goals.weeklyCalls, AppTheme.successGreen)
            goalRing("Visits", appState.teamGoals.goals.visitsCompleted, appState.teamGoals.goals.weeklyVisits, AppTheme.tealGreen)
            goalRing("New Leads", appState.teamGoals.goals.newLeadsCompleted, appState.teamGoals.goals.weeklyNewLeads, AppTheme.electricBlueBright)
        }
        .padding()
        .appBackground()
        .navigationTitle("Activity Goals")
    }

    private func goalRing(_ title: String, _ done: Int, _ target: Int, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text("\(done)/\(target)").font(.subheadline.bold()).foregroundStyle(color)
            }
            ProgressView(value: Double(done), total: Double(max(target, 1))).tint(color)
        }
        .cardStyle()
    }
}

struct CRMExportView: View {
    @Environment(AppState.self) private var appState
    @State private var exported = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Export \(appState.crm.leads.count) leads to CSV for backup or spreadsheet analysis.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Share CSV Export", icon: "square.and.arrow.up") {
                exported = true
                Haptic.success()
            }
            ShareLink(item: appState.crm.exportCSV()) {
                Label("Open Share Sheet", systemImage: "doc.text")
            }
        }
        .padding()
        .appBackground()
        .navigationTitle("Export CRM")
    }
}

struct ManagerDrillsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            ForEach(appState.teamGoals.drills) { drill in
                NavigationLink {
                    VoiceRoleplayView(scenario: drill.scenario, personality: drill.personality)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(drill.title).font(.headline)
                            Text("Due \(drill.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                        }
                        Spacer()
                        if drill.isCompleted {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.successGreen)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Manager Drills")
    }
}

struct PlaybooksView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List(appState.teamGoals.playbooks) { entry in
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title).font(.headline)
                Text(entry.content).font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Playbooks")
    }
}

struct IntegrationsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        IntegrationsHubView()
            .navigationTitle("Integrations")
    }
}
