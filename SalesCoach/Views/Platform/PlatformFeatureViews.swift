import SwiftUI

// MARK: - Sell

struct LeadGenerationView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "AI Lead Generation",
                    subtitle: "Discovery, scoring, enrichment, and ICP matching",
                    icon: "sparkle.magnifyingglass",
                    accent: AppTheme.tealGreen
                )
                NavigationLink {
                    CompanyDiscoveryView(initialCategory: appState.auth.currentUser?.salesCategory)
                } label: {
                    FeatureCard(title: "Discover Prospects", subtitle: "Map + category search", icon: "map.fill", accentColor: AppTheme.tealGreen)
                }.buttonStyle(.plain)

                SectionHeader(title: "Lead Scores")
                ForEach(scoredLeads.prefix(8)) { lead in
                    NavigationLink { LeadDetailView(lead: lead) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lead.company.isEmpty ? lead.name : lead.company).font(.subheadline.bold())
                                Text(lead.leadSource).font(.caption).foregroundStyle(AppTheme.textMuted)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(leadScore(lead))").font(.headline.bold()).foregroundStyle(AppTheme.successGreen)
                                Text("ICP fit").font(.caption2).foregroundStyle(AppTheme.textMuted)
                            }
                        }.cardStyle()
                    }.buttonStyle(.plain)
                }
            }.padding()
        }.appBackground()
    }

    private var scoredLeads: [Lead] {
        appState.crm.leads.sorted { leadScore($0) > leadScore($1) }
    }

    private func leadScore(_ lead: Lead) -> Int {
        min(100, lead.probabilityOfClosing + (lead.priority == .hot ? 15 : 0) + min(lead.activities.count * 3, 15))
    }
}

struct ProspectResearchView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedLeadId: String?
    @State private var briefing: PreCallBriefing?
    @State private var isLoading = false

    private var selectedLead: Lead? {
        guard let id = selectedLeadId else { return appState.crm.leads.first }
        return appState.crm.leads.first { $0.id == id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(title: "Prospect Research", subtitle: "Never enter a meeting unprepared", icon: "doc.text.magnifyingglass", accent: AppTheme.electricBlueBright)
                if !appState.crm.leads.isEmpty {
                    Picker("Client", selection: Binding(get: { selectedLeadId ?? appState.crm.leads.first?.id ?? "" }, set: { selectedLeadId = $0 })) {
                        ForEach(appState.crm.leads) { lead in
                            Text(lead.company.isEmpty ? lead.name : lead.company).tag(lead.id)
                        }
                    }
                }
                PrimaryButton(title: isLoading ? "Generating..." : "Generate Briefing", icon: "sparkles") {
                    Task { await loadBriefing() }
                }.disabled(isLoading || selectedLead == nil)
                if let briefing {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Opening").font(.headline)
                        Text(briefing.openingLine).font(.subheadline).cardStyle()
                        SectionHeader(title: "Key Points")
                        ForEach(briefing.keyPoints, id: \.self) { Text("• \($0)").font(.caption) }
                        SectionHeader(title: "Questions")
                        ForEach(briefing.questionsToAsk, id: \.self) { Text("• \($0)").font(.caption) }
                    }
                }
            }.padding()
        }.appBackground()
    }

    private func loadBriefing() async {
        guard let lead = selectedLead else { return }
        isLoading = true
        briefing = try? await OpenAIService.shared.requestPreCallBriefing(lead: lead, category: appState.auth.currentUser?.salesCategory)
        isLoading = false
    }
}

// MARK: - Intelligence

struct DealHealthCenterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                CRMGradientHeader(title: "Deal Health Center", subtitle: "AI scores with explainable factors", icon: "heart.circle.fill", accent: AppTheme.dangerRed)
                ForEach(appState.crm.leads.filter { $0.dealStage.isActivePipeline }.sorted { $0.dealHealthScore < $1.dealHealthScore }) { lead in
                    NavigationLink { LeadDetailView(lead: lead) } label: {
                        HStack {
                            DealHealthRing(score: lead.dealHealthScore, size: 44)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lead.name).font(.subheadline.bold())
                                Text(lead.dealHealthLabel).font(.caption).foregroundStyle(lead.dealHealthColor)
                                Text(lead.predictedCloseInsight.explanation).font(.caption2).foregroundStyle(AppTheme.textMuted).lineLimit(2)
                            }
                            Spacer()
                        }.cardStyle()
                    }.buttonStyle(.plain)
                }
            }.padding()
        }.appBackground()
    }
}

