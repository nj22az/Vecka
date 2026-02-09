//
//  SmallWidgetView.swift
//  VeckaWidget
//
//  Small Widget: Two-compartment bento
//  Top: holiday/birthday or daily fact
//  Bottom: Big date + weekday + month + week badge
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
                // ═══════════════════════════════════════════
                // TOP: Holiday/birthday or daily fact
                // ═══════════════════════════════════════════
                HStack(spacing: 6 * scale) {
                    Image(systemName: hasSpecialDay ? specialDaySymbol : fact.symbol)
                        .font(.system(size: 18 * scale, weight: .bold))
                        .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))

                    Text(hasSpecialDay ? (specialDayName ?? "") : fact.text)
                        .font(.system(size: 11 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12 * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ═══════════════════════════════════════════
                // DIVIDER
                // ═══════════════════════════════════════════
                Rectangle()
                    .fill(JohoWidget.Colors.border(for: colorScheme))
                    .frame(height: 1.5)
                    .padding(.horizontal, 8 * scale)

                // ═══════════════════════════════════════════
                // BOTTOM: Big date + weekday + month + week
                // ═══════════════════════════════════════════
                VStack(spacing: 1 * scale) {
                    Text("\(dayOfMonth)")
                        .font(.system(size: 44 * scale, weight: .black, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))

                    Text(weekdayFull)
                        .font(.system(size: 11 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.textSecondary(for: colorScheme))
                        .tracking(1)

                    HStack(spacing: 6 * scale) {
                        Text(monthShort)
                            .font(.system(size: 10 * scale, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.textSecondary(for: colorScheme))

                        // Week badge pill
                        Text("W\(entry.weekNumber)")
                            .font(.system(size: 9 * scale, weight: .black, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))
                            .padding(.horizontal, 6 * scale)
                            .padding(.vertical, 2 * scale)
                            .background(JohoWidget.Colors.now)
                            .clipShape(RoundedRectangle(cornerRadius: 4 * scale, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                                    .stroke(JohoWidget.Colors.border(for: colorScheme), lineWidth: 1)
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .widgetURL(URL(string: hasSpecialDay ? "vecka://today" : "vecka://facts/\(fact.id)"))
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
