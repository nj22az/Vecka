//
//  MediumWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Medium Widget
//  Japanese minimalism: MA (negative space), focused hierarchy
//  Hero week number left | Clean week strip right
//  ADAPTIVE: Scales properly for iPhone and iPad widget sizes
//

import SwiftUI
import WidgetKit

struct VeckaMediumWidgetView: View {
    let entry: VeckaWidgetEntry

    // 情報デザイン: Use computed property to avoid storing Calendar instance
    private var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        cal.locale = .autoupdatingCurrent
        return cal
    }

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
            let holidays = entry.holidays(for: date)
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

    /// Simulate blinking by checking if minute is divisible by 7
    private var isBlinking: Bool {
        let minute = Calendar.current.component(.minute, from: entry.date)
        return minute % 7 == 0
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let metrics = AdaptiveMetrics(size: geo.size)

            HStack(spacing: 0) {
                // LEFT: Week Number Hero
                weekNumberHero(metrics: metrics)
                    .frame(width: geo.size.width * 0.32)

                // Vertical divider
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(width: metrics.borderWidth)

                // RIGHT: Minimal calendar strip
                rightPanel(metrics: metrics)
                    .frame(maxWidth: .infinity)
            }
        }
        .widgetURL(URL(string: "vecka://week/\(weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            JohoWidget.Colors.content
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week \(weekNumber), \(monthName) \(today)")
    }

    // MARK: - Week Number Hero (Mascot)

    private func weekNumberHero(metrics: AdaptiveMetrics) -> some View {
        VStack(spacing: metrics.spacing * 0.3) {
            // Mascot with week number
            JohoWidget.WidgetMascot(
                size: metrics.mascotSize,
                weekNumber: weekNumber,
                isBlinking: isBlinking,
                accentColor: JohoWidget.Colors.now
            )

            Text("WEEK \(weekNumber)")
                .font(.system(size: metrics.labelSize, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.textSecondary)
                .tracking(metrics.isLarge ? 2 : 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Right Panel

    private func rightPanel(metrics: AdaptiveMetrics) -> some View {
        VStack(spacing: 0) {
            // Top: Month + Year label
            HStack {
                Text("\(monthName) \(year)")
                    .font(.system(size: metrics.captionSize, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.textSecondary)
                    .tracking(metrics.isLarge ? 2 : 1)
                Spacer()
            }
            .padding(.horizontal, metrics.padding)
            .padding(.top, metrics.padding * 0.6)

            Spacer(minLength: metrics.spacing * 0.5)

            // Center: Clean week strip
            weekStrip(metrics: metrics)
                .padding(.horizontal, metrics.padding * 0.5)

            Spacer(minLength: metrics.spacing * 0.5)

            // Bottom: Holiday/Birthday indicators
            VStack(spacing: metrics.spacing * 0.3) {
                if let holiday = todayHolidayName {
                    holidayIndicator(name: holiday, metrics: metrics)
                }
                if let birthday = todayBirthdayName {
                    birthdayIndicator(name: birthday, metrics: metrics)
                }
            }
            .padding(.horizontal, metrics.padding * 0.8)
            .padding(.bottom, todayHolidayName == nil && todayBirthdayName == nil ? metrics.padding * 0.6 : metrics.spacing * 0.3)

            if todayHolidayName == nil && todayBirthdayName == nil {
                Color.clear.frame(height: metrics.padding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Week Strip

    private func weekStrip(metrics: AdaptiveMetrics) -> some View {
        HStack(spacing: metrics.dayCellSpacing) {
            ForEach(Array(currentWeekDays.enumerated()), id: \.offset) { index, weekDay in
                VStack(spacing: metrics.spacing * 0.1) {
                    // Weekday label (情報デザイン: never below .medium weight)
                    Text(weekdayLabels[index])
                        .font(.system(size: metrics.labelSize, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            weekDay.isSunday
                                ? JohoWidget.Colors.alert
                                : JohoWidget.Colors.textSecondary
                        )

                    // Day number with circle
                    ZStack {
                        if weekDay.isToday {
                            Circle()
                                .fill(JohoWidget.Colors.now)
                                .frame(width: metrics.dayCellSize, height: metrics.dayCellSize)
                            Circle()
                                .stroke(JohoWidget.Colors.border, lineWidth: metrics.borderWidth)
                                .frame(width: metrics.dayCellSize, height: metrics.dayCellSize)
                        } else if weekDay.isBankHoliday {
                            Circle()
                                .fill(JohoWidget.Colors.holiday)
                                .frame(width: metrics.dayCellSize, height: metrics.dayCellSize)
                            Circle()
                                .stroke(JohoWidget.Colors.border, lineWidth: metrics.cellBorderWidth)
                                .frame(width: metrics.dayCellSize, height: metrics.dayCellSize)
                        }
                        Text("\(weekDay.day)")
                            .font(.system(size: metrics.bodySize, weight: weekDay.isToday ? .black : .medium, design: .rounded))
                            .foregroundStyle(dayTextColor(weekDay))
                    }
                    .frame(width: metrics.dayCellSize, height: metrics.dayCellSize)

                    // Event indicators
                    HStack(spacing: 1) {
                        if weekDay.hasEvent {
                            Image(systemName: "star.fill")
                                .font(.system(size: metrics.indicatorSize, weight: .bold))
                                .foregroundStyle(weekDay.isBankHoliday ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                        }
                        if weekDay.hasBirthday {
                            Image(systemName: "birthday.cake.fill")
                                .font(.system(size: metrics.indicatorSize, weight: .bold))
                                .foregroundStyle(JohoWidget.Colors.holiday)
                        }
                    }
                    .frame(height: metrics.indicatorSize + 2)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Holiday Indicator

    private func holidayIndicator(name: String, metrics: AdaptiveMetrics) -> some View {
        HStack(spacing: metrics.spacing * 0.5) {
            Image(systemName: "star.fill")
                .font(.system(size: metrics.indicatorSize + 2, weight: .bold))
                .foregroundStyle(JohoWidget.Colors.alert)

            Text(name)
                .font(.system(size: metrics.captionSize, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.vertical, metrics.spacing * 0.3)
        .padding(.horizontal, metrics.padding * 0.6)
        .background(JohoWidget.Colors.holiday)
        .clipShape(RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: metrics.rowBorderWidth)
        )
    }

    // MARK: - Birthday Indicator

    private func birthdayIndicator(name: String, metrics: AdaptiveMetrics) -> some View {
        HStack(spacing: metrics.spacing * 0.5) {
            Image(systemName: "birthday.cake.fill")
                .font(.system(size: metrics.indicatorSize + 2, weight: .bold))
                .foregroundStyle(JohoWidget.Colors.text)

            Text(name)
                .font(.system(size: metrics.captionSize, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()
        }
        .padding(.vertical, metrics.spacing * 0.3)
        .padding(.horizontal, metrics.padding * 0.6)
        .background(JohoWidget.Colors.holiday)
        .clipShape(RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: metrics.rowBorderWidth)
        )
    }

    // MARK: - Styling Helpers

    private func dayTextColor(_ weekDay: WeekDay) -> Color {
        if weekDay.isToday { return JohoWidget.Colors.text }
        if weekDay.isBankHoliday { return JohoWidget.Colors.alert }
        if weekDay.isSunday { return JohoWidget.Colors.alert }
        return JohoWidget.Colors.text
    }
}

// MARK: - Adaptive Metrics

/// Calculates adaptive sizes based on widget dimensions
/// iPhone medium widget: ~329 x 155 pt
/// iPad medium widget: ~348 x 159 pt (small iPad) to ~412 x 188 pt (large iPad)
private struct AdaptiveMetrics {
    let size: CGSize

    /// Scale factor based on widget height (baseline: 155pt for iPhone)
    private var scale: CGFloat {
        let baselineHeight: CGFloat = 155
        return max(1.0, size.height / baselineHeight)
    }

    /// True if this appears to be iPad-sized
    var isLarge: Bool {
        size.height > 170 || size.width > 380
    }

    // MARK: - Typography (scaled)

    var weekNumberSize: CGFloat {
        let base: CGFloat = 56
        return base * scale
    }

    var labelSize: CGFloat {
        let base: CGFloat = 9
        return max(9, base * scale)  // Minimum 9pt for readability
    }

    var bodySize: CGFloat {
        let base: CGFloat = 13
        return base * scale
    }

    var captionSize: CGFloat {
        let base: CGFloat = 11
        return max(10, base * scale)
    }

    var indicatorSize: CGFloat {
        let base: CGFloat = 7
        return base * scale
    }

    // MARK: - Layout (scaled)

    var mascotSize: CGFloat {
        let base: CGFloat = 70
        return base * scale
    }

    var dayCellSize: CGFloat {
        let base: CGFloat = 28
        return base * scale
    }

    var dayCellSpacing: CGFloat {
        let base: CGFloat = 2
        return base * scale
    }

    var padding: CGFloat {
        let base: CGFloat = 12
        return base * scale
    }

    var spacing: CGFloat {
        let base: CGFloat = 8
        return base * scale
    }

    var borderWidth: CGFloat {
        isLarge ? 2 : 1.5
    }

    // 情報デザイン: Spec-compliant border widths (Theme.swift medium = 0.75 cell, 1 row)
    var cellBorderWidth: CGFloat {
        isLarge ? 1 : 0.75
    }

    var rowBorderWidth: CGFloat {
        isLarge ? 1.5 : 1
    }

    var cornerRadius: CGFloat {
        let base: CGFloat = 6
        return base * scale
    }
}

// MARK: - Week Day Model

private struct WeekDay {
    let day: Int
    let isToday: Bool
    let isSunday: Bool
    let isBankHoliday: Bool
    let hasEvent: Bool
    let hasBirthday: Bool
}
