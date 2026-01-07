//
//  JohoDesignSystem.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Authentic Japanese Packaging Style
//  Inspired by Muhi, Rohto, and classic Japanese OTC medicine packaging
//

import SwiftUI

// MARK: - Hex Color Extension

extension Color {
    /// Thread-safe hex color initialization with proper error handling
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&int) else {
            self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
            return
        }

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(min(255, max(0, r))) / 255.0,
            green: Double(min(255, max(0, g))) / 255.0,
            blue: Double(min(255, max(0, b))) / 255.0,
            opacity: Double(min(255, max(0, a))) / 255.0
        )
    }
}

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

// MARK: - Page Header Colors (情報デザイン: Unique colors for page headers)
// These are DISTINCT from entry type colors - used for page/section identity

enum PageHeaderColor {
    case landing       // Warm Amber - today, now, present (情報デザイン: NOW semantic)
    case calendar      // Deep Indigo - time, structure
    case specialDays   // Rich Amber - celebration, golden
    case tools         // Teal - active, productivity
    case contacts      // Warm Brown - personal, human
    case settings      // Slate Blue - system, configuration

    /// Primary accent color for page headers (used in icon backgrounds, badges)
    var accent: Color {
        switch self {
        case .landing:      return Color(hex: "F59E0B")  // Warm Amber
        case .calendar:     return Color(hex: "4338CA")  // Deep Indigo
        case .specialDays:  return Color(hex: "D97706")  // Rich Amber
        case .tools:        return Color(hex: "0D9488")  // Teal
        case .contacts:     return Color(hex: "78350F")  // Warm Brown
        case .settings:     return Color(hex: "475569")  // Slate Blue
        }
    }

    /// Light tint for header backgrounds (20% opacity of accent)
    var lightBackground: Color {
        switch self {
        case .landing:      return Color(hex: "F59E0B").opacity(0.15)
        case .calendar:     return Color(hex: "4338CA").opacity(0.15)
        case .specialDays:  return Color(hex: "D97706").opacity(0.15)
        case .tools:        return Color(hex: "0D9488").opacity(0.15)
        case .contacts:     return Color(hex: "78350F").opacity(0.15)
        case .settings:     return Color(hex: "475569").opacity(0.15)
        }
    }

    /// Text color on this header (always high contrast)
    var textColor: Color {
        JohoColors.black
    }
}

// MARK: - App Background Options (AMOLED-friendly)
// User can choose background color for battery savings on OLED screens

enum AppBackgroundOption: String, CaseIterable, Identifiable {
    case trueBlack = "black"       // #000000 - Maximum AMOLED savings
    case darkNavy = "darkNavy"     // #1A1A2E - Current warm dark (legacy)
    case nearBlack = "nearBlack"   // #0A0A0F - Slightly warmer than pure black

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .trueBlack:  return Color(hex: "000000")
        case .darkNavy:   return Color(hex: "1A1A2E")
        case .nearBlack:  return Color(hex: "0A0A0F")
        }
    }

    var displayName: String {
        switch self {
        case .trueBlack:  return "True Black (AMOLED)"
        case .darkNavy:   return "Dark Navy"
        case .nearBlack:  return "Near Black"
        }
    }

    var description: String {
        switch self {
        case .trueBlack:  return "Maximum battery savings on OLED"
        case .darkNavy:   return "Warm dark blue (original)"
        case .nearBlack:  return "Softer than pure black"
        }
    }
}

// MARK: - 情報デザイン Color Scheme (夜間モード - AMOLED Dark Mode)
// Inverted 情報デザイン for AMOLED screens: WHITE text on BLACK backgrounds

