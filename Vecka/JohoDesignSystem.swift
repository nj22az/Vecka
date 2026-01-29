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
// 情報デザイン Option B: 6-Color Simplified Palette
// Each color has ONE clear meaning to reduce cognitive load

enum JohoColors {
    // Primary contrast pair - ALWAYS use these for text
    static let black = Color(hex: "000000")
    static let white = Color(hex: "FFFFFF")

    // ═══════════════════════════════════════════════════════════════════
    // 情報デザイン: 6-COLOR SEMANTIC PALETTE
    // ═══════════════════════════════════════════════════════════════════
    // 1. YELLOW  = 今 (ima)   - NOW: Today, current moment, personal notes
    // 2. CYAN    = 予定 (yotei) - SCHEDULED: Events, trips, appointments
    // 3. PINK    = 祝 (iwai)  - CELEBRATION: Holidays, birthdays, special days
    // 4. GREEN   = 金 (kane)  - MONEY: Expenses, financial items
    // 5. PURPLE  = 人 (hito)  - PEOPLE: Contacts, relationships
    // 6. RED     = 警告       - ALERT: Warnings, errors (system only)
    // ═══════════════════════════════════════════════════════════════════

    static let yellow = Color(hex: "FFE566")    // NOW - today, notes, present moment
    static let cyan = Color(hex: "A5F3FC")      // SCHEDULED - events, trips, calendar
    static let pink = Color(hex: "FECDD3")      // CELEBRATION - holidays, birthdays
    static let green = Color(hex: "BBF7D0")     // MONEY - expenses
    static let purple = Color(hex: "E9D5FF")    // PEOPLE - contacts
    static let red = Color(hex: "E53935")       // ALERT - warnings, errors (system)

    // Light tints for bento box backgrounds
    static let yellowLight = Color(hex: "FEF3C7")   // Light yellow for notes
    static let cyanLight = Color(hex: "CFFAFE")     // Light cyan for events
    static let pinkLight = Color(hex: "FED7E2")     // Light pink for celebrations
    static let greenLight = Color(hex: "D1FAE5")    // Light green for expenses
    static let purpleLight = Color(hex: "F3E8FF")   // Light purple for contacts
    static let redLight = Color(hex: "FECACA")      // Light red for alerts

    // DEPRECATED: Use yellow instead (kept for migration)
    @available(*, deprecated, message: "Use yellow - notes are 'present moment' items")
    static let cream = Color(hex: "FFE566")

    // DEPRECATED: Use cyan instead (kept for migration)
    @available(*, deprecated, message: "Use cyan - trips are scheduled time items")
    static let orange = Color(hex: "A5F3FC")

    // Type-specific indicator colors (darker versions for visibility on white)
    static let tripBlue = Color(hex: "3182CE")     // TRP indicator on calendar
    static let eventPurple = Color(hex: "805AD5")  // EVT indicator on calendar

    // App base (dark mode base, but sections are colorful)
    static let background = Color(hex: "1A1A2E")
    static let surface = Color(hex: "FFFFFF")   // Cards are WHITE with black borders

    // Form & Input semantic colors
    static let inputBackground = Color(hex: "F5F5F5")  // Light gray for text fields
    static let notesBackground = Color(hex: "FFE566").opacity(0.3)  // Yellow tint for notes

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

    /// Text color for the specified color mode
    func textColor(for mode: JohoColorMode) -> Color {
        JohoScheme.colors(for: mode).primary
    }
}

// MARK: - System UI Accent (情報デザイン: Neutral navigation elements)
// Used for month/year pickers, generic buttons, navigation controls
// These are NOT tied to semantic content types

