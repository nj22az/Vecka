//
//  MediumWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Medium Widget
//  Clean two-column bento: Week/Today | Calendar Strip
//  Philosophy: Essential info with visual clarity
//

import SwiftUI
import WidgetKit

struct VeckaMediumWidgetView: View {
    let entry: VeckaWidgetEntry
    private let family: WidgetFamily = .systemMedium

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        cal.locale = .autoupdatingCurrent
        return cal
    }()

    private let holidayEngine = WidgetHolidayEngine()

    // MARK: - Computed Properties

    private var weekInterval: DateInterval? {
        calendar.dateInterval(of: .weekOfYear, for: entry.date)
    }

    private var weekDays: [Date] {
        guard let interval = weekInterval else { return [] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: interval.start)
        }
    }

    private var monthYear: String {
        let month = entry.date.formatted(.dateTime.month(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
        let year = String(calendar.component(.year, from: entry.date))
        return "\(month) \(year)"
    }

    private var dayOfMonth: Int {
        calendar.component(.day, from: entry.date)
    }

    private var weekdayShort: String {
        entry.date.formatted(.dateTime.weekday(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        return Array(symbols[1...]) + [symbols[0]]  // Monday first
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
        HStack(spacing: 0) {
            // ═══════════════════════════════════════════════
            // LEFT: Week + Today Hero
            // ═══════════════════════════════════════════════
            leftCompartment
                .frame(width: 100)

            // VERTICAL WALL
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(width: borders.container)

            // ═══════════════════════════════════════════════
            // RIGHT: Calendar Strip
            // ═══════════════════════════════════════════════
            rightCompartment
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
        .accessibilityLabel("Week \(entry.weekNumber), \(monthYear)")
    }

    // MARK: - Left Compartment (Week + Today)

    private var leftCompartment: some View {
        VStack(spacing: 0) {
            // Week badge (hero - 黒に白)
            VStack(spacing: 2) {
                Text("\(entry.weekNumber)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.textInverted)
                Text("WEEK")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.textInverted.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, spacing.md)
            .background(JohoWidget.Colors.border)

            // Thin divider
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(height: 1)

            // Today info (day + weekday)
            VStack(spacing: 2) {
                Text("\(dayOfMonth)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(dayColor)

                Text(weekdayShort)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(centerBackground)

            // Holiday/Month footer
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(height: 1)

            Group {
                if let holiday = entry.todaysHolidays.first {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(holiday.isRedDay ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().stroke(JohoWidget.Colors.border, lineWidth: 0.5))

                        Text(holiday.displayName)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text)
                            .lineLimit(1)
                    }
                } else {
                    Text(monthYear)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .padding(.horizontal, spacing.sm)
        }
        .background(JohoWidget.Colors.content)
    }

    // MARK: - Right Compartment (Calendar Strip)

    private var rightCompartment: some View {
        VStack(spacing: 0) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(weekdayColor(for: index))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, spacing.sm)
            .padding(.top, spacing.sm)
            .padding(.bottom, spacing.xs)

            // Thin divider
            Rectangle()
                .fill(JohoWidget.Colors.border.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, spacing.sm)

            // Day cells
            HStack(spacing: 4) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, date in
                    dayCell(date: date, dayIndex: index)
                }
            }
            .padding(.horizontal, spacing.sm)
            .padding(.vertical, spacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoWidget.Colors.content)
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(date: Date, dayIndex: Int) -> some View {
        let isToday = calendar.isDate(date, inSameDayAs: entry.date)
        let dayNumber = calendar.component(.day, from: date)
        let holidays = holidayEngine.getHolidays(for: date)
        let isRedDay = holidays.first?.isRedDay ?? false
        let isSunday = dayIndex == 6
        let hasEvent = !holidays.isEmpty

        VStack(spacing: 3) {
            Text("\(dayNumber)")
                .font(.system(size: 16, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(cellTextColor(isToday: isToday, isRedDay: isRedDay, isSunday: isSunday))

            // Event indicator
            if hasEvent {
                Circle()
                    .fill(isRedDay ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                    .frame(width: 5, height: 5)
                    .overlay(Circle().stroke(JohoWidget.Colors.border, lineWidth: 0.5))
            } else {
                Spacer().frame(height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(cellBackground(isToday: isToday, isRedDay: isRedDay, isSunday: isSunday))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: isToday ? borders.selected : borders.cell)
        )
    }

    // MARK: - Styling Helpers

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

    private var dayColor: Color {
        if isRedDay { return JohoWidget.Colors.alert }
        if isSunday { return JohoWidget.Colors.alert }
        return JohoWidget.Colors.text
    }

    private var centerBackground: Color {
        if isRedDay { return JohoWidget.Colors.holiday.opacity(0.15) }
        if isSunday { return JohoWidget.Colors.alert.opacity(0.08) }
        return JohoWidget.Colors.content
    }
}
