//
//  JohoDesignSystem.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Authentic Japanese Packaging Style
//  Inspired by Muhi, Rohto, and classic Japanese OTC medicine packaging
//

import SwiftUI

// MARK: - Core Colors (Like Muhi/Rohto Packaging)

enum JohoColors {
    // Primary contrast pair - ALWAYS use these for text
    static let black = Color(hex: "000000")
    static let white = Color(hex: "FFFFFF")

    // Section background colors (情報デザイン semantic colors - CLAUDE.md spec)
    static let pink = Color(hex: "FECDD3")      // Special Days - celebrations (#FECDD3)
    static let red = Color(hex: "E53935")       // Alert/Warnings/Sundays (#E53935)

    // 情報デザイン: Light tints for bento box backgrounds (so colored circles are visible)
    static let redLight = Color(hex: "FECACA")      // Light red for holiday bento boxes
    static let pinkLight = Color(hex: "FED7E2")     // Light pink for birthday bento boxes
    static let green = Color(hex: "BBF7D0")     // Money/Expenses (#BBF7D0)
    static let yellow = Color(hex: "FFE566")    // NOW/Present/Today (#FFE566)
    static let orange = Color(hex: "FED7AA")    // Movement/Trips (#FED7AA)
    static let cyan = Color(hex: "A5F3FC")      // Scheduled Time/Events (#A5F3FC)
    static let cream = Color(hex: "FEF3C7")     // Personal/Notes (#FEF3C7)
    static let purple = Color(hex: "E9D5FF")    // People/Contacts (#E9D5FF)

    // Type-specific colors (for indicator circles)
    static let eventPurple = Color(hex: "805AD5")  // EVT - Events
    static let tripBlue = Color(hex: "3182CE")     // TRP - Trips

    // App base (dark mode base, but sections are colorful)
    static let background = Color(hex: "1A1A2E")
    static let surface = Color(hex: "FFFFFF")   // Cards are WHITE with black borders

    // Form & Input semantic colors (情報デザイン)
    static let inputBackground = Color(hex: "F5F5F5")  // Light gray for text fields
    static let notesBackground = Color(hex: "FEF3C7")  // Warm cream for notes content

    // Action colors (destructive/interactive)
    static let editAction = Color(hex: "3182CE")       // Blue for edit actions
    static let deleteAction = Color(hex: "E53E3E")     // Red for delete actions
}

// MARK: - Section Zones (色分け)
// Each feature gets a distinct pastel background + BLACK border

enum SectionZone {
    case calendar   // Cyan - cool, organized
    case notes      // Yellow - attention, ideas
    case expenses   // Green - money, growth
    case trips      // Orange - energy, adventure
    case holidays   // RED - celebration, holidays
    case birthdays  // PINK - birthdays (from Contacts)
    case contacts   // Cream - people, warmth
    case countdowns // Orange - urgency, timers
    case warning    // Orange - alerts

    /// 情報デザイン: Bento box backgrounds use LIGHT TINTS so colored indicator circles are visible
    var background: Color {
        switch self {
        case .calendar: return JohoColors.cyan.opacity(0.3)
        case .notes: return JohoColors.yellow.opacity(0.3)
        case .expenses: return JohoColors.green.opacity(0.3)
        case .trips: return JohoColors.orange.opacity(0.3)
        case .holidays: return JohoColors.redLight       // Light red so RED circles visible
        case .birthdays: return JohoColors.pinkLight     // Light pink so PINK circles visible
        case .contacts: return JohoColors.cream
        case .countdowns: return JohoColors.orange.opacity(0.3)
        case .warning: return JohoColors.orange.opacity(0.3)
        }
    }

    // All zones use BLACK text now (light backgrounds have good contrast)
    var textColor: Color {
        JohoColors.black
    }
}

// MARK: - Typography (Bold & Rounded)

enum JohoFont {
    // Display - for big numbers, titles
    static let displayLarge = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let displayMedium = Font.system(size: 32, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 24, weight: .bold, design: .rounded)

