//
//  MediumWidgetView.swift
//  VeckaWidget
//
//  Medium widget: Clean design with Liquid Glass on navigation only
//  Glass = week badge only. Calendar content = clean and readable.
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

    private var monthName: String {
        entry.date.formatted(.dateTime.month(.wide).locale(.autoupdatingCurrent)).capitalized
    }

    private var yearString: String {
        entry.date.formatted(.dateTime.year().locale(.autoupdatingCurrent))
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        return Array(symbols[1...]) + [symbols[0]]
    }

    private let holidayEngine = WidgetHolidayEngine()

    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            HStack(alignment: .center) {
                // Month + Year - NO GLASS (content)
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(monthName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(WidgetColors.accent)

                    Text(yearString)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Week Badge - GLASS (navigation element)
                Text("\(entry.weekNumber)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .glassEffect(.regular, in: .capsule)
            }
            .padding(.top, 14)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Spacer()

            // CALENDAR ROW - NO GLASS (content)
            VStack(spacing: 6) {
                // Weekday Headers
                HStack(spacing: 0) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(weekdayHeaderColor(for: index))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)

                // Days Row
                HStack(spacing: 0) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { index, date in
                        dayCellView(date: date, dayIndex: index)
                    }
                }
                .padding(.horizontal, 14)
            }
            .padding(.bottom, 16)
        }
        .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        .containerBackground(.fill.tertiary, for: .widget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(widgetAccessibilityLabel)
    }

    private var widgetAccessibilityLabel: String {
        let todayFormatted = entry.date.formatted(date: .complete, time: .omitted)
        var label = "\(monthName) \(yearString), Week \(entry.weekNumber). Today: \(todayFormatted)"
        if let holiday = entry.todaysHolidays.first {
            label += ", \(holiday.displayName)"
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
    private func dayCellView(date: Date, dayIndex: Int) -> some View {
        let isToday = calendar.isDate(date, inSameDayAs: entry.date)
        let dayNumber = calendar.component(.day, from: date)
        let holidays = holidayEngine.getHolidays(for: date)
        let isRedDay = holidays.first?.isRedDay ?? false

        let textColor: Color = {
            if isToday { return .white }
            if isRedDay { return WidgetColors.holiday }
            if dayIndex == 6 { return WidgetColors.sundayBlue }  // Sunday = Blue
            return .primary
        }()

        ZStack {
            // Today indicator - squircle (continuous corner radius)
            if isToday {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(WidgetColors.accent)
                    .frame(width: 32, height: 32)
            }

            Text("\(dayNumber)")
                .font(.system(size: 17, weight: isToday ? .bold : .medium))
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity)
    }
}