/// 情報デザイン color scheme mode
/// - `.light`: Classic 情報デザイン - BLACK text on WHITE backgrounds
/// - `.dark`: Inverted 夜間モード - WHITE text on BLACK backgrounds (AMOLED optimized)
enum JohoColorMode: String, CaseIterable, Identifiable {
    case light = "light"   // Classic 情報デザイン
    case dark = "dark"     // 夜間モード (Night Mode)

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light Mode"
        case .dark: return "Dark Mode"
        }
    }

    var description: String {
        switch self {
        case .light: return "Classic black on white"
        case .dark: return "AMOLED optimized, white on black"
        }
    }
}

/// Dynamic colors that adapt to the current color mode
/// Use `@Environment(\.johoColorMode) var colorMode` then access `JohoScheme.colors(for: colorMode)`
struct JohoScheme {
    /// Primary content color (text, icons)
    let primary: Color
    /// Secondary content color (subtitles, hints)
    let secondary: Color
    /// Surface/container background color
    let surface: Color
    /// Border color for containers
    let border: Color
    /// Canvas/app background color
    let canvas: Color
    /// Inverted surface (for contrast elements)
    let surfaceInverted: Color
    /// Inverted primary (text on inverted surface)
    let primaryInverted: Color

    /// Get the color scheme for a given mode
    static func colors(for mode: JohoColorMode) -> JohoScheme {
        switch mode {
        case .light:
            return JohoScheme(
                primary: Color(hex: "000000"),       // Black text
                secondary: Color(hex: "000000").opacity(0.6),
                surface: Color(hex: "FFFFFF"),      // White containers
                border: Color(hex: "000000"),       // Black borders
                canvas: Color(hex: "1A1A2E"),       // Dark canvas (barely visible)
                surfaceInverted: Color(hex: "000000"),
                primaryInverted: Color(hex: "FFFFFF")
            )
        case .dark:
            return JohoScheme(
                primary: Color(hex: "FFFFFF"),       // White text
                secondary: Color(hex: "FFFFFF").opacity(0.6),
                surface: Color(hex: "000000"),      // Pure black containers (AMOLED)
                border: Color(hex: "FFFFFF"),       // White borders
                canvas: Color(hex: "000000"),       // Pure black canvas (AMOLED)
                surfaceInverted: Color(hex: "FFFFFF"),
                primaryInverted: Color(hex: "000000")
            )
        }
    }
}

/// Environment key for 情報デザイン color mode
private struct JohoColorModeKey: EnvironmentKey {
    static let defaultValue: JohoColorMode = .light
}

extension EnvironmentValues {
    var johoColorMode: JohoColorMode {
        get { self[JohoColorModeKey.self] }
        set { self[JohoColorModeKey.self] = newValue }
    }
}

extension View {
    /// Apply a specific 情報デザイン color mode to this view and its children
    func johoColorMode(_ mode: JohoColorMode) -> some View {
        environment(\.johoColorMode, mode)
    }
}

// MARK: - Section Zones (色分け)
// Each feature gets a distinct pastel background + BLACK border

enum SectionZone {
    case calendar    // Cyan - cool, organized (legacy)
    case notes       // Yellow - attention, ideas
    case expenses    // Green - money, growth
    case trips       // Blue - travel, adventure
    case holidays    // RED - celebration, holidays
    case observances // Orange - observances
    case birthdays   // PINK - birthdays (from Contacts)
    case contacts    // Cream - people, warmth
    case events      // Purple - personal events/countdowns
    case countdowns  // Purple (alias for events)
    case warning     // Orange - alerts

    /// 情報デザイン: Semantic background colors (from design-system.md)
    /// These are the PASTEL versions - no opacity needed
    var background: Color {
        switch self {
        case .calendar: return Color(hex: "A5F3FC")    // Cyan - Events/Calendar
        case .notes: return Color(hex: "FEF3C7")       // Cream - Notes
        case .expenses: return Color(hex: "BBF7D0")    // Green - Money
        case .trips: return Color(hex: "FED7AA")       // Orange - Movement/Travel
        case .holidays: return Color(hex: "FECDD3")    // Pink - Special Days/Holidays
        case .observances: return Color(hex: "FED7AA") // Orange - Observances
        case .birthdays: return Color(hex: "FECDD3")   // Pink - Birthdays
        case .contacts: return Color(hex: "E9D5FF")    // Purple - People
        case .events, .countdowns: return Color(hex: "A5F3FC") // Cyan - Events
        case .warning: return Color(hex: "FED7AA")     // Orange - Alerts
        }
    }

