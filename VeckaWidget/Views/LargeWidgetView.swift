//
//  LargeWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Large Widget
//  Full month calendar - clean, bold, high-contrast
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

    private var monthYear: String {
        let month = entry.date.formatted(.dateTime.month(.wide).locale(.autoupdatingCurrent)).uppercased()
        let year = entry.date.formatted(.dateTime.year().locale(.autoupdatingCurrent))
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

    var body: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            // HEADER
            HStack(alignment: .center) {
                Text(monthYear)
                    .font(JohoWidgetFont.headerLarge)
                    .foregroundStyle(JohoWidgetColors.black)

                Spacer()

                JohoWeekBadge(weekNumber: entry.weekNumber, size: .large)
            }
            .padding(.horizontal, JohoDimensions.spacingXL)
            .padding(.top, JohoDimensions.spacingLG)

            // CALENDAR GRID
            VStack(spacing: JohoDimensions.spacingXS) {
                // Weekday headers with W column
                HStack(spacing: 0) {
                    Text("W")
                        .font(JohoWidgetFont.labelSmall)
                        .foregroundStyle(JohoWidgetColors.black.opacity(0.6))
                        .frame(width: 24)

                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol)
                            .font(JohoWidgetFont.labelBold)
                            .foregroundStyle(weekdayColor(for: index))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar rows
                ForEach(Array(weeksInMonth.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 0) {
                        // Week number
                        Text("\(weekNumber(for: weekIndex))")
                            .font(JohoWidgetFont.weekNumber)
                            .foregroundStyle(JohoWidgetColors.black.opacity(0.6))
                            .frame(width: 24)

                        ForEach(0..<7, id: \.self) { dayIndex in
                            if let day = week[dayIndex] {
                                dayCell(day: day, dayIndex: dayIndex)
                            } else {
                                Color.clear.frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(height: 28)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)

            Spacer()

            // UPCOMING holiday (if any)
            if let upcoming = findUpcomingHoliday() {
                HStack(spacing: JohoDimensions.spacingSM) {
                    JohoHolidayPill(name: upcomingText(for: upcoming), isRedDay: upcoming.holiday.isRedDay)
                    Spacer()
                }
                .padding(.horizontal, JohoDimensions.spacingXL)
                .padding(.bottom, JohoDimensions.spacingLG)
            } else {
                Spacer().frame(height: JohoDimensions.spacingLG)
            }
        }
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

    private func weekdayColor(for index: Int) -> Color {
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
            cellSize: 24
        )
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

    private var accessibilityLabel: String {
        var label = "\(monthYear) calendar, Week \(entry.weekNumber)"
        if let holiday = entry.todaysHolidays.first {
            label += ", \(holiday.displayName)"
        }
        return label
    }
}
