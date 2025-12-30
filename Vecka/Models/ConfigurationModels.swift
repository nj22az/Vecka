//
//  ConfigurationModels.swift
//  Vecka
//
//  Database-driven configuration system for 100% data-driven architecture
//  Replaces hardcoded constants, limits, and configuration values
//

import Foundation
import SwiftData

// MARK: - Generic Configuration

@Model
final class AppConfiguration {
    @Attribute(.unique) var key: String
    var intValue: Int?
    var doubleValue: Double?
    var stringValue: String?
    var boolValue: Bool?
    var category: String  // "ui", "business", "system", "feature"
    var configDescription: String
    var isActive: Bool
    var validFrom: Date
    var validTo: Date?

    init(
        key: String,
        intValue: Int? = nil,
        doubleValue: Double? = nil,
        stringValue: String? = nil,
        boolValue: Bool? = nil,
        category: String = "system",
        configDescription: String,
        isActive: Bool = true,
        validFrom: Date = Date(),
        validTo: Date? = nil
    ) {
        self.key = key
        self.intValue = intValue
        self.doubleValue = doubleValue
        self.stringValue = stringValue
        self.boolValue = boolValue
        self.category = category
        self.configDescription = configDescription
        self.isActive = isActive
        self.validFrom = validFrom
        self.validTo = validTo
    }
}

// MARK: - Validation Rules

@Model
final class ValidationRule {
    @Attribute(.unique) var id: UUID
    var fieldName: String
    var validationType: String  // "min_value", "max_value", "required", "regex", "range"
    var minValue: Double?
    var maxValue: Double?
    var regexPattern: String?
    var errorMessage: String
    var isActive: Bool

    init(
        id: UUID = UUID(),
        fieldName: String,
        validationType: String,
        minValue: Double? = nil,
        maxValue: Double? = nil,
        regexPattern: String? = nil,
        errorMessage: String,
        isActive: Bool = true
    ) {
        self.id = id
        self.fieldName = fieldName
        self.validationType = validationType
        self.minValue = minValue
        self.maxValue = maxValue
        self.regexPattern = regexPattern
        self.errorMessage = errorMessage
        self.isActive = isActive
    }
}

// MARK: - Algorithm Parameters

@Model
final class AlgorithmParameter {
    @Attribute(.unique) var id: UUID
    var algorithmName: String  // "easter_computus", "lunar_conversion", "solstice_calculation"
    var parameterName: String  // "coefficient_a", "base_day", "year_adjustment"
    var parameterValue: Double
    var parameterType: String  // "multiplier", "addend", "divisor", "constant"
    var algorithmDescription: String
    var validFrom: Date
    var validTo: Date?

    init(
        id: UUID = UUID(),
        algorithmName: String,
        parameterName: String,
        parameterValue: Double,
        parameterType: String,
        algorithmDescription: String,
        validFrom: Date = Date(),
        validTo: Date? = nil
    ) {
        self.id = id
        self.algorithmName = algorithmName
        self.parameterName = parameterName
        self.parameterValue = parameterValue
        self.parameterType = parameterType
        self.algorithmDescription = algorithmDescription
        self.validFrom = validFrom
        self.validTo = validTo
    }
}

// MARK: - UI Theme Configuration

@Model
final class UITheme {
    @Attribute(.unique) var id: UUID
    var themeName: String
    var isActive: Bool
    var isPremium: Bool

    // Planetary colors (weekday associations)
    var mondayColorHex: String
    var tuesdayColorHex: String
    var wednesdayColorHex: String
    var thursdayColorHex: String
    var fridayColorHex: String
    var saturdayColorHex: String
    var sundayColorHex: String

    // Accent colors
    var primaryAccentHex: String
    var secondaryAccentHex: String

    init(
        id: UUID = UUID(),
        themeName: String,
        isActive: Bool = false,
        isPremium: Bool = false,
        mondayColorHex: String = "C0C0C0",
        tuesdayColorHex: String = "E53E3E",
        wednesdayColorHex: String = "1B6DEF",
        thursdayColorHex: String = "38A169",
        fridayColorHex: String = "B8860B",
        saturdayColorHex: String = "8B4513",
        sundayColorHex: String = "FFD700",
        primaryAccentHex: String = "007AFF",
        secondaryAccentHex: String = "5856D6"
    ) {
        self.id = id
        self.themeName = themeName
        self.isActive = isActive
        self.isPremium = isPremium
        self.mondayColorHex = mondayColorHex
        self.tuesdayColorHex = tuesdayColorHex
        self.wednesdayColorHex = wednesdayColorHex
        self.thursdayColorHex = thursdayColorHex
        self.fridayColorHex = fridayColorHex
        self.saturdayColorHex = saturdayColorHex
        self.sundayColorHex = sundayColorHex
        self.primaryAccentHex = primaryAccentHex
        self.secondaryAccentHex = secondaryAccentHex
    }
}

// MARK: - Typography Scale

@Model
final class TypographyScale {
    @Attribute(.unique) var id: UUID
    var scaleName: String  // "default", "large", "compact"
    var isActive: Bool

