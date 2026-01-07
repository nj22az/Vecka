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

    private var isBankHoliday: Bool {
        entry.todaysHolidays.first?.isBankHoliday ?? false
    }

    private var isSunday: Bool {
        Calendar.current.component(.weekday, from: entry.date) == 1
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            Spacer()

            // HERO: Week Number (the ONE thing)
            Text("\(weekNumber)")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .minimumScaleFactor(0.5)

            // Small label
            Text("WEEK")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
                .tracking(2)

            Spacer()

            // Footer: Date + Day (minimal)
            HStack(spacing: 6) {
                Text("\(dayOfMonth)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(dayColor)

                Text(weekdayShort)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "vecka://week/\(weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            // Simple white background with subtle border
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(JohoWidget.Colors.content)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(JohoWidget.Colors.border.opacity(0.2), lineWidth: 1)
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week \(weekNumber), \(monthShort) \(dayOfMonth), \(weekdayShort)")
    }

    // MARK: - Styling

    private var dayColor: Color {
        if isBankHoliday { return JohoWidget.Colors.alert }
        if isSunday { return JohoWidget.Colors.alert }
        return JohoWidget.Colors.text
    }
}
