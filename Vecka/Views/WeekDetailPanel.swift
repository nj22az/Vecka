//
//  WeekDetailPanel.swift
//  Vecka
//
//  Right-side panel showing week details, calendar events, and notes
//  Combines EventKit integration with WeekGrid's daily notes
//  Uses Joho Design System - authentic Japanese packaging aesthetic
//

import SwiftUI
import EventKit
import SwiftData

// MARK: - Week Detail Panel

struct WeekDetailPanel: View {
    let week: CalendarWeek
    let selectedDay: CalendarDay?
    let notes: [DailyNote]
    let holidays: [HolidayCacheItem]
    let onDayTap: (CalendarDay) -> Void

    @State private var eventManager = CalendarEventManager()
    @State private var expandedDays: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JohoDimensions.spacingLG) {
                // Redesigned header - inline week badge + date range
                weekHeader
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingLG)

                // Week summary statistics (no "7 days" - show holidays instead)
                weekSummaryStats
                    .padding(.horizontal, JohoDimensions.spacingLG)

                // Day-by-day breakdown with more spacing
                VStack(spacing: JohoDimensions.spacingMD) {
                    ForEach(week.days) { day in
                        CollapsibleDayCard(
                            day: day,
                            isSelected: selectedDay?.id == day.id,
                            isExpanded: isExpanded(day),
                            calendarEvents: eventManager.events(for: day.date),
                            notes: notesFor(day),
                            holidays: holidaysFor(day),
                            onTap: { onDayTap(day) },
                            onToggle: { toggleExpand(day) }
                        )
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.bottom, JohoDimensions.spacingLG)
            }
        }
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
        .johoBackground()
        .onAppear {
            eventManager.requestAccessAndFetchEvents(for: week)
            initializeExpandedDays()
        }
        .onChange(of: week.id) { _, _ in
            eventManager.fetchEvents(for: week)
            initializeExpandedDays()
        }
    }

    // MARK: - Week Header (Redesigned)

    private var weekHeader: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            HStack(alignment: .center, spacing: JohoDimensions.spacingMD) {
                JohoPill(text: "Week \(week.weekNumber)", style: .whiteOnBlack, size: .large)

                Spacer()

                Text(dateRangeText)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.white.opacity(0.7))
            }
        }
    }

    // MARK: - Expand/Collapse Logic

    private func isExpanded(_ day: CalendarDay) -> Bool {
        expandedDays.contains(day.id)
    }

    private func toggleExpand(_ day: CalendarDay) {
        if expandedDays.contains(day.id) {
            expandedDays.remove(day.id)
        } else {
            expandedDays.insert(day.id)
        }
    }

    private func initializeExpandedDays() {
        expandedDays.removeAll()
        // Auto-expand today and selected day
        for day in week.days {
            let hasContent = !notesFor(day).isEmpty ||
                             !holidaysFor(day).isEmpty ||
                             !eventManager.events(for: day.date).isEmpty
            if day.isToday || hasContent || selectedDay?.id == day.id {
                expandedDays.insert(day.id)
            }
        }
    }

    // MARK: - Week Summary Stats

    private var weekSummaryStats: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            JohoStatBox(
                value: "\(calendarEventsCount)",
                label: "Events",
                zone: .calendar
            )

            JohoStatBox(
                value: "\(holidaysCount)",
                label: "Holidays",
                zone: .holidays
            )

            JohoStatBox(
                value: "\(notesCount)",
                label: "Notes",
                zone: .notes
            )
        }
    }

    private var calendarEventsCount: Int {
        week.days.reduce(0) { count, day in
            count + eventManager.events(for: day.date).count
        }
    }

    private var holidaysCount: Int {
        week.days.reduce(0) { count, day in
            count + holidaysFor(day).count
        }
    }

    private var notesCount: Int {
        week.days.reduce(0) { count, day in
            count + notesFor(day).count
        }
    }

    private var dateRangeText: String {
        let calendar = Calendar.iso8601
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: week.startDate) else {
            return ""
        }

        let startFormatter = DateFormatter()
        let endFormatter = DateFormatter()

        // Check if start and end are in different months
        let startMonth = calendar.component(.month, from: week.startDate)
        let endMonth = calendar.component(.month, from: endDate)

        if startMonth == endMonth {
            startFormatter.dateFormat = "MMM d"
            endFormatter.dateFormat = "d"
        } else {
            startFormatter.dateFormat = "MMM d"
            endFormatter.dateFormat = "MMM d"
        }

        let start = startFormatter.string(from: week.startDate)
        let end = endFormatter.string(from: endDate)

        return "\(start) – \(end)"
    }

    // MARK: - Data Helpers

    private func notesFor(_ day: CalendarDay) -> [DailyNote] {
        notes.filter { Calendar.iso8601.isDate($0.date, inSameDayAs: day.date) }
    }

    private func holidaysFor(_ day: CalendarDay) -> [HolidayCacheItem] {
        // Holidays are passed filtered for the week, check if day has holiday via CalendarDay
        if day.isHoliday {
            return holidays.filter { $0.displayTitle == day.holidayName }
        }
        return []
    }
}

