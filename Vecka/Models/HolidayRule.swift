//
//  HolidayRule.swift
//  Vecka
//
//  The "DNA" of the Holiday Engine.
//  Stores the LOGIC for calculating holidays, not the dates themselves.
//

import Foundation
import SwiftData

enum HolidayRuleType: String, Codable {
    case fixed          // e.g., Christmas Eve (Dec 24)
    case easterRelative // e.g., Good Friday (-2 days from Easter)
    case floating       // e.g., Midsummer (Saturday between June 20-26)
    case nthWeekday     // e.g., Father's Day (2nd Sunday in Nov), Mother's Day (Last Sunday in May)
    case lunar          // e.g., Tet (1st day of 1st Lunar Month)
    case astronomical   // e.g., Solstices and Equinoxes
}

@Model
final class HolidayRule {
    @Attribute(.unique) var id: String
    
    var name: String
    var region: String // "SE", "US", etc.
    var isRedDay: Bool // True = Red Day (Holiday), False = Observance (Valentine's)

    /// Optional user-facing title override (shown instead of localization key or name).
    var titleOverride: String?

    /// Optional SF Symbol name used in the UI/calendar.
    var symbolName: String?

    /// Optional icon background color (hex string, e.g., "FFB5BA")
    var iconColor: String?

    /// Set when the user edits a rule; used to avoid overwriting user changes in migrations.
    var userModifiedAt: Date?

    /// Optional notes/description for the observance
    var notes: String?

    // Rule Configuration
    var type: HolidayRuleType
    
    // Parameters (Optional based on type)
    var month: Int?
    var day: Int?
    var daysOffset: Int?      // For Easter
    var weekday: Int?         // 1=Sunday, 2=Monday...
    var ordinal: Int?         // 1=1st, 2=2nd, -1=Last
    var dayRangeStart: Int?   // For floating (e.g., 20)
    var dayRangeEnd: Int?     // For floating (e.g., 26)
    
    init(
        name: String,
        region: String = "SE",
        isRedDay: Bool,
        titleOverride: String? = nil,
        symbolName: String? = nil,
        iconColor: String? = nil,
        userModifiedAt: Date? = nil,
        notes: String? = nil,
        type: HolidayRuleType,
        month: Int? = nil,
        day: Int? = nil,
        daysOffset: Int? = nil,
        weekday: Int? = nil,
        ordinal: Int? = nil,
        dayRangeStart: Int? = nil,
        dayRangeEnd: Int? = nil
    ) {
        self.id = "\(region)-\(name)"
        self.name = name
        self.region = region
        self.isRedDay = isRedDay
        self.titleOverride = titleOverride
        self.symbolName = symbolName
        self.iconColor = iconColor
        self.userModifiedAt = userModifiedAt
        self.notes = notes
        self.type = type
        self.month = month
        self.day = day
        self.daysOffset = daysOffset
        self.weekday = weekday
        self.ordinal = ordinal
        self.dayRangeStart = dayRangeStart
        self.dayRangeEnd = dayRangeEnd

        // Validate parameters match the rule type in debug builds
        #if DEBUG
        if let error = validationError {
            Log.w("HolidayRule validation warning for '\(name)': \(error)")
        }
        #endif
    }

    // MARK: - Validation

    /// Returns nil if the rule is valid, otherwise returns an error description
    var validationError: String? {
        // Validate month range (1-12)
        if let m = month, (m < 1 || m > 12) {
            return "Month must be between 1 and 12, got \(m)"
        }

        // Validate day range (1-31)
        if let d = day, (d < 1 || d > 31) {
            return "Day must be between 1 and 31, got \(d)"
        }

        // Validate weekday range (1-7, where 1=Sunday)
        if let w = weekday, (w < 1 || w > 7) {
            return "Weekday must be between 1 and 7, got \(w)"
        }

        // Type-specific validation
        switch type {
        case .fixed:
            if month == nil || day == nil {
                return "Fixed holiday requires month and day"
            }
        case .easterRelative:
            if daysOffset == nil {
                return "Easter-relative holiday requires daysOffset"
            }
        case .floating:
            if month == nil || weekday == nil || dayRangeStart == nil || dayRangeEnd == nil {
                return "Floating holiday requires month, weekday, dayRangeStart, and dayRangeEnd"
            }
            if let start = dayRangeStart, let end = dayRangeEnd, start > end {
                return "dayRangeStart (\(start)) must be <= dayRangeEnd (\(end))"
            }
        case .nthWeekday:
            if month == nil || weekday == nil || ordinal == nil {
                return "Nth weekday holiday requires month, weekday, and ordinal"
            }
        case .lunar:
            if month == nil || day == nil {
                return "Lunar holiday requires month and day"
            }
        case .astronomical:
            if month == nil {
                return "Astronomical event requires month (3, 6, 9, or 12)"
            }
            if let m = month, ![3, 6, 9, 12].contains(m) {
                return "Astronomical event month must be 3, 6, 9, or 12 (got \(m))"
            }
        }

        return nil
    }

    /// Whether this rule has valid parameters for its type
    var isValid: Bool {
        validationError == nil
    }
}
