import Foundation
import SwiftUI

enum DigitalCardTheme: String, Codable, CaseIterable, Identifiable {
    case electricBlue = "Electric Blue"
    case teal = "Teal Pro"
    case sunset = "Sunset Orange"
    case midnight = "Midnight Navy"
    case emerald = "Emerald Close"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .electricBlue: AppTheme.electricBlueBright
        case .teal: AppTheme.tealGreen
        case .sunset: AppTheme.warningOrange
        case .midnight: AppTheme.electricBlue
        case .emerald: AppTheme.successGreen
        }
    }

    var gradient: [Color] {
        [accent, accent.opacity(0.55)]
    }
}

struct DigitalBusinessCard: Codable, Equatable, Identifiable {
    var id: String
    var userId: String
    var fullName: String
    var title: String
    var company: String
    var phone: String
    var email: String
    var website: String
    var linkedIn: String
    var tagline: String
    var theme: DigitalCardTheme
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        fullName: String = "",
        title: String = "",
        company: String = "",
        phone: String = "",
        email: String = "",
        website: String = "",
        linkedIn: String = "",
        tagline: String = "",
        theme: DigitalCardTheme = .electricBlue,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.title = title
        self.company = company
        self.phone = phone
        self.email = email
        self.website = website
        self.linkedIn = linkedIn
        self.tagline = tagline
        self.theme = theme
        self.updatedAt = updatedAt
    }

    static func fromProfile(_ profile: UserProfile) -> DigitalBusinessCard {
        DigitalBusinessCard(
            userId: profile.id,
            fullName: profile.fullName,
            title: profile.isManager ? "Sales Manager" : "Sales Professional",
            company: profile.companyName ?? AppConfig.appName,
            email: profile.email,
            tagline: profile.salesCategory.map { "Helping clients win with \($0.rawValue)" } ?? AppConfig.productTagline,
            theme: .electricBlue
        )
    }

    var shareText: String {
        var lines = [fullName]
        if !title.isEmpty { lines.append(title) }
        if !company.isEmpty { lines.append(company) }
        if !phone.isEmpty { lines.append("Phone: \(phone)") }
        if !email.isEmpty { lines.append("Email: \(email)") }
        if !website.isEmpty { lines.append("Web: \(website)") }
        if !linkedIn.isEmpty { lines.append("LinkedIn: \(linkedIn)") }
        if !tagline.isEmpty { lines.append("\n\(tagline)") }
        lines.append("\n— Sent via \(AppConfig.appName)")
        return lines.joined(separator: "\n")
    }

    var vCard: String {
        var lines = [
            "BEGIN:VCARD",
            "VERSION:3.0",
            "FN:\(fullName)",
            "N:\(fullName);;;"
        ]
        if !title.isEmpty { lines.append("TITLE:\(title)") }
        if !company.isEmpty { lines.append("ORG:\(company)") }
        if !phone.isEmpty { lines.append("TEL;TYPE=CELL:\(phone)") }
        if !email.isEmpty { lines.append("EMAIL:\(email)") }
        if !website.isEmpty { lines.append("URL:\(website)") }
        if !linkedIn.isEmpty { lines.append("X-SOCIALPROFILE;type=linkedin:\(linkedIn)") }
        if !tagline.isEmpty { lines.append("NOTE:\(tagline)") }
        lines.append("END:VCARD")
        return lines.joined(separator: "\n")
    }

    var qrPayload: String { vCard }
}
