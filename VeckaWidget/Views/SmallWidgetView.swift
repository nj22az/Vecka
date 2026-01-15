//
//  SmallWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Small Widget
//  Hokusai Great Wave motif - authentic Japanese aesthetic
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

    // 情報デザイン: Use theme constants for consistency
    private var borders: JohoWidget.Borders.Weights { JohoWidget.Borders.small }
    private var typo: JohoWidget.Typography.Scale { JohoWidget.Typography.small }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background: Hokusai wave in bottom-left corner
            VStack {
                Spacer()
                HStack {
                    Image("HokusaiWave")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 110, height: 73)
                        .opacity(0.9)
                    Spacer()
                }
            }

            // Content: Information in upper-right area
            VStack(alignment: .trailing, spacing: 2) {
                // Week number - hero (情報デザイン: typo.weekNumber = 48pt for small)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("W")
                        .font(.system(size: typo.headline, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
                    Text("\(weekNumber)")
                        .font(.system(size: typo.weekNumber, weight: .black, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text)
                }

                // Date row
                HStack(spacing: 4) {
                    Text(weekdayShort)
                        .font(.system(size: typo.headline, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))

                    // 情報デザイン: Today indicator with semantic NOW color + BLACK border
                    ZStack {
                        Circle()
                            .fill(JohoWidget.Colors.now)
                            .frame(width: 28, height: 28)
                        Circle()
                            .stroke(JohoWidget.Colors.border, lineWidth: borders.selected)
                            .frame(width: 28, height: 28)
                        Text("\(dayOfMonth)")
                            .font(.system(size: typo.body, weight: .black, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text)
                    }
                }

                // Month + Year
                Text("\(monthShort) \(year)")
                    .font(.system(size: typo.body, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))

                Spacer()
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .widgetURL(URL(string: "vecka://week/\(weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            JohoWidget.Colors.content
        }
    }
}
