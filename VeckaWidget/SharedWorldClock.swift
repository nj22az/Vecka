//
//  SharedWorldClock.swift
//  VeckaWidget
//
//  Shared world clock data for App Group sync between main app and widget
//  情報デザイン: Analog clocks with region-themed colors
//

import Foundation
import SwiftUI

// MARK: - Shared World Clock (Codable for UserDefaults)

/// Lightweight world clock data for widget display
/// Synced via App Group UserDefaults from main app's SwiftData WorldClock model
struct SharedWorldClock: Codable, Identifiable, Hashable {
    let id: UUID
    let cityName: String
    let timezoneIdentifier: String
    let sortOrder: Int

    // MARK: - Computed Properties

    var timezone: TimeZone? {
        TimeZone(identifier: timezoneIdentifier)
    }

    /// Current time in this timezone
    var currentTime: Date {
        Date()
    }

    /// Formatted time string with seconds (e.g., "14:30:45")
    var formattedTime: String {
        guard let tz = timezone else { return "--:--:--" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }

    /// Hour offset from local time (e.g., "+9" or "-5")
    var offsetFromLocal: String {
        guard let tz = timezone else { return "" }
        let localOffset = TimeZone.current.secondsFromGMT()
        let clockOffset = tz.secondsFromGMT()
        let hourDiff = (clockOffset - localOffset) / 3600

        if hourDiff == 0 {
            return "LOCAL"
        } else if hourDiff > 0 {
            return "+\(hourDiff)"
        } else {
            return "\(hourDiff)"
        }
    }

    /// Check if it's currently daytime (6am-6pm) in this timezone
    var isDaytime: Bool {
        guard let tz = timezone else { return true }
        var cal = Calendar.current
        cal.timeZone = tz
        let hour = cal.component(.hour, from: currentTime)
        return hour >= 6 && hour < 18
    }

    /// Get country code from timezone
    var countryCode: String {
        // Map common timezone identifiers to country codes
        let cityPart = timezoneIdentifier.split(separator: "/").last.map(String.init) ?? cityName
        switch cityPart {
        case "Tokyo": return "JP"
        case "Sydney", "Melbourne": return "AU"
        case "London": return "GB"
        case "Paris", "Lyon", "Nice": return "FR"
        case "Berlin", "Munich", "Frankfurt": return "DE"
        case "New_York", "Los_Angeles", "Chicago": return "US"
        case "Stockholm", "Gothenburg": return "SE"
        case "Amsterdam": return "NL"
        case "Hong_Kong": return "HK"
        case "Singapore": return "SG"
        case "Dubai": return "AE"
        case "Moscow": return "RU"
        case "Ho_Chi_Minh", "Hanoi": return "VN"
        case "Seoul": return "KR"
        case "Taipei": return "TW"
        case "Bangkok": return "TH"
        case "Oslo": return "NO"
        case "Copenhagen": return "DK"
        case "Helsinki": return "FI"
        default:
            // Generate from city name
            return cityName.prefix(2).uppercased()
        }
    }

    /// Hour and minute components for analog clock
    var hourAngle: Double {
        guard let tz = timezone else { return 0 }
        var cal = Calendar.current
        cal.timeZone = tz
        let hour = cal.component(.hour, from: currentTime)
        let minute = cal.component(.minute, from: currentTime)
        return Double(hour % 12) * 30 + Double(minute) * 0.5
    }

    var minuteAngle: Double {
        guard let tz = timezone else { return 0 }
        var cal = Calendar.current
        cal.timeZone = tz
        let minute = cal.component(.minute, from: currentTime)
        return Double(minute) * 6
    }
}

// MARK: - App Group Storage

enum WorldClockStorage {
    static let appGroupID = "group.Johansson.Vecka"
    static let worldClocksKey = "shared_world_clocks"

    /// Safely access App Group UserDefaults
    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Save world clocks to App Group (called from main app)
    static func save(_ clocks: [SharedWorldClock]) {
        guard let defaults = sharedDefaults,
              let encoded = try? JSONEncoder().encode(clocks)
        else { return }
        defaults.set(encoded, forKey: worldClocksKey)
    }

    /// Load world clocks from App Group (called from widget)
    /// Returns default clocks if App Group unavailable or empty
    static func load() -> [SharedWorldClock] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: worldClocksKey),
              let clocks = try? JSONDecoder().decode([SharedWorldClock].self, from: data),
              !clocks.isEmpty
        else { return defaultClocks }
        return Array(clocks.prefix(3))
    }

    /// Default clocks when none configured
    static var defaultClocks: [SharedWorldClock] {
        [
            SharedWorldClock(
                id: UUID(),
                cityName: "Stockholm",
                timezoneIdentifier: "Europe/Stockholm",
                sortOrder: 0
            ),
            SharedWorldClock(
                id: UUID(),
                cityName: "Tokyo",
                timezoneIdentifier: "Asia/Tokyo",
                sortOrder: 1
            ),
            SharedWorldClock(
                id: UUID(),
                cityName: "New York",
                timezoneIdentifier: "America/New_York",
                sortOrder: 2
            )
        ]
    }
}

// MARK: - Timezone Theme (情報デザイン: Region-based colors)

/// Region-specific colors matching the main app's TimezoneTheme
enum WidgetTimezoneTheme {
    case nordic      // Blue - Scandinavia
    case european    // Green - Western Europe
    case asian       // Red/Orange - Asia
    case american    // Purple - Americas
    case oceanian    // Teal - Pacific
    case african     // Brown/Orange - Africa/Middle East

    var accentColor: Color {
        switch self {
        case .nordic:    return Color(hex: "4A90D9")  // Swedish blue
        case .european:  return Color(hex: "2ECC71")  // EU green
        case .asian:     return Color(hex: "E74C3C")  // Rising sun red
        case .american:  return Color(hex: "9B59B6")  // Purple
        case .oceanian:  return Color(hex: "1ABC9C")  // Ocean teal
        case .african:   return Color(hex: "E67E22")  // Sahara orange
        }
    }

    var lightBackground: Color {
        switch self {
        case .nordic:    return Color(hex: "E8F4FD")
        case .european:  return Color(hex: "E8F8F0")
        case .asian:     return Color(hex: "FDEDEC")
        case .american:  return Color(hex: "F4ECF7")
        case .oceanian:  return Color(hex: "E8F6F3")
        case .african:   return Color(hex: "FDF2E9")
        }
    }

    static func theme(for timezoneId: String) -> WidgetTimezoneTheme {
        let parts = timezoneId.split(separator: "/")
        guard let region = parts.first else { return .european }

        switch String(region) {
        case "Europe":
            // Check for Nordic countries
            let city = parts.last.map(String.init) ?? ""
            let nordicCities = ["Stockholm", "Oslo", "Copenhagen", "Helsinki", "Gothenburg", "Malmö"]
            if nordicCities.contains(city) {
                return .nordic
            }
            return .european
        case "Asia":
            return .asian
        case "America":
            return .american
        case "Australia", "Pacific":
            return .oceanian
        case "Africa":
            return .african
        default:
            return .european
        }
    }
}