struct ClosingPredictorView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                CRMGradientHeader(title: "Closing Predictor", subtitle: "Probability, revenue, and required next steps", icon: "scope", accent: AppTheme.tealGreen)
                ForEach(appState.crm.leads.filter { $0.dealStage.isActivePipeline }.sorted { $0.predictedCloseInsight.closeProbability > $1.predictedCloseInsight.closeProbability }.prefix(12)) { lead in
                    let insight = lead.predictedCloseInsight
                    NavigationLink { LeadDetailView(lead: lead) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(lead.company.isEmpty ? lead.name : lead.company).font(.headline)
                                Spacer()
                                Text("\(insight.closeProbability)%").font(.title3.bold()).foregroundStyle(AppTheme.successGreen)
                            }
                            Text("Expected: \(formatShortCurrency(insight.expectedRevenue)) · ~\(insight.estimatedDaysToClose)d · Risk: \(insight.riskLevel)")
                                .font(.caption).foregroundStyle(AppTheme.textSecondary)
                        }.cardStyle()
                    }.buttonStyle(.plain)
                }
            }.padding()
        }.appBackground()
    }
}

struct RevenueForecastingView: View {
    @Environment(AppState.self) private var appState
    private var snapshot: CRMSnapshot { appState.crm.snapshot() }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(title: "Revenue Forecasting", subtitle: "Pipeline-weighted monthly and quarterly outlook", icon: "chart.line.uptrend.xyaxis", accent: AppTheme.electricBlueBright)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    forecastTile("Pipeline", snapshot.pipelineValue, AppTheme.successGreen)
                    forecastTile("Weighted", snapshot.weightedPipeline, AppTheme.tealGreen)
                    forecastTile("Won Revenue", snapshot.wonRevenue, AppTheme.warningOrange)
                    forecastTile("Win Rate", snapshot.winRate, AppTheme.electricBlueBright, isPercent: true)
                }
                SectionHeader(title: "Monthly Trend")
                ForEach(snapshot.monthlyTrends) { point in
                    HStack {
                        Text(point.label).font(.caption.bold())
                        Spacer()
                        Text("$\(Int(point.revenueWon)) won").font(.caption)
                        Text("· \(point.acquisitions) new").font(.caption2).foregroundStyle(AppTheme.textMuted)
                    }.cardStyle()
                }
            }.padding()
        }.appBackground()
    }

    private func forecastTile(_ label: String, _ value: Double, _ color: Color, isPercent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(AppTheme.textMuted)
            Text(isPercent ? "\(Int(value))%" : formatShortCurrency(value)).font(.headline.bold()).foregroundStyle(color)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(AppTheme.navyCard.opacity(0.6)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct BusinessIntelligenceView: View {
    @Environment(AppState.self) private var appState
    @State private var question = ""
    @State private var answer = ""
    @State private var isLoading = false

    private let samples = [
        "Why are sales slowing?",
        "Which industries close fastest?",
        "Which rep needs coaching?",
        "Where should we invest?"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(title: "Business Intelligence", subtitle: "Ask natural language questions about your book", icon: "brain", accent: AppTheme.electricBlue)
                TextField("Ask a question...", text: $question, axis: .vertical).lineLimit(2...4).textFieldStyle(AppTextFieldStyle())
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(samples, id: \.self) { sample in
                            Button(sample) { question = sample }.font(.caption2).padding(.horizontal, 10).padding(.vertical, 6).background(AppTheme.navyCard).clipShape(Capsule())
                        }
                    }
                }
                PrimaryButton(title: isLoading ? "Analyzing..." : "Ask AI", icon: "sparkles") {
                    Task { await runQuery() }
                }.disabled(question.isEmpty || isLoading)
                if !answer.isEmpty {
                    Text(answer).font(.subheadline).cardStyle()
                }
            }.padding()
        }.appBackground()
    }

    private func runQuery() async {
        isLoading = true
        let snapshot = appState.crm.snapshot()
        let prompt = "Question: \(question)\nPipeline: $\(Int(snapshot.pipelineValue)), Win rate: \(Int(snapshot.winRate))%, Active deals: \(snapshot.activeDeals), Avg deal: $\(Int(snapshot.avgDealSize)). Answer as an executive brief in 3-5 sentences."
        if AppConfig.isAIConfigured, let result = try? await OpenAIService.shared.requestBusinessIntel(prompt: prompt) {
            answer = result
            appState.platform.storeIntel(question: question, answer: result)
        } else {
            answer = "Based on your pipeline of \(formatShortCurrency(snapshot.pipelineValue)) and \(Int(snapshot.winRate))% win rate, focus on clearing overdue follow-ups and pushing hot deals in proposal stage."
        }
        isLoading = false
    }
}

