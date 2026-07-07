import UIKit

enum LeadCommunicationService {
    static func phoneDigits(_ phone: String) -> String {
        phone.filter { $0.isNumber || $0 == "+" }
    }

    static func callURL(for phone: String) -> URL? {
        let digits = phoneDigits(phone)
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }

    static func smsURL(for phone: String, body: String? = nil) -> URL? {
        let digits = phoneDigits(phone)
        guard !digits.isEmpty else { return nil }
        var urlString = "sms:\(digits)"
        if let body, let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "&body=\(encoded)"
        }
        return URL(string: urlString)
    }

    static func emailURL(for email: String, subject: String? = nil, body: String? = nil) -> URL? {
        guard !email.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        var queryItems: [URLQueryItem] = []
        if let subject { queryItems.append(URLQueryItem(name: "subject", value: subject)) }
        if let body { queryItems.append(URLQueryItem(name: "body", value: body)) }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        return components.url
    }

    static func defaultEmailSubject(for lead: Lead) -> String {
        let target = lead.company.isEmpty ? lead.name : lead.company
        return "Following up — \(target)"
    }

    static func open(_ url: URL?) {
        guard let url else { return }
        UIApplication.shared.open(url)
    }

    static func call(lead: Lead, logHandler: (() -> Void)? = nil) {
        open(callURL(for: lead.phone))
        logHandler?()
    }

    static func email(lead: Lead, logHandler: (() -> Void)? = nil) {
        open(emailURL(for: lead.email, subject: defaultEmailSubject(for: lead)))
        logHandler?()
    }

    static func text(lead: Lead, body: String? = nil, logHandler: (() -> Void)? = nil) {
        open(smsURL(for: lead.phone, body: body))
        logHandler?()
    }
}

struct CommunicationActivityItem: Identifiable, Equatable {
    let leadId: String
    let leadName: String
    let company: String
    let phone: String
    let email: String
    let activity: LeadActivity

    var id: String { activity.id }

    var leadLabel: String {
        company.isEmpty ? leadName : company
    }
}
