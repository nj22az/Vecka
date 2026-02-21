//
//  JohoTheme.swift
//  Vecka
//
//  Theme preset system for unified category color theming
//  Themes change category colors + icons + UI accent
//  Month seasonal colors (季節の色) are identity-locked and never change
//

import SwiftUI

// MARK: - Theme Preset Model

struct JohoThemePreset: Codable, Identifiable {
    let id: String              // "default", "sakura", "nordic"
    let name: String            // Display name
    let description: String     // One-liner
    let previewIcon: String     // SF Symbol for theme card

    // Category colors (hex)
    let holidayColorHex: String
    let observanceColorHex: String
    let memoColorHex: String

    // Category icons (nil = keep default)
    let holidayIcon: String?
    let observanceIcon: String?
    let memoIcon: String?

    // UI accent
    let systemAccent: String    // "black", "indigo", "navy", "blue", "slate"

    // Category foreground colors (nil = auto-derive from background)
    let holidayForegroundHex: String?
    let observanceForegroundHex: String?
    let memoForegroundHex: String?

    // Dark mode category colors (nil = use light mode value)
    let holidayDarkColorHex: String?
    let observanceDarkColorHex: String?
    let memoDarkColorHex: String?

    // Dark mode foreground colors (nil = auto-derive)
    let holidayDarkForegroundHex: String?
    let observanceDarkForegroundHex: String?
    let memoDarkForegroundHex: String?

    // Structural overrides (nil = use JohoScheme defaults)
    let lightBorderHex: String?
    let lightSurfaceHex: String?
    let lightCanvasHex: String?
    let darkBorderHex: String?
    let darkSurfaceHex: String?
    let darkCanvasHex: String?

    init(
        id: String, name: String, description: String, previewIcon: String,
        holidayColorHex: String, observanceColorHex: String, memoColorHex: String,
        holidayIcon: String?, observanceIcon: String?, memoIcon: String?,
        systemAccent: String,
        holidayForegroundHex: String? = nil, observanceForegroundHex: String? = nil, memoForegroundHex: String? = nil,
        holidayDarkColorHex: String? = nil, observanceDarkColorHex: String? = nil, memoDarkColorHex: String? = nil,
        holidayDarkForegroundHex: String? = nil, observanceDarkForegroundHex: String? = nil, memoDarkForegroundHex: String? = nil,
        lightBorderHex: String? = nil, lightSurfaceHex: String? = nil, lightCanvasHex: String? = nil,
        darkBorderHex: String? = nil, darkSurfaceHex: String? = nil, darkCanvasHex: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.previewIcon = previewIcon
        self.holidayColorHex = holidayColorHex
        self.observanceColorHex = observanceColorHex
        self.memoColorHex = memoColorHex
        self.holidayIcon = holidayIcon
        self.observanceIcon = observanceIcon
        self.memoIcon = memoIcon
        self.systemAccent = systemAccent
        self.holidayForegroundHex = holidayForegroundHex
        self.observanceForegroundHex = observanceForegroundHex
        self.memoForegroundHex = memoForegroundHex
        self.holidayDarkColorHex = holidayDarkColorHex
        self.observanceDarkColorHex = observanceDarkColorHex
        self.memoDarkColorHex = memoDarkColorHex
        self.holidayDarkForegroundHex = holidayDarkForegroundHex
        self.observanceDarkForegroundHex = observanceDarkForegroundHex
        self.memoDarkForegroundHex = memoDarkForegroundHex
        self.lightBorderHex = lightBorderHex
        self.lightSurfaceHex = lightSurfaceHex
        self.lightCanvasHex = lightCanvasHex
        self.darkBorderHex = darkBorderHex
        self.darkSurfaceHex = darkSurfaceHex
        self.darkCanvasHex = darkCanvasHex
    }
}

// MARK: - Theme Loader

enum JohoThemeLoader {

    /// Load theme presets from bundled JSON
    static func loadPresets() -> [JohoThemePreset] {
        BundleJSON.load("theme-presets", fallback: builtInPresets)
    }

