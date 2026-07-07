import Foundation

struct AIRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let priority: Int
}

enum AIRecommendationEngine {
    static func recommendations(
        leads: [Lead],
        overdueFollowUps: [Lead],
        followUpsToday: [Lead],
        hotLeads: [Lead],
        overdueTasks: Int,
        roleplayCount: Int,
        averageScore: Int,
        pipelineValue: Double
    ) -> [AIRecommendation] {
        var items: [AIRecommendation] = []

        if !overdueFollowUps.isEmpty {
            items.append(AIRecommendation(
                title: "Follow up on overdue clients",
                detail: "\(overdueFollowUps.count) client\(overdueFollowUps.count == 1 ? "" : "s") need attention. Speed wins deals.",
                icon: "clock.badge.exclamationmark",
                priority: 1
            ))
        }

        if overdueTasks > 0 {
            items.append(AIRecommendation(
                title: "Complete overdue tasks",
                detail: "\(overdueTasks) task\(overdueTasks == 1 ? "" : "s") are past due. Clear your queue before new outreach.",
                icon: "checklist",
                priority: 2
            ))
        }

        if !hotLeads.isEmpty {
            items.append(AIRecommendation(
                title: "Push hot opportunities",
                detail: "\(hotLeads.count) high-priority deal\(hotLeads.count == 1 ? "" : "s") are active. Schedule the next step today.",
                icon: "flame.fill",
                priority: 3
            ))
        }

        if !followUpsToday.isEmpty {
            items.append(AIRecommendation(
                title: "Today's follow-ups",
                detail: "\(followUpsToday.count) client\(followUpsToday.count == 1 ? "" : "s") expect contact today.",
                icon: "calendar.badge.clock",
                priority: 4
            ))
        }

        if leads.isEmpty {
            items.append(AIRecommendation(
                title: "Add your first client",
                detail: "Pin a location and notes to unlock proximity briefings when you're nearby.",
                icon: "person.badge.plus",
                priority: 5
            ))
        }

        if roleplayCount == 0 {
            items.append(AIRecommendation(
                title: "Start AI roleplay training",
                detail: "Practice objections with realistic AI customers before your next call.",
                icon: "mic.fill",
                priority: 6
            ))
        } else if averageScore < 75 {
            items.append(AIRecommendation(
                title: "Sharpen your closing skills",
                detail: "Your avg score is \(averageScore). Run an advanced roleplay to level up.",
                icon: "chart.line.uptrend.xyaxis",
                priority: 7
            ))
        }

        if pipelineValue > 0, hotLeads.isEmpty, overdueFollowUps.isEmpty {
            items.append(AIRecommendation(
                title: "Review pipeline health",
                detail: "Check deal stages and update probabilities to keep your forecast accurate.",
                icon: "arrow.triangle.branch",
                priority: 8
            ))
        }

        if items.isEmpty {
            items.append(AIRecommendation(
                title: "You're on track",
                detail: "No urgent actions. Review your pipeline or practice a new scenario.",
                icon: "sparkles",
                priority: 99
            ))
        }

        if metricsAtRisk(dealsAtRisk: leads.filter { $0.dealStage.isActivePipeline && $0.dealHealthScore < 50 }.count) {
            items.append(AIRecommendation(
                title: "Rescue at-risk deals",
                detail: "Low health scores detected. Review deal replay and schedule recovery calls.",
                icon: "heart.slash.fill",
                priority: 2
            ))
        }

        if pipelineValue > 50_000, hotLeads.isEmpty {
            items.append(AIRecommendation(
                title: "Accelerate pipeline velocity",
                detail: "Strong pipeline value — identify bottlenecks in proposal and negotiation stages.",
                icon: "arrow.forward.circle.fill",
                priority: 9
            ))
        }

        return items.sorted { $0.priority < $1.priority }.prefix(5).map { $0 }
    }

    private static func metricsAtRisk(dealsAtRisk: Int) -> Bool {
        dealsAtRisk > 0
    }

    static func dailyMotivation(for category: SalesCategory?) -> String {
        let quotes = [
            "Every conversation is a chance to create value.",
            "Listen twice as much as you talk.",
            "Confidence comes from preparation — roleplay before you dial.",
            "Follow up fast. Momentum closes deals.",
            "Ask one more question before you pitch.",
            "The best closers solve problems, not push products."
        ]
        if let category {
            return "Focus on \(category.clientLabel) outcomes today. \(quotes.randomElement() ?? quotes[0])"
        }
        return quotes.randomElement() ?? quotes[0]
    }
}
