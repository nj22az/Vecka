//
//  ConfigurationManager.swift
//  Vecka
//
//  Centralized configuration management for database-driven app settings
//  Replaces hardcoded constants with database-backed configuration
//

import Foundation
import SwiftData
import SwiftUI

class ConfigurationManager {
    static let shared = ConfigurationManager()

    private init() {}

    // MARK: - Configuration Access

    func getInt(_ key: String, context: ModelContext, default defaultValue: Int) -> Int {
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate<AppConfiguration> { config in
                config.key == key && config.isActive
            }
        )

        do {
            if let config = try context.fetch(descriptor).first,
               let value = config.intValue {
                return value
            }
        } catch {
            Log.e("ConfigurationManager: Failed to fetch \(key): \(error)")
        }

        return defaultValue
    }

    func getDouble(_ key: String, context: ModelContext, default defaultValue: Double) -> Double {
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate<AppConfiguration> { config in
                config.key == key && config.isActive
            }
        )

        do {
            if let config = try context.fetch(descriptor).first,
               let value = config.doubleValue {
                return value
            }
        } catch {
            Log.e("ConfigurationManager: Failed to fetch \(key): \(error)")
        }

        return defaultValue
    }

    func getString(_ key: String, context: ModelContext, default defaultValue: String) -> String {
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate<AppConfiguration> { config in
                config.key == key && config.isActive
            }
        )

        do {
            if let config = try context.fetch(descriptor).first,
               let value = config.stringValue {
                return value
            }
        } catch {
            Log.e("ConfigurationManager: Failed to fetch \(key): \(error)")
        }

        return defaultValue
    }

    func getBool(_ key: String, context: ModelContext, default defaultValue: Bool) -> Bool {
        let descriptor = FetchDescriptor<AppConfiguration>(
            predicate: #Predicate<AppConfiguration> { config in
                config.key == key && config.isActive
            }
        )

        do {
            if let config = try context.fetch(descriptor).first,
               let value = config.boolValue {
                return value
            }
        } catch {
            Log.e("ConfigurationManager: Failed to fetch \(key): \(error)")
        }

        return defaultValue
    }

    // MARK: - Icon Catalog Queries

    /// Get all icons for a specific category
    func getIcons(category: String, context: ModelContext) -> [IconCatalogItem] {
        let descriptor = FetchDescriptor<IconCatalogItem>(
            predicate: #Predicate<IconCatalogItem> { icon in
                icon.category == category && icon.isActive
            },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            Log.e("ConfigurationManager: Failed to fetch icons for category \(category): \(error)")
            return []
        }
    }

    /// Get symbol name and label for a specific icon
    func getIconSymbol(symbolName: String, category: String, context: ModelContext) -> (symbol: String, label: String)? {
        let descriptor = FetchDescriptor<IconCatalogItem>(
            predicate: #Predicate<IconCatalogItem> { icon in
                icon.symbolName == symbolName && icon.category == category && icon.isActive
            }
        )

        do {
            if let icon = try context.fetch(descriptor).first {
                return (icon.symbolName, icon.displayLabel)
            }
        } catch {
            Log.e("ConfigurationManager: Failed to fetch icon \(symbolName): \(error)")
        }

        return nil
    }

    /// Get default icon for countdown type (database-driven with fallback)
    func getCountdownIcon(for type: String, context: ModelContext) -> String {
        // Map countdown type to icon (database-driven)
        let iconMap: [String: String] = [
            "new_year": "sparkles",
            "christmas": "tree.fill",
            "summer": "sun.max.fill",
            "valentines": "heart.fill",
            "halloween": "moon.stars.fill",
            "midsummer": "leaf.fill",
            "custom": "calendar.badge.plus"
        ]

        return iconMap[type] ?? "calendar.badge.plus"
    }

    // MARK: - Theme Management

    func getActiveTheme(context: ModelContext) -> UITheme? {
        let descriptor = FetchDescriptor<UITheme>(
            predicate: #Predicate<UITheme> { theme in
                theme.isActive
            }
        )

        do {
            return try context.fetch(descriptor).first
        } catch {
            Log.e("ConfigurationManager: Failed to fetch active theme: \(error)")
            return nil
        }
    }

    func getWeekdayColor(for weekday: Int, context: ModelContext) -> Color {
        guard let theme = getActiveTheme(context: context) else {
            return getDefaultWeekdayColor(for: weekday)
        }

        let hexCode: String
        switch weekday {
        case 1: hexCode = theme.sundayColorHex
        case 2: hexCode = theme.mondayColorHex
        case 3: hexCode = theme.tuesdayColorHex
        case 4: hexCode = theme.wednesdayColorHex
        case 5: hexCode = theme.thursdayColorHex
        case 6: hexCode = theme.fridayColorHex
        case 7: hexCode = theme.saturdayColorHex
        default: hexCode = "C0C0C0"
        }

        return Color(hex: hexCode)
    }

    private func getDefaultWeekdayColor(for weekday: Int) -> Color {
        // Fallback to hardcoded defaults if no theme in database
        switch weekday {
        case 1: return Color(hex: "FFD700")  // Sunday - Sun
        case 2: return Color(hex: "C0C0C0")  // Monday - Moon
        case 3: return Color(hex: "E53E3E")  // Tuesday - Mars
        case 4: return Color(hex: "1B6DEF")  // Wednesday - Mercury
        case 5: return Color(hex: "38A169")  // Thursday - Jupiter
        case 6: return Color(hex: "B8860B")  // Friday - Venus
        case 7: return Color(hex: "8B4513")  // Saturday - Saturn
        default: return .gray
        }
    }

    // MARK: - Typography Management

    func getActiveTypography(context: ModelContext) -> TypographyScale? {
        let descriptor = FetchDescriptor<TypographyScale>(
            predicate: #Predicate<TypographyScale> { scale in
                scale.isActive
            }
        )

        do {
            return try context.fetch(descriptor).first
        } catch {
            Log.e("ConfigurationManager: Failed to fetch active typography: \(error)")
            return nil
        }
    }

    func getFontSize(_ key: String, context: ModelContext, default defaultValue: Double) -> Double {
        guard let typography = getActiveTypography(context: context) else {
            return defaultValue
        }

        switch key {
        case "hero": return typography.heroSize
        case "title_large": return typography.titleLargeSize
        case "title_medium": return typography.titleMediumSize
        case "title_small": return typography.titleSmallSize
        case "body_large": return typography.bodyLargeSize
        case "body_medium": return typography.bodyMediumSize
        case "body_small": return typography.bodySmallSize
        case "caption": return typography.captionSize
        default: return defaultValue
        }
    }

    // MARK: - Spacing Management

    func getActiveSpacing(context: ModelContext) -> SpacingScale? {
        let descriptor = FetchDescriptor<SpacingScale>(
            predicate: #Predicate<SpacingScale> { scale in
                scale.isActive
            }
        )

        do {
            return try context.fetch(descriptor).first
        } catch {
            Log.e("ConfigurationManager: Failed to fetch active spacing: \(error)")
            return nil
        }
    }

    func getSpacing(_ key: String, context: ModelContext, default defaultValue: Double) -> Double {
        guard let spacing = getActiveSpacing(context: context) else {
            return defaultValue
        }

        switch key {
        case "extra_small": return spacing.extraSmall
        case "small": return spacing.small
        case "medium": return spacing.medium
        case "large": return spacing.large
        case "extra_large": return spacing.extraLarge
        case "huge": return spacing.huge
        case "massive": return spacing.massive
        case "corner_radius": return spacing.cornerRadius
        case "card_spacing": return spacing.cardSpacing
        case "section_spacing": return spacing.sectionSpacing
        case "grid_spacing": return spacing.gridSpacing
        case "minimum_tap_target": return spacing.minimumTapTarget
        default: return defaultValue
        }
    }

    // MARK: - Icon Catalog (Legacy methods - for backward compatibility)

    func getIcons(for category: String, context: ModelContext) -> [IconCatalogItem] {
        let descriptor = FetchDescriptor<IconCatalogItem>(
            predicate: #Predicate<IconCatalogItem> { item in
                item.category == category && item.isActive
            },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            Log.e("ConfigurationManager: Failed to fetch icons for \(category): \(error)")
            return []
        }
    }

    // MARK: - Validation

    func validate(field: String, value: Any, context: ModelContext) -> (isValid: Bool, error: String?) {
        let descriptor = FetchDescriptor<ValidationRule>(
            predicate: #Predicate<ValidationRule> { rule in
                rule.fieldName == field && rule.isActive
            }
        )

        do {
            let rules = try context.fetch(descriptor)

            for rule in rules {
                switch rule.validationType {
                case "min_value":
                    if let minValue = rule.minValue,
                       let doubleValue = value as? Double,
                       doubleValue < minValue {
                        return (false, rule.errorMessage)
                    }

                case "max_value":
                    if let maxValue = rule.maxValue,
                       let doubleValue = value as? Double,
                       doubleValue > maxValue {
                        return (false, rule.errorMessage)
                    }

                case "range":
                    if let minValue = rule.minValue,
                       let maxValue = rule.maxValue,
                       let doubleValue = value as? Double,
                       !(minValue...maxValue).contains(doubleValue) {
                        return (false, rule.errorMessage)
                    }

                case "required":
                    if let stringValue = value as? String, stringValue.isEmpty {
                        return (false, rule.errorMessage)
                    }

                case "regex":
                    if let regexPattern = rule.regexPattern,
                       let stringValue = value as? String {
                        let regex = try? NSRegularExpression(pattern: regexPattern)
                        let range = NSRange(location: 0, length: stringValue.utf16.count)
                        if regex?.firstMatch(in: stringValue, options: [], range: range) == nil {
                            return (false, rule.errorMessage)
                        }
                    }

                default:
                    break
                }
            }
        } catch {
            Log.e("ConfigurationManager: Failed to validate \(field): \(error)")
        }

        return (true, nil)
    }

    // MARK: - Algorithm Parameters

    func getAlgorithmParameters(for algorithm: String, context: ModelContext) -> [String: Double] {
        let descriptor = FetchDescriptor<AlgorithmParameter>(
            predicate: #Predicate<AlgorithmParameter> { param in
                param.algorithmName == algorithm
            }
        )

        do {
            let params = try context.fetch(descriptor)
            var result: [String: Double] = [:]
            for param in params {
                result[param.parameterName] = param.parameterValue
            }
            return result
        } catch {
            Log.e("ConfigurationManager: Failed to fetch algorithm parameters for \(algorithm): \(error)")
            return [:]
        }
    }

    // MARK: - Default Seeding

    func seedDefaultConfiguration(context: ModelContext) {
        // Check if already seeded
        let configDescriptor = FetchDescriptor<AppConfiguration>()
        if let existingCount = try? context.fetchCount(configDescriptor), existingCount > 0 {
            return
        }

        Log.i("ConfigurationManager: Seeding default configuration...")

        // UI Configuration
        let maxFavorites = AppConfiguration(
            key: "max_favorites",
            intValue: 4,
            category: "ui",
            configDescription: "Maximum number of favorite countdowns"
        )

        let yearRange = AppConfiguration(
            key: "year_picker_range",
            intValue: 20,
            category: "ui",
            configDescription: "Years to show before/after current year in pickers"
        )

        let holidayCacheSpan = AppConfiguration(
            key: "holiday_cache_span",
            intValue: 2,
            category: "system",
            configDescription: "Years to cache before/after current year"
        )

        let pdfPageLimit = AppConfiguration(
            key: "pdf_items_per_page",
            intValue: 10,
            category: "business",
            configDescription: "Maximum items per PDF page before pagination"
        )

        context.insert(maxFavorites)
        context.insert(yearRange)
        context.insert(holidayCacheSpan)
        context.insert(pdfPageLimit)

        // Default Theme
        let defaultTheme = UITheme(themeName: "Planetary Classic", isActive: true)
        context.insert(defaultTheme)

        // Default Typography
        let defaultTypography = TypographyScale()
        context.insert(defaultTypography)

        // Default Spacing
        let defaultSpacing = SpacingScale()
        context.insert(defaultSpacing)

        // Validation Rules
        let amountMinRule = ValidationRule(
            fieldName: "expense_amount",
            validationType: "min_value",
            minValue: 0.01,
            errorMessage: "Amount must be greater than 0"
        )

        let latitudeRule = ValidationRule(
            fieldName: "latitude",
            validationType: "range",
            minValue: -90,
            maxValue: 90,
            errorMessage: "Latitude must be between -90 and 90"
        )

        let longitudeRule = ValidationRule(
            fieldName: "longitude",
            validationType: "range",
            minValue: -180,
            maxValue: 180,
            errorMessage: "Longitude must be between -180 and 180"
        )

        context.insert(amountMinRule)
        context.insert(latitudeRule)
        context.insert(longitudeRule)

        // Icon Catalog
        seedIconCatalog(context: context)

        do {
            try context.save()
            Log.i("ConfigurationManager: Default configuration seeded successfully")
        } catch {
            Log.e("ConfigurationManager: Failed to seed configuration: \(error)")
        }
    }

    private func seedIconCatalog(context: ModelContext) {
        // Holiday icons (from HolidaySymbolCatalog)
        let holidayIcons = [
            ("flag.fill", "Flag", 0),
            ("flag", "Flag (Outline)", 1),
            ("star", "Star", 2),
            ("star.fill", "Star (Filled)", 3),
            ("sparkles", "Sparkles", 4),
            ("gift", "Gift", 5),
            ("gift.fill", "Gift (Filled)", 6),
            ("heart", "Heart", 7),
            ("heart.fill", "Heart (Filled)", 8),
            ("birthday.cake", "Cake", 9),
            ("balloon.2", "Balloons", 10),
            ("trophy.fill", "Trophy", 11),
            ("leaf.fill", "Leaf", 12),
            ("sun.max.fill", "Sun", 13),
            ("snowflake", "Snowflake", 14),
            ("cloud.sun.fill", "Cloud & Sun", 15),
            ("bell.fill", "Bell", 16),
            ("graduationcap.fill", "Graduation Cap", 17),
            ("airplane", "Airplane", 18),
            ("briefcase.fill", "Briefcase", 19),
            ("cross.fill", "Cross", 20)
        ]

        for (symbol, label, order) in holidayIcons {
            let icon = IconCatalogItem(
                symbolName: symbol,
                displayLabel: label,
                category: "holiday",
                sortOrder: order
            )
            context.insert(icon)
        }

        // Countdown icons (from CountdownType enum)
        let countdownIcons = [
            ("sparkles", "Sparkles", 0),
            ("tree.fill", "Christmas Tree", 1),
            ("sun.max.fill", "Sun", 2),
            ("heart.fill", "Heart", 3),
            ("moon.stars.fill", "Moon & Stars", 4),
            ("leaf.fill", "Leaf", 5),
            ("calendar.badge.plus", "Calendar", 6)
        ]

        for (symbol, label, order) in countdownIcons {
            let icon = IconCatalogItem(
                symbolName: symbol,
                displayLabel: label,
                category: "countdown",
                sortOrder: order
            )
            context.insert(icon)
        }

        // General event icons
        let eventIcons = [
            ("party.popper", "Party", 0),
            ("fireworks", "Fireworks", 1),
            ("balloon", "Balloon", 2),
            ("confetti.fill", "Confetti", 3)
        ]

        for (symbol, label, order) in eventIcons {
            let icon = IconCatalogItem(
                symbolName: symbol,
                displayLabel: label,
                category: "event",
                sortOrder: order
            )
            context.insert(icon)
        }
    }
}