    /// Fallback built-in presets if JSON fails to load
    static let builtInPresets: [JohoThemePreset] = [
        JohoThemePreset(
            id: "default", name: "Default", description: "Original 情報デザイン palette",
            previewIcon: "circle.hexagongrid.fill",
            holidayColorHex: "FECDD3", observanceColorHex: "A5F3FC", memoColorHex: "FFE566",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "indigo",
            holidayForegroundHex: "9F1239", observanceForegroundHex: "155E75", memoForegroundHex: "854D0E",
            holidayDarkColorHex: "881337", observanceDarkColorHex: "164E63", memoDarkColorHex: "854D0E",
            holidayDarkForegroundHex: "FECDD3", observanceDarkForegroundHex: "A5F3FC", memoDarkForegroundHex: "FFE566"
        ),
        JohoThemePreset(
            id: "nordic", name: "Nordic", description: "Scandinavian minimalism",
            previewIcon: "snowflake",
            holidayColorHex: "93C5FD", observanceColorHex: "C4B5FD", memoColorHex: "CBD5E1",
            holidayIcon: "star.fill", observanceIcon: "diamond.fill", memoIcon: "note.text",
            systemAccent: "navy",
            holidayForegroundHex: "1E40AF", observanceForegroundHex: "5B21B6", memoForegroundHex: "334155",
            holidayDarkColorHex: "1E3A5F", observanceDarkColorHex: "4C1D95", memoDarkColorHex: "334155",
            holidayDarkForegroundHex: "93C5FD", observanceDarkForegroundHex: "C4B5FD", memoDarkForegroundHex: "CBD5E1",
            lightBorderHex: "475569", lightSurfaceHex: "F8FAFC", lightCanvasHex: nil,
            darkBorderHex: "64748B", darkSurfaceHex: "1E293B", darkCanvasHex: nil
        ),
        JohoThemePreset(
            id: "earth", name: "Earth", description: "Warm, natural tones",
            previewIcon: "mountain.2.fill",
            holidayColorHex: "86EFAC", observanceColorHex: "FDBA74", memoColorHex: "FDE68A",
            holidayIcon: "leaf.fill", observanceIcon: "sun.max.fill", memoIcon: "note.text",
            systemAccent: "slate",
            holidayForegroundHex: "15803D", observanceForegroundHex: "9A3412", memoForegroundHex: "854D0E",
            holidayDarkColorHex: "14532D", observanceDarkColorHex: "7C2D12", memoDarkColorHex: "713F12",
            holidayDarkForegroundHex: "86EFAC", observanceDarkForegroundHex: "FDBA74", memoDarkForegroundHex: "FDE68A",
            lightBorderHex: "92400E", lightSurfaceHex: "FFFBEB", lightCanvasHex: nil,
            darkBorderHex: "A0896D", darkSurfaceHex: "1C1917", darkCanvasHex: nil
        ),
        JohoThemePreset(
            id: "ink", name: "Ink", description: "AMOLED high-contrast mono",
            previewIcon: "drop.fill",
            holidayColorHex: "E4E4E7", observanceColorHex: "A1A1AA", memoColorHex: "71717A",
            holidayIcon: nil, observanceIcon: nil, memoIcon: nil,
            systemAccent: "black",
            holidayForegroundHex: "27272A", observanceForegroundHex: "27272A", memoForegroundHex: "18181B",
            holidayDarkColorHex: "3F3F46", observanceDarkColorHex: "52525B", memoDarkColorHex: "52525B",
            holidayDarkForegroundHex: "E4E4E7", observanceDarkForegroundHex: "D4D4D8", memoDarkForegroundHex: "A1A1AA",
            lightBorderHex: "52525B", lightSurfaceHex: "000000", lightCanvasHex: "000000",
            darkBorderHex: "3F3F46", darkSurfaceHex: "000000", darkCanvasHex: "000000"
        ),
    ]
}

// MARK: - Structural Color Overrides

extension JohoThemePreset {

