import Foundation

enum DashboardWidgetKind: String, Codable, CaseIterable, Identifiable {
    case heroMetrics = "Revenue Pulse"
    case aiRecommendations = "AI Recommendations"
    case todaysPriorities = "Today's Priorities"
    case revenueMetrics = "Revenue Metrics"
    case pipelineForecast = "Pipeline & Forecast"
    case quotaProgress = "Quota Progress"
    case hotOpportunities = "Hot Opportunities"
    case dealsAtRisk = "Deals at Risk"
    case newLeads = "New Leads"
    case tasksAndFollowUps = "Tasks & Follow-Ups"
    case performanceStats = "Performance Stats"
    case customerHealth = "Customer Health"
    case recentActivity = "Recent Activity"
    case leaderboard = "Leaderboard"
    case repDNA = "Rep DNA"
    case gamification = "Achievements"
    case quickAccess = "Quick Access"
    case dailyMotivation = "Daily Motivation"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .heroMetrics: "waveform.path.ecg"
        case .aiRecommendations: "brain.head.profile"
        case .todaysPriorities: "list.star"
        case .revenueMetrics: "dollarsign.circle.fill"
        case .pipelineForecast: "chart.line.uptrend.xyaxis"
        case .quotaProgress: "target"
        case .hotOpportunities: "flame.fill"
        case .dealsAtRisk: "exclamationmark.triangle.fill"
        case .newLeads: "person.badge.plus"
        case .tasksAndFollowUps: "checklist"
        case .performanceStats: "chart.bar.fill"
        case .customerHealth: "heart.text.square.fill"
        case .recentActivity: "clock.arrow.circlepath"
        case .leaderboard: "trophy.fill"
        case .repDNA: "person.crop.circle.badge.checkmark"
        case .gamification: "star.circle.fill"
        case .quickAccess: "square.grid.2x2.fill"
        case .dailyMotivation: "quote.opening"
        }
    }

    var subtitle: String {
        switch self {
        case .heroMetrics: "Revenue today, pipeline, and win rate at a glance"
        case .aiRecommendations: "Proactive AI guidance for your day"
        case .todaysPriorities: "Meetings, follow-ups, and urgent actions"
        case .revenueMetrics: "Today, month, and year revenue"
        case .pipelineForecast: "Weighted pipeline and forecast contribution"
        case .quotaProgress: "Quota attainment and goal tracking"
        case .hotOpportunities: "High-priority deals to push today"
        case .dealsAtRisk: "Stale or low-health opportunities"
        case .newLeads: "Recently added prospects"
        case .tasksAndFollowUps: "Tasks, missed follow-ups, and emails"
        case .performanceStats: "Conversion, cycle length, and deal size"
        case .customerHealth: "Health scores across your book"
        case .recentActivity: "Latest CRM and coaching activity"
        case .leaderboard: "Team rankings and wins"
        case .repDNA: "Skill profile and weekly challenge"
        case .gamification: "XP, streaks, and badges"
        case .quickAccess: "One-tap access to core modules"
        case .dailyMotivation: "Daily coaching motivation"
        }
    }

    static var defaultLayout: [DashboardWidgetKind] {
        [
            .heroMetrics,
            .aiRecommendations,
            .todaysPriorities,
            .quotaProgress,
            .revenueMetrics,
            .pipelineForecast,
            .hotOpportunities,
            .dealsAtRisk,
            .performanceStats,
            .repDNA,
            .quickAccess,
            .recentActivity
        ]
    }
}

struct DashboardLayout: Codable, Equatable {
    var enabledWidgets: [DashboardWidgetKind]
    var hiddenWidgets: [DashboardWidgetKind]

    static let `default` = DashboardLayout(
        enabledWidgets: DashboardWidgetKind.defaultLayout,
        hiddenWidgets: DashboardWidgetKind.allCases.filter { !DashboardWidgetKind.defaultLayout.contains($0) }
    )
}

struct RevenueOSMetrics: Equatable {
    let revenueToday: Double
    let revenueMonth: Double
    let revenueYear: Double
    let pipelineValue: Double
    let weightedForecast: Double
    let quotaProgress: Double
    let quotaTarget: Double
    let quotaRevenue: Double
    let winRate: Double
    let conversionRate: Double
    let avgDealSize: Double
    let avgSalesCycleDays: Int
    let newLeadsThisWeek: Int
    let hotOpportunities: Int
    let dealsAtRisk: Int
    let missedFollowUps: Int
    let followUpsToday: Int
    let tasksDueToday: Int
    let tasksOverdue: Int
    let meetingsToday: Int
    let activeDeals: Int
    let avgHealthScore: Int
    let atRiskHealthCount: Int
}

enum RevenueOSPlatformModule: String, CaseIterable, Identifiable {
    case crm = "CRM"
    case aiCoach = "AI Sales Coach"
    case roleplay = "Roleplay Academy"
    case conversationIntel = "Conversation Intelligence"
    case dealHealth = "Deal Health"
    case forecasting = "Revenue Forecasting"
    case businessIntel = "Business Intelligence"
    case enablement = "Sales Enablement"
    case proposals = "Proposals & Quotes"
    case customerSuccess = "Customer Success"
    case marketing = "Marketing Automation"
    case communications = "Communications Hub"
    case automation = "Workflow Automation"
    case analytics = "Analytics"
    case team = "Team Management"
    case office = "Office & Billing"
    case leadGen = "AI Lead Generation"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .crm: "person.crop.rectangle.stack.fill"
        case .aiCoach: "sparkles"
        case .roleplay: "mic.fill"
        case .conversationIntel: "waveform"
        case .dealHealth: "heart.text.square.fill"
        case .forecasting: "chart.line.uptrend.xyaxis"
        case .businessIntel: "brain"
        case .enablement: "books.vertical.fill"
        case .proposals: "doc.text.fill"
        case .customerSuccess: "hand.thumbsup.fill"
        case .marketing: "megaphone.fill"
        case .communications: "phone.connection"
        case .automation: "arrow.triangle.branch"
        case .analytics: "chart.bar.xaxis"
        case .team: "person.3.fill"
        case .office: "building.2.fill"
        case .leadGen: "magnifyingglass"
        }
    }

    var isLive: Bool { true }

    var statusLabel: String { "Live" }
}
