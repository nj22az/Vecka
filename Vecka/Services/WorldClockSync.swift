//
//  WorldClockSync.swift
//  Vecka
//
//  Syncs world clocks to App Group for widget access
//  情報デザイン: Shared data between main app and widget
//

import Foundation

// MARK: - Shared World Clock (Codable for UserDefaults)

/// Lightweight world clock data for widget display
/// Synced via App Group UserDefaults from main app's SwiftData WorldClock model
struct SharedWorldClock: Codable, Identifiable, Hashable {
    let id: UUID
    let cityName: String
    let timezoneIdentifier: String
    let sortOrder: Int
}

// MARK: - App Group Storage

enum WorldClockStorage {
    static let appGroupID = "group.Johansson.Vecka"
    static let worldClocksKey = "shared_world_clocks"

    /// Safely access App Group UserDefaults (returns nil if unavailable)
    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Save world clocks to App Group (called from main app)
    /// Silently fails if App Group is unavailable - widget will use defaults
    static func save(_ clocks: [SharedWorldClock]) {
        guard let defaults = sharedDefaults else { return }
        guard let encoded = try? JSONEncoder().encode(clocks) else { return }
        defaults.set(encoded, forKey: worldClocksKey)
    }

    /// Load world clocks from App Group (called from widget)
    /// Returns empty array if App Group is unavailable
    static func load() -> [SharedWorldClock] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: worldClocksKey),
              let clocks = try? JSONDecoder().decode([SharedWorldClock].self, from: data)
        else { return [] }
        return Array(clocks.prefix(3))
    }
}
