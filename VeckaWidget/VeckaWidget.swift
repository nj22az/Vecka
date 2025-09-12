//
//  VeckaWidget.swift
//  VeckaWidget
//
//  Complete WidgetKit implementation for Vecka app
//  Features:
//  - Three widget sizes (Small, Medium, Large) following Apple HIG
//  - iPhone calendar events integration with graceful fallback
//  - Small widget: Week number with event indicator
//  - Medium widget: Week number with today's events or next upcoming event
//  - Large widget: 7-day calendar with event indicators for each day
//  - Planetary color system for daily theming
//  - Deep linking support for seamless app navigation
//  - Full accessibility support with VoiceOver
//  - Midnight refresh timeline for accurate week changes
//
//  Created by Nils Johansson on 2025-09-11.
//

import WidgetKit
import SwiftUI
import Foundation
import EventKit

// MARK: - Widget Timeline Provider
struct VeckaWidgetProvider: TimelineProvider {
    typealias Entry = VeckaWidgetEntry
    
    // Calendar instance for ISO week calculations
    private static let isoCalendar: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .autoupdatingCurrent
        calendar.locale = .autoupdatingCurrent
        return calendar
    }()
    
    private let eventStore = EKEventStore()
    
    private var isCalendarAuthorized: Bool {
        if #available(iOS 17.0, *) {
            // For reading events, require fullAccess on iOS 17+
            return EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            return EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }
    
    func placeholder(in context: Context) -> VeckaWidgetEntry {
        VeckaWidgetEntry(date: Date(), todaysEvents: [], weekEvents: [:], upcomingEvent: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (VeckaWidgetEntry) -> Void) {
        let now = Date()
        fetchCalendarEvents(for: now) { todaysEvents, weekEvents, upcomingEvent in
            let entry = VeckaWidgetEntry(date: now, todaysEvents: todaysEvents, weekEvents: weekEvents, upcomingEvent: upcomingEvent)
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<VeckaWidgetEntry>) -> Void) {
        let now = Date()
        let calendar = Self.isoCalendar
        
        fetchCalendarEvents(for: now) { todaysEvents, weekEvents, upcomingEvent in
            // Create entry for current time
            let currentEntry = VeckaWidgetEntry(date: now, todaysEvents: todaysEvents, weekEvents: weekEvents, upcomingEvent: upcomingEvent)
            
            // Calculate next midnight for timeline refresh
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            guard let nextMidnight = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: tomorrow)) else {
                completion(Timeline(entries: [currentEntry], policy: .after(calendar.date(byAdding: .hour, value: 1, to: now) ?? now)))
                return
            }
            
            // Create next entry for after midnight (with fresh calendar data)
            self.fetchCalendarEvents(for: nextMidnight) { tomorrowEvents, tomorrowWeekEvents, tomorrowUpcoming in
                let nextEntry = VeckaWidgetEntry(date: nextMidnight, todaysEvents: tomorrowEvents, weekEvents: tomorrowWeekEvents, upcomingEvent: tomorrowUpcoming)
                let timeline = Timeline(entries: [currentEntry, nextEntry], policy: .after(nextMidnight))
                completion(timeline)
            }
        }
    }
    
    // MARK: - Calendar Event Fetching
    private func fetchCalendarEvents(for date: Date, completion: @escaping ([EKEvent], [Date: [EKEvent]], EKEvent?) -> Void) {
        guard isCalendarAuthorized else {
            completion([], [:], nil)
            return
        }
        
        let calendar = Self.isoCalendar
        let startOfDay = calendar.startOfDay(for: date)
        
        // Get week range for week events
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            completion([], [:], nil)
            return
        }
        
        let weekStart = weekInterval.start
        let weekEnd = weekInterval.end
        
        // Fetch events for the week
        let weekPredicate = eventStore.predicateForEvents(withStart: weekStart, end: weekEnd, calendars: nil)
        let weekEvents = eventStore.events(matching: weekPredicate)
        
        // Organize events by day
        var eventsByDay: [Date: [EKEvent]] = [:]
        for event in weekEvents {
            let eventDay = calendar.startOfDay(for: event.startDate)
            eventsByDay[eventDay, default: []].append(event)
        }
        
        // Get today's events
        let todaysEvents = eventsByDay[startOfDay] ?? []
        
        // Get upcoming event (next event from now)
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) else {
            completion(todaysEvents, eventsByDay, nil)
            return
        }
        
        let upcomingPredicate = eventStore.predicateForEvents(withStart: date, end: nextMonth, calendars: nil)
        let upcomingEvents = eventStore.events(matching: upcomingPredicate)
        
        let upcomingEvent = upcomingEvents
            .filter { $0.startDate >= date }
            .sorted { $0.startDate < $1.startDate }
            .first
        
        completion(todaysEvents, eventsByDay, upcomingEvent)
    }
}

