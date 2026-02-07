//
//  SmallWidgetView.swift
//  VeckaWidget
//
//  Small Widget: "Is today special?"
//  Shows holiday/birthday OR random fact
//  Clean typography, SF Symbol accent
//

import SwiftUI
import WidgetKit

struct VeckaSmallWidgetView: View {
    let entry: VeckaWidgetEntry
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        cal.locale = .autoupdatingCurrent
        return cal
    }

    private var dayOfMonth: Int {
        calendar.component(.day, from: entry.date)
    }

    private var monthShort: String {
        entry.date.formatted(.dateTime.month(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var weekdayFull: String {
        entry.date.formatted(.dateTime.weekday(.wide).locale(.autoupdatingCurrent)).uppercased()
    }

    private var hasSpecialDay: Bool {
        !entry.todaysHolidays.isEmpty || !entry.todaysBirthdays.isEmpty
    }

    private var specialDayName: String? {
        if let holiday = entry.todaysHolidays.first {
            return holiday.displayName
        }
        if let birthday = entry.todaysBirthdays.first {
            return birthday.displayName
        }
        return nil
    }

    private var specialDaySymbol: String {
        if !entry.todaysHolidays.isEmpty {
            let holiday = entry.todaysHolidays.first
            return holiday?.isBankHoliday == true ? "star.fill" : "sparkles"
        }
        if !entry.todaysBirthdays.isEmpty {
            return "gift.fill"
        }
        return "calendar"
    }

    private var backgroundColor: Color {
        // High contrast: adapts to color scheme
        return JohoWidget.Colors.content(for: colorScheme)
    }

    private var fact: WidgetFacts.Fact {
        WidgetFacts.randomFact(for: entry.date)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width, geo.size.height) / 155

            VStack(spacing: 0) {
                // Top: SF Symbol + special text or fact
                HStack(spacing: 6 * scale) {
                    Image(systemName: hasSpecialDay ? specialDaySymbol : fact.symbol)
                        .font(.system(size: 14 * scale, weight: .bold))
                        .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))

                    Text(hasSpecialDay ? (specialDayName ?? "") : fact.text)
                        .font(.system(size: 11 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12 * scale)
                .padding(.top, 12 * scale)

                Spacer(minLength: 0)

                // Center: Big date
                VStack(spacing: 2 * scale) {
                    Text(monthShort)
                        .font(.system(size: 12 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.textSecondary(for: colorScheme))
                        .tracking(1)

                    Text("\(dayOfMonth)")
                        .font(.system(size: 48 * scale, weight: .black, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))

                    Text(weekdayFull)
                        .font(.system(size: 12 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.textSecondary(for: colorScheme))
                        .tracking(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.bottom, 12 * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .widgetURL(URL(string: "vecka://today"))
        .containerBackground(for: .widget) {
            backgroundColor
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if let special = specialDayName {
            return "\(special), \(weekdayFull) \(monthShort) \(dayOfMonth)"
        }
        return "\(weekdayFull) \(monthShort) \(dayOfMonth), \(fact.text)"
    }
}
