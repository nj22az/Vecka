//
//  WorldCityDatabase.swift
//  Vecka
//
//  情報デザイン: JSON-driven world city database for timezone lookup
//  Supports intelligent search by city name, country, or region
//

import Foundation

/// A world city with timezone information
struct WorldCity: Identifiable, Hashable, Codable {
    var id: String { code }  // Use code as stable ID for Codable
    let name: String
    let country: String
    let countryCode: String  // ISO 3166-1 alpha-2
    let timezone: String     // IANA timezone identifier
    let code: String         // 3-letter city code
    let region: String       // Region name (lowercase)

    /// Search keywords (city + country + aliases)
    var searchKeywords: String {
        "\(name) \(country) \(countryCode) \(code)".lowercased()
    }

    /// Get WorldRegion enum from string
    var worldRegion: WorldRegion {
        WorldRegion(rawValue: region) ?? .europe
    }

    // Custom coding keys to match JSON
    enum CodingKeys: String, CodingKey {
        case name, country, countryCode, timezone, code, region
    }
}

/// World regions for color theming (情報デザイン)
enum WorldRegion: String, CaseIterable, Codable {
    case europe = "europe"
    case asia = "asia"
    case northAmerica = "northAmerica"
    case southAmerica = "southAmerica"
    case africa = "africa"
    case oceania = "oceania"
    case middleEast = "middleEast"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .europe: return "Europe"
        case .asia: return "Asia"
        case .northAmerica: return "North America"
        case .southAmerica: return "South America"
        case .africa: return "Africa"
        case .oceania: return "Oceania"
        case .middleEast: return "Middle East"
        }
    }
}

/// Comprehensive world city database with intelligent search
/// 情報デザイン: JSON-driven for easy updates without recompilation
struct WorldCityDatabase {

    // MARK: - Database (Lazy-loaded from JSON)

    /// All world cities loaded from JSON
    static let cities: [WorldCity] = {
        guard let url = Bundle.main.url(forResource: "world-cities", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cities = try? JSONDecoder().decode([WorldCity].self, from: data) else {
            Log.e("Failed to load world-cities.json")
            return []
        }
        Log.i("Loaded \(cities.count) world cities from JSON")
        return cities
    }()

    // MARK: - Search Functions

    /// Search cities by name, country, or code (情報デザイン: intelligent matching)
    /// - Parameter query: Search string
    /// - Returns: Matching cities, sorted by relevance
    static func search(_ query: String) -> [WorldCity] {
        let trimmedQuery = query.trimmed.lowercased()
        guard !trimmedQuery.isEmpty else { return [] }

        // Score and filter cities
        var scored: [(city: WorldCity, score: Int)] = []

        for city in cities {
            var score = 0
            let cityLower = city.name.lowercased()
            let countryLower = city.country.lowercased()
            let codeLower = city.code.lowercased()

            // Exact city name match (highest priority)
            if cityLower == trimmedQuery {
                score = 100
            }
            // City name starts with query
            else if cityLower.hasPrefix(trimmedQuery) {
                score = 80
            }
            // Exact code match
            else if codeLower == trimmedQuery {
                score = 75
            }
            // Exact country match
            else if countryLower == trimmedQuery {
                score = 70
            }
            // Country starts with query
            else if countryLower.hasPrefix(trimmedQuery) {
                score = 60
            }
            // City name contains query
            else if cityLower.contains(trimmedQuery) {
                score = 50
            }
            // Country contains query
            else if countryLower.contains(trimmedQuery) {
                score = 40
            }
            // Any keyword contains query
            else if city.searchKeywords.contains(trimmedQuery) {
                score = 30
            }

            if score > 0 {
                scored.append((city, score))
            }
        }

        // Sort by score descending, then alphabetically
        return scored
            .sorted { $0.score > $1.score || ($0.score == $1.score && $0.city.name < $1.city.name) }
            .prefix(20)
            .map { $0.city }
    }

    /// Get timezone for a city or country name
    static func timezone(for query: String) -> TimeZone? {
        guard let city = search(query).first else { return nil }
        return TimeZone(identifier: city.timezone)
    }

    /// Get default city (STM - Stora Mellösa)
    static var defaultCity: WorldCity {
        cities.first { $0.code == "STM" } ?? cities.first ?? WorldCity(
            name: "Stockholm",
            country: "Sweden",
            countryCode: "SE",
            timezone: "Europe/Stockholm",
            code: "STM",
            region: "europe"
        )
    }

    /// Get cities by region
    static func cities(in region: WorldRegion) -> [WorldCity] {
        cities.filter { $0.region == region.rawValue }
    }

    /// Get city by code
    static func city(byCode code: String) -> WorldCity? {
        cities.first { $0.code == code }
    }

    // MARK: - Capital City Lookup (情報デザイン: Auto-derive clocks from holiday regions)

    /// Maps ISO country codes to their capital/primary city name
    private static let capitalCityNames: [String: String] = [
        "SE": "Stockholm",
        "NO": "Oslo",
        "DK": "Copenhagen",
        "FI": "Helsinki",
        "IS": "Reykjavik",
        "GL": "Nuuk",
        "FO": "Tórshavn",
        "VN": "Hanoi",
        "JP": "Tokyo",
        "GB": "London",
        "US": "New York",
        "DE": "Berlin",
        "FR": "Paris",
        "ES": "Madrid",
        "IT": "Rome",
        "NL": "Amsterdam",
        "AU": "Sydney",
        "KR": "Seoul",
    ]

    /// Get capital/primary city for a country code
    static func capitalCity(forCountryCode code: String) -> WorldCity? {
        let upper = code.uppercased()
        // Try named capital first
        if let capitalName = capitalCityNames[upper],
           let city = cities.first(where: { $0.countryCode == upper && $0.name == capitalName }) {
            return city
        }
        // Fallback: first city matching the country code
        return cities.first(where: { $0.countryCode == upper })
    }

    /// Derive up to 3 unique-timezone world clocks from selected holiday regions
    static func clockCities(for regions: HolidayRegionSelection) -> [WorldCity] {
        var seenTimezones = Set<String>()
        var result: [WorldCity] = []

        for code in regions.expandedRegions {
            guard result.count < 3 else { break }
            guard let city = capitalCity(forCountryCode: code) else { continue }
            // De-duplicate by timezone (Nordic countries share Europe/Stockholm etc.)
            guard !seenTimezones.contains(city.timezone) else { continue }
            seenTimezones.insert(city.timezone)
            result.append(city)
        }

        return result
    }
}