enum SystemUIAccent: String, CaseIterable, Identifiable {
    case black = "black"           // Pure authority - stark but clear
    case slate = "slate"           // Soft professional - Settings-like
    case indigo = "indigo"         // Deep calm - Calendar header inspired
    case navy = "navy"             // Warm neutral - softer than black
    case blue = "blue"             // Information blue - Japanese wayfinding style

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .black:  return Color(hex: "000000")  // Pure black
        case .slate:  return Color(hex: "475569")  // Slate gray (Settings header)
        case .indigo: return Color(hex: "4338CA")  // Deep indigo (Calendar header)
        case .navy:   return Color(hex: "1E3A5F")  // Soft navy
        case .blue:   return Color(hex: "3B82F6")  // UI blue (wayfinding)
        }
    }

    var displayName: String {
        switch self {
        case .black:  return "Black"
        case .slate:  return "Slate"
        case .indigo: return "Indigo"
        case .navy:   return "Navy"
        case .blue:   return "Blue"
        }
    }

    var description: String {
        switch self {
        case .black:  return "Pure authority"
        case .slate:  return "Soft professional"
        case .indigo: return "Deep calm"
        case .navy:   return "Warm neutral"
        case .blue:   return "Wayfinding"
        }
    }

    /// Japanese design principle this represents
    var japaneseName: String {
        switch self {
        case .black:  return "権威"      // Authority
        case .slate:  return "穏やか"    // Calm/gentle
        case .indigo: return "時"        // Time/structure
        case .navy:   return "深み"      // Depth
        case .blue:   return "案内"      // Guidance
        }
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
    /// Input/text field background color
    let inputBackground: Color

    /// Get the color scheme for a given mode
    static func colors(for mode: JohoColorMode) -> JohoScheme {
        switch mode {
        case .light:
            return JohoScheme(
                primary: Color(hex: "000000"),       // Black text
                secondary: Color(hex: "000000").opacity(0.6),
                surface: Color(hex: "FFFFFF"),      // White containers
                border: Color(hex: "000000"),       // Black borders
                canvas: Color(hex: "FFFFFF"),       // White canvas (light mode)
                surfaceInverted: Color(hex: "000000"),
                primaryInverted: Color(hex: "FFFFFF"),
                inputBackground: Color(hex: "F5F5F5")  // Light gray for text fields
            )
        case .dark:
            return JohoScheme(
                primary: Color(hex: "F0F0F0"),       // Soft off-white (less eye strain)
                secondary: Color(hex: "F0F0F0").opacity(0.5),
                surface: Color(hex: "1C1C1E"),      // Elevated dark gray (Apple dark elevated)
                border: Color(hex: "48484A"),       // Medium gray borders (visible, not harsh)
                canvas: Color(hex: "000000"),       // True black (OLED canvas)
                surfaceInverted: Color(hex: "F0F0F0"),
                primaryInverted: Color(hex: "1C1C1E"),
                inputBackground: Color(hex: "2C2C2E")  // Dark input fields
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
// 情報デザイン Option B: 6-Color Simplified Zones
// Each zone maps to ONE semantic color for reduced cognitive load

enum SectionZone {
    // ═══════════════════════════════════════════════════════════════════
    // 6 SEMANTIC ZONES (matching 6-color palette)
    // ═══════════════════════════════════════════════════════════════════
    case notes       // YELLOW - present moment, personal items
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

        // CYAN = SCHEDULED (all time-based items + cultural observances)
        case .calendar, .trips, .events, .countdowns, .observances:
            return JohoColors.cyan

        // PINK = CELEBRATION (holidays and birthdays)
        case .holidays, .birthdays:
            return JohoColors.pink

        // GREEN = MONEY
        case .expenses:
            return JohoColors.green

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
        case .calendar, .trips, .events, .countdowns, .observances:
            return JohoColors.cyan.opacity(0.25)          // Cool teal tint
        case .holidays, .birthdays:
            return JohoColors.pink.opacity(0.25)          // Soft rose tint
        case .expenses:
            return JohoColors.green.opacity(0.25)         // Mint tint
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

    @Environment(\.johoColorMode) private var colorMode

    private var fillColor: Color {
        if let bg = backgroundColor { return bg }
        if let z = zone { return z.background(for: colorMode) }
        return JohoScheme.colors(for: colorMode).surface
    }

    var body: some View {
        let colors = JohoScheme.colors(for: colorMode)
        content
            .padding(padding)
            .background(fillColor)
            .johoBordered(cornerRadius: cornerRadius, borderWidth: borderWidth, borderColor: colors.border)
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

// MARK: - Flow Layout (Wrapping horizontal layout)
// 情報デザイン: Chips wrap to next line instead of scrolling

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Wrap to next line if needed
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return (CGSize(width: totalWidth, height: currentY + lineHeight), positions)
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
        .background(zone.background(for: colorMode))
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick, borderColor: colors.border)
    }
}

// MARK: - Form Section (情報デザイン: Surface background for entry forms)
// Use for Add Trip, Add Expense, etc. - surface background with border

struct JohoFormSection<Content: View>: View {
    let title: String
    var icon: String? = nil
    var accentColor: Color? = nil
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
                        .foregroundStyle(accentColor ?? colors.primary)
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
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderThick, borderColor: colors.border)
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
            .johoBordered(cornerRadius: cornerRadius, borderWidth: borderWidth, borderColor: colors.border)
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
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: 2, borderColor: colors.primaryInverted)
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
                .foregroundStyle(zone.textColor(for: colorMode))
                .frame(width: 40, height: 40)
                .background(zone.background(for: colorMode))
                .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderThin, borderColor: colors.border)

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
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
    }
}

// MARK: - Stat Box (統計)

