import SwiftUI

struct ProductGuideView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedSection: String?

    private let sections: [GuideSection] = [
        GuideSection(
            id: "start",
            title: "Getting Started",
            icon: "sparkles",
            color: AppTheme.electricBlueBright,
            summary: "Sales Coach AI is your sales operating system — CRM, coaching, training, and field tools in one app.",
            steps: [
                "Sign in and pick your sales vertical (SaaS, Real Estate, Insurance, etc.).",
                "Your home screen, CRM labels, and discovery map adapt to your category.",
                "Add real clients or load example data from Settings to explore features.",
                "Open the Product Guide anytime from Home or More."
            ],
            destination: "Home tab"
        ),
        GuideSection(
            id: "dashboard",
            title: "Your Dashboard",
            icon: "square.grid.2x2.fill",
            color: AppTheme.tealGreen,
            summary: "The Home tab shows today's priorities, pipeline snapshot, AI recommendations, and quick access to every module.",
            steps: [
                "Today at a Glance — follow-ups due, hot deals, pipeline, win rate, and training score.",
                "AI Recommendations — proactive next steps based on your CRM and training data.",
                "Performance — track roleplay scores, pipeline value, and pinned field clients.",
                "Priority Clients — jump straight into your most important deals."
            ],
            destination: "Home tab"
        ),
        GuideSection(
            id: "crm",
            title: "CRM & Pipeline",
            icon: "person.crop.rectangle.stack.fill",
            color: AppTheme.successGreen,
            summary: "Track people, companies, deals, notes, locations, tags, and activity timelines.",
            steps: [
                "Field Sales & CRM hub — KPIs, map discovery, and workspace links.",
                "Pipeline board — drag deals across stages from New Lead to Closed Won/Lost.",
                "Tasks — overdue follow-ups, hot leads, and stale contacts in one queue.",
                "Lead detail — contact intel, deal events, AI next steps, and Apple Maps navigation.",
                "Companies view — group contacts, tags, and tasks by organization."
            ],
            destination: "Home → Field Sales & CRM"
        ),
        GuideSection(
            id: "coach",
            title: "AI Sales Coach",
            icon: "bubble.left.and.bubble.right.fill",
            color: AppTheme.electricBlueBright,
            summary: "Chat with an AI coach for objection handling, talk tracks, negotiation tactics, and deal strategy.",
            steps: [
                "Open AI Training Studio → AI Coach tab.",
                "Ask about specific deals, industries, or scenarios.",
                "Use proximity briefings in the field for pre-call intel.",
                "Follow-up generator drafts emails from lead context."
            ],
            destination: "Home → AI Training Studio → Coach"
        ),
        GuideSection(
            id: "roleplay",
            title: "Voice Roleplay Training",
            icon: "mic.fill",
            color: AppTheme.warningOrange,
            summary: "Practice against AI customers with natural voices, multiple personalities, and post-call scoring.",
            steps: [
                "Choose a scenario: cold call, follow-up, closing, upsell, and more.",
                "Pick a personality: skeptical, busy executive, price-focused, angry, etc.",
                "Speak naturally — the AI responds in real time with HD voice.",
                "Review your score report: objections, confidence, questions asked, and improvements.",
                "Earn certifications as your scores improve."
            ],
            destination: "Home → AI Training Studio → Roleplay"
        ),
        GuideSection(
            id: "field",
            title: "Field Sales & Maps",
            icon: "map.fill",
            color: AppTheme.tealGreen,
            summary: "Find prospects, pin client locations, get GPS proximity alerts, and plan multi-stop routes.",
            steps: [
                "Map Discovery — search nearby businesses by your sales category.",
                "Pin client addresses — enable geofencing for arrival briefings.",
                "Route Planner — optimize visit order with Apple Maps navigation.",
                "Proximity sheet — personal hooks, talk track, and practice-this-deal shortcuts."
            ],
            destination: "Home → Field Sales & CRM → Map / Discovery"
        ),
        GuideSection(
            id: "toolkit",
            title: "Ultimate Sales Toolkit",
            icon: "star.circle.fill",
            color: AppTheme.warningOrange,
            summary: "Forecasts, skill gaps, script packs, battle mode, call analysis, and team playbooks.",
            steps: [
                "Revenue Forecast — weighted pipeline projections.",
                "Skill Gap Dashboard — compare training scores vs deal performance.",
                "Script Packs & Playbooks — vertical talk tracks for your team.",
                "Call Analysis — paste a transcript for AI breakdown.",
                "Activity Goals — weekly calls, visits, and new lead targets.",
                "CRM Export — download your pipeline as CSV."
            ],
            destination: "Home → Ultimate Sales Toolkit"
        ),
        GuideSection(
            id: "team",
            title: "Team & Leaderboard",
            icon: "person.3.fill",
            color: AppTheme.electricBlueBright,
            summary: "Manager dashboards, rep scorecards, leaderboards, and assigned drills.",
            steps: [
                "Leaderboard — individual and team rankings.",
                "Team Dashboard — rep stats, weaknesses, and assignments.",
                "Manager Drills — assign training scenarios to reps.",
                "Load example team data from Settings to preview team features."
            ],
            destination: "More tab → Leaderboard / Team"
        ),
        GuideSection(
            id: "chatcrm",
            title: "Team Sales Logging",
            icon: "bubble.left.and.text.bubble.right.fill",
            color: AppTheme.successGreen,
            summary: "Reps log closed deals in Team Sales Coach — shared on the Team Dashboard. Clients never need the app.",
            steps: [
                "Try: \"Closed $8k with Acme Corp today.\"",
                "Try: \"Just sold $12k to TechFlow.\"",
                "Sales appear on Team Dashboard → Team Sales Feed.",
                "Also recorded in Order Audit Log for managers.",
                "Still ask coaching questions — objections, scripts, win announcements."
            ],
            destination: "AI Training Studio → Team Sales Coach"
        ),
        GuideSection(
            id: "audit",
            title: "Order Audit Trail",
            icon: "list.bullet.rectangle.portrait.fill",
            color: AppTheme.warningOrange,
            summary: "Every sale, contact, and deal change is recorded with timestamp, source, and field-level changes.",
            steps: [
                "Closed Orders — view won deals and monthly revenue.",
                "Audit Log — full history of CRM changes.",
                "Sources tracked: Manual, AI Chat, Pipeline, Import.",
                "Open from Ultimate Toolkit → Order Audit Log."
            ],
            destination: "Ultimate Toolkit → Order Audit Log"
        ),
        GuideSection(
            id: "roadmap",
            title: "Coming Soon",
            icon: "arrow.triangle.branch",
            color: AppTheme.textMuted,
            summary: "We're building toward the full Sales Coach AI vision. These features are on the roadmap.",
            steps: [
                "HubSpot / Salesforce live sync.",
                "Live call coaching and conversation intelligence.",
                "Marketing campaigns and Apple Watch widgets.",
                "Business card OCR scanner.",
                "Full visual automation workflow builder."
            ],
            destination: "Integrations hub (preview)"
        )
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                guideHero
                quickStartCard
                ForEach(sections) { section in
                    GuideSectionCard(section: section, isExpanded: expandedSection == section.id) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedSection = expandedSection == section.id ? nil : section.id
                        }
                    }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Product Guide")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    private var guideHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Sales Coach AI", systemImage: "graduationcap.fill")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.tealGreen)
            Text("Your AI-powered sales operating system")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Text("CRM, coaching, training, analytics, and field tools — designed to help you perform like a top 1% closer.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.heroGradient)
                .background(AppTheme.cardBackground(for: colorScheme))
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var quickStartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("5-Minute Quick Start")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            VStack(alignment: .leading, spacing: 8) {
                quickStep(1, "Add a client with name, company, and location")
                quickStep(2, "Run one voice roleplay in AI Training Studio")
                quickStep(3, "Check AI Recommendations on your Home dashboard")
                quickStep(4, "Open the CRM pipeline and move a deal to the next stage")
                quickStep(5, "Pin a map location to test proximity briefings")
            }
        }
        .cardStyle()
    }

    private func quickStep(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(AppTheme.brandGradient)
                .clipShape(Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        }
    }
}