    /// 情報デザイン: Dark mode background colors (muted, works on black)
    /// Darker, saturated versions that maintain semantic meaning on black backgrounds
    var darkBackground: Color {
        switch self {
        case .calendar: return Color(hex: "164E63")    // Dark Cyan
        case .notes: return Color(hex: "78350F")       // Dark Amber
        case .expenses: return Color(hex: "14532D")    // Dark Green
        case .trips: return Color(hex: "7C2D12")       // Dark Orange
        case .holidays: return Color(hex: "831843")    // Dark Pink
        case .observances: return Color(hex: "7C2D12") // Dark Orange
        case .birthdays: return Color(hex: "831843")   // Dark Pink
        case .contacts: return Color(hex: "581C87")    // Dark Purple
        case .events, .countdowns: return Color(hex: "164E63") // Dark Cyan
        case .warning: return Color(hex: "7C2D12")     // Dark Orange
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
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    enum PillStyle {
        case blackOnWhite   // Surface pill, primary border, primary text
        case whiteOnBlack   // Primary pill, inverted text (most common)
        case colored(Color) // 情報デザイン: Surface pill, colored border, colored text (NOT inverted!)
        case coloredInverted(Color) // Inverted: Colored bg, appropriate text (use sparingly)
        case muted          // Muted background, muted text - for past dates (YESTERDAY, X DAYS AGO)
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
        case .blackOnWhite: return colors.primary
        case .whiteOnBlack: return colors.primaryInverted
        case .colored(let color): return color  // 情報デザイン: Colored text on surface
        case .coloredInverted(let color):
            // 情報デザイン: Black text on light backgrounds (yellow), white on dark
            return color == JohoColors.yellow ? JohoColors.black : JohoColors.white
        case .muted: return colors.primary.opacity(0.6)  // Muted text for past dates
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .blackOnWhite:
            Capsule()
                .fill(colors.surface)
                .overlay(Capsule().stroke(colors.border, lineWidth: 2))
        case .whiteOnBlack:
            Capsule()
                .fill(colors.primary)
        case .colored(let color):
            // 情報デザイン: Surface background, COLORED border (not inverted!)
            Capsule()
                .fill(colors.surface)
                .overlay(Capsule().stroke(color, lineWidth: 1.5))
        case .coloredInverted(let color):
            // Inverted style (use sparingly)
            Capsule()
                .fill(color)
                .overlay(Capsule().stroke(colors.border, lineWidth: 1.5))
        case .muted:
            // Muted gray for past dates (YESTERDAY, X DAYS AGO)
            Capsule()
                .fill(colors.primary.opacity(0.1))
                .overlay(Capsule().stroke(colors.border.opacity(0.3), lineWidth: 1.5))
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
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
                    .stroke(isFilled ? colors.border : color, lineWidth: size.borderWidth)
            )
    }
}

// MARK: - Section Box (区画)
// Colored compartment with title pill and thick border

struct JohoSectionBox<Content: View>: View {
    let title: String
    let zone: SectionZone
    // 情報デザイン: Removed redundant icon parameter
    // The pill label already communicates the section type
    // "Every visual element must serve a clear informational purpose."
    @ViewBuilder let content: Content
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            // Header with pill label only (情報デザイン: no redundant icon)
            JohoPill(text: title, style: .whiteOnBlack, size: .medium)

            // Content
            content
                .foregroundStyle(colors.primary)
        }
        .padding(JohoDimensions.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(zone.background)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
    }
}

