//
//  MediumWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Medium Widget
//  Japanese minimalism: MA (negative space), focused hierarchy
//  Hero week number left | Clean week strip right
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

    private var weekNumber: Int { entry.weekNumber }
    private var today: Int { calendar.component(.day, from: entry.date) }
    private var todayWeekday: Int {
        let wd = calendar.component(.weekday, from: entry.date)
        return wd == 1 ? 7 : wd - 1  // Monday=1 system
    }

    private var monthName: String {
        entry.date.formatted(.dateTime.month(.wide).locale(.autoupdatingCurrent)).uppercased()
    }

    private var currentWeekDays: [WeekDay] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date)) ?? entry.date
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) ?? entry.date
            let day = calendar.component(.day, from: date)
            let holidays = holidayEngine.getHolidays(for: date)
            let isToday = calendar.isDate(date, inSameDayAs: entry.date)
            let isSunday = offset == 6
            return WeekDay(
                day: day,
                isToday: isToday,
                isSunday: isSunday,
                isBankHoliday: holidays.first?.isBankHoliday ?? false,
                hasEvent: !holidays.isEmpty
            )
        }
    }

    private var weekdayLabels: [String] {
        ["M", "T", "W", "T", "F", "S", "S"]
    }

    private var todayHolidayName: String? {
        entry.todaysHolidays.first?.displayName
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // LEFT: Week Number Hero (Japanese: bold center focus)
                weekNumberHero
                    .frame(width: geo.size.width * 0.35)

                // Vertical divider (情報デザイン: thin black wall)
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(width: 1.5)

                // RIGHT: Minimal calendar strip
                rightPanel
                    .frame(maxWidth: .infinity)
            }
        }
        .widgetURL(URL(string: "vecka://week/\(weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(JohoWidget.Colors.content)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(JohoWidget.Colors.border.opacity(0.3), lineWidth: 1)
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week \(weekNumber), \(monthName) \(today)")
    }

    // MARK: - Week Number Hero (Japanese: 間 MA - centered with breathing room)

    private var weekNumberHero: some View {
        VStack(spacing: 2) {
            // Main hero: Week number
            Text("\(weekNumber)")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .minimumScaleFactor(0.7)

            // Subtitle: "WEEK"
            Text("WEEK")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.35))
                .tracking(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoWidget.Colors.now.opacity(0.25))
    }

    // MARK: - Right Panel (Japanese minimalism: curated content)

    private var rightPanel: some View {
        VStack(spacing: 0) {
            // Top: Month label (small, understated)
            HStack {
                Text(monthName)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.4))
                    .tracking(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            Spacer(minLength: 6)

            // Center: Clean week strip (日本: focus on essential)
            weekStrip
                .padding(.horizontal, 6)

            Spacer(minLength: 6)

            // Bottom: Holiday indicator or nothing (MA: empty space is meaningful)
            if let holiday = todayHolidayName {
                holidayIndicator(name: holiday)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
            } else {
                Color.clear.frame(height: 20)
                    .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Week Strip (情報デザイン: minimal, clear hierarchy)

    private var weekStrip: some View {
        HStack(spacing: 2) {
            ForEach(Array(currentWeekDays.enumerated()), id: \.offset) { index, weekDay in
                VStack(spacing: 1) {
                    // Weekday label (tiny, subtle)
                    Text(weekdayLabels[index])
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            weekDay.isSunday
                                ? JohoWidget.Colors.alert.opacity(0.6)
                                : JohoWidget.Colors.text.opacity(0.3)
                        )

                    // Day number
                    Text("\(weekDay.day)")
                        .font(.system(size: 13, weight: weekDay.isToday ? .black : .medium, design: .rounded))
                        .foregroundStyle(dayTextColor(weekDay))
                        .frame(width: 26, height: 26)
                        .background(dayBackground(weekDay))
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(
                                    weekDay.isToday ? JohoWidget.Colors.border : Color.clear,
                                    lineWidth: weekDay.isToday ? 1 : 0
                                )
                        )

                    // Event indicator (minimal dot)
                    Circle()
                        .fill(weekDay.hasEvent
                            ? (weekDay.isBankHoliday ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                            : Color.clear)
                        .frame(width: 3, height: 3)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Holiday Indicator (情報デザイン: readable, untruncated)

    private func holidayIndicator(name: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(JohoWidget.Colors.holiday)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(JohoWidget.Colors.border, lineWidth: 0.5)
                )

            Text(name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(JohoWidget.Colors.holiday.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(JohoWidget.Colors.border.opacity(0.3), lineWidth: 0.75)
        )
    }

    // MARK: - Styling Helpers

    private func dayTextColor(_ weekDay: WeekDay) -> Color {
        if weekDay.isToday { return JohoWidget.Colors.text }
        if weekDay.isBankHoliday { return JohoWidget.Colors.alert }
        if weekDay.isSunday { return JohoWidget.Colors.alert.opacity(0.8) }
        return JohoWidget.Colors.text.opacity(0.8)
    }

    private func dayBackground(_ weekDay: WeekDay) -> Color {
        if weekDay.isToday { return JohoWidget.Colors.now }
        if weekDay.isBankHoliday { return JohoWidget.Colors.holiday.opacity(0.2) }
        return Color.clear
    }
}

// MARK: - Week Day Model

private struct WeekDay {
    let day: Int
    let isToday: Bool
    let isSunday: Bool
    let isBankHoliday: Bool
    let hasEvent: Bool
}
