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
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([ChatConversation].self, from: data) else {
            conversations = []
            return
        }
        conversations = stored.filter { $0.userId == userId }.sorted { $0.updatedAt > $1.updatedAt }
    }

    func startNewConversation(userId: String) {
        let conversation = ChatConversation(userId: userId)
        currentConversation = conversation
    }

    func selectConversation(_ conversation: ChatConversation) {
        currentConversation = conversation
    }

    func sendMessage(_ content: String, userId: String) async {
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
        isLoading = true
        errorMessage = nil

        do {
            let response = try await OpenAIService.shared.chat(messages: conversation.messages)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            conversation.messages.append(assistantMessage)
            conversation.updatedAt = .now
            currentConversation = conversation
            upsertConversation(conversation)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteConversation(_ conversation: ChatConversation) {
        conversations.removeAll { $0.id == conversation.id }
        if currentConversation?.id == conversation.id {
            currentConversation = nil
        }
        saveConversations()
    }

    private func upsertConversation(_ conversation: ChatConversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
        saveConversations()
    }

    private func saveConversations() {
        if let data = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
