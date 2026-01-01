//
//  ExtraLargeWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Extra Large Widget (iPad)
//  Two-column layout: Today info + Full month calendar
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

    private var monthYear: String {
        let month = entry.date.formatted(.dateTime.month(.wide).locale(.autoupdatingCurrent)).uppercased()
        let year = entry.date.formatted(.dateTime.year().locale(.autoupdatingCurrent))
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
            if holidays.count >= 5 { break }
        }
        return holidays
    }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingXL) {
            // LEFT COLUMN: Today Info
            VStack(alignment: .leading, spacing: JohoDimensions.spacingLG) {
                // Week Badge
                JohoWeekBadge(weekNumber: entry.weekNumber, size: .large)

                Spacer()

                // Big Day Number
                VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                    Text("\(dayOfMonth)")
                        .font(JohoWidgetFont.displayLarge)
                        .foregroundStyle(JohoWidgetColors.black)

                    Text(weekdayName)
                        .font(JohoWidgetFont.headerMedium)
                        .foregroundStyle(JohoWidgetColors.black.opacity(0.6))
                }

                // Today's Holidays
                if !entry.todaysHolidays.isEmpty {
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        ForEach(entry.todaysHolidays.prefix(2), id: \.id) { holiday in
                            JohoHolidayPill(name: holiday.displayName, isRedDay: holiday.isRedDay)
                        }
                    }
                }

                Spacer()

                // Upcoming Holidays
                if !upcomingHolidays.isEmpty {
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        Text("UPCOMING")
                            .font(JohoWidgetFont.labelBold)
                            .foregroundStyle(JohoWidgetColors.black.opacity(0.6))

                        ForEach(Array(upcomingHolidays.prefix(3).enumerated()), id: \.offset) { _, item in
                            HStack(spacing: JohoDimensions.spacingSM) {
                                Circle()
                                    .fill(item.holiday.isRedDay ? JohoWidgetColors.pink : JohoWidgetColors.cyan)
                                    .frame(width: 5, height: 5)

                                Text(item.holiday.displayName)
                                    .font(JohoWidgetFont.body)
                                    .foregroundStyle(JohoWidgetColors.black)
                                    .lineLimit(1)

                                Spacer()

                                Text(daysUntilText(item.daysUntil))
                                    .font(JohoWidgetFont.labelSmall)
                                    .foregroundStyle(JohoWidgetColors.black.opacity(0.6))
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // RIGHT COLUMN: Calendar Grid
            VStack(spacing: JohoDimensions.spacingSM) {
                // Month header
                Text(monthYear)
                    .font(JohoWidgetFont.headerMedium)
                    .foregroundStyle(JohoWidgetColors.black)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Weekday headers
                HStack(spacing: 0) {
                    Text("W")
                        .font(JohoWidgetFont.labelSmall)
                        .foregroundStyle(JohoWidgetColors.black.opacity(0.6))
                        .frame(width: 26)

                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol)
                            .font(JohoWidgetFont.labelBold)
                            .foregroundStyle(weekdayHeaderColor(for: index))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar rows
                ForEach(Array(weeksInMonth.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 0) {
                        Text("\(weekNumber(for: weekIndex))")
                            .font(JohoWidgetFont.weekNumber)
                            .foregroundStyle(JohoWidgetColors.black.opacity(0.6))
                            .frame(width: 26)

                        ForEach(0..<7, id: \.self) { dayIndex in
                            if let day = week[dayIndex] {
                                dayCell(day: day, dayIndex: dayIndex)
                            } else {
                                Color.clear.frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(height: 34)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(JohoDimensions.spacingXL)
        .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            // 情報デザイン: WHITE background with BLACK border
            ZStack {
                RoundedRectangle(cornerRadius: JohoDimensions.radiusLarge, style: .continuous)
                    .fill(JohoWidgetColors.white)
                RoundedRectangle(cornerRadius: JohoDimensions.radiusLarge, style: .continuous)
                    .stroke(JohoWidgetColors.black, lineWidth: JohoDimensions.borderBold)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var label = "\(monthYear) calendar, Week \(entry.weekNumber). Today: \(weekdayName) \(dayOfMonth)"
        if let holiday = entry.todaysHolidays.first {
            label += ", \(holiday.displayName)"
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
        index == 6 ? JohoWidgetColors.sundayBlue : JohoWidgetColors.black.opacity(0.7)
    }

    @ViewBuilder
    private func dayCell(day: Int, dayIndex: Int) -> some View {
        let isToday = self.isToday(day: day)
        let dayDate = dateFor(day: day)
        let holidays = dayDate.map { holidayEngine.getHolidays(for: $0) } ?? []
        let isRedDay = holidays.first?.isRedDay ?? false
        let isSunday = dayIndex == 6

        JohoDayCell(
            day: day,
            isToday: isToday,
            isRedDay: isRedDay,
            isSunday: isSunday,
            cellSize: 28
        )
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