    /// Apply structural color overrides from this theme to a base color scheme.
    /// Auto-derives text colors from surface luminance — guarantees readable text on any surface.
    func applyStructuralOverrides(to base: JohoScheme, mode: JohoColorMode) -> JohoScheme {
        let surfaceHex: String?
        let borderHex: String?
        let canvasHex: String?

        switch mode {
        case .light:
            surfaceHex = lightSurfaceHex
            borderHex = lightBorderHex
            canvasHex = lightCanvasHex
        case .dark:
            surfaceHex = darkSurfaceHex
            borderHex = darkBorderHex
            canvasHex = darkCanvasHex
        }

        let surface = surfaceHex.map { Color(hex: $0) } ?? base.surface
        let border = borderHex.map { Color(hex: $0) } ?? base.border
        let canvas = canvasHex.map { Color(hex: $0) } ?? base.canvas

        // Auto-derive text colors from surface luminance
        let lum = surface.relativeLuminance
        let isDark = lum <= 0.5

        let primary = isDark ? Color(hex: "F0F0F0") : Color(hex: "000000")
        let secondary = isDark ? Color(hex: "F0F0F0").opacity(0.6) : Color(hex: "000000").opacity(0.6)
        let surfaceInverted = isDark ? Color(hex: "F0F0F0") : Color(hex: "000000")
        let primaryInverted = isDark ? Color(hex: "1C1C1E") : Color(hex: "FFFFFF")
        let inputBackground = isDark ? surface.adjustedBrightness(by: 0.08) : surface.adjustedBrightness(by: -0.04)

        return JohoScheme(
            primary: primary,
            secondary: secondary,
            surface: surface,
            border: border,
            canvas: canvas,
            surfaceInverted: surfaceInverted,
            primaryInverted: primaryInverted,
            inputBackground: inputBackground
        )
    }

    /// Whether this theme has any structural overrides
    var hasStructuralOverrides: Bool {
        lightBorderHex != nil || lightSurfaceHex != nil || lightCanvasHex != nil ||
        darkBorderHex != nil || darkSurfaceHex != nil || darkCanvasHex != nil
    }
}

// MARK: - Theme Cache (avoids JSON parsing on every colors(for:) call)

enum JohoThemeCache {
    private static var cachedThemeId: String?
    private static var cachedTheme: JohoThemePreset?

    /// Get the active theme, using cache when possible
    static func activeTheme() -> JohoThemePreset? {
        guard let themeId = UserDefaults.standard.string(forKey: "activeThemeId") else {
            cachedThemeId = nil
            cachedTheme = nil
            return nil
        }
        if themeId == cachedThemeId, let theme = cachedTheme {
            return theme
        }
        let theme = JohoThemeLoader.loadPresets().first { $0.id == themeId }
        cachedThemeId = themeId
        cachedTheme = theme
        return theme
    }

    /// Invalidate the cache (call when theme changes)
    static func invalidate() {
        cachedThemeId = nil
        cachedTheme = nil
    }
}

// MARK: - Theme Application

extension CategoryColorSettings {

