//
//  ExtraLargeWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Extra Large Widget (iPad)
//  Three-column bento: Today info | Calendar | Upcoming
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

    private var weekdayName: String {
        entry.date.formatted(.dateTime.weekday(.wide).locale(.autoupdatingCurrent)).uppercased()
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
        let symbols = calendar.shortWeekdaySymbols
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
        HStack(spacing: 0) {
            // LEFT COMPARTMENT: Today Info (narrower, cleaner)
            leftCompartment
                .frame(width: 140)

            // VERTICAL WALL
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(width: borders.container)

            // CENTER COMPARTMENT: Calendar Grid (more space)
            centerCompartment

            // VERTICAL WALL
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(width: borders.container)

            // RIGHT COMPARTMENT: Upcoming Holidays
            rightCompartment
                .frame(width: 180)
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

    // MARK: - Left Compartment (Today)

    private var leftCompartment: some View {
        VStack(alignment: .center, spacing: spacing.md) {
            // Week Badge (compact)
            Text("W\(entry.weekNumber)")
                .font(JohoWidget.Typography.font(typo.label, weight: .black))
                .foregroundStyle(JohoWidget.Colors.textInverted)
                .padding(.horizontal, spacing.md)
                .padding(.vertical, spacing.sm)
                .background(JohoWidget.Colors.border)
                .clipShape(RoundedRectangle(cornerRadius: corners.pill, style: .continuous))

            Spacer()

            // Big Day Number (hero)
            VStack(spacing: 2) {
                Text("\(dayOfMonth)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(dayColor)

                Text(weekdayName)
                    .font(JohoWidget.Typography.font(typo.micro, weight: .bold))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
            }

            Spacer()

            // Today's Holidays (only if present)
            if let holiday = entry.todaysHolidays.first {
                HStack(spacing: 4) {
                    Circle()
                        .fill(holiday.isRedDay ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                        .frame(width: 6, height: 6)
                    Text(holiday.displayName)
                        .font(JohoWidget.Typography.font(typo.micro, weight: .semibold))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.7))
                        .lineLimit(1)
                }
            }
        }
        .padding(spacing.md)
        .frame(maxHeight: .infinity)
        .background(JohoWidget.Colors.content)  // Clean white - no cream tint
    }

    // MARK: - Center Compartment (Calendar)

    private var centerCompartment: some View {
        VStack(spacing: spacing.md) {
            // Month header
            Text(monthYear)
                .font(JohoWidget.Typography.font(typo.headline, weight: .heavy))
                .foregroundStyle(JohoWidget.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Weekday headers
            HStack(spacing: 0) {
                Text("W")
                    .font(JohoWidget.Typography.font(typo.micro, weight: .bold))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
                    .frame(width: 30)

                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(JohoWidget.Typography.font(typo.micro, weight: .bold))
                        .foregroundStyle(weekdayHeaderColor(for: index))
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar rows
            ForEach(Array(weeksInMonth.enumerated()), id: \.offset) { weekIndex, week in
                HStack(spacing: 0) {
                    Text("\(weekNumber(for: weekIndex))")
                        .font(JohoWidget.Typography.font(typo.micro, weight: .bold))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
                        .frame(width: 30)

                    ForEach(0..<7, id: \.self) { dayIndex in
                        if let day = week[dayIndex] {
                            dayCell(day: day, dayIndex: dayIndex)
                        } else {
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(height: 38)
            }

            Spacer(minLength: 0)
        }
        .padding(spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoWidget.Colors.content)
    }

    // MARK: - Right Compartment (Upcoming)

    private var rightCompartment: some View {
        VStack(alignment: .leading, spacing: spacing.sm) {
            // Section header (compact)
            HStack(spacing: 4) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
                Text("UPCOMING")
                    .font(JohoWidget.Typography.font(typo.micro, weight: .bold))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
            }

            if upcomingHolidays.isEmpty {
                Spacer()
                Text("No upcoming\nholidays")
                    .font(JohoWidget.Typography.font(typo.caption, weight: .medium))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                // Show more items with tighter spacing
                ForEach(Array(upcomingHolidays.prefix(6).enumerated()), id: \.offset) { _, item in
                    upcomingRow(item)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(spacing.md)
        .frame(maxHeight: .infinity)
        .background(JohoWidget.Colors.content)
    }

    // MARK: - Subviews

    private func upcomingRow(_ item: (holiday: WidgetHoliday, daysUntil: Int)) -> some View {
        HStack(spacing: 6) {
            // Type indicator
            Circle()
                .fill(item.holiday.isRedDay ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                .frame(width: 6, height: 6)

            // Holiday name
            Text(item.holiday.displayName)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .lineLimit(1)

            Spacer(minLength: 2)

            // Days until (compact pill)
            Text(daysUntilText(item.daysUntil))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
        }
        .padding(.horizontal, 8)
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

        VStack(spacing: 2) {
            Text("\(day)")
                .font(JohoWidget.Typography.font(typo.body, weight: isToday ? .bold : .medium))
                .foregroundStyle(cellTextColor(isToday: isToday, isRedDay: isRedDay, isSunday: isSunday))

            if hasEvent {
                Circle()
                    .fill(isRedDay ? JohoWidget.Colors.holiday : JohoWidget.Colors.event)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38)
        .background(cellBackground(isToday: isToday, isRedDay: isRedDay, isSunday: isSunday))
        .clipShape(RoundedRectangle(cornerRadius: corners.cell, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corners.cell, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: isToday ? borders.selected : borders.cell)
        )
    }

    // MARK: - Helper Functions

    private var accessibilityLabel: String {
        var label = "\(monthYear) calendar, Week \(entry.weekNumber). Today: \(weekdayName) \(dayOfMonth)"
        if let holiday = entry.todaysHolidays.first {
            label += ", \(holiday.displayName)"
        }
        return label
    }

    private var dayColor: Color {
        let isRedDay = entry.todaysHolidays.first?.isRedDay ?? false
        let isSunday = calendar.component(.weekday, from: entry.date) == 1
        if isRedDay { return JohoWidget.Colors.alert }
        if isSunday { return JohoWidget.Colors.sunday }
        return JohoWidget.Colors.text
    }

    private func daysUntilText(_ days: Int) -> String {
        switch days {
        case 1: return "Tomorrow"
        default: return "in \(days)d"
        }
    }

    private func weekdayHeaderColor(for index: Int) -> Color {
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
}
