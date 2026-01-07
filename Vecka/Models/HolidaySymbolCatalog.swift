//
//  HolidaySymbolCatalog.swift
//  Vecka
//
//  Curated SF Symbols used for holidays.
//

import Foundation

enum HolidaySymbolCatalog {
    static func defaultSymbolName(for name: String, isBankHoliday: Bool) -> String? {
        if name.hasPrefix("holiday.") {
            switch name {
            case "holiday.juldagen", "holiday.annandag_jul": return "gift.fill"
            case "holiday.julafton": return "gift"
            case "holiday.nyarsdagen", "holiday.nyarsafton": return "sparkles"
            case "holiday.paskdagen", "holiday.annandag_pask": return "sun.max.fill"
            case "holiday.langfredagen": return "cross.fill"
            case "holiday.kristi_himmelsfardsdag": return "cloud.sun.fill"
            case "holiday.midsommardagen", "holiday.midsommarafton": return "leaf.fill"
            case "holiday.alla_hjartans_dag": return "heart.fill"
            default: break
            }
        }

        return isBankHoliday ? "flag.fill" : "star"
    }

    static let suggestedSymbols: [String] = [
        "flag.fill",
        "flag",
        "star",
        "star.fill",
        "sparkles",
        "gift",
        "gift.fill",
        "heart",
        "heart.fill",
        "birthday.cake",
        "balloon.2",
        "trophy.fill",
        "leaf.fill",
        "sun.max.fill",
        "snowflake",
        "cloud.sun.fill",
        "bell.fill",
        "graduationcap.fill",
        "airplane",
        "briefcase.fill"
    ]

    static func label(for symbol: String) -> String {
        labels[symbol] ?? symbol
    }

    private static let labels: [String: String] = [
        "flag.fill": "Flag",
        "flag": "Flag (Outline)",
        "star": "Star",
        "star.fill": "Star (Filled)",
        "sparkles": "Sparkles",
        "gift": "Gift",
        "gift.fill": "Gift (Filled)",
        "heart": "Heart",
        "heart.fill": "Heart (Filled)",
        "birthday.cake": "Cake",
        "balloon.2": "Balloons",
        "trophy.fill": "Trophy",
        "leaf.fill": "Leaf",
        "sun.max.fill": "Sun",
        "snowflake": "Snowflake",
        "cloud.sun.fill": "Cloud & Sun",
        "bell.fill": "Bell",
        "graduationcap.fill": "Graduation Cap",
        "airplane": "Airplane",
        "briefcase.fill": "Briefcase"
    ]
}