struct WinLossAnalysisHubView: View {
    @Environment(AppState.self) private var appState
    @State private var presentation: WinLossAutopsyPresentation?
    @State private var loadingLeadId: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                CRMGradientHeader(title: "Win/Loss Analysis", subtitle: "Coaching autopsies and pattern detection", icon: "arrow.triangle.branch", accent: AppTheme.warningOrange)
                let won = appState.crm.leads.filter { $0.dealStage == .won }
                let lost = appState.crm.leads.filter { $0.dealStage == .lost }
                HStack {
                    statPill("Won", won.count, AppTheme.successGreen)
                    statPill("Lost", lost.count, AppTheme.dangerRed)
                }
                SectionHeader(title: "Recent Outcomes")
                ForEach((won + lost).sorted { $0.updatedAt > $1.updatedAt }.prefix(10)) { lead in
                    VStack(spacing: 8) {
                        NavigationLink { LeadDetailView(lead: lead) } label: {
                            HStack {
                                Image(systemName: lead.dealStage == .won ? "trophy.fill" : "xmark.circle.fill")
                                    .foregroundStyle(lead.dealStage == .won ? AppTheme.successGreen : AppTheme.dangerRed)
                                VStack(alignment: .leading) {
                                    Text(lead.name).font(.subheadline.bold())
                                    Text(lead.dealStage.rawValue).font(.caption).foregroundStyle(AppTheme.textMuted)
                                }
                                Spacer()
                                Text(formatShortCurrency(lead.dealValue)).font(.caption.bold())
                            }.cardStyle()
                        }.buttonStyle(.plain)

                        Button {
                            Task { await runAutopsy(for: lead) }
                        } label: {
                            Label(loadingLeadId == lead.id ? "Analyzing..." : "AI Deal Autopsy", systemImage: "sparkles")
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(AppTheme.electricBlueBright.opacity(0.12))
                                .foregroundStyle(AppTheme.electricBlueBright)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .disabled(loadingLeadId != nil)
                    }
                }
            }.padding()
        }
        .appBackground()
        .sheet(item: $presentation) { item in
            NavigationStack {
                WinLossAutopsyView(autopsy: item.autopsy, lead: item.lead)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { presentation = nil }
                        }
                    }
            }
        }
    }

    private func runAutopsy(for lead: Lead) async {
        loadingLeadId = lead.id
        defer { loadingLeadId = nil }
        let report: WinLossAutopsy
        if AppConfig.isAIConfigured, let ai = try? await OpenAIService.shared.requestWinLossAutopsy(
            lead: lead,
            won: lead.dealStage == .won,
            finalValue: lead.dealValue
        ) {
            report = ai
        } else {
            report = WinLossAutopsy(
                headline: lead.dealStage == .won ? "Strong close on \(lead.company)" : "Learn from \(lead.company)",
                whatWorked: ["Built rapport early", "Confirmed budget timeline"],
                whatToImprove: ["Document objections sooner", "Schedule tighter follow-ups"],
                playbookSnippet: "When \(lead.leadSource) leads stall, re-engage with a value recap and one clear next step.",
                recommendedDrill: "Objection handling practice",
                nextActions: ["Log competitor notes", "Schedule debrief with manager"]
            )
        }
        presentation = WinLossAutopsyPresentation(lead: lead, autopsy: report)
    }

    private func statPill(_ label: String, _ count: Int, _ color: Color) -> some View {
        VStack {
            Text("\(count)").font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption)
        }.frame(maxWidth: .infinity).cardStyle()
    }
}

