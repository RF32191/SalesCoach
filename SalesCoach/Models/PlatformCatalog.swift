import Foundation

enum PlatformCategory: String, CaseIterable, Identifiable {
    case sell = "Sell"
    case coach = "Coach"
    case intelligence = "Intelligence"
    case enablement = "Enablement"
    case customer = "Customer Success"
    case marketing = "Marketing"
    case communications = "Communications"
    case automate = "Automation"
    case analyze = "Analytics"
    case team = "Team"
    case operate = "Operations"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sell: "cart.fill"
        case .coach: "sparkles"
        case .intelligence: "brain.head.profile"
        case .enablement: "books.vertical.fill"
        case .customer: "hand.thumbsup.fill"
        case .marketing: "megaphone.fill"
        case .communications: "phone.connection"
        case .automate: "arrow.triangle.branch"
        case .analyze: "chart.bar.xaxis"
        case .team: "person.3.fill"
        case .operate: "building.2.fill"
        }
    }

    var tint: String { rawValue }
}

enum PlatformDestination: String, Codable, Hashable, CaseIterable, Identifiable {
    case crm = "CRM Hub"
    case pipeline = "Sales Pipeline"
    case leadGen = "AI Lead Generation"
    case prospectResearch = "Prospect Research"
    case mapProspecting = "Map Prospecting"
    case aiCoach = "AI Sales Coach"
    case roleplay = "Roleplay Academy"
    case scriptMaker = "Script Maker"
    case repDNA = "Rep DNA"
    case conversationIntel = "Conversation Intelligence"
    case emotionalIntel = "Emotional Intelligence"
    case liveCopilot = "Live Call Co-Pilot"
    case dealHealth = "Deal Health Center"
    case closingPredictor = "Closing Predictor"
    case forecasting = "Revenue Forecasting"
    case businessIntel = "Business Intelligence"
    case winLoss = "Win/Loss Analysis"
    case competitorIntel = "Competitor Intelligence"
    case pricingAdvisor = "Pricing Advisor"
    case enablement = "Sales Enablement"
    case proposals = "Proposals & Quotes"
    case contracts = "Contract Management"
    case customerSuccess = "Customer Success"
    case customerPortal = "Customer Portal"
    case marketing = "Marketing Automation"
    case emailAssistant = "AI Email Assistant"
    case communications = "Communications Hub"
    case workflows = "Workflow Automation"
    case analytics = "Analytics Dashboard"
    case aiManager = "AI Sales Manager"
    case team = "Team Management"
    case leaderboard = "Leaderboard"
    case office = "Office & Accounting"
    case billing = "AI Billing Agent"
    case commission = "Commission Calculator"
    case integrations = "Integrations"
    case activityLog = "Activity Log"
    case crmImport = "CRM Import"
    case businessCard = "Business Card Scan"
    case digitalBusinessCard = "Digital Business Card"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .crm: "person.crop.rectangle.stack.fill"
        case .pipeline: "rectangle.3.group.fill"
        case .leadGen: "sparkle.magnifyingglass"
        case .prospectResearch: "doc.text.magnifyingglass"
        case .mapProspecting: "map.fill"
        case .aiCoach: "sparkles"
        case .roleplay: "mic.fill"
        case .scriptMaker: "text.book.closed.fill"
        case .repDNA: "person.crop.circle.badge.checkmark"
        case .conversationIntel: "waveform"
        case .emotionalIntel: "heart.text.square.fill"
        case .liveCopilot: "ear.fill"
        case .dealHealth: "heart.circle.fill"
        case .closingPredictor: "scope"
        case .forecasting: "chart.line.uptrend.xyaxis"
        case .businessIntel: "brain"
        case .winLoss: "arrow.triangle.branch"
        case .competitorIntel: "flag.2.crossed.fill"
        case .pricingAdvisor: "percent"
        case .enablement: "books.vertical.fill"
        case .proposals: "doc.richtext.fill"
        case .contracts: "signature"
        case .customerSuccess: "hand.thumbsup.fill"
        case .customerPortal: "person.crop.circle.badge.checkmark"
        case .marketing: "megaphone.fill"
        case .emailAssistant: "envelope.badge.fill"
        case .communications: "phone.connection"
        case .workflows: "arrow.triangle.branch"
        case .analytics: "chart.bar.xaxis"
        case .aiManager: "person.badge.shield.checkmark.fill"
        case .team: "person.3.fill"
        case .leaderboard: "trophy.fill"
        case .office: "building.2.fill"
        case .billing: "creditcard.fill"
        case .commission: "function"
        case .integrations: "link.circle.fill"
        case .activityLog: "clock.arrow.circlepath"
        case .crmImport: "square.and.arrow.down.fill"
        case .businessCard: "camera.viewfinder"
        case .digitalBusinessCard: "creditcard.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .crm: "Contacts, companies, deals, and global search"
        case .pipeline: "Kanban boards with AI deal scores"
        case .leadGen: "Enrichment, scoring, and ICP matching"
        case .prospectResearch: "Pre-meeting briefings and intel"
        case .mapProspecting: "Territory discovery on the map"
        case .aiCoach: "Chat coach and deal guidance"
        case .roleplay: "Voice roleplay with AI customers"
        case .scriptMaker: "AI talk tracks and scripts"
        case .repDNA: "Skill profile and daily drills"
        case .conversationIntel: "Call transcripts and analysis"
        case .emotionalIntel: "Tone, confidence, and empathy coaching"
        case .liveCopilot: "Real-time coaching during calls"
        case .dealHealth: "AI health scores for every deal"
        case .closingPredictor: "Close probability and next steps"
        case .forecasting: "Monthly, quarterly, and annual forecast"
        case .businessIntel: "Ask questions in natural language"
        case .winLoss: "Autopsy reports and executive summaries"
        case .competitorIntel: "Win rates and battle responses"
        case .pricingAdvisor: "Discounts, bundles, and upsells"
        case .enablement: "Playbooks, battle cards, and assets"
        case .proposals: "Quotes, proposals, and PDF export"
        case .contracts: "Renewals, signatures, and legal review"
        case .customerSuccess: "Health, churn risk, and success plans"
        case .customerPortal: "Client-facing proposals and support"
        case .marketing: "Campaigns, drips, and A/B tests"
        case .emailAssistant: "Outreach, follow-ups, and rewrites"
        case .communications: "Calls, email, SMS activity hub"
        case .workflows: "Visual automation builder"
        case .analytics: "Revenue, pipeline, and rep metrics"
        case .aiManager: "Team coaching and pipeline alerts"
        case .team: "Roles, territories, and quotas"
        case .leaderboard: "XP, rankings, and achievements"
        case .office: "Accounting, complaints, and ledger"
        case .billing: "Autonomous token billing agent"
        case .commission: "Payout and quota modeling"
        case .integrations: "Google, Microsoft, HubSpot, webhooks"
        case .activityLog: "Training and conversation history"
        case .crmImport: "HubSpot, Salesforce, CSV, vCard, JSON"
        case .businessCard: "Camera OCR contact capture"
        case .digitalBusinessCard: "Create and share your own card"
        }
    }

    var category: PlatformCategory {
        switch self {
        case .crm, .pipeline, .leadGen, .prospectResearch, .mapProspecting: .sell
        case .aiCoach, .roleplay, .scriptMaker, .repDNA, .conversationIntel, .emotionalIntel, .liveCopilot: .coach
        case .dealHealth, .closingPredictor, .forecasting, .businessIntel, .winLoss, .competitorIntel, .pricingAdvisor: .intelligence
        case .enablement, .proposals: .enablement
        case .customerSuccess, .customerPortal: .customer
        case .marketing, .emailAssistant: .marketing
        case .communications: .communications
        case .workflows: .automate
        case .analytics: .analyze
        case .aiManager, .team, .leaderboard: .team
        case .office, .billing, .commission, .contracts, .integrations, .activityLog, .crmImport, .businessCard, .digitalBusinessCard: .operate
        }
    }

    static var catalog: [PlatformDestination] { allCases }

    static func modules(in category: PlatformCategory) -> [PlatformDestination] {
        allCases.filter { $0.category == category }
    }

    static var quickAccess: [PlatformDestination] {
        [.crm, .aiCoach, .liveCopilot, .dealHealth, .proposals, .office]
    }
}

struct PlatformModuleItem: Identifiable, Hashable {
    let destination: PlatformDestination
    var id: String { destination.rawValue }
    var title: String { destination.rawValue }
    var subtitle: String { destination.subtitle }
    var icon: String { destination.icon }
    var category: PlatformCategory { destination.category }
}
