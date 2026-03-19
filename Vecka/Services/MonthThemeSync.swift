//
//  MonthThemeSync.swift
//  Vecka
//
//  Syncs month theme customizations to App Group for widget access
//  Follows WorldClockSync pattern for App Group transfer
//

import Foundation
import SwiftUI

// MARK: - Shared Month Style (Codable for UserDefaults)

/// Lightweight month style data for widget display
/// Synced via App Group UserDefaults from main app's MonthCustomization
struct SharedMonthStyle: Codable {
    let month: Int              // 1-12
    let icon: String            // Custom or seasonal default SF Symbol
    let accentColorHex: String  // Custom icon color or seasonal default
    let lightBackgroundHex: String // Seasonal background (locked to theme)
    let message: String?        // User's personal note
}

// MARK: - App Group Storage

enum MonthThemeStorage {
    static let appGroupID = "group.Johansson.Vecka"
    static let monthStylesKey = "shared_month_styles"

    /// Safely access App Group UserDefaults (returns nil if unavailable)
    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Save month styles to App Group (called from main app)
    /// Silently fails if App Group is unavailable - widget will use defaults
    static func save(_ styles: [SharedMonthStyle]) {
        guard let defaults = sharedDefaults,
              let encoded = try? JSONEncoder().encode(styles)
        else { return }
        defaults.set(encoded, forKey: monthStylesKey)
    }

    /// Load month styles from App Group (called from widget)
    /// Returns empty array if App Group is unavailable
    static func load() -> [SharedMonthStyle] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: monthStylesKey),
              let styles = try? JSONDecoder().decode([SharedMonthStyle].self, from: data)
        else { return [] }
        return styles
    }

    /// Sync month customizations to App Group for widget access
    static func syncCustomizations(_ customizations: [Int: MonthCustomization]) {
        let styles: [SharedMonthStyle] = (1...12).map { month in
            let theme = MonthTheme.theme(for: month)
            let custom = customizations[month]
            return SharedMonthStyle(
                month: month,
                icon: custom?.icon ?? theme.icon,
                accentColorHex: custom?.iconColorHex ?? theme.accentColor.toHex(),
                lightBackgroundHex: theme.lightBackground.toHex(),
                message: custom?.message
            )
        }
        save(styles)
    }
}

// MARK: - Category Color Storage (App Group Sync)

/// Syncs category colors to App Group for widget access
/// Follows same pattern as MonthThemeStorage
enum CategoryColorStorage {
    static let appGroupID = "group.Johansson.Vecka"
    static let categoryColorsKey = "shared_category_colors"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Save current category colors and structural theme overrides to App Group
    static func save() {
        guard let defaults = sharedDefaults else { return }
        let settings = CategoryColorSettings.shared
        var categoryColorMap: [String: String] = [
            "holiday": settings.holidayColorHex,
            "observance": settings.observanceColorHex,
            "memo": settings.memoColorHex,
        ]

        // Sync structural theme overrides for widget
        if let theme = JohoThemeCache.activeTheme() {
            if let hex = theme.lightBorderHex { categoryColorMap["border_light"] = hex }
            if let hex = theme.lightSurfaceHex { categoryColorMap["surface_light"] = hex }
            if let hex = theme.lightCanvasHex { categoryColorMap["canvas_light"] = hex }
            if let hex = theme.darkBorderHex { categoryColorMap["border_dark"] = hex }
            if let hex = theme.darkSurfaceHex { categoryColorMap["surface_dark"] = hex }
            if let hex = theme.darkCanvasHex { categoryColorMap["canvas_dark"] = hex }

            // Derive text colors from surface luminance for widget readability
            if let lightSurface = theme.lightSurfaceHex {
                let lum = Color(hex: lightSurface).relativeLuminance
                categoryColorMap["primary_light"] = lum <= 0.5 ? "F0F0F0" : "000000"
            }
            if let darkSurface = theme.darkSurfaceHex {
                let lum = Color(hex: darkSurface).relativeLuminance
                categoryColorMap["primary_dark"] = lum <= 0.5 ? "F0F0F0" : "000000"
            }
        }

        guard let encoded = try? JSONEncoder().encode(categoryColorMap) else { return }
        defaults.set(encoded, forKey: categoryColorsKey)
    }

    /// Load category colors from App Group (returns defaults if unavailable)
    static func load() -> (holiday: String, observance: String, memo: String) {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: categoryColorsKey),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return (
                CategoryColorSettings.defaultHolidayHex,
                CategoryColorSettings.defaultObservanceHex,
                CategoryColorSettings.defaultMemoHex
            )
        }
        return (
            dict["holiday"] ?? CategoryColorSettings.defaultHolidayHex,
            dict["observance"] ?? CategoryColorSettings.defaultObservanceHex,
            dict["memo"] ?? CategoryColorSettings.defaultMemoHex
        )
    }

    /// Load structural theme overrides from App Group (returns nil values if no overrides)
    static func loadStructuralOverrides() -> (
        borderLight: String?, surfaceLight: String?, canvasLight: String?,
        borderDark: String?, surfaceDark: String?, canvasDark: String?
    ) {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: categoryColorsKey),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return (nil, nil, nil, nil, nil, nil)
        }
        return (
            dict["border_light"],
            dict["surface_light"],
            dict["canvas_light"],
            dict["border_dark"],
            dict["surface_dark"],
            dict["canvas_dark"]
        )
    }
}
