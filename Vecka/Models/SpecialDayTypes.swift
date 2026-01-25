//
//  SpecialDayTypes.swift
//  Vecka
//
//  情報デザイン: Data types for Star page (Special Days)
//  Extracted from SpecialDaysListView for clean architecture
//
//  Types:
//  - SpecialDayType: Enum for all special day categories
//  - MonthTheme: Seasonal colors and icons
//  - HolidayCategory: Color coding for holidays
//  - DayCardData: Grouping for same-day holidays
//  - SpecialDayRow: Individual special day data
//  - ConsolidatedHoliday: Merged same-date holidays
//

import SwiftUI

// MARK: - Special Day Type

/// 情報デザイン: Simplified type system after Memo consolidation
/// - holiday/observance: From HolidayManager
/// - birthday: From Contact model
/// - memo: User entries (replaces event, note, trip, expense)
/// - Legacy types (trip, expense, note, event): For backwards compatibility
enum SpecialDayType: String, CaseIterable {
    case holiday    // Red days (isBankHoliday = true)
    case observance // Non-red days (isBankHoliday = false)
    case birthday   // Birthdays from contacts
    case memo       // User memos (can have money/place/person enrichments)

    // Legacy types for backwards compatibility with LandingPageView
    case trip       // → Now Memo with place (cyan)
    case expense    // → Now Memo with amount (green)
    case note       // → Now Memo (yellow)
    case event      // → Now Memo (yellow)

    var title: String {
        switch self {
        case .holiday: return NSLocalizedString("library.bank_holidays", value: "Bank Holidays", comment: "Bank Holidays")
        case .observance: return NSLocalizedString("library.observances", value: "Observances", comment: "Observances")
        case .birthday: return NSLocalizedString("library.birthdays", value: "Birthdays", comment: "Birthdays")
        case .memo, .note, .event: return NSLocalizedString("library.memos", value: "Memos", comment: "Memos")
        case .trip: return NSLocalizedString("library.trips", value: "Trips", comment: "Trips")
        case .expense: return NSLocalizedString("library.expenses", value: "Expenses", comment: "Expenses")
        }
    }

    var prioritySymbol: String {
        switch self {
        case .holiday: return "●"    // Filled circle
        case .observance: return "○" // Outlined circle
        case .birthday: return "★"   // Star
        case .memo, .note, .event: return "□"       // Square
        case .trip: return "◇"       // Diamond
        case .expense: return "◆"    // Filled diamond
        }
    }

    var defaultIcon: String {
        switch self {
        case .holiday: return "star.fill"
        case .observance: return "sparkles"
        case .birthday: return "birthday.cake.fill"
        case .memo, .note: return "note.text"
        case .trip: return "airplane"
        case .expense: return "yensign.circle.fill"
        case .event: return "calendar.badge.clock"
        }
    }

    /// 情報デザイン: Different accent colors for visual interest
    var accentColor: Color {
        switch self {
        case .holiday: return Color(hex: "E53E3E")    // Red - "day off!"
        case .observance: return Color(hex: "ED8936") // Orange - celebration
        case .birthday: return Color(hex: "D53F8C")   // Pink - birthdays
        case .memo, .note, .event: return Color(hex: "ECC94B")  // Yellow - memos
        case .trip: return Color(hex: "22D3EE")       // Cyan - trips (予定)
        case .expense: return Color(hex: "4ADE80")    // Green - money (金)
        }
    }

    /// 情報デザイン: Light background tints for icon zones
    var lightBackground: Color {
        switch self {
        case .holiday: return Color(hex: "FDE8E8")    // Light red
        case .observance: return Color(hex: "FEEBC8") // Light orange
        case .birthday: return Color(hex: "FECDD3")   // Light pink
        case .memo, .note, .event: return Color(hex: "FFE566")  // Light yellow
        case .trip: return Color(hex: "A5F3FC")       // Light cyan
        case .expense: return Color(hex: "BBF7D0")    // Light green
        }
    }

    var isBankHoliday: Bool {
        self == .holiday
    }

    /// 情報デザイン: 3-letter type codes
    var code: String {
        switch self {
        case .holiday: return "HOL"
        case .observance: return "OBS"
        case .birthday: return "BDY"
        case .memo: return "MEM"
        case .trip: return "TRP"
        case .expense: return "EXP"
        case .note: return "NOT"
        case .event: return "EVT"
        }
    }
}

// MARK: - Birthday Display Text (情報デザイン: Intelligent messaging)

/// Returns display text for birthday row metadata - handles age 0 as "born" message
func birthdayDisplayText(age: Int, date: Date) -> String {
    let isPast = Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    let isToday = Calendar.current.isDateInToday(date)

    if age == 0 {
        return isToday ? "BORN TODAY" : (isPast ? "WAS BORN" : "WILL BE BORN")
    } else {
        let tense = isToday ? "TURNS" : (isPast ? "TURNED" : "TURNS")
        return "\(tense) \(age)"
    }
}