// MARK: - Week Detail Sheet Content (iPhone)

/// Full-width version for bottom sheet on iPhone
struct WeekDetailSheetContent: View {
    let week: CalendarWeek
    let selectedDay: CalendarDay?
    let notes: [DailyNote]
    let holidays: [HolidayCacheItem]
    let onDayTap: (CalendarDay) -> Void

    @State private var eventManager = CalendarEventManager()
    @State private var expandedDays: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JohoDimensions.spacingLG) {
                // Redesigned header - inline week badge + date range
                HStack(alignment: .center, spacing: JohoDimensions.spacingMD) {
                    JohoPill(text: "Week \(week.weekNumber)", style: .whiteOnBlack, size: .large)

                    Spacer()

                    Text(dateRangeText)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.white.opacity(0.7))
                }
                .padding(.horizontal, JohoDimensions.spacingLG)

                // Day-by-day breakdown with more spacing
                VStack(spacing: JohoDimensions.spacingMD) {
                    ForEach(week.days) { day in
                        CollapsibleDayCard(
                            day: day,
                            isSelected: selectedDay?.id == day.id,
                            isExpanded: isExpanded(day),
                            calendarEvents: eventManager.events(for: day.date),
                            notes: notesFor(day),
                            holidays: holidaysFor(day),
                            onTap: { onDayTap(day) },
                            onToggle: { toggleExpand(day) }
                        )
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.bottom, JohoDimensions.spacingLG)
            }
        }
        .johoBackground()
        .onAppear {
            eventManager.requestAccessAndFetchEvents(for: week)
            initializeExpandedDays()
        }
    }

    private var dateRangeText: String {
        let calendar = Calendar.iso8601
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: week.startDate) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: week.startDate)
        let end = formatter.string(from: endDate)
        return "\(start) – \(end)"
    }

    private func isExpanded(_ day: CalendarDay) -> Bool {
        expandedDays.contains(day.id)
    }

    private func toggleExpand(_ day: CalendarDay) {
        if expandedDays.contains(day.id) {
            expandedDays.remove(day.id)
        } else {
            expandedDays.insert(day.id)
        }
    }

    private func initializeExpandedDays() {
        expandedDays.removeAll()
        for day in week.days {
            let hasContent = !notesFor(day).isEmpty ||
                             !holidaysFor(day).isEmpty ||
                             !eventManager.events(for: day.date).isEmpty
            if day.isToday || hasContent || selectedDay?.id == day.id {
                expandedDays.insert(day.id)
            }
        }
    }

    private func notesFor(_ day: CalendarDay) -> [DailyNote] {
        notes.filter { Calendar.iso8601.isDate($0.date, inSameDayAs: day.date) }
    }

    private func holidaysFor(_ day: CalendarDay) -> [HolidayCacheItem] {
        if day.isHoliday {
            return holidays.filter { $0.displayTitle == day.holidayName }
        }
        return []
    }
}

// MARK: - Collapsible Day Card

struct CollapsibleDayCard: View {
    let day: CalendarDay
    let isSelected: Bool
    let isExpanded: Bool
    let calendarEvents: [EKEvent]
    let notes: [DailyNote]
    let holidays: [HolidayCacheItem]
    let onTap: () -> Void
    let onToggle: () -> Void

