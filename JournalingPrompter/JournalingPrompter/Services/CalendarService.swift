import EventKit
import SwiftUI

@MainActor
class CalendarService: ObservableObject {
    static let shared = CalendarService()

    private let store = EKEventStore()

    @Published var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published var availableCalendars: [EKCalendar] = []
    @Published var todayEvents: [EKEvent] = []

    @AppStorage("calendarEnabled") var calendarEnabled: Bool = false

    private let selectedCalendarIDsKey = "selectedCalendarIDs"

    var selectedCalendarIDs: Set<String> {
        get {
            let stored = UserDefaults.standard.stringArray(forKey: selectedCalendarIDsKey) ?? []
            return Set(stored)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: selectedCalendarIDsKey)
        }
    }

    private init() {}

    func requestAccess() async {
        do {
            let granted = try await store.requestFullAccessToEvents()
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            if granted {
                loadAvailableCalendars()
            }
        } catch {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
    }

    func loadAvailableCalendars() {
        availableCalendars = store.calendars(for: .event)
    }

    func fetchTodayEvents() {
        guard authorizationStatus == .fullAccess else {
            todayEvents = []
            return
        }

        loadAvailableCalendars()

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) else { return }

        let predicate = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let allEvents = store.events(matching: predicate)

        let ids = selectedCalendarIDs
        todayEvents = allEvents
            .filter { ids.isEmpty || ids.contains($0.calendar.calendarIdentifier) }
            .sorted { $0.startDate < $1.startDate }
    }

    func isCalendarSelected(_ calendar: EKCalendar) -> Bool {
        selectedCalendarIDs.contains(calendar.calendarIdentifier)
    }

    func toggleCalendar(_ calendar: EKCalendar) {
        var ids = selectedCalendarIDs
        if ids.contains(calendar.calendarIdentifier) {
            ids.remove(calendar.calendarIdentifier)
        } else {
            ids.insert(calendar.calendarIdentifier)
        }
        selectedCalendarIDs = ids
        fetchTodayEvents()
    }
}
