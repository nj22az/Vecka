//
//  WidgetMonthTheme.swift
//  VeckaWidget
//
//  Month theme data for widget display
//  Checks App Group first, falls back to hardcoded seasonal defaults
//

import Foundation
import SwiftUI

// MARK: - Shared Month Style (duplicated from main app for widget target)

struct SharedMonthStyle: Codable {
    let month: Int
    let icon: String
    let accentColorHex: String
    let lightBackgroundHex: String
    let message: String?
}

// MARK: - Widget Month Theme

struct WidgetMonthTheme {
    let month: Int
    let icon: String
    let accentColor: Color
    let lightBackground: Color
    let message: String?

    /// Get theme for a specific month, checking App Group sync first
    static func theme(for month: Int) -> WidgetMonthTheme {
        // Try App Group synced data first
        let synced = loadFromAppGroup()
        if let style = synced.first(where: { $0.month == month }) {
            return WidgetMonthTheme(
                month: style.month,
                icon: style.icon,
                accentColor: Color(hex: style.accentColorHex),
                lightBackground: Color(hex: style.lightBackgroundHex),
                message: style.message
            )
        }
        // Fall back to hardcoded seasonal defaults
        return defaults[month - 1]
    }

    // MARK: - App Group Load

    private static func loadFromAppGroup() -> [SharedMonthStyle] {
        guard let defaults = UserDefaults(suiteName: "group.Johansson.Vecka"),
              let data = defaults.data(forKey: "shared_month_styles"),
              let styles = try? JSONDecoder().decode([SharedMonthStyle].self, from: data)
        else { return [] }
        return styles
    }

    // MARK: - Hardcoded Seasonal Defaults (same as month-themes.json)

    static let defaults: [WidgetMonthTheme] = [
        // 1月: Pine Green - New Year
        WidgetMonthTheme(month: 1, icon: "tree.fill",
                         accentColor: Color(hex: "1D4A3A"), lightBackground: Color(hex: "A8D5C2"), message: nil),
        // 2月: Red Plum - Ume blossoms
        WidgetMonthTheme(month: 2, icon: "camera.macro",
                         accentColor: Color(hex: "B8363B"), lightBackground: Color(hex: "F2B8BA"), message: nil),
        // 3月: Peach Pink - Hina-matsuri
        WidgetMonthTheme(month: 3, icon: "leaf",
                         accentColor: Color(hex: "D4587A"), lightBackground: Color(hex: "F8C4D4"), message: nil),
        // 4月: Cherry Blossom - Hanami
        WidgetMonthTheme(month: 4, icon: "camera.macro",
                         accentColor: Color(hex: "E8A0A0"), lightBackground: Color(hex: "FFE4E4"), message: nil),
        // 5月: Young Leaf - Fresh growth
        WidgetMonthTheme(month: 5, icon: "leaf.fill",
                         accentColor: Color(hex: "4A8C2A"), lightBackground: Color(hex: "B8E89C"), message: nil),
        // 6月: Hydrangea Blue - Rainy season
        WidgetMonthTheme(month: 6, icon: "cloud.rain.fill",
                         accentColor: Color(hex: "4A7CB8"), lightBackground: Color(hex: "B4D4F4"), message: nil),
        // 7月: Deep Indigo - Summer
        WidgetMonthTheme(month: 7, icon: "water.waves",
                         accentColor: Color(hex: "1E3A5F"), lightBackground: Color(hex: "8AAED4"), message: nil),
        // 8月: Gold - Summer sun
        WidgetMonthTheme(month: 8, icon: "sun.max.fill",
                         accentColor: Color(hex: "C88C10"), lightBackground: Color(hex: "F4D88C"), message: nil),
        // 9月: Persimmon - Harvest moon
        WidgetMonthTheme(month: 9, icon: "moon.fill",
                         accentColor: Color(hex: "D47830"), lightBackground: Color(hex: "F4C89C"), message: nil),
        // 10月: Maple Red - Autumn leaves
        WidgetMonthTheme(month: 10, icon: "leaf.fill",
                         accentColor: Color(hex: "9C1C1C"), lightBackground: Color(hex: "E8A0A0"), message: nil),
        // 11月: Fallen Leaf - Melancholy
        WidgetMonthTheme(month: 11, icon: "wind",
                         accentColor: Color(hex: "8C5C34"), lightBackground: Color(hex: "D4B89C"), message: nil),
        // 12月: Steel Blue-Gray - Winter
        WidgetMonthTheme(month: 12, icon: "snowflake",
                         accentColor: Color(hex: "5C6C7C"), lightBackground: Color(hex: "C4D0DC"), message: nil),
    ]
}