/// Returns expanded display text for birthday card - includes time context
func birthdayExpandedDisplayText(age: Int, date: Date, daysUntil: Int) -> String {
    let isPast = Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    let isToday = Calendar.current.isDateInToday(date)
    let timeText = isToday ? "TODAY" : (isPast ? "\(abs(daysUntil))D AGO" : "IN \(daysUntil)D")

    if age == 0 {
        return isToday ? "BORN ON THIS DAY" : (isPast ? "WAS BORN · \(timeText)" : "WILL BE BORN · \(timeText)")
    } else {
        let tense = isToday ? "TURNS" : (isPast ? "TURNED" : "TURNS")
        return "\(tense) \(age) · \(timeText)"
    }
}

// MARK: - Month Theme (情報デザイン: JSON-driven seasonal colors & icons)

struct MonthTheme {
    let month: Int
    let name: String
    let icon: String           // SF Symbol
    let accentColor: Color     // Month's signature color
    let lightBackground: Color // Lighter tint for card background

    /// 情報デザイン month themes - loaded from JSON for easy customization
    static let themes: [MonthTheme] = {
        guard let url = Bundle.main.url(forResource: "month-themes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([MonthThemeDTO].self, from: data) else {
            Log.e("Failed to load month-themes.json")
            return defaultThemes
        }
        Log.i("Loaded \(dtos.count) month themes from JSON")
        return dtos.map { $0.toMonthTheme() }
    }()

    static func theme(for month: Int) -> MonthTheme {
        themes.first(where: { $0.month == month }) ?? themes.first ?? MonthTheme(
            month: 1,
            name: "January",
            icon: "calendar",
            accentColor: Color(hex: "4A90D9"),
            lightBackground: Color(hex: "E8F4FD")
        )
    }

    /// Fallback themes if JSON fails to load
    private static let defaultThemes: [MonthTheme] = [
        MonthTheme(month: 1, name: "January", icon: "snowflake",
                   accentColor: Color(hex: "4A90D9"), lightBackground: Color(hex: "E8F4FD")),
        MonthTheme(month: 2, name: "February", icon: "heart.fill",
                   accentColor: Color(hex: "E84393"), lightBackground: Color(hex: "FDE8F3")),
        MonthTheme(month: 3, name: "March", icon: "leaf.fill",
                   accentColor: Color(hex: "00B894"), lightBackground: Color(hex: "E8FDF6")),
        MonthTheme(month: 4, name: "April", icon: "cloud.rain.fill",
                   accentColor: Color(hex: "74B9FF"), lightBackground: Color(hex: "EBF5FF")),
        MonthTheme(month: 5, name: "May", icon: "camera.macro",
                   accentColor: Color(hex: "FDCB6E"), lightBackground: Color(hex: "FFF9E8")),
        MonthTheme(month: 6, name: "June", icon: "sun.max.fill",
                   accentColor: Color(hex: "F39C12"), lightBackground: Color(hex: "FEF3E2")),
        MonthTheme(month: 7, name: "July", icon: "beach.umbrella.fill",
                   accentColor: Color(hex: "00CEC9"), lightBackground: Color(hex: "E8FFFE")),
        MonthTheme(month: 8, name: "August", icon: "flame.fill",
                   accentColor: Color(hex: "E17055"), lightBackground: Color(hex: "FDECE8")),
        MonthTheme(month: 9, name: "September", icon: "leaf.arrow.triangle.circlepath",
                   accentColor: Color(hex: "D35400"), lightBackground: Color(hex: "FDEEE5")),
        MonthTheme(month: 10, name: "October", icon: "moon.fill",
                   accentColor: Color(hex: "6C5CE7"), lightBackground: Color(hex: "EFECFD")),
        MonthTheme(month: 11, name: "November", icon: "wind",
                   accentColor: Color(hex: "636E72"), lightBackground: Color(hex: "F0F2F3")),
        MonthTheme(month: 12, name: "December", icon: "gift.fill",
                   accentColor: Color(hex: "C0392B"), lightBackground: Color(hex: "F9E7E5"))
    ]
}

/// DTO for JSON decoding (colors stored as hex strings)
private struct MonthThemeDTO: Codable {
    let month: Int
    let name: String
    let icon: String
    let accentColor: String      // Hex color without #
    let lightBackground: String  // Hex color without #

    func toMonthTheme() -> MonthTheme {
        MonthTheme(
            month: month,
            name: name,
            icon: icon,
            accentColor: Color(hex: accentColor),
            lightBackground: Color(hex: lightBackground)
        )
    }
}

// MARK: - Holiday Category (for color coding)

enum HolidayCategory {
    case redDay      // Bank holidays - RED
    case religious   // Easter, Christmas etc - PURPLE
    case cultural    // Midsummer, etc - ORANGE
    case personal    // Birthdays, anniversaries - BLUE
    case seasonal    // First day of spring - GREEN

