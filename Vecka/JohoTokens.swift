//
//  JohoTokens.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Authentic Japanese Packaging Style
//  Inspired by Muhi, Rohto, and classic Japanese OTC medicine packaging
//

import SwiftUI

// MARK: - Section Zones (色分け)
// 情報デザイン Option B: 6-Color Simplified Zones
// Each zone maps to ONE semantic color for reduced cognitive load

enum SectionZone {
    // ═══════════════════════════════════════════════════════════════════
    // 6 SEMANTIC ZONES (matching 6-color palette)
    // ═══════════════════════════════════════════════════════════════════
    case notes       // YELLOW - present moment, personal items
    case memos       // GREEN - user memos (メモ category in Star page)
    case calendar    // CYAN - scheduled time (events, trips, calendar)
    case trips       // CYAN - scheduled time (alias for calendar)
    case events      // CYAN - scheduled time (alias for calendar)
    case countdowns  // CYAN - scheduled time (alias for calendar)
    case holidays    // PINK - celebrations, special days
    case observances // CYAN - scheduled cultural observances
    case birthdays   // PINK - celebrations (alias for holidays)
    case expenses    // GREEN - money, financial items
    case contacts    // PURPLE - people, relationships
    case warning     // RED - alerts (system only)

    /// 情報デザイン: Semantic background colors (6-color palette)
    var background: Color {
        switch self {
        // YELLOW = NOW (notes, present moment)
        case .notes:
            return JohoColors.yellow

        // GREEN = MEMOS (user memos in Star page)
        case .memos, .expenses:
            return JohoColors.green

        // CYAN = SCHEDULED (all time-based items + cultural observances)
        case .calendar, .trips, .events, .countdowns, .observances:
            return JohoColors.cyan

        // PINK = CELEBRATION (holidays and birthdays)
        case .holidays, .birthdays:
            return JohoColors.pink

        // PURPLE = PEOPLE
        case .contacts:
            return JohoColors.purple

        // RED = ALERT (system only)
        case .warning:
            return JohoColors.redLight
        }
    }

    /// 情報デザイン: Dark mode background colors (opacity-based tints over dark surface)
    var darkBackground: Color {
        switch self {
        case .notes:
            return JohoColors.yellow.opacity(0.25)       // Warm amber tint
        case .memos, .expenses:
            return JohoColors.green.opacity(0.25)         // Mint tint (memos + expenses)
        case .calendar, .trips, .events, .countdowns, .observances:
            return JohoColors.cyan.opacity(0.25)          // Cool teal tint
        case .holidays, .birthdays:
            return JohoColors.pink.opacity(0.25)          // Soft rose tint
        case .contacts:
            return JohoColors.purple.opacity(0.25)        // Lavender tint
        case .warning:
            return JohoColors.red.opacity(0.25)           // Alert tint
        }
    }

    /// Get background color for the specified color mode
    func background(for mode: JohoColorMode) -> Color {
        switch mode {
        case .light: return background
        case .dark: return darkBackground
        }
    }

    // All zones use BLACK text now (light backgrounds have good contrast)
    var textColor: Color {
        JohoColors.black
    }

    /// Get text color for the specified color mode
    func textColor(for mode: JohoColorMode) -> Color {
        switch mode {
        case .light: return JohoColors.black
        case .dark: return JohoColors.white
        }
    }
}

// MARK: - Typography (Bold & Rounded)

enum JohoFont {
    // Display - for big numbers, titles
    static let displayLarge = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let displayMedium = Font.system(size: 32, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 24, weight: .bold, design: .rounded)

    // Titles
    static let title = Font.system(size: 20, weight: .bold, design: .rounded)

    // Headlines
    static let headline = Font.system(size: 18, weight: .bold, design: .rounded)
    static let headlineSmall = Font.system(size: 16, weight: .bold, design: .rounded)
    static let subheadline = Font.system(size: 15, weight: .semibold, design: .rounded)

    // Body
    static let body = Font.system(size: 16, weight: .medium, design: .rounded)
    static let bodySmall = Font.system(size: 14, weight: .medium, design: .rounded)
    static let bodySmallBold = Font.system(size: 14, weight: .bold, design: .rounded)

    // Tags & Badges
    static let tag = Font.system(size: 11, weight: .bold, design: .rounded)
    static let headerTag = Font.system(size: 11, weight: .black, design: .rounded)
    static let pillLabel = Font.system(size: 10, weight: .black, design: .rounded)

