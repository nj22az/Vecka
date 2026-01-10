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
    let trips: [TravelTrip]  // 情報デザイン: Trips data for week view
    let onDayTap: (CalendarDay) -> Void

    @State private var eventManager = CalendarEventManager()
    @State private var expandedDays: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JohoDimensions.spacingLG) {
                // Redesigned header - inline week badge + date range
                weekHeader
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingSM)

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
                            trips: tripsFor(day),  // 情報デザイン: Pass trips for day
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

    private func tripsFor(_ day: CalendarDay) -> [TravelTrip] {
        // 情報デザイン: Check if day falls within any trip's date range
        let calendar = Calendar.iso8601
        let dayStart = calendar.startOfDay(for: day.date)
        return trips.filter { trip in
            let tripStart = calendar.startOfDay(for: trip.startDate)
            let tripEnd = calendar.startOfDay(for: trip.endDate)
            return dayStart >= tripStart && dayStart <= tripEnd
        }
    }
}

// MARK: - Week Detail Sheet Content (iPhone)

/// Full-width version for bottom sheet on iPhone
struct WeekDetailSheetContent: View {
    let week: CalendarWeek
    let selectedDay: CalendarDay?
    let notes: [DailyNote]
    let holidays: [HolidayCacheItem]
    let trips: [TravelTrip]  // 情報デザイン: Trips data for week view
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
                            trips: tripsFor(day),  // 情報デザイン: Pass trips for day
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
                             !tripsFor(day).isEmpty ||
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

    private func tripsFor(_ day: CalendarDay) -> [TravelTrip] {
        // 情報デザイン: Check if day falls within any trip's date range
        let calendar = Calendar.iso8601
        let dayStart = calendar.startOfDay(for: day.date)
        return trips.filter { trip in
            let tripStart = calendar.startOfDay(for: trip.startDate)
            let tripEnd = calendar.startOfDay(for: trip.endDate)
            return dayStart >= tripStart && dayStart <= tripEnd
        }
    }
}

// MARK: - Collapsible Day Card (情報デザイン: Star Pages Golden Standard)
//
// 情報デザイン BENTO LAYOUT - Matches Star Pages exactly
// ┌────────────────────────────────────────────────────────────────┐
// │ [TUE 6]  January 6, 2026              [TODAY] ●●● ▼           │
// ├────────────────────────────────────────────────────────────────┤
// │ ┌─────────────────────────────────────────────────────┬──────┐ │
// │ │ [HOLIDAYS]                                          │  ★   │ │
// │ ├──────┬──────────────────────────────────────────────┼──────┤ │
// │ │ ●🔒  │ Epiphany                                     │ [SWE]│ │
// │ └──────┴──────────────────────────────────────────────┴──────┘ │
// └────────────────────────────────────────────────────────────────┘

struct CollapsibleDayCard: View {
    let day: CalendarDay
    let isSelected: Bool
    let isExpanded: Bool
    let calendarEvents: [EKEvent]
    let notes: [DailyNote]
    let holidays: [HolidayCacheItem]
    let trips: [TravelTrip]
    let onTap: () -> Void
    let onToggle: () -> Void

    private let calendar = Calendar.iso8601

    /// 情報デザイン: Filter calendar events to remove holiday duplicates
    /// EventKit often includes Swedish holidays like "Trettondedag jul" which duplicate
    /// our HolidayManager entries like "Epiphany"
    private var filteredCalendarEvents: [EKEvent] {
        // If no holidays on this day, show all events
        guard !holidays.isEmpty else { return calendarEvents }

        // Known Swedish/system holiday patterns to filter
        let holidayPatterns = [
            "trettondedag", "nyårsdagen", "juldagen", "annandag",
            "första maj", "nationaldag", "midsommar", "alla helgon",
            "långfredag", "påsk", "kristi", "pingstdag",
            "epiphany", "christmas", "new year", "easter",
            "good friday", "ascension", "whit", "midsummer"
        ]

        return calendarEvents.filter { event in
            guard let title = event.title?.lowercased() else { return true }

            // Skip all-day events that match holiday patterns
            if event.isAllDay {
                for pattern in holidayPatterns {
                    if title.contains(pattern) {
                        return false // Filter out this holiday duplicate
                    }
                }
            }
            return true
        }
    }

    private var hasContent: Bool {
        !filteredCalendarEvents.isEmpty || !notes.isEmpty || !holidays.isEmpty || !trips.isEmpty
    }

