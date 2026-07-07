import EventKit
import Foundation

@MainActor
@Observable
final class CalendarService {
    var isAuthorized = false
    var syncEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "salescoach_calendar_sync") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "salescoach_calendar_sync") }
    }
    func requestAccess() async {}
    func addFollowUpEvent(title: String, date: Date, notes: String?) {}
}