struct CompetitorIntelligenceView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                CRMGradientHeader(title: "Competitor Intelligence", subtitle: "Mentions, win/loss patterns, and responses", icon: "flag.2.crossed.fill", accent: AppTheme.dangerRed)
                ForEach(appState.platform.competitorInsights(from: appState.crm.leads)) { insight in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(insight.name).font(.headline)
                        Text("\(insight.mentionCount) mentions · \(insight.activeDeals) active · \(insight.lostTo) lost to")
                            .font(.caption).foregroundStyle(AppTheme.textSecondary)
                    }.cardStyle()
                }
                if appState.platform.competitorInsights(from: appState.crm.leads).isEmpty {
                    Text("Add competitor names on client records to track competitive intel.").font(.caption).foregroundStyle(AppTheme.textMuted).cardStyle()
                }
            }.padding()
        }.appBackground()
    }
}

struct PricingAdvisorView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(title: "Pricing Advisor", subtitle: "Discounts, bundles, upsells, and contract strategy", icon: "percent", accent: AppTheme.tealGreen)
                CommissionCalculatorView()
            }.padding()
        }.appBackground()
    }
}

// MARK: - Enablement & Operations

struct PlatformProposalView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedLeadId: String?
    @State private var amount = ""
    @State private var scope = ""
    @State private var generated = ""
    @State private var isGenerating = false

    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(title: "Proposals & Quotes", subtitle: "AI-generated proposals ready to send", icon: "doc.richtext.fill", accent: AppTheme.electricBlueBright)
                if !appState.crm.leads.isEmpty {
                    Picker("Client", selection: Binding(get: { selectedLeadId ?? appState.crm.leads.first?.id ?? "" }, set: { selectedLeadId = $0 })) {
                        ForEach(appState.crm.leads.filter { $0.dealStage.isActivePipeline }) { lead in
                            Text(lead.name).tag(lead.id)
                        }
                    }
                }
                TextField("Amount", text: $amount).keyboardType(.decimalPad).textFieldStyle(AppTextFieldStyle())
                TextField("Scope / products", text: $scope, axis: .vertical).lineLimit(2...4).textFieldStyle(AppTextFieldStyle())
                PrimaryButton(title: isGenerating ? "Generating..." : "Generate Proposal", icon: "sparkles") {
                    Task { await generate() }
                }.disabled(isGenerating)
                TextField("Proposal", text: $generated, axis: .vertical).lineLimit(8...20).textFieldStyle(AppTextFieldStyle())
                if !generated.isEmpty {
                    ShareLink(item: generated) { Label("Share / Export", systemImage: "square.and.arrow.up") }
                }
            }.padding()
        }.appBackground()
    }

    private func generate() async {
        guard let lead = appState.crm.leads.first(where: { $0.id == (selectedLeadId ?? appState.crm.leads.first?.id) }) else { return }
        isGenerating = true
        let value = Double(amount.filter { $0.isNumber || $0 == "." }) ?? lead.dealValue
        if AppConfig.isAIConfigured, let body = try? await OpenAIService.shared.requestProposal(lead: lead, amount: value, scope: scope) {
            generated = body
            appState.platform.saveProposal(SalesProposal(userId: userId, leadId: lead.id, title: "Proposal — \(lead.company)", body: body, amount: value), for: userId)
        } else {
            generated = "Proposal for \(lead.company)\n\nInvestment: $\(Int(value))\nScope: \(scope.isEmpty ? lead.notes : scope)\n\nWe look forward to partnering with you."
        }
        isGenerating = false
    }
}

