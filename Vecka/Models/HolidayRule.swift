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
    var region: String // "SE", "US", "VN", "CUSTOM"
    @Attribute(originalName: "isRedDay")
    var isBankHoliday: Bool // True = Bank Holiday, False = Observance

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

    /// 情報デザイン: Local language name (e.g., "Julafton" for Christmas Eve in Swedish)
    /// Shown alongside English name for authenticity
    var localName: String?

    // MARK: - 情報デザイン: Editable Holiday Database Fields

    /// True if this rule was seeded from defaults (can be reset)
    var isSystemDefault: Bool = false

    /// Whether this rule is active (soft delete = disabled)
    var isEnabled: Bool = true

    /// Original rule JSON for "Reset to Default" feature
    var originalDefaultJSON: String?

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
        isBankHoliday: Bool,
        titleOverride: String? = nil,
        symbolName: String? = nil,
        iconColor: String? = nil,
        userModifiedAt: Date? = nil,
        notes: String? = nil,
        localName: String? = nil,
        type: HolidayRuleType,
        month: Int? = nil,
        day: Int? = nil,
        daysOffset: Int? = nil,
        weekday: Int? = nil,
        ordinal: Int? = nil,
        dayRangeStart: Int? = nil,
        dayRangeEnd: Int? = nil,
        isSystemDefault: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = "\(region)-\(name)"
        self.name = name
        self.region = region
        self.isBankHoliday = isBankHoliday
        self.titleOverride = titleOverride
        self.symbolName = symbolName
        self.iconColor = iconColor
        self.userModifiedAt = userModifiedAt
        self.notes = notes
        self.localName = localName
        self.type = type
        self.month = month
        self.day = day
        self.daysOffset = daysOffset
        self.weekday = weekday
        self.ordinal = ordinal
        self.dayRangeStart = dayRangeStart
        self.dayRangeEnd = dayRangeEnd
        self.isSystemDefault = isSystemDefault
        self.isEnabled = isEnabled

        // Store original JSON for system defaults (for reset feature)
        if isSystemDefault {
            self.originalDefaultJSON = self.toJSON()
        }

        // Validate parameters match the rule type in debug builds
        #if DEBUG
        if let error = validationError {
            Log.w("HolidayRule validation warning for '\(name)': \(error)")
        }
        #endif
    }

    // MARK: - JSON Serialization (for changelog/reset)

    func toJSON() -> String {
        let snapshot = HolidayRuleSnapshot(from: self)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(snapshot),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    /// Whether this rule has been modified from its default
    var isModifiedFromDefault: Bool {
        guard isSystemDefault else { return false }
        return userModifiedAt != nil
    }

    /// Whether this rule can be reset to default
    var canResetToDefault: Bool {
        isSystemDefault && isModifiedFromDefault && originalDefaultJSON != nil
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
