//
//  SmallWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Small Widget
//  Two-zone horizontal bento: Week Hero | Today Info
//  Philosophy: Maximum clarity in minimum space
//

import SwiftUI
import WidgetKit

struct VeckaSmallWidgetView: View {
    let entry: VeckaWidgetEntry
    private let family: WidgetFamily = .systemSmall

    // MARK: - Computed Properties

    private var weekNumber: Int { entry.weekNumber }

    private var dayOfMonth: Int {
        Calendar.current.component(.day, from: entry.date)
    }

    private var weekdayShort: String {
        entry.date.formatted(.dateTime.weekday(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var monthShort: String {
        entry.date.formatted(.dateTime.month(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var isRedDay: Bool {
        entry.todaysHolidays.first?.isRedDay ?? false
    }

    private var isSunday: Bool {
        Calendar.current.component(.weekday, from: entry.date) == 1
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(entry.date)
    }

    // MARK: - Sizing

    private var borders: JohoWidget.Borders.Weights {
        JohoWidget.Borders.weights(for: family)
    }

    private var corners: JohoWidget.Corners.Radii {
        JohoWidget.Corners.radii(for: family)
    }

    private var spacing: JohoWidget.Spacing.Grid {
        JohoWidget.Spacing.grid(for: family)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // ═══════════════════════════════════════════════
            // MAIN BENTO: Two horizontal compartments
            // ═══════════════════════════════════════════════
            HStack(spacing: 0) {
                // LEFT COMPARTMENT: Week Number (Hero)
                weekHeroCompartment

                // VERTICAL WALL
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(width: borders.container)

                // RIGHT COMPARTMENT: Today Info
                todayInfoCompartment
            }
            .frame(maxHeight: .infinity)

            // ═══════════════════════════════════════════════
            // FOOTER: Holiday or Status Badge
            // ═══════════════════════════════════════════════
            if entry.todaysHolidays.first != nil || isToday {
                // HORIZONTAL WALL
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(height: borders.row)

                footerCompartment
            }
        }
        .widgetURL(URL(string: "vecka://week/\(weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            RoundedRectangle(cornerRadius: corners.widget, style: .continuous)
                .fill(JohoWidget.Colors.content)
                .overlay(
                    RoundedRectangle(cornerRadius: corners.widget, style: .continuous)
                        .stroke(JohoWidget.Colors.border, lineWidth: borders.widget)
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week \(weekNumber), \(monthShort) \(dayOfMonth), \(weekdayShort)")
    }

    // MARK: - Week Hero Compartment (Left)

    private var weekHeroCompartment: some View {
        VStack(spacing: 2) {
            // Week number (BIG HERO)
            Text("\(weekNumber)")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .minimumScaleFactor(0.7)

            // Week label
            Text("WEEK")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JohoWidget.Colors.content)
    }

    // MARK: - Today Info Compartment (Right)

    private var todayInfoCompartment: some View {
        VStack(spacing: 4) {
            // Weekday (context)
            Text(weekdayShort)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))

            // Day number (secondary hero)
            Text("\(dayOfMonth)")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(dayColor)
                .minimumScaleFactor(0.8)

            // Month
            Text(monthShort)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(centerBackground)
    }

    // MARK: - Footer Compartment

    private var footerCompartment: some View {
        Group {
            if let holiday = entry.todaysHolidays.first {
                // Holiday indicator
                HStack(spacing: 5) {
                    Circle()
                        .fill(holiday.isRedDay ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                        .frame(width: 7, height: 7)
                        .overlay(Circle().stroke(JohoWidget.Colors.border, lineWidth: 0.5))

                    Text(holiday.displayName)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
            } else if isToday {
                // TODAY badge
                HStack {
                    Text("TODAY")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(JohoWidget.Colors.now)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(JohoWidget.Colors.border, lineWidth: 0.5)
                        )
                    Spacer()
                }
            }
        }
        .padding(.horizontal, spacing.md)
        .padding(.vertical, spacing.sm)
        .frame(maxWidth: .infinity)
        .frame(height: 24)
        .background(JohoWidget.Colors.content)
    }

    // MARK: - Styling

    private var dayColor: Color {
        if isRedDay { return JohoWidget.Colors.alert }
        if isSunday { return JohoWidget.Colors.alert.opacity(0.9) }
        return JohoWidget.Colors.text
    }

    private var centerBackground: Color {
        if isRedDay { return JohoWidget.Colors.holiday.opacity(0.15) }
        if isSunday { return JohoWidget.Colors.sunday.opacity(0.08) }
        return JohoWidget.Colors.content
    }
}
