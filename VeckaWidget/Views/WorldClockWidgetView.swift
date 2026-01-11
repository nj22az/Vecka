//
//  WorldClockWidgetView.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) World Clock Widget
//  Analog clocks with region-themed colors, matching Onsen landing page
//

import SwiftUI
import WidgetKit

/// Medium widget showing world clocks (情報デザイン style)
struct WorldClockMediumWidgetView: View {
    let entry: VeckaWidgetEntry
    private let family: WidgetFamily = .systemMedium

    // 情報デザイン: Theme constants for consistency
    private var typo: JohoWidget.Typography.Scale { JohoWidget.Typography.medium }
    private var borders: JohoWidget.Borders.Weights { JohoWidget.Borders.medium }
    private var corners: JohoWidget.Corners.Radii { JohoWidget.Corners.medium }

    private var worldClocks: [SharedWorldClock] {
        WorldClockStorage.load()
    }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // LEFT: Week number hero (compact)
                weekNumberSection
                    .frame(width: geo.size.width * 0.25)

                // Vertical divider (情報デザイン: match border weight)
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(width: borders.container)

                // RIGHT: World clocks (bento compartments)
                worldClocksSection
                    .frame(maxWidth: .infinity)
            }
        }
        .widgetURL(URL(string: "vecka://clocks"))
        .containerBackground(for: .widget) {
            // 情報デザイン: Theme.Borders.medium.widget = 2.5pt
            RoundedRectangle(cornerRadius: corners.widget, style: .continuous)
                .fill(JohoWidget.Colors.content)
                .overlay(
                    RoundedRectangle(cornerRadius: corners.widget - 2, style: .continuous)
                        .stroke(JohoWidget.Colors.border, lineWidth: borders.widget)
                        .padding(1)
                )
        }
    }

    // MARK: - Computed Properties (情報デザイン: functional data)

    private var monthShort: String {
        entry.date.formatted(.dateTime.month(.abbreviated).locale(.autoupdatingCurrent)).uppercased()
    }

    private var year: String {
        String(entry.year)
    }

    // MARK: - Week Number Section (情報デザイン: Day, Week, Month, Year - all functional)

    private var weekNumberSection: some View {
        VStack(spacing: 2) {
            // Month + Year (情報デザイン: complete temporal context)
            Text("\(monthShort)")
                .font(.system(size: typo.label, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
                .tracking(1)

            Text(year)
                .font(.system(size: typo.micro, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))

            Spacer(minLength: 2)

            // Week number (hero) - compact version for world clock widget
            Text("\(entry.weekNumber)")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .minimumScaleFactor(0.7)

            Text("WEEK")
                .font(.system(size: typo.micro, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
                .tracking(1)

            Spacer(minLength: 2)

            // Today indicator (情報デザイン: Circle like all other widgets, not RoundedRectangle)
            ZStack {
                Circle()
                    .fill(JohoWidget.Colors.now)
                    .frame(width: 32, height: 32)
                Circle()
                    .stroke(JohoWidget.Colors.border, lineWidth: borders.selected)
                    .frame(width: 32, height: 32)
                Text("\(entry.dayNumber)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 6)
        // 情報デザイン: WHITE background - color only on TODAY indicator
    }

    // MARK: - World Clocks Section

    private var worldClocksSection: some View {
        HStack(spacing: 0) {
            ForEach(Array(worldClocks.enumerated()), id: \.element.id) { index, clock in
                if index > 0 {
                    // 情報デザイン: Bento wall - match row border weight
                    Rectangle()
                        .fill(JohoWidget.Colors.border)
                        .frame(width: borders.row)
                }

                worldClockCell(clock)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Individual Clock Cell

    private func worldClockCell(_ clock: SharedWorldClock) -> some View {
        let theme = WidgetTimezoneTheme.theme(for: clock.timezoneIdentifier)

        return VStack(spacing: 3) {
            // Country code pill (情報デザイン: Region-colored with black border)
            Text(clock.countryCode)
                .font(.system(size: typo.label, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(theme.accentColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(JohoWidget.Colors.border, lineWidth: borders.cell))

            // City name
            Text(clock.cityName)
                .font(.system(size: typo.label, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Analog clock (情報デザイン: Station clock style)
            WidgetAnalogClock(
                hourAngle: clock.hourAngle,
                minuteAngle: clock.minuteAngle,
                accentColor: theme.accentColor,
                size: 44
            )

            // Digital time
            Text(clock.formattedTime)
                .font(.system(size: typo.headline, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)

            // Day/Night + offset
            HStack(spacing: 2) {
                Image(systemName: clock.isDaytime ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(clock.isDaytime ? Color(hex: "F39C12") : Color(hex: "6C5CE7"))

                Text(clock.offsetFromLocal)
                    .font(.system(size: typo.micro, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 4)
        // 情報デザイン: WHITE background - semantic color only on country pill
    }
}

// MARK: - Widget Analog Clock (Static for widgets)

/// Simple analog clock for widgets (no animation, just renders current time)
struct WidgetAnalogClock: View {
    let hourAngle: Double
    let minuteAngle: Double
    let accentColor: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            // Clock face
            Circle()
                .fill(Color.white)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: size * 0.04)
                )

            // Hour markers
            ForEach(0..<12) { hour in
                Rectangle()
                    .fill(Color.black)
                    .frame(
                        width: hour % 3 == 0 ? size * 0.025 : size * 0.015,
                        height: hour % 3 == 0 ? size * 0.1 : size * 0.05
                    )
                    .offset(y: -size * 0.38)
                    .rotationEffect(.degrees(Double(hour) * 30))
            }

            // Hour hand
            RoundedRectangle(cornerRadius: size * 0.02)
                .fill(Color.black)
                .frame(width: size * 0.05, height: size * 0.25)
                .offset(y: -size * 0.1)
                .rotationEffect(.degrees(hourAngle))

            // Minute hand
            RoundedRectangle(cornerRadius: size * 0.015)
                .fill(accentColor)
                .frame(width: size * 0.03, height: size * 0.35)
                .offset(y: -size * 0.15)
                .rotationEffect(.degrees(minuteAngle))

            // Center dot
            Circle()
                .fill(Color.black)
                .frame(width: size * 0.08, height: size * 0.08)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("World Clock Widget", as: .systemMedium) {
    VeckaWidget()
} timeline: {
    VeckaWidgetEntry.preview
}
