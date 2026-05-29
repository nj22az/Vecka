//
//  SmallWidgetView.swift
//  VeckaWidget
//
//  Small Widget: Two-compartment bento card
//  Top: Colored month zone with icon + date
//  Bottom: White zone with fact/holiday
//  Matches Star page card pattern: squircle clip + border + divider
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

    private var monthTheme: WidgetMonthTheme {
        let month = calendar.component(.month, from: entry.date)
        return WidgetMonthTheme.theme(for: month)
    }

    private var dayOfMonth: Int {
        calendar.component(.day, from: entry.date)
    }

    private var monthShort: String {
        entry.date.formatted(.dateTime.month(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var yearString: String {
        String(calendar.component(.year, from: entry.date)).suffix(2).description
    }

    private var weekdayShort: String {
        entry.date.formatted(.dateTime.weekday(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
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

    private var fact: WidgetFacts.Fact {
        WidgetFacts.randomFact(for: entry.date)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width, geo.size.height) / 155
            let borderColor = JohoWidget.Colors.border(for: colorScheme)
            let cardRadius: CGFloat = 14 * scale

            // Single bento card: colored top + white bottom
            VStack(spacing: 0) {
                // ═══════════════════════════════════════════
                // TOP: Colored month zone (like Star page card)
                // ═══════════════════════════════════════════
                VStack(spacing: 3 * scale) {
                    // Month icon — centered, prominent
                    Image(systemName: monthTheme.icon)
                        .font(.system(size: 22 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(monthTheme.accentColor)

                    // Date row: big number + day/month + week badge
                    HStack(alignment: .firstTextBaseline, spacing: 4 * scale) {
                        Text("\(dayOfMonth)")
                            .font(.system(size: 34 * scale, weight: .black, design: .rounded))
                            .foregroundStyle(monthTheme.accentColor)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(weekdayShort)
                                .font(.system(size: 9 * scale, weight: .black, design: .rounded))
                                .foregroundStyle(monthTheme.accentColor.opacity(0.8))

                            Text("\(monthShort) \(yearString)")
                                .font(.system(size: 8 * scale, weight: .bold, design: .rounded))
                                .foregroundStyle(monthTheme.accentColor.opacity(0.6))
                        }

                        Spacer(minLength: 0)

                        // Week badge
                        Text("W\(entry.weekNumber)")
                            .font(.system(size: 9 * scale, weight: .black, design: .rounded))
                            .foregroundStyle(monthTheme.accentColor)
                            .padding(.horizontal, 5 * scale)
                            .padding(.vertical, 3 * scale)
                            .background(monthTheme.accentColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4 * scale, style: .continuous))
                    }
                }
                .padding(.horizontal, 10 * scale)
                .padding(.top, 8 * scale)
                .padding(.bottom, 6 * scale)
                .frame(maxWidth: .infinity)
                .background(monthTheme.lightBackground)

                // ═══════════════════════════════════════════
                // DIVIDER
                // ═══════════════════════════════════════════
                Rectangle()
                    .fill(borderColor)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════
                // BOTTOM: White zone — fact/holiday + country pill
                // ═══════════════════════════════════════════
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 5 * scale) {
                        Image(systemName: hasSpecialDay ? specialDaySymbol : fact.symbol)
                            .font(.system(size: 13 * scale, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))

                        Text(hasSpecialDay ? (specialDayName ?? "") : fact.text)
                            .font(.system(size: 11 * scale, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)

                        Spacer(minLength: 0)
                    }

                    Spacer(minLength: 0)

                    // Country pill — right-aligned
                    if !hasSpecialDay, let region = fact.region {
                        HStack {
                            Spacer()
                            Text(region)
                                .font(.system(size: 8 * scale, weight: .black, design: .rounded))
                                .foregroundStyle(JohoWidget.Colors.textSecondary(for: colorScheme))
                                .tracking(0.5)
                                .padding(.horizontal, 5 * scale)
                                .padding(.vertical, 2 * scale)
                                .background(borderColor.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 3 * scale, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                                        .stroke(borderColor.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 10 * scale)
                .padding(.vertical, 7 * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(JohoWidget.Colors.content(for: colorScheme))
            }
            .clipShape(WidgetSquircle(cornerRadius: cardRadius))
            .overlay(
                WidgetSquircle(cornerRadius: cardRadius)
                    .stroke(borderColor, lineWidth: 2)
            )
            .padding(4 * scale)
        }
        .widgetURL(URL(string: hasSpecialDay ? "vecka://today" : "vecka://facts/\(fact.id)"))
        .containerBackground(for: .widget) {
            JohoWidget.Colors.content(for: colorScheme)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if let special = specialDayName {
            return "\(special), \(weekdayShort) \(monthShort) \(dayOfMonth) \(yearString)"
        }
        return "\(weekdayShort) \(monthShort) \(dayOfMonth) \(yearString), \(fact.text)"
    }
}
