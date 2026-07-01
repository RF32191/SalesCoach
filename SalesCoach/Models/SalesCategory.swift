import Foundation
import MapKit
import SwiftUI

enum SalesCategory: String, Codable, CaseIterable, Identifiable {
    case b2bServices = "B2B Services"
    case retail = "Retail & Stores"
    case restaurants = "Restaurants"
    case realEstate = "Real Estate"
    case insurance = "Insurance & Finance"
    case healthcare = "Healthcare"
    case automotive = "Automotive"
    case homeServices = "Home Services"
    case saas = "SaaS & Tech"
    case fitness = "Fitness & Wellness"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .b2bServices: "building.2.fill"
        case .retail: "bag.fill"
        case .restaurants: "fork.knife"
        case .realEstate: "house.fill"
        case .insurance: "shield.fill"
        case .healthcare: "cross.case.fill"
        case .automotive: "car.fill"
        case .homeServices: "wrench.and.screwdriver.fill"
        case .saas: "laptopcomputer"
        case .fitness: "figure.run"
        }
    }

    var subtitle: String {
        switch self {
        case .b2bServices: "Offices, agencies, and professional services"
        case .retail: "Shops, boutiques, and consumer brands"
        case .restaurants: "Dining, cafes, and hospitality"
        case .realEstate: "Agents, brokers, and property managers"
        case .insurance: "Agencies, advisors, and lenders"
        case .healthcare: "Clinics, dental, and medical practices"
        case .automotive: "Dealers, repair, and auto services"
        case .homeServices: "Contractors, HVAC, and landscaping"
        case .saas: "Software companies and tech vendors"
        case .fitness: "Gyms, studios, and wellness centers"
        }
    }

    /// Primary MapKit search terms for this sales vertical.
    var searchQueries: [String] {
        switch self {
        case .b2bServices: ["business services", "consulting office", "professional services"]
        case .retail: ["retail store", "boutique shop", "clothing store"]
        case .restaurants: ["restaurant", "cafe", "coffee shop"]
        case .realEstate: ["real estate agency", "property management", "real estate broker"]
        case .insurance: ["insurance agency", "financial advisor", "mortgage broker"]
        case .healthcare: ["medical clinic", "dental office", "urgent care"]
        case .automotive: ["car dealership", "auto repair", "auto body shop"]
        case .homeServices: ["HVAC contractor", "plumber", "landscaping company"]
        case .saas: ["software company", "technology startup", "IT services"]
        case .fitness: ["gym", "fitness studio", "yoga studio"]
        }
    }

    var searchQuery: String { searchQueries.first ?? rawValue }

    var accentColor: Color {
        switch self {
        case .b2bServices: AppTheme.electricBlueBright
        case .retail: AppTheme.warningOrange
        case .restaurants: AppTheme.dangerRed
        case .realEstate: AppTheme.tealGreen
        case .insurance: AppTheme.electricBlue
        case .healthcare: AppTheme.successGreen
        case .automotive: AppTheme.textMuted
        case .homeServices: AppTheme.warningOrange
        case .saas: AppTheme.electricBlueBright
        case .fitness: AppTheme.tealGreen
        }
    }

    var teamWorkspaceTitle: String {
        switch self {
        case .b2bServices: "B2B Sales Workspace"
        case .retail: "Retail Sales Workspace"
        case .restaurants: "Restaurant Sales Workspace"
        case .realEstate: "Real Estate Workspace"
        case .insurance: "Insurance & Finance Workspace"
        case .healthcare: "Healthcare Sales Workspace"
        case .automotive: "Automotive Sales Workspace"
        case .homeServices: "Home Services Workspace"
        case .saas: "SaaS Sales Workspace"
        case .fitness: "Fitness & Wellness Workspace"
        }
    }

    var clientLabel: String {
        switch self {
        case .b2bServices: "business clients"
        case .retail: "store owners"
        case .restaurants: "restaurant owners"
        case .realEstate: "buyers & sellers"
        case .insurance: "policy prospects"
        case .healthcare: "practice contacts"
        case .automotive: "dealership contacts"
        case .homeServices: "homeowner leads"
        case .saas: "software prospects"
        case .fitness: "gym & studio owners"
        }
    }

    var homeHeadline: String {
        "Built for \(rawValue.lowercased()) reps"
    }

    var proximityAlertTitle: String {
        switch self {
        case .restaurants: "You're near a restaurant prospect"
        case .retail: "You're near a retail prospect"
        case .realEstate: "You're near a property contact"
        case .healthcare: "You're near a practice"
        case .automotive: "You're near an auto business"
        case .homeServices: "You're near a homeowner lead"
        case .saas: "You're near a tech prospect"
        case .fitness: "You're near a fitness business"
        default: "You're near a pinned prospect"
        }
    }

    /// Example brands and account types sales teams commonly target in CRM.
    var notableCRMTargets: [String] {
        switch self {
        case .b2bServices:
            ["Deloitte", "Accenture", "McKinsey", "WeWork", "Regus", "KPMG", "ADP", "Paychex"]
        case .retail:
            ["Target", "Best Buy", "Nordstrom", "Sephora", "Apple Store", "Costco", "Trader Joe's", "Nike"]
        case .restaurants:
            ["Starbucks", "Chipotle", "Panera", "McDonald's", "Sweetgreen", "Shake Shack", "Olive Garden", "Dunkin'"]
        case .realEstate:
            ["Coldwell Banker", "RE/MAX", "Keller Williams", "Compass", "CBRE", "JLL", "Zillow Offices", "Redfin"]
        case .insurance:
            ["State Farm", "Allstate", "Northwestern Mutual", "Prudential", "Fidelity", "Charles Schwab", "Edward Jones", "Chase Bank"]
        case .healthcare:
            ["Kaiser Permanente", "CVS Health", "Walgreens", "Aspen Dental", "One Medical", "Mayo Clinic", "Urgent Care", "Pediatric Group"]
        case .automotive:
            ["Toyota", "Ford", "CarMax", "AutoNation", "Jiffy Lube", "Midas", "Firestone", "Tesla Service"]
        case .homeServices:
            ["Servpro", "Roto-Rooter", "Mr. Rooters", "Trane", "Carrier", "BrightView", "Terminix", "Home Depot Pro"]
        case .saas:
            ["Salesforce", "HubSpot", "Slack", "Atlassian", "Zendesk", "Monday.com", "Notion", "Stripe"]
        case .fitness:
            ["Planet Fitness", "LA Fitness", "Equinox", "Orangetheory", "CrossFit", "CorePower Yoga", "Anytime Fitness", "Barry's"]
        }
    }

    /// Short labels for quick-search chips in the map finder.
    var quickSearchTerms: [String] {
        switch self {
        case .b2bServices: ["Consulting", "Marketing Agency", "Law Firm", "Accounting"]
        case .retail: ["Clothing Store", "Electronics", "Furniture", "Grocery"]
        case .restaurants: ["Coffee Shop", "Fast Casual", "Pizza", "Fine Dining"]
        case .realEstate: ["Real Estate Office", "Property Management", "Apartments"]
        case .insurance: ["Insurance Agency", "Wealth Management", "Credit Union"]
        case .healthcare: ["Dental Office", "Urgent Care", "Chiropractor", "Pharmacy"]
        case .automotive: ["Auto Dealer", "Auto Repair", "Tire Shop", "Car Wash"]
        case .homeServices: ["HVAC", "Plumber", "Roofing", "Landscaping"]
        case .saas: ["Software Company", "IT Services", "Cybersecurity", "Cloud Consulting"]
        case .fitness: ["Gym", "Yoga Studio", "Personal Training", "Pilates"]
        }
    }

    var poiCategories: Set<MKPointOfInterestCategory> {
        switch self {
        case .b2bServices:
            [.school, .university, .library, .postOffice]
        case .retail:
            [.store, .pharmacy, .foodMarket]
        case .restaurants:
            [.restaurant, .cafe, .bakery, .winery, .brewery, .foodMarket, .nightlife]
        case .realEstate:
            [.hotel]
        case .insurance:
            [.bank, .atm]
        case .healthcare:
            [.hospital, .pharmacy]
        case .automotive:
            [.gasStation, .carRental, .evCharger, .parking]
        case .homeServices:
            [.laundry, .animalService]
        case .saas:
            [.school, .university, .library]
        case .fitness:
            [.fitnessCenter, .stadium, .park]
        }
    }

    var matchKeywords: [String] {
        switch self {
        case .b2bServices:
            ["consult", "agency", "law", "legal", "accounting", "cpa", "marketing", "staffing", "recruiting", "office", "business services", "professional"]
        case .retail:
            ["store", "shop", "boutique", "retail", "outlet", "market", "apparel", "clothing", "furniture", "electronics", "grocery", "supermarket"]
        case .restaurants:
            ["restaurant", "cafe", "coffee", "diner", "grill", "kitchen", "bistro", "pizza", "sushi", "bar ", " tavern", "bakery", "food"]
        case .realEstate:
            ["real estate", "realty", "property", "broker", "realtor", "apartment", "housing", "property management", "homes", "real estate office"]
        case .insurance:
            ["insurance", "financial", "advisor", "wealth", "mortgage", "loan", "bank", "credit union", "investment", "capital", "agency"]
        case .healthcare:
            ["medical", "clinic", "dental", "doctor", "physician", "health", "urgent care", "chiro", "therapy", "hospital", "pharmacy", "pediatric"]
        case .automotive:
            ["auto", "car", "motor", "dealer", "dealership", "tire", "repair", "body shop", "mechanic", "oil change", "transmission"]
        case .homeServices:
            ["hvac", "plumb", "roof", "landscap", "electric", "contractor", "remodel", "cleaning", "pest", "handyman", "garage door", "paint"]
        case .saas:
            ["software", "technology", "tech", "saas", "cloud", "digital", "data", "cyber", "it ", "systems", "platform", "solutions"]
        case .fitness:
            ["gym", "fitness", "yoga", "pilates", "crossfit", "training", "wellness", "studio", "athletic", "sports club"]
        }
    }

    var excludeKeywords: [String] {
        switch self {
        case .restaurants: ["gas station", "pharmacy", "bank"]
        case .retail: ["restaurant", "hospital", "dentist"]
        case .healthcare: ["restaurant", "auto", "gym"]
        case .automotive: ["restaurant", "coffee", "dental"]
        default: []
        }
    }

    func matchScore(for mapItem: MKMapItem) -> Int {
        let name = (mapItem.name ?? "").lowercased()
        let placemarkText = [
            mapItem.placemark.locality,
            mapItem.placemark.subLocality,
            mapItem.placemark.thoroughfare
        ]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")
        let searchable = "\(name) \(placemarkText)"

        if excludeKeywords.contains(where: { searchable.contains($0) }) {
            return 0
        }

        var score = 0
        if let poi = mapItem.pointOfInterestCategory, poiCategories.contains(poi) {
            score += 12
        }
        for keyword in matchKeywords where searchable.contains(keyword) {
            score += 6
        }
        return score
    }

    static func bestMatch(for mapItem: MKMapItem) -> SalesCategory? {
        let ranked = allCases
            .map { ($0, $0.matchScore(for: mapItem)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
        return ranked.first?.0
    }

    func matches(mapItem: MKMapItem, companyQuery: String = "") -> Bool {
        let trimmedQuery = companyQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let name = (mapItem.name ?? "").lowercased()

        if !trimmedQuery.isEmpty, name.contains(trimmedQuery) {
            if let best = Self.bestMatch(for: mapItem) {
                return best == self
            }
            return matchScore(for: mapItem) >= 6
        }

        guard let best = Self.bestMatch(for: mapItem) else { return false }
        return best == self
    }
}

struct DiscoveredProspect: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let city: String
    let latitude: Double
    let longitude: Double
    let phone: String?
    let website: String?
    let category: SalesCategory
    let distanceMeters: Double?

    var distanceLabel: String? {
        guard let distanceMeters else { return nil }
        if distanceMeters < 1000 {
            return String(format: "%.0f m away", distanceMeters)
        }
        return String(format: "%.1f mi away", distanceMeters / 1609.34)
    }
}
