//
//  JohoFoundations.swift
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

    /// Convert Color to hex string (6-digit, no #)
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    /// WCAG 2.1 relative luminance (0 = black, 1 = white)
    /// Used for auto-deriving text colors from surface backgrounds
    var relativeLuminance: Double {
        let uiColor = UIColor(self)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        func linearize(_ c: CGFloat) -> Double {
            let v = Double(c)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }

    /// Shift brightness by delta (-1...1). Positive = lighter, negative = darker.
    func adjustedBrightness(by delta: Double) -> Color {
        let uiColor = UIColor(self)
        var h: CGFloat = 0; var s: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let newB = min(1, max(0, b + CGFloat(delta)))
        return Color(UIColor(hue: h, saturation: s, brightness: newB, alpha: a))
    }

    /// Data-driven readable foreground: looks up curated foreground from CategoryColorSettings
    /// when this color matches a known category background, otherwise auto-derives.
    /// Mode-aware via UITraitCollection for correct light/dark contrast.
    var readableForeground: Color {
        let hex = self.toHex()
        let settings = CategoryColorSettings.shared
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        let mode: JohoColorMode = isDark ? .dark : .light

        // Check if this color matches any category background (light or dark)
        for category in DisplayCategory.allCases {
            let lightBg = settings.colorHex(for: category)
            let darkBg: String
            switch category {
            case .holiday: darkBg = settings.holidayDarkColorHex
            case .observance: darkBg = settings.observanceDarkColorHex
            case .memo: darkBg = settings.memoDarkColorHex
            }
            if hex == lightBg || hex == darkBg {
                return settings.foregroundColor(for: category, mode: mode)
            }
        }

        // Fallback: darken if too light for foreground use, lighten if too dark
        if isDark {
            return relativeLuminance < 0.3 ? adjustedBrightness(by: 0.35) : self
        } else {
            return relativeLuminance > 0.45 ? adjustedBrightness(by: -0.35) : self
        }
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
    static let green = Color(hex: "4ADE80")     // MONEY - expenses (stark green for readability)
    static let purple = Color(hex: "E9D5FF")    // PEOPLE - contacts
    static let red = Color(hex: "E53935")       // ALERT - warnings, errors (system)

    // Dark foreground variants (readable on white backgrounds)
    static let yellowDark = Color(hex: "B8860B")    // Dark gold for icon/text on white
    static let cyanDark = Color(hex: "0891B2")      // Dark teal for icon/text on white
    static let pinkDark = Color(hex: "BE123C")      // Dark rose for icon/text on white
    static let greenDark = Color(hex: "15803D")     // Dark green for icon/text on white
    static let purpleDark = Color(hex: "7C3AED")    // Dark violet for icon/text on white

    // Light tints for bento box backgrounds
    static let yellowLight = Color(hex: "FEF3C7")   // Light yellow for notes
    static let cyanLight = Color(hex: "CFFAFE")     // Light cyan for events
    static let pinkLight = Color(hex: "FED7E2")     // Light pink for celebrations
    static let greenLight = Color(hex: "D1FAE5")    // Light green for expenses
    static let purpleLight = Color(hex: "F3E8FF")   // Light purple for contacts
    static let redLight = Color(hex: "FECACA")      // Light red for alerts

    // Today highlight - bright orange (distinct from yellow memos)
    static let todayOrange = Color(hex: "FF9500")

    // Type-specific indicator colors (darker versions for visibility on white)
    static let tripBlue = Color(hex: "3182CE")     // TRP indicator on calendar
}

// MARK: - Page Header Colors (情報デザイン: Unique colors for page headers)
// These are DISTINCT from entry type colors - used for page/section identity

enum PageHeaderColor {
    case landing       // Warm Amber - today, now, present (情報デザイン: NOW semantic)
    case calendar      // Deep Indigo - time, structure
    case specialDays   // Rich Amber - celebration, golden
    case tools         // Teal - active, productivity
    case contacts      // Vivid Purple - PEOPLE semantic color
    case settings      // Slate Blue - system, configuration

    /// Primary accent color for page headers (used in icon backgrounds, badges)
    var accent: Color {
        switch self {
        case .landing:      return Color(hex: "F59E0B")  // Warm Amber
        case .calendar:     return Color(hex: "4338CA")  // Deep Indigo
        case .specialDays:  return Color(hex: "D97706")  // Rich Amber
        case .tools:        return Color(hex: "0D9488")  // Teal
        case .contacts:     return Color(hex: "7C3AED")  // Vivid Purple (PEOPLE)
        case .settings:     return Color(hex: "475569")  // Slate Blue
        }
    }

    /// Light tint for header backgrounds (20% opacity of accent)
    var lightBackground: Color {
        switch self {
        case .landing:      return Color(hex: "F59E0B").opacity(JohoDimensions.opacityLight)
        case .calendar:     return Color(hex: "4338CA").opacity(JohoDimensions.opacityLight)
        case .specialDays:  return Color(hex: "D97706").opacity(JohoDimensions.opacityLight)
        case .tools:        return Color(hex: "0D9488").opacity(JohoDimensions.opacityLight)
        case .contacts:     return Color(hex: "7C3AED").opacity(JohoDimensions.opacityLight)
        case .settings:     return Color(hex: "475569").opacity(JohoDimensions.opacityLight)
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

    /// Get the color scheme for a given mode, with theme structural overrides applied
    static func colors(for mode: JohoColorMode) -> JohoScheme {
        let base: JohoScheme = switch mode {
        case .light:
            JohoScheme(
                primary: Color(hex: "000000"),       // Black text (on white bentos)
                secondary: Color(hex: "000000").opacity(JohoDimensions.opacityStrong),
                surface: Color(hex: "FFFFFF"),      // White containers (bentos pop against black canvas)
                border: Color(hex: "000000"),       // Black borders
                canvas: Color(hex: "000000"),       // True black canvas (AMOLED, matches dark mode)
                surfaceInverted: Color(hex: "000000"),
                primaryInverted: Color(hex: "FFFFFF"),
                inputBackground: Color(hex: "F5F5F5")  // Light gray for text fields
            )
        case .dark:
            JohoScheme(
                primary: Color(hex: "F0F0F0"),       // Soft off-white (less eye strain)
                secondary: Color(hex: "F0F0F0").opacity(JohoDimensions.opacityHeavy),
                surface: Color(hex: "1C1C1E"),      // Elevated dark gray (Apple dark elevated)
                border: Color(hex: "48484A"),       // Medium gray borders (visible, not harsh)
                canvas: Color(hex: "000000"),       // True black (OLED canvas)
                surfaceInverted: Color(hex: "F0F0F0"),
                primaryInverted: Color(hex: "1C1C1E"),
                inputBackground: Color(hex: "2C2C2E")  // Dark input fields
            )
        }

        // Apply theme structural overrides if active
        guard let theme = JohoThemeCache.activeTheme(),
              theme.hasStructuralOverrides
        else { return base }

        return theme.applyStructuralOverrides(to: base, mode: mode)
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
