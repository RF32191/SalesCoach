import Foundation

enum SalesActionParser {
    /// Parses team sale announcements from chat — no CRM client management.
    static func parseTeamSale(from text: String, leads: [Lead]) -> [SalesAction] {
        let lower = text.lowercased()
        let saleKeywords = ["won", "closed", "sale", "sold", "deal", "booked", "signed"]
        let hasSaleIntent = saleKeywords.contains(where: { lower.contains($0) })
            || (lower.contains("log") && extractDollarAmount(from: text) != nil)
            || (lower.contains("record") && extractDollarAmount(from: text) != nil)

        guard hasSaleIntent, let value = extractDollarAmount(from: text), value > 0 else {
            return []
        }

        guard let clientName = extractClientName(from: text, leads: leads) else {
            return []
        }

        return [
            SalesAction(
                type: .logSale,
                leadMatch: clientName,
                company: extractCompany(from: text),
                dealValue: value,
                summary: text,
                won: true
            )
        ]
    }

    static func parseFromAIResponse(_ content: String) -> ChatActionPayload? {
        guard let range = content.range(of: "<!--ACTIONS") else { return nil }
        let jsonPart = content[range.upperBound...]
            .replacingOccurrences(of: "-->", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = jsonPart.data(using: .utf8),
              let payload = try? JSONDecoder().decode(ChatActionPayload.self, from: data) else { return nil }
        let salesOnly = payload.actions.filter { $0.type == .logSale }
        guard !salesOnly.isEmpty else { return nil }
        return ChatActionPayload(reply: payload.reply, actions: salesOnly)
    }

    private static func extractClientName(from text: String, leads: [Lead]) -> String? {
        for lead in leads {
            if text.localizedCaseInsensitiveContains(lead.name) { return lead.name }
            if !lead.company.isEmpty, text.localizedCaseInsensitiveContains(lead.company) { return lead.company }
        }
        if let quoted = extractQuotedName(from: text) { return quoted }
        if let withMatch = extractPattern(from: text, pattern: #"(?:with|for|to)\s+([A-Z][A-Za-z0-9\s&\.\'-]{1,40})"#) {
            return withMatch
        }
        if let atMatch = extractPattern(from: text, pattern: #"at\s+([A-Z][A-Za-z0-9\s&\.\'-]{1,40})"#) {
            return atMatch
        }
        return nil
    }

    private static func extractPattern(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        let value = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.count >= 2 ? value : nil
    }

    private static func extractDollarAmount(from text: String) -> Double? {
        let pattern = #"\$?\s*([\d,]+(?:\.\d+)?)\s*[kK]?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        var raw = String(text[range]).replacingOccurrences(of: ",", with: "")
        var multiplier = 1.0
        if text.localizedCaseInsensitiveContains("k") && !raw.lowercased().contains("k") {
            if let value = Double(raw) { return value * 1000 }
        }
        if raw.lowercased().hasSuffix("k") {
            raw = String(raw.dropLast())
            multiplier = 1000
        }
        guard let value = Double(raw) else { return nil }
        return value * multiplier
    }

    private static func extractQuotedName(from text: String) -> String? {
        let patterns = [#""([^"]+)""#, #"with\s+([A-Z][a-zA-Z\s&\.\'-]+)"#, #"for\s+([A-Z][a-zA-Z\s&\.\'-]+)"#]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range(at: 1), in: text) else { continue }
            let name = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if name.count >= 2 { return name }
        }
        return nil
    }

    private static func extractCompany(from text: String) -> String? {
        extractPattern(from: text, pattern: #"at\s+([A-Z][A-Za-z0-9\s&\.\'-]+)"#)
    }
}