struct JohoStatBox: View {
    let value: String
    let label: String
    let zone: SectionZone
    var isActive: Bool = true  // 情報デザイン: Visual feedback for filter state
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        VStack(spacing: JohoDimensions.spacingXS) {
            Text(value)
                .font(JohoFont.displaySmall)
                .foregroundStyle(zone.textColor(for: colorMode))

            Text(label.uppercased())
                .font(JohoFont.labelSmall)
                .foregroundStyle(zone.textColor(for: colorMode).opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingMD)
        .background(isActive ? zone.background(for: colorMode) : colors.inputBackground)
        .opacity(isActive ? 1.0 : 0.5)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
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
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick, borderColor: colors.border)
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
                    .johoTouchTarget()
                    .background(colors.surface)
                    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderThin, borderColor: colors.border)
            }

            // Icon zone (52×52pt) - matches January 2026 pattern
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(accentColor)
                .frame(width: 52, height: 52)
                .background(lightBackground)
                .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)

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
                    .johoTouchTarget()
                    .background(canSave ? accentColor : colors.surface)
                    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
            }
            .disabled(!canSave)
        }
        .padding(JohoDimensions.spacingLG)  // 16pt all sides
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick, borderColor: colors.border)
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
        .background(zone.background(for: colorMode).opacity(0.3))
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
            .foregroundStyle(zone.textColor(for: colorMode))
            .frame(width: size, height: size)
            .background(zone.background(for: colorMode))
            .johoBordered(cornerRadius: size * 0.25, borderWidth: JohoDimensions.borderThin, borderColor: colors.border)
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
        return color == colors.primary ? colors.primaryInverted.opacity(0.7) : colors.primary
    }

    private var effectiveBorder: Color {
        borderColor ?? colors.border
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
                .foregroundStyle(colors.primary.opacity(0.5))

            TextField(placeholder, text: $text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)

            if text.isNotEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(colors.primary.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM + 2)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderThin)
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
                .tint(zone.background(for: colorMode))
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
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
        case "NORDIC": // Nordic: Dark blue pill, white text (Nordic Council colors)
            return CountryColorScheme(
                backgroundColor: Color(hex: "003087"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: JohoColors.black,
                code: "NORD"
            )
        case "NO": // Norway: Red pill, white text (Norwegian flag)
            return CountryColorScheme(
                backgroundColor: Color(hex: "BA0C2F"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: Color(hex: "00205B"),
                code: "NOR"
            )
        case "DK": // Denmark: Red pill, white text (Dannebrog)
            return CountryColorScheme(
                backgroundColor: Color(hex: "C8102E"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: JohoColors.black,
                code: "DK"
            )
        case "FI": // Finland: Blue pill, white text (Siniristilippu)
            return CountryColorScheme(
                backgroundColor: Color(hex: "003580"),
                textColor: Color(hex: "FFFFFF"),
                borderColor: JohoColors.black,
                code: "FI"
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
            withAnimation(.easeInOut(duration: 0.2)) {
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
                .foregroundStyle(zone.textColor(for: colorMode))
                .frame(width: 80, height: 80)
                .background(zone.background(for: colorMode))
                .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)

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

// MARK: - String Extensions (情報デザイン Utilities)

extension String {
    /// Trimmed string with whitespace and newlines removed
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Check if trimmed string is empty
    var isTrimmedEmpty: Bool {
        trimmed.isEmpty
    }
}

// MARK: - Collection Extensions (情報デザイン Utilities)

extension Collection {
    /// More readable alternative to !isEmpty
    var isNotEmpty: Bool { !isEmpty }
}

// MARK: - View Extensions

/// Environment-aware border modifier — resolves border color from JohoScheme automatically
private struct JohoBorderedModifier: ViewModifier {
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let explicitBorderColor: Color?

    @Environment(\.johoColorMode) private var colorMode

    func body(content: Content) -> some View {
        let resolvedColor = explicitBorderColor ?? JohoScheme.colors(for: colorMode).border
        content
            .clipShape(Squircle(cornerRadius: cornerRadius))
            .overlay(
                Squircle(cornerRadius: cornerRadius)
                    .stroke(resolvedColor, lineWidth: borderWidth)
            )
    }
}

extension View {
    /// 情報デザイン: Apply squircle clip with border in one modifier
    /// Automatically resolves border color from JohoScheme (environment-aware)
    /// Pass explicit borderColor only to override the scheme color
    func johoBordered(
        cornerRadius: CGFloat = JohoDimensions.radiusMedium,
        borderWidth: CGFloat = JohoDimensions.borderMedium,
        borderColor: Color? = nil
    ) -> some View {
        modifier(JohoBorderedModifier(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            explicitBorderColor: borderColor
        ))
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - 情報デザイン ViewModifier Pattern Extensions
    // Inspired by Swift Playgrounds ThemeViews.swift ViewModifier pattern
    // ═══════════════════════════════════════════════════════════════════════════

    /// 情報デザイン: Bento box card styling
    /// White background with black border - the core card pattern
    /// Usage: `.johoBento()` or `.johoBento(padding: 16, cornerRadius: 16)`
    func johoBento(
        padding: CGFloat = JohoDimensions.spacingMD,
        cornerRadius: CGFloat = JohoDimensions.radiusMedium,
        borderWidth: CGFloat = JohoDimensions.borderMedium
    ) -> some View {
        modifier(JohoBentoModifier(
            padding: padding,
            cornerRadius: cornerRadius,
            borderWidth: borderWidth
        ))
    }

    /// 情報デザイン: Accented bento box with semantic color
    /// Colored background tint with black border
    /// Usage: `.johoAccentedBento(color: JohoColors.cyan)`
    func johoAccentedBento(
        color: Color,
        opacity: Double = 0.15,
        padding: CGFloat = JohoDimensions.spacingMD,
        cornerRadius: CGFloat = JohoDimensions.radiusMedium,
        borderWidth: CGFloat = JohoDimensions.borderMedium
    ) -> some View {
        modifier(JohoAccentedBentoModifier(
            accentColor: color,
            opacity: opacity,
            padding: padding,
            cornerRadius: cornerRadius,
            borderWidth: borderWidth
        ))
    }

    /// 情報デザイン: Section header styling
    /// Colored background header strip for bento sections
    /// Usage: `.johoSectionHeader(color: JohoColors.cyan)`
    func johoSectionHeader(
        color: Color,
        opacity: Double = 0.3,
        height: CGFloat = 32
    ) -> some View {
        modifier(JohoSectionHeaderModifier(
            accentColor: color,
            opacity: opacity,
            height: height
        ))
    }

    /// 情報デザイン: Interactive cell styling
    /// For tappable list items and buttons with hover/press states
    /// Usage: `.johoInteractiveCell()` or `.johoInteractiveCell(isSelected: true)`
    func johoInteractiveCell(
        isSelected: Bool = false,
        isHighlighted: Bool = false,
        cornerRadius: CGFloat = JohoDimensions.radiusMedium
    ) -> some View {
        modifier(JohoInteractiveCellModifier(
            isSelected: isSelected,
            isHighlighted: isHighlighted,
            cornerRadius: cornerRadius
        ))
    }

    /// 情報デザイン: Icon badge styling
    /// Colored icon container with border
    /// Usage: `.johoIconBadge(color: JohoColors.cyan, size: 40)`
    func johoIconBadge(
        color: Color,
        size: CGFloat = 32
    ) -> some View {
        modifier(JohoIconBadgeModifier(
            backgroundColor: color,
            size: size
        ))
    }

    /// 情報デザイン: Pill/tag styling
    /// Capsule shape with border for labels and tags
    /// Usage: `.johoPillStyle(color: JohoColors.black)`
    func johoPillStyle(
        backgroundColor: Color = JohoColors.black,
        foregroundColor: Color = JohoColors.white,
        borderColor: Color? = nil
    ) -> some View {
        modifier(JohoPillModifier(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            borderColor: borderColor
        ))
    }

    /// 情報デザイン: Minimum 44×44pt touch target (Apple HIG requirement)
    func johoTouchTarget(_ size: CGFloat = 44) -> some View {
        frame(width: size, height: size)
    }

    /// Apply dark Joho background (respects user's AMOLED preference and color mode)
    func johoBackground() -> some View {
        modifier(JohoBackgroundModifier())
    }

    /// Standard Joho navigation bar styling
    func johoNavigation(title: String = "") -> some View {
        modifier(JohoNavigationModifier(title: title))
    }

    /// Joho List styling
    func johoListStyle() -> some View {
        modifier(JohoListStyleModifier())
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
            .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick, borderColor: colors.border)
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
            // Previous month button (情報デザイン: Minimum 44pt touch target)
            Button(action: { onPrevious?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .johoTouchTarget()
                    .background(colors.surface)
                    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
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
                .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
            }
            .buttonStyle(.plain)

            // Next month button (情報デザイン: Minimum 44pt touch target)
            Button(action: { onNext?() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .johoTouchTarget()
                    .background(colors.surface)
                    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Calendar Container (カレンダー枠)
// White container with thick black border for the entire calendar grid

struct JohoCalendarContainer<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        content
            .padding(JohoDimensions.spacingSM)
            .background(colors.surface)
            .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick, borderColor: colors.border)
    }
}

// MARK: - Weekday Header (曜日ヘッダー)
// Header row showing weekday abbreviations

struct JohoWeekdayHeader: View {
    let weekdays: [String] // ["M", "T", "W", "T", "F", "S", "S"]
    var showWeekColumn: Bool = true
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingXS) {
            // Week column header
            if showWeekColumn {
                Text("W")
                    .font(JohoFont.label)
                    .foregroundStyle(colors.primary)
                    .frame(width: 36, height: 28)
                    .background(colors.primary.opacity(0.1))
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            }

            // Day headers
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(JohoFont.label)
                    .foregroundStyle(colors.primary)
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
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        ZStack {
            // Background
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .fill(colors.primary)

            // Border when current/selected
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(
                    (isCurrentWeek || isSelected) ? colors.primaryInverted : colors.primary.opacity(0.3),
                    lineWidth: (isCurrentWeek || isSelected) ? JohoDimensions.borderMedium : JohoDimensions.borderThin
                )

            // Week number - smaller font for better padding with 2-digit numbers
            Text("\(weekNumber)")
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.primaryInverted)
                .monospacedDigit()
        }
        // 情報デザイン: Minimum 44pt touch target in both dimensions
        .frame(width: 44, height: 44)
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
    var hasEvents: Bool = false  // NEW: Generic events indicator
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        ZStack {
            // Background
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .fill(backgroundColor)

            // Border - ALL cells have borders
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(
                    colors.border,
                    lineWidth: (isToday || isSelected) ? JohoDimensions.borderThick : JohoDimensions.borderThin
                )

            // Content
            VStack(spacing: 2) {
                Text("\(dayNumber)")
                    .font(JohoFont.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(textColor)
                    .monospacedDigit()

                // Event indicators (6-color palette)
                // YELLOW=notes, CYAN=scheduled(trips+events), PINK=celebration, GREEN=money
                HStack(spacing: 2) {
                    if isHoliday {
                        Circle()
                            .fill(JohoColors.pink)      // CELEBRATION
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                    }
                    if hasNotes {
                        Circle()
                            .fill(JohoColors.yellow)    // NOW
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                    }
                    if hasExpenses {
                        Circle()
                            .fill(JohoColors.green)     // MONEY
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                    }
                    if hasTrips || hasEvents {
                        Circle()
                            .fill(JohoColors.cyan)      // SCHEDULED (unified)
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
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
        if isSelected { return colors.primary }
        if isToday { return JohoColors.yellow }
        return colors.surface
    }

    private var textColor: Color {
        if isSelected { return colors.primaryInverted }
        if isToday { return JohoColors.black }  // Black on yellow is always readable
        return colors.primary
    }
}

// MARK: - Action Menu Button (メニューボタン)
// Circular action button for toolbar

struct JohoActionButton: View {
    let icon: String
    var size: CGFloat = 44
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
            .foregroundStyle(colors.primary)
            .frame(width: size, height: size)
            .background(colors.surface)
            .johoBordered(cornerRadius: size * 0.3, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
    }
}

// MARK: - Hotel Clock Widget (情報デザイン)

/// Prominent world clock display like hotel reception or airport wall
/// Used in the Onsen landing page Bento grid
struct HotelClockWidget: View {
    let clock: WorldClock
    var isLarge: Bool = false
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var timeSize: CGFloat { isLarge ? 48 : 32 }
    private var codeSize: CGFloat { isLarge ? 12 : 10 }

    var body: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            // City code pill
            Text(clock.cityCode)
                .font(.system(size: codeSize, weight: .black, design: .rounded))
                .foregroundStyle(colors.primaryInverted)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(colors.primary)
                .clipShape(Capsule())

            // Large time display
            Text(clock.formattedTime)
                .font(.system(size: timeSize, weight: .bold, design: .monospaced))
                .foregroundStyle(colors.primary)
                .monospacedDigit()

            // City name
            Text(clock.cityName.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(colors.primary.opacity(0.7))

            // Offset badge + Day/Night
            HStack(spacing: 6) {
                // Offset
                Text(clock.offsetFromLocal)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        clock.offsetFromLocal == "LOCAL"
                            ? JohoColors.green
                            : colors.primary.opacity(0.6)
                    )
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        clock.offsetFromLocal == "LOCAL"
                            ? JohoColors.green.opacity(0.15)
                            : colors.primary.opacity(0.05)
                    )
                    .clipShape(Capsule())

                // Day/Night icon
                Image(systemName: clock.isDaytime ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(
                        clock.isDaytime
                            ? JohoColors.yellow
                            : colors.primary.opacity(0.6)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
    }
}

// MARK: - Year Picker

/// 情報デザイン: Compact year stepper with chevron buttons
/// Reusable across Star Page, Calendar, Expenses, Countdowns, etc.
struct JohoYearPicker: View {
    @Binding var year: Int
    var minYear: Int = 1900
    var maxYear: Int = 2100

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: 4) {
            // Decrement button
            Button {
                if year > minYear {
                    withAnimation(.easeInOut(duration: 0.15)) { year -= 1 }
                    HapticManager.selection()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(year > minYear ? colors.primary : colors.primary.opacity(0.3))
                    .frame(width: 24, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(year <= minYear)

            // Year text - tap to reset to current year
            let currentYear = Calendar.current.component(.year, from: Date())
            let isCurrentYear = year == currentYear

            Button {
                if !isCurrentYear {
                    withAnimation(.easeInOut(duration: 0.15)) { year = currentYear }
                    HapticManager.notification(.success)
                }
            } label: {
                Text(String(year))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isCurrentYear ? colors.primary : colors.primary.opacity(0.7))
                    .underline(!isCurrentYear, color: colors.primary.opacity(0.3))
                    .fixedSize()
            }
            .buttonStyle(.plain)

            // Increment button
            Button {
                if year < maxYear {
                    withAnimation(.easeInOut(duration: 0.15)) { year += 1 }
                    HapticManager.selection()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(year < maxYear ? colors.primary : colors.primary.opacity(0.3))
                    .frame(width: 24, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(year >= maxYear)
        }
    }
}

// MARK: - Type Selector (Unified Entry)

/// 情報デザイン: Neutral dropdown type selector for unified entry form
/// Black/white only - no semantic colors in the selector chrome
struct JohoTypeSelector: View {
    @Binding var selectedType: EntryType
    var onTypeChange: ((EntryType) -> Void)? = nil

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        Menu {
            // 情報デザイン: Text-only menu items - icon is already visible in selector
            ForEach(EntryType.allCases) { type in
                Button {
                    selectedType = type
                    onTypeChange?(type)
                    HapticManager.selection()
                } label: {
                    Text(type.displayName)
                }
            }
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Icon (no nested border - simpler, no flashing)
                Image(systemName: selectedType.icon)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 28, height: 28)

                // Chevron
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.6))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(colors.surface)
            .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
        }
    }
}

/// 情報デザイン: Suggestion pill for smart type detection
/// Appears when input matches a pattern, tappable to switch type
struct JohoTypeSuggestionPill: View {
    let suggestedType: EntryType
    let onAccept: () -> Void
    let onDismiss: () -> Void

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Sparkle icon
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary.opacity(0.6))

            // Suggestion text
            Text("Looks like \(suggestedType.displayName.lowercased())?")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary.opacity(0.8))

            // Accept button
            Button(action: onAccept) {
                HStack(spacing: 4) {
                    Image(systemName: suggestedType.icon)
                    Text("Switch")
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primaryInverted)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(colors.primary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(colors.primary.opacity(0.4))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(colors.primary.opacity(0.05))
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1, borderColor: colors.border.opacity(0.3))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - 情報デザイン ViewModifier Implementations
// Pattern from Swift Playgrounds "Laying Out Views" ThemeViews.swift

/// Background modifier that uses user's AMOLED background preference
/// Canvas is always dark (for AMOLED battery savings) - Light/Dark only affects cards/text
struct JohoBackgroundModifier: ViewModifier {
    @AppStorage("appBackgroundColor") private var appBackgroundColor = "black"

    private var backgroundColor: Color {
        (AppBackgroundOption(rawValue: appBackgroundColor) ?? .trueBlack).color
    }

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .scrollContentBackground(.hidden)
    }
}

/// Navigation bar modifier that adapts to color mode
struct JohoNavigationModifier: ViewModifier {
    let title: String
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(colors.primary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorMode == .dark ? .light : .dark, for: .navigationBar)
    }
}

/// List style modifier that adapts to color mode
struct JohoListStyleModifier: ViewModifier {
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    func body(content: Content) -> some View {
        content
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(colors.canvas)
    }
}

/// Bento box card modifier - white background with black border
struct JohoBentoModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(colors.surface)
            .johoBordered(
                cornerRadius: cornerRadius,
                borderWidth: borderWidth,
                borderColor: colors.border
            )
    }
}

/// Accented bento box modifier - colored background tint with black border
struct JohoAccentedBentoModifier: ViewModifier {
    let accentColor: Color
    let opacity: Double
    let padding: CGFloat
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(accentColor.opacity(opacity))
            .johoBordered(
                cornerRadius: cornerRadius,
                borderWidth: borderWidth,
                borderColor: colors.border
            )
    }
}

/// Section header modifier - colored background strip
struct JohoSectionHeaderModifier: ViewModifier {
    let accentColor: Color
    let opacity: Double
    let height: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(height: height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accentColor.opacity(opacity))
    }
}

/// Interactive cell modifier - for tappable items with selection state
struct JohoInteractiveCellModifier: ViewModifier {
    let isSelected: Bool
    let isHighlighted: Bool
    let cornerRadius: CGFloat

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var backgroundColor: Color {
        if isSelected { return colors.primary }
        if isHighlighted { return colors.primary.opacity(0.1) }
        return colors.surface
    }

    private var borderWidth: CGFloat {
        isSelected ? JohoDimensions.borderThick : JohoDimensions.borderMedium
    }

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .johoBordered(
                cornerRadius: cornerRadius,
                borderWidth: borderWidth,
                borderColor: colors.border
            )
    }
}

/// Icon badge modifier - colored icon container
struct JohoIconBadgeModifier: ViewModifier {
    let backgroundColor: Color
    let size: CGFloat

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(colors.primary)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .johoBordered(
                cornerRadius: size * 0.25,
                borderWidth: JohoDimensions.borderThin,
                borderColor: colors.border
            )
    }
}

/// Pill styling modifier - capsule with optional border
struct JohoPillModifier: ViewModifier {
    let backgroundColor: Color
    let foregroundColor: Color
    let borderColor: Color?

    func body(content: Content) -> some View {
        content
            .font(JohoFont.label)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Group {
                    if let border = borderColor {
                        Capsule().stroke(border, lineWidth: 1.5)
                    }
                }
            )
    }
}