    // Headlines
    static let headline = Font.system(size: 18, weight: .bold, design: .rounded)
    static let subheadline = Font.system(size: 15, weight: .semibold, design: .rounded)

    // Body
    static let body = Font.system(size: 16, weight: .medium, design: .rounded)
    static let bodySmall = Font.system(size: 14, weight: .medium, design: .rounded)

    // Labels (for pills)
    static let label = Font.system(size: 12, weight: .bold, design: .rounded)
    static let labelSmall = Font.system(size: 10, weight: .heavy, design: .rounded)

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
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXL: CGFloat = 20

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
}

// MARK: - Squircle Shape
// iOS app-icon style continuous corners

struct Squircle: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(
            roundedRect: rect,
            cornerRadius: cornerRadius,
            style: .continuous
        )
    }
}

// MARK: - Bordered Squircle Container
// The CORE component - colored background + thick black border

struct JohoContainer<Content: View>: View {
    let zone: SectionZone?
    let backgroundColor: Color?
    var borderWidth: CGFloat = JohoDimensions.borderMedium
    var cornerRadius: CGFloat = JohoDimensions.radiusLarge
    var padding: CGFloat = JohoDimensions.spacingMD
    @ViewBuilder let content: Content

    init(
        zone: SectionZone? = nil,
        backgroundColor: Color? = nil,
        borderWidth: CGFloat = JohoDimensions.borderMedium,
        cornerRadius: CGFloat = JohoDimensions.radiusLarge,
        padding: CGFloat = JohoDimensions.spacingMD,
        @ViewBuilder content: () -> Content
    ) {
        self.zone = zone
        self.backgroundColor = backgroundColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    private var fillColor: Color {
        if let bg = backgroundColor { return bg }
        if let z = zone { return z.background }
        return JohoColors.white
    }

    var body: some View {
        content
            .padding(padding)
            .background(fillColor)
            .clipShape(Squircle(cornerRadius: cornerRadius))
            .overlay(
                Squircle(cornerRadius: cornerRadius)
                    .stroke(JohoColors.black, lineWidth: borderWidth)
            )
    }
}

// MARK: - Pill Label (ラベル)
// Inverted color pills like Japanese packaging badges

struct JohoPill: View {
    let text: String
    var style: PillStyle = .blackOnWhite
    var size: PillSize = .medium

    enum PillStyle {
        case blackOnWhite   // White pill, black border, black text
        case whiteOnBlack   // Black pill, white text (most common)
        case colored(Color) // 情報デザイン: WHITE pill, colored border, colored text (NOT inverted!)
        case coloredInverted(Color) // Inverted: Colored bg, white text (use sparingly)
    }

    enum PillSize {
        case small, medium, large

        var font: Font {
            switch self {
            case .small: return JohoFont.labelSmall
            case .medium: return JohoFont.label
            case .large: return JohoFont.subheadline
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 3
            case .medium: return 5
            case .large: return 7
            }
        }
    }

    var body: some View {
        Text(text.uppercased())
            .font(size.font)
            .tracking(0.5)
            .foregroundStyle(textColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(backgroundView)
    }

    private var textColor: Color {
        switch style {
        case .blackOnWhite: return JohoColors.black
        case .whiteOnBlack: return JohoColors.white
        case .colored(let color): return color  // 情報デザイン: Colored text on white
        case .coloredInverted(let color):
            // 情報デザイン: Black text on light backgrounds (yellow), white on dark
            return color == JohoColors.yellow ? JohoColors.black : JohoColors.white
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .blackOnWhite:
            Capsule()
                .fill(JohoColors.white)
                .overlay(Capsule().stroke(JohoColors.black, lineWidth: 2))
        case .whiteOnBlack:
            Capsule()
                .fill(JohoColors.black)
        case .colored(let color):
            // 情報デザイン: WHITE background, COLORED border (not inverted!)
            Capsule()
                .fill(JohoColors.white)
                .overlay(Capsule().stroke(color, lineWidth: 1.5))
        case .coloredInverted(let color):
            // Inverted style (use sparingly)
            Capsule()
                .fill(color)
                .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1.5))
        }
    }
}

