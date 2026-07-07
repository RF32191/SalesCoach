import Foundation

enum CRMImportSource: String, CaseIterable, Identifiable {
    case genericCSV = "Generic CSV"
    case hubspot = "HubSpot Export"
    case salesforce = "Salesforce Export"
    case pipedrive = "Pipedrive Export"
    case zoho = "Zoho CRM Export"
    case vcard = "vCard (.vcf)"
    case json = "JSON"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .genericCSV: "doc.text"
        case .hubspot: "h.square.fill"
        case .salesforce: "cloud.fill"
        case .pipedrive: "chart.line.uptrend.xyaxis"
        case .zoho: "z.circle.fill"
        case .vcard: "person.crop.rectangle"
        case .json: "curlybraces"
        }
    }

    var hint: String {
        switch self {
        case .genericCSV: "Name, Company, Email, Phone, Stage, Value columns"
        case .hubspot: "Export contacts or deals from HubSpot → Import"
        case .salesforce: "Data Export or Report CSV from Salesforce"
        case .pipedrive: "Export people or deals from Pipedrive"
        case .zoho: "Export module records from Zoho CRM"
        case .vcard: "Single or multi-contact .vcf from Contacts or email"
        case .json: "Array of contact objects with name, email, company"
        }
    }
}

@MainActor
@Observable
final class IntegrationService {
    var hubspotConnected: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hubspot) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hubspot) }
    }
    var salesforceConnected: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.salesforce) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.salesforce) }
    }
    var googleCalendarConnected: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.googleCalendar) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.googleCalendar) }
    }
    var zapierConnected: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.zapier) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.zapier) }
    }
    var zapierWebhookURL: String {
        get { UserDefaults.standard.string(forKey: Keys.zapierWebhook) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.zapierWebhook) }
    }
    var hubspotPortalId: String {
        get { UserDefaults.standard.string(forKey: Keys.hubspotPortal) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hubspotPortal) }
    }
    var salesforceOrgId: String {
        get { UserDefaults.standard.string(forKey: Keys.salesforceOrg) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.salesforceOrg) }
    }
    var googleCalendarEmail: String {
        get { UserDefaults.standard.string(forKey: Keys.googleEmail) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.googleEmail) }
    }

    func isConnected(_ provider: IntegrationProvider) -> Bool {
        switch provider {
        case .hubspot: hubspotConnected
        case .salesforce: salesforceConnected
        case .googleCalendar: googleCalendarConnected
        case .appleCalendar: true
        case .zapier: zapierConnected && !zapierWebhookURL.isEmpty
        }
    }

    func connect(_ provider: IntegrationProvider) {
        switch provider {
        case .hubspot: hubspotConnected = true
        case .salesforce: salesforceConnected = true
        case .googleCalendar: googleCalendarConnected = true
        case .appleCalendar: break
        case .zapier: zapierConnected = true
        }
    }

    func disconnect(_ provider: IntegrationProvider) {
        switch provider {
        case .hubspot: hubspotConnected = false
        case .salesforce: salesforceConnected = false
        case .googleCalendar: googleCalendarConnected = false
        case .appleCalendar: break
        case .zapier:
            zapierConnected = false
            zapierWebhookURL = ""
        }
    }

    func notifyZapier(lead: Lead, event: String) async {
        guard zapierConnected, let url = URL(string: zapierWebhookURL), !zapierWebhookURL.isEmpty else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "event": event,
            "name": lead.name,
            "company": lead.company,
            "email": lead.email,
            "phone": lead.phone,
            "stage": lead.dealStage.rawValue,
            "value": lead.dealValue,
            "source": lead.leadSource
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        _ = try? await URLSession.shared.data(for: request)
    }

    private enum Keys {
        static let hubspot = "integration_hubspot_connected"
        static let salesforce = "integration_salesforce_connected"
        static let googleCalendar = "integration_google_calendar_connected"
        static let zapier = "integration_zapier_connected"
        static let zapierWebhook = "integration_zapier_webhook"
        static let hubspotPortal = "integration_hubspot_portal"
        static let salesforceOrg = "integration_salesforce_org"
        static let googleEmail = "integration_google_email"
    }
}