    /// Apply a theme preset, updating all category colors, foregrounds, and icons
    func applyTheme(_ theme: JohoThemePreset) {
        // Update category background colors
        setColorHex(theme.holidayColorHex, for: .holiday)
        setColorHex(theme.observanceColorHex, for: .observance)
        setColorHex(theme.memoColorHex, for: .memo)

        // Update foreground colors (direct UserDefaults write + in-memory update)
        let holFg = theme.holidayForegroundHex ?? Self.autoDerivedForeground(theme.holidayColorHex)
        let obsFg = theme.observanceForegroundHex ?? Self.autoDerivedForeground(theme.observanceColorHex)
        let memFg = theme.memoForegroundHex ?? Self.autoDerivedForeground(theme.memoColorHex)
        holidayForegroundHex = holFg
        observanceForegroundHex = obsFg
        memoForegroundHex = memFg
        UserDefaults.standard.set(holFg, forKey: "categoryForeground_holiday")
        UserDefaults.standard.set(obsFg, forKey: "categoryForeground_observance")
        UserDefaults.standard.set(memFg, forKey: "categoryForeground_memo")

        // Update dark mode background colors
        let holDk = theme.holidayDarkColorHex ?? theme.holidayColorHex
        let obsDk = theme.observanceDarkColorHex ?? theme.observanceColorHex
        let memDk = theme.memoDarkColorHex ?? theme.memoColorHex
        holidayDarkColorHex = holDk
        observanceDarkColorHex = obsDk
        memoDarkColorHex = memDk
        UserDefaults.standard.set(holDk, forKey: "categoryDarkColor_holiday")
        UserDefaults.standard.set(obsDk, forKey: "categoryDarkColor_observance")
        UserDefaults.standard.set(memDk, forKey: "categoryDarkColor_memo")

        // Update dark mode foreground colors
        let holDkFg = theme.holidayDarkForegroundHex ?? Self.autoDerivedLightForeground(holDk)
        let obsDkFg = theme.observanceDarkForegroundHex ?? Self.autoDerivedLightForeground(obsDk)
        let memDkFg = theme.memoDarkForegroundHex ?? Self.autoDerivedLightForeground(memDk)
        holidayDarkForegroundHex = holDkFg
        observanceDarkForegroundHex = obsDkFg
        memoDarkForegroundHex = memDkFg
        UserDefaults.standard.set(holDkFg, forKey: "categoryDarkForeground_holiday")
        UserDefaults.standard.set(obsDkFg, forKey: "categoryDarkForeground_observance")
        UserDefaults.standard.set(memDkFg, forKey: "categoryDarkForeground_memo")

        // Update category icons (set if specified, reset to default if nil)
        if let icon = theme.holidayIcon {
            CategoryIconSettings.setIcon(icon, for: .holiday)
        } else {
            CategoryIconSettings.reset(for: .holiday)
        }
        if let icon = theme.observanceIcon {
            CategoryIconSettings.setIcon(icon, for: .observance)
        } else {
            CategoryIconSettings.reset(for: .observance)
        }
        if let icon = theme.memoIcon {
            CategoryIconSettings.setIcon(icon, for: .memo)
        } else {
            CategoryIconSettings.reset(for: .memo)
        }

        // Update system UI accent
        UserDefaults.standard.set(theme.systemAccent, forKey: "systemUIAccent")

        // Save active theme ID
        UserDefaults.standard.set(theme.id, forKey: "activeThemeId")

        // Invalidate theme cache so colors(for:) picks up the new theme
        JohoThemeCache.invalidate()

        // Sync to widget (includes structural colors)
        CategoryColorStorage.save()
    }

    /// Auto-derive a dark foreground from a light background hex (darken by luminance)
    private static func autoDerivedForeground(_ bgHex: String) -> String {
        let color = Color(hex: bgHex)
        return color.adjustedBrightness(by: -0.45).toHex()
    }

    /// Auto-derive a light foreground from a dark background hex (lighten by luminance)
    private static func autoDerivedLightForeground(_ bgHex: String) -> String {
        let color = Color(hex: bgHex)
        return color.adjustedBrightness(by: 0.45).toHex()
    }

    /// Get the currently active theme ID (nil if custom/no theme)
    var activeThemeId: String? {
        UserDefaults.standard.string(forKey: "activeThemeId")
    }

    /// Set category icon for a display category
    func setCategoryIcon(_ icon: String, for category: DisplayCategory) {
        UserDefaults.standard.set(icon, forKey: "categoryIcon_\(category.rawValue)")
    }

    /// Get category icon for a display category (nil = use default)
    func categoryIcon(for category: DisplayCategory) -> String? {
        UserDefaults.standard.string(forKey: "categoryIcon_\(category.rawValue)")
    }

    /// Reset category icon to default
    func resetCategoryIcon(for category: DisplayCategory) {
        UserDefaults.standard.removeObject(forKey: "categoryIcon_\(category.rawValue)")
    }

    /// Check if current colors match a specific theme
    func matchesTheme(_ theme: JohoThemePreset) -> Bool {
        holidayColorHex == theme.holidayColorHex &&
        observanceColorHex == theme.observanceColorHex &&
        memoColorHex == theme.memoColorHex
    }
}