// MARK: - Indicator Circle (型別指示器)
// 情報デザイン: Type indicator circles ALWAYS have BLACK borders
// Used in: calendar grid, collapsed rows, legend, expanded sections

struct JohoIndicatorCircle: View {
    let color: Color
    var size: JohoIndicatorSize = .medium
    var isFilled: Bool = true  // Filled = primary (●), Outlined = secondary (○)

    enum JohoIndicatorSize {
        case tiny      // 5pt - calendar grid indicators
        case small     // 7pt - calendar day cells
        case medium    // 10pt - expanded section items
        case large     // 12pt - legend popover
        case xlarge    // 24pt - legend header

        var dimension: CGFloat {
            switch self {
            case .tiny: return 5
            case .small: return 7
            case .medium: return 10
            case .large: return 12
            case .xlarge: return 24
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .tiny: return 0.5
            case .small: return 1
            case .medium: return 1.5
            case .large: return 1.5
            case .xlarge: return 2
            }
        }
    }

    var body: some View {
        Circle()
            .fill(isFilled ? color : Color.clear)
            .frame(width: size.dimension, height: size.dimension)
            .overlay(
                Circle()
                    .stroke(isFilled ? JohoColors.black : color, lineWidth: size.borderWidth)
            )
    }
}

// MARK: - Section Box (区画)
// Colored compartment with title pill and thick border

struct JohoSectionBox<Content: View>: View {
    let title: String
    let zone: SectionZone
    var icon: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            // Header with pill label
            HStack(spacing: JohoDimensions.spacingSM) {
                JohoPill(text: title, style: .whiteOnBlack, size: .medium)

                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                }

                Spacer()
            }

            // Content
            content
                .foregroundStyle(zone.textColor)
        }
        .padding(JohoDimensions.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(zone.background)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }
}

// MARK: - Form Section (情報デザイン: WHITE background for entry forms)
// Use for Add Trip, Add Expense, etc. - always WHITE with thick BLACK borders

struct JohoFormSection<Content: View>: View {
    let title: String
    var icon: String? = nil
    var accentColor: Color = JohoColors.black
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            // Header row with BLACK pill
            HStack(spacing: JohoDimensions.spacingSM) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(JohoColors.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(JohoColors.black)
                    .clipShape(Squircle(cornerRadius: 4))

                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accentColor)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(JohoColors.white)

            // BLACK divider
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: JohoDimensions.borderMedium)

            // Content area - WHITE background
            content
                .padding(14)
                .background(JohoColors.white)
        }
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }
}

// MARK: - Form Field (情報デザイン: Individual form row)

struct JohoFormField<Content: View>: View {
    let label: String
    var isOptional: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(isOptional ? JohoColors.black.opacity(0.5) : JohoColors.black.opacity(0.7))

            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(JohoColors.white)
    }
}

// MARK: - Info Card (White card with black border)
// For list items, detail cards

struct JohoCard<Content: View>: View {
    var cornerRadius: CGFloat = JohoDimensions.radiusMedium
    var borderWidth: CGFloat = JohoDimensions.borderMedium
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(JohoDimensions.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: cornerRadius))
            .overlay(
                Squircle(cornerRadius: cornerRadius)
                    .stroke(JohoColors.black, lineWidth: borderWidth)
            )
    }
}

// MARK: - Day Cell (Calendar grid item)

struct JohoDayCell: View {
    let day: Int
    var isToday: Bool = false
    var isSelected: Bool = false
    var hasEvent: Bool = false
    var eventColor: Color = JohoColors.pink