// MARK: - Widget Entry
struct VeckaWidgetEntry: TimelineEntry {
    let date: Date
    let todaysEvents: [EKEvent]
    let weekEvents: [Date: [EKEvent]]
    let upcomingEvent: EKEvent?
    
    // Computed properties for widget data
    var weekNumber: Int {
        return Self.isoCalendar.component(.weekOfYear, from: date)
    }
    
    var year: Int {
        return Self.isoCalendar.component(.yearForWeekOfYear, from: date)
    }
    
    var dayColor: Color {
        return Self.colorForDay(date)
    }
    
    var weekRange: String {
        let calendar = Self.isoCalendar
        let dateFormatter = Self.weekDateFormatter
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start,
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return ""
        }
        
        return "\(dateFormatter.string(from: weekStart)) – \(dateFormatter.string(from: weekEnd))"
    }
    
    var currentDate: String {
        return Self.currentDateFormatter.string(from: date)
    }
    
    var hasEventsToday: Bool {
        return !todaysEvents.isEmpty
    }
    
    var nextEventTitle: String? {
        return upcomingEvent?.title
    }
    
    var nextEventTime: String? {
        guard let event = upcomingEvent else { return nil }
        let formatter = Self.timeFormatter
        if event.isAllDay {
            return "All day"
        } else {
            return formatter.string(from: event.startDate)
        }
    }
    
    // Static instances for performance
    private static let isoCalendar: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .autoupdatingCurrent
        calendar.locale = .autoupdatingCurrent
        return calendar
    }()
    
    private static let weekDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        return formatter
    }()
    
    private static let currentDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        return formatter
    }()
    
    static let relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    // MARK: - Color System (Simplified for Widget)
    static func colorForDay(_ date: Date) -> Color {
        let weekday = isoCalendar.component(.weekday, from: date)
        
        switch weekday {
        case 1: return Color(red: 1.0, green: 0.843, blue: 0.0)      // Sunday - Sun (Gold)
        case 2: return Color(red: 0.753, green: 0.753, blue: 0.753) // Monday - Moon (Silver)
        case 3: return Color(red: 0.898, green: 0.243, blue: 0.243) // Tuesday - Fire (Red)
        case 4: return Color(red: 0.106, green: 0.427, blue: 0.937) // Wednesday - Water (Blue)
        case 5: return Color(red: 0.220, green: 0.631, blue: 0.412) // Thursday - Wood (Green)
        case 6: return Color(red: 0.722, green: 0.525, blue: 0.043) // Friday - Metal (Dark Gold)
        case 7: return Color(red: 0.545, green: 0.271, blue: 0.075) // Saturday - Earth (Brown)
        default: return Color(.systemBlue)
        }
    }
}

// MARK: - Preview Convenience Init
extension VeckaWidgetEntry {
    /// Convenience initializer for previews and tests
    init(date: Date) {
        self.init(date: date, todaysEvents: [], weekEvents: [:], upcomingEvent: nil)
    }
}

// MARK: - Small Widget (2x2)
struct VeckaSmallWidgetView: View {
    let entry: VeckaWidgetEntry
    
