import Foundation
import SwiftUI

enum AppTutorialID: String, CaseIterable, Identifiable, Codable {
    case home
    case sellCRM
    case crmPipeline
    case crmActivity
    case crmTasks
    case crmList
    case crmCompanies
    case crmMap
    case coach
    case platform
    case more
    case aiCoach
    case roleplay
    case scriptMaker
    case repDNA
    case liveCopilot
    case dealHealth
    case forecasting
    case businessIntel
    case proposals
    case office
    case billing
    case integrations
    case crmImport
    case businessCards
    case digitalCard
    case leaderboard
    case subscription
    case settings

    var id: String { rawValue }

    var category: String {
        switch self {
        case .home: "Main Tabs"
        case .sellCRM, .crmPipeline, .crmActivity, .crmTasks, .crmList, .crmCompanies, .crmMap: "CRM"
        case .coach, .aiCoach, .roleplay, .scriptMaker, .repDNA, .liveCopilot: "Coach"
        case .platform, .dealHealth, .forecasting, .businessIntel, .proposals: "Platform"
        case .more, .settings, .subscription, .leaderboard: "Account"
        case .office, .billing, .integrations, .crmImport, .businessCards, .digitalCard: "Operations"
        }
    }
}

struct AppTutorial: Identifiable, Equatable {
    let id: String
    let helpID: AppTutorialID?
    let title: String
    let icon: String
    let accent: Color
    let summary: String
    let steps: [String]
    let proTips: [String]
    let whereToFind: String

    var category: String { helpID?.category ?? "Platform Modules" }
}

enum AppTutorialCatalog {
    static let all: [AppTutorial] = {
        var items = coreTutorials
        items.append(contentsOf: platformTutorials)
        return items.sorted { $0.category < $1.category || ($0.category == $1.category && $0.title < $1.title) }
    }()

    static func tutorial(for id: AppTutorialID) -> AppTutorial {
        all.first { $0.helpID == id } ?? fallback(for: id)
    }

    static func tutorials(in category: String) -> [AppTutorial] {
        all.filter { $0.category == category }
    }

    static var categories: [String] {
        Array(Set(all.map(\.category))).sorted()
    }

