import Foundation

enum OpenAIError: LocalizedError {
    case notConfigured
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "OpenAI API key not configured."
        case .invalidResponse: "Invalid response from OpenAI."
        case .apiError(let message): message
        }
    }
}

final class OpenAIService {
    static let shared = OpenAIService()
    var onTokensUsed: ((Int) -> Void)?
    private init() {}

    private let coachSystemPrompt = """
    You are Sales Coach, an expert AI sales trainer and CRM assistant. Help users write scripts, \
    improve pitches, handle objections, and close deals. Be concise, actionable, and encouraging. \
    Use bullet points when listing steps. Never be generic—give specific language they can use on calls.
    """

    private let teamSalesPrompt = """
    This is an internal team sales log — reps announce closed deals to their sales team. Clients do NOT use this app. \
    When the user reports a closed sale or won deal, include a JSON action block at the END of your response:
    <!--ACTIONS
    {"reply":"your visible reply","actions":[{"type":"logSale","leadMatch":"Client or Company Name","dealValue":5000,"summary":"optional notes"}]}
    -->
    Only use action type logSale. Extract client/account name and dollar amount. Do NOT create leads, log calls, or schedule follow-ups from chat.
    """

    func chatWithTeamSales(
        messages: [ChatMessage],
        repName: String,
        teamMembers: [TeamMember],
        leads: [Lead]
    ) async throws -> ChatCRMResponse {
        let teamContext = teamMembers.prefix(8).map { "- \($0.fullName)" }.joined(separator: "\n")
        let leadContext = leads.prefix(8).map {
            "- \($0.name) @ \($0.company.isEmpty ? "no company" : $0.company)"
        }.joined(separator: "\n")

        let systemPrompt = coachSystemPrompt + "\n" + teamSalesPrompt
            + "\n\nRep logging sale: \(repName)"
            + "\nTeam members:\n" + (teamContext.isEmpty ? "(just you for now)" : teamContext)
            + "\n\nKnown CRM accounts (optional match):\n" + (leadContext.isEmpty ? "(none)" : leadContext)

        let apiMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ] + messages.map { ["role": $0.role.rawValue, "content": $0.content] }

        let raw: String
        if AppConfig.isRailwayConfigured {
            raw = try await requestRailwayTeamSalesChat(
                messages: messages,
                repName: repName,
                teamMembers: teamMembers,
                leads: leads
            )
        } else if AppConfig.isOpenAIConfigured {
            raw = try await requestCompletion(messages: apiMessages)
        } else {
            let last = messages.last?.content ?? ""
            let actions = SalesActionParser.parseTeamSale(from: last, leads: leads)
            return ChatCRMResponse(reply: mockChatResponse(for: last), actions: actions, actionResults: [])
        }

        if let payload = SalesActionParser.parseFromAIResponse(raw) {
            let visible = raw.components(separatedBy: "<!--ACTIONS").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? payload.reply
            return ChatCRMResponse(reply: visible.isEmpty ? payload.reply : visible, actions: payload.actions, actionResults: [])
        }

