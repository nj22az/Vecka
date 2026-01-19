//
//  WorldClockWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Random Fact Widget
//  Bento compartmentalized layout with daily random fact
//

import SwiftUI
import WidgetKit

/// Medium widget showing random fact (情報デザイン style - bento layout)
struct WorldClockMediumWidgetView: View {
    let entry: VeckaWidgetEntry
    private let family: WidgetFamily = .systemMedium

    // 情報デザイン: Border weights
    private let borderContainer: CGFloat = 3
    private let borderRow: CGFloat = 1.5
    private let borderCell: CGFloat = 1

    // Get fact based on current date (changes daily)
    private var randomFact: WidgetRandomFact {
        WidgetRandomFact.factForDate(entry.date)
    }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // LEFT: Week number compartment
                weekNumberSection
                    .frame(width: geo.size.width * 0.22)

                // 情報デザイン: Bento wall (container weight)
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(width: borderContainer)

                // RIGHT: Random fact section
                randomFactSection
                    .frame(maxWidth: .infinity)
            }
        }
        .widgetURL(URL(string: "vecka://facts/\(randomFact.id)"))
        .containerBackground(for: .widget) {
            JohoWidget.Colors.content
        }
    }

    // MARK: - Week Number Section

    private var weekNumberSection: some View {
        VStack(spacing: 4) {
            // Month + Year
            Text(entry.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))

            Text(String(entry.year))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))

            Spacer(minLength: 4)

            // Week number hero
            Text("\(entry.weekNumber)")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .minimumScaleFactor(0.7)

            Text("WEEK")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))

            Spacer(minLength: 4)

            // Today indicator
            ZStack {
                Circle()
                    .fill(JohoWidget.Colors.now)
                Circle()
                    .stroke(JohoWidget.Colors.border, lineWidth: 2)
                Text("\(entry.dayNumber)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text)
            }
            .frame(width: 28, height: 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Random Fact Section (情報デザイン: Bento compartments)

    private var randomFactSection: some View {
        VStack(spacing: 0) {
            // TOP: Header row with source
            HStack(spacing: 0) {
                // Icon compartment
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(randomFact.color.opacity(0.2))
                    Image(systemName: randomFact.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(randomFact.color)
                }
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(JohoWidget.Colors.border, lineWidth: borderCell)
                )
                .padding(8)

                // Bento wall
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(width: borderCell)

                // Source label
                VStack(alignment: .leading, spacing: 2) {
                    Text("RANDOM FACT")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoWidget.Colors.text.opacity(0.5))
                        .tracking(0.5)

                    Text(randomFact.source.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(randomFact.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
            }
            .frame(height: 60)

            // 情報デザイン: Horizontal bento wall
            Rectangle()
                .fill(JohoWidget.Colors.border)
                .frame(height: borderRow)

            // BOTTOM: Fact text
            Text(randomFact.text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)
        }
    }
}

// MARK: - Preview

#Preview("World Clock Widget", as: .systemMedium) {
    VeckaWidget()
} timeline: {
    VeckaWidgetEntry.preview
}
