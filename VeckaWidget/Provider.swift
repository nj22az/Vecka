//
//  Provider.swift
//  VeckaWidget
//
//  Created by Nils Johansson on 2025-09-11.
//

import WidgetKit
import SwiftUI
import EventKit

// MARK: - Timeline Provider
struct VeckaWidgetProvider: TimelineProvider {
    typealias Entry = VeckaWidgetEntry

    private static var calendar: Calendar { sharedISO8601Calendar }

    private let eventStore = EKEventStore()

    private var isCalendarAuthorized: Bool {
        // iOS 18.0+ minimum, no availability check needed
        return EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    func placeholder(in context: Context) -> VeckaWidgetEntry {
        VeckaWidgetEntry(
            date: Date(),
            todaysEvents: [],
            weekEvents: [:],
            upcomingEvent: nil,
            todaysHolidays: [],
            upcomingHolidays: [],
            todaysBirthdays: [],
            weekBirthdays: [:],
            calendarAccessDenied: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (VeckaWidgetEntry) -> Void) {
        if context.isPreview {
            // For widget gallery previews, use static preview data
            completion(.preview)
            return
        }

        // For actual snapshots, fetch real data synchronously where possible
        let now = Date()
        let (todaysHolidays, upcomingHolidays) = fetchHolidays(for: now)
        let todaysBirthdays = fetchBirthdays(for: now)
        let weekBirthdays = fetchWeekBirthdays(for: now)

        let entry = VeckaWidgetEntry(
            date: now,
            todaysEvents: [],  // Skip async calendar events for snapshots
            weekEvents: [:],
            upcomingEvent: nil,
            todaysHolidays: todaysHolidays,
            upcomingHolidays: upcomingHolidays,
            todaysBirthdays: todaysBirthdays,
            weekBirthdays: weekBirthdays,
            calendarAccessDenied: !isCalendarAuthorized
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VeckaWidgetEntry>) -> Void) {
        let now = Date()
        let calendar = Self.calendar

        // Fetch holidays synchronously (no async needed)
        let (todaysHolidays, upcomingHolidays) = fetchHolidays(for: now)
        let todaysBirthdays = fetchBirthdays(for: now)
        let weekBirthdays = fetchWeekBirthdays(for: now)

        // Fetch calendar events (can access EventKit synchronously in widgets)
        fetchCalendarEvents(for: now) { todaysEvents, weekEvents, upcomingEvent in
            let entry = VeckaWidgetEntry(
                date: now,
                todaysEvents: todaysEvents,
                weekEvents: weekEvents,
                upcomingEvent: upcomingEvent,
                todaysHolidays: todaysHolidays,
                upcomingHolidays: upcomingHolidays,
                todaysBirthdays: todaysBirthdays,
                weekBirthdays: weekBirthdays,
                calendarAccessDenied: !self.isCalendarAuthorized
            )

            // Calculate next update time: midnight or next event, whichever is sooner
            let nextMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
            var nextUpdate = nextMidnight

            // Update at next event if sooner than midnight
            if let event = upcomingEvent, event.startDate < nextMidnight {
                nextUpdate = event.startDate
            }

            // Minimum update interval of 15 minutes to avoid excessive refreshes
            let minimumUpdate = now.addingTimeInterval(15 * 60)
            if nextUpdate < minimumUpdate {
                nextUpdate = minimumUpdate
            }

            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    // MARK: - Calendar Event Fetching
    private func fetchCalendarEvents(
        for date: Date,
        completion: @escaping ([EKEvent], [Date: [EKEvent]], EKEvent?) -> Void
    ) {
        guard isCalendarAuthorized else {
            completion([], [:], nil)
            return
        }
        
        let calendar = Self.calendar
        let startOfDay = calendar.startOfDay(for: date)
        
        // Get week interval
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            completion([], [:], nil)
            return
        }
        
        // Fetch week events
        let weekPredicate = eventStore.predicateForEvents(
            withStart: weekInterval.start,
            end: weekInterval.end,
            calendars: nil
        )
        let weekEvents = eventStore.events(matching: weekPredicate)
        
        // Group events by day
        var eventsByDay: [Date: [EKEvent]] = [:]
        for event in weekEvents {
            let eventDay = calendar.startOfDay(for: event.startDate)
            eventsByDay[eventDay, default: []].append(event)
        }
        
        // Sort events within each day
        for (day, events) in eventsByDay {
            eventsByDay[day] = events.sorted { $0.startDate < $1.startDate }
        }
        
        let todaysEvents = eventsByDay[startOfDay] ?? []
        
        // Find next upcoming event
        guard let endDate = calendar.date(byAdding: .day, value: 30, to: date) else {
            completion(todaysEvents, eventsByDay, nil)
            return
        }
        
        let upcomingPredicate = eventStore.predicateForEvents(
            withStart: date,
            end: endDate,
            calendars: nil
        )
        let upcomingEvents = eventStore.events(matching: upcomingPredicate)
            .filter { $0.startDate >= date }
            .sorted { $0.startDate < $1.startDate }
        
        completion(todaysEvents, eventsByDay, upcomingEvents.first)
    }

    // MARK: - Holiday Fetching
    private func fetchHolidays(for date: Date) -> ([WidgetHoliday], [WidgetHoliday]) {
        let engine = WidgetHolidayEngine()
        let todaysHolidays = engine.getHolidays(for: date)
        let upcomingHolidays = engine.getUpcomingHolidays(from: date, days: 30)
        return (todaysHolidays, upcomingHolidays)
    }

    // MARK: - Birthday Fetching (情報デザイン: Birthdays from iOS Calendar)
    private func fetchBirthdays(for date: Date) -> [WidgetBirthday] {
        guard isCalendarAuthorized else { return [] }

        let calendar = Self.calendar
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        // Find birthday calendars
        let birthdayCalendars = eventStore.calendars(for: .event).filter { $0.type == .birthday }
        guard !birthdayCalendars.isEmpty else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: birthdayCalendars
        )

        return eventStore.events(matching: predicate).map { event in
            WidgetBirthday(name: event.title ?? "Birthday", date: event.startDate)
        }
    }

    /// Fetch birthdays for a range of dates (for week view)
    private func fetchWeekBirthdays(for date: Date) -> [Date: [WidgetBirthday]] {
        guard isCalendarAuthorized else { return [:] }

        let calendar = Self.calendar
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [:] }

        // Find birthday calendars
        let birthdayCalendars = eventStore.calendars(for: .event).filter { $0.type == .birthday }
        guard !birthdayCalendars.isEmpty else { return [:] }

        let predicate = eventStore.predicateForEvents(
            withStart: weekInterval.start,
            end: weekInterval.end,
            calendars: birthdayCalendars
        )

        var birthdaysByDay: [Date: [WidgetBirthday]] = [:]
        for event in eventStore.events(matching: predicate) {
            let day = calendar.startOfDay(for: event.startDate)
            let birthday = WidgetBirthday(name: event.title ?? "Birthday", date: event.startDate)
            birthdaysByDay[day, default: []].append(birthday)
        }
        return birthdaysByDay
    }
}

// MARK: - Widget Birthday Model
struct WidgetBirthday: Identifiable {
    let id = UUID()
    let name: String
    let date: Date