        let last = messages.last?.content ?? ""
        return ChatCRMResponse(
            reply: raw,
            actions: SalesActionParser.parseTeamSale(from: last, leads: leads),
            actionResults: []
        )
    }

    /// Legacy alias — use chatWithTeamSales.
    func chatWithCRMActions(messages: [ChatMessage], leads: [Lead]) async throws -> ChatCRMResponse {
        try await chatWithTeamSales(messages: messages, repName: "Rep", teamMembers: [], leads: leads)
    }

    func chat(messages: [ChatMessage]) async throws -> String {
        let apiMessages: [[String: String]] = [
            ["role": "system", "content": coachSystemPrompt]
        ] + messages.map { ["role": $0.role.rawValue, "content": $0.content] }

        if AppConfig.isRailwayConfigured {
            do {
                return try await requestRailwayChat(messages: messages)
            } catch {
                if AppConfig.demoModeEnabled, shouldFallbackToDemo(for: error) {
                    return demoModeNotice + mockChatResponse(for: messages.last?.content ?? "")
                }
                throw error
            }
        }
        if AppConfig.isOpenAIConfigured {
            return try await requestCompletion(messages: apiMessages)
        }
        return mockChatResponse(for: messages.last?.content ?? "")
    }

    func roleplayResponse(
        scenario: TrainingScenario,
        personality: CustomerPersonality,
        transcript: [RoleplayTranscriptEntry]
    ) async throws -> String {
        let result = try await roleplayTurn(
            scenario: scenario,
            personality: personality,
            transcript: transcript
        )
        return result.customerReply
    }

    func roleplayTurn(
        scenario: TrainingScenario,
        personality: CustomerPersonality,
        transcript: [RoleplayTranscriptEntry],
        closingProgress: Int = 0
    ) async throws -> RoleplayTurnResult {
        if AppConfig.isRailwayConfigured {
            do {
                return try await requestRailwayRoleplayTurn(
                    scenario: scenario,
                    personality: personality,
                    transcript: transcript,
                    closingProgress: closingProgress
                )
            } catch {
                if AppConfig.demoModeEnabled, shouldFallbackToDemo(for: error) {
                    return demoRoleplayFallback(
                        scenario: scenario,
                        personality: personality,
                        transcript: transcript,
                        closingProgress: closingProgress
                    )
                }
                throw error
            }
        }
        if AppConfig.isOpenAIConfigured {
            return try await requestRoleplayTurn(
                scenario: scenario,
                personality: personality,
                transcript: transcript,
                closingProgress: closingProgress
            )
        }

        let reply = mockRoleplayResponse(
            scenario: scenario,
            personality: personality,
            turn: transcript.count
        )
        let delta = estimateClosingDelta(
            scenario: scenario,
            personality: personality,
            transcript: transcript,
            closingProgress: closingProgress
        )
        let suggestion = mockSuggestion(
            scenario: scenario,
            personality: personality,
            closingProgress: closingProgress + delta,
            transcript: transcript
        )

        return RoleplayTurnResult(
            customerReply: reply,
            closingProgressDelta: delta,
            suggestion: suggestion
        )
    }

    func scoreSession(
        scenario: TrainingScenario,
        personality: CustomerPersonality,
        transcript: [RoleplayTranscriptEntry]
    ) async throws -> TrainingScoreReport {
        let transcriptText = transcript.map { "\($0.speaker): \($0.text)" }.joined(separator: "\n")
        let prompt = """
        Score this sales roleplay from 1-100. Scenario: \(scenario.rawValue). \
        Customer type: \(personality.rawValue).\n\nTranscript:\n\(transcriptText)\n\n\
        Return JSON with keys: overallScore (int), categories (array of {name, score}), \
        strengths (array), improvements (array), betterResponses (array), scriptSuggestions (array). \
        Categories: Confidence, Clarity, Listening, Rapport Building, Discovery Questions, \
        Objection Handling, Closing Ability, Professionalism, Product Knowledge.
        """

        if AppConfig.isRailwayConfigured {
            if let report = try await requestRailwayScore(
                scenario: scenario,
                personality: personality,
                transcript: transcript
            ) {
                return report
            }
        } else if AppConfig.isOpenAIConfigured {
            let response = try await requestCompletion(messages: [
                ["role": "system", "content": "You are a sales coach scoring roleplay sessions. Return valid JSON only."],
                ["role": "user", "content": prompt]
            ])
            if let report = parseScoreReport(from: response) {
                return report
            }
        }

        return mockScoreReport(scenario: scenario, transcript: transcript)
    }

    func generateFollowUp(type: FollowUpType, lead: Lead) async throws -> String {
        let prompt = """
        Generate a \(type.rawValue) for this lead:
        Name: \(lead.name), Company: \(lead.company), Stage: \(lead.dealStage.rawValue), \
        Value: $\(Int(lead.dealValue)), Notes: \(lead.notes).
        Make it professional, personalized, and ready to send.
        """

        if AppConfig.isRailwayConfigured {
            return try await requestRailwayFollowUp(type: type, lead: lead)
        }
        if AppConfig.isOpenAIConfigured {
            return try await requestCompletion(messages: [
                ["role": "system", "content": coachSystemPrompt],
                ["role": "user", "content": prompt]
            ])
        }
        return mockFollowUp(type: type, lead: lead)
    }

    func recommendNextAction(for lead: Lead) async throws -> String {
        let prompt = """
        Given this lead—Name: \(lead.name), Company: \(lead.company), Stage: \(lead.dealStage.rawValue), \
        Probability: \(lead.probabilityOfClosing)%, Last contacted: \(lead.lastContactedDate?.formatted() ?? "Never"), \
        Notes: \(lead.notes)—recommend ONE specific next action in one sentence.
        """

        if AppConfig.isRailwayConfigured {
            return try await requestRailwayNextAction(lead: lead)
        }
        if AppConfig.isOpenAIConfigured {
            return try await requestCompletion(messages: [
                ["role": "system", "content": coachSystemPrompt],
                ["role": "user", "content": prompt]
            ])
        }
        return "Schedule a 15-minute discovery call to understand their timeline and decision process."
    }

    func estimateClosingDelta(
        scenario: TrainingScenario,
        personality: CustomerPersonality,
        transcript: [RoleplayTranscriptEntry],
        closingProgress: Int
    ) -> Int {
        guard let lastUser = transcript.last(where: { $0.speaker == "You" }) else { return 0 }

        let text = lastUser.text.lowercased()
        var delta = 3

        if text.contains("?") { delta += 2 }
        if text.contains("understand") || text.contains("hear you") || text.contains("makes sense") {
            delta += 3
        }
        if text.contains("next step") || text.contains("move forward") || text.contains("schedule") {
            delta += 5
        }
        if text.contains("roi") || text.contains("value") || text.contains("save") || text.contains("results") {
            delta += 2
        }
        if text.contains("case study") || text.contains("example") || text.contains("client") {
            delta += 2
        }

        if text.contains("trust me") || text.contains("just buy") || text.contains("best product") {
            delta -= 5
        }
        if lastUser.text.count < 20 { delta -= 2 }

        switch personality {
        case .angry:
            if text.contains("sorry") || text.contains("apologize") || text.contains("frustrating") {
                delta += 4
            }
        case .budgetConscious:
            if text.contains("budget") || text.contains("cost") || text.contains("roi") || text.contains("invest") {
                delta += 3
            }
        case .skeptical:
            if text.contains("proof") || text.contains("data") || text.contains("study") {
                delta += 3
            }
        case .busyExecutive:
            if text.contains("minute") || text.contains("bottom line") || text.contains("quick") {
                delta += 2
            }
        case .competitorLoyal:
            if text.contains("switch") || text.contains("compare") || text.contains("difference") {
                delta += 3
            }
        case .firstTimeBuyer:
            if text.contains("help") || text.contains("guide") || text.contains("recommend") {
                delta += 3
            }
        case .interested:
            if text.contains("start") || text.contains("demo") || text.contains("trial") {
                delta += 4
            }
        }

        switch scenario {
        case .closing, .objectionHandling:
            if text.contains("ready") || text.contains("sign") || text.contains("proposal") {
                delta += 3
            }
        case .coldCall, .doorToDoor:
            if text.contains("reason") || text.contains("quick question") {
                delta += 2
            }
        default:
            break
        }

        if closingProgress > 80 {
            delta = max(delta - 2, -5)
        }

        return min(15, max(-10, delta))
    }

    func mockSuggestion(
        scenario: TrainingScenario,
        personality: CustomerPersonality,
        closingProgress: Int,
        transcript: [RoleplayTranscriptEntry]
    ) -> String {
        let progress = min(100, max(0, closingProgress))

        if progress < 25 {
            return "Open with empathy and ask one open-ended question about their current situation."
        }
        if progress < 50 {
            switch personality {
            case .angry:
                return "Validate their frustration before presenting any solution."
            case .budgetConscious:
                return "Quantify value in dollars saved or revenue gained, not features."
            case .skeptical:
                return "Offer a specific proof point—a metric, case study, or reference."
            case .busyExecutive:
                return "Lead with the business outcome in one sentence, then pause."
            default:
                return "Mirror their words back, then bridge to a relevant benefit."
            }
        }
        if progress < 75 {
            switch scenario {
            case .objectionHandling, .closing:
                return "Use a trial close: 'What would need to be true for you to move forward this week?'"
            case .followUp, .renewal:
                return "Reference your last conversation and propose a concrete next step with a date."
            default:
                return "Summarize the value you've uncovered and ask if it aligns with their goals."
            }
        }

        let userTurns = transcript.filter { $0.speaker == "You" }.count
        if userTurns >= 4 && progress >= 75 {
            return "Ask for the commitment directly: propose a specific date to finalize."
        }
        return "Confirm remaining concerns, then ask for a clear yes/no on moving forward."
    }

    private func requestRoleplayTurn(
        scenario: TrainingScenario,
        personality: CustomerPersonality,
        transcript: [RoleplayTranscriptEntry],
        closingProgress: Int
    ) async throws -> RoleplayTurnResult {
        let system = """
        You are roleplaying as a \(personality.rawValue) in a \(scenario.rawValue) sales scenario. \
        Stay in character. \(personality.description)
        Current closing progress: \(closingProgress)/100.
        Return valid JSON only with keys:
        - customerReply (string, 1-3 sentences, in character)
        - closingProgressDelta (int, -10 to 15, how much the rep's last message moved the deal)
        - suggestion (string, one actionable coaching tip for the sales rep)
        """

        var apiMessages: [[String: String]] = [["role": "system", "content": system]]
        for entry in transcript {
            let role = entry.speaker == "You" ? "user" : "assistant"
            apiMessages.append(["role": role, "content": entry.text])
        }

        let response = try await requestCompletion(messages: apiMessages)
        if let result = parseRoleplayTurn(from: response) {
            return result
        }

        let reply = mockRoleplayResponse(
            scenario: scenario,
            personality: personality,
            turn: transcript.count
        )
        let delta = estimateClosingDelta(
            scenario: scenario,
            personality: personality,
            transcript: transcript,
            closingProgress: closingProgress
        )
        let suggestion = mockSuggestion(
            scenario: scenario,
            personality: personality,
            closingProgress: closingProgress + delta,
            transcript: transcript
        )
        return RoleplayTurnResult(
            customerReply: reply,
            closingProgressDelta: delta,
            suggestion: suggestion
        )
    }

    private func parseRoleplayTurn(from json: String) -> RoleplayTurnResult? {
        let cleaned = json
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reply = dict["customerReply"] as? String else {
            return nil
        }

        let delta = dict["closingProgressDelta"] as? Int ?? 0
        let suggestion = dict["suggestion"] as? String ?? ""
        let clampedDelta = min(15, max(-10, delta))

        return RoleplayTurnResult(
            customerReply: reply.trimmingCharacters(in: .whitespacesAndNewlines),
            closingProgressDelta: clampedDelta,
            suggestion: suggestion.isEmpty ? "Listen actively and ask a follow-up question." : suggestion
        )
    }

    func synthesizeSpeech(text: String, voice: String, speed: Double, model: String = OpenAITTSModel.hd.rawValue) async throws -> Data {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw OpenAIError.invalidResponse }

        if AppConfig.isRailwayConfigured {
            let json = try await postRailway(path: "tts", body: [
                "text": trimmed,
                "voice": voice,
                "speed": speed,
                "model": model
            ])
            guard let base64 = json["audioBase64"] as? String,
                  let data = Data(base64Encoded: base64) else {
                throw OpenAIError.invalidResponse
            }
            recordTokens(from: json, fallbackInput: trimmed)
            return data
        }

        throw OpenAIError.notConfigured
    }

    private func recordTokens(_ count: Int, fallbackInput: String = "", fallbackOutput: String = "") {
        let tokens = count > 0 ? count : SubscriptionService.estimateTokens(input: fallbackInput, output: fallbackOutput)
        onTokensUsed?(tokens)
    }

    private func recordTokens(from json: [String: Any], fallbackInput: String = "", fallbackOutput: String = "") {
        let count = json["tokensUsed"] as? Int ?? 0
        recordTokens(count, fallbackInput: fallbackInput, fallbackOutput: fallbackOutput)
    }

    private func requestRailwayChat(messages: [ChatMessage]) async throws -> String {
        let payload: [[String: String]] = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        let json = try await postRailway(path: "chat", body: ["messages": payload])
        guard let content = json["content"] as? String else { throw OpenAIError.invalidResponse }
        recordTokens(from: json, fallbackInput: messages.map(\.content).joined(), fallbackOutput: content)
        return content
    }

    private func requestRailwayTeamSalesChat(
        messages: [ChatMessage],
        repName: String,
        teamMembers: [TeamMember],
        leads: [Lead]
    ) async throws -> String {
        let payload: [[String: String]] = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        let teamPayload = teamMembers.prefix(8).map { ["name": $0.fullName] as [String: Any] }
        let leadPayload = leads.prefix(8).map { [
            "name": $0.name,
            "company": $0.company
        ] as [String: Any] }
        let json = try await postRailway(path: "chat/team-sales", body: [
            "messages": payload,
            "repName": repName,
            "teamMembers": teamPayload,
            "leads": leadPayload
        ])
        if let reply = json["reply"] as? String, let actions = json["actions"] as? [[String: Any]], !actions.isEmpty {
            let encoded = (try? JSONSerialization.data(withJSONObject: ["reply": reply, "actions": actions])) ?? Data()
            let actionBlock = String(data: encoded, encoding: .utf8) ?? ""
            return reply + "\n<!--ACTIONS\n" + actionBlock + "\n-->"
        }
        guard let content = json["content"] as? String ?? json["reply"] as? String else {
            throw OpenAIError.invalidResponse
        }
        recordTokens(from: json, fallbackInput: messages.map(\.content).joined(), fallbackOutput: content)
        return content
    }

    private func requestRailwayCRMChat(messages: [ChatMessage], leads: [Lead]) async throws -> String {
        try await requestRailwayTeamSalesChat(messages: messages, repName: "Rep", teamMembers: [], leads: leads)
    }

    private func requestRailwayRoleplayTurn(
        scenario: TrainingScenario,
        personality: CustomerPersonality,
        transcript: [RoleplayTranscriptEntry],
        closingProgress: Int
    ) async throws -> RoleplayTurnResult {
        let transcriptPayload = transcript.map { ["speaker": $0.speaker, "text": $0.text] }
        let json = try await postRailway(path: "roleplay/turn", body: [
            "scenario": scenario.rawValue,
            "personality": personality.rawValue,
            "personalityDescription": personality.description,
            "transcript": transcriptPayload,
            "closingProgress": closingProgress
        ])

        guard let reply = json["customerReply"] as? String else { throw OpenAIError.invalidResponse }
        recordTokens(from: json, fallbackOutput: reply)
        let delta = json["closingProgressDelta"] as? Int ?? 0
        let suggestion = json["suggestion"] as? String ?? "Listen actively and ask a follow-up question."

        return RoleplayTurnResult(
            customerReply: reply,
            closingProgressDelta: min(15, max(-10, delta)),
            suggestion: suggestion
        )
    }

    private func requestRailwayScore(
        scenario: TrainingScenario,
        personality: CustomerPersonality,
        transcript: [RoleplayTranscriptEntry]
    ) async throws -> TrainingScoreReport? {
        let transcriptPayload = transcript.map { ["speaker": $0.speaker, "text": $0.text] }
        let json = try await postRailway(path: "roleplay/score", body: [
            "scenario": scenario.rawValue,
            "personality": personality.rawValue,
            "transcript": transcriptPayload
        ])

        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let raw = String(data: data, encoding: .utf8) else { return nil }
        recordTokens(from: json)
        return parseScoreReport(from: raw)
    }

    private func requestRailwayFollowUp(type: FollowUpType, lead: Lead) async throws -> String {
        let leadData = try encodeLead(lead)
        let json = try await postRailway(path: "crm/follow-up", body: [
            "type": type.rawValue,
            "lead": leadData
        ])
        guard let content = json["content"] as? String else { throw OpenAIError.invalidResponse }
        recordTokens(from: json, fallbackOutput: content)
        return content
    }

    private func requestRailwayNextAction(lead: Lead) async throws -> String {
        let leadData = try encodeLead(lead)
        let json = try await postRailway(path: "crm/next-action", body: ["lead": leadData])
        guard let content = json["content"] as? String else { throw OpenAIError.invalidResponse }
        recordTokens(from: json, fallbackOutput: content)
        return content
    }

    func requestPreCallBriefing(lead: Lead, category: SalesCategory?) async throws -> PreCallBriefing {
        let leadData = try encodeLead(lead)
        if AppConfig.isRailwayConfigured {
            let json = try await postRailway(path: "crm/pre-call-briefing", body: [
                "lead": leadData,
                "category": category?.rawValue ?? lead.leadSource
            ])
            return parsePreCallBriefing(json)
        }
        let prompt = "Generate a pre-call briefing JSON for lead \(lead.name) at \(lead.company). Keys: openingLine, keyPoints[], questionsToAsk[], closeLine, personalHooks[]"
        let response = try await requestCompletion(messages: [
            ["role": "system", "content": "Return valid JSON only."],
            ["role": "user", "content": prompt]
        ])
        return parsePreCallBriefingJSON(response) ?? PreCallBriefing(
            openingLine: "Hi \(lead.name), thanks for taking my call.",
            keyPoints: [lead.displayAIAction],
            questionsToAsk: ["What's your timeline?"],
            closeLine: "Can we schedule next steps?",
            personalHooks: lead.contactIntel.briefingFacts.map { $0.value }
        )
    }

    func requestPostVisitDebrief(lead: Lead, visitNotes: String) async throws -> PostVisitDebrief {
        let leadData = try encodeLead(lead)
        if AppConfig.isRailwayConfigured {
            let json = try await postRailway(path: "crm/post-visit-debrief", body: [
                "lead": leadData,
                "visitNotes": visitNotes
            ])
            return parsePostVisitDebrief(json)
        }
        return PostVisitDebrief(
            whatWentWell: ["Engaged the contact", "Confirmed next steps"],
            improvements: ["Ask more discovery questions"],
            nextStep: lead.displayAIAction,
            practicePrompt: "Practice objection handling for \(lead.company)"
        )
    }

    func analyzeCallTranscript(_ transcript: String) async throws -> CallAnalysisResult {
        if AppConfig.isRailwayConfigured {
            let json = try await postRailway(path: "training/analyze-call", body: ["transcript": transcript])
            return parseCallAnalysis(json)
        }
        return CallAnalysisResult.analyzeLocal(
            transcript: transcript,
            talkRatioPercent: 58,
            questionsAsked: transcript.filter { $0 == "?" }.count,
            fillerWordCount: 3,
            overallScore: 74,
            strengths: ["Professional tone"],
            improvements: ["Ask more open questions"]
        )
    }

    private func parsePreCallBriefing(_ json: [String: Any]) -> PreCallBriefing {
        PreCallBriefing(
            openingLine: json["openingLine"] as? String ?? "",
            keyPoints: json["keyPoints"] as? [String] ?? [],
            questionsToAsk: json["questionsToAsk"] as? [String] ?? [],
            closeLine: json["closeLine"] as? String ?? "",
            personalHooks: json["personalHooks"] as? [String] ?? []
        )
    }

    private func parsePreCallBriefingJSON(_ json: String) -> PreCallBriefing? {
        let cleaned = json.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
        guard let data = cleaned.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return parsePreCallBriefing(dict)
    }

    private func parsePostVisitDebrief(_ json: [String: Any]) -> PostVisitDebrief {
        PostVisitDebrief(
            whatWentWell: json["whatWentWell"] as? [String] ?? [],
            improvements: json["improvements"] as? [String] ?? [],
            nextStep: json["nextStep"] as? String ?? "",
            practicePrompt: json["practicePrompt"] as? String ?? ""
        )
    }

    private func parseCallAnalysis(_ json: [String: Any]) -> CallAnalysisResult {
        let transcript = json["transcript"] as? String ?? ""
        return CallAnalysisResult.analyzeLocal(
            transcript: transcript,
            talkRatioPercent: json["talkRatioPercent"] as? Int ?? 50,
            questionsAsked: json["questionsAsked"] as? Int ?? 0,
            fillerWordCount: json["fillerWordCount"] as? Int ?? 0,
            overallScore: json["overallScore"] as? Int ?? 70,
            strengths: json["strengths"] as? [String] ?? [],
            improvements: json["improvements"] as? [String] ?? []
        )
    }

    private func encodeLead(_ lead: Lead) throws -> [String: Any] {
        let data = try JSONEncoder().encode(lead)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OpenAIError.invalidResponse
        }
        return dict
    }

    private func postRailway(path: String, body: [String: Any]) async throws -> [String: Any] {
        let base = AppConfig.railwayAPIURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/api/\(path)") else {
            throw OpenAIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !AppConfig.railwayAPIKey.isEmpty {
            request.setValue(AppConfig.railwayAPIKey, forHTTPHeaderField: "X-API-Key")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw OpenAIError.invalidResponse }

        if http.statusCode >= 400 {
            throw OpenAIError.apiError(parseAPIErrorMessage(data: data, statusCode: http.statusCode))
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OpenAIError.invalidResponse
        }
        return json
    }

    private func requestCompletion(messages: [[String: String]]) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw OpenAIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.7
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw OpenAIError.invalidResponse }

        if http.statusCode >= 400 {
            throw OpenAIError.apiError(parseAPIErrorMessage(data: data, statusCode: http.statusCode))
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }

        let inputText = messages.compactMap { $0["content"] }.joined()
        if let usage = json["usage"] as? [String: Any],
           let total = usage["total_tokens"] as? Int {
            recordTokens(total, fallbackInput: inputText, fallbackOutput: content)
        } else {
            recordTokens(0, fallbackInput: inputText, fallbackOutput: content)
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var demoModeNotice: String {
        "⚠️ Live AI is offline — showing demo coaching. Set a valid OPENAI_API_KEY on Railway.\n\n"
    }

    private func shouldFallbackToDemo(for error: Error) -> Bool {
        guard case OpenAIError.apiError(let message) = error else { return false }
        let lower = message.lowercased()
        return lower.contains("incorrect api key")
            || lower.contains("openai api key")
            || lower.contains("openai_key_invalid")
            || lower.contains("unauthorized")
            || lower.contains("not configured")
            || lower.contains("live ai is offline")
    }

    private func demoRoleplayFallback(
        scenario: TrainingScenario,
        personality: CustomerPersonality,
        transcript: [RoleplayTranscriptEntry],
        closingProgress: Int
    ) -> RoleplayTurnResult {
        let reply = mockRoleplayResponse(
            scenario: scenario,
            personality: personality,
            turn: transcript.count
        )
        let delta = estimateClosingDelta(
            scenario: scenario,
            personality: personality,
            transcript: transcript,
            closingProgress: closingProgress
        )
        let suggestion = mockSuggestion(
            scenario: scenario,
            personality: personality,
            closingProgress: closingProgress + delta,
            transcript: transcript
        )
        return RoleplayTurnResult(
            customerReply: reply,
            closingProgressDelta: delta,
            suggestion: suggestion
        )
    }

    private func parseAPIErrorMessage(data: Data, statusCode: Int) -> String {
        let raw = String(data: data, encoding: .utf8) ?? "API error"

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? String {
            if error.contains("Incorrect API key") || error.contains("OPENAI") {
                return "Railway OpenAI key is invalid. In Railway → Variables, set OPENAI_API_KEY to a real key from platform.openai.com/api-keys."
            }
            if statusCode == 401 && error == "Unauthorized" {
                return "Railway API key mismatch. Match LocalSecrets.railwayAPIKey with Railway API_SECRET."
            }
            return error
        }

        if raw.contains("Incorrect API key") {
            return "Railway OpenAI key is invalid. Update OPENAI_API_KEY in Railway variables."
        }
        if statusCode == 401 {
            return "Railway API key mismatch. Update LocalSecrets.railwayAPIKey to match Railway API_SECRET."
        }
        return raw
    }

    private func parseScoreReport(from json: String) -> TrainingScoreReport? {
        let cleaned = json
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let overall = dict["overallScore"] as? Int ?? 75
        let categoriesRaw = dict["categories"] as? [[String: Any]] ?? []
        let categories = categoriesRaw.compactMap { item -> ScoreCategory? in
            guard let name = item["name"] as? String, let score = item["score"] as? Int else { return nil }
            return ScoreCategory(name: name, score: score)
        }

        return TrainingScoreReport(
            sessionId: UUID().uuidString,
            overallScore: overall,
            categories: categories.isEmpty ? defaultCategories(base: overall) : categories,
            strengths: dict["strengths"] as? [String] ?? [],
            improvements: dict["improvements"] as? [String] ?? [],
            betterResponses: dict["betterResponses"] as? [String] ?? [],
            scriptSuggestions: dict["scriptSuggestions"] as? [String] ?? []
        )
    }

    private func defaultCategories(base: Int) -> [ScoreCategory] {
        let names = ["Confidence", "Clarity", "Listening", "Rapport Building", "Discovery Questions",
                     "Objection Handling", "Closing Ability", "Professionalism", "Product Knowledge"]
        return names.map { ScoreCategory(name: $0, score: base + Int.random(in: -10...10)) }
    }

    private func mockChatResponse(for input: String) -> String {
        let lower = input.lowercased()
        if lower.contains("objection") || lower.contains("price") {
            return """
            Great question on pricing objections. Try the **Feel-Felt-Found** framework:

            1. **Acknowledge**: "I completely understand budget is a priority."
            2. **Relate**: "Other clients felt the same until they saw the ROI."
            3. **Reframe**: "What they found was the cost of *not* solving this was 3x higher."

            Would you like a script tailored to your specific product?
            """
        }
        if lower.contains("close") || lower.contains("closing") {
            return """
            Here are three closing techniques to practice:

            • **Assumptive close**: "Should we start with the starter plan or the full package?"
            • **Summary close**: Recap value, then ask "Ready to move forward?"
            • **Trial close**: "On a scale of 1-10, how ready are you? What would get you to a 10?"

            Pick one and roleplay it in the Train tab!
            """
        }
        return """
        I'm your AI Sales Coach. I can help you:

        • Write and refine sales scripts
        • Handle tough objections
        • Plan follow-ups and closing strategies
        • Analyze your roleplay performance

        What would you like to work on today?
        """
    }

    private func mockRoleplayResponse(
        scenario: TrainingScenario,
        personality: CustomerPersonality,
        turn: Int
    ) -> String {
        let responses: [CustomerPersonality: [String]] = [
            .angry: [
                "Look, I've been burned before. Why should I trust you?",
                "Your competitor promised the same thing and failed.",
                "I'm not interested unless you can prove this actually works."
            ],
            .budgetConscious: [
                "What's this going to cost me? I need numbers.",
                "We have a strict budget this quarter.",
                "Can you justify the ROI in plain terms?"
            ],
            .interested: [
                "Tell me more—this sounds like what we need.",
                "How quickly could we get started?",
                "What does onboarding look like?"
            ],
            .skeptical: [
                "I've heard these claims before. Where's your proof?",
                "Can you share case studies from companies our size?",
                "What happens if it doesn't deliver?"
            ],
            .busyExecutive: [
                "I've got two minutes. What's the bottom line?",
                "Skip the features—what's the business impact?",
                "Send me a one-pager. I'm running to a meeting."
            ],
            .competitorLoyal: [
                "We're happy with our current vendor.",
                "Switching costs time and money we don't have.",
                "What would make this worth the hassle?"
            ],
            .firstTimeBuyer: [
                "I'm not even sure what we need yet.",
                "This is all new to me—can you simplify?",
                "What questions should I be asking?"
            ]
        ]
        let lines = responses[personality] ?? ["I'm listening. Go on."]
        return lines[min(turn / 2, lines.count - 1)]
    }

    private func mockScoreReport(scenario: TrainingScenario, transcript: [RoleplayTranscriptEntry]) -> TrainingScoreReport {
        let userTurns = transcript.filter { $0.speaker == "You" }.count
        let base = min(95, 55 + userTurns * 8 + Int.random(in: 0...10))

        return TrainingScoreReport(
            sessionId: UUID().uuidString,
            overallScore: base,
            categories: defaultCategories(base: base),
            strengths: [
                "Opened with confidence and a clear value proposition",
                "Asked relevant discovery questions",
                "Maintained professional tone throughout"
            ],
            improvements: [
                "Pause more after asking questions to let the customer respond",
                "Use more specific proof points instead of general claims",
                "Try a trial close before ending the \(scenario.rawValue.lowercased())"
            ],
            betterResponses: [
                "Instead of 'Our product is great,' try 'Clients like [Company] saw a 23% increase in pipeline within 90 days.'",
                "When they push back on price, ask 'What would success look like for you in the first 6 months?'"
            ],
            scriptSuggestions: [
                "Add a pattern interrupt in your opening: 'I'll be brief—I noticed [specific insight about their business].'",
                "End with a clear next step: 'Can we schedule 15 minutes Thursday to walk through a tailored proposal?'"
            ]
        )
    }

    private func mockFollowUp(type: FollowUpType, lead: Lead) -> String {
        switch type {
        case .text:
            return "Hi \(lead.name), following up on our conversation about \(lead.company). I have a few ideas that could help with your current goals—do you have 10 minutes this week?"
        case .coldEmail:
            return """
            Subject: Idea for \(lead.company)

            Hi \(lead.name),

            I work with \(lead.leadSource.isEmpty ? "teams like yours" : lead.leadSource) and noticed an opportunity to improve outcomes at \(lead.company).

            Open to a 10-minute intro call this week?

            Best regards
            """
        case .followUpEmail:
            return """
            Subject: Quick follow-up for \(lead.company)

            Hi \(lead.name),

            I wanted to follow up on our recent conversation. Based on what you shared, I believe we can help \(lead.company) achieve meaningful results at the \(lead.dealStage.rawValue) stage.

            Would you be open to a brief call this week to explore next steps?

            Best regards
            """
        case .meetingConfirm:
            return """
            Subject: Confirming our meeting — \(lead.company)

            Hi \(lead.name),

            Looking forward to our conversation. I'll come prepared with ideas tailored to \(lead.company)'s priorities.

            Please reply to confirm the time still works for you.
            """
        case .proposalEmail:
            return """
            Subject: Proposal for \(lead.company)

            Hi \(lead.name),

            As discussed, I've attached a proposal outlining scope, pricing, and timeline for \(lead.company).

            Happy to walk through any questions on a quick call.
            """
        case .thankYou:
            return "Hi \(lead.name), thank you for your time today. I appreciated learning about \(lead.company)'s goals and will send a summary of next steps shortly."
        case .renewal:
            return """
            Subject: Renewal discussion — \(lead.company)

            Hi \(lead.name),

            Your renewal window is approaching. I'd love to review results so far and ensure the plan still fits \(lead.company)'s needs.

            Can we schedule 20 minutes this week?
            """
        case .callScript:
            return """
            Opening: "Hi \(lead.name), this is [Your Name] from [Company]. Do you have a quick minute?"

            Value: "I'm calling because based on our last conversation, I think we can help \(lead.company) with [specific pain point]."

            Ask: "What does your timeline look like for making a decision?"

            Close: "Can we schedule 15 minutes to review a tailored proposal?"
            """
        case .closingMessage:
            return "Hi \(lead.name), based on everything we've discussed, I'm confident this is the right fit for \(lead.company). Shall we move forward with the proposal we reviewed?"
        case .objectionResponse:
            return "I hear you on budget concerns. Many clients felt the same until they calculated the cost of inaction. Would it help if I walked you through a quick ROI breakdown?"
        }
    }
}
