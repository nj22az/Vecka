//
//  CountdownModels.swift
//  Vecka
//
//  Extracted models for countdown functionality
//

import Foundation
import SwiftUI

// MARK: - Event Task Model (情報デザイン: Checklist items for events)

/// A single task/checklist item for an event
/// Inspired by Swift Playgrounds Date Planner, styled for 情報デザイン
struct EventTask: Identifiable, Hashable, Codable {
    var id = UUID()
    var text: String
    var isCompleted: Bool = false

    init(text: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.text = text
        self.isCompleted = isCompleted
    }
}

// MARK: - Countdown Models

/// Custom countdown event with XPC-safe operations
struct CustomCountdown: Codable, Hashable {
    let name: String
    let date: Date
    let isAnnual: Bool
    let iconName: String?
    var tasks: [EventTask]  // 情報デザイン: Checklist items for event preparation

    // Cache month and day components to avoid XPC-sensitive operations
    private let cachedMonth: Int?
    private let cachedDay: Int?

    // MARK: - Computed Properties (情報デザイン: Task completion status)

    /// Number of incomplete tasks remaining
    var remainingTaskCount: Int {
        tasks.filter { !$0.isCompleted && !$0.text.isEmpty }.count
    }

    /// Whether all tasks are complete
    var isComplete: Bool {
        tasks.isEmpty || tasks.allSatisfy { $0.isCompleted || $0.text.isEmpty }
    }

    // MARK: - Initializers

    init(name: String, date: Date, isAnnual: Bool, iconName: String? = nil, tasks: [EventTask] = []) {
        self.name = name
        self.date = date
        self.isAnnual = isAnnual
        self.iconName = iconName
        self.tasks = tasks

        // Pre-compute and cache month/day components during initialization
        if isAnnual {
            let calendar = Calendar.iso8601
            let components = calendar.dateComponents([.month, .day], from: date)
            self.cachedMonth = components.month
            self.cachedDay = components.day
        } else {
            self.cachedMonth = nil
            self.cachedDay = nil
        }
    }
    
    // MARK: - Codable Support with Backward Compatibility

    private enum CodingKeys: String, CodingKey {
        case name, date, isAnnual, cachedMonth, cachedDay, iconName, tasks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        date = try container.decode(Date.self, forKey: .date)
        isAnnual = try container.decode(Bool.self, forKey: .isAnnual)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName)

        // Decode tasks with backward compatibility (empty array if not present)
        tasks = try container.decodeIfPresent([EventTask].self, forKey: .tasks) ?? []

        // Handle cached components with backward compatibility
        if let month = try container.decodeIfPresent(Int.self, forKey: .cachedMonth),
           let day = try container.decodeIfPresent(Int.self, forKey: .cachedDay) {
            self.cachedMonth = month
            self.cachedDay = day
        } else if isAnnual {
            // Fallback: compute during decoding for backward compatibility
            let calendar = Calendar.iso8601
            let components = calendar.dateComponents([.month, .day], from: date)
            self.cachedMonth = components.month
            self.cachedDay = components.day
        } else {
            self.cachedMonth = nil
            self.cachedDay = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(date, forKey: .date)
        try container.encode(isAnnual, forKey: .isAnnual)
        try container.encodeIfPresent(cachedMonth, forKey: .cachedMonth)
        try container.encodeIfPresent(cachedDay, forKey: .cachedDay)
        try container.encodeIfPresent(iconName, forKey: .iconName)
        try container.encode(tasks, forKey: .tasks)
    }
    
    // MARK: - Target Date Calculation
    
    /// Compute target date for countdown (XPC-safe)
    func computeTargetDate(for currentYear: Int) -> Date? {
        if isAnnual {
            guard let month = cachedMonth, let day = cachedDay else {
                return date // Fallback to original date
            }
            
            let calendar = Calendar.iso8601
            var components = DateComponents()
            components.year = currentYear
            components.month = month
            components.day = day
            
            guard let targetDate = calendar.date(from: components) else {
                return date // Fallback to original date
            }
            
            // If target date has passed this year, use next year
            if targetDate < Date() {
                components.year = currentYear + 1
                return calendar.date(from: components) ?? date
            }
            
            return targetDate
        } else {
            return date
        }
    }
}

/// Predefined countdown types
enum CountdownType: String, CaseIterable, Codable {
    case newYear = "new_year"
    case christmas = "christmas"
    case summer = "summer"
    case valentines = "valentines"
    case halloween = "halloween"
    case midsummer = "midsummer"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .newYear: return "New Year"
        case .christmas: return "Christmas"
        case .summer: return "Summer"
        case .valentines: return "Valentine's Day"
        case .halloween: return "Halloween"
        case .midsummer: return "Midsummer"
        case .custom: return "Custom Event"
        }
    }
    
    var icon: String {
        switch self {
        case .newYear: return "sparkles"
        case .christmas: return "tree.fill"
        case .summer: return "sun.max.fill"
        case .valentines: return "heart.fill"
        case .halloween: return "moon.stars.fill"
        case .midsummer: return "leaf.fill"
        case .custom: return "calendar.badge.plus"
        }
    }
    
    var targetDate: Date {
        // Backward-compat convenience; uses "today" as the base date
        return targetDate(from: Date())
    }

    /// Target date computed using an arbitrary base date (e.g. selectedDate).
    /// This lets the UI show countdown relative to the currently selected day/week.
    func targetDate(from baseDate: Date) -> Date {
        let calendar = Calendar.iso8601
        let baseYear = calendar.component(.year, from: baseDate)

        var components = DateComponents()
        components.year = baseYear

        switch self {
        case .newYear:
            components.month = 1
            components.day = 1
        case .christmas:
            components.month = 12
            components.day = 25
        case .summer:
            components.month = 6
            components.day = 21
        case .valentines:
            components.month = 2
            components.day = 14
        case .halloween:
            components.month = 10
            components.day = 31
        case .midsummer:
            components.month = 6
            components.day = 24
        case .custom:
            return baseDate
        }

        guard let dateThisYear = calendar.date(from: components) else {
            return baseDate
        }

        // If the date has passed relative to the base date's start of day, use next year
        let startOfBase = calendar.startOfDay(for: baseDate)
        if dateThisYear < startOfBase {
            components.year = baseYear + 1
            return calendar.date(from: components) ?? dateThisYear
        }

        return dateThisYear
    }
}

// MARK: - Saved Countdown (Favorites)
struct SavedCountdown: Codable, Hashable, Identifiable {
    let type: CountdownType
    let custom: CustomCountdown?
    var id: String { type == .custom ? (custom?.name ?? "custom") + "_" + String(custom?.date.timeIntervalSince1970 ?? 0) : type.rawValue }
    
    var displayName: String {
        if type == .custom { return custom?.name ?? "Custom" }
        return type.displayName
    }
    
    var icon: String {
        if type == .custom { return custom?.iconName ?? CountdownType.custom.icon }
        return type.icon
    }
}