struct ContractManagementView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                CRMGradientHeader(title: "Contract Management", subtitle: "Track renewals, signatures, and legal review", icon: "signature", accent: AppTheme.textSecondary)
                ForEach(appState.crm.leads.filter { $0.dealStage == .won || $0.dealStage == .legal || $0.dealStage == .procurement }.prefix(10)) { lead in
                    Button {
                        appState.platform.addContract(from: lead)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(lead.name).font(.subheadline.bold())
                                Text(lead.dealStage.rawValue).font(.caption).foregroundStyle(AppTheme.textMuted)
                            }
                            Spacer()
                            Text(formatShortCurrency(lead.dealValue)).font(.caption.bold())
                            Image(systemName: "plus.circle").foregroundStyle(AppTheme.tealGreen)
                        }.cardStyle()
                    }.buttonStyle(.plain)
                }
                SectionHeader(title: "Contracts")
                ForEach(appState.platform.contracts) { contract in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contract.clientName).font(.subheadline.bold())
                        Text("\(contract.status) · \(formatShortCurrency(contract.value))").font(.caption).foregroundStyle(AppTheme.textSecondary)
                        if let exp = contract.expiresAt {
                            Text("Expires \(exp.formatted(date: .abbreviated, time: .omitted))").font(.caption2).foregroundStyle(AppTheme.textMuted)
                        }
                    }.cardStyle()
                }
            }.padding()
        }.appBackground()
    }
}

struct CustomerSuccessView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                CRMGradientHeader(title: "Customer Success", subtitle: "Health scores, churn risk, and renewals", icon: "hand.thumbsup.fill", accent: AppTheme.successGreen)
                ForEach(appState.crm.leads.filter { $0.dealStage == .won || $0.dealStage.isActivePipeline }.sorted { $0.dealHealthScore < $1.dealHealthScore }.prefix(12)) { lead in
                    NavigationLink { LeadDetailView(lead: lead) } label: {
                        HStack {
                            DealHealthRing(score: lead.dealHealthScore, size: 40)
                            VStack(alignment: .leading) {
                                Text(lead.name).font(.subheadline.bold())
                                Text(lead.dealHealthScore < 50 ? "Churn risk — schedule check-in" : "Healthy account").font(.caption).foregroundStyle(lead.dealHealthColor)
                            }
                            Spacer()
                        }.cardStyle()
                    }.buttonStyle(.plain)
                }
            }.padding()
        }.appBackground()
    }
}

struct CustomerPortalView: View {
    @Environment(AppState.self) private var appState

    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(title: "Customer Portal", subtitle: "Clients view proposals, pay invoices, and get support", icon: "person.crop.circle", accent: AppTheme.electricBlueBright)

                SectionHeader(title: "Shared Proposals")
                if appState.platform.proposals(for: userId).isEmpty {
                    Text("Generate proposals in Proposals & Quotes — they appear here for client sharing.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMuted)
                        .cardStyle()
                } else {
                    ForEach(appState.platform.proposals(for: userId).prefix(8)) { proposal in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(proposal.title).font(.subheadline.bold())
                            Text(formatShortCurrency(proposal.amount)).font(.caption).foregroundStyle(AppTheme.tealGreen)
                            Text(proposal.body).font(.caption2).foregroundStyle(AppTheme.textMuted).lineLimit(3)
                            ShareLink(item: proposalShareText(proposal)) {
                                Label("Share with Client", systemImage: "square.and.arrow.up")
                                    .font(.caption.bold())
                            }
                        }.cardStyle()
                    }
                }

                SectionHeader(title: "Support & Billing")
                NavigationLink {
                    OfficeTabView()
                } label: {
                    FeatureCard(title: "Support Requests", subtitle: "Route complaints and billing from Office", icon: "lifepreserver.fill", accentColor: AppTheme.warningOrange)
                }.buttonStyle(.plain)

                NavigationLink {
                    ContractManagementView()
                } label: {
                    FeatureCard(title: "Contracts & Renewals", subtitle: "Active agreements and renewal dates", icon: "signature", accentColor: AppTheme.electricBlue)
                }.buttonStyle(.plain)
            }.padding()
        }.appBackground()
    }

    private func proposalShareText(_ proposal: SalesProposal) -> String {
        "\(proposal.title)\n\n\(proposal.body)\n\nInvestment: \(formatShortCurrency(proposal.amount))"
    }
}

struct MarketingAutomationView: View {
    @Environment(AppState.self) private var appState
    @State private var showCreate = false
    @State private var newName = ""
    @State private var newChannel = "Email"
    @State private var generatedCampaign = ""
    @State private var isGenerating = false

