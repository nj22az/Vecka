//
//  SmallWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Small Widget
//  Exceptional: Clean, focused, one-glance information
//  Philosophy: "Every element serves a purpose - nothing decorative"
//

import SwiftUI
import WidgetKit

struct VeckaSmallWidgetView: View {
    let entry: VeckaWidgetEntry

    // MARK: - Computed Properties

    private var weekNumber: Int { entry.weekNumber }

    private var dayOfMonth: Int {
        Calendar.current.component(.day, from: entry.date)
    }

    private var weekdayShort: String {
        entry.date.formatted(.dateTime.weekday(.short).locale(.autoupdatingCurrent)).uppercased()
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

    private var hasHoliday: Bool {
        !entry.todaysHolidays.isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background - pure white content area
            JohoWidget.Colors.content

            VStack(spacing: 0) {
                // TOP: Month label (subtle context)
                Text(monthShort)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                Spacer(minLength: 0)

                // CENTER: Hero - Week Number (PRIMARY INFO)
                VStack(spacing: 4) {
                    Text("W\(weekNumber)")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)
                        .minimumScaleFactor(0.7)

                    // Day + Weekday (secondary info)
                    HStack(spacing: 6) {
                        Text("\(dayOfMonth)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(dayColor)

                        Text(weekdayShort)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
                    }
                }

                Spacer(minLength: 0)

                // BOTTOM: Holiday indicator (only if present)
                if let holiday = entry.todaysHolidays.first {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(holiday.isRedDay ? JohoWidget.Colors.alert : JohoWidget.Colors.event)
                            .frame(width: 8, height: 8)

                        Text(holiday.displayName)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text.opacity(0.7))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                } else {
                    // Empty space to maintain balance
                    Spacer().frame(height: 14)
                }
            }
        }
        .widgetURL(URL(string: "vecka://week/\(weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            // 情報デザイン: Clean white, thin black border
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(JohoWidget.Colors.content)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week \(weekNumber), \(monthShort) \(dayOfMonth), \(weekdayShort)")
    }

    // MARK: - Styling

    private var dayColor: Color {
        if isRedDay { return JohoWidget.Colors.alert }
        if isSunday { return JohoWidget.Colors.alert.opacity(0.8) }
        return JohoWidget.Colors.text
    }
}