    var body: some View {
        ZStack {
            // Background
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .fill(backgroundColor)

            // Border (always present, thicker when selected)
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(
                    JohoColors.black,
                    lineWidth: (isToday || isSelected) ? JohoDimensions.borderThick : JohoDimensions.borderThin
                )

            // Day number
            Text("\(day)")
                .font(JohoFont.headline)
                .foregroundStyle(textColor)

            // Event dot
            if hasEvent {
                VStack {
                    Spacer()
                    Circle()
                        .fill(eventColor)
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                        .padding(.bottom, 4)
                }
            }
        }
        .frame(width: 44, height: 44)
    }

    private var backgroundColor: Color {
        if isSelected { return JohoColors.black }
        if isToday { return JohoColors.yellow }
        return JohoColors.white
    }

    private var textColor: Color {
        if isSelected { return JohoColors.white }
        return JohoColors.black
    }
}

// MARK: - Week Badge (Large week number display)

struct JohoWeekBadge: View {
    let weekNumber: Int
    var size: BadgeSize = .large

    enum BadgeSize {
        case small, medium, large

        var dimension: CGFloat {
            switch self {
            case .small: return 44
            case .medium: return 54
            case .large: return 64
            }
        }

        var numberFont: Font {
            switch self {
            case .small: return JohoFont.headline
            case .medium: return JohoFont.displaySmall
            case .large: return JohoFont.displayMedium
            }
        }

        var labelFont: Font {
            switch self {
            case .small: return Font.system(size: 8, weight: .heavy, design: .rounded)
            case .medium: return JohoFont.labelSmall
            case .large: return JohoFont.labelSmall
            }
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("WEEK")
                .font(size.labelFont)
                .foregroundStyle(JohoColors.white.opacity(0.8))

            Text("\(weekNumber)")
                .font(size.numberFont)
                .foregroundStyle(JohoColors.white)
        }
        .frame(width: size.dimension, height: size.dimension)
        .background(JohoColors.black)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.white, lineWidth: 2)
        )
    }
}

// MARK: - List Row

struct JohoListRow: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    let zone: SectionZone
    var badge: String? = nil
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Icon in colored squircle
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)
                .frame(width: 40, height: 40)
                .background(zone.background)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                )

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)

                if let subtitle {
                    Text(subtitle)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
            }

            Spacer()

            // Optional badge
            if let badge {
                JohoPill(text: badge, style: .whiteOnBlack, size: .small)
            }

            // Chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.black)
            }
        }
        .padding(JohoDimensions.spacingMD)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }
}

// MARK: - Stat Box (統計)

struct JohoStatBox: View {
    let value: String
    let label: String
    let zone: SectionZone

    var body: some View {
        VStack(spacing: JohoDimensions.spacingXS) {
            Text(value)
                .font(JohoFont.displaySmall)
                .foregroundStyle(JohoColors.black)

            Text(label.uppercased())
                .font(JohoFont.labelSmall)
                .foregroundStyle(JohoColors.black.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingMD)
        .background(zone.background)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }
}

// MARK: - Page Header
// 情報デザイン: BLACK text on WHITE background, ALWAYS

struct JohoPageHeader: View {
    let title: String
    var badge: String? = nil
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            if let badge {
                JohoPill(text: badge, style: .whiteOnBlack, size: .large)
            }

            Text(title)
                .font(JohoFont.displayMedium)
                .foregroundStyle(JohoColors.black)  // 情報デザイン: BLACK text

            if let subtitle {
                Text(subtitle)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black.opacity(0.7))  // 情報デザイン: min 0.6 opacity
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(JohoDimensions.spacingLG)
        .background(JohoColors.white)  // 情報デザイン: WHITE container
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }
}

// MARK: - Metric Row (for stats display)

struct JohoMetricRow: View {
    let label: String
    let value: String
    var zone: SectionZone = .calendar

