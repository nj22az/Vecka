//
//  SmallWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Small Widget
//  Clean, bold, high-contrast Japanese information design
//

import SwiftUI
import WidgetKit

struct VeckaSmallWidgetView: View {
    let entry: VeckaWidgetEntry

    private var dayOfMonth: String {
        "\(Calendar.current.component(.day, from: entry.date))"
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

    var body: some View {
        VStack(spacing: 0) {
            // TOP: Month + Week Badge
            HStack(alignment: .center) {
                Text(monthShort)
                    .font(JohoWidgetFont.labelBold)
                    .foregroundStyle(JohoWidgetColors.black.opacity(0.7))

                Spacer()

                JohoWeekBadge(weekNumber: entry.weekNumber, size: .small)
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.top, JohoDimensions.spacingLG)

            Spacer()

            // CENTER: Big Day Number
            VStack(spacing: 2) {
                Text(dayOfMonth)
                    .font(JohoWidgetFont.displayHuge)
                    .foregroundStyle(dayColor)
                    .minimumScaleFactor(0.7)

                Text(weekdayShort)
                    .font(JohoWidgetFont.headerMedium)
                    .foregroundStyle(JohoWidgetColors.black.opacity(0.6))
            }

            Spacer()

            // BOTTOM: Holiday indicator (if any)
            if let holiday = entry.todaysHolidays.first {
                JohoHolidayPill(name: holiday.displayName, isRedDay: holiday.isRedDay)
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.bottom, JohoDimensions.spacingLG)
            } else {
                Spacer().frame(height: JohoDimensions.spacingLG)
            }
        }
        .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            // 情報デザイン: WHITE background with BLACK border
            ZStack {
                RoundedRectangle(cornerRadius: JohoDimensions.radiusLarge, style: .continuous)
                    .fill(JohoWidgetColors.white)
                RoundedRectangle(cornerRadius: JohoDimensions.radiusLarge, style: .continuous)
                    .stroke(JohoWidgetColors.black, lineWidth: JohoDimensions.borderBold)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var dayColor: Color {
        if isRedDay { return JohoWidgetColors.pink }
        if isSunday { return JohoWidgetColors.sundayBlue }
        return JohoWidgetColors.black
    }

    private var accessibilityLabel: String {
        var label = "\(weekdayShort), \(monthShort) \(dayOfMonth), Week \(entry.weekNumber)"
        if let holiday = entry.todaysHolidays.first {
            label += ", \(holiday.displayName)"
        }
        return label
    }
}