// MARK: - JohoCalendarPicker (情報デザイン: Unified Date Picker)

/// A 情報デザイン compliant calendar picker matching the Calendar page design
/// Features: Week numbers, bordered cells, yellow today highlight, week selection
struct JohoCalendarPicker: View {
    @Binding var selectedDate: Date
    let accentColor: Color
    let onDone: () -> Void
    let onCancel: () -> Void

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    @State private var displayedMonth: Date

    init(selectedDate: Binding<Date>, accentColor: Color = JohoColors.pink, onDone: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self._selectedDate = selectedDate
        self.accentColor = accentColor
        self.onDone = onDone
        self.onCancel = onCancel
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue)
    }

    private let calendar = Calendar.iso8601
    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(spacing: 0) {
            // Header with buttons
            headerRow

            Rectangle().fill(colors.border).frame(height: 2)

            // Month navigation
            monthNavigationRow

            Rectangle().fill(colors.border).frame(height: 1.5)

            // Calendar grid
            calendarGrid
                .padding(JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colors.border, lineWidth: 3)
        )
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            Button {
                onCancel()
                HapticManager.selection()
            } label: {
                Text("CANCEL")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(colors.border, lineWidth: 1.5)
                    )
            }

            Spacer()

            Text("SELECT DATE")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(colors.primary)

            Spacer()

            Button {
                onDone()
                HapticManager.selection()
            } label: {
                Text("DONE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primaryInverted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(colors.border, lineWidth: 1.5)
                    )
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingMD)
    }

    // MARK: - Month Navigation

    private var monthNavigationRow: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
                HapticManager.selection()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(colors.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(monthYearString)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }
                HapticManager.selection()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(colors.primary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingXS)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth).uppercased()
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let weeks = weeksInMonth()

        return VStack(spacing: JohoDimensions.spacingXS) {
            // Weekday header row
            HStack(spacing: JohoDimensions.spacingXS) {
                // Week column header
                Text("W")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primaryInverted)
                    .frame(width: 28, height: 28)
                    .background(colors.surfaceInverted)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                // Day headers
                ForEach(0..<7, id: \.self) { index in
                    let isWeekend = index >= 5
                    Text(weekdays[index])
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(isWeekend ? accentColor.opacity(0.2) : colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(colors.border, lineWidth: 1)
                        )
                }
            }

            // Week rows
            ForEach(weeks, id: \.self) { week in
                HStack(spacing: JohoDimensions.spacingXS) {
                    // Week number cell (tappable to select first day of week)
                    weekNumberCell(for: week)

                    // Day cells
                    ForEach(week, id: \.self) { day in
                        dayCell(for: day)
                    }
                }
            }
        }
    }

    private func weekNumberCell(for week: [Date]) -> some View {
        let weekNumber = calendar.component(.weekOfYear, from: week.first ?? Date())
        let firstDayOfWeek = week.first { calendar.component(.month, from: $0) == calendar.component(.month, from: displayedMonth) } ?? week.first!

        return Button {
            selectedDate = firstDayOfWeek
            HapticManager.impact(.light)
        } label: {
            Text("\(weekNumber)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(colors.primaryInverted)
                .frame(width: 28, height: 40)
                .background(colors.surfaceInverted)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func dayCell(for date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isCurrentMonth = calendar.component(.month, from: date) == calendar.component(.month, from: displayedMonth)
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

        return Button {
            selectedDate = date
            HapticManager.impact(.light)
        } label: {
            Text("\(day)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(dayTextColor(isToday: isToday, isSelected: isSelected, isCurrentMonth: isCurrentMonth))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(dayBackground(isToday: isToday, isSelected: isSelected))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(
                            dayBorderColor(isToday: isToday, isSelected: isSelected),
                            lineWidth: (isToday || isSelected) ? 2 : 1
                        )
                )
                .opacity(isCurrentMonth ? 1.0 : 0.3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Styling Helpers

    private func dayBackground(isToday: Bool, isSelected: Bool) -> Color {
        if isToday { return JohoColors.yellow }
        if isSelected { return accentColor }
        return colors.surface
    }

    private func dayTextColor(isToday: Bool, isSelected: Bool, isCurrentMonth: Bool) -> Color {
        if isToday { return colors.primary }
        if isSelected { return colors.primaryInverted }
        return colors.primary
    }

    private func dayBorderColor(isToday: Bool, isSelected: Bool) -> Color {
        if isToday || isSelected { return colors.border }
        return colors.border.opacity(0.5)
    }

    // MARK: - Date Calculations

    private func weeksInMonth() -> [[Date]] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        // Find the Monday of the week containing the 1st
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        // ISO 8601: Monday = 1, Sunday = 7
        // Calendar weekday: Sunday = 1, Monday = 2, etc.
        let daysToSubtract = (firstWeekday + 5) % 7 // Convert to ISO weekday offset
        guard let gridStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: monthStart) else {
            return []
        }

        var weeks: [[Date]] = []
        var currentDate = gridStart

        // Generate 6 weeks to cover all possible month layouts
        for _ in 0..<6 {
            var week: [Date] = []
            for _ in 0..<7 {
                week.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            weeks.append(week)

            // Stop if we've passed the end of the month and completed the week
            if calendar.component(.month, from: currentDate) != calendar.component(.month, from: monthStart)
                && calendar.component(.day, from: currentDate) > 7 {
                break
            }
        }

        return weeks
    }
}

// MARK: - JohoCalendarPicker Sheet Wrapper

/// Overlay modifier for presenting JohoCalendarPicker floating over content
struct JohoCalendarPickerOverlay: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    // Calendar picker floating over content
                    JohoCalendarPicker(
                        selectedDate: $selectedDate,
                        accentColor: accentColor,
                        onDone: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented = false
                            }
                        },
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented = false
                            }
                        }
                    )
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

