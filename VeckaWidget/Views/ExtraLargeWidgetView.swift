//
//  ExtraLargeWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Extra Large Widget (iPad)
//  Horizontal header bento: Week | Today | Upcoming
//  Full calendar grid below
//  Philosophy: All key info at a glance in header, full month view below
//

import SwiftUI
import WidgetKit
import EventKit

struct VeckaExtraLargeWidgetView: View {
    let entry: VeckaWidgetEntry
    private let family: WidgetFamily = .systemExtraLarge

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        cal.locale = .autoupdatingCurrent
        return cal
    }()

    private let holidayEngine = WidgetHolidayEngine()

    // MARK: - Computed Properties

    private var monthYear: String {
        let month = entry.date.formatted(.dateTime.month(.wide).locale(.autoupdatingCurrent)).uppercased()
        let year = String(calendar.component(.year, from: entry.date))
        return "\(month) \(year)"
    }

    private var dayOfMonth: Int {
        calendar.component(.day, from: entry.date)
    }

    private var weekdayShort: String {
        entry.date.formatted(.dateTime.weekday(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var monthShort: String {
        entry.date.formatted(.dateTime.month(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var firstOfMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date)) ?? entry.date
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
    }

    private var firstWeekday: Int {
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        return weekday == 1 ? 7 : weekday - 1
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        return Array(symbols[1...]) + [symbols[0]]
    }

    private var weeksInMonth: [[Int?]] {
        var weeks: [[Int?]] = []
        var currentWeek: [Int?] = Array(repeating: nil, count: 7)
        var dayCounter = 1

        for i in 0..<(firstWeekday - 1) {
            currentWeek[i] = nil
        }

        for i in (firstWeekday - 1)..<7 {
            if dayCounter <= daysInMonth {
                currentWeek[i] = dayCounter
                dayCounter += 1
            }
        }
        weeks.append(currentWeek)

        while dayCounter <= daysInMonth {
            currentWeek = Array(repeating: nil, count: 7)
            for i in 0..<7 {
                if dayCounter <= daysInMonth {
                    currentWeek[i] = dayCounter
                    dayCounter += 1
                }
            }
            weeks.append(currentWeek)
        }
        return weeks
    }

    private var upcomingHolidays: [(holiday: WidgetHoliday, daysUntil: Int)] {
        var holidays: [(holiday: WidgetHoliday, daysUntil: Int)] = []
        for daysAhead in 1...30 {
            if let futureDate = calendar.date(byAdding: .day, value: daysAhead, to: entry.date) {
                let dayHolidays = holidayEngine.getHolidays(for: futureDate)
                for holiday in dayHolidays {
                    holidays.append((holiday, daysAhead))
                }
            }
            if holidays.count >= 6 { break }
        }
        return holidays
    }

    private var isRedDay: Bool {
        entry.todaysHolidays.first?.isRedDay ?? false
    }

    private var isSunday: Bool {
        calendar.component(.weekday, from: entry.date) == 1
    }

    // MARK: - Sizing

    private var borders: JohoWidget.Borders.Weights {
        JohoWidget.Borders.weights(for: family)
    }

    private var corners: JohoWidget.Corners.Radii {
        JohoWidget.Corners.radii(for: family)
    }

    private var spacing: JohoWidget.Spacing.Grid {
        JohoWidget.Spacing.grid(for: family)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // ═══════════════════════════════════════════════
            // HEADER ROW: Week | Today | Upcoming
            // ═══════════════════════════════════════════════
            headerRow

            // HORIZONTAL WALL
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(height: borders.container)

            // ═══════════════════════════════════════════════
            // CALENDAR GRID
            // ═══════════════════════════════════════════════
            calendarSection

            // ═══════════════════════════════════════════════
            // FOOTER: Upcoming Holiday Pills
            // ═══════════════════════════════════════════════
            if !upcomingHolidays.isEmpty {
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(height: borders.row)

                upcomingFooter
            }
        }
        .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            RoundedRectangle(cornerRadius: corners.widget, style: .continuous)
                .fill(JohoWidget.Colors.content)
                .overlay(
                    RoundedRectangle(cornerRadius: corners.widget, style: .continuous)
                        .stroke(JohoWidget.Colors.border, lineWidth: borders.widget)
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Header Row (Horizontal Bento)

    private var headerRow: some View {
        HStack(spacing: 0) {
            // LEFT: Week Badge (hero)
            VStack(spacing: 2) {
                Text("\(entry.weekNumber)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.textInverted)
                Text("WEEK")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.textInverted.opacity(0.7))
            }
            .frame(width: 90)
            .frame(maxHeight: .infinity)
            .background(JohoWidget.Colors.border)

            // VERTICAL WALL
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(width: 1)

            // CENTER: Today Info + Holiday
            HStack(spacing: spacing.md) {
                // Day number
                Text("\(dayOfMonth)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(dayColor)

                // Date details
                VStack(alignment: .leading, spacing: 2) {
                    Text(weekdayShort)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)

                    Text("\(monthShort) \(String(calendar.component(.year, from: entry.date)))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
                }

                // Holiday/Today badge
                if let holiday = entry.todaysHolidays.first {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(holiday.isRedDay ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(JohoWidget.Colors.border, lineWidth: 1))
                        Text(holiday.displayName)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(holiday.isRedDay ? JohoWidget.Colors.holiday.opacity(0.15) : JohoWidget.Colors.event.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(JohoWidget.Colors.border, lineWidth: 1)
                    )
                } else {
                    Text("TODAY")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(JohoWidget.Colors.now)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(JohoWidget.Colors.border, lineWidth: 1)
                        )
                }

                Spacer(minLength: 4)
            }
            .padding(.horizontal, spacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(centerBackground)

            // VERTICAL WALL
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(width: borders.container)

            // RIGHT: Upcoming Preview
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
                    Text("UPCOMING")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.7))
                }

                if let next = upcomingHolidays.first {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(next.holiday.isRedDay ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                            .frame(width: 6, height: 6)
                        Text(next.holiday.displayName)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text)
                            .lineLimit(1)
                    }
                    Text(daysUntilText(next.daysUntil))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
                } else {
                    Text("No upcoming")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.4))
                }
            }
            .padding(.horizontal, spacing.md)
            .frame(width: 150, alignment: .leading)
            .frame(maxHeight: .infinity)
            .background(JohoWidget.Colors.content)
        }
        .frame(height: 80)
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(spacing: 0) {
            // Month header
            HStack {
                Text(monthYear)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text)
                Spacer()
            }
            .padding(.horizontal, spacing.lg)
            .padding(.vertical, spacing.sm)

            // Divider
            Rectangle()
                .fill(JohoWidget.Colors.border.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, spacing.md)

            // Calendar grid
            VStack(spacing: spacing.xs) {
                // Weekday headers with W column
                HStack(spacing: 0) {
                    Text("W")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.4))
                        .frame(width: 36)

                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(weekdayColor(for: index))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, spacing.md)
                .padding(.top, spacing.xs)

                // Calendar rows
                ForEach(Array(weeksInMonth.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 0) {
                        // Week number column
                        Text("\(weekNumber(for: weekIndex))")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text.opacity(0.4))
                            .frame(width: 36)

                        ForEach(0..<7, id: \.self) { dayIndex in
                            if let day = week[dayIndex] {
                                dayCell(day: day, dayIndex: dayIndex)
                            } else {
                                Color.clear.frame(maxWidth: .infinity, minHeight: 36)
                            }
                        }
                    }
                }
                .padding(.horizontal, spacing.md)
                .padding(.bottom, spacing.xs)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(JohoWidget.Colors.content)
    }

    // MARK: - Upcoming Footer

    private var upcomingFooter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing.sm) {
                ForEach(Array(upcomingHolidays.prefix(6).enumerated()), id: \.offset) { _, item in
                    upcomingPill(item)
                }
            }
            .padding(.horizontal, spacing.md)
            .padding(.vertical, spacing.sm)
        }
        .frame(height: 44)
        .background(JohoWidget.Colors.content)
    }

    private func upcomingPill(_ item: (holiday: WidgetHoliday, daysUntil: Int)) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(item.holiday.isRedDay ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                .frame(width: 7, height: 7)
                .overlay(Circle().stroke(JohoWidget.Colors.border, lineWidth: 0.5))

            Text(item.holiday.displayName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .lineLimit(1)

            Text(shortDaysUntil(item.daysUntil))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(JohoWidget.Colors.content)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(day: Int, dayIndex: Int) -> some View {
        let isToday = self.isToday(day: day)
        let dayDate = dateFor(day: day)
        let holidays = dayDate.map { holidayEngine.getHolidays(for: $0) } ?? []
        let isRedDay = holidays.first?.isRedDay ?? false
        let isSunday = dayIndex == 6
        let hasEvent = !holidays.isEmpty

        VStack(spacing: 1) {
            Text("\(day)")
                .font(.system(size: 14, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(cellTextColor(isToday: isToday, isRedDay: isRedDay, isSunday: isSunday))

            if hasEvent {
                Circle()
                    .fill(isRedDay ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                    .frame(width: 5, height: 5)
                    .overlay(Circle().stroke(JohoWidget.Colors.border, lineWidth: 0.5))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36)
        .background(cellBackground(isToday: isToday, isRedDay: isRedDay, isSunday: isSunday))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: isToday ? borders.selected : borders.cell)
        )
    }

    // MARK: - Helper Functions

    private func weekdayColor(for index: Int) -> Color {
        index == 6 ? JohoWidget.Colors.alert : JohoWidget.Colors.text.opacity(0.6)
    }

    private func cellTextColor(isToday: Bool, isRedDay: Bool, isSunday: Bool) -> Color {
        if isToday { return JohoWidget.Colors.text }
        if isRedDay { return JohoWidget.Colors.alert }
        if isSunday { return JohoWidget.Colors.alert }
        return JohoWidget.Colors.text
    }

    private func cellBackground(isToday: Bool, isRedDay: Bool, isSunday: Bool) -> Color {
        if isToday { return JohoWidget.Colors.now }
        if isRedDay { return JohoWidget.Colors.holiday.opacity(0.15) }
        if isSunday { return JohoWidget.Colors.alert.opacity(0.08) }
        return JohoWidget.Colors.content
    }

    private func daysUntilText(_ days: Int) -> String {
        switch days {
        case 1: return "Tomorrow"
        default: return "in \(days) days"
        }
    }

    private func shortDaysUntil(_ days: Int) -> String {
        switch days {
        case 1: return "1d"
        default: return "\(days)d"
        }
    }

    private func isToday(day: Int) -> Bool {
        guard let dayDate = dateFor(day: day) else { return false }
        return calendar.isDate(dayDate, inSameDayAs: entry.date)
    }

    private func dateFor(day: Int) -> Date? {
        calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
    }

    private func weekNumber(for weekIndex: Int) -> Int {
        guard let firstDayOfWeek = weeksInMonth[weekIndex].compactMap({ $0 }).first,
              let date = dateFor(day: firstDayOfWeek) else {
            return entry.weekNumber
        }
        return calendar.component(.weekOfYear, from: date)
    }

    private var dayColor: Color {
        if isRedDay { return JohoWidget.Colors.alert }
        if isSunday { return JohoWidget.Colors.alert.opacity(0.9) }
        return JohoWidget.Colors.text
    }

    private var centerBackground: Color {
        if isRedDay { return JohoWidget.Colors.holiday.opacity(0.15) }
        if isSunday { return JohoWidget.Colors.sunday.opacity(0.08) }
        return JohoWidget.Colors.content
    }

    private var accessibilityLabel: String {
        var label = "\(monthYear) calendar, Week \(entry.weekNumber), Day \(dayOfMonth)"
        if let holiday = entry.todaysHolidays.first {
            label += ", \(holiday.displayName)"
        }
        return label
    }
}
