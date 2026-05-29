//
//  LargeWidgetView.swift
//  VeckaWidget
//
//  Large Widget: Three-section bento with star card
//  Header → Today's holiday with notes → Upcoming list → Fact bar
//

import SwiftUI
import WidgetKit

struct VeckaLargeWidgetView: View {
    let entry: VeckaWidgetEntry
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Calendar

    private var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        cal.locale = .autoupdatingCurrent
        return cal
    }

    // MARK: - Month Theme

    private var monthTheme: WidgetMonthTheme {
        let month = calendar.component(.month, from: entry.date)
        return WidgetMonthTheme.theme(for: month)
    }

    // MARK: - Computed Properties

    private var dayOfMonth: Int {
        calendar.component(.day, from: entry.date)
    }

    private var monthShort: String {
        entry.date.formatted(.dateTime.month(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var weekdayFull: String {
        entry.date.formatted(.dateTime.weekday(.wide).locale(.autoupdatingCurrent)).uppercased()
    }

    private var yearString: String {
        String(calendar.component(.year, from: entry.date))
    }

    private var fact: WidgetFacts.Fact {
        WidgetFacts.randomFact(for: entry.date)
    }

    /// Today's holiday/birthday for the TODAY section
    private var todayItem: TodayDisplayItem? {
        if let holiday = entry.todaysHolidays.first {
            return TodayDisplayItem(
                name: holiday.displayName,
                symbol: holiday.isBankHoliday ? "star.fill" : "sparkles",
                notes: holiday.notes,
                isBankHoliday: holiday.isBankHoliday
            )
        }
        if let birthday = entry.todaysBirthdays.first {
            return TodayDisplayItem(
                name: birthday.displayName,
                symbol: "gift.fill",
                notes: nil,
                isBankHoliday: false
            )
        }
        return nil
    }

    /// Combined list of upcoming specials (holidays + birthdays)
    private var upcomingItems: [UpcomingItem] {
        var items: [UpcomingItem] = []

        // Add upcoming holidays
        for holiday in entry.upcomingHolidays {
            items.append(UpcomingItem(
                name: holiday.displayName,
                date: holiday.date,
                symbol: holiday.isBankHoliday ? "star.fill" : "sparkles",
                color: JohoWidget.Colors.holiday,
                isBankHoliday: holiday.isBankHoliday,
                isBirthday: false
            ))
        }

        // Add upcoming birthdays from week
        for (date, birthdays) in entry.weekBirthdays {
            for birthday in birthdays {
                if date > calendar.startOfDay(for: entry.date) {
                    items.append(UpcomingItem(
                        name: birthday.displayName,
                        date: date,
                        symbol: "gift.fill",
                        color: JohoWidget.Colors.contact,
                        isBankHoliday: false,
                        isBirthday: true
                    ))
                }
            }
        }

        // Sort by date and limit to 4
        return items.sorted { $0.date < $1.date }.prefix(4).map { $0 }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.height / 354
            let borderColor = JohoWidget.Colors.border(for: colorScheme)

            VStack(spacing: 0) {
                // Header bento card — colored zone + month label
                headerCard(scale: scale, borderColor: borderColor)
                    .padding(.horizontal, 8 * scale)
                    .padding(.top, 6 * scale)
                    .padding(.bottom, 6 * scale)

                // Divider
                Rectangle()
                    .fill(borderColor)
                    .frame(height: 1.5)
                    .padding(.horizontal, 12 * scale)

                // TODAY section (holiday with notes)
                if let today = todayItem {
                    todaySection(item: today, scale: scale)
                        .padding(.horizontal, 12 * scale)
                        .padding(.vertical, 8 * scale)

                    // Divider
                    Rectangle()
                        .fill(JohoWidget.Colors.border(for: colorScheme))
                        .frame(height: 1.5)
                        .padding(.horizontal, 12 * scale)
                }

                // UPCOMING header
                if !upcomingItems.isEmpty {
                    HStack {
                        Text("UPCOMING")
                            .font(.system(size: 10 * scale, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.textSecondary(for: colorScheme))
                            .tracking(1)
                        Spacer()
                    }
                    .padding(.horizontal, 14 * scale)
                    .padding(.top, 6 * scale)
                    .padding(.bottom, 4 * scale)
                }

                // Upcoming list
                VStack(spacing: 6 * scale) {
                    if upcomingItems.isEmpty && todayItem == nil {
                        emptyState(scale: scale)
                    } else {
                        ForEach(Array(upcomingItems.enumerated()), id: \.offset) { _, item in
                            upcomingRow(item: item, scale: scale)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12 * scale)
                .padding(.vertical, 4 * scale)

                // Divider
                Rectangle()
                    .fill(JohoWidget.Colors.border(for: colorScheme))
                    .frame(height: 1.5)
                    .padding(.horizontal, 12 * scale)

                // Bottom fact bar
                factBar(scale: scale)
                    .padding(.horizontal, 14 * scale)
                    .padding(.vertical, 10 * scale)
            }
        }
        .widgetURL(URL(string: "vecka://facts/\(fact.id)"))
        .containerBackground(for: .widget) {
            JohoWidget.Colors.content(for: colorScheme)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Header Card (Star Page Pattern: colored top + white bottom)

    private func headerCard(scale: CGFloat, borderColor: Color) -> some View {
        let cardRadius: CGFloat = 12 * scale
        let secondaryColor = JohoWidget.Colors.textSecondary(for: colorScheme)

        return VStack(spacing: 0) {
            // TOP: Colored zone with icon + TODAY
            HStack(alignment: .center, spacing: 8 * scale) {
                Image(systemName: monthTheme.icon)
                    .font(.system(size: 20 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(monthTheme.accentColor)

                Text("TODAY")
                    .font(.system(size: 13 * scale, weight: .black, design: .rounded))
                    .foregroundStyle(monthTheme.accentColor)
                    .tracking(1)

                Spacer()

                // Week badge
                Text("W\(entry.weekNumber)")
                    .font(.system(size: 11 * scale, weight: .black, design: .rounded))
                    .foregroundStyle(monthTheme.accentColor)
                    .padding(.horizontal, 6 * scale)
                    .padding(.vertical, 3 * scale)
                    .background(monthTheme.accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 5 * scale, style: .continuous))
            }
            .padding(.horizontal, 10 * scale)
            .padding(.vertical, 8 * scale)
            .frame(maxWidth: .infinity)
            .background(monthTheme.lightBackground)

            // Divider
            Rectangle()
                .fill(borderColor)
                .frame(height: 1)

            // BOTTOM: White zone with date info
            HStack(spacing: 6 * scale) {
                Text("\(dayOfMonth)")
                    .font(.system(size: 20 * scale, weight: .black, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))

                Text("\(weekdayFull) \(monthShort) \(yearString)")
                    .font(.system(size: 9 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(secondaryColor)
                    .tracking(0.5)

                Spacer()
            }
            .padding(.horizontal, 10 * scale)
            .padding(.vertical, 6 * scale)
            .background(JohoWidget.Colors.content(for: colorScheme))
        }
        .clipShape(WidgetSquircle(cornerRadius: cardRadius))
        .overlay(
            WidgetSquircle(cornerRadius: cardRadius)
                .stroke(borderColor, lineWidth: 1.5)
        )
    }

    // MARK: - Today Section

    private func todaySection(item: TodayDisplayItem, scale: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 8 * scale) {
            // Symbol
            Image(systemName: item.symbol)
                .font(.system(size: 18 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))
                .frame(width: 24 * scale)

            // Name + Notes
            VStack(alignment: .leading, spacing: 4 * scale) {
                Text(item.name)
                    .font(.system(size: 14 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))
                    .lineLimit(1)

                if let notes = item.notes {
                    Text(notes)
                        .font(.system(size: 11 * scale, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.textSecondary(for: colorScheme))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Upcoming Row

    private func upcomingRow(item: UpcomingItem, scale: CGFloat) -> some View {
        HStack(spacing: 8 * scale) {
            // Symbol
            Image(systemName: item.symbol)
                .font(.system(size: 18 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))
                .frame(width: 20 * scale)

            // Name
            Text(item.name)
                .font(.system(size: 13 * scale, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            // Date
            VStack(alignment: .trailing, spacing: 0) {
                Text(item.date.formatted(.dateTime.weekday(.abbreviated).locale(.autoupdatingCurrent)).uppercased())
                    .font(.system(size: 10 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.textSecondary(for: colorScheme))

                Text(item.date.formatted(.dateTime.month(.abbreviated).day().locale(.autoupdatingCurrent)).uppercased())
                    .font(.system(size: 11 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))
            }
        }
        .padding(.horizontal, 10 * scale)
        .padding(.vertical, 8 * scale)
        .background(JohoWidget.Colors.content(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 10 * scale, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                .stroke(JohoWidget.Colors.border(for: colorScheme), lineWidth: 2)
        )
    }

    // MARK: - Empty State

    private func emptyState(scale: CGFloat) -> some View {
        VStack(spacing: 8 * scale) {
            Image(systemName: JohoWidget.Symbols.calendarBadgeCheckmark)
                .font(.system(size: 32 * scale, weight: .medium, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.textSecondary(for: colorScheme))

            Text("No upcoming specials")
                .font(.system(size: 13 * scale, weight: .medium, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40 * scale)
    }

    // MARK: - Fact Bar

    private func factBar(scale: CGFloat) -> some View {
        HStack(spacing: 8 * scale) {
            Text("TODAY")
                .font(.system(size: 10 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.textSecondary(for: colorScheme))
                .tracking(1)

            Rectangle()
                .fill(JohoWidget.Colors.border(for: colorScheme))
                .frame(width: 1, height: 14 * scale)

            Image(systemName: fact.symbol)
                .font(.system(size: 12 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))

            Text(fact.text)
                .font(.system(size: 11 * scale, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text(for: colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10 * scale)
        .padding(.vertical, 8 * scale)
        .background(JohoWidget.Colors.content(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 8 * scale, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                .stroke(JohoWidget.Colors.border(for: colorScheme), lineWidth: 2)
        )
    }

    private var accessibilityLabel: String {
        var label = "Week \(entry.weekNumber)"
        if let today = todayItem {
            label += ", Today: \(today.name)"
        }
        if !upcomingItems.isEmpty {
            label += ", Upcoming: \(upcomingItems.prefix(3).map(\.name).joined(separator: ", "))"
        }
        return label
    }
}

// MARK: - Models

private struct TodayDisplayItem {
    let name: String
    let symbol: String
    let notes: String?
    let isBankHoliday: Bool
}

private struct UpcomingItem {
    let name: String
    let date: Date
    let symbol: String
    let color: Color
    let isBankHoliday: Bool
    let isBirthday: Bool
}