    private let channels = ["Email", "SMS", "Multi-channel"]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                CRMGradientHeader(title: "Marketing Automation", subtitle: "Email campaigns, drips, and A/B templates", icon: "megaphone.fill", accent: AppTheme.warningOrange)

                PrimaryButton(title: "New Campaign", icon: "plus.circle.fill") {
                    showCreate = true
                }

                SectionHeader(title: "Campaigns")
                ForEach(appState.platform.campaigns) { campaign in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(campaign.name).font(.subheadline.bold())
                                Text("\(campaign.channel) · \(campaign.status)").font(.caption).foregroundStyle(AppTheme.textMuted)
                            }
                            Spacer()
                            if campaign.sent > 0 {
                                Text("\(campaign.opens)/\(campaign.sent) opens").font(.caption2)
                            }
                        }
                        HStack(spacing: 8) {
                            if campaign.status == "Draft" || campaign.status == "Template" {
                                Button("Launch") {
                                    appState.platform.launchCampaign(campaign.id)
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.tealGreen.opacity(0.15))
                                .foregroundStyle(AppTheme.tealGreen)
                                .clipShape(Capsule())
                            }
                            NavigationLink {
                                EmailAssistantView()
                            } label: {
                                Text("Draft Email")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.electricBlueBright.opacity(0.12))
                                    .foregroundStyle(AppTheme.electricBlueBright)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }.cardStyle()
                }
            }.padding()
        }
        .appBackground()
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                Form {
                    Section("Campaign") {
                        TextField("Name", text: $newName)
                        Picker("Channel", selection: $newChannel) {
                            ForEach(channels, id: \.self) { Text($0).tag($0) }
                        }
                    }
                    if !generatedCampaign.isEmpty {
                        Section("AI Draft") {
                            Text(generatedCampaign).font(.caption)
                        }
                    }
                    Section {
                        Button(isGenerating ? "Generating..." : "Generate with AI") {
                            Task { await generateCampaignDraft() }
                        }.disabled(newName.isEmpty || isGenerating)
                        Button("Save Campaign") {
                            appState.platform.createCampaign(name: newName, channel: newChannel)
                            showCreate = false
                            newName = ""
                            generatedCampaign = ""
                        }.disabled(newName.isEmpty)
                    }
                }
                .navigationTitle("New Campaign")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showCreate = false }
                    }
                }
            }
        }
    }

    private func generateCampaignDraft() async {
        isGenerating = true
        defer { isGenerating = false }
        let prompt = "Campaign: \(newName). Channel: \(newChannel). Audience: CRM prospects. Goal: pipeline growth."
        if AppConfig.isAIConfigured, let result = try? await OpenAIService.shared.requestBusinessIntel(prompt: prompt) {
            generatedCampaign = result
        } else {
            generatedCampaign = "3-touch \(newChannel.lowercased()) sequence: intro value, social proof, and meeting ask."
        }
    }
}

struct EmailAssistantView: View {
    @Environment(AppState.self) private var appState
    @State private var emailType: EmailAssistantType = .followUp
    @State private var selectedLeadId: String?
    @State private var generated = ""
    @State private var isGenerating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(title: "AI Email Assistant", subtitle: "Outreach, follow-ups, and tone rewrites", icon: "envelope.badge.fill", accent: AppTheme.electricBlueBright)
                Picker("Type", selection: $emailType) {
                    ForEach(EmailAssistantType.allCases) { type in Text(type.rawValue).tag(type) }
                }
                if !appState.crm.leads.isEmpty {
                    Picker("Client", selection: Binding(get: { selectedLeadId ?? appState.crm.leads.first?.id ?? "" }, set: { selectedLeadId = $0 })) {
                        ForEach(appState.crm.leads) { lead in Text(lead.name).tag(lead.id) }
                    }
                }
                PrimaryButton(title: isGenerating ? "Writing..." : "Generate Email", icon: "sparkles") {
                    Task { await generate() }
                }.disabled(isGenerating)
                TextField("Email draft", text: $generated, axis: .vertical).lineLimit(6...16).textFieldStyle(AppTextFieldStyle())
                if !generated.isEmpty { ShareLink(item: generated) { Label("Share", systemImage: "square.and.arrow.up") } }
            }.padding()
        }.appBackground()
    }

    private func generate() async {
        guard let lead = appState.crm.leads.first(where: { $0.id == (selectedLeadId ?? appState.crm.leads.first?.id) }) else { return }
        isGenerating = true
        if AppConfig.isAIConfigured, let body = try? await OpenAIService.shared.requestEmailDraft(type: emailType.rawValue, lead: lead) {
            generated = body
        } else {
            generated = "Subject: \(emailType.rawValue) — \(lead.company)\n\nHi \(lead.name),\n\n[Personalized \(emailType.rawValue.lowercased()) message]\n\nBest regards"
        }
        isGenerating = false
    }
}

