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

    private var worldClocks: [SharedWorldClock] {
        WorldClockStorage.load()
    }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // LEFT: Week number hero (compact)
                weekNumberSection
                    .frame(width: geo.size.width * 0.25)

                // Vertical divider
                Rectangle()
                    .fill(JohoWidget.Colors.border)
                    .frame(width: 1.5)

                // RIGHT: World clocks (bento compartments)
                worldClocksSection
                    .frame(maxWidth: .infinity)
            }
        }
        .widgetURL(URL(string: "vecka://clocks"))
        .containerBackground(for: .widget) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(JohoWidget.Colors.content)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(JohoWidget.Colors.border.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // MARK: - Week Number Section

    private var weekNumberSection: some View {
        VStack(spacing: 4) {
            // Week number
            Text("\(entry.weekNumber)")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .minimumScaleFactor(0.7)

            Text("WEEK")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text.opacity(0.4))
                .tracking(1.5)

            Spacer(minLength: 4)

            // Today indicator
            Text("\(entry.dayNumber)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)
                .frame(width: 28, height: 28)
                .background(JohoWidget.Colors.now)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(JohoWidget.Colors.border, lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 8)
        .background(JohoWidget.Colors.now.opacity(0.15))
    }

    // MARK: - World Clocks Section

    private var worldClocksSection: some View {
        HStack(spacing: 0) {
            ForEach(Array(worldClocks.enumerated()), id: \.element.id) { index, clock in
                if index > 0 {
                    // Vertical wall between clocks (情報デザイン: bento compartment)
                    Rectangle()
                        .fill(JohoWidget.Colors.border.opacity(0.3))
                        .frame(width: 1)
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
            // Country code pill (情報デザイン: Region-colored)
            Text(clock.countryCode)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(theme.accentColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(JohoWidget.Colors.border.opacity(0.5), lineWidth: 0.5))

            // City name
            Text(clock.cityName)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
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
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(JohoWidget.Colors.text)

            // Day/Night + offset
            HStack(spacing: 2) {
                Image(systemName: clock.isDaytime ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(clock.isDaytime ? Color(hex: "F39C12") : Color(hex: "6C5CE7"))

                Text(clock.offsetFromLocal)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoWidget.Colors.text.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 4)
        .background(theme.lightBackground.opacity(0.5))
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
