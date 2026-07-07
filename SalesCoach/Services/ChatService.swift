import Foundation

@MainActor
@Observable
final class ChatService {
    var conversations: [ChatConversation] = []
    var currentConversation: ChatConversation?
    var isLoading = false
    var errorMessage: String?

    private let storageKey = "salescoach_conversations"

    func loadConversations(for userId: String) {
        let all = loadAllConversations()
        conversations = all.filter { $0.userId == userId }.sorted { $0.updatedAt > $1.updatedAt }
        ensureCurrentConversation(for: userId)
    }

    func ensureCurrentConversation(for userId: String) {
        if currentConversation == nil, let recent = conversations.first {
            currentConversation = recent
        }
    }

    func startNewConversation(userId: String) {
        if let current = currentConversation, !current.messages.isEmpty {
            upsertConversation(current)
        }
        let conversation = ChatConversation(userId: userId)
        currentConversation = conversation
    }

    func selectConversation(_ conversation: ChatConversation) {
        if let current = currentConversation, current.id != conversation.id, !current.messages.isEmpty {
            upsertConversation(current)
        }
        currentConversation = conversation
    }

    func sendMessage(
        _ content: String,
        userId: String,
        repName: String,
        teamId: String,
        companyName: String?,
        teamMembers: [TeamMember],
        crm: CRMService,
        audit: AuditService,
        teamSales: TeamSalesService,
        gamification: GamificationService
    ) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if currentConversation == nil {
            startNewConversation(userId: userId)
        }
        guard var conversation = currentConversation else { return }

        let userMessage = ChatMessage(role: .user, content: trimmed)
        conversation.messages.append(userMessage)
        conversation.updatedAt = .now

        if conversation.messages.count == 1 {
            conversation.title = String(trimmed.prefix(40))
        }

        currentConversation = conversation
        upsertConversation(conversation)
        isLoading = true
        errorMessage = nil

        let executor = SalesActionExecutor(
            crm: crm,
            audit: audit,
            teamSales: teamSales,
            gamification: gamification,
            userId: userId,
            repName: repName,
            teamId: teamId,
            source: .chat
        )

        let saleActions = SalesActionParser.parseTeamSale(from: trimmed, leads: crm.leads)
        var results: [String] = []
        var reply: String

        if !saleActions.isEmpty {
            results = executor.execute(saleActions)
            reply = results.isEmpty
                ? "Include a client name and amount, e.g. \"Closed $5k with Acme Corp.\""
                : "Posted to \(teamLabel(companyName)).\n\n✓ " + results.joined(separator: "\n✓ ")
        } else if teamId != "solo" {
            teamSales.postUpdate(TeamFeedUpdate(
                teamId: teamId,
                repUserId: userId,
                repName: repName,
                message: trimmed
            ))
            reply = "Shared with \(teamLabel(companyName)). Invited reps on your company account will see this on Team Dashboard."
        } else {
            reply = "Create a team account to share sales updates with invited reps. Example: \"Closed $5k with Acme Corp.\""
        }

        if Self.isCoachingRequest(trimmed), AppConfig.isAIConfigured {
            do {
                let coaching = try await OpenAIService.shared.chatWithTeamSales(
                    messages: conversation.messages,
                    repName: repName,
                    teamMembers: teamMembers,
                    leads: crm.leads
                )
                if !coaching.reply.isEmpty {
                    reply += "\n\n" + coaching.reply
                }
            } catch {
                if teamId == "solo" {
                    errorMessage = error.localizedDescription
                }
            }
        }

        let assistantMessage = ChatMessage(
            role: .assistant,
            content: reply,
            loggedActions: results.isEmpty ? nil : results
        )
        conversation.messages.append(assistantMessage)
        conversation.updatedAt = .now
        currentConversation = conversation
        upsertConversation(conversation)
        isLoading = false
    }

    private func teamLabel(_ companyName: String?) -> String {
        if let companyName, !companyName.isEmpty { return companyName }
        return "your team"
    }

    static func isCoachingRequest(_ text: String) -> Bool {
        let lower = text.lowercased()
        let coachingWords = ["help", "objection", "script", "write", "how do i", "how should i", "coach", "practice", "pitch"]
        return coachingWords.contains(where: { lower.contains($0) })
    }

    static func isTeamPost(_ text: String) -> Bool {
        !parseTeamSaleOnly(text).isEmpty || !isCoachingRequest(text)
    }

    private static func parseTeamSaleOnly(_ text: String) -> [SalesAction] {
        SalesActionParser.parseTeamSale(from: text, leads: [])
    }

    func deleteConversation(_ conversation: ChatConversation) {
        conversations.removeAll { $0.id == conversation.id }
        if currentConversation?.id == conversation.id {
            currentConversation = conversations.first
        }
        saveAllConversations()
    }

    private func upsertConversation(_ conversation: ChatConversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
        saveAllConversations()
    }

    private func loadAllConversations() -> [ChatConversation] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([ChatConversation].self, from: data) else {
            return []
        }
        return stored
    }

    private func saveAllConversations() {
        var all = loadAllConversations()
        let touchedUserIds = Set(conversations.map(\.userId))
        for userId in touchedUserIds {
            all.removeAll { $0.userId == userId }
        }
        all.append(contentsOf: conversations)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
