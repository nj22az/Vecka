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
        VStack(spacing: 0) {
            // Header: Month + Year (情報デザイン: complete information, readable)
            Text("\(monthShort) \(year)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.7))
                .tracking(1)
                .padding(.top, 8)

            Spacer(minLength: 4)

            // HERO: Week Number (the ONE thing)
            Text("\(weekNumber)")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .minimumScaleFactor(0.5)

            // Label (情報デザイン: readable, not invisible)
            Text("WEEK")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
                .tracking(2)

            Spacer(minLength: 4)

            // Footer: Today in YELLOW CIRCLE (情報デザイン: TODAY = NOW = YELLOW)
            HStack(spacing: 4) {
                // Today indicator: ALWAYS yellow circle with black border
                ZStack {
                    Circle()
                        .fill(JohoWidget.Colors.now)
                        .frame(width: 32, height: 32)
                    Circle()
                        .stroke(JohoWidget.Colors.border, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                    Text("\(dayOfMonth)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)
                }

                Text(weekdayShort)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(sundayOrHolidayColor)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "vecka://week/\(weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            // 情報デザイン: Strong 2pt black border (per Theme.Borders.small.widget)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(JohoWidget.Colors.content)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(JohoWidget.Colors.border, lineWidth: 2)
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
