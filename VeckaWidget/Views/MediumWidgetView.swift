//
//  MediumWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Medium Widget
//  Clean week strip with bold typography and high contrast
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
        let month = entry.date.formatted(.dateTime.month(.wide).locale(.autoupdatingCurrent)).uppercased()
        let year = entry.date.formatted(.dateTime.year().locale(.autoupdatingCurrent))
        return "\(month) \(year)"
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        return Array(symbols[1...]) + [symbols[0]]  // Monday first
    }

    private let holidayEngine = WidgetHolidayEngine()

    var body: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            // HEADER: Month Year + Week Badge
            HStack(alignment: .center) {
                Text(monthYear)
                    .font(JohoWidgetFont.headerMedium)
                    .foregroundStyle(JohoWidgetColors.black)

                Spacer()

                JohoWeekBadge(weekNumber: entry.weekNumber, size: .medium)
            }
            .padding(.horizontal, JohoDimensions.spacingXL)
            .padding(.top, JohoDimensions.spacingLG)

            Spacer()

            // WEEK STRIP: Clean calendar row
            VStack(spacing: JohoDimensions.spacingSM) {
                // Weekday labels
                HStack(spacing: 0) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol)
                            .font(JohoWidgetFont.labelSmall)
                            .foregroundStyle(weekdayColor(for: index))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Day numbers
                HStack(spacing: 0) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { index, date in
                        dayCell(date: date, dayIndex: index)
                    }
                }
            }
            .padding(.horizontal, JohoDimensions.spacingXL)
            .padding(.bottom, JohoDimensions.spacingXL)
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
        index == 6 ? JohoWidgetColors.sundayBlue : JohoWidgetColors.black.opacity(0.6)
    }

    @ViewBuilder
    private func dayCell(date: Date, dayIndex: Int) -> some View {
        let isToday = calendar.isDate(date, inSameDayAs: entry.date)
        let dayNumber = calendar.component(.day, from: date)
        let holidays = holidayEngine.getHolidays(for: date)
        let isRedDay = holidays.first?.isRedDay ?? false
        let isSunday = dayIndex == 6

        JohoDayCell(
            day: dayNumber,
            isToday: isToday,
            isRedDay: isRedDay,
            isSunday: isSunday,
            cellSize: 30
        )
    }

    private var accessibilityLabel: String {
        var label = "\(monthYear), Week \(entry.weekNumber)"
        if let holiday = entry.todaysHolidays.first {
            label += ", \(holiday.displayName)"
        }
        return label
    }
}