    var body: some View {
        HStack {
            Text(label)
                .font(JohoFont.body)
                .foregroundStyle(JohoColors.black)

            Spacer()

            Text(value)
                .font(JohoFont.monoMedium)
                .foregroundStyle(JohoColors.black)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(zone.background.opacity(0.3))
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
    }
}

// MARK: - Icon Badge (small icon with zone color)

struct JohoIconBadge: View {
    let icon: String
    let zone: SectionZone
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(JohoColors.black)
            .frame(width: size, height: size)
            .background(zone.background)
            .clipShape(Squircle(cornerRadius: size * 0.25))
            .overlay(
                Squircle(cornerRadius: size * 0.25)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
            )
    }
}

// MARK: - Toggle Row

struct JohoToggleRow: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    let zone: SectionZone
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            JohoIconBadge(icon: icon, zone: zone, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)

                if let subtitle {
                    Text(subtitle)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(zone.background)
        }
        .padding(JohoDimensions.spacingMD)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }
}

// MARK: - Divider

struct JohoDivider: View {
    var body: some View {
        Rectangle()
            .fill(JohoColors.black)
            .frame(height: 2)
    }
}

// MARK: - Country Color Scheme (情報デザイン: National colors as text pills)

struct CountryColorScheme {
    let backgroundColor: Color
    let textColor: Color
    let borderColor: Color
    let code: String  // 3-letter country code

    /// Get color scheme for a region code
    static func scheme(for region: String) -> CountryColorScheme? {
        switch region.uppercased() {
        case "SE": // Sweden: Dark blue pill, yellow text, black border
            return CountryColorScheme(
                backgroundColor: Color(hex: "004B87"),
                textColor: Color(hex: "FECC00"),
                borderColor: JohoColors.black,
                code: "SWE"
            )
        case "US": // USA: Navy blue pill, white text, black border
            return CountryColorScheme(
                backgroundColor: Color(hex: "3C3B6E"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: JohoColors.black,
                code: "USA"
            )
        case "VN": // Vietnam: Red pill, yellow text, black border
            return CountryColorScheme(
                backgroundColor: Color(hex: "DA251D"),
                textColor: Color(hex: "FFCD00"),
                borderColor: JohoColors.black,
                code: "VN"
            )
        default:
            return nil
        }
    }
}

/// 情報デザイン country indicator pill with text (replaces emoji flags)
struct CountryPill: View {
    let region: String

    var body: some View {
        if let scheme = CountryColorScheme.scheme(for: region) {
            Text(scheme.code)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(scheme.textColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(scheme.backgroundColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(scheme.borderColor, lineWidth: 1.5))
        }
    }
}

// MARK: - 情報デザイン Toggle

/// Standard 情報デザイン toggle switch with black border
struct JohoToggle: View {
    @Binding var isOn: Bool
    var accentColor: Color = JohoColors.cyan

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isOn.toggle()
            }
            HapticManager.selection()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? accentColor : JohoColors.black.opacity(0.2))
                    .frame(width: 50, height: 28)
                    .overlay(
                        Capsule()
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )

                Circle()
                    .fill(JohoColors.white)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Empty State

struct JohoEmptyState: View {
    let title: String
    let message: String
    let icon: String
    let zone: SectionZone

    var body: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)
                .frame(width: 80, height: 80)
                .background(zone.background)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                )

            Text(title)
                .font(JohoFont.headline)
                .foregroundStyle(JohoColors.white)

            Text(message)
                .font(JohoFont.bodySmall)
                .foregroundStyle(JohoColors.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(JohoDimensions.spacingXL)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply dark Joho background
    func johoBackground() -> some View {
        self
            .background(JohoColors.background)
            .scrollContentBackground(.hidden)
    }

    /// Standard Joho navigation bar styling
    func johoNavigation(title: String = "") -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JohoColors.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    /// Joho List styling
    func johoListStyle() -> some View {
        self
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(JohoColors.background)
    }
}

// MARK: - Today Banner (今日のバナー)
// Prominent banner showing today's date - goes at the VERY TOP

