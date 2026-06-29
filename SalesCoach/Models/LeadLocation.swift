import CoreLocation
import Foundation

struct LeadLocation: Codable, Equatable {
    var address: String
    var city: String
    var latitude: Double?
    var longitude: Double?
    var locationLabel: String
    var pinReminderEnabled: Bool
    var reminderRadiusMeters: Double

    static let defaultRadius: Double = 250

    init(
        address: String = "",
        city: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationLabel: String = "",
        pinReminderEnabled: Bool = false,
        reminderRadiusMeters: Double = LeadLocation.defaultRadius
    ) {
        self.address = address
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
        self.locationLabel = locationLabel
        self.pinReminderEnabled = pinReminderEnabled
        self.reminderRadiusMeters = reminderRadiusMeters
    }

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var displayAddress: String {
        [locationLabel, address, city].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

enum LeadActivityType: String, Codable, CaseIterable, Identifiable {
    case call = "Call"
    case email = "Email"
    case meeting = "Meeting"
    case visit = "Site Visit"
    case note = "Note"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .call: "phone.fill"
        case .email: "envelope.fill"
        case .meeting: "person.2.fill"
        case .visit: "mappin.and.ellipse"
        case .note: "note.text"
        }
    }
}

struct LeadActivity: Codable, Identifiable, Equatable {
    var id: String
    var type: LeadActivityType
    var summary: String
    var date: Date

    init(id: String = UUID().uuidString, type: LeadActivityType, summary: String, date: Date = .now) {
        self.id = id
        self.type = type
        self.summary = summary
        self.date = date
    }
}
