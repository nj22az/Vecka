//
//  CategoryEngine.swift
//  Vecka
//
//  JSON-driven category definitions for icons, colors, labels, and codes.
//  Single source of truth — replaces hardcoded switch statements in
//  SpecialDayType, DisplayCategory, and Memo.
//

import SwiftUI

// MARK: - Category Definition (JSON-backed)

struct CategoryDefinition: Codable, Identifiable {
    let id: String
    let displayCategory: String
    let title: String
    let code: String
    let defaultIcon: String?
    let accentColorHex: String
    let lightBackgroundHex: String?
    let isBankHoliday: Bool

    /// Resolved icon: defaultIcon from JSON, or locale-aware expense icon for "expense"
    var resolvedIcon: String {
        if let icon = defaultIcon { return icon }
        if id == "expense" { return IconCatalog.expense }
        return IconCatalog.memo
    }

    /// Accent color from hex
    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    /// Light background: explicit hex if set, otherwise accent at medium opacity
    var lightBackground: Color {
        if let hex = lightBackgroundHex {
            return Color(hex: hex)
        }
        return accentColor.opacity(JohoDimensions.opacityMedium)
    }
}

// MARK: - Category Engine (Singleton Loader)

enum CategoryEngine {
    /// All definitions loaded from JSON
    static let definitions: [CategoryDefinition] = {
        BundleJSON.load("category-definitions", fallback: [])
    }()

    /// Lookup by ID (e.g., "holiday", "memo", "trip")
    static func definition(for id: String) -> CategoryDefinition? {
        definitions.first { $0.id == id }
    }

    /// All definitions matching a display category (e.g., "memo" returns memo, trip, expense, etc.)
    static func definitions(for displayCategory: String) -> [CategoryDefinition] {
        definitions.filter { $0.displayCategory == displayCategory }
    }
}
