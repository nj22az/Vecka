//
//  SmallWidgetView.swift
//  VeckaWidget
//
//  Small widget: Clean design with Liquid Glass on navigation only
//  Glass = week badge only. Content = clean and readable.
//

import SwiftUI
import WidgetKit

struct VeckaSmallWidgetView: View {
    let entry: VeckaWidgetEntry

    private var monthAbbrev: String {
        entry.date.formatted(.dateTime.month(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var dayOfMonth: String {
        "\(Calendar.current.component(.day, from: entry.date))"
    }

    private var weekdayName: String {
        entry.date.formatted(.dateTime.weekday(.wide).locale(.autoupdatingCurrent)).capitalized
    }

    private var weekdayIndex: Int {
        Calendar.current.component(.weekday, from: entry.date)
    }

    private var hasHolidayToday: Bool {
        !entry.todaysHolidays.isEmpty
    }

    private var isRedDay: Bool {
        entry.todaysHolidays.first?.isRedDay ?? false
    }

    private var hasObservance: Bool {
        hasHolidayToday && !isRedDay
    }

    var body: some View {
        VStack(spacing: 0) {
            // HEADER: Month (Left) + Week Badge with Glass (Right)
            HStack(alignment: .center) {
                Text(monthAbbrev)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WidgetColors.accent)

                Spacer()

                // Week Badge - GLASS (navigation element)
                Text("\(entry.weekNumber)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassEffect(.regular, in: .capsule)
            }
            .padding(.top, 14)
            .padding(.horizontal, 14)

            Spacer()

            // CENTER: Large Day Number - NO GLASS (content)
            VStack(spacing: 2) {
                Text(dayOfMonth)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(dayTextColor)

                Text(weekdayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(dayTextColor.opacity(0.8))
            }

            Spacer()

            // BOTTOM: Holiday Indicator or Calendar Access Notice - NO GLASS (content)
            if hasHolidayToday {
                HStack(spacing: 5) {
                    Circle()
                        .fill(isRedDay ? WidgetColors.holiday : WidgetColors.observance)
                        .frame(width: 6, height: 6)

                    if let holiday = entry.todaysHolidays.first {
                        Text(holiday.displayName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(isRedDay ? WidgetColors.holiday : WidgetColors.observance)
                            .lineLimit(1)
                    }
                }
                .padding(.bottom, 14)
                .padding(.horizontal, 10)
            } else if entry.calendarAccessDenied {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 10))
                    Text("Calendar access needed")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(.bottom, 14)
                .padding(.horizontal, 10)
            } else {
                Spacer().frame(height: 14)
            }
        }
        .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        .containerBackground(.fill.tertiary, for: .widget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(widgetAccessibilityLabel)
    }

    private var widgetAccessibilityLabel: String {
        var label = "\(weekdayName), \(monthAbbrev) \(dayOfMonth), Week \(entry.weekNumber)"
        if let holiday = entry.todaysHolidays.first {
            label += ", \(holiday.displayName)"
            if isRedDay {
                label += ", public holiday"
            }
        }
        return label
    }

    private var dayTextColor: Color {
        if isRedDay { return WidgetColors.holiday }
        if hasObservance { return WidgetColors.observance }
        switch weekdayIndex {
        case 1: return WidgetColors.sundayBlue  // Sunday = Blue
        default: return .primary                 // All other days = normal
        }
    }
}
