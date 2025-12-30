//
//  LargeWidgetView.swift
//  VeckaWidget
//
//  Large widget: Clean design with Liquid Glass on navigation only
//  Glass = week badge only. Calendar grid = clean and readable.
//

import SwiftUI
import WidgetKit
import EventKit

struct VeckaLargeWidgetView: View {
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

    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            HStack(alignment: .center) {
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(monthName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(WidgetColors.accent)

                    Text(yearString)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Week Badge - GLASS (navigation element)
                Text("\(entry.weekNumber)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // CALENDAR GRID - NO GLASS (content)
            VStack(spacing: 4) {
                // Weekday Headers
                HStack(spacing: 0) {
                    Text("W")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 26)

                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(weekdayHeaderColor(for: index))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 14)

                // Calendar Rows
                ForEach(Array(weeksInMonth.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 0) {
                        Text("\(weekNumber(for: weekIndex))")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(.secondary.opacity(0.6))
                            .frame(width: 26)

                        ForEach(0..<7, id: \.self) { dayIndex in
                            if let day = week[dayIndex] {
                                dayCellView(day: day, dayIndex: dayIndex)
                            } else {
                                Color.clear.frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 30)
                }
            }

            Spacer()

            // UPCOMING - NO GLASS (content)
            if let upcoming = findUpcomingHoliday() {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(upcomingText(for: upcoming))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            } else {
                Spacer().frame(height: 14)
            }
        }
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
        if let upcoming = findUpcomingHoliday() {
            label += ". Upcoming: \(upcoming.holiday.displayName) in \(upcoming.daysUntil) days"
        }
        return label
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
                    .frame(width: 26, height: 26)
            }

            Text("\(day)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity)
    }

    private func upcomingText(for upcoming: (holiday: WidgetHoliday, daysUntil: Int)) -> String {
        let daysText = upcoming.daysUntil == 1 ? "tomorrow" : "in \(upcoming.daysUntil)d"
        return "\(upcoming.holiday.displayName) (\(daysText))"
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
}
