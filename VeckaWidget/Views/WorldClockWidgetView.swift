//
//  WorldClockWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Random Fact Widget
//  Bento compartmentalized layout with daily random fact
//  ADAPTIVE: Scales properly for iPhone and iPad widget sizes
//

import SwiftUI
import WidgetKit

/// Medium widget showing random fact (情報デザイン style - bento layout)
/// ADAPTIVE: Uses FactWidgetMetrics for proportional scaling on iPad
struct WorldClockMediumWidgetView: View {
    let entry: VeckaWidgetEntry

    // Get fact based on current date (changes daily)
    private var randomFact: WidgetRandomFact {
        WidgetRandomFact.factForDate(entry.date)
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = FactWidgetMetrics(size: geo.size)

            HStack(spacing: 0) {
                // LEFT: Week number compartment
                weekNumberSection(metrics: metrics)
                    .frame(width: geo.size.width * 0.22)

                // 情報デザイン: Bento wall (container weight)
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(width: metrics.borderContainer)

                // RIGHT: Random fact section
                randomFactSection(metrics: metrics)
                    .frame(maxWidth: .infinity)
            }
        }
        .widgetURL(URL(string: "vecka://facts/\(randomFact.id)"))
        .containerBackground(for: .widget) {
            JohoWidget.Colors.content
        }
    }

    // MARK: - Week Number Section

    private func weekNumberSection(metrics: FactWidgetMetrics) -> some View {
        VStack(spacing: metrics.spacing * 0.5) {
            // Month + Year
            Text(entry.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                .font(.system(size: metrics.labelSize, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))

            Text(String(entry.year))
                .font(.system(size: metrics.smallLabelSize, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))

            Spacer(minLength: metrics.spacing * 0.5)

            // Week number hero
            Text("\(entry.weekNumber)")
                .font(.system(size: metrics.weekNumberSize, weight: .black, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .minimumScaleFactor(0.7)

            Text("WEEK")
                .font(.system(size: metrics.smallLabelSize, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))

            Spacer(minLength: metrics.spacing * 0.5)

            // Today indicator
            ZStack {
                Circle()
                    .fill(JohoWidget.Colors.now)
                Circle()
                    .stroke(JohoWidget.Colors.border, lineWidth: metrics.borderRow)
                Text("\(entry.dayNumber)")
                    .font(.system(size: metrics.dayNumberSize, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text)
            }
            .frame(width: metrics.todayCircleSize, height: metrics.todayCircleSize)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, metrics.padding)
    }

    // MARK: - Random Fact Section (情報デザイン: Bento compartments)

    private func randomFactSection(metrics: FactWidgetMetrics) -> some View {
        VStack(spacing: 0) {
            // TOP: Header row with source
            HStack(spacing: 0) {
                // Icon compartment
                ZStack {
                    RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                        .fill(randomFact.color.opacity(0.2))
                    Image(systemName: randomFact.icon)
                        .font(.system(size: metrics.iconSize, weight: .bold))
                        .foregroundStyle(randomFact.color)
                }
                .frame(width: metrics.iconBoxSize, height: metrics.iconBoxSize)
                .overlay(
                    RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                        .stroke(JohoWidget.Colors.border, lineWidth: metrics.borderCell)
                )
                .padding(metrics.padding)

                // Bento wall
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(width: metrics.borderCell)

                // Source label
                VStack(alignment: .leading, spacing: 2) {
                    Text("RANDOM FACT")
                        .font(.system(size: metrics.smallLabelSize, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
                        .tracking(0.5)

                    Text(randomFact.source.uppercased())
                        .font(.system(size: metrics.sourceLabelSize, weight: .black, design: .rounded))
                        .foregroundStyle(randomFact.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, metrics.padding)
            }
            .frame(height: metrics.headerHeight)

            // 情報デザイン: Horizontal bento wall
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(height: metrics.borderRow)

            // BOTTOM: Fact text
            Text(randomFact.text)
                .font(.system(size: metrics.factTextSize, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(metrics.padding)
        }
    }
}

// MARK: - Adaptive Metrics for Random Fact Widget

/// Calculates adaptive sizes based on widget dimensions
/// iPhone medium widget: ~329 x 155 pt
/// iPad medium widget: ~348 x 159 pt (small iPad) to ~412 x 188 pt (large iPad)
private struct FactWidgetMetrics {
    let size: CGSize

    /// Scale factor based on widget height (baseline: 155pt for iPhone)
    private var scale: CGFloat {
        let baselineHeight: CGFloat = 155
        return max(1.0, size.height / baselineHeight)
    }

    /// True if this appears to be iPad-sized
    var isLarge: Bool {
        size.height > 170 || size.width > 380
    }

    // MARK: - Typography (scaled)

    var weekNumberSize: CGFloat {
        let base: CGFloat = 32
        return base * scale
    }

    var labelSize: CGFloat {
        let base: CGFloat = 10
        return max(10, base * scale)
    }

    var smallLabelSize: CGFloat {
        let base: CGFloat = 9
        return max(9, base * scale)
    }

    var dayNumberSize: CGFloat {
        let base: CGFloat = 14
        return base * scale
    }

    var iconSize: CGFloat {
        let base: CGFloat = 20
        return base * scale
    }

    var sourceLabelSize: CGFloat {
        let base: CGFloat = 11
        return max(11, base * scale)
    }

    var factTextSize: CGFloat {
        let base: CGFloat = 15
        return base * scale
    }

    // MARK: - Layout (scaled)

    var todayCircleSize: CGFloat {
        let base: CGFloat = 28
        return base * scale
    }

    var iconBoxSize: CGFloat {
        let base: CGFloat = 44
        return base * scale
    }

    var headerHeight: CGFloat {
        let base: CGFloat = 60
        return base * scale
    }

    var padding: CGFloat {
        let base: CGFloat = 8
        return base * scale
    }

    var spacing: CGFloat {
        let base: CGFloat = 8
        return base * scale
    }

    var cornerRadius: CGFloat {
        let base: CGFloat = 8
        return base * scale
    }

    // MARK: - Borders (scaled for iPad)

    var borderContainer: CGFloat {
        isLarge ? 3.5 : 3
    }

    var borderRow: CGFloat {
        isLarge ? 2 : 1.5
    }

    var borderCell: CGFloat {
        isLarge ? 1.5 : 1
    }
}

// MARK: - Preview

#Preview("World Clock Widget", as: .systemMedium) {
    VeckaWidget()
} timeline: {
    VeckaWidgetEntry.preview
}
