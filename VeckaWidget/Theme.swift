//
//  Theme.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Widget Theme
//  Japanese Information Design: HIGH CONTRAST, BOLD BORDERS, CLEAN WHITE
//

import SwiftUI
import WidgetKit

// MARK: - 情報デザイン Widget Colors

enum JohoWidgetColors {
    // Core - HIGH CONTRAST
    static let black = Color.black
    static let white = Color.white

    // Accent colors - vibrant, clear
    static let pink = Color(red: 255/255, green: 100/255, blue: 130/255)    // Vibrant pink for holidays
    static let cyan = Color(red: 0/255, green: 180/255, blue: 216/255)      // Bright cyan for observances
    static let sundayBlue = Color(red: 65/255, green: 130/255, blue: 235/255)  // Clear blue for Sundays

    // Today indicator - bold red-orange
    static let todayRed = Color(red: 235/255, green: 64/255, blue: 52/255)
}

// MARK: - 情報デザイン Widget Typography

enum JohoWidgetFont {
    // Display - BOLD, HEAVY for impact
    static let displayHuge = Font.system(size: 56, weight: .black, design: .rounded)
    static let displayLarge = Font.system(size: 42, weight: .black, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)

    // Headers
    static let headerLarge = Font.system(size: 18, weight: .heavy, design: .rounded)
    static let headerMedium = Font.system(size: 15, weight: .bold, design: .rounded)

    // Body
    static let bodyLarge = Font.system(size: 14, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 13, weight: .medium, design: .rounded)

    // Labels - small but BOLD
    static let labelBold = Font.system(size: 11, weight: .heavy, design: .rounded)
    static let labelSmall = Font.system(size: 10, weight: .bold, design: .rounded)

    // Calendar numbers
    static let calendarDay = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let calendarDayBold = Font.system(size: 15, weight: .bold, design: .rounded)
    static let weekNumber = Font.system(size: 10, weight: .heavy, design: .rounded)
}

// MARK: - 情報デザイン Dimensions

enum JohoDimensions {
    // Borders - THICK, BOLD
    static let borderBold: CGFloat = 3
    static let borderMedium: CGFloat = 2.5
    static let borderThin: CGFloat = 2

    // Corner radii - continuous squircle
    static let radiusLarge: CGFloat = 16
    static let radiusMedium: CGFloat = 12
    static let radiusSmall: CGFloat = 8
    static let radiusTiny: CGFloat = 6

    // Spacing
    static let spacingXL: CGFloat = 16
    static let spacingLG: CGFloat = 12
    static let spacingMD: CGFloat = 8
    static let spacingSM: CGFloat = 6
    static let spacingXS: CGFloat = 4
}

// MARK: - Squircle Shape

struct WidgetSquircle: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
    }
}

// MARK: - 情報デザイン Week Badge (Bold Black Pill)

struct JohoWeekBadge: View {
    let weekNumber: Int
    var size: Size = .medium

    enum Size {
        case small, medium, large

        var fontSize: CGFloat {
            switch self {
            case .small: return 11
            case .medium: return 14
            case .large: return 16
            }
        }

        var paddingH: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }

        var paddingV: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 5
            case .large: return 6
            }
        }
    }

    var body: some View {
        Text("W\(weekNumber)")
            .font(.system(size: size.fontSize, weight: .black, design: .rounded))
            .foregroundStyle(JohoWidgetColors.white)
            .padding(.horizontal, size.paddingH)
            .padding(.vertical, size.paddingV)
            .background(JohoWidgetColors.black)
            .clipShape(WidgetSquircle(cornerRadius: JohoDimensions.radiusTiny))
    }
}

// MARK: - 情報デザイン Day Cell

struct JohoDayCell: View {
    let day: Int
    let isToday: Bool
    let isRedDay: Bool
    let isSunday: Bool
    var cellSize: CGFloat = 28

    var body: some View {
        ZStack {
            // Today gets bold red circle
            if isToday {
                Circle()
                    .fill(JohoWidgetColors.todayRed)
                    .frame(width: cellSize, height: cellSize)
            }

            Text("\(day)")
                .font(isToday ? JohoWidgetFont.calendarDayBold : JohoWidgetFont.calendarDay)
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity)
    }

    private var textColor: Color {
        if isToday { return JohoWidgetColors.white }
        if isRedDay { return JohoWidgetColors.pink }
        if isSunday { return JohoWidgetColors.sundayBlue }
        return JohoWidgetColors.black
    }
}

// MARK: - 情報デザイン Holiday Pill

struct JohoHolidayPill: View {
    let name: String
    let isRedDay: Bool

    var body: some View {
        HStack(spacing: JohoDimensions.spacingXS) {
            Circle()
                .fill(isRedDay ? JohoWidgetColors.pink : JohoWidgetColors.cyan)
                .frame(width: 6, height: 6)

            Text(name)
                .font(JohoWidgetFont.labelSmall)
                .foregroundStyle(isRedDay ? JohoWidgetColors.pink : JohoWidgetColors.cyan)
                .lineLimit(1)
        }
    }
}

// MARK: - Legacy Support (for backwards compatibility)

struct WidgetColors {
    static let accent = JohoWidgetColors.todayRed  // 情報デザイン: Use semantic red
    static let holiday = JohoWidgetColors.pink
    static let observance = JohoWidgetColors.cyan
    static let sundayBlue = JohoWidgetColors.sundayBlue
    static let saturdayNormal = Color.primary
}

struct Theme {
    static let cornerRadius: CGFloat = 20
    static let padding: CGFloat = 16
    static let compactPadding: CGFloat = 12
    static let itemSpacing: CGFloat = 8

    static func primaryLabel(for mode: WidgetRenderingMode) -> Color {
        switch mode {
        case .vibrant: return .white
        case .accented: return .primary
        default: return .primary
        }
    }

    static func secondaryLabel(for mode: WidgetRenderingMode) -> Color {
        switch mode {
        case .vibrant: return .white.opacity(0.6)
        case .accented: return .secondary
        default: return .secondary
        }
    }

    static func tertiaryLabel(for mode: WidgetRenderingMode) -> Color {
        switch mode {
        case .vibrant: return .white.opacity(0.4)
        case .accented: return .secondary.opacity(0.6)
        default: return Color(uiColor: .tertiaryLabel)
        }
    }
}
