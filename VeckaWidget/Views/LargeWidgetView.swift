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

    // 情報デザイン: Use shared calendar for memory efficiency
    private var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        cal.locale = .autoupdatingCurrent
        return cal
    }

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

    // 情報デザイン: Theme constants for consistency
    private var typo: JohoWidget.Typography.Scale { JohoWidget.Typography.large }
    private var borders: JohoWidget.Borders.Weights { JohoWidget.Borders.large }
    private var corners: JohoWidget.Corners.Radii { JohoWidget.Corners.large }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let metrics = LargeWidgetMetrics(size: geo.size)

            VStack(spacing: metrics.verticalSpacing) {
                // Header: Month/Year + Week badge
                HStack {
                    Text(monthYear)
                        .font(.system(size: metrics.titleSize, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)

                    Spacer()

                    // Week badge (情報デザイン: with border)
                    Text("W\(entry.weekNumber)")
                        .font(.system(size: metrics.labelSize, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)
                        .padding(.horizontal, 10 * metrics.scale)
                        .padding(.vertical, 4 * metrics.scale)
                        .background(JohoWidget.Colors.now)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(JohoWidget.Colors.border, lineWidth: metrics.borderButton)
                        )
                }
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.top, 8 * metrics.scale)

                // Calendar Grid
                VStack(spacing: 4 * metrics.scale) {
                    // Weekday headers (情報デザイン: functional labels, minimum readable size)
                    HStack(spacing: 0) {
                        Text("W")
                            .font(.system(size: metrics.microSize, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.textSecondary)
                            .frame(width: metrics.weekColumnWidth)

                        ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                            Text(symbol)
                                .font(.system(size: metrics.microSize, weight: .medium, design: .rounded))
                                .foregroundStyle(weekdayColor(for: index))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, metrics.rowPadding)

                    // Calendar rows
                    ForEach(Array(weeksInMonth.enumerated()), id: \.offset) { weekIndex, week in
                        HStack(spacing: 0) {
                            // Week number (情報デザイン: functional, visible)
                            Text("\(weekNumber(for: weekIndex))")
                                .font(.system(size: metrics.labelSize, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoWidget.Colors.textSecondary)
                                .frame(width: metrics.weekColumnWidth)

                            ForEach(0..<7, id: \.self) { dayIndex in
                                if let day = week[dayIndex] {
                                    dayCell(day: day, dayIndex: dayIndex, metrics: metrics)
                                } else {
                                    Color.clear.frame(maxWidth: .infinity, minHeight: metrics.cellHeight)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, metrics.rowPadding)
                }
                .padding(.bottom, metrics.rowPadding)
            }
        }
        .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            JohoWidget.Colors.content
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(day: Int, dayIndex: Int, metrics: LargeWidgetMetrics) -> some View {
        let isToday = self.isToday(day: day)
        let dayDate = dateFor(day: day)
        let dayStart = dayDate.map { calendar.startOfDay(for: $0) }
        let holidays = dayDate.map { entry.holidays(for: $0) } ?? []
        let birthdays = dayStart.flatMap { entry.weekBirthdays[$0] } ?? []
        let isBankHoliday = holidays.first?.isBankHoliday ?? false
        let isSunday = dayIndex == 6
        let hasHoliday = !holidays.isEmpty
        let hasBirthday = !birthdays.isEmpty

        ZStack {
            // Today indicator
            if isToday {
                Circle()
                    .fill(JohoWidget.Colors.now)
                    .frame(width: metrics.todayCircleSize, height: metrics.todayCircleSize)
                    .overlay(
                        Circle()
                            .stroke(JohoWidget.Colors.border, lineWidth: metrics.borderSelected)
                    )
            }

            // Day number
            Text("\(day)")
                .font(.system(size: metrics.bodySize, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(cellTextColor(isToday: isToday, isBankHoliday: isBankHoliday, isSunday: isSunday))

            // Event dots overlay
            if hasHoliday || hasBirthday {
                VStack {
                    Spacer()
                    HStack(spacing: 2 * metrics.scale) {
                        if hasHoliday {
                            Circle()
                                .fill(isBankHoliday ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                                .frame(width: metrics.eventDotSize, height: metrics.eventDotSize)
                        }
                        if hasBirthday {
                            Circle()
                                .fill(JohoWidget.Colors.holiday)
                                .frame(width: metrics.eventDotSize, height: metrics.eventDotSize)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 2 * metrics.scale)
            }
        }
        .frame(maxWidth: .infinity, minHeight: metrics.cellHeight)
    }

    // MARK: - Helper Functions

    private func weekdayColor(for index: Int) -> Color {
        // 情報デザイン: Sunday in red, weekdays in secondary text color
        index == 6 ? JohoWidget.Colors.alert : JohoWidget.Colors.textSecondary
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
        guard weekIndex < weeksInMonth.count,
              let firstDayOfWeek = weeksInMonth[weekIndex].compactMap({ $0 }).first,
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

// MARK: - Adaptive Metrics

/// Calculates adaptive sizes based on widget dimensions
/// iPhone large widget: ~338 x 354 pt
/// iPad large widget: ~364 x 382 pt to ~432 x 454 pt
private struct LargeWidgetMetrics {
    let size: CGSize

    /// Scale factor based on widget height (baseline: 354pt for iPhone)
    var scale: CGFloat {
        let baseline: CGFloat = 354
        return max(1.0, size.height / baseline)
    }

    // Typography (scaled)
    var titleSize: CGFloat { 18 * scale }
    var labelSize: CGFloat { 11 * scale }
    var bodySize: CGFloat { 14 * scale }
    var microSize: CGFloat { 10 * scale }

    // Layout (scaled)
    var cellHeight: CGFloat { 36 * scale }
    var todayCircleSize: CGFloat { 32 * scale }
    var eventDotSize: CGFloat { 6 * scale }
    var weekColumnWidth: CGFloat { 28 * scale }
    var horizontalPadding: CGFloat { 16 * scale }
    var rowPadding: CGFloat { 12 * scale }
    var verticalSpacing: CGFloat { 12 * scale }

    // Borders (slightly thicker on iPad)
    var borderButton: CGFloat { scale > 1.05 ? 2.5 : 2 }
    var borderSelected: CGFloat { scale > 1.05 ? 3 : 2.5 }
}