    private static let coreTutorials: [AppTutorial] = [
        AppTutorial(
            id: "home",
            helpID: .home,
            title: "Home Dashboard",
            icon: "house.fill",
            accent: AppTheme.electricBlueBright,
            summary: "Your Revenue OS command center — metrics, AI guidance, and quick access.",
            steps: [
                "Revenue Pulse shows today's numbers, pipeline, forecast, and win rate.",
                "Tap Customize to show/hide widgets and drag to reorder your layout.",
                "AI Recommendations surfaces your next best actions from CRM + training data.",
                "Quick Access jumps to CRM, Coach, Co-Pilot, Deal Health, Quotes, and Office.",
                "Tap Platform in the header to open the full module catalog."
            ],
            proTips: ["Pin hot deals from CRM to see them in Hot Opportunities.", "Check Rep DNA weekly for your skill focus."],
            whereToFind: "Home tab"
        ),
        AppTutorial(
            id: "sellCRM",
            helpID: .sellCRM,            title: "Sell — CRM Hub",
            icon: "cart.fill",
            accent: AppTheme.successGreen,
            summary: "Manage clients, pipeline, tasks, map prospecting, and activity in one workspace.",
            steps: [
                "Use the horizontal tabs: Dashboard, Pipeline, Activity, Tasks, List, Companies, Map.",
                "Search globally across names and companies from the top search bar.",
                "Tap + to add a client, or the import menu for CRM import and business card scan.",
                "Swipe a client row to call, email, star, or mark contacted.",
                "Open any client for deal health, AI next steps, location pins, and stage changes."
            ],
            proTips: ["Certification gates may block advanced stages until you pass training drills.", "Enable location pins for proximity briefings in the field."],
            whereToFind: "Sell tab"
        ),
        AppTutorial(
            id: "crmPipeline",
            helpID: .crmPipeline,            title: "Pipeline Board",
            icon: "rectangle.split.3x1.fill",
            accent: AppTheme.tealGreen,
            summary: "Kanban view of deals across every stage from Lead to Procurement.",
            steps: [
                "Scroll horizontally across stage columns.",
                "Each card shows value, health score, priority, and close probability.",
                "Tap a card to open full client details.",
                "Long-press a card to move stages or log a quick call.",
                "Watch deal health labels — At Risk deals need immediate follow-up."
            ],
            proTips: ["Move deals to Proposal only after certification if your team requires it."],
            whereToFind: "Sell → Pipeline"
        ),
        AppTutorial(
            id: "crmActivity",
            helpID: .crmActivity,            title: "Activity Inbox",
            icon: "phone.connection",
            accent: AppTheme.warningOrange,
            summary: "Unified feed of calls, emails, and logged touchpoints.",
            steps: [
                "Review recent communication across all clients.",
                "Tap an item to jump to the client record.",
                "Log activity from client detail to keep this feed accurate."
            ],
            proTips: ["Consistent logging improves AI recommendations and deal health scores."],
            whereToFind: "Sell → Activity"
        ),
        AppTutorial(
            id: "crmTasks",
            helpID: .crmTasks,            title: "CRM Tasks",
            icon: "checklist",
            accent: AppTheme.electricBlue,
            summary: "Follow-ups, overdue items, and action queue.",
            steps: [
                "See tasks due today, overdue, and upcoming.",
                "Complete tasks to keep pipeline momentum.",
                "Create tasks from client records for specific deals."
            ],
            proTips: ["Pair with Apple Calendar sync in Integrations for reminders."],
            whereToFind: "Sell → Tasks"
        ),
        AppTutorial(
            id: "crmList",
            helpID: .crmList,            title: "Client List",
            icon: "list.bullet",
            accent: AppTheme.electricBlueBright,
            summary: "Sortable, filterable list of every contact in your book.",
            steps: [
                "Filter by All, Favorites, Hot, Going Cold, or Overdue.",
                "Filter by deal stage using the stage chips.",
                "Change sort order from the toolbar menu.",
                "Swipe for quick call, email, star, or contacted actions."
            ],
            proTips: ["Mark priority Hot on urgent deals to surface them on Home."],
            whereToFind: "Sell → List"
        ),
        AppTutorial(
            id: "crmCompanies",
            helpID: .crmCompanies,            title: "Companies View",
            icon: "building.2.fill",
            accent: AppTheme.textSecondary,
            summary: "Group contacts and deals by organization.",
            steps: [
                "See total pipeline value per company.",
                "Expand a company to view all related contacts.",
                "Track multi-threaded enterprise deals in one place."
            ],
            proTips: ["Add competitor names on records for competitive intel tracking."],
            whereToFind: "Sell → Companies"
        ),
        AppTutorial(
            id: "crmMap",
            helpID: .crmMap,            title: "Map Prospecting",
            icon: "map.fill",
            accent: AppTheme.tealGreen,
            summary: "Territory map, discovery search, routes, and geofencing.",
            steps: [
                "View pinned clients on the map.",
                "Use Find Category Targets for vertical-matched discovery.",
                "Enable pin reminders for proximity alerts when nearby.",
                "Open Apple Maps for turn-by-turn navigation."
            ],
            proTips: ["Proximity briefings auto-surface when you enter a geofence."],
            whereToFind: "Sell → Map"
        ),
        AppTutorial(
            id: "coach",
            helpID: .coach,            title: "Coach Hub",
            icon: "sparkles",
            accent: AppTheme.tealGreen,
            summary: "Training, roleplay, scripts, Rep DNA, and live call coaching.",
            steps: [
                "Browse all coaching modules in the grid.",
                "Open Training Studio for roleplay + AI chat in one place.",
                "Coaching Toolkit has route planner, walk-in mode, and deal replay.",
                "Each module has its own tutorial — tap ? on any coach screen."
            ],
            proTips: ["Run one roleplay daily to keep certifications current."],
            whereToFind: "Coach tab"
        ),
        AppTutorial(
            id: "platform",
            helpID: .platform,            title: "Platform Catalog",
            icon: "square.grid.3x3.fill",
            accent: AppTheme.electricBlueBright,
            summary: "Every revenue tool organized by job — Sell, Coach, Intelligence, Operations, and more.",
            steps: [
                "Search modules by name or description.",
                "Browse 11 categories with 35+ modules.",
                "Tap any module card to open that feature.",
                "Use this as your master index when you can't find a tool."
            ],
            proTips: ["Pin frequent modules via Home Quick Access customization."],
            whereToFind: "Platform tab"
        ),
        AppTutorial(
            id: "more",
            helpID: .more,            title: "More Menu",
            icon: "ellipsis.circle.fill",
            accent: AppTheme.textMuted,
            summary: "Settings, billing, leaderboard, tutorials, and account tools.",
            steps: [
                "Open All Modules for the Platform catalog.",
                "Office and AI Billing Agent live under Platform section.",
                "Replay App Tour or open Tutorial Library anytime.",
                "Load example data from Settings to explore safely."
            ],
            proTips: ["Check Subscription Plans before heavy AI usage."],
            whereToFind: "More tab"
        ),
        AppTutorial(
            id: "aiCoach",
            helpID: .aiCoach,            title: "AI Sales Coach Chat",
            icon: "sparkles",
            accent: AppTheme.electricBlueBright,
            summary: "Ask for objection handling, talk tracks, negotiation help, and deal strategy.",
            steps: [
                "Type or dictate your question.",
                "Reference specific clients for contextual advice.",
                "Use after roleplay to debrief what to improve.",
                "Token usage applies — check Settings for AI backend status."
            ],
            proTips: ["Paste a call summary for tailored next-step coaching."],
            whereToFind: "Coach → AI Sales Coach"
        ),
        AppTutorial(
            id: "roleplay",
            helpID: .roleplay,            title: "Roleplay Academy",
            icon: "mic.fill",
            accent: AppTheme.warningOrange,
            summary: "Voice practice with AI buyers, personalities, and scored debriefs.",
            steps: [
                "Pick scenario: cold call, follow-up, closing, objection handling, etc.",
                "Choose personality: skeptical, busy exec, price-focused, angry, and more.",
                "Speak naturally — AI responds with HD voice in real time.",
                "Review score report: confidence, empathy, objections, and drill suggestions.",
                "Certifications unlock advanced CRM stages when enabled."
            ],
            proTips: ["Practice with a real CRM client loaded for deal-specific scenarios."],
            whereToFind: "Coach → Roleplay Academy"
        ),
        AppTutorial(
            id: "scriptMaker",
            helpID: .scriptMaker,            title: "Script Maker",
            icon: "text.book.closed.fill",
            accent: AppTheme.electricBlue,
            summary: "Generate talk tracks for calls, emails, voicemails, and objections.",
            steps: [
                "Select script type and target client.",
                "Add a custom angle for industry-specific output.",
                "Edit, save, and share generated scripts.",
                "Saved scripts appear below for reuse."
            ],
            proTips: ["Save winning scripts to team playbooks after closed deals."],
            whereToFind: "Coach → Script Maker"
        ),
        AppTutorial(
            id: "repDNA",
            helpID: .repDNA,            title: "Rep DNA",
            icon: "person.crop.circle.badge.checkmark",
            accent: AppTheme.tealGreen,
            summary: "Your skill profile, strengths, gaps, and weekly challenge.",
            steps: [
                "View skill scores from training + CRM performance.",
                "See weakest skill and recommended focus area.",
                "Complete weekly challenge for XP and badges.",
                "Rep DNA widget on Home tracks progress at a glance."
            ],
            proTips: ["Improve weak skills with targeted roleplay scenarios."],
            whereToFind: "Coach → Rep DNA"
        ),
        AppTutorial(
            id: "liveCopilot",
            helpID: .liveCopilot,            title: "Live Call Co-Pilot",
            icon: "ear.fill",
            accent: AppTheme.tealGreen,
            summary: "Real-time AI coaching tips while you speak on calls.",
            steps: [
                "Select the client you're speaking with.",
                "Tap Start Co-Pilot Session and allow microphone access.",
                "After you speak, AI suggests your next move.",
                "End session and review tips in Conversation Intelligence."
            ],
            proTips: ["Use in discovery calls before discussing price."],
            whereToFind: "Coach → Live Call Co-Pilot"
        ),
        AppTutorial(
            id: "dealHealth",
            helpID: .dealHealth,            title: "Deal Health Center",
            icon: "heart.circle.fill",
            accent: AppTheme.dangerRed,
            summary: "AI health scores with explainable risk factors per deal.",
            steps: [
                "Deals sorted by lowest health first.",
                "Tap any deal for full detail and next actions.",
                "Health considers follow-ups, activity, priority, and staleness."
            ],
            proTips: ["Fix overdue follow-ups first — biggest health lift."],
            whereToFind: "Platform → Intelligence → Deal Health"
        ),
        AppTutorial(
            id: "forecasting",
            helpID: .forecasting,            title: "Revenue Forecasting",
            icon: "chart.line.uptrend.xyaxis",
            accent: AppTheme.successGreen,
            summary: "Weighted pipeline and monthly trend outlook.",
            steps: [
                "See pipeline, weighted forecast, won revenue, and win rate.",
                "Review monthly trend for acquisitions and revenue won.",
                "Use with Business Intelligence for executive questions."
            ],
            proTips: ["Update deal probability sliders for accurate weighting."],
            whereToFind: "Platform → Intelligence → Revenue Forecasting"
        ),
        AppTutorial(
            id: "businessIntel",
            helpID: .businessIntel,            title: "Business Intelligence",
            icon: "brain",
            accent: AppTheme.electricBlue,
            summary: "Ask natural-language questions about your pipeline and team.",
            steps: [
                "Type a question or tap a sample prompt.",
                "AI analyzes your CRM snapshot and returns an executive brief.",
                "Use for standups, QBRs, and territory reviews."
            ],
            proTips: ["Try: \"Why are sales slowing?\" or \"Which rep needs coaching?\""],
            whereToFind: "Platform → Intelligence → Business Intelligence"
        ),
        AppTutorial(
            id: "proposals",
            helpID: .proposals,            title: "Proposals & Quotes",
            icon: "doc.richtext.fill",
            accent: AppTheme.electricBlueBright,
            summary: "AI-generated proposals ready to send or share.",
            steps: [
                "Select client, enter amount and scope.",
                "Generate proposal with AI.",
                "Edit output, then share or export.",
                "Saved proposals appear in Customer Portal for client sharing."
            ],
            proTips: ["Move deal to Proposal stage after sending."],
            whereToFind: "Platform → Enablement → Proposals & Quotes"
        ),
        AppTutorial(
            id: "office",
            helpID: .office,            title: "Office & Accounting",
            icon: "building.2.fill",
            accent: AppTheme.textSecondary,
            summary: "Ledger, complaints, scripts, and back-office workflows.",
            steps: [
                "Track commissions, expenses, invoices, and payments.",
                "Generate AI complaint responses for client issues.",
                "Use Script Maker for office-ready talk tracks.",
                "Review closed orders linked from CRM wins."
            ],
            proTips: ["Log token charges to reconcile AI usage costs."],
            whereToFind: "Platform → Operations → Office & Accounting"
        ),
        AppTutorial(
            id: "billing",
            helpID: .billing,            title: "AI Billing Agent",
            icon: "creditcard.fill",
            accent: AppTheme.warningOrange,
            summary: "Autonomous review of token usage and plan recommendations.",
            steps: [
                "See token charges by feature.",
                "Review AI agent recommendations for plan tier.",
                "Monitor usage against subscription limits."
            ],
            proTips: ["Connect Railway OpenAI key for live AI features."],
            whereToFind: "Platform → Operations → AI Billing Agent"
        ),
        AppTutorial(
            id: "integrations",
            helpID: .integrations,            title: "Integrations Hub",
            icon: "link.circle.fill",
            accent: AppTheme.electricBlueBright,
            summary: "HubSpot, Salesforce, Google Calendar, Zapier, and Apple Calendar.",
            steps: [
                "Connect each platform and save credentials locally.",
                "Import HubSpot/Salesforce CSV exports via CRM Import.",
                "Paste Zapier webhook URL to POST new leads automatically.",
                "Toggle Apple Calendar for follow-up event sync."
            ],
            proTips: ["Use Zapier to mirror leads into Google Sheets or Slack."],
            whereToFind: "Platform → Operations → Integrations"
        ),
        AppTutorial(
            id: "crmImport",
            helpID: .crmImport,            title: "CRM Import",
            icon: "square.and.arrow.down.fill",
            accent: AppTheme.tealGreen,
            summary: "Import from HubSpot, Salesforce, Pipedrive, Zoho, CSV, vCard, or JSON.",
            steps: [
                "Choose your source format.",
                "Select the exported file from your other CRM.",
                "Review import count and duplicate skips.",
                "Imported contacts appear in Sell tab immediately."
            ],
            proTips: ["Export deals + contacts together for best field mapping."],
            whereToFind: "Platform → Operations → CRM Import"
        ),
        AppTutorial(
            id: "businessCards",
            helpID: .businessCards,            title: "Business Cards",
            icon: "person.text.rectangle.fill",
            accent: AppTheme.electricBlueBright,
            summary: "Scan physical cards or create your own digital card.",
            steps: [
                "Scan with camera — OCR fills name, company, phone, email.",
                "Or create My Digital Card with themes and QR code.",
                "Save scanned contacts directly to CRM.",
                "Share digital card as text, vCard, or image."
            ],
            proTips: ["Share your digital card QR at networking events."],
            whereToFind: "Platform → Operations → Business Cards"
        ),
        AppTutorial(
            id: "digitalCard",
            helpID: .digitalCard,            title: "Digital Business Card",
            icon: "creditcard.fill",
            accent: AppTheme.tealGreen,
            summary: "Design, preview, and share your personal card.",
            steps: [
                "Fill in name, title, company, and contact info.",
                "Pick a theme color.",
                "Save card — generates QR code for contacts.",
                "Share via text, vCard file, or card image."
            ],
            proTips: ["Card prefills from your account profile on first open."],
            whereToFind: "More → Digital Business Card"
        ),
        AppTutorial(
            id: "leaderboard",
            helpID: .leaderboard,            title: "Leaderboard",
            icon: "trophy.fill",
            accent: AppTheme.warningOrange,
            summary: "XP, rankings, streaks, and team wins.",
            steps: [
                "See top reps by XP and activity.",
                "Earn XP from roleplay, CRM contacts, and closed deals.",
                "Compare team performance if on a team plan."
            ],
            proTips: ["Daily streaks boost motivation — log one activity per day."],
            whereToFind: "More → Leaderboard"
        ),
        AppTutorial(
            id: "subscription",
            helpID: .subscription,            title: "Subscription Plans",
            icon: "crown.fill",
            accent: AppTheme.electricBlueBright,
            summary: "Free, Pro, Team, and Enterprise tiers with token limits.",
            steps: [
                "Review monthly token, roleplay, and discovery limits.",
                "Upgrade for unlimited chat and team dashboard.",
                "Crown icon on Home shows your current tier."
            ],
            proTips: ["Pro unlocks 100K tokens/month for heavy AI usage."],
            whereToFind: "More → Subscription Plans"
        ),
        AppTutorial(
            id: "settings",
            helpID: .settings,            title: "Settings",
            icon: "gearshape.fill",
            accent: AppTheme.textMuted,
            summary: "Profile, vertical, data, and API configuration.",
            steps: [
                "Change sales team category to retarget discovery + scripts.",
                "Load or remove example data for safe exploration.",
                "Clear local CRM data if resetting your book.",
                "Check AI backend status: Railway, OpenAI, or Mock."
            ],
            proTips: ["Never commit API keys — use Xcode scheme env vars or Railway."],
            whereToFind: "More → Settings"
        )
    ]