struct WorkflowAutomationView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                CRMGradientHeader(title: "Workflow Automation", subtitle: "Trigger actions automatically across your stack", icon: "arrow.triangle.branch", accent: AppTheme.tealGreen)
                ForEach(appState.platform.workflows) { workflow in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(workflow.name).font(.headline)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { workflow.isEnabled },
                                set: { _ in appState.platform.toggleWorkflow(workflow.id) }
                            )).labelsHidden()
                        }
                        Text("Trigger: \(workflow.trigger)").font(.caption).foregroundStyle(AppTheme.textSecondary)
                        ForEach(workflow.actions, id: \.self) { action in
                            Label(action, systemImage: "bolt.fill").font(.caption2).foregroundStyle(AppTheme.textMuted)
                        }
                    }.cardStyle()
                }
            }.padding()
        }.appBackground()
    }
}

// MARK: - Coach extensions

struct ConversationIntelligenceView: View {
    @Environment(AppState.self) private var appState
    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                CRMGradientHeader(title: "Conversation Intelligence", subtitle: "Transcripts, summaries, and action items", icon: "waveform", accent: AppTheme.electricBlue)
                ForEach(appState.training.sessions.filter { $0.userId == userId && !$0.transcript.isEmpty }.prefix(10)) { session in
                    NavigationLink {
                        if let report = session.scoreReport {
                            ScoringReportView(report: report, session: session)
                        } else {
                            TrainingSessionDetailView(session: session)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.scenario.rawValue).font(.headline)
                            Text("\(session.transcript.count) turns · \(session.personality.rawValue)").font(.caption).foregroundStyle(AppTheme.textMuted)
                        }.cardStyle()
                    }.buttonStyle(.plain)
                }
            }.padding()
        }.appBackground()
    }
}

struct EmotionalIntelligenceView: View {
    @Environment(AppState.self) private var appState
    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                CRMGradientHeader(title: "Emotional Intelligence", subtitle: "Confidence, empathy, pacing, and energy", icon: "heart.text.square.fill", accent: AppTheme.warningOrange)
                let profile = RepDNAService.shared.profile(userId: userId, training: appState.training, crm: appState.crm, gamification: appState.gamification)
                ForEach(profile.skills) { skill in
                    HStack {
                        Text(skill.name).font(.subheadline.bold())
                        Spacer()
                        Text("\(skill.score)").font(.headline.bold()).foregroundStyle(skill.score >= 75 ? AppTheme.successGreen : AppTheme.warningOrange)
                        Text(skill.trend).font(.caption2).foregroundStyle(AppTheme.textMuted)
                    }.cardStyle()
                }
            }.padding()
        }.appBackground()
    }
}

struct LiveCallCopilotView: View {
    @Environment(AppState.self) private var appState
    @State private var isSessionActive = false
    @State private var coachingTip = "Pick a client and start a session before your next call."
    @State private var tipHistory: [String] = []
    @State private var selectedLeadId: String?
    @State private var isAnalyzing = false
    @State private var lastRepLine = ""