struct JohoTodayBanner: View {
    let date: Date
    var weekNumber: Int
    var onTapToday: (() -> Void)? = nil

    private var dayNumber: Int {
        Calendar.iso8601.component(.day, from: date)
    }

    private var weekdayName: String {
        date.formatted(.dateTime.weekday(.wide)).uppercased()
    }

    private var monthName: String {
        date.formatted(.dateTime.month(.wide))
    }

    private var yearString: String {
        String(Calendar.iso8601.component(.year, from: date))
    }

    var body: some View {
        Button(action: { onTapToday?() }) {
            HStack(spacing: JohoDimensions.spacingMD) {
                // Large day number
                Text("\(dayNumber)")
                    .font(JohoFont.displayLarge)
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 72)

                // Vertical separator
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 3, height: 56)

                // Date info
                VStack(alignment: .leading, spacing: 2) {
                    Text(weekdayName)
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)

                    Text("\(monthName) \(yearString)")
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                }

                Spacer()

                // Week badge
                VStack(spacing: 0) {
                    Text("WEEK")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.white.opacity(0.8))

                    Text("\(weekNumber)")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(JohoColors.white)
                }
                .frame(width: 56, height: 56)
                .background(JohoColors.black)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            }
            .padding(JohoDimensions.spacingMD)
            .background(JohoColors.yellow)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Today, \(weekdayName), \(monthName) \(dayNumber), \(yearString), Week \(weekNumber)")
        .accessibilityHint("Tap to jump to today")
    }
}

// MARK: - Month Selector (月選択)
// Compact month/year display with navigation arrows

struct JohoMonthSelector: View {
    let monthName: String
    let year: Int
    var onPrevious: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Previous month button
            Button(action: { onPrevious?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 36, height: 36)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )
            }
            .buttonStyle(.plain)

            // Month/Year button
            Button(action: { onTap?() }) {
                HStack(spacing: 6) {
                    Text(monthName.uppercased())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(1)

                    Text(verbatim: "\(year)")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                )
            }
            .buttonStyle(.plain)

            // Next month button
            Button(action: { onNext?() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 36, height: 36)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Calendar Container (カレンダー枠)
// White container with thick black border for the entire calendar grid

struct JohoCalendarContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(JohoDimensions.spacingSM)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
            )
    }
}

// MARK: - Weekday Header (曜日ヘッダー)
// Header row showing weekday abbreviations

struct JohoWeekdayHeader: View {
    let weekdays: [String] // ["M", "T", "W", "T", "F", "S", "S"]
    var showWeekColumn: Bool = true

    var body: some View {
        HStack(spacing: JohoDimensions.spacingXS) {
            // Week column header
            if showWeekColumn {
                Text("W")
                    .font(JohoFont.label)
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 36, height: 28)
                    .background(JohoColors.black.opacity(0.1))
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            }

            // Day headers
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(JohoFont.label)
                    .foregroundStyle(JohoColors.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
            }
        }
    }
}

// MARK: - Week Number Cell (週番号セル)
// Tappable week number in calendar grid

struct JohoWeekNumberCell: View {
    let weekNumber: Int
    var isCurrentWeek: Bool = false
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            // Background
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .fill(JohoColors.black)

            // Border when current/selected
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(
                    (isCurrentWeek || isSelected) ? JohoColors.white : JohoColors.black.opacity(0.3),
                    lineWidth: (isCurrentWeek || isSelected) ? JohoDimensions.borderMedium : JohoDimensions.borderThin
                )

            // Week number
            Text("\(weekNumber)")
                .font(JohoFont.headline)
                .foregroundStyle(JohoColors.white)
                .monospacedDigit()
        }
        .frame(width: 36, height: 44)
    }
}

// MARK: - Calendar Day Cell (カレンダー日セル)
// Individual day cell for calendar grid with borders