private struct GuideSection: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let summary: String
    let steps: [String]
    let destination: String
}

private struct GuideSectionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let section: GuideSection
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    Image(systemName: section.icon)
                        .font(.title3)
                        .foregroundStyle(section.color)
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(section.title)
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        Text(section.summary)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            .lineLimit(isExpanded ? nil : 2)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.electricBlueBright)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().padding(.vertical, 8)
                    ForEach(Array(section.steps.enumerated()), id: \.offset) { _, step in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(section.color.opacity(0.6))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(step)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        }
                    }
                    Label(section.destination, systemImage: "arrow.turn.up.right")
                        .font(.caption.bold())
                        .foregroundStyle(section.color)
                        .padding(.top, 4)
                }
            }
        }
        .cardStyle()
    }
}

struct OnboardingTourView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    @State private var step = 0

    private let tips: [(String, String, String)] = [
        ("Pick your sales vertical", "Your CRM, discovery map, and scripts adapt to your industry.", "building.2.fill"),
        ("Train with voice roleplay", "Practice against AI customers with natural HD voices and scoring.", "mic.fill"),
        ("Win in the field", "Pin locations, get proximity briefings, and navigate with Apple Maps.", "map.fill"),
        ("Use the full toolkit", "Forecasts, certifications, route planner, and skill gap analytics.", "star.circle.fill")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: tips[step].2)
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.brandGradient)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text(tips[step].0)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                Text(tips[step].1)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                ForEach(0..<tips.count, id: \.self) { i in
                    Capsule()
                        .fill(i == step ? AppTheme.electricBlueBright : AppTheme.textMuted.opacity(0.25))
                        .frame(width: i == step ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: step)
                }
            }

            HStack(spacing: 12) {
                if step > 0 {
                    SecondaryButton(title: "Back", icon: "chevron.left") {
                        step -= 1
                    }
                }
                PrimaryButton(title: step == tips.count - 1 ? "Get Started" : "Next", icon: step == tips.count - 1 ? "checkmark" : "arrow.right") {
                    if step < tips.count - 1 {
                        step += 1
                    } else {
                        isPresented = false
                    }
                }
            }
        }
        .padding(28)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.borderColor(for: colorScheme), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.25), radius: 30, y: 16)
        .padding(24)
    }
}
