import Foundation

@MainActor
@Observable
final class ScriptMakerService {
    private(set) var scripts: [SalesScript] = []
    private let storageKey = "salescoach_scripts"

    func load(for userId: String) {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([SalesScript].self, from: data) else {
            scripts = []
            return
        }
        scripts = stored.filter { $0.userId == userId }.sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(_ script: SalesScript, for userId: String) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            scripts[index] = script
        } else {
            scripts.insert(script, at: 0)
        }
        persist(for: userId)
    }

    func delete(_ script: SalesScript, for userId: String) {
        scripts.removeAll { $0.id == script.id }
        persist(for: userId)
    }

    func generateScript(
        type: ScriptType,
        lead: Lead?,
        category: SalesCategory?,
        customPrompt: String
    ) async -> SalesScript? {
        let body: String
        if AppConfig.isAIConfigured {
            body = (try? await OpenAIService.shared.requestSalesScript(
                type: type,
                lead: lead,
                category: category,
                customPrompt: customPrompt
            )) ?? localScript(type: type, lead: lead, category: category)
        } else {
            body = localScript(type: type, lead: lead, category: category)
        }
        let title = lead.map { "\(type.rawValue) — \($0.company.isEmpty ? $0.name : $0.company)" } ?? type.rawValue
        return SalesScript(
            userId: "",
            title: title,
            scriptType: type,
            leadId: lead?.id,
            body: body,
            tags: [type.rawValue, category?.rawValue ?? "General"].compactMap { $0 }
        )
    }

    private func persist(for userId: String) {
        var all = (UserDefaults.standard.data(forKey: storageKey)
            .flatMap { try? JSONDecoder().decode([SalesScript].self, from: $0) }) ?? []
        all.removeAll { $0.userId == userId }
        all.append(contentsOf: scripts)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func localScript(type: ScriptType, lead: Lead?, category: SalesCategory?) -> String {
        let name = lead?.name ?? "there"
        let company = lead?.company ?? "your business"
        switch type {
        case .coldCall:
            return "Hi \(name), this is [Your Name] with [Company]. I work with \(category?.clientLabel ?? "businesses") like \(company) on [outcome]. Do you have 30 seconds for one quick question?"
        case .followUp:
            return "Hi \(name), following up on our last conversation about \(company). I had one idea that could help with [pain point]. Are you free for 10 minutes this week?"
        case .objection:
            return "I hear you on budget. Most \(category?.clientLabel ?? "clients") we work with see ROI within [timeframe]. Would it help if I walked through how similar accounts justified the investment?"
        case .closing:
            return "\(name), based on what you've shared, it sounds like we're aligned. Should we move forward with [package] starting [date]?"
        case .voicemail:
            return "Hi \(name), [Your Name] here. Quick reason for my call: I help \(company)-type accounts with [value]. Call me back at [phone] or reply to my email — happy to keep it to 5 minutes."
        case .email:
            return "Subject: Quick follow-up for \(company)\n\nHi \(name),\n\n[Value prop in 2 sentences]\n\nOpen to a brief call this week?\n\nBest,\n[Your Name]"
        case .discovery:
            return "Before I share anything, help me understand: what's the biggest challenge \(company) is facing with [area] right now? What happens if that doesn't change this quarter?"
        }
    }
}