// MARK: - Form Section (情報デザイン: Surface background for entry forms)
// Use for Add Trip, Add Expense, etc. - surface background with border

struct JohoFormSection<Content: View>: View {
    let title: String
    var icon: String? = nil
    var accentColor: Color = JohoColors.black
    @ViewBuilder let content: Content
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(spacing: 0) {
            // Header row with pill
            HStack(spacing: JohoDimensions.spacingSM) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(colors.primaryInverted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(colors.primary)
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
            .background(colors.surface)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: JohoDimensions.borderMedium)

            // Content area
            content
                .padding(14)
                .background(colors.surface)
        }
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
    }
}

// MARK: - Form Field (情報デザイン: Individual form row)

struct JohoFormField<Content: View>: View {
    let label: String
    var isOptional: Bool = false
    @ViewBuilder let content: Content
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(isOptional ? colors.primary.opacity(0.5) : colors.primary.opacity(0.7))

            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(colors.surface)
    }
}

// MARK: - Info Card (Surface card with border)
// For list items, detail cards

struct JohoCard<Content: View>: View {
    var cornerRadius: CGFloat = JohoDimensions.radiusMedium
    var borderWidth: CGFloat = JohoDimensions.borderMedium
    @ViewBuilder let content: Content
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        content
            .padding(JohoDimensions.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: cornerRadius))
            .overlay(
                Squircle(cornerRadius: cornerRadius)
                    .stroke(colors.border, lineWidth: borderWidth)
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
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        ZStack {
            // Background
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .fill(backgroundColor)

            // Border (always present, thicker when selected)
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(
                    colors.border,
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
                        .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        .padding(.bottom, 4)
                }
            }
        }
        .frame(width: 44, height: 44)
    }

    private var backgroundColor: Color {
        if isSelected { return colors.primary }
        if isToday { return JohoColors.yellow }
        return colors.surface
    }

    private var textColor: Color {
        if isSelected { return colors.primaryInverted }
        if isToday { return JohoColors.black }  // Yellow always gets black text
        return colors.primary
    }
}

// MARK: - Week Badge (Large week number display)

struct JohoWeekBadge: View {
    let weekNumber: Int
    var size: BadgeSize = .large
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
                .foregroundStyle(colors.primaryInverted.opacity(0.8))

            Text("\(weekNumber)")
                .font(size.numberFont)
                .foregroundStyle(colors.primaryInverted)
        }
        .frame(width: size.dimension, height: size.dimension)
        .background(colors.primary)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.primaryInverted, lineWidth: 2)
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
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Icon in colored squircle
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)  // Always black on colored backgrounds
                .frame(width: 40, height: 40)
                .background(zone.background)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                )

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.body)
                    .foregroundStyle(colors.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary.opacity(0.6))
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
                    .foregroundStyle(colors.primary)
            }
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }
}

// MARK: - Stat Box (統計)

struct JohoStatBox: View {
    let value: String
    let label: String
    let zone: SectionZone
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(spacing: JohoDimensions.spacingXS) {
            Text(value)
                .font(JohoFont.displaySmall)
                .foregroundStyle(JohoColors.black)  // Always black on colored backgrounds

            Text(label.uppercased())
                .font(JohoFont.labelSmall)
                .foregroundStyle(JohoColors.black.opacity(0.7))  // Always black on colored backgrounds
        }
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingMD)
        .background(zone.background)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }
}

// MARK: - Page Header
// 情報デザイン: Dynamic colors based on color mode

struct JohoPageHeader: View {
    let title: String
    var badge: String? = nil
    var subtitle: String? = nil
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            if let badge {
                JohoPill(text: badge, style: .whiteOnBlack, size: .large)
            }

            Text(title)
                .font(JohoFont.displayMedium)
                .foregroundStyle(colors.primary)

