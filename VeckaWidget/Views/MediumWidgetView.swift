//
//  MediumWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Medium Widget
//  Two-column bento: Week info | Calendar strip
//  Philosophy: Compartmentalized information at a glance
//

import SwiftUI
import WidgetKit

struct VeckaMediumWidgetView: View {
    let entry: VeckaWidgetEntry

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        cal.locale = .autoupdatingCurrent
        return cal
    }()

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

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        return Array(symbols[1...]) + [symbols[0]]  // Monday first
    }

    private let holidayEngine = WidgetHolidayEngine()

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // LEFT COMPARTMENT: Week Info
            leftCompartment
                .frame(width: 100)

            // VERTICAL WALL (bento divider)
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(width: 2)

            // RIGHT COMPARTMENT: Calendar Strip
            rightCompartment
        }
        .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(JohoWidget.Colors.content)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week \(entry.weekNumber), \(monthYear)")
    }

    // MARK: - Left Compartment

    private var leftCompartment: some View {
        VStack(spacing: 6) {
            // Week badge (hero)
            Text("W\(entry.weekNumber)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.textInverted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(JohoWidget.Colors.border)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Day number
            Text("\(dayOfMonth)")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(dayColor)

            // Month year
            Text(monthYear)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))

            // Holiday indicator (if any)
            if let holiday = entry.todaysHolidays.first {
                HStack(spacing: 4) {
                    Circle()
                        .fill(holiday.isRedDay ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                        .frame(width: 6, height: 6)
                    Text(holiday.displayName)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.7))
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Right Compartment

    private var rightCompartment: some View {
        VStack(spacing: 6) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(weekdayColor(for: index))
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            HStack(spacing: 3) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, date in
                    dayCell(date: date, dayIndex: index)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

        VStack(spacing: 2) {
            Text("\(dayNumber)")
                .font(.system(size: 14, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(cellTextColor(isToday: isToday, isRedDay: isRedDay, isSunday: isSunday))

            // Event indicator dot
            if hasEvent {
                Circle()
                    .fill(isRedDay ? JohoWidget.Colors.holiday : JohoWidget.Colors.event)
                    .frame(width: 4, height: 4)
            } else {
                Spacer().frame(height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38)
        .background(cellBackground(isToday: isToday, isRedDay: isRedDay, isSunday: isSunday))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: isToday ? 2 : 0.5)
        )
    }

    // MARK: - Styling Helpers

    private func weekdayColor(for index: Int) -> Color {
        index == 6 ? JohoWidget.Colors.alert : JohoWidget.Colors.text.opacity(0.5)
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
        let isRedDay = entry.todaysHolidays.first?.isRedDay ?? false
        let isSunday = calendar.component(.weekday, from: entry.date) == 1
        if isRedDay { return JohoWidget.Colors.alert }
        if isSunday { return JohoWidget.Colors.alert }
        return JohoWidget.Colors.text
    }
}