    // Labels (for pills)
    static let label = Font.system(size: 12, weight: .bold, design: .rounded)
    static let labelSmall = Font.system(size: 10, weight: .heavy, design: .rounded)
    static let labelBold = Font.system(size: 10, weight: .bold, design: .rounded)

    // Button
    static let button = Font.system(size: 15, weight: .semibold, design: .rounded)

    // Caption (情報デザイン: NEVER below .medium weight)
    static let caption = Font.system(size: 12, weight: .medium, design: .rounded)

    // Monospaced (for numbers)
    static let monoLarge = Font.system(size: 24, weight: .bold, design: .monospaced)
    static let monoMedium = Font.system(size: 16, weight: .semibold, design: .monospaced)
    static let monoSmall = Font.system(size: 14, weight: .medium, design: .monospaced)
}

// MARK: - Dimensions

enum JohoDimensions {
    // Corner radii (squircle style)
    static let radiusXS: CGFloat = 4
    static let radiusChip: CGFloat = 6
    static let radiusSmall: CGFloat = 8
    static let radiusCard: CGFloat = 10
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXL: CGFloat = 20
    static let radiusXXL: CGFloat = 24

    // CRITICAL: Thick outlines like Japanese packaging (CLAUDE.md spec)
    static let borderThin: CGFloat = 1.0      // Day cells - per CLAUDE.md spec
    static let borderMedium: CGFloat = 2.0    // Buttons - per CLAUDE.md spec
    static let borderThick: CGFloat = 3.0     // Containers - per CLAUDE.md spec

    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 20

    // Opacity levels (情報デザイン: consistent transparency)
    static let opacityFaint: Double = 0.05
    static let opacitySubtle: Double = 0.1
    static let opacityLight: Double = 0.15
    static let opacityMild: Double = 0.2
    static let opacityMedium: Double = 0.3
    static let opacityModerate: Double = 0.4
    static let opacityHeavy: Double = 0.5
    static let opacityStrong: Double = 0.6
    static let opacityBold: Double = 0.7
    static let opacityDense: Double = 0.8
}

// MARK: - Card Size (Regular vs Compact)
/// 情報デザイン: Adaptive card sizing for iPhone (regular) vs iPad compact layouts

enum JohoCardSize {
    case regular   // iPhone: larger text, more spacing
    case compact   // iPad widgets: smaller text, tighter spacing

    // Typography
    var headerFontSize: CGFloat { self == .regular ? 11 : 10 }
    var bodyFontSize: CGFloat { self == .regular ? 13 : 11 }
    var labelFontSize: CGFloat { self == .regular ? 10 : 9 }
    var badgeFontSize: CGFloat { self == .regular ? 8 : 7 }

    // Indicators
    var dotSize: CGFloat { self == .regular ? 8 : 6 }
    var iconSize: CGFloat { self == .regular ? 12 : 10 }

    // Spacing
    var headerPadding: CGFloat { self == .regular ? JohoDimensions.spacingMD : JohoDimensions.spacingSM }
    var contentPadding: CGFloat { self == .regular ? JohoDimensions.spacingMD : JohoDimensions.spacingSM }
    var itemSpacing: CGFloat { self == .regular ? JohoDimensions.spacingSM : 4 }

    // Border & Corner
    var borderWidth: CGFloat { self == .regular ? JohoDimensions.borderMedium : JohoDimensions.borderThick }
    var cornerRadius: CGFloat { self == .regular ? JohoDimensions.radiusMedium : JohoDimensions.radiusSmall }

    // Item limits
    var maxItems: Int { self == .regular ? 5 : 10 }
}

// MARK: - Squircle Shape
// iOS app-icon style continuous corners

struct Squircle: Shape, InsettableShape {
    var cornerRadius: CGFloat
    private var insetAmount: CGFloat = 0

    init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
    }

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        return Path(
            roundedRect: insetRect,
            cornerRadius: max(cornerRadius - insetAmount, 0),
            style: .continuous
        )
    }

    func inset(by amount: CGFloat) -> Squircle {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

/// 情報デザイン: Half circle shape for split-color buttons
struct HalfCircle: Shape {
    var isLeft: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isLeft {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                       radius: rect.width / 2,
                       startAngle: .degrees(-90),
                       endAngle: .degrees(90),
                       clockwise: true)
            path.closeSubpath()
        } else {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                       radius: rect.width / 2,
                       startAngle: .degrees(-90),
                       endAngle: .degrees(90),
                       clockwise: false)
            path.closeSubpath()
        }
        return path
    }
}