    private var selectedLead: Lead? {
        guard let id = selectedLeadId else { return appState.crm.leads.first }
        return appState.crm.leads.first { $0.id == id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(title: "Live Call Co-Pilot", subtitle: "Real-time coaching during conversations", icon: "ear.fill", accent: AppTheme.tealGreen)

                if !appState.crm.leads.isEmpty {
                    Picker("Client", selection: Binding(
                        get: { selectedLeadId ?? appState.crm.leads.first?.id ?? "" },
                        set: { selectedLeadId = $0 }
                    )) {
                        ForEach(appState.crm.leads.filter { $0.dealStage.isActivePipeline }) { lead in
                            Text(lead.company.isEmpty ? lead.name : lead.company).tag(lead.id)
                        }
                    }
                }

                HStack {
                    Circle()
                        .fill(isSessionActive ? AppTheme.dangerRed : AppTheme.textMuted)
                        .frame(width: 10, height: 10)
                    Text(isSessionActive ? "Listening — speak naturally" : "Session inactive")
                        .font(.caption.bold())
                        .foregroundStyle(isSessionActive ? AppTheme.tealGreen : AppTheme.textMuted)
                    Spacer()
                    if appState.voice.isListening {
                        Text("Mic on").font(.caption2).foregroundStyle(AppTheme.warningOrange)
                    }
                }
                .cardStyle()

                Text(coachingTip)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                if !lastRepLine.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You said").font(.caption.bold()).foregroundStyle(AppTheme.textMuted)
                        Text(lastRepLine).font(.caption)
                    }.cardStyle()
                }

                PrimaryButton(
                    title: isSessionActive ? "End Session" : "Start Co-Pilot Session",
                    icon: isSessionActive ? "stop.fill" : "play.fill"
                ) {
                    toggleSession()
                }
                .disabled(selectedLead == nil || isAnalyzing)

                if !tipHistory.isEmpty {
                    SectionHeader(title: "Session Tips")
                    ForEach(Array(tipHistory.enumerated()), id: \.offset) { _, tip in
                        Text(tip).font(.caption).foregroundStyle(AppTheme.textSecondary).cardStyle()
                    }
                }

                NavigationLink {
                    ConversationIntelligenceView()
                } label: {
                    FeatureCard(title: "Review After Call", subtitle: "Debrief in Conversation Intelligence", icon: "waveform", accentColor: AppTheme.electricBlueBright)
                }.buttonStyle(.plain)
            }.padding()
        }
        .appBackground()
        .onDisappear { stopSession() }
    }

    private func toggleSession() {
        if isSessionActive {
            stopSession()
        } else {
            startSession()
        }
    }

    private func startSession() {
        guard selectedLead != nil else { return }
        coachingTip = "Listening… after you speak, co-pilot suggests your next move."
        tipHistory = []
        isSessionActive = true
        appState.voice.onUtteranceFinished = { text in
            Task { await analyzeUtterance(text) }
        }
        do {
            try appState.voice.startListening()
        } catch {
            coachingTip = appState.voice.errorMessage ?? "Could not start microphone."
            isSessionActive = false
        }
    }

    private func stopSession() {
        isSessionActive = false
        appState.voice.onUtteranceFinished = nil
        appState.voice.stopListening()
        if tipHistory.isEmpty {
            coachingTip = "Session ended. Review Conversation Intelligence for your debrief."
        }
    }

    private func analyzeUtterance(_ text: String) async {
        guard isSessionActive, let lead = selectedLead else { return }
        lastRepLine = text
        isAnalyzing = true
        defer { isAnalyzing = false }

        let tip: String
        if AppConfig.isAIConfigured, let ai = try? await OpenAIService.shared.requestLiveCopilotTip(
            lead: lead,
            transcript: text,
            category: appState.auth.currentUser?.salesCategory
        ) {
            tip = ai
            appState.recordTokenCharge(feature: .chatCoach, tokens: 120)
        } else {
            tip = "Acknowledge what they said, then ask one discovery question before discussing price."
        }

        coachingTip = tip
        tipHistory.insert(tip, at: 0)
        if tipHistory.count > 5 { tipHistory.removeLast() }

        if isSessionActive {
            do {
                try appState.voice.startListening()
            } catch {
                coachingTip = "Mic paused — tap Start to resume co-pilot."
                isSessionActive = false
            }
        }
    }
}

private func formatShortCurrency(_ value: Double) -> String {
    if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
    if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
    return String(format: "$%.0f", value)
}

private struct WinLossAutopsyPresentation: Identifiable {
    let id = UUID()
    let lead: Lead
    let autopsy: WinLossAutopsy
}
