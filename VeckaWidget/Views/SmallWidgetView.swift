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
        // High contrast: white background for all states
        return JohoWidget.Colors.content
    }

    /// Color indicator for the current day type
    private var indicatorColor: Color {
        if !entry.todaysHolidays.isEmpty {
            return JohoWidget.Colors.holiday  // Pink
        }
        if !entry.todaysBirthdays.isEmpty {
            return JohoWidget.Colors.contact  // Purple
        }
        // Fact colors based on type
        let fact = WidgetFacts.randomFact(for: entry.date)
        switch fact.type {
        case .dateBased:
            return JohoWidget.Colors.event  // Cyan
        case .nordic:
            return JohoWidget.Colors.now  // Yellow
        case .trivia:
            return JohoWidget.Colors.event  // Cyan
        }
    }

    private var fact: WidgetFacts.Fact {
        WidgetFacts.randomFact(for: entry.date)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width, geo.size.height) / 155

            VStack(spacing: 0) {
                // Top color indicator stripe
                RoundedRectangle(cornerRadius: 2 * scale, style: .continuous)
                    .fill(indicatorColor)
                    .frame(maxWidth: .infinity, maxHeight: 6 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2 * scale, style: .continuous)
                            .stroke(JohoWidget.Colors.border, lineWidth: 1)
                    )
                    .padding(.horizontal, 12 * scale)
                    .padding(.top, 8 * scale)

                VStack(spacing: 6 * scale) {
                    // Top: SF Symbol + special text or fact
                    HStack(spacing: 6 * scale) {
                        Image(systemName: hasSpecialDay ? specialDaySymbol : fact.symbol)
                            .font(.system(size: 14 * scale, weight: .bold))
                            .foregroundStyle(JohoWidget.Colors.text)

                        Text(hasSpecialDay ? (specialDayName ?? "") : fact.text)
                            .font(.system(size: 11 * scale, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)

                        Spacer(minLength: 0)
                    }

                    Spacer(minLength: 0)

                    // Center: Big date
                    VStack(spacing: 2 * scale) {
                        Text(monthShort)
                            .font(.system(size: 12 * scale, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.textSecondary)
                            .tracking(1)

                        Text("\(dayOfMonth)")
                            .font(.system(size: 48 * scale, weight: .black, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text)

                        Text(weekdayFull)
                            .font(.system(size: 12 * scale, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.textSecondary)
                            .tracking(1)
                    }

                    Spacer(minLength: 0)

                    // Bottom: Week badge
                    HStack {
                        Spacer()
                        weekBadge(scale: scale)
                    }
                }
                .padding(.horizontal, 12 * scale)
                .padding(.bottom, 16 * scale)
                .padding(.top, 6 * scale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .widgetURL(URL(string: "vecka://today"))
        .containerBackground(for: .widget) {
            backgroundColor
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Week Badge

    private func weekBadge(scale: CGFloat) -> some View {
        Text("W\(entry.weekNumber)")
            .font(.system(size: 10 * scale, weight: .black, design: .rounded))
            .foregroundStyle(JohoWidget.Colors.text)
            .padding(.horizontal, 8 * scale)
            .padding(.vertical, 4 * scale)
            .background(JohoWidget.Colors.content)
            .clipShape(RoundedRectangle(cornerRadius: 6 * scale, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                    .stroke(JohoWidget.Colors.border, lineWidth: 1.5)
            )
    }

    private var accessibilityLabel: String {
        if let special = specialDayName {
            return "\(special), \(weekdayFull) \(monthShort) \(dayOfMonth)"
        }
        return "\(weekdayFull) \(monthShort) \(dayOfMonth), \(fact.text)"
    }
}
