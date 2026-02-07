//
//  MediumWidgetView.swift
//  VeckaWidget
//
//  Medium Widget: This week's specials
//  Today section + upcoming specials this week
//  Falls back to showing next upcoming special if week is empty
//

import SwiftUI
import WidgetKit

struct VeckaMediumWidgetView: View {
    let entry: VeckaWidgetEntry

    // MARK: - Calendar

    private var calendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        cal.locale = .autoupdatingCurrent
        return cal
    }

    // MARK: - Computed Properties

    private var monthShort: String {
        entry.date.formatted(.dateTime.month(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var hasSpecialToday: Bool {
        !entry.todaysHolidays.isEmpty || !entry.todaysBirthdays.isEmpty
    }

    private var todayDisplay: SpecialItem? {
        if let holiday = entry.todaysHolidays.first {
            return SpecialItem(
                name: holiday.displayName,
                symbol: holiday.isBankHoliday ? "star.fill" : "sparkles",
                color: JohoWidget.Colors.holiday,
                weekday: entry.date.formatted(.dateTime.weekday(.abbreviated).locale(.autoupdatingCurrent)).uppercased(),
                isBankHoliday: holiday.isBankHoliday
            )
        }
        if let birthday = entry.todaysBirthdays.first {
            return SpecialItem(
                name: birthday.displayName,
                symbol: "gift.fill",
                color: JohoWidget.Colors.contact,
                weekday: entry.date.formatted(.dateTime.weekday(.abbreviated).locale(.autoupdatingCurrent)).uppercased(),
                isBankHoliday: false
            )
        }
        return nil
    }

    private var fact: WidgetFacts.Fact {
        WidgetFacts.randomFact(for: entry.date)
    }

    /// Get this week's upcoming specials (excluding today)
    private var thisWeekSpecials: [SpecialItem] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: entry.date) else {
            return []
        }

        var items: [SpecialItem] = []
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: entry.date)) ?? entry.date

        // Check upcoming holidays this week
        for holiday in entry.upcomingHolidays {
            guard holiday.date >= tomorrow && holiday.date < weekInterval.end else { continue }
            items.append(SpecialItem(
                name: holiday.displayName,
                symbol: holiday.isBankHoliday ? "star.fill" : "sparkles",
                color: JohoWidget.Colors.holiday,
                weekday: holiday.date.formatted(.dateTime.weekday(.abbreviated).locale(.autoupdatingCurrent)).uppercased(),
                isBankHoliday: holiday.isBankHoliday
            ))
        }

        // Check week birthdays
        for (date, birthdays) in entry.weekBirthdays where date >= tomorrow && date < weekInterval.end {
            for birthday in birthdays {
                items.append(SpecialItem(
                    name: birthday.displayName,
                    symbol: "gift.fill",
                    color: JohoWidget.Colors.contact,
                    weekday: date.formatted(.dateTime.weekday(.abbreviated).locale(.autoupdatingCurrent)).uppercased(),
                    isBankHoliday: false
                ))
            }
        }

        return Array(items.prefix(2))  // Max 2 items
    }

    /// Get upcoming specials beyond this week (for "Coming Up" section)
    private var upcomingSpecials: [SpecialItem] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: entry.date) else {
            return []
        }

        var items: [SpecialItem] = []

        for holiday in entry.upcomingHolidays where holiday.date >= weekInterval.end {
            items.append(SpecialItem(
                name: holiday.displayName,
                symbol: holiday.isBankHoliday ? "star.fill" : "sparkles",
                color: JohoWidget.Colors.holiday,
                dateString: holiday.date.formatted(.dateTime.month(.abbreviated).day().locale(.autoupdatingCurrent)).uppercased(),
                isBankHoliday: holiday.isBankHoliday
            ))
        }

        return Array(items.prefix(2))  // Max 2 items
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.height / 155

            HStack(spacing: 0) {
                // Left column: Today
                todayColumn(scale: scale)
                    .frame(width: geo.size.width * 0.45)

                // Divider
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(width: 1.5)

                // Right column: This week / Coming up
                weekColumn(scale: scale)
                    .frame(maxWidth: .infinity)
            }
        }
        .widgetURL(URL(string: "vecka://today"))
        .containerBackground(for: .widget) {
            JohoWidget.Colors.content
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Today Column

    private func todayColumn(scale: CGFloat) -> some View {
        VStack(spacing: 4 * scale) {
            // Header
            HStack {
                Text("TODAY")
                    .font(.system(size: 10 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.textSecondary)
                    .tracking(1)
                Spacer()
                Text("W\(entry.weekNumber)")
                    .font(.system(size: 9 * scale, weight: .black, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text)
                    .padding(.horizontal, 6 * scale)
                    .padding(.vertical, 2 * scale)
                    .background(JohoWidget.Colors.now)
                    .clipShape(RoundedRectangle(cornerRadius: 4 * scale, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)
                            .stroke(JohoWidget.Colors.border, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 10 * scale)
            .padding(.top, 8 * scale)

            Spacer(minLength: 0)

            // Today content
            if let today = todayDisplay {
                specialRow(item: today, scale: scale, showBackground: true)
                    .padding(.horizontal, 8 * scale)
            } else {
                // Show fact
                factRow(scale: scale)
                    .padding(.horizontal, 8 * scale)
            }

            Spacer(minLength: 0)

            // Date display
            Text(entry.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().locale(.autoupdatingCurrent)))
                .font(.system(size: 10 * scale, weight: .medium, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.textSecondary)
                .padding(.bottom, 8 * scale)
        }
    }

    // MARK: - Week Column

    private func weekColumn(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4 * scale) {
            // Header
            HStack {
                Text(thisWeekSpecials.isEmpty ? "COMING UP" : "THIS WEEK")
                    .font(.system(size: 10 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.textSecondary)
                    .tracking(1)
                Spacer()
            }
            .padding(.horizontal, 10 * scale)
            .padding(.top, 8 * scale)

            Spacer(minLength: 0)

            // Week specials or upcoming
            let items = thisWeekSpecials.isEmpty ? upcomingSpecials : thisWeekSpecials
            if items.isEmpty {
                // No specials - show a message
                Text("No specials this week")
                    .font(.system(size: 11 * scale, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 6 * scale) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        specialRow(item: item, scale: scale, showBackground: false)
                    }
                }
                .padding(.horizontal, 8 * scale)
            }

            Spacer(minLength: 0)

            // Month indicator
            Text(monthShort)
                .font(.system(size: 10 * scale, weight: .medium, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.textSecondary)
                .padding(.horizontal, 10 * scale)
                .padding(.bottom, 8 * scale)
        }
    }

    // MARK: - Row Components

    private func specialRow(item: SpecialItem, scale: CGFloat, showBackground: Bool) -> some View {
        HStack(spacing: 6 * scale) {
            Image(systemName: item.symbol)
                .font(.system(size: 12 * scale, weight: .bold))
                .foregroundStyle(item.isBankHoliday ? JohoWidget.Colors.alert : JohoWidget.Colors.text)

            Text(item.name)
                .font(.system(size: 11 * scale, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            Text(item.weekday ?? item.dateString ?? "")
                .font(.system(size: 10 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.textSecondary)
        }
        .padding(.horizontal, 8 * scale)
        .padding(.vertical, 6 * scale)
        .background(showBackground ? item.color : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8 * scale, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: showBackground ? 1.5 : 1)
        )
    }

    private func factRow(scale: CGFloat) -> some View {
        let factColor: Color = {
            switch fact.type {
            case .dateBased: return JohoWidget.Colors.event
            case .nordic: return JohoWidget.Colors.now
            case .trivia: return JohoWidget.Colors.event
            }
        }()

        return HStack(spacing: 6 * scale) {
            Image(systemName: fact.symbol)
                .font(.system(size: 12 * scale, weight: .bold))
                .foregroundStyle(JohoWidget.Colors.text)

            Text(fact.text)
                .font(.system(size: 11 * scale, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8 * scale)
        .padding(.vertical, 6 * scale)
        .background(factColor)
        .clipShape(RoundedRectangle(cornerRadius: 8 * scale, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: 1.5)
        )
    }

    private var accessibilityLabel: String {
        var label = "Week \(entry.weekNumber)"
        if let today = todayDisplay {
            label += ", Today: \(today.name)"
        }
        if !thisWeekSpecials.isEmpty {
            label += ", This week: \(thisWeekSpecials.map(\.name).joined(separator: ", "))"
        }
        return label
    }
}

// MARK: - Special Item Model

private struct SpecialItem {
    let name: String
    let symbol: String
    let color: Color
    var weekday: String? = nil
    var dateString: String? = nil
    let isBankHoliday: Bool
}