    var displayName: String {
        // Remove "'s Birthday" suffix if present (iOS adds this)
        name.replacingOccurrences(of: "'s Birthday", with: "")
            .replacingOccurrences(of: "'s birthday", with: "")
    }
}

// MARK: - Thread-Safe Calendar Access
private var sharedISO8601Calendar: Calendar {
    // Each access creates a new instance, avoiding thread safety issues
    // Calendar creation is lightweight and this ensures thread safety in widget timelines
    var cal = Calendar(identifier: .iso8601)
    cal.timeZone = .autoupdatingCurrent
    cal.locale = .autoupdatingCurrent
    return cal
}

// MARK: - Widget Entry
struct VeckaWidgetEntry: TimelineEntry {
    let date: Date
    let todaysEvents: [EKEvent]
    let weekEvents: [Date: [EKEvent]]
    let upcomingEvent: EKEvent?
    let todaysHolidays: [WidgetHoliday]  // Today's holidays
    let upcomingHolidays: [WidgetHoliday]  // Upcoming holidays
    let todaysBirthdays: [WidgetBirthday]  // Today's birthdays (情報デザイン)
    let weekBirthdays: [Date: [WidgetBirthday]]  // Week birthdays for calendar view
    let calendarAccessDenied: Bool  // Shows feedback when calendar permission denied

    var weekNumber: Int {
        sharedISO8601Calendar.component(.weekOfYear, from: date)
    }

    var year: Int {
        sharedISO8601Calendar.component(.yearForWeekOfYear, from: date)
    }

    var weekday: Int {
        sharedISO8601Calendar.component(.weekday, from: date)
    }

    var dayNumber: Int {
        sharedISO8601Calendar.component(.day, from: date)
    }

    var weekdayName: String {
        date.formatted(.dateTime.weekday(.wide)).uppercased()
    }

    var monthName: String {
        date.formatted(.dateTime.month(.wide))
    }

    // Helper to get color in view (uses 情報デザイン colors)
    func dayColor(for mode: WidgetRenderingMode) -> Color {
        // Sunday = blue, other days = black (情報デザイン style)
        switch weekday {
        case 1: return JohoWidgetColors.sundayBlue
        default: return JohoWidgetColors.black
        }
    }

    var weekRange: String {
        guard let weekStart = sharedISO8601Calendar.dateInterval(of: .weekOfYear, for: date)?.start,
              let weekEnd = sharedISO8601Calendar.date(byAdding: .day, value: 6, to: weekStart)
        else { return "" }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) – \(formatter.string(from: weekEnd))"
    }

    var currentDate: String {
        date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    var hasEventsToday: Bool {
        !todaysEvents.isEmpty
    }

    var hasTodaysHolidays: Bool {
        !todaysHolidays.isEmpty
    }

    var hasTodaysBirthdays: Bool {
        !todaysBirthdays.isEmpty
    }

    // Preview data
    static var preview: VeckaWidgetEntry {
        let engine = WidgetHolidayEngine()
        let today = Date()
        return VeckaWidgetEntry(
            date: today,
            todaysEvents: [],
            weekEvents: [:],
            upcomingEvent: nil,
            todaysHolidays: engine.getHolidays(for: today),
            upcomingHolidays: engine.getUpcomingHolidays(from: today, days: 30),
            todaysBirthdays: [],
            weekBirthdays: [:],
            calendarAccessDenied: false
        )
    }
}
