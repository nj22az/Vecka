//
//  LargeWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Large Widget
//  Japanese Minimalist: Clean month calendar
//  Breathing room, subtle colors, no heavy borders
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
        let month = entry.date.formatted(.dateTime.month(.wide).locale(.autoupdatingCurrent))
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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Header: Month/Year + Week badge
            HStack {
                Text(monthYear)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text)

                Spacer()

                // Week badge
                Text("W\(entry.weekNumber)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(JohoWidget.Colors.now)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)  // 情報デザイン: Max 8pt top padding

            // Calendar Grid
            VStack(spacing: 4) {
                // Weekday headers
                HStack(spacing: 0) {
                    Text("W")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.3))
                        .frame(width: 28)

                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(weekdayColor(for: index))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 12)

                // Calendar rows
                ForEach(Array(weeksInMonth.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 0) {
                        // Week number
                        Text("\(weekNumber(for: weekIndex))")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text.opacity(0.3))
                            .frame(width: 28)

                        ForEach(0..<7, id: \.self) { dayIndex in
                            if let day = week[dayIndex] {
                                dayCell(day: day, dayIndex: dayIndex)
                            } else {
                                Color.clear.frame(maxWidth: .infinity, minHeight: 36)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 12)
        }
        .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(JohoWidget.Colors.content)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(JohoWidget.Colors.border.opacity(0.2), lineWidth: 1)
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(day: Int, dayIndex: Int) -> some View {
        let isToday = self.isToday(day: day)
        let dayDate = dateFor(day: day)
        let holidays = dayDate.map { holidayEngine.getHolidays(for: $0) } ?? []
        let isBankHoliday = holidays.first?.isBankHoliday ?? false
        let isSunday = dayIndex == 6
        let hasEvent = !holidays.isEmpty

        VStack(spacing: 2) {
            Text("\(day)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular, design: .rounded))
                .foregroundStyle(cellTextColor(isToday: isToday, isBankHoliday: isBankHoliday, isSunday: isSunday))

            if hasEvent {
                Circle()
                    .fill(isBankHoliday ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36)
        .background(isToday ? JohoWidget.Colors.now.opacity(0.5) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Helper Functions

    private func weekdayColor(for index: Int) -> Color {
        index == 6 ? JohoWidget.Colors.alert.opacity(0.7) : JohoWidget.Colors.text.opacity(0.5)
    }

    private func cellTextColor(isToday: Bool, isBankHoliday: Bool, isSunday: Bool) -> Color {
        if isToday { return JohoWidget.Colors.text }
        if isBankHoliday { return JohoWidget.Colors.alert }
        if isSunday { return JohoWidget.Colors.alert }
        return JohoWidget.Colors.text
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
