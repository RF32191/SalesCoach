import Foundation

enum CRMImportParser {
    static func parse(text: String, source: CRMImportSource) -> [CSVLeadRow] {
        switch source {
        case .genericCSV, .hubspot, .salesforce, .pipedrive, .zoho:
            return CRMEnhancements.parseCSV(text, source: source)
        case .vcard:
            return parseVCard(text)
        case .json:
            return parseJSON(text)
        }
    }

    private static func parseVCard(_ text: String) -> [CSVLeadRow] {
        let cards = text.components(separatedBy: "BEGIN:VCARD").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return cards.compactMap { cardText in
            var fields: [String: String] = [:]
            let lines = cardText.components(separatedBy: .newlines)
            for line in lines {
                let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { continue }
                let key = parts[0].uppercased()
                let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if key.hasPrefix("FN") { fields["name"] = value }
                else if key.hasPrefix("ORG") { fields["company"] = value.replacingOccurrences(of: ";", with: " ") }
                else if key.hasPrefix("TEL") { fields["phone"] = value }
                else if key.hasPrefix("EMAIL") { fields["email"] = value }
                else if key.hasPrefix("TITLE") { fields["title"] = value }
            }
            guard !fields.isEmpty else { return nil }
            fields["source"] = "vCard Import"
            return CSVLeadRow(fields: fields)
        }
    }

    private static func parseJSON(_ text: String) -> [CSVLeadRow] {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) else { return [] }
        let objects: [[String: Any]]
        if let array = json as? [[String: Any]] {
            objects = array
        } else if let dict = json as? [String: Any], let array = dict["contacts"] as? [[String: Any]] ?? dict["leads"] as? [[String: Any]] {
            objects = array
        } else {
            return []
        }
        return objects.map { obj in
            var fields: [String: String] = [:]
            for (key, value) in obj {
                fields[key.lowercased()] = "\(value)"
            }
            fields["source"] = "JSON Import"
            return CSVLeadRow(fields: fields)
        }
    }
}