    var body: some View {
        ZStack {
            // Background with subtle glass effect
            Color(.systemBackground)
            
            VStack(spacing: 2) {
                // Brand name and event indicator (top-left aligned)
                HStack {
                    Text("VECKA")
                        .font(.system(size: 8, weight: .medium, design: .default))
                        .foregroundColor(Color(.tertiaryLabel))
                        .textCase(.uppercase)
                        .tracking(1.2)
                    
                    Spacer()
                    
                    // Event indicator
                    if entry.hasEventsToday {
                        Circle()
                            .fill(entry.dayColor)
                            .frame(width: 6, height: 6)
                    }
                }
                
                Spacer()
                
                // Week number (main content)
                Text("\(entry.weekNumber)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(entry.dayColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                // Year (secondary)
                Text("\(entry.year)")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(Color(.secondaryLabel))
                
                Spacer()
            }
            .padding(16)
        }
        .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        .accessibilityLabel("Week \(entry.weekNumber), \(entry.year)\(entry.hasEventsToday ? ", has events today" : "")")
        .accessibilityHint("Opens Vecka app to show week \(entry.weekNumber)")
    }
}

// MARK: - Medium Widget (4x2)
struct VeckaMediumWidgetView: View {
    let entry: VeckaWidgetEntry
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
            
            HStack(spacing: 20) {
                // Left side - Week number
                VStack(spacing: 4) {
                    Text("VECKA")
                        .font(.system(size: 8, weight: .medium, design: .default))
                        .foregroundColor(Color(.tertiaryLabel))
                        .textCase(.uppercase)
                        .tracking(1.2)
                    
                    Text("\(entry.weekNumber)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(entry.dayColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                
                // Right side - Date information
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Week Range")
                            .font(.system(size: 11, weight: .medium, design: .default))
                            .foregroundColor(Color(.tertiaryLabel))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text(entry.weekRange)
                            .font(.system(size: 15, weight: .semibold, design: .default))
                            .foregroundColor(Color(.label))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today")
                            .font(.system(size: 11, weight: .medium, design: .default))
                            .foregroundColor(Color(.tertiaryLabel))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text(entry.currentDate)
                            .font(.system(size: 13, weight: .medium, design: .default))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    
                    // Calendar events for today or next upcoming event
                    if !entry.todaysEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Today")
                                .font(.system(size: 11, weight: .medium, design: .default))
                                .foregroundColor(Color(.tertiaryLabel))
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            if let firstEvent = entry.todaysEvents.first {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(firstEvent.title ?? "Untitled Event")
                                        .font(.system(size: 13, weight: .medium, design: .default))
                                        .foregroundColor(entry.dayColor)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    
                                    if !firstEvent.isAllDay {
                                        Text(VeckaWidgetEntry.timeFormatter.string(from: firstEvent.startDate))
                                            .font(.system(size: 11, weight: .regular, design: .default))
                                            .foregroundColor(Color(.secondaryLabel))
                                    }
                                }
                                
                                if entry.todaysEvents.count > 1 {
                                    Text("+\(entry.todaysEvents.count - 1) more")
                                        .font(.system(size: 10, weight: .regular, design: .default))
                                        .foregroundColor(Color(.tertiaryLabel))
                                }
                            }
                        }
                    } else if let upcomingEvent = entry.upcomingEvent {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next Event")
                                .font(.system(size: 11, weight: .medium, design: .default))
                                .foregroundColor(Color(.tertiaryLabel))
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(upcomingEvent.title ?? "Untitled Event")
                                    .font(.system(size: 13, weight: .medium, design: .default))
                                    .foregroundColor(entry.dayColor)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text(VeckaWidgetEntry.relativeDateFormatter.string(from: upcomingEvent.startDate))
                                    .font(.system(size: 11, weight: .regular, design: .default))
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
        }
        .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        .accessibilityLabel("Week \(entry.weekNumber), \(entry.year). \(entry.weekRange). Today is \(entry.currentDate)\(entry.hasEventsToday ? ". Has \(entry.todaysEvents.count) events today" : entry.upcomingEvent != nil ? ". Next event: \(entry.upcomingEvent?.title ?? "")" : "")")
        .accessibilityHint("Opens Vecka app to show week \(entry.weekNumber)")
    }
}

