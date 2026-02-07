//
//  LargeWidgetView.swift
//  VeckaWidget
//
//  Large Widget: Upcoming specials list
//  Shows next 5-7 holidays/birthdays with dates
//  Bottom bar shows daily fact
//

import SwiftUI
import WidgetKit

struct VeckaLargeWidgetView: View {
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

    private var yearString: String {
        String(calendar.component(.year, from: entry.date))
    }

    private var fact: WidgetFacts.Fact {
        WidgetFacts.randomFact(for: entry.date)
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

        // Add upcoming birthdays from week (we only have week data, but show what we have)
        for (date, birthdays) in entry.weekBirthdays {
            for birthday in birthdays {
                // Only add if it's in the future
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

        // Sort by date and limit
        return items.sorted { $0.date < $1.date }.prefix(6).map { $0 }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.height / 354

            VStack(spacing: 0) {
                // Header
                headerRow(scale: scale)
                    .padding(.horizontal, 14 * scale)
                    .padding(.top, 12 * scale)
                    .padding(.bottom, 8 * scale)

                // Divider
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(height: 1.5)
                    .padding(.horizontal, 12 * scale)

                // Upcoming list (no ScrollView - widgets must be static)
                VStack(spacing: 6 * scale) {
                    if upcomingItems.isEmpty {
                        emptyState(scale: scale)
                    } else {
                        ForEach(Array(upcomingItems.enumerated()), id: \.offset) { _, item in
                            upcomingRow(item: item, scale: scale)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12 * scale)
                .padding(.vertical, 8 * scale)

                // Divider
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(height: 1.5)
                    .padding(.horizontal, 12 * scale)

                // Bottom fact bar
                factBar(scale: scale)
                    .padding(.horizontal, 14 * scale)
                    .padding(.vertical, 10 * scale)
            }
        }
        .widgetURL(URL(string: "vecka://upcoming"))
        .containerBackground(for: .widget) {
            JohoWidget.Colors.content
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Header

    private func headerRow(scale: CGFloat) -> some View {
        HStack {
            Text("UPCOMING")
                .font(.system(size: 14 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .tracking(1)

            Spacer()

            // Week + Year badge
            HStack(spacing: 6 * scale) {
                Text("W\(entry.weekNumber)")
                    .font(.system(size: 11 * scale, weight: .black, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text)
                    .padding(.horizontal, 8 * scale)
                    .padding(.vertical, 4 * scale)
                    .background(JohoWidget.Colors.now)
                    .clipShape(RoundedRectangle(cornerRadius: 6 * scale, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                            .stroke(JohoWidget.Colors.border, lineWidth: 1.5)
                    )

                Text(yearString)
                    .font(.system(size: 11 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.textSecondary)
            }
        }
    }

    // MARK: - Upcoming Row

    private func upcomingRow(item: UpcomingItem, scale: CGFloat) -> some View {
        HStack(spacing: 8 * scale) {
            // Color indicator stripe
            RoundedRectangle(cornerRadius: 2 * scale, style: .continuous)
                .fill(item.color)
                .frame(width: 4 * scale, height: 24 * scale)
                .overlay(
                    RoundedRectangle(cornerRadius: 2 * scale, style: .continuous)
                        .stroke(JohoWidget.Colors.border, lineWidth: 1)
                )

            // Symbol
            Image(systemName: item.symbol)
                .font(.system(size: 14 * scale, weight: .bold))
                .foregroundStyle(JohoWidget.Colors.text)
                .frame(width: 20 * scale)

            // Name
            Text(item.name)
                .font(.system(size: 13 * scale, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            // Date
            VStack(alignment: .trailing, spacing: 0) {
                Text(item.date.formatted(.dateTime.weekday(.abbreviated).locale(.autoupdatingCurrent)).uppercased())
                    .font(.system(size: 10 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.textSecondary)

                Text(item.date.formatted(.dateTime.month(.abbreviated).day().locale(.autoupdatingCurrent)).uppercased())
                    .font(.system(size: 11 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text)
            }
        }
        .padding(.horizontal, 10 * scale)
        .padding(.vertical, 8 * scale)
        .background(JohoWidget.Colors.content)
        .clipShape(RoundedRectangle(cornerRadius: 10 * scale, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: 2)
        )
    }

    // MARK: - Empty State

    private func emptyState(scale: CGFloat) -> some View {
        VStack(spacing: 8 * scale) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 32 * scale, weight: .medium))
                .foregroundStyle(JohoWidget.Colors.textSecondary)

            Text("No upcoming specials")
                .font(.system(size: 13 * scale, weight: .medium, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40 * scale)
    }

    // MARK: - Fact Bar

    private func factBar(scale: CGFloat) -> some View {
        let factColor: Color = {
            switch fact.type {
            case .dateBased: return JohoWidget.Colors.event
            case .nordic: return JohoWidget.Colors.now
            case .trivia: return JohoWidget.Colors.event
            }
        }()

        return HStack(spacing: 8 * scale) {
            // Color indicator stripe
            RoundedRectangle(cornerRadius: 2 * scale, style: .continuous)
                .fill(factColor)
                .frame(width: 4 * scale, height: 20 * scale)
                .overlay(
                    RoundedRectangle(cornerRadius: 2 * scale, style: .continuous)
                        .stroke(JohoWidget.Colors.border, lineWidth: 1)
                )

            Text("TODAY")
                .font(.system(size: 10 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.textSecondary)
                .tracking(1)

            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(width: 1, height: 14 * scale)

            Image(systemName: fact.symbol)
                .font(.system(size: 12 * scale, weight: .bold))
                .foregroundStyle(JohoWidget.Colors.text)

            Text(fact.text)
                .font(.system(size: 11 * scale, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10 * scale)
        .padding(.vertical, 8 * scale)
        .background(JohoWidget.Colors.content)
        .clipShape(RoundedRectangle(cornerRadius: 8 * scale, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                .stroke(JohoWidget.Colors.border, lineWidth: 2)
        )
    }

    private var accessibilityLabel: String {
        var label = "Upcoming specials, Week \(entry.weekNumber)"
        if !upcomingItems.isEmpty {
            label += ": \(upcomingItems.prefix(3).map(\.name).joined(separator: ", "))"
        }
        return label
    }
}

// MARK: - Upcoming Item Model

private struct UpcomingItem {
    let name: String
    let date: Date
    let symbol: String
    let color: Color
    let isBankHoliday: Bool
    let isBirthday: Bool
}
