//
//  LargeWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Large Widget
//  Full month calendar with header and upcoming holidays
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

    private var typo: JohoWidget.Typography.Scale {
        JohoWidget.Typography.scale(for: family)
    }

    private var spacing: JohoWidget.Spacing.Grid {
        JohoWidget.Spacing.grid(for: family)
    }

    private var corners: JohoWidget.Corners.Radii {
        JohoWidget.Corners.radii(for: family)
    }

    private var borders: JohoWidget.Borders.Weights {
        JohoWidget.Borders.weights(for: family)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // HEADER COMPARTMENT
            headerCompartment

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(height: borders.container)

            // CALENDAR COMPARTMENT
            calendarCompartment

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(height: borders.row)

            // FOOTER COMPARTMENT (Upcoming)
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

    // MARK: - Header

    private var headerCompartment: some View {
        HStack(alignment: .center) {
            // Month Year
            Text(monthYear)
                .font(JohoWidget.Typography.font(typo.headline, weight: .heavy))
                .foregroundStyle(JohoWidget.Colors.text)

            Spacer()

            // Week badge
            Text("W\(entry.weekNumber)")
                .font(JohoWidget.Typography.font(typo.label, weight: .black))
                .foregroundStyle(JohoWidget.Colors.textInverted)
                .padding(.horizontal, spacing.lg)
                .padding(.vertical, spacing.sm)
                .background(JohoWidget.Colors.border)
                .clipShape(RoundedRectangle(cornerRadius: corners.card, style: .continuous))
        }
        .padding(.horizontal, spacing.xl)
        .padding(.vertical, spacing.md)
        .background(JohoWidget.Colors.content)
    }

    // MARK: - Calendar Grid

    private var calendarCompartment: some View {
        VStack(spacing: spacing.sm) {
            // Weekday headers with W column
            HStack(spacing: 0) {
                Text("W")
                    .font(JohoWidget.Typography.font(typo.micro, weight: .bold))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
                    .frame(width: 28)

                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(JohoWidget.Typography.font(typo.micro, weight: .bold))
                        .foregroundStyle(weekdayColor(for: index))
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar rows
            ForEach(Array(weeksInMonth.enumerated()), id: \.offset) { weekIndex, week in
                HStack(spacing: 0) {
                    // Week number
                    Text("\(weekNumber(for: weekIndex))")
                        .font(JohoWidget.Typography.font(typo.micro, weight: .bold))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
                        .frame(width: 28)

                    ForEach(0..<7, id: \.self) { dayIndex in
                        if let day = week[dayIndex] {
                            dayCell(day: day, dayIndex: dayIndex)
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 32)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, spacing.lg)
        .padding(.vertical, spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoWidget.Colors.content)
    }

    // MARK: - Footer

    private var footerCompartment: some View {
        Group {
            if let upcoming = findUpcomingHoliday() {
                HStack(spacing: spacing.sm) {
                    // Type indicator
                    Circle()
                        .fill(upcoming.holiday.isRedDay ? JohoWidget.Colors.holiday : JohoWidget.Colors.event)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(JohoWidget.Colors.border, lineWidth: 0.5)
                        )

                    Text(upcoming.holiday.displayName)
                        .font(JohoWidget.Typography.font(typo.caption, weight: .semibold))
                        .foregroundStyle(JohoWidget.Colors.text)
                        .lineLimit(1)

                    Spacer()

                    // Days until badge
                    Text(daysUntilText(upcoming.daysUntil))
                        .font(JohoWidget.Typography.font(typo.micro, weight: .bold))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
                        .padding(.horizontal, spacing.md)
                        .padding(.vertical, spacing.xs)
                        .background(JohoWidget.Colors.now.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: corners.pill, style: .continuous))
                }
                .padding(.horizontal, spacing.xl)
                .padding(.vertical, spacing.md)
            } else {
                HStack {
                    Text("No upcoming holidays")
                        .font(JohoWidget.Typography.font(typo.caption, weight: .medium))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
                }
                .padding(.horizontal, spacing.xl)
                .padding(.vertical, spacing.md)
            }
        }
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
                .font(JohoWidget.Typography.font(typo.caption, weight: isToday ? .bold : .medium))
                .foregroundStyle(cellTextColor(isToday: isToday, isRedDay: isRedDay, isSunday: isSunday))

            if hasEvent {
                Circle()
                    .fill(isRedDay ? JohoWidget.Colors.holiday : JohoWidget.Colors.event)
                    .frame(width: 5, height: 5)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 32)
        .background(cellBackground(isToday: isToday, isRedDay: isRedDay, isSunday: isSunday))
        .clipShape(RoundedRectangle(cornerRadius: corners.cell, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corners.cell, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: isToday ? borders.selected : borders.cell)
        )
    }

    // MARK: - Helper Functions

    private func weekdayColor(for index: Int) -> Color {
        index == 6 ? JohoWidget.Colors.sunday : JohoWidget.Colors.text.opacity(0.7)
    }

    private func cellTextColor(isToday: Bool, isRedDay: Bool, isSunday: Bool) -> Color {
        if isToday { return JohoWidget.Colors.text }
        if isRedDay { return JohoWidget.Colors.alert }
        if isSunday { return JohoWidget.Colors.sunday }
        return JohoWidget.Colors.text
    }

    private func cellBackground(isToday: Bool, isRedDay: Bool, isSunday: Bool) -> Color {
        if isToday { return JohoWidget.Colors.now }
        if isRedDay { return JohoWidget.Colors.holiday.opacity(0.15) }
        if isSunday { return JohoWidget.Colors.sunday.opacity(0.08) }
        return JohoWidget.Colors.content
    }

    private func daysUntilText(_ days: Int) -> String {
        switch days {
        case 1: return "Tomorrow"
        default: return "in \(days)d"
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