    var pillColor: Color {
        switch self {
        case .redDay: return Color(hex: "E53E3E")      // Red
        case .religious: return Color(hex: "805AD5")   // Purple
        case .cultural: return Color(hex: "ED8936")    // Orange
        case .personal: return Color(hex: "3182CE")    // Blue
        case .seasonal: return Color(hex: "38A169")    // Green
        }
    }

    var textColor: Color {
        switch self {
        case .redDay, .religious, .personal: return JohoColors.white
        case .cultural, .seasonal: return JohoColors.black
        }
    }
}

// MARK: - Day Card Grouping (情報デザイン: Same-day holidays combine)

/// A day card groups all special days that fall on the same date
struct DayCardData: Identifiable {
    let id: String
    let date: Date
    let day: Int
    let items: [SpecialDayRow]

    /// Card size based on content (情報デザイン: expand to fit data)
    var cardSize: DayCardSize {
        if items.count >= 2 {
            return .expanded  // 2 columns wide for multiple items
        }
        return .standard     // 1 column for single item
    }

    /// Primary item (first holiday/observance, or first item)
    var primaryItem: SpecialDayRow? { items.first }

    /// All unique regions in this card
    var regions: [String] {
        Array(Set(items.compactMap { $0.region.isEmpty ? nil : $0.region }))
    }
}

enum DayCardSize {
    case standard   // 1x1 grid cell
    case expanded   // 2x1 grid cells (spans 2 columns)
}

// MARK: - Special Day Row (Individual item data)

struct SpecialDayRow: Identifiable {
    let id: String
    let ruleID: String        // HolidayRule ID or Memo ID
    let region: String
    let date: Date
    let title: String
    let type: SpecialDayType
    let symbolName: String?
    let iconColor: String?
    let notes: String?
    let isCustom: Bool
    let isMemo: Bool          // True if this is a memo
    let originalBirthday: Date?  // For birthdays: the original birth date (to calculate age)
    let turningAge: Int?         // For birthdays: the age they're turning

    /// Determine category based on holiday characteristics
    var category: HolidayCategory {
        switch type {
        case .holiday: return .redDay
        case .birthday: return .personal
        case .memo, .note, .event: return .personal
        case .observance: return .cultural
        case .trip: return .cultural
        case .expense: return .personal
        }
    }

    /// Days until this event (for countdowns)
    var daysUntil: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    /// Whether this row has a supported country color scheme
    var hasCountryPill: Bool {
        CountryColorScheme.scheme(for: region) != nil
    }

    /// Whether this is a system holiday (vs user-created)
    var isSystem: Bool {
        !isCustom
    }
}

// MARK: - Consolidated Holiday (Merged same-date holidays)

/// Groups same-date holidays from multiple regions into one row
/// 情報デザイン: Same semantic holiday (same date + type) = ONE row with multiple country pills
struct ConsolidatedHoliday: Identifiable {
    let id: String                      // "holiday-1704067200" (date timestamp)
    let date: Date
    let type: SpecialDayType            // .holiday
    let regions: [String]               // ["SE", "US", "VN"]
    let names: [String: String]         // ["SE": "Nyårsdagen", "US": "New Year's Day", "VN": "Tết Dương lịch"]
    let icons: [String: String]         // ["SE": "snowflake", "US": "fireworks", "VN": "sparkles"]
    let isSystemHoliday: Bool           // All source rows are system holidays
    let sourceRows: [SpecialDayRow]     // Original rows for detail sheet display

    /// Get the best display name for the current locale
    /// 情報デザイン: Show the user's locale name, fallback to English, then first available
    func displayName(for locale: Locale) -> String {
        // 1. Try device locale region (e.g., "SE" for Swedish)
        if let regionCode = locale.region?.identifier,
           let localeName = names[regionCode] {
            return localeName
        }

        // 2. Try English name (US)
        if let englishName = names["US"] {
            return englishName
        }

        // 3. Fallback to first available name
        return names.values.first ?? "Holiday"
    }

    /// Create from a group of same-DATE holidays (not same-name)
    /// 情報デザイン: Semantic grouping - same date + same type = same holiday
    static func from(holidays: [SpecialDayRow]) -> ConsolidatedHoliday? {
        guard let first = holidays.first else { return nil }

        return ConsolidatedHoliday(
            id: "holiday-\(first.date.timeIntervalSince1970)",
            date: first.date,
            type: .holiday,
            regions: holidays.map { $0.region },
            names: Dictionary(uniqueKeysWithValues: holidays.map { ($0.region, $0.title) }),
            icons: Dictionary(uniqueKeysWithValues: holidays.compactMap { holiday in
                let icon = holiday.symbolName ?? SpecialDayType.holiday.defaultIcon
                return (holiday.region, icon)
            }),
            isSystemHoliday: holidays.allSatisfy { $0.isSystem },
            sourceRows: holidays
        )
    }
}

