//
//  SmallWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Small Widget
//  LINE/Kakao-inspired mascot design with week number
//  Cute character + functional information
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

    /// Simulate blinking by checking if minute is divisible by 7 (random-ish)
    /// This creates variety across timeline updates
    private var isBlinking: Bool {
        let minute = Calendar.current.component(.minute, from: entry.date)
        return minute % 7 == 0
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let metrics = SmallWidgetMetrics(size: geo.size)

            VStack(spacing: metrics.spacing) {
                // Month + Year header
                Text("\(monthShort) \(year)")
                    .font(.system(size: metrics.headerSize, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.textSecondary)
                    .tracking(1)

                Spacer(minLength: 0)

                // 情報デザイン + LINE/Kakao: Mascot with week number
                JohoWidget.WidgetMascot(
                    size: metrics.mascotSize,
                    weekNumber: weekNumber,
                    isBlinking: isBlinking,
                    accentColor: JohoWidget.Colors.now
                )

                Spacer(minLength: 0)

                // Today indicator row
                HStack(spacing: metrics.spacing) {
                    Text(weekdayShort)
                        .font(.system(size: metrics.weekdaySize, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.textSecondary)

                    // Today badge (情報デザイン: Yellow + border)
                    ZStack {
                        Circle()
                            .fill(JohoWidget.Colors.now)
                        Circle()
                            .stroke(JohoWidget.Colors.border, lineWidth: metrics.borderWidth)
                        Text("\(dayOfMonth)")
                            .font(.system(size: metrics.daySize, weight: .black, design: .rounded))
                            .foregroundStyle(JohoWidget.Colors.text)
                    }
                    .frame(width: metrics.todayCircleSize, height: metrics.todayCircleSize)
                }
            }
            .padding(metrics.padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .widgetURL(URL(string: "vecka://week/\(weekNumber)/\(entry.year)"))
        .containerBackground(for: .widget) {
            JohoWidget.Colors.content
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week \(weekNumber), \(weekdayShort) \(dayOfMonth)")
    }
}

// MARK: - Adaptive Metrics

/// Calculates adaptive sizes based on widget dimensions
/// iPhone small widget: ~158 x 158 pt
/// iPad small widget: ~170 x 170 pt to ~200 x 200 pt
private struct SmallWidgetMetrics {
    let size: CGSize

    /// Scale factor based on widget size (baseline: 155pt for iPhone)
    var scale: CGFloat {
        let baseline: CGFloat = 155
        let minDimension = min(size.width, size.height)
        return max(1.0, minDimension / baseline)
    }

    // Typography (scaled)
    var headerSize: CGFloat { 10 * scale }
    var weekdaySize: CGFloat { 11 * scale }
    var daySize: CGFloat { 13 * scale }

    // Layout (scaled)
    var mascotSize: CGFloat { 80 * scale }
    var todayCircleSize: CGFloat { 26 * scale }
    var spacing: CGFloat { 6 * scale }
    var padding: CGFloat { 10 * scale }
    var borderWidth: CGFloat { scale > 1.1 ? 2 : 1.5 }
}
