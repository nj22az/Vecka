//
//  HolidaySymbolCatalog.swift
//  Vecka
//
//  情報デザイン: Curated SF Symbols for holidays (JSON-driven)
//

import Foundation

enum HolidaySymbolCatalog {
    /// Get default SF Symbol for a holiday name
    static func defaultSymbolName(for name: String, isBankHoliday: Bool) -> String? {
        if name.hasPrefix("holiday.") {
            if let match = HolidaySymbolsLoader.holidayDefaults[name] {
                return match
            }
        }
        return isBankHoliday ? HolidaySymbolsLoader.defaultBankHoliday : HolidaySymbolsLoader.defaultObservance
    }

    /// Suggested SF Symbols for holiday picker
    static var suggestedSymbols: [String] {
        HolidaySymbolsLoader.suggestedSymbols
    }

    /// Get human-readable label for an SF Symbol
    static func label(for symbol: String) -> String {
        HolidaySymbolsLoader.labels[symbol] ?? symbol
    }
}

// MARK: - JSON Loader (情報デザイン: Database-driven symbols)

private enum HolidaySymbolsLoader {
    /// Holiday name to symbol mapping
    static let holidayDefaults: [String: String] = {
        Dictionary(uniqueKeysWithValues: loadedData.holidayDefaults.map { ($0.pattern, $0.symbol) })
    }()

    /// Suggested symbols for picker
    static let suggestedSymbols: [String] = {
        loadedData.suggestedSymbols.map { $0.symbol }
    }()

    /// Symbol to label mapping
    static let labels: [String: String] = {
        Dictionary(uniqueKeysWithValues: loadedData.suggestedSymbols.map { ($0.symbol, $0.label) })
    }()

    /// Default symbol for bank holidays
    static let defaultBankHoliday: String = {
        loadedData.defaultBankHoliday
    }()

    /// Default symbol for observances
    static let defaultObservance: String = {
        loadedData.defaultObservance
    }()

    /// Loaded JSON data with fallback
    private static let loadedData: HolidaySymbolsJSON = {
        guard let url = Bundle.main.url(forResource: "holiday-symbols", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONDecoder().decode(HolidaySymbolsJSON.self, from: data) else {
            Log.e("Failed to load holiday-symbols.json")
            return defaultData
        }
        Log.i("Loaded \(json.suggestedSymbols.count) holiday symbols from JSON")
        return json
    }()

    /// Fallback data if JSON fails to load
    private static let defaultData = HolidaySymbolsJSON(
        holidayDefaults: [
            HolidayDefaultDTO(pattern: "holiday.juldagen", symbol: "gift.fill"),
            HolidayDefaultDTO(pattern: "holiday.julafton", symbol: "gift"),
            HolidayDefaultDTO(pattern: "holiday.nyarsdagen", symbol: "sparkles")
        ],
        suggestedSymbols: [
            SuggestedSymbolDTO(symbol: "flag.fill", label: "Flag"),
            SuggestedSymbolDTO(symbol: "star", label: "Star"),
            SuggestedSymbolDTO(symbol: "sparkles", label: "Sparkles"),
            SuggestedSymbolDTO(symbol: "gift.fill", label: "Gift"),
            SuggestedSymbolDTO(symbol: "heart.fill", label: "Heart")
        ],
        defaultBankHoliday: "flag.fill",
        defaultObservance: "star"
    )
}

// MARK: - JSON DTOs

private struct HolidaySymbolsJSON: Codable {
    let holidayDefaults: [HolidayDefaultDTO]
    let suggestedSymbols: [SuggestedSymbolDTO]
    let defaultBankHoliday: String
    let defaultObservance: String
}

private struct HolidayDefaultDTO: Codable {
    let pattern: String
    let symbol: String
}

private struct SuggestedSymbolDTO: Codable {
    let symbol: String
    let label: String
}
