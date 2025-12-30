//
//  ExtraLargeWidgetView.swift
//  VeckaWidget
//
//  Extra Large widget (iPad): Clean design with Liquid Glass on navigation only
//  Glass = week badge only. All content = clean and readable.
//

import SwiftUI
import WidgetKit
import EventKit

struct VeckaExtraLargeWidgetView: View {
    let entry: VeckaWidgetEntry

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        cal.locale = .autoupdatingCurrent
        return cal
    }()

    private let holidayEngine = WidgetHolidayEngine()

    private var monthName: String {
        entry.date.formatted(.dateTime.month(.wide).locale(.autoupdatingCurrent)).capitalized
    }

    private var yearString: String {
        entry.date.formatted(.dateTime.year().locale(.autoupdatingCurrent))
    }

    private var dayOfMonth: Int {
        calendar.component(.day, from: entry.date)
    }

    private var weekdayName: String {
        entry.date.formatted(.dateTime.weekday(.wide).locale(.autoupdatingCurrent)).capitalized
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
            if holidays.count >= 5 { break }
        }
        return holidays
    }

    var body: some View {
        HStack(spacing: 24) {
            // LEFT: Today Info
            VStack(alignment: .leading, spacing: 16) {
                // Week Badge - GLASS (navigation element)
                HStack {
                    Text("Week \(entry.weekNumber)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .glassEffect(.regular, in: .capsule)

                    Spacer()
                }

                // Today - NO GLASS (content)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(dayOfMonth)")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.primary)

                    Text(weekdayName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)

                    Text("\(monthName) \(yearString)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                // Today's Holidays - NO GLASS (content)
                if !entry.todaysHolidays.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(entry.todaysHolidays.prefix(2), id: \.id) { holiday in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(holiday.isRedDay ? WidgetColors.holiday : WidgetColors.observance)
                                    .frame(width: 8, height: 8)

                                Text(holiday.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(holiday.isRedDay ? WidgetColors.holiday : WidgetColors.observance)
                            }
                        }
                    }
                }

                Spacer()

                // Upcoming - NO GLASS (content)
                if !upcomingHolidays.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upcoming")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)

                        ForEach(Array(upcomingHolidays.prefix(3).enumerated()), id: \.offset) { _, item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.holiday.isRedDay ? WidgetColors.holiday : WidgetColors.observance)
                                    .frame(width: 5, height: 5)

                                Text(item.holiday.displayName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Spacer()

                                Text(daysUntilText(item.daysUntil))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // RIGHT: Calendar Grid (clean, no redundant header)
            VStack(spacing: 8) {
                // Weekday Headers only
                HStack(spacing: 0) {
                    Text("W")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(weekdayHeaderColor(for: index))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar Rows
                ForEach(Array(weeksInMonth.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 0) {
                        Text("\(weekNumber(for: weekIndex))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary.opacity(0.6))
                            .frame(width: 24)

                        ForEach(0..<7, id: \.self) { dayIndex in
                            if let day = week[dayIndex] {
                                dayCellView(day: day, dayIndex: dayIndex)
                            } else {
                                Color.clear.frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(height: 36)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        .containerBackground(.fill.tertiary, for: .widget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(widgetAccessibilityLabel)
    }

    private var widgetAccessibilityLabel: String {
        let todayFormatted = entry.date.formatted(date: .complete, time: .omitted)
        var label = "\(monthName) \(yearString) calendar, Week \(entry.weekNumber). Today: \(todayFormatted)"
        if let holiday = entry.todaysHolidays.first {
            label += ", \(holiday.displayName)"
        }
        if !upcomingHolidays.isEmpty {
            let upcoming = upcomingHolidays.prefix(2).map { "\($0.holiday.displayName) in \($0.daysUntil) days" }.joined(separator: ", ")
            label += ". Upcoming: \(upcoming)"
        }
        return label
    }

    private func daysUntilText(_ days: Int) -> String {
        switch days {
        case 1: return "Tomorrow"
        default: return "in \(days)d"
        }
    }

    private func weekdayHeaderColor(for index: Int) -> Color {
        switch index {
        case 6: return WidgetColors.sundayBlue  // Sunday = Blue
        default: return .secondary               // Saturday and weekdays = normal
        }
    }

    @ViewBuilder
    private func dayCellView(day: Int, dayIndex: Int) -> some View {
        let isToday = self.isToday(day: day)
        let dayDate = dateFor(day: day)
        let holidays = dayDate.map { holidayEngine.getHolidays(for: $0) } ?? []
        let isRedDay = holidays.first?.isRedDay ?? false

        let textColor: Color = {
            if isToday { return .white }
            if isRedDay { return WidgetColors.holiday }
            if dayIndex == 6 { return WidgetColors.sundayBlue }  // Sunday = Blue
            return .primary
        }()

        ZStack {
            if isToday {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(WidgetColors.accent)
                    .frame(width: 30, height: 30)
            }

            Text("\(day)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity)
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