    // Font sizes
    var heroSize: Double
    var titleLargeSize: Double
    var titleMediumSize: Double
    var titleSmallSize: Double
    var bodyLargeSize: Double
    var bodyMediumSize: Double
    var bodySmallSize: Double
    var captionSize: Double

    // Tracking values
    var tightTracking: Double
    var normalTracking: Double
    var wideTracking: Double

    // Line spacing
    var tightLineSpacing: Double
    var normalLineSpacing: Double
    var relaxedLineSpacing: Double

    init(
        id: UUID = UUID(),
        scaleName: String = "default",
        isActive: Bool = true,
        heroSize: Double = 88,
        titleLargeSize: Double = 34,
        titleMediumSize: Double = 28,
        titleSmallSize: Double = 22,
        bodyLargeSize: Double = 17,
        bodyMediumSize: Double = 15,
        bodySmallSize: Double = 13,
        captionSize: Double = 11,
        tightTracking: Double = -0.41,
        normalTracking: Double = 0.0,
        wideTracking: Double = 0.38,
        tightLineSpacing: Double = 1.1,
        normalLineSpacing: Double = 1.2,
        relaxedLineSpacing: Double = 1.4
    ) {
        self.id = id
        self.scaleName = scaleName
        self.isActive = isActive
        self.heroSize = heroSize
        self.titleLargeSize = titleLargeSize
        self.titleMediumSize = titleMediumSize
        self.titleSmallSize = titleSmallSize
        self.bodyLargeSize = bodyLargeSize
        self.bodyMediumSize = bodyMediumSize
        self.bodySmallSize = bodySmallSize
        self.captionSize = captionSize
        self.tightTracking = tightTracking
        self.normalTracking = normalTracking
        self.wideTracking = wideTracking
        self.tightLineSpacing = tightLineSpacing
        self.normalLineSpacing = normalLineSpacing
        self.relaxedLineSpacing = relaxedLineSpacing
    }
}

// MARK: - Spacing Scale

@Model
final class SpacingScale {
    @Attribute(.unique) var id: UUID
    var scaleName: String
    var isActive: Bool

    var extraSmall: Double
    var small: Double
    var medium: Double
    var large: Double
    var extraLarge: Double
    var huge: Double
    var massive: Double

    var cornerRadius: Double
    var cardSpacing: Double
    var sectionSpacing: Double
    var gridSpacing: Double
    var minimumTapTarget: Double

    init(
        id: UUID = UUID(),
        scaleName: String = "default",
        isActive: Bool = true,
        extraSmall: Double = 4,
        small: Double = 8,
        medium: Double = 16,
        large: Double = 24,
        extraLarge: Double = 32,
        huge: Double = 48,
        massive: Double = 64,
        cornerRadius: Double = 12,
        cardSpacing: Double = 16,
        sectionSpacing: Double = 24,
        gridSpacing: Double = 12,
        minimumTapTarget: Double = 44
    ) {
        self.id = id
        self.scaleName = scaleName
        self.isActive = isActive
        self.extraSmall = extraSmall
        self.small = small
        self.medium = medium
        self.large = large
        self.extraLarge = extraLarge
        self.huge = huge
        self.massive = massive
        self.cornerRadius = cornerRadius
        self.cardSpacing = cardSpacing
        self.sectionSpacing = sectionSpacing
        self.gridSpacing = gridSpacing
        self.minimumTapTarget = minimumTapTarget
    }
}

// MARK: - Icon Catalog

@Model
final class IconCatalogItem {
    @Attribute(.unique) var id: UUID
    var symbolName: String  // SF Symbol name
    var displayLabel: String
    var category: String  // "event", "celebration", "nature", "note", "weather", "holiday"
    var isPremium: Bool
    var sortOrder: Int
    var isActive: Bool

    init(
        id: UUID = UUID(),
        symbolName: String,
        displayLabel: String,
        category: String,
        isPremium: Bool = false,
        sortOrder: Int = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.symbolName = symbolName
        self.displayLabel = displayLabel
        self.category = category
        self.isPremium = isPremium
        self.sortOrder = sortOrder
        self.isActive = isActive
    }
}

// MARK: - Weather Icon Mapping

@Model
final class WeatherIconMapping {
    @Attribute(.unique) var id: UUID
    var conditionCode: String  // "clear", "mostlyClear", "partlyCloudy", etc.
    var sfSymbolName: String
    var colorHex: String
    var priority: Int
    var isActive: Bool

    init(
        id: UUID = UUID(),
        conditionCode: String,
        sfSymbolName: String,
        colorHex: String,
        priority: Int = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.conditionCode = conditionCode
        self.sfSymbolName = sfSymbolName
        self.colorHex = colorHex
        self.priority = priority
        self.isActive = isActive
    }
}

// Note: CurrencyDefinition exists as a struct in ExpenseModels.swift
// Future enhancement: Migrate CurrencyDefinition struct to @Model for full database-driven currencies
