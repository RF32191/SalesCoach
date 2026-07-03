import Foundation

/// Optional demo content — never loaded automatically. Users can load this from Settings to explore the app.
enum ExampleData {
    static let sampleCompanyNames: Set<String> = ["TechFlow Inc", "BuildRight Co", "Growth Labs"]
    static let sampleMemberEmails: Set<String> = [
        "alex@company.com", "jordan@company.com", "taylor@company.com", "casey@company.com"
    ]

    static func isExampleLead(_ lead: Lead) -> Bool {
        sampleCompanyNames.contains(lead.company)
    }

    static func isExampleTeamMember(_ member: TeamMember) -> Bool {
        sampleMemberEmails.contains(member.email.lowercased())
    }

    static func exampleLeads(ownerId: String) -> [Lead] {
        [
            Lead(
                ownerId: ownerId,
                name: "Sarah Chen",
                company: "TechFlow Inc",
                phone: "555-0101",
                email: "sarah@techflow.io",
                dealValue: 45000,
                dealStage: .qualified,
                notes: "Example client — interested in enterprise plan. Decision maker.",
                lastContactedDate: Calendar.current.date(byAdding: .day, value: -3, to: .now),
                nextFollowUpDate: Calendar.current.date(byAdding: .day, value: 2, to: .now),
                probabilityOfClosing: 65,
                aiRecommendedAction: "Send case study from similar SaaS company.",
                priority: .hot,
                contactIntel: ContactIntel(
                    interests: "AI automation, scaling outbound",
                    likes: "San Francisco Giants, craft coffee",
                    kidsNames: "Emma (8), Noah (5)",
                    conversationStarters: "Ask about their Series B hiring push"
                ),
                location: LeadLocation(
                    address: "123 Market St",
                    city: "San Francisco, CA",
                    latitude: 37.7937,
                    longitude: -122.3965,
                    locationLabel: "TechFlow HQ",
                    pinReminderEnabled: true
                )
            ),
            Lead(
                ownerId: ownerId,
                name: "Marcus Johnson",
                company: "BuildRight Co",
                phone: "555-0102",
                email: "marcus@buildright.com",
                dealValue: 12000,
                dealStage: .proposalSent,
                notes: "Example client — waiting on budget approval from CFO.",
                lastContactedDate: Calendar.current.date(byAdding: .day, value: -7, to: .now),
                nextFollowUpDate: Calendar.current.date(byAdding: .day, value: 1, to: .now),
                probabilityOfClosing: 40,
                aiRecommendedAction: "Follow up with ROI calculator for CFO.",
                priority: .warm,
                contactIntel: ContactIntel(
                    likes: "Local basketball, weekend fishing",
                    familyNotes: "Wife named Lisa, renovating their home"
                ),
                location: LeadLocation(
                    address: "555 Bryant St",
                    city: "San Francisco, CA",
                    latitude: 37.7823,
                    longitude: -122.3971,
                    locationLabel: "BuildRight Office"
                )
            ),
            Lead(
                ownerId: ownerId,
                name: "Emily Rodriguez",
                company: "Growth Labs",
                phone: "555-0103",
                email: "emily@growthlabs.co",
                dealValue: 78000,
                dealStage: .negotiation,
                notes: "Example client — negotiating contract terms. Very engaged.",
                lastContactedDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
                nextFollowUpDate: Calendar.current.date(byAdding: .day, value: 3, to: .now),
                probabilityOfClosing: 80,
                aiRecommendedAction: "Schedule final contract review call.",
                priority: .hot,
                location: LeadLocation(
                    address: "680 Folsom St",
                    city: "San Francisco, CA",
                    latitude: 37.7852,
                    longitude: -122.3960,
                    locationLabel: "Growth Labs"
                )
            )
        ]
    }

    static func exampleTeamMembers(teamId: String) -> [TeamMember] {
        [
            TeamMember(teamId: teamId, userId: "rep1", fullName: "Alex Rivera", email: "alex@company.com",
                       averageScore: 82, roleplaysCompleted: 24, closingScore: 78, improvementDelta: 15,
                       assignedScenarios: [.coldCall, .objectionHandling]),
            TeamMember(teamId: teamId, userId: "rep2", fullName: "Jordan Kim", email: "jordan@company.com",
                       averageScore: 91, roleplaysCompleted: 31, closingScore: 88, improvementDelta: 8,
                       assignedScenarios: [.closing]),
            TeamMember(teamId: teamId, userId: "rep3", fullName: "Taylor Brooks", email: "taylor@company.com",
                       averageScore: 74, roleplaysCompleted: 18, closingScore: 65, improvementDelta: 22,
                       assignedScenarios: [.followUp, .renewal]),
            TeamMember(teamId: teamId, userId: "rep4", fullName: "Casey Morgan", email: "casey@company.com",
                       averageScore: 86, roleplaysCompleted: 27, closingScore: 84, improvementDelta: 11,
                       assignedScenarios: [.upsell])
        ]
    }

    static func exampleDrills() -> [ManagerDrill] {
        [
            ManagerDrill(title: "Price objection drill", scenario: .objectionHandling, personality: .budgetConscious, dueDate: Calendar.current.date(byAdding: .day, value: 3, to: .now)!),
            ManagerDrill(title: "Executive pitch", scenario: .closing, personality: .busyExecutive, dueDate: Calendar.current.date(byAdding: .day, value: 5, to: .now)!)
        ]
    }

    static func examplePlaybooks() -> [PlaybookEntry] {
        [
            PlaybookEntry(title: "Feel-Felt-Found", content: "I understand how you feel. Others felt the same until they found...", category: "Objections"),
            PlaybookEntry(title: "Trial Close", content: "On a scale of 1-10, how ready are you? What gets you to a 10?", category: "Closing")
        ]
    }
}