    private var hasContent: Bool {
        !calendarEvents.isEmpty || !notes.isEmpty || !holidays.isEmpty
    }

    var body: some View {
        JohoCard(
            cornerRadius: JohoDimensions.radiusMedium,
            borderWidth: (isSelected || day.isToday) ? JohoDimensions.borderThick : JohoDimensions.borderMedium
        ) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row (always visible) - tap to select day
                Button(action: onTap) {
                    headerRow
                }
                .buttonStyle(.plain)

                // Expanded content
                if isExpanded {
                    expandedContent
                        .padding(.top, JohoDimensions.spacingSM)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Header Row (Simplified: [TUE 30] + Date)

    private var headerRow: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Combined day badge: [TUE 30]
            HStack(spacing: 4) {
                Text(weekdayShort)
                    .font(JohoFont.labelSmall)
                Text("\(day.dayNumber)")
                    .font(JohoFont.headline)
            }
            .foregroundStyle(dayBadgeTextColor)
            .padding(.horizontal, JohoDimensions.spacingSM)
            .padding(.vertical, JohoDimensions.spacingXS)
            .background(dayBadgeBackground)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
            )

            // Full date
            Text(fullDateText)
                .font(JohoFont.body)
                .foregroundStyle(JohoColors.black)

            Spacer()

            // Status indicators
            HStack(spacing: JohoDimensions.spacingXS) {
                // Today pill (情報デザイン: inverted - yellow bg, white text, black border)
                if day.isToday {
                    JohoPill(text: "TODAY", style: .coloredInverted(JohoColors.yellow), size: .small)
                }

                // Content indicator dots (when collapsed)
                if !isExpanded && hasContent {
                    contentIndicatorDots
                }

                // Expand/collapse chevron - tap to toggle (44pt min touch target)
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Content Indicator Dots (shown when collapsed)

    private var contentIndicatorDots: some View {
        HStack(spacing: 3) {
            if !holidays.isEmpty {
                Circle()
                    .fill(JohoColors.pink)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
            if !calendarEvents.isEmpty {
                Circle()
                    .fill(JohoColors.cyan)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
            if !notes.isEmpty {
                Circle()
                    .fill(JohoColors.yellow)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
        }
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                // Holidays
                if !holidays.isEmpty {
                    JohoSectionBox(title: "Holidays", zone: .holidays, icon: "star.fill") {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                            ForEach(holidays, id: \.id) { holiday in
                                EventItemView(
                                    time: nil,
                                    title: holiday.displayTitle,
                                    icon: holiday.symbolName ?? "star.fill",
                                    isRedDay: holiday.isRedDay
                                )
                            }
                        }
                    }
                }

                // Calendar events
                if !calendarEvents.isEmpty {
                    JohoSectionBox(title: "Events", zone: .calendar, icon: "calendar") {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                            ForEach(calendarEvents, id: \.eventIdentifier) { event in
                                EventItemView(
                                    time: formatTime(event.startDate),
                                    title: event.title ?? "Event",
                                    icon: "calendar"
                                )
                            }
                        }
                    }
                }

                // Notes
                if !notes.isEmpty {
                    JohoSectionBox(title: "Notes", zone: .notes, icon: "note.text") {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                            ForEach(notes) { note in
                                EventItemView(
                                    time: nil,
                                    title: firstLine(of: note.content),
                                    icon: note.symbolName ?? "note.text"
                                )
                            }
                        }
                    }
                }
            }
        } else {
            // Empty state
            Text("No events or notes")
                .font(JohoFont.bodySmall)
                .foregroundStyle(JohoColors.black.opacity(0.6))
                .padding(.vertical, JohoDimensions.spacingXS)
        }
    }

    // MARK: - Day Badge Styling

    private var dayBadgeBackground: Color {
        if isSelected {
            return JohoColors.black
        }
        if day.isToday {
            return JohoColors.yellow
        }
        let weekday = Calendar.iso8601.component(.weekday, from: day.date)
        if weekday == 1 { // Sunday
            return JohoColors.pink.opacity(0.3)
        }
        return JohoColors.white
    }

