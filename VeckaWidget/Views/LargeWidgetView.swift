//
//  LargeWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Large Widget
//  Three-zone bento: Header | Calendar Grid | Footer
//  Philosophy: Full month at a glance with clear compartmentalization
//

import SwiftUI
import WidgetKit
import EventKit

struct VeckaLargeWidgetView: View {
    let entry: VeckaWidgetEntry
    private let family: WidgetFamily = .systemLarge

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
            // HEADER COMPARTMENT: Month + Week Badge
            // ═══════════════════════════════════════════════
            headerCompartment

            // HORIZONTAL WALL
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(height: borders.container)

            // ═══════════════════════════════════════════════
            // CALENDAR COMPARTMENT: Full Month Grid
            // ═══════════════════════════════════════════════
            calendarCompartment

            // HORIZONTAL WALL
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(height: borders.row)

            // ═══════════════════════════════════════════════
            // FOOTER COMPARTMENT: Upcoming Holiday
            // ═══════════════════════════════════════════════
            footerCompartment
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

    // MARK: - Header Compartment

    private var headerCompartment: some View {
        HStack(alignment: .center) {
            // Month Year (hero text)
            Text(monthYear)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)

            Spacer()

            // Week badge (黒に白 - white on black)
            Text("W\(entry.weekNumber)")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.textInverted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(JohoWidget.Colors.border)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, spacing.lg)
        .padding(.vertical, spacing.md)
        .background(JohoWidget.Colors.content)
    }

    // MARK: - Calendar Compartment

    private var calendarCompartment: some View {
        VStack(spacing: spacing.xs) {
            // Weekday headers with W column
            HStack(spacing: 0) {
                Text("W")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.4))
                    .frame(width: 26)

                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(weekdayColor(for: index))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, spacing.md)
            .padding(.top, spacing.sm)

            // Divider under headers
            Rectangle()
                .fill(JohoWidget.Colors.border.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, spacing.md)

            // Calendar rows
            ForEach(Array(weeksInMonth.enumerated()), id: \.offset) { weekIndex, week in
                HStack(spacing: 0) {
                    // Week number column
                    Text("\(weekNumber(for: weekIndex))")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.4))
                        .frame(width: 26)

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
            .padding(.bottom, spacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoWidget.Colors.content)
    }

    // MARK: - Footer Compartment

    private var footerCompartment: some View {
        Group {
            if let upcoming = findUpcomingHoliday() {
                HStack(spacing: spacing.sm) {
                    // Type indicator
                    Circle()
                        .fill(upcoming.holiday.isRedDay ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(JohoWidget.Colors.border, lineWidth: 1))

                    Text(upcoming.holiday.displayName)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)
                        .lineLimit(1)

                    Spacer()

                    // Days until badge
                    Text(daysUntilText(upcoming.daysUntil))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(JohoWidget.Colors.now)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(JohoWidget.Colors.border, lineWidth: 1)
                        )
                }
            } else {
                HStack {
                    Text("No upcoming holidays")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.4))
                    Spacer()
                }
            }
        }
        .padding(.horizontal, spacing.lg)
        .padding(.vertical, spacing.md)
        .frame(maxWidth: .infinity)
        .background(JohoWidget.Colors.content)
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
                .font(.system(size: 13, weight: isToday ? .bold : .medium, design: .rounded))
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

    private func findUpcomingHoliday() -> (holiday: WidgetHoliday, daysUntil: Int)? {
        for daysAhead in 1...14 {
            if let futureDate = calendar.date(byAdding: .day, value: daysAhead, to: entry.date) {
                let holidays = holidayEngine.getHolidays(for: futureDate)
                if let holiday = holidays.first {
                    return (holiday, daysAhead)
                }
            }
        }
        return nil
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

    private var accessibilityLabel: String {
        var label = "\(monthYear) calendar, Week \(entry.weekNumber)"
        if let holiday = entry.todaysHolidays.first {
            label += ", \(holiday.displayName)"
        }
        return label
    }
}
