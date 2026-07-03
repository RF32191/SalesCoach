import EventKit
import Foundation

@MainActor
@Observable
final class CalendarService {
    private let store = EKEventStore()
    var isAuthorized = false
    var syncEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "salescoach_calendar_sync") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "salescoach_calendar_sync") }
    }

    func requestAccess() async {
        do {
            isAuthorized = try await store.requestFullAccessToEvents()
        } catch {
            isAuthorized = false
        }
    }

    func addFollowUpEvent(title: String, date: Date, notes: String?) {
        guard syncEnabled, isAuthorized else { return }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = date
        event.endDate = Calendar.current.date(byAdding: .minute, value: 30, to: date) ?? date
        event.notes = notes
        event.calendar = store.defaultCalendarForNewEvents
        try? store.save(event, span: .thisEvent)
    }
}