// MARK: - Large Widget (4x4)
struct VeckaLargeWidgetView: View {
    let entry: VeckaWidgetEntry
    
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "Europe/Stockholm") ?? TimeZone.current
        calendar.locale = Locale(identifier: "sv_SE")
        return calendar
    }()
    
    private var weekDates: [Date] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: entry.date)?.start else {
            return []
        }
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.timeZone = TimeZone(identifier: "Europe/Stockholm")
        return formatter
    }()
    
    private let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.timeZone = TimeZone(identifier: "Europe/Stockholm")
        return formatter
    }()
    
    var body: some View { mainView }

    // Split into smaller subviews to aid type-checker
    @ViewBuilder private var mainView: some View {
        ZStack {
            Color(.systemBackground)
            VStack(spacing: 16) {
                headerSection
                weekGridSection
                Spacer()
            }
            .padding(16)
        }
        .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        .accessibilityLabel("Week \(entry.weekNumber), \(entry.year). 7-day calendar view with today highlighted and event indicators")
        .accessibilityHint("Opens Vecka app to show week \(entry.weekNumber)")
    }

    @ViewBuilder private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("VECKA")
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundColor(Color(.tertiaryLabel))
                    .textCase(.uppercase)
                    .tracking(1.2)
                Text("\(entry.weekNumber)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(entry.dayColor)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.weekRange)
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(Color(.label))
                if entry.hasEventsToday {
                    Text("\(entry.todaysEvents.count) event\(entry.todaysEvents.count == 1 ? "" : "s") today")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(entry.dayColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    @ViewBuilder private var weekGridSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    Text(dayFormatter.string(from: date))
                        .font(.system(size: 11, weight: .medium, design: .default))
                        .foregroundColor(Color(.tertiaryLabel))
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    let isToday = calendar.isDate(date, inSameDayAs: entry.date)
                    let dayEvents = entry.weekEvents[calendar.startOfDay(for: date)] ?? []
                    VStack(spacing: 2) {
                        Text(dayNumberFormatter.string(from: date))
                            .font(.system(size: 16, weight: isToday ? .bold : .medium, design: .default))
                            .foregroundColor(isToday ? entry.dayColor : Color(.label))
                            .frame(minHeight: 24)
                            .background(
                                Circle().fill(isToday ? entry.dayColor.opacity(0.15) : Color.clear)
                            )
                        if !dayEvents.isEmpty {
                            HStack(spacing: 1) {
                                ForEach(0..<min(dayEvents.count, 3), id: \.self) { _ in
                                    Circle().fill(VeckaWidgetEntry.colorForDay(date)).frame(width: 3, height: 3)
                                }
                                if dayEvents.count > 3 {
                                    Text("•")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(VeckaWidgetEntry.colorForDay(date))
                                }
                            }.frame(height: 8)
                        } else {
                            Spacer().frame(height: 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Widget Configuration
struct VeckaWidget: Widget {
    let kind: String = "VeckaWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VeckaWidgetProvider()) { entry in
            VeckaWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Vecka")
        .description("Show the current week number with iPhone calendar events and daily planetary colors.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Widget Entry View
struct VeckaWidgetEntryView: View {
    let entry: VeckaWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            VeckaSmallWidgetView(entry: entry)
        case .systemMedium:
            VeckaMediumWidgetView(entry: entry)
        case .systemLarge:
            VeckaLargeWidgetView(entry: entry)
        default:
            VeckaSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle
@main
struct VeckaWidgetBundle: WidgetBundle {
    var body: some Widget {
        VeckaWidget()
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    VeckaWidget()
} timeline: {
    VeckaWidgetEntry(date: Date())
    VeckaWidgetEntry(date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
}

#Preview(as: .systemMedium) {
    VeckaWidget()
} timeline: {
    VeckaWidgetEntry(date: Date())
}

#Preview(as: .systemLarge) {
    VeckaWidget()
} timeline: {
    VeckaWidgetEntry(date: Date())
}
