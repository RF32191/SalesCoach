import Foundation

@MainActor
final class DealCoachingService {
    static let shared = DealCoachingService()

    func generatePreCallBriefing(for lead: Lead, category: SalesCategory?) async throws -> PreCallBriefing {
        if AppConfig.isRailwayConfigured || AppConfig.isOpenAIConfigured {
            if let briefing = try? await OpenAIService.shared.requestPreCallBriefing(lead: lead, category: category) {
                return briefing
            }
        }
        return mockPreCallBriefing(for: lead)
    }

    func generatePostVisitDebrief(for lead: Lead, visitNotes: String) async throws -> PostVisitDebrief {
        if AppConfig.isRailwayConfigured || AppConfig.isOpenAIConfigured {
            if let debrief = try? await OpenAIService.shared.requestPostVisitDebrief(lead: lead, visitNotes: visitNotes) {
                return debrief
            }
        }
        return mockPostVisitDebrief(for: lead)
    }

    func analyzeCallTranscript(_ transcript: String) async -> CallAnalysisResult {
        if !transcript.isEmpty, AppConfig.isAIConfigured {
            if let result = try? await OpenAIService.shared.analyzeCallTranscript(transcript) {
                return result
            }
        }
        return mockCallAnalysis(transcript)
    }

    func arrivalChecklist(for lead: Lead, category: SalesCategory?) -> ArrivalChecklist {
        let hooks = lead.contactIntel.briefingFacts.map(\.value)
        let categoryName = category?.rawValue ?? lead.leadSource

        return ArrivalChecklist(
            items: [
                "Reference something personal (\(hooks.first ?? "their business priorities"))",
                "Confirm decision timeline and next step",
                "Handle top objection for \(categoryName)",
                "Log visit and schedule follow-up before leaving"
            ],
            talkTrack: lead.displayAIAction,
            closeAsk: "Based on what we discussed, should we schedule \(lead.dealStage == .negotiation ? "contract review" : "a follow-up demo") this week?"
        )
    }

    func personalityForLead(_ lead: Lead) -> CustomerPersonality {
        if lead.dealStage == .lost { return .angry }
        if !lead.competitorName.isEmpty { return .competitorLoyal }
        if lead.probabilityOfClosing >= 70 { return .interested }
        if lead.probabilityOfClosing < 35 { return .skeptical }
        if lead.dealValue >= 50_000 { return .busyExecutive }
        if lead.priority == .hot { return .interested }
        return .budgetConscious
    }

    func scenarioForLead(_ lead: Lead) -> TrainingScenario {
        switch lead.dealStage {
        case .newLead, .contacted: return .coldCall
        case .qualified, .proposalSent: return .followUp
        case .negotiation: return .closing
        case .won: return .upsell
        case .lost: return .lostCustomer
        }
    }

    private func mockPreCallBriefing(for lead: Lead) -> PreCallBriefing {
        PreCallBriefing(
            openingLine: "Hi \(lead.name.split(separator: " ").first.map(String.init) ?? lead.name), it's great to connect — I wanted to follow up on \(lead.company.isEmpty ? "our last conversation" : lead.company).",
            keyPoints: [
                lead.displayAIAction,
                "Deal stage: \(lead.dealStage.rawValue) at \(lead.probabilityOfClosing)% probability",
                "Pipeline value: $\(Int(lead.dealValue))"
            ],
            questionsToAsk: [
                "What's changed since we last spoke?",
                "Who else needs to weigh in on this decision?",
                "What would make moving forward a no-brainer for you?"
            ],
            closeLine: "Can we lock in the next step on the calendar before I leave?",
            personalHooks: lead.contactIntel.briefingFacts.map { "\($0.label): \($0.value)" }
        )
    }

    private func mockPostVisitDebrief(for lead: Lead) -> PostVisitDebrief {
        PostVisitDebrief(
            whatWentWell: ["Built rapport", "Confirmed pain points", "Got clarity on timeline"],
            improvements: ["Ask one more trial close", "Quantify ROI in their words"],
            nextStep: lead.displayAIAction,
            practicePrompt: "Practice handling '\(lead.objectionTags.first ?? "budget")' objection for \(lead.company.isEmpty ? lead.name : lead.company)"
        )
    }

    private func mockCallAnalysis(_ transcript: String) -> CallAnalysisResult {
        let words = transcript.split(separator: " ").count
        let questions = transcript.filter { $0 == "?" }.count
        return CallAnalysisResult.analyzeLocal(
            transcript: transcript,
            talkRatioPercent: min(85, max(35, words / 4)),
            questionsAsked: max(questions, transcript.lowercased().components(separatedBy: "?").count - 1),
            fillerWordCount: ["um", "uh", "like"].reduce(0) { $0 + transcript.lowercased().components(separatedBy: $1).count - 1 },
            overallScore: min(92, 55 + questions * 8),
            strengths: ["Clear structure", "Professional tone"],
            improvements: ["Pause after questions", "Use specific proof points"]
        )
    }
}
