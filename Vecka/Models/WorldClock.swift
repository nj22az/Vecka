//
//  WorldClock.swift
//  Vecka
//
//  SwiftData model for world clocks on Onsen landing page
//  情報デザイン: Expandable row of timezone widgets
//

import Foundation
import SwiftData

/// A saved world clock for the Onsen landing page
@Model
final class WorldClock {
    var id: UUID
    var cityName: String
    var timezoneIdentifier: String
    var sortOrder: Int
    var dateCreated: Date

    init(
        cityName: String,
        timezoneIdentifier: String,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.cityName = cityName
        self.timezoneIdentifier = timezoneIdentifier
        self.sortOrder = sortOrder
        self.dateCreated = Date()
    }

    // MARK: - Computed Properties

    var timezone: TimeZone? {
        TimeZone(identifier: timezoneIdentifier)
    }

    /// Current time in this timezone
    var currentTime: Date {
        Date()
    }

    /// Formatted time string (e.g., "14:30")
    var formattedTime: String {
        guard let tz = timezone else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }

    /// Formatted time with seconds
    var formattedTimeWithSeconds: String {
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
        let calendar = Calendar.current
        var cal = calendar
        cal.timeZone = tz
        let hour = cal.component(.hour, from: currentTime)
        return hour >= 6 && hour < 18
    }
}

// MARK: - Predefined World Clocks (情報デザイン: City Code Pills)

extension WorldClock {
    /// Common timezone presets for quick setup
    /// 情報デザイン compliant: Uses 3-letter city codes, NO emoji flags
    /// STM (Stora Mellösa) is the default - a nod to the developer
    static let presets: [(name: String, timezone: String, code: String)] = [
        // Default: Stora Mellösa, Sweden (developer's hometown)
        ("Stora Mellösa", "Europe/Stockholm", "STM"),
        // Major cities
        ("Tokyo", "Asia/Tokyo", "TYO"),
        ("New York", "America/New_York", "NYC"),
        ("London", "Europe/London", "LON"),
        ("Paris", "Europe/Paris", "PAR"),
        ("Sydney", "Australia/Sydney", "SYD"),
        ("Los Angeles", "America/Los_Angeles", "LAX"),
        ("Berlin", "Europe/Berlin", "BER"),
        ("Singapore", "Asia/Singapore", "SIN"),
        ("Dubai", "Asia/Dubai", "DXB"),
        ("Hong Kong", "Asia/Hong_Kong", "HKG"),
        ("Seoul", "Asia/Seoul", "SEL"),
        ("Mumbai", "Asia/Kolkata", "BOM"),
        ("São Paulo", "America/Sao_Paulo", "GRU"),
        ("Moscow", "Europe/Moscow", "MOW"),
        ("Stockholm", "Europe/Stockholm", "ARN"),
        ("Ho Chi Minh", "Asia/Ho_Chi_Minh", "SGN"),
        ("Bangkok", "Asia/Bangkok", "BKK"),
        ("Amsterdam", "Europe/Amsterdam", "AMS"),
        ("Zurich", "Europe/Zurich", "ZRH"),
        ("Toronto", "America/Toronto", "YYZ"),
        // Scandinavian cities
        ("Oslo", "Europe/Oslo", "OSL"),
        ("Copenhagen", "Europe/Copenhagen", "CPH"),
        ("Helsinki", "Europe/Helsinki", "HEL"),
        ("Gothenburg", "Europe/Stockholm", "GOT"),
        ("Malmö", "Europe/Stockholm", "MMA"),
        // European cities
        ("Madrid", "Europe/Madrid", "MAD"),
        ("Rome", "Europe/Rome", "ROM"),
        ("Vienna", "Europe/Vienna", "VIE"),
        ("Prague", "Europe/Prague", "PRG"),
        ("Warsaw", "Europe/Warsaw", "WAW"),
        ("Athens", "Europe/Athens", "ATH"),
        ("Istanbul", "Europe/Istanbul", "IST"),
        // Asian cities
        ("Shanghai", "Asia/Shanghai", "SHA"),
        ("Beijing", "Asia/Shanghai", "PEK"),
        ("Taipei", "Asia/Taipei", "TPE"),
        ("Manila", "Asia/Manila", "MNL"),
        ("Jakarta", "Asia/Jakarta", "JKT"),
        ("Kuala Lumpur", "Asia/Kuala_Lumpur", "KUL"),
        ("Hanoi", "Asia/Ho_Chi_Minh", "HAN"),
        // American cities
        ("Chicago", "America/Chicago", "CHI"),
        ("Miami", "America/New_York", "MIA"),
        ("San Francisco", "America/Los_Angeles", "SFO"),
        ("Seattle", "America/Los_Angeles", "SEA"),
        ("Denver", "America/Denver", "DEN"),
        ("Vancouver", "America/Vancouver", "YVR"),
        ("Mexico City", "America/Mexico_City", "MEX"),
        // Oceania
        ("Melbourne", "Australia/Melbourne", "MEL"),
        ("Auckland", "Pacific/Auckland", "AKL"),
        // Africa & Middle East
        ("Cairo", "Africa/Cairo", "CAI"),
        ("Johannesburg", "Africa/Johannesburg", "JNB"),
        ("Tel Aviv", "Asia/Jerusalem", "TLV"),
        ("Riyadh", "Asia/Riyadh", "RUH")
    ]

    /// Get 3-letter city code for this timezone (情報デザイン compliant)
    var cityCode: String {
        // First check if cityName matches a preset
        if let preset = WorldClock.presets.first(where: { $0.name.lowercased() == cityName.lowercased() }) {
            return preset.code
        }
        // Otherwise generate from city name
        return cityName.prefix(3).uppercased()
    }

    /// Get country code (ISO 3166-1 alpha-2) from WorldCityDatabase
    /// 情報デザイン: Shows country pill instead of city code for clarity
    var countryCode: String {
        // Look up in WorldCityDatabase
        if let city = WorldCityDatabase.cities.first(where: { $0.name.lowercased() == cityName.lowercased() }) {
            return city.countryCode
        }
        // Fallback: try to extract from timezone identifier
        let tzParts = timezoneIdentifier.split(separator: "/")
        if tzParts.count >= 2 {
            // Map common continent/city patterns to country codes
            let cityPart = String(tzParts.last ?? "")
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
            default: break
            }
        }
        // Ultimate fallback: use city code
        return cityCode
    }

    /// Look up timezone from city name (情報デザイン: Any city input)
    /// Returns nil if city not found in presets
    static func timezone(forCity cityName: String) -> String? {
        // Exact match first
        if let preset = presets.first(where: { $0.name.lowercased() == cityName.lowercased() }) {
            return preset.timezone
        }
        // Partial match
        if let preset = presets.first(where: { $0.name.lowercased().contains(cityName.lowercased()) }) {
            return preset.timezone
        }
        // Check if cityName is a timezone identifier directly
        if TimeZone(identifier: cityName) != nil {
            return cityName
        }
        return nil
    }

    /// Get 3-letter code for a city name
    static func code(forCity cityName: String) -> String {
        if let preset = presets.first(where: { $0.name.lowercased() == cityName.lowercased() }) {
            return preset.code
        }
        return cityName.prefix(3).uppercased()
    }
}