            if let subtitle {
                Text(subtitle)
                    .font(JohoFont.body)
                    .foregroundStyle(colors.primary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(JohoDimensions.spacingLG)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
    }
}

// MARK: - Editor Header (情報デザイン: Consistent header for all editor sheets)
// Pattern: [Back] [Icon Zone] Title/Subtitle [Save]
// Matches Star Page month detail view header pattern

struct JohoEditorHeader: View {
    let icon: String              // SF Symbol from SpecialDayType.defaultIcon
    let accentColor: Color        // From SpecialDayType.accentColor
    let lightBackground: Color    // From SpecialDayType.lightBackground (explicit light tint)
    let title: String             // e.g., "NEW EVENT" (UPPERCASE)
    let subtitle: String          // e.g., "Set date & details"
    let canSave: Bool             // Validation state for Save button
    let onBack: () -> Void
    let onSave: () -> Void
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(alignment: .center, spacing: JohoDimensions.spacingMD) {
            // Cancel button (44×44pt) - × (batsu) = Cancel in Japanese UI
            Button(action: onBack) {
                Text(JohoSymbols.batsu)  // ×
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(colors.primary)
                    .frame(width: 44, height: 44)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                    )
            }

            // Icon zone (52×52pt) - matches January 2026 pattern
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(accentColor)
                .frame(width: 52, height: 52)
                .background(lightBackground)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                )

            // Title area
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.headline)
                    .foregroundStyle(colors.primary)

                Text(subtitle)
                    .font(JohoFont.caption)
                    .foregroundStyle(colors.primary.opacity(0.7))
            }

            Spacer()

            // Confirm button (44×44pt) - ○ (maru) = Confirm in Japanese UI
            Button(action: onSave) {
                Text(JohoSymbols.maru)  // ○
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(canSave ? colors.primaryInverted : colors.primary.opacity(0.4))
                    .frame(width: 44, height: 44)
                    .background(canSave ? accentColor : colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                    )
            }
            .disabled(!canSave)
        }
        .padding(JohoDimensions.spacingLG)  // 16pt all sides
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)  // 3pt border
        )
    }
}

// MARK: - Metric Row (for stats display)

struct JohoMetricRow: View {
    let label: String
    let value: String
    var zone: SectionZone = .calendar
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack {
            Text(label)
                .font(JohoFont.body)
                .foregroundStyle(colors.primary)

            Spacer()

            Text(value)
                .font(JohoFont.monoMedium)
                .foregroundStyle(colors.primary)
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
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(JohoColors.black)  // Always black on colored backgrounds
            .frame(width: size, height: size)
            .background(zone.background)
            .clipShape(Squircle(cornerRadius: size * 0.25))
            .overlay(
                Squircle(cornerRadius: size * 0.25)
                    .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
            )
    }
}

// MARK: - Icon Button (Actionable circular button with semantic color)

/// 情報デザイン: Unified circular icon button for actions
/// Use semantic colors: cyan=message, purple=email, green=call, orange=trip
struct JohoIconButton: View {
    let icon: String
    let color: Color
    var foregroundColor: Color? = nil  // nil = auto (black on light, white on dark)
    var borderColor: Color? = nil      // nil = black
    var size: CGFloat = 36
    var borderWidth: CGFloat = 1
    let action: () -> Void

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    /// Auto-detect foreground color based on background brightness
    private var effectiveForeground: Color {
        if let fg = foregroundColor { return fg }
        // Dark backgrounds get white text, light backgrounds get black
        return color == JohoColors.black ? JohoColors.white.opacity(0.7) : JohoColors.black
    }

    private var effectiveBorder: Color {
        borderColor ?? JohoColors.black
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(effectiveForeground)
                .frame(width: size, height: size)
                .background(color)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(effectiveBorder, lineWidth: borderWidth)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search Field (情報デザイン styled search input)

/// 情報デザイン: Unified search field with squircle styling
struct JohoSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var zone: SectionZone = .calendar

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.5))

            TextField(placeholder, text: $text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JohoColors.black.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM + 2)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
        )
    }
}

