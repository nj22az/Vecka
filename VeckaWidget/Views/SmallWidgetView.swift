//
//  SmallWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Small Widget
//  Clean, minimal week number display - no decorative elements
//

import SwiftUI
import WidgetKit

struct VeckaSmallWidgetView: View {
    let entry: VeckaWidgetEntry

    // MARK: - Computed Properties

    private var weekNumber: Int { entry.weekNumber }
    private var dayOfMonth: Int { Calendar.current.component(.day, from: entry.date) }

    private var weekdayShort: String {
        entry.date.formatted(.dateTime.weekday(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var monthShort: String {
        entry.date.formatted(.dateTime.month(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var year: String { String(entry.year) }

    // 情報デザイン: Theme tokens
    private var borders: JohoWidget.Borders.Weights { JohoWidget.Borders.small }
    private var typo: JohoWidget.Typography.Scale { JohoWidget.Typography.small }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            Spacer()

            // 情報デザイン: Week number hero (centered, prominent)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("W")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    // 情報デザイン: Secondary text color, no opacity
                    .foregroundStyle(JohoWidget.Colors.textSecondary)
                Text("\(weekNumber)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text)
            }

            // 情報デザイン: Today indicator - Yellow circle with black border
            HStack(spacing: 6) {
                Text(weekdayShort)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    // 情報デザイン: Secondary text color, no opacity
                    .foregroundStyle(JohoWidget.Colors.textSecondary)

                ZStack {
                    Circle()
                        .fill(JohoWidget.Colors.now)
                    Circle()
                        .stroke(JohoWidget.Colors.border, lineWidth: borders.selected)
                    Text("\(dayOfMonth)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)
                }
                .frame(width: 28, height: 28)
            }

            // Month + Year
            Text("\(monthShort) \(year)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                // 情報デザイン: Secondary text color, no opacity
                .foregroundStyle(JohoWidget.Colors.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "vecka://week/\(weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            JohoWidget.Colors.content
        }
    }
}