extension View {
    /// Present a floating calendar picker overlay
    func johoCalendarPicker(
        isPresented: Binding<Bool>,
        selectedDate: Binding<Date>,
        accentColor: Color
    ) -> some View {
        modifier(JohoCalendarPickerOverlay(
            isPresented: isPresented,
            selectedDate: selectedDate,
            accentColor: accentColor
        ))
    }
}

/// Legacy wrapper - redirects to overlay for backward compatibility
struct JohoCalendarPickerSheet: View {
    @Binding var selectedDate: Date
    let accentColor: Color
    @Binding var isPresented: Bool

    var body: some View {
        // This is now just the picker itself for sheet contexts
        JohoCalendarPicker(
            selectedDate: $selectedDate,
            accentColor: accentColor,
            onDone: { isPresented = false },
            onCancel: { isPresented = false }
        )
        .padding(JohoDimensions.spacingMD)
        .presentationDetents([.medium])
        .presentationCornerRadius(20)
        .presentationDragIndicator(.hidden)
        .presentationBackground(JohoColors.black)
    }
}

// MARK: - JohoMonthYearPicker (情報デザイン: Month/Year Navigation)

/// A 情報デザイン compliant month/year picker for calendar navigation
/// Matches the JohoCalendarPicker aesthetic but only selects month and year
struct JohoMonthYearPicker: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    let accentColor: Color
    let onDone: () -> Void
    let onCancel: () -> Void

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                          "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

    private var years: [Int] {
        let current = Calendar.iso8601.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }

    private var currentYear: Int {
        Calendar.iso8601.component(.year, from: Date())
    }

    private var currentMonth: Int {
        Calendar.iso8601.component(.month, from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            headerRow

            Rectangle().fill(colors.border).frame(height: 1.5)

            // Year navigation row
            yearNavigationRow

            Rectangle().fill(colors.border).frame(height: 1.5)

            // Month grid (3x4)
            monthGrid
        }
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colors.border, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Button {
                onCancel()
                HapticManager.selection()
            } label: {
                Text("CANCEL")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(colors.border, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("SELECT MONTH")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(colors.primary)

            Spacer()

            Button {
                onDone()
                HapticManager.notification(.success)
            } label: {
                Text("DONE")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primaryInverted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(colors.border, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
    }

    // MARK: - Year Navigation

    private var yearNavigationRow: some View {
        HStack(spacing: 0) {
            // Previous year button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedYear -= 1
                }
                HapticManager.selection()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            // Year display
            Text(String(selectedYear))
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(selectedYear == currentYear ? accentColor : colors.primary)

            Spacer()

            // Next year button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedYear += 1
                }
                HapticManager.selection()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, JohoDimensions.spacingSM)
        .frame(height: 52)
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 4), spacing: 0) {
            ForEach(1...12, id: \.self) { month in
                monthCell(month)
            }
        }
    }

    private func monthCell(_ month: Int) -> some View {
        let isSelected = month == selectedMonth
        let isCurrentMonth = month == currentMonth && selectedYear == currentYear

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedMonth = month
            }
            HapticManager.selection()
        } label: {
            Text(months[month - 1])
                .font(.system(size: 14, weight: isSelected ? .heavy : .bold, design: .rounded))
                .foregroundStyle(isSelected ? colors.primaryInverted : colors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    isSelected ? accentColor :
                    isCurrentMonth ? JohoColors.yellow.opacity(0.3) :
                    colors.surface
                )
                .overlay(
                    Rectangle()
                        .stroke(colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - JohoMonthYearPicker Overlay

/// Overlay modifier for presenting JohoMonthYearPicker floating over content
struct JohoMonthYearPickerOverlay: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    JohoMonthYearPicker(
                        selectedMonth: $selectedMonth,
                        selectedYear: $selectedYear,
                        accentColor: accentColor,
                        onDone: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented = false
                            }
                        },
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented = false
                            }
                        }
                    )
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

