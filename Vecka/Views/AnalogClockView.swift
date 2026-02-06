//
//  AnalogClockView.swift
//  Vecka
//
//  情報デザイン: Analog clock with hour/minute hands
//  Inspired by classic station clocks
//

import SwiftUI

/// Analog clock view with hour and minute hands (情報デザイン compliant)
/// Uses TimelineView for memory-safe time updates (no timer leaks)
struct AnalogClockView: View {
    let timezone: TimeZone
    let size: CGFloat
    let accentColor: Color
    @Environment(\.scenePhase) private var scenePhase

    private var shouldAnimate: Bool {
        scenePhase == .active && !AppEnvironment.disableAnimations
    }

    var body: some View {
        if shouldAnimate {
            // TimelineView properly manages its lifecycle - no memory leaks
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ClockFaceView(
                    currentTime: context.date,
                    timezone: timezone,
                    size: size,
                    accentColor: accentColor
                )
            }
        } else {
            ClockFaceView(
                currentTime: Date(),
                timezone: timezone,
                size: size,
                accentColor: accentColor
            )
        }
    }
}

/// Internal clock face view (extracted to avoid TimelineView re-render issues)
private struct ClockFaceView: View {
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    let currentTime: Date
    let timezone: TimeZone
    let size: CGFloat
    let accentColor: Color

    var body: some View {
        ZStack {
            // Clock face (情報デザイン: clean, minimal)
            clockFace

            // Hour markers
            hourMarkers

            // Hour hand
            hourHand

            // Minute hand
            minuteHand

            // Center dot
            Circle()
                .fill(colors.primary)
                .frame(width: size * 0.08, height: size * 0.08)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Clock Components

    private var clockFace: some View {
        Circle()
            .fill(colors.surface)
            .overlay(
                Circle()
                    .stroke(colors.border, lineWidth: size * 0.04)
            )
    }

    private var hourMarkers: some View {
        ForEach(0..<12, id: \.self) { hour in
            Rectangle()
                .fill(colors.primary)
                .frame(width: hour % 3 == 0 ? size * 0.03 : size * 0.015,
                       height: hour % 3 == 0 ? size * 0.12 : size * 0.06)
                .offset(y: -size * 0.38)
                .rotationEffect(.degrees(Double(hour) * 30))
        }
    }

    private var hourHand: some View {
        RoundedRectangle(cornerRadius: size * 0.02)
            .fill(colors.primary)
            .frame(width: size * 0.06, height: size * 0.28)
            .offset(y: -size * 0.12)
            .rotationEffect(hourAngle)
    }

    private var minuteHand: some View {
        RoundedRectangle(cornerRadius: size * 0.015)
            .fill(accentColor)
            .frame(width: size * 0.035, height: size * 0.38)
            .offset(y: -size * 0.17)
            .rotationEffect(minuteAngle)
    }

    // MARK: - Time Calculations

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = timezone
        return cal
    }

    private var hourAngle: Angle {
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        // Hour hand moves 30 degrees per hour + 0.5 degrees per minute
        let degrees = Double(hour % 12) * 30 + Double(minute) * 0.5
        return .degrees(degrees)
    }

    private var minuteAngle: Angle {
        let minute = calendar.component(.minute, from: currentTime)
        let second = calendar.component(.second, from: currentTime)
        // Minute hand moves 6 degrees per minute + 0.1 degrees per second
        let degrees = Double(minute) * 6 + Double(second) * 0.1
        return .degrees(degrees)
    }
}

/// World clock cell with analog clock and digital time (情報デザイン)
/// Uses TimelineView for memory-safe time updates (no timer leaks)
struct WorldClockCell: View {
    let cityCode: String
    let cityName: String
    let timezone: TimeZone
    let accentColor: Color
    let lightBackground: Color
    let isLocal: Bool
    @Environment(\.scenePhase) private var scenePhase

    private var shouldAnimate: Bool {
        scenePhase == .active && !AppEnvironment.disableAnimations
    }

    var body: some View {
        if shouldAnimate {
            // TimelineView properly manages its lifecycle - no memory leaks
            TimelineView(.periodic(from: .now, by: 1)) { context in
                WorldClockCellContent(
                    currentTime: context.date,
                    cityCode: cityCode,
                    cityName: cityName,
                    timezone: timezone,
                    accentColor: accentColor,
                    lightBackground: lightBackground,
                    isLocal: isLocal
                )
            }
        } else {
            WorldClockCellContent(
                currentTime: Date(),
                cityCode: cityCode,
                cityName: cityName,
                timezone: timezone,
                accentColor: accentColor,
                lightBackground: lightBackground,
                isLocal: isLocal
            )
        }
    }
}

/// Internal content view for WorldClockCell
private struct WorldClockCellContent: View {
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    let currentTime: Date
    let cityCode: String
    let cityName: String
    let timezone: TimeZone
    let accentColor: Color
    let lightBackground: Color
    let isLocal: Bool

    var body: some View {
        VStack(spacing: 6) {
            // City code badge
            Text(cityCode)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(accentColor)
                .clipShape(Capsule())

            // Analog clock
            AnalogClockView(
                timezone: timezone,
                size: 60,
                accentColor: accentColor
            )

            // Digital time (small, below clock)
            Text(formattedTime)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)

            // Offset indicator
            HStack(spacing: 2) {
                Image(systemName: isDaytime ? "sun.min.fill" : "moon.fill")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(isDaytime ? Color(hex: "F39C12") : Color(hex: "6C5CE7"))

                Text(offsetText)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(lightBackground)
    }

    // MARK: - Computed Properties

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }

    private var offsetText: String {
        let localOffset = TimeZone.current.secondsFromGMT()
        let clockOffset = timezone.secondsFromGMT()
        let hourDiff = (clockOffset - localOffset) / 3600

        if hourDiff == 0 {
            return "LOCAL"
        } else if hourDiff > 0 {
            return "+\(hourDiff)"
        } else {
            return "\(hourDiff)"
        }
    }

    private var isDaytime: Bool {
        var cal = Calendar.current
        cal.timeZone = timezone
        let hour = cal.component(.hour, from: currentTime)
        return hour >= 6 && hour < 18
    }
}

#Preview {
    VStack(spacing: 20) {
        AnalogClockView(
            timezone: TimeZone(identifier: "Europe/Stockholm")!,
            size: 100,
            accentColor: Color(hex: "4A90D9")
        )

        WorldClockCell(
            cityCode: "STM",
            cityName: "Stora Mellösa",
            timezone: TimeZone(identifier: "Europe/Stockholm")!,
            accentColor: Color(hex: "4A90D9"),
            lightBackground: Color(hex: "E8F4FD"),
            isLocal: true
        )
        .frame(width: 120)
    }
    .padding()
    .background(Color.black)
}