struct JohoCalendarDayCell: View {
    let dayNumber: Int
    var isToday: Bool = false
    var isSelected: Bool = false
    var isInCurrentMonth: Bool = true
    var isHoliday: Bool = false
    var hasNotes: Bool = false
    var hasExpenses: Bool = false
    var hasTrips: Bool = false

    var body: some View {
        ZStack {
            // Background
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .fill(backgroundColor)

            // Border - ALL cells have borders
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(
                    JohoColors.black,
                    lineWidth: (isToday || isSelected) ? JohoDimensions.borderThick : JohoDimensions.borderThin
                )

            // Content
            VStack(spacing: 2) {
                Text("\(dayNumber)")
                    .font(JohoFont.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(textColor)
                    .monospacedDigit()

                // Event indicators
                HStack(spacing: 2) {
                    if isHoliday {
                        Circle()
                            .fill(JohoColors.pink)
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                    }
                    if hasNotes {
                        Circle()
                            .fill(JohoColors.yellow)
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                    }
                    if hasExpenses {
                        Circle()
                            .fill(JohoColors.green)
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                    }
                    if hasTrips {
                        Circle()
                            .fill(JohoColors.orange)
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                    }
                }
                .frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .opacity(isInCurrentMonth ? 1.0 : 0.4)
    }

    private var backgroundColor: Color {
        if isSelected { return JohoColors.black }
        if isToday { return JohoColors.yellow }
        return JohoColors.white
    }

    private var textColor: Color {
        if isSelected { return JohoColors.white }
        return JohoColors.black
    }
}

// MARK: - Action Menu Button (メニューボタン)
// Circular action button for toolbar

struct JohoActionButton: View {
    let icon: String
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
            .foregroundStyle(JohoColors.black)
            .frame(width: size, height: size)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: size * 0.3))
            .overlay(
                Squircle(cornerRadius: size * 0.3)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
            )
    }
}

// MARK: - Preview

#Preview("Joho Components") {
    ScrollView {
        VStack(spacing: JohoDimensions.spacingLG) {
            JohoPageHeader(
                title: "December 2025",
                badge: "WEEK 52",
                subtitle: "Year's end approaching"
            )

            JohoWeekBadge(weekNumber: 52)

            JohoSectionBox(title: "Holidays", zone: .holidays, icon: "star.fill") {
                Text("Christmas Eve")
                    .font(JohoFont.body)
                Text("Boxing Day")
                    .font(JohoFont.body)
            }

            JohoSectionBox(title: "Notes", zone: .notes, icon: "note.text") {
                Text("Remember to buy gifts")
                    .font(JohoFont.body)
            }

            JohoCard {
                VStack(spacing: JohoDimensions.spacingXS) {
                    JohoPill(text: "Total", style: .whiteOnBlack)
                    Text("$1,234.56")
                        .font(JohoFont.displayLarge)
                        .foregroundStyle(JohoColors.black)
                }
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: JohoDimensions.spacingSM) {
                JohoStatBox(value: "$456", label: "Food", zone: .trips)
                JohoStatBox(value: "$523", label: "Hotel", zone: .contacts)
                JohoStatBox(value: "$255", label: "Transit", zone: .expenses)
            }

            JohoListRow(
                title: "Flight to Tokyo",
                subtitle: "Dec 25 - Jan 2",
                icon: "airplane",
                zone: .trips,
                badge: "8 DAYS"
            )

            JohoListRow(
                title: "Christmas Party",
                subtitle: "December 24, 2025",
                icon: "star.fill",
                zone: .holidays
            )

            HStack(spacing: JohoDimensions.spacingSM) {
                JohoDayCell(day: 24, isToday: true, hasEvent: true)
                JohoDayCell(day: 25, hasEvent: true, eventColor: JohoColors.pink)
                JohoDayCell(day: 26, isSelected: true)
                JohoDayCell(day: 27)
            }
        }
        .padding(JohoDimensions.spacingLG)
    }
    .johoBackground()
}