extension View {
    /// Present a floating month/year picker overlay
    func johoYearPicker(
        isPresented: Binding<Bool>,
        selectedMonth: Binding<Int>,
        selectedYear: Binding<Int>,
        accentColor: Color
    ) -> some View {
        modifier(JohoMonthYearPickerOverlay(
            isPresented: isPresented,
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            accentColor: accentColor
        ))
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

#Preview("ViewModifier Pattern") {
    ScrollView {
        VStack(spacing: JohoDimensions.spacingLG) {
            // MARK: - johoBento() modifier
            Text("johoBento()")
                .font(JohoFont.label)
                .foregroundStyle(JohoColors.black.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text("Basic Bento Card")
                    .font(JohoFont.headline)
                Text("White background with black border")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .johoBento()

            // MARK: - johoAccentedBento() modifier
            Text("johoAccentedBento()")
                .font(JohoFont.label)
                .foregroundStyle(JohoColors.black.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: JohoDimensions.spacingSM) {
                VStack {
                    Image(systemName: "calendar")
                    Text("CYAN")
                        .font(JohoFont.labelSmall)
                }
                .frame(maxWidth: .infinity)
                .johoAccentedBento(color: JohoColors.cyan)

                VStack {
                    Image(systemName: "star.fill")
                    Text("PINK")
                        .font(JohoFont.labelSmall)
                }
                .frame(maxWidth: .infinity)
                .johoAccentedBento(color: JohoColors.pink)

                VStack {
                    Image(systemName: "dollarsign")
                    Text("GREEN")
                        .font(JohoFont.labelSmall)
                }
                .frame(maxWidth: .infinity)
                .johoAccentedBento(color: JohoColors.green)
            }

            // MARK: - johoInteractiveCell() modifier
            Text("johoInteractiveCell()")
                .font(JohoFont.label)
                .foregroundStyle(JohoColors.black.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: JohoDimensions.spacingSM) {
                HStack {
                    Text("Normal Cell")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding(JohoDimensions.spacingMD)
                .johoInteractiveCell()

                HStack {
                    Text("Selected Cell")
                    Spacer()
                    Image(systemName: "checkmark")
                }
                .padding(JohoDimensions.spacingMD)
                .foregroundStyle(JohoColors.white)
                .johoInteractiveCell(isSelected: true)

                HStack {
                    Text("Highlighted Cell")
                    Spacer()
                    Image(systemName: "hand.tap")
                }
                .padding(JohoDimensions.spacingMD)
                .johoInteractiveCell(isHighlighted: true)
            }

            // MARK: - johoIconBadge() modifier
            Text("johoIconBadge()")
                .font(JohoFont.label)
                .foregroundStyle(JohoColors.black.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: JohoDimensions.spacingMD) {
                Image(systemName: "airplane")
                    .johoIconBadge(color: JohoColors.cyan, size: 40)

                Image(systemName: "gift.fill")
                    .johoIconBadge(color: JohoColors.pink, size: 40)

                Image(systemName: "note.text")
                    .johoIconBadge(color: JohoColors.yellow, size: 40)

                Image(systemName: "person.fill")
                    .johoIconBadge(color: JohoColors.purple, size: 40)
            }

            // MARK: - johoPillStyle() modifier
            Text("johoPillStyle()")
                .font(JohoFont.label)
                .foregroundStyle(JohoColors.black.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: JohoDimensions.spacingSM) {
                Text("DEFAULT")
                    .johoPillStyle()

                Text("CYAN")
                    .johoPillStyle(
                        backgroundColor: JohoColors.cyan,
                        foregroundColor: JohoColors.black,
                        borderColor: JohoColors.black
                    )

                Text("OUTLINED")
                    .johoPillStyle(
                        backgroundColor: .clear,
                        foregroundColor: JohoColors.black,
                        borderColor: JohoColors.black
                    )
            }
        }
        .padding(JohoDimensions.spacingLG)
    }
    .johoBackground()
}