    /// Days from today (negative = past, positive = future)
    private var daysFromToday: Int {
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: day.date)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row (always visible)
            headerRow

            // Expanded content
            if isExpanded {
                // Thin divider
                Rectangle()
                    .fill(JohoColors.black.opacity(0.15))
                    .frame(height: 1)

                expandedContent
                    .padding(.top, JohoDimensions.spacingSM)
                    .padding(.bottom, JohoDimensions.spacingMD)
            }
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: day.isToday ? JohoDimensions.borderThick : JohoDimensions.borderMedium)
        )
    }

    // MARK: - Header Row (情報デザイン: Star Pages style)

    private var headerRow: some View {
        Button(action: onToggle) {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Day badge: [TUE 6]
                dayBadge

                // Full date: January 6, 2026 (Star Pages format)
                Text(fullDateText)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)

                Spacer()

                // Status indicators
                HStack(spacing: JohoDimensions.spacingXS) {
                    // Date status pill (情報デザイン: TODAY, YESTERDAY, or X DAYS AGO)
                    dateStatusPill

                    // Content indicator dots (when collapsed)
                    if !isExpanded && hasContent {
                        contentIndicatorDots
                    }

                    // Expand/collapse chevron
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Day Badge (情報デザイン: [TUE 6] format)

    private var dayBadge: some View {
        HStack(spacing: 4) {
            Text(weekdayShort)
                .font(JohoFont.labelSmall)
            Text("\(day.dayNumber)")
                .font(JohoFont.headline)
        }
        .foregroundStyle(day.isToday ? JohoColors.black : JohoColors.black)
        .padding(.horizontal, JohoDimensions.spacingSM)
        .padding(.vertical, JohoDimensions.spacingXS)
        .background(day.isToday ? JohoColors.yellow : JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
        )
    }

    // MARK: - Date Status Pill (情報デザイン: Temporal context)

    @ViewBuilder
    private var dateStatusPill: some View {
        if daysFromToday == 0 {
            // TODAY - Yellow inverted pill
            JohoPill(text: "TODAY", style: .coloredInverted(JohoColors.yellow), size: .small)
        } else if daysFromToday == -1 {
            // YESTERDAY - Muted gray pill
            JohoPill(text: "YESTERDAY", style: .muted, size: .small)
        } else if daysFromToday < -1 {
            // X DAYS AGO - Muted gray pill
            JohoPill(text: "\(abs(daysFromToday)) DAYS AGO", style: .muted, size: .small)
        }
        // Future dates: no status pill shown
    }

    // MARK: - Content Indicator Dots (情報デザイン: Colored circles with BLACK borders)

    private var contentIndicatorDots: some View {
        HStack(spacing: 3) {
            if !holidays.isEmpty {
                Circle()
                    .fill(SpecialDayType.holiday.accentColor)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
            if !filteredCalendarEvents.isEmpty {
                Circle()
                    .fill(SpecialDayType.event.accentColor)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
            if !notes.isEmpty {
                Circle()
                    .fill(SpecialDayType.note.accentColor)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
            if !trips.isEmpty {
                Circle()
                    .fill(SpecialDayType.trip.accentColor)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
        }
    }

    // MARK: - Expanded Content (情報デザイン: Bento sections)

    @ViewBuilder
    private var expandedContent: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                // Holidays section (pink background)
                if !holidays.isEmpty {
                    bentoSection(
                        title: "Holidays",
                        icon: "star.fill",
                        zone: .holidays
                    ) {
                        ForEach(holidays, id: \.id) { holiday in
                            bentoItemRow(
                                title: holiday.displayTitle,
                                type: .holiday,
                                isSystem: true,
                                region: holiday.region
                            )
                        }
                    }
                }

                // Calendar events section (purple/cyan) - filtered to remove holiday duplicates
                if !filteredCalendarEvents.isEmpty {
                    bentoSection(
                        title: "Events",
                        icon: "calendar.badge.clock",
                        zone: .calendar
                    ) {
                        ForEach(filteredCalendarEvents, id: \.eventIdentifier) { event in
                            bentoItemRow(
                                title: event.title ?? "Event",
                                type: .event,
                                isSystem: false,
                                time: event.isAllDay ? nil : formatTime(event.startDate)
                            )
                        }
                    }
                }

                // Notes section (yellow)
                if !notes.isEmpty {
                    bentoSection(
                        title: "Notes",
                        icon: "note.text",
                        zone: .notes
                    ) {
                        ForEach(notes) { note in
                            bentoItemRow(
                                title: firstLine(of: note.content),
                                type: .note,
                                isSystem: false
                            )
                        }
                    }
                }

                // Trips section (blue/orange)
                if !trips.isEmpty {
                    bentoSection(
                        title: "Trips",
                        icon: "airplane",
                        zone: .trips
                    ) {
                        ForEach(trips) { trip in
                            bentoItemRow(
                                title: trip.destination,
                                type: .trip,
                                isSystem: false
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
        } else {
            EmptyView()
        }
    }

    // MARK: - Bento Section Box (情報デザイン: Star Pages style with wall)
    //
    // ┌───────────────────────────────────────────────┬──────┐
    // │ [HOLIDAYS]                                    │  ★   │
    // ├───────────────────────────────────────────────┴──────┤
    // │ Items...                                              │
    // └───────────────────────────────────────────────────────┘

    @ViewBuilder
    private func bentoSection<Content: View>(
        title: String,
        icon: String,
        zone: SectionZone,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header with icon compartment
            HStack(spacing: 0) {
                // LEFT: Title pill
                JohoPill(text: title.uppercased(), style: .whiteOnBlack, size: .small)
                    .padding(.leading, JohoDimensions.spacingMD)

                Spacer()

                // WALL (vertical divider)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Icon compartment
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 40)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 32)
            .background(zone.background.opacity(0.5))

            // Horizontal divider
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // Items
            VStack(spacing: 0) {
                content()
            }
            .padding(.vertical, 4)
        }
        .background(zone.background)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Bento Item Row (情報デザイン: Compartmentalized with walls)
    //
    // ┌──────┬────────────────────────────────────┬─────────┐
    // │ ●🔒  │ Epiphany                           │ [SWE]   │
    // └──────┴────────────────────────────────────┴─────────┘

    @ViewBuilder
    private func bentoItemRow(
        title: String,
        type: SpecialDayType,
        isSystem: Bool,
        region: String? = nil,
        time: String? = nil
    ) -> some View {
        HStack(spacing: 0) {
            // LEFT COMPARTMENT: Type indicator (fixed 32pt)
            HStack(alignment: .center, spacing: 3) {
                Circle()
                    .fill(type.accentColor)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))

                if isSystem {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
            }
            .frame(width: 32, alignment: .center)
            .frame(maxHeight: .infinity)

            // WALL (vertical divider)
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER COMPARTMENT: Title (flexible)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)

                if let time = time {
                    Text(time)
                        .font(JohoFont.monoSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
            }
            .padding(.horizontal, 8)
            .frame(maxHeight: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            // WALL (vertical divider) - only if we have right content
            if region != nil {
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT COMPARTMENT: Region pill
                if let region = region, !region.isEmpty {
                    CountryPill(region: region)
                        .padding(.horizontal, 6)
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .frame(minHeight: 36)
        .contentShape(Rectangle())
    }

    // MARK: - Formatters

    private var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day.date).uppercased()
    }

    private var fullDateText: String {
        // 情報デザイン: Star Pages format - "January 6, 2026"
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
}

// MARK: - Event Item View

struct EventItemView: View, Equatable {
    let time: String?
    let title: String
    let icon: String
    var isBankHoliday: Bool = false

    static func == (lhs: EventItemView, rhs: EventItemView) -> Bool {
        lhs.time == rhs.time &&
        lhs.title == rhs.title &&
        lhs.icon == rhs.icon &&
        lhs.isBankHoliday == rhs.isBankHoliday
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
        }
    }

    private var iconBackground: Color {
        if isBankHoliday {
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

        // 情報デザイン: Only fetch from USER calendars, not subscription/holiday calendars
        // This ensures HolidayManager is the SINGLE source of truth for holidays
        let userCalendars = eventStore.calendars(for: .event).filter { cal in
            // Include only editable calendars (user-created events)
            // Exclude: subscription calendars (holidays), birthdays, read-only
            cal.allowsContentModifications &&
            cal.type != .subscription &&
            cal.type != .birthday
        }

        // If no user calendars, return empty
        guard !userCalendars.isEmpty else {
            eventsByDate = [:]
            return
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startOfWeek,
            end: endOfWeek,
            calendars: userCalendars  // Only user calendars
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
            trips: [],
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
        trips: [],
        onDayTap: { _ in }
    )
}
