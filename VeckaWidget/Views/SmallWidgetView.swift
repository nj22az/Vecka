//
//  SmallWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Small Widget
//  Japanese Minimalist: ONE hero element, breathing room
//  Inspired by Animal Crossing & LINE widget simplicity
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

    private var year: String {
        String(entry.year)
    }

    private var isBankHoliday: Bool {
        entry.todaysHolidays.first?.isBankHoliday ?? false
    }

    private var isSunday: Bool {
        Calendar.current.component(.weekday, from: entry.date) == 1
    }

    // MARK: - Body

    var body: some View {
        // 情報デザイン: Use Theme constants for consistency
        let typo = JohoWidget.Typography.small
        let borders = JohoWidget.Borders.small
        let corners = JohoWidget.Corners.small

        VStack(spacing: 0) {
            // Header: Month + Year (情報デザイン: complete information, readable)
            Text("\(monthShort) \(year)")
                .font(.system(size: typo.caption, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
                .tracking(1)
                .padding(.top, 8)

            Spacer(minLength: 4)

            // HERO: Week Number (情報デザイン: Theme.Typography.small.weekNumber = 48pt)
            Text("\(weekNumber)")
                .font(.system(size: typo.weekNumber, weight: .black, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .minimumScaleFactor(0.5)

            // Label (情報デザイン: readable, consistent opacity 0.6)
            Text("WEEK")
                .font(.system(size: typo.label, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
                .tracking(1)

            Spacer(minLength: 4)

            // Footer: Today in YELLOW CIRCLE (情報デザイン: TODAY = NOW = YELLOW)
            // Touch target: 44pt minimum per Apple HIG
            HStack(spacing: 6) {
                // Today indicator: 44pt circle for touch target compliance
                ZStack {
                    Circle()
                        .fill(JohoWidget.Colors.now)
                        .frame(width: 44, height: 44)
                    Circle()
                        .stroke(JohoWidget.Colors.border, lineWidth: borders.selected)
                        .frame(width: 44, height: 44)
                    Text("\(dayOfMonth)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)
                }

                Text(weekdayShort)
                    .font(.system(size: typo.headline, weight: .bold, design: .rounded))
                    .foregroundStyle(sundayOrHolidayColor)
            }
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "vecka://week/\(weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            // 情報デザイン: Theme.Borders.small.widget = 2pt
            RoundedRectangle(cornerRadius: corners.widget, style: .continuous)
                .fill(JohoWidget.Colors.content)
                .overlay(
                    RoundedRectangle(cornerRadius: corners.widget - 2, style: .continuous)
                        .stroke(JohoWidget.Colors.border, lineWidth: borders.widget)
                        .padding(1)
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week \(weekNumber), \(monthShort) \(dayOfMonth), \(weekdayShort), \(year)")
    }

    // MARK: - Styling

    private var sundayOrHolidayColor: Color {
        if isBankHoliday { return JohoWidget.Colors.alert }
        if isSunday { return JohoWidget.Colors.alert }
        return JohoWidget.Colors.text
    }
}
