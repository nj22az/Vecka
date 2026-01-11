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

    private var year: String {
        String(entry.year)
    }

    private var currentWeekDays: [WeekDay] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date)) ?? entry.date
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) ?? entry.date
            let dayStart = calendar.startOfDay(for: date)
            let day = calendar.component(.day, from: date)
            let holidays = holidayEngine.getHolidays(for: date)
            let birthdays = entry.weekBirthdays[dayStart] ?? []
            let isToday = calendar.isDate(date, inSameDayAs: entry.date)
            let isSunday = offset == 6
            return WeekDay(
                day: day,
                isToday: isToday,
                isSunday: isSunday,
                isBankHoliday: holidays.first?.isBankHoliday ?? false,
                hasEvent: !holidays.isEmpty,
                hasBirthday: !birthdays.isEmpty
            )
        }
    }

    private var weekdayLabels: [String] {
        ["M", "T", "W", "T", "F", "S", "S"]
    }

    private var todayHolidayName: String? {
        entry.todaysHolidays.first?.displayName
    }

    private var todayBirthdayName: String? {
        entry.todaysBirthdays.first?.displayName
    }

    // 情報デザイン: Theme constants for consistency
    private var typo: JohoWidget.Typography.Scale { JohoWidget.Typography.medium }
    private var borders: JohoWidget.Borders.Weights { JohoWidget.Borders.medium }
    private var corners: JohoWidget.Corners.Radii { JohoWidget.Corners.medium }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // LEFT: Week Number Hero (Japanese: bold center focus)
                weekNumberHero
                    .frame(width: geo.size.width * 0.35)

                // Vertical divider (情報デザイン: match border weight)
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(width: borders.container)

                // RIGHT: Minimal calendar strip
                rightPanel
                    .frame(maxWidth: .infinity)
            }
        }
        .widgetURL(URL(string: "vecka://week/\(weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            // 情報デザイン: Theme.Borders.medium.widget = 2.5pt
            RoundedRectangle(cornerRadius: corners.widget, style: .continuous)
                .fill(JohoWidget.Colors.content)
                .overlay(
                    RoundedRectangle(cornerRadius: corners.widget - 2, style: .continuous)
                        .stroke(JohoWidget.Colors.border, lineWidth: borders.widget)
                        .padding(1)
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week \(weekNumber), \(monthName) \(today)")
    }

    // MARK: - Week Number Hero (Japanese: 間 MA - centered with breathing room)

    private var weekNumberHero: some View {
        VStack(spacing: 2) {
            // Main hero: Week number (情報デザイン: Theme.Typography.medium.weekNumber = 56pt)
            Text("\(weekNumber)")
                .font(.system(size: typo.weekNumber, weight: .black, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .minimumScaleFactor(0.7)

            // Subtitle: "WEEK" (情報デザイン: visible, minimum 9pt)
            Text("WEEK")
                .font(.system(size: typo.label, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
                .tracking(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 情報デザイン: WHITE background - color only on TODAY indicator
    }

    // MARK: - Right Panel (Japanese minimalism: curated content)

    private var rightPanel: some View {
        VStack(spacing: 0) {
            // Top: Month + Year label (情報デザイン: complete information, readable)
            HStack {
                Text("\(monthName) \(year)")
                    .font(.system(size: typo.caption, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
                    .tracking(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Spacer(minLength: 6)

            // Center: Clean week strip (日本: focus on essential)
            weekStrip
                .padding(.horizontal, 6)

            Spacer(minLength: 6)

            // Bottom: Holiday/Birthday indicators (情報デザイン: icons for both)
            VStack(spacing: 4) {
                if let holiday = todayHolidayName {
                    holidayIndicator(name: holiday)
                }
                if let birthday = todayBirthdayName {
                    birthdayIndicator(name: birthday)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, todayHolidayName == nil && todayBirthdayName == nil ? 8 : 4)

            if todayHolidayName == nil && todayBirthdayName == nil {
                Color.clear.frame(height: 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Week Strip (情報デザイン: minimal, clear hierarchy)

    private var weekStrip: some View {
        HStack(spacing: 2) {
            ForEach(Array(currentWeekDays.enumerated()), id: \.offset) { index, weekDay in
                VStack(spacing: 1) {
                    // Weekday label (情報デザイン: minimum 9pt per audit)
                    Text(weekdayLabels[index])
                        .font(.system(size: typo.label, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            weekDay.isSunday
                                ? JohoWidget.Colors.alert.opacity(0.6)
                                : JohoWidget.Colors.text.opacity(0.4)
                        )

                    // Day number (情報デザイン: Circle for today = NOW indicator)
                    // Day cell: 28pt width for better touch target (limited by widget space)
                    ZStack {
                        if weekDay.isToday {
                            Circle()
                                .fill(JohoWidget.Colors.now)
                                .frame(width: 28, height: 28)
                            Circle()
                                .stroke(JohoWidget.Colors.border, lineWidth: borders.selected)
                                .frame(width: 28, height: 28)
                        } else if weekDay.isBankHoliday {
                            Circle()
                                .fill(JohoWidget.Colors.holiday.opacity(0.3))
                                .frame(width: 28, height: 28)
                        }
                        Text("\(weekDay.day)")
                            .font(.system(size: typo.body, weight: weekDay.isToday ? .black : .medium, design: .rounded))
                            .foregroundStyle(dayTextColor(weekDay))
                    }
                    .frame(width: 28, height: 28)

                    // Event indicators (情報デザイン: icons for holidays and birthdays)
                    HStack(spacing: 1) {
                        if weekDay.hasEvent {
                            Image(systemName: "star.fill")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(weekDay.isBankHoliday ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                        }
                        if weekDay.hasBirthday {
                            Image(systemName: "birthday.cake.fill")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(JohoWidget.Colors.holiday) // Pink for birthdays
                        }
                    }
                    .frame(height: 8)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Holiday Indicator (情報デザイン: readable, untruncated)

    private func holidayIndicator(name: String) -> some View {
        HStack(spacing: 6) {
            // 情報デザイン: Use star icon for holidays (consistent with main app)
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(JohoWidget.Colors.alert)

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
        .background(JohoWidget.Colors.holiday.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Birthday Indicator (情報デザイン: consistent with main app)

    private func birthdayIndicator(name: String) -> some View {
        HStack(spacing: 6) {
            // 情報デザイン: Use birthday cake icon (consistent with main app)
            Image(systemName: "birthday.cake.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(JohoWidget.Colors.holiday) // Pink for birthdays

            Text(name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(JohoWidget.Colors.holiday.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: 1)
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
    let hasBirthday: Bool  // 情報デザイン: Birthday support
}