    private var dayBadgeTextColor: Color {
        if isSelected {
            return JohoColors.white
        }
        return JohoColors.black
    }

    // MARK: - Formatters

    private var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day.date).uppercased()
    }

    private var fullDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: day.date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func firstLine(of text: String) -> String {
        text.components(separatedBy: .newlines).first ?? text
    }

    private var accessibilityLabel: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        var label = dateFormatter.string(from: day.date)

        if !holidays.isEmpty {
            label += ". Holidays: \(holidays.map { $0.displayTitle }.joined(separator: ", "))"
        }
        if !calendarEvents.isEmpty {
            label += ". \(calendarEvents.count) calendar events"
        }
        if !notes.isEmpty {
            label += ". \(notes.count) notes"
        }

        return label
    }
}

// MARK: - Event Item View

struct EventItemView: View, Equatable {
    let time: String?
    let title: String
    let icon: String
    var isRedDay: Bool = false

    static func == (lhs: EventItemView, rhs: EventItemView) -> Bool {
        lhs.time == rhs.time &&
        lhs.title == rhs.title &&
        lhs.icon == rhs.icon &&
        lhs.isRedDay == rhs.isRedDay
    }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Icon badge
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)
                .frame(width: 24, height: 24)
                .background(iconBackground)
                .clipShape(Circle())

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(2)

                if let time = time {
                    Text(time)
                        .font(JohoFont.monoSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
            }

            Spacer()

            // Red day indicator
            if isRedDay {
                JohoPill(text: "Red Day", style: .colored(JohoColors.pink), size: .small)
            }
        }
    }

    private var iconBackground: Color {
        if isRedDay {
            return JohoColors.pink
        }
        return JohoColors.white
    }
}

// MARK: - Calendar Event Manager

@MainActor
@Observable
class CalendarEventManager {
    private(set) var eventsByDate: [Date: [EKEvent]] = [:]
    private(set) var hasCalendarAccess = false

    private let eventStore = EKEventStore()
    private let calendar = Calendar.iso8601

    func requestAccessAndFetchEvents(for week: CalendarWeek) {
        Task {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                hasCalendarAccess = granted
                if granted {
                    fetchEvents(for: week)
                }
            } catch {
                Log.w("Calendar access error: \(error)")
                hasCalendarAccess = false
            }
        }
    }

    func fetchEvents(for week: CalendarWeek) {
        guard hasCalendarAccess else { return }

        let startOfWeek = calendar.startOfDay(for: week.startDate)
        guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else { return }

        let predicate = eventStore.predicateForEvents(
            withStart: startOfWeek,
            end: endOfWeek,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)

        // Group events by date
        var grouped: [Date: [EKEvent]] = [:]
        for event in events {
            let dayStart = calendar.startOfDay(for: event.startDate)
            grouped[dayStart, default: []].append(event)
        }

        // Sort events within each day by start time
        for (date, dayEvents) in grouped {
            grouped[date] = dayEvents.sorted { $0.startDate < $1.startDate }
        }

        eventsByDate = grouped
    }

    func events(for date: Date) -> [EKEvent] {
        let dayStart = calendar.startOfDay(for: date)
        return eventsByDate[dayStart] ?? []
    }
}

// MARK: - Preview

#Preview("Week Detail Panel") {
    let currentMonth = CalendarMonth.current()
    let currentWeek = currentMonth.weeks.first!

    return HStack(spacing: 0) {
        Rectangle()
            .fill(JohoColors.black)
            .frame(width: 300)

        WeekDetailPanel(
            week: currentWeek,
            selectedDay: currentWeek.days.first,
            notes: [],
            holidays: [],
            onDayTap: { _ in }
        )
    }
    .frame(width: 600, height: 500)
}

#Preview("Week Detail Sheet") {
    let currentMonth = CalendarMonth.current()
    let currentWeek = currentMonth.weeks.first!

    return WeekDetailSheetContent(
        week: currentWeek,
        selectedDay: nil,
        notes: [],
        holidays: [],
        onDayTap: { _ in }
    )
}