    private static var platformTutorials: [AppTutorial] {
        PlatformDestination.allCases.compactMap { destination in
            if coreTutorialIDs.contains(mappedID(for: destination)) { return nil }
            return AppTutorial(
                id: "platform.\(destination.rawValue)",
                helpID: mappedID(for: destination),
                title: destination.rawValue,
                icon: destination.icon,
                accent: accent(for: destination.category),
                summary: destination.subtitle,
                steps: defaultSteps(for: destination),
                proTips: ["Open the ? button on this screen anytime for a refresher."],
                whereToFind: "Platform → \(destination.category.rawValue) → \(destination.rawValue)"
            )
        }
    }

    private static let coreTutorialIDs: Set<AppTutorialID> = Set(coreTutorials.compactMap(\.helpID))

    private static func mappedID(for destination: PlatformDestination) -> AppTutorialID {
        switch destination {
        case .crm: .sellCRM
        case .pipeline: .crmPipeline
        case .aiCoach: .aiCoach
        case .roleplay: .roleplay
        case .scriptMaker: .scriptMaker
        case .repDNA: .repDNA
        case .liveCopilot: .liveCopilot
        case .dealHealth: .dealHealth
        case .forecasting: .forecasting
        case .businessIntel: .businessIntel
        case .proposals: .proposals
        case .office: .office
        case .billing: .billing
        case .integrations: .integrations
        case .crmImport: .crmImport
        case .businessCard, .digitalBusinessCard: .businessCards
        case .leaderboard: .leaderboard
        default: .platform
        }
    }