// MARK: - Contact Action Buttons (Semantic action buttons for contacts)

/// 情報デザイン: Pre-configured contact action buttons
enum JohoContactAction {
    case message(phone: String)
    case email(address: String)
    case call(phone: String)

    var icon: String {
        switch self {
        case .message: return "message.fill"
        case .email: return "envelope.fill"
        case .call: return "phone.fill"
        }
    }

    var color: Color {
        switch self {
        case .message: return JohoColors.cyan
        case .email: return JohoColors.purple
        case .call: return JohoColors.green
        }
    }

    func execute() {
        let urlString: String
        switch self {
        case .message(let phone):
            urlString = "sms:\(phone)"
        case .email(let address):
            urlString = "mailto:\(address)"
        case .call(let phone):
            urlString = "tel:\(phone)"
        }
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct JohoContactActionButton: View {
    let action: JohoContactAction

    var body: some View {
        JohoIconButton(
            icon: action.icon,
            color: action.color,
            size: 36,
            borderWidth: 1
        ) {
            action.execute()
        }
    }
}

// MARK: - Toggle Row

struct JohoToggleRow: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    let zone: SectionZone
    @Binding var isOn: Bool
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            JohoIconBadge(icon: icon, zone: zone, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JohoFont.body)
                    .foregroundStyle(colors.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary.opacity(0.6))
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(zone.background)
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
    }
}

// MARK: - Divider

