//
//  WeekDetailPanel.swift
//  Vecka
//
//  Right-side panel showing week details, calendar events, and notes
//  Combines EventKit integration with WeekGrid's daily notes
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

    @StateObject private var eventManager = CalendarEventManager()


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Week Header
            weekHeader
                .padding(.horizontal, Spacing.large)
                .padding(.top, Spacing.large)
                .padding(.bottom, Spacing.medium)

            // Subtle divider
            Rectangle()
                .fill(SlateColors.divider)
                .frame(height: 1)

            // Day-by-day event list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(week.days) { day in
                        DayEventRow(
                            day: day,
                            isSelected: selectedDay?.id == day.id,
                            calendarEvents: eventManager.events(for: day.date),
                            notes: notesFor(day),
                            holidays: holidaysFor(day),
                            onTap: { onDayTap(day) }
                        )
                    }
                }
            }
        }
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
        .background(SlateColors.mediumSlate)
        .onAppear {
            eventManager.requestAccessAndFetchEvents(for: week)
        }
        .onChange(of: week.id) { _, _ in
            eventManager.fetchEvents(for: week)
        }
    }

    // MARK: - Week Header

    private var weekHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            // "WEEK 01" in caps with tracking
            Text("WEEK \(String(format: "%02d", week.weekNumber))")
                .font(Typography.bodySmall.weight(.semibold))
                .tracking(2)
                .foregroundStyle(SlateColors.secondaryText)

            // Date range
            Text(dateRangeText)
                .font(.subheadline)
                .foregroundStyle(SlateColors.primaryText)
        }
    }

    private var dateRangeText: String {
        let calendar = Calendar.iso8601
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: week.startDate) else {
            return ""
        }

        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"

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

        let year = yearFormatter.string(from: week.startDate)
        let start = startFormatter.string(from: week.startDate)
        let end = endFormatter.string(from: endDate)

        return "\(year) · \(start) – \(end)"
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

    @StateObject private var eventManager = CalendarEventManager()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(week.days) { day in
                    DayEventRow(
                        day: day,
                        isSelected: selectedDay?.id == day.id,
                        calendarEvents: eventManager.events(for: day.date),
                        notes: notesFor(day),
                        holidays: holidaysFor(day),
                        onTap: { onDayTap(day) }
                    )
                }
            }
        }
        .background(SlateColors.mediumSlate)
        .onAppear {
            eventManager.requestAccessAndFetchEvents(for: week)
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

// MARK: - Day Event Row

struct DayEventRow: View {
    let day: CalendarDay
    let isSelected: Bool
    let calendarEvents: [EKEvent]
    let notes: [DailyNote]
    let holidays: [HolidayCacheItem]
    let onTap: () -> Void

    private var hasContent: Bool {
        !calendarEvents.isEmpty || !notes.isEmpty || !holidays.isEmpty
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Day column
                dayColumn
                    .frame(width: 44)

                // Events column
                VStack(alignment: .leading, spacing: 6) {
                    // Holidays first
                    ForEach(holidays, id: \.id) { holiday in
                        EventItemView(
                            time: nil,
                            title: holiday.displayTitle,
                            icon: holiday.symbolName ?? "star.fill",
                            color: holiday.isRedDay ? .red : SlateColors.sundayBlue
                        )
                    }

                    // Calendar events
                    ForEach(calendarEvents, id: \.eventIdentifier) { event in
                        EventItemView(
                            time: formatTime(event.startDate),
                            title: event.title ?? "Event",
                            icon: "calendar",
                            color: Color(cgColor: event.calendar.cgColor)
                        )
                    }

                    // Notes
                    ForEach(notes) { note in
                        EventItemView(
                            time: nil,
                            title: firstLine(of: note.content),
                            icon: note.symbolName ?? "note.text",
                            color: noteColor(note)
                        )
                    }

                    // Empty state
                    if !hasContent {
                        Text("No events")
                            .font(.subheadline)
                            .foregroundStyle(SlateColors.tertiaryText)
                            .padding(.vertical, Spacing.extraSmall)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.small)
            .background(isSelected ? SlateColors.selectionHighlight : Color.clear)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Day Column

    private var dayColumn: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(weekdayShort)
                .font(.caption2.weight(.medium))
                .foregroundStyle(SlateColors.tertiaryText)

            Text("\(day.dayNumber)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(dayColor)
        }
    }

    private var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day.date).uppercased()
    }

    private var dayColor: Color {
        let weekday = Calendar.iso8601.component(.weekday, from: day.date)
        if weekday == 1 { // Sunday
            return SlateColors.sundayBlue
        }
        if day.isToday {
            return SlateColors.sidebarActiveBar
        }
        return SlateColors.primaryText
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func firstLine(of text: String) -> String {
        text.components(separatedBy: .newlines).first ?? text
    }

    private func noteColor(_ note: DailyNote) -> Color {
        switch note.color {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        default: return SlateColors.secondaryText
        }
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

struct EventItemView: View {
    let time: String?
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            if let time = time {
                Text(time)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(SlateColors.secondaryText)
                    .frame(width: 40, alignment: .leading)
            }

            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 16)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(SlateColors.primaryText)
                .lineLimit(1)
        }
    }
}

// MARK: - Calendar Event Manager

@MainActor
class CalendarEventManager: ObservableObject {
    @Published private(set) var eventsByDate: [Date: [EKEvent]] = [:]
    @Published private(set) var hasCalendarAccess = false

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
            .fill(SlateColors.deepSlate)
            .frame(width: 300)

        WeekDetailPanel(
            week: currentWeek,
            selectedDay: nil,
            notes: [],
            holidays: [],
            onDayTap: { _ in }
        )
    }
    .frame(width: 600, height: 500)
    .preferredColorScheme(.dark)
}
