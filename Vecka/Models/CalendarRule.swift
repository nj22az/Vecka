//
//  CalendarRule.swift
//  Vecka
//
//  The "DNA" of the Calendar System.
//  Stores configuration for week calculation (ISO8601 vs US, etc.)
//

import Foundation
import SwiftData

@Model
final class CalendarRule {
    @Attribute(.unique) var id: String // e.g., "SE", "US"
    
    // Calendar Configuration
    var identifier: String // "gregorian", "iso8601"
    var firstWeekday: Int // 1=Sunday, 2=Monday
    var minimumDaysInFirstWeek: Int // 1 or 4 (ISO8601 = 4)
    var localeIdentifier: String // "sv_SE", "en_US"
    
    // Secondary Calendar (e.g., Lunar)
    var secondaryCalendarIdentifier: String? // "chinese", "hebrew", "islamic"
    
    // Active Status
    var isActive: Bool
    
    init(
        regionCode: String = "SE",
        identifier: String = "gregorian", // ISO8601 is often implemented via Gregorian with params
        firstWeekday: Int = 2, // Monday
        minimumDaysInFirstWeek: Int = 4, // ISO8601 standard
        localeIdentifier: String = "sv_SE",
        secondaryCalendarIdentifier: String? = nil,
        isActive: Bool = true
    ) {
        self.id = regionCode
        self.identifier = identifier
        self.firstWeekday = firstWeekday
        self.minimumDaysInFirstWeek = minimumDaysInFirstWeek
        self.localeIdentifier = localeIdentifier
        self.secondaryCalendarIdentifier = secondaryCalendarIdentifier
        self.isActive = isActive
    }
}