    private static func accent(for category: PlatformCategory) -> Color {
        switch category {
        case .sell: AppTheme.successGreen
        case .coach: AppTheme.tealGreen
        case .intelligence: AppTheme.warningOrange
        case .enablement: AppTheme.electricBlue
        case .customer: AppTheme.electricBlueBright
        case .marketing: AppTheme.warningOrange
        case .communications: AppTheme.electricBlueBright
        case .automate: AppTheme.tealGreen
        case .analyze: AppTheme.successGreen
        case .team: AppTheme.electricBlue
        case .operate: AppTheme.textSecondary
        }
    }

    private static func defaultSteps(for destination: PlatformDestination) -> [String] {
        [
            destination.subtitle,
            "Use the fields and buttons on this screen to take action.",
            "Data syncs with your CRM and saves locally on this device.",
            "Tap ? in the toolbar if you need this tutorial again."
        ]
    }

    private static func fallback(for id: AppTutorialID) -> AppTutorial {
        AppTutorial(
            id: id.rawValue,
            helpID: id,
            title: id.rawValue.capitalized,
            icon: "questionmark.circle",
            accent: AppTheme.electricBlueBright,
            summary: "Learn how to use this part of Sales Coach AI.",
            steps: ["Explore the screen and tap help icons for guidance."],
            proTips: [],
            whereToFind: "Tutorial Library"
        )
    }
}

extension AppTutorialID {
    static func forCRMViewMode(_ mode: CRMView.CRMViewMode) -> AppTutorialID {
        switch mode {
        case .dashboard: .sellCRM
        case .pipeline: .crmPipeline
        case .activity: .crmActivity
        case .tasks: .crmTasks
        case .list: .crmList
        case .companies: .crmCompanies
        case .map: .crmMap
        }
    }
}

extension PlatformDestination {
    var tutorialID: AppTutorialID {
        switch self {
        case .crm: .sellCRM
        case .pipeline: .crmPipeline
        case .aiCoach: .aiCoach
        case .roleplay: .roleplay
        case .scriptMaker: .scriptMaker
        case .repDNA: .repDNA
        case .liveCopilot: .liveCopilot
        case .dealHealth: .dealHealth
        case .forecasting: .forecasting
        case .businessIntel: .businessIntel
        case .proposals: .proposals
        case .office: .office
        case .billing: .billing
        case .integrations: .integrations
        case .crmImport: .crmImport
        case .businessCard: .businessCards
        case .digitalBusinessCard: .digitalCard
        case .leaderboard: .leaderboard
        default: .platform
        }
    }
}