struct JohoDivider: View {
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        Rectangle()
            .fill(colors.border)
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
        case "DE": // Germany: Black pill, yellow text (Schwarz-Rot-Gold)
            return CountryColorScheme(
                backgroundColor: Color(hex: "000000"),
                textColor: Color(hex: "FFCC00"),
                borderColor: Color(hex: "DD0000"),
                code: "DE"
            )
        case "GB": // United Kingdom: Navy blue pill, white text (Union Jack)
            return CountryColorScheme(
                backgroundColor: Color(hex: "012169"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: Color(hex: "C8102E"),
                code: "UK"
            )
        case "FR": // France: Blue pill, white text (Tricolore)
            return CountryColorScheme(
                backgroundColor: Color(hex: "002395"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: Color(hex: "ED2939"),
                code: "FR"
            )
        case "IT": // Italy: Green pill, white text (Il Tricolore)
            return CountryColorScheme(
                backgroundColor: Color(hex: "008C45"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: Color(hex: "CD212A"),
                code: "IT"
            )
        case "NL": // Netherlands: Orange pill, white text (Oranje)
            return CountryColorScheme(
                backgroundColor: Color(hex: "AE1C28"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: Color(hex: "21468B"),
                code: "NL"
            )
        case "JP": // Japan: Red pill, white text (Hinomaru)
            return CountryColorScheme(
                backgroundColor: Color(hex: "BC002D"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: JohoColors.black,
                code: "JP"
            )
        case "HK": // Hong Kong: Red pill, white text (Bauhinia)
            return CountryColorScheme(
                backgroundColor: Color(hex: "DE2910"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: JohoColors.black,
                code: "HK"
            )
        case "CN": // China: Red pill, yellow text (五星红旗)
            return CountryColorScheme(
                backgroundColor: Color(hex: "DE2910"),
                textColor: Color(hex: "FFDE00"),
                borderColor: JohoColors.black,
                code: "CN"
            )
        case "TH": // Thailand: Blue pill, white text (ธงไตรรงค์)
            return CountryColorScheme(
                backgroundColor: Color(hex: "241D4F"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: Color(hex: "A51931"),
                code: "TH"
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

/// Standard 情報デザイン toggle switch with border
struct JohoToggle: View {
    @Binding var isOn: Bool
    var accentColor: Color = JohoColors.cyan
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isOn.toggle()
            }
            HapticManager.selection()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? accentColor : colors.primary.opacity(0.2))
                    .frame(width: 50, height: 28)
                    .overlay(
                        Capsule()
                            .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                    )

                Circle()
                    .fill(colors.surface)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
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
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)  // Always black on colored backgrounds
                .frame(width: 80, height: 80)
                .background(zone.background)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                )

            Text(title)
                .font(JohoFont.headline)
                .foregroundStyle(colors.primary)

            Text(message)
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.primary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(JohoDimensions.spacingXL)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply dark Joho background (respects user's AMOLED preference)
    func johoBackground() -> some View {
        let savedOption = UserDefaults.standard.string(forKey: "appBackgroundColor") ?? "black"
        let option = AppBackgroundOption(rawValue: savedOption) ?? .trueBlack
        return self
            .background(option.color)
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
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
                // Large day number (always black on yellow)
                Text("\(dayNumber)")
                    .font(JohoFont.displayLarge)
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 72)

                // Vertical separator (always black on yellow)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 3, height: 56)

                // Date info (always black on yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text(weekdayName)
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)

                    Text("\(monthName) \(yearString)")
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                }

                Spacer()

                // Week badge (inverted colors)
                VStack(spacing: 0) {
                    Text("WEEK")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(colors.primaryInverted.opacity(0.8))

                    Text("\(weekNumber)")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(colors.primaryInverted)
                }
                .frame(width: 56, height: 56)
                .background(colors.primary)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            }
            .padding(JohoDimensions.spacingMD)
            .background(JohoColors.yellow)  // Yellow is semantic color - always yellow
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
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
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Previous month button
            Button(action: { onPrevious?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 36, height: 36)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                    )
            }
            .buttonStyle(.plain)

            // Month/Year button
            Button(action: { onTap?() }) {
                HStack(spacing: 6) {
                    Text(monthName.uppercased())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .lineLimit(1)

                    Text(verbatim: "\(year)")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary.opacity(0.7))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(colors.primary.opacity(0.5))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                )
            }
            .buttonStyle(.plain)

            // Next month button
            Button(action: { onNext?() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 36, height: 36)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
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

// MARK: - Hotel Clock Widget (情報デザイン)

/// Prominent world clock display like hotel reception or airport wall
/// Used in the Onsen landing page Bento grid
struct HotelClockWidget: View {
    let clock: WorldClock
    var isLarge: Bool = false

    private var timeSize: CGFloat { isLarge ? 48 : 32 }
    private var codeSize: CGFloat { isLarge ? 12 : 10 }

    var body: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            // City code pill
            Text(clock.cityCode)
                .font(.system(size: codeSize, weight: .black, design: .rounded))
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(JohoColors.black)
                .clipShape(Capsule())

            // Large time display
            Text(clock.formattedTime)
                .font(.system(size: timeSize, weight: .bold, design: .monospaced))
                .foregroundStyle(JohoColors.black)
                .monospacedDigit()

            // City name
            Text(clock.cityName.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(JohoColors.black.opacity(0.7))

            // Offset badge + Day/Night
            HStack(spacing: 6) {
                // Offset
                Text(clock.offsetFromLocal)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        clock.offsetFromLocal == "LOCAL"
                            ? JohoColors.green
                            : JohoColors.black.opacity(0.6)
                    )
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        clock.offsetFromLocal == "LOCAL"
                            ? JohoColors.green.opacity(0.15)
                            : JohoColors.black.opacity(0.05)
                    )
                    .clipShape(Capsule())

                // Day/Night icon
                Image(systemName: clock.isDaytime ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(
                        clock.isDaytime
                            ? JohoColors.yellow
                            : JohoColors.black.opacity(0.6)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(JohoDimensions.spacingMD)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
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

            JohoSectionBox(title: "Holidays", zone: .holidays) {
                Text("Christmas Eve")
                    .font(JohoFont.body)
                Text("Boxing Day")
                    .font(JohoFont.body)
            }

            JohoSectionBox(title: "Notes", zone: .notes) {
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
