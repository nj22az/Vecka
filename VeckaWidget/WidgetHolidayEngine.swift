//
//  WidgetHolidayEngine.swift
//  VeckaWidget
//
//  Holiday calculation engine for widgets.
//  Uses the same algorithms as the main app's HolidayEngine
//  but with static rule definitions (no SwiftData dependency).
//

import Foundation

// MARK: - Holiday Rule Types (mirrors main app)

enum WidgetHolidayRuleType {
    case fixed          // e.g., Christmas Eve (Dec 24)
    case easterRelative // e.g., Good Friday (-2 days from Easter)
    case floating       // e.g., Midsummer (Saturday between June 20-26)
    case nthWeekday     // e.g., Father's Day (2nd Sunday in Nov)
    case astronomical   // e.g., Solstices and Equinoxes
}

// MARK: - Holiday Rule Definition

struct WidgetHolidayRule {
    let name: String           // Localization key (e.g., "holiday.juldagen")
    let isBankHoliday: Bool
    let type: WidgetHolidayRuleType

    // Parameters (based on type)
    var month: Int?
    var day: Int?
    var daysOffset: Int?      // For Easter-relative
    var weekday: Int?         // 1=Sunday, 7=Saturday
    var ordinal: Int?         // 1=1st, 2=2nd, -1=Last
    var dayRangeStart: Int?   // For floating
    var dayRangeEnd: Int?     // For floating
}

// MARK: - Computed Holiday

struct WidgetHoliday: Identifiable {
    let id: String
    let date: Date
    let name: String
    let isBankHoliday: Bool

    var displayName: String {
        // Try localization first
        if name.hasPrefix("holiday.") {
            let localized = NSLocalizedString(name, bundle: .main, comment: "Holiday name")
            if localized != name {
                return localized
            }
        }
        // Fallback to name itself
        return name
    }
}

// MARK: - Holiday Engine

struct WidgetHolidayEngine {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        return cal
    }()

    // MARK: - Swedish Holiday Rules (mirrors HolidayManager.seedSwedishRules)

    private let swedishHolidayRules: [WidgetHolidayRule] = [
        // --- RED DAYS (Official Public Holidays) ---
        WidgetHolidayRule(name: "holiday.nyarsdagen", isBankHoliday: true, type: .fixed, month: 1, day: 1),
        WidgetHolidayRule(name: "holiday.trettondedag_jul", isBankHoliday: true, type: .fixed, month: 1, day: 6),
        WidgetHolidayRule(name: "holiday.forsta_maj", isBankHoliday: true, type: .fixed, month: 5, day: 1),
        WidgetHolidayRule(name: "holiday.sveriges_nationaldag", isBankHoliday: true, type: .fixed, month: 6, day: 6),
        WidgetHolidayRule(name: "holiday.juldagen", isBankHoliday: true, type: .fixed, month: 12, day: 25),
        WidgetHolidayRule(name: "holiday.annandag_jul", isBankHoliday: true, type: .fixed, month: 12, day: 26),

        // --- HOLIDAYS (Not Red Days) ---
        WidgetHolidayRule(name: "holiday.nyarsafton", isBankHoliday: false, type: .fixed, month: 12, day: 31),
        WidgetHolidayRule(name: "holiday.julafton", isBankHoliday: false, type: .fixed, month: 12, day: 24),

        // --- Observances ---
        WidgetHolidayRule(name: "holiday.alla_hjartans_dag", isBankHoliday: false, type: .fixed, month: 2, day: 14),
        WidgetHolidayRule(name: "holiday.internationella_kvinnodagen", isBankHoliday: false, type: .fixed, month: 3, day: 8),

        // --- Easter Relative ---
        WidgetHolidayRule(name: "holiday.langfredagen", isBankHoliday: true, type: .easterRelative, daysOffset: -2),
        WidgetHolidayRule(name: "holiday.paskdagen", isBankHoliday: true, type: .easterRelative, daysOffset: 0),
        WidgetHolidayRule(name: "holiday.annandag_pask", isBankHoliday: true, type: .easterRelative, daysOffset: 1),
        WidgetHolidayRule(name: "holiday.kristi_himmelsfardsdag", isBankHoliday: true, type: .easterRelative, daysOffset: 39),
        WidgetHolidayRule(name: "holiday.pingstdagen", isBankHoliday: true, type: .easterRelative, daysOffset: 49),

        // --- Floating Red Days ---
        WidgetHolidayRule(name: "holiday.midsommardagen", isBankHoliday: true, type: .floating, month: 6, weekday: 7, dayRangeStart: 20, dayRangeEnd: 26),
        WidgetHolidayRule(name: "holiday.midsommarafton", isBankHoliday: false, type: .floating, month: 6, weekday: 6, dayRangeStart: 19, dayRangeEnd: 25),
        WidgetHolidayRule(name: "holiday.alla_helgons_dag", isBankHoliday: true, type: .nthWeekday, month: 11, weekday: 7, ordinal: 1),

        // --- Other Observances ---
        WidgetHolidayRule(name: "holiday.mors_dag", isBankHoliday: false, type: .nthWeekday, month: 5, weekday: 1, ordinal: -1),
        WidgetHolidayRule(name: "holiday.fars_dag", isBankHoliday: false, type: .nthWeekday, month: 11, weekday: 1, ordinal: 2),

        // --- Astronomical Events ---
        WidgetHolidayRule(name: "holiday.virdagjamning", isBankHoliday: false, type: .astronomical, month: 3),
        WidgetHolidayRule(name: "holiday.sommarsolstand", isBankHoliday: false, type: .astronomical, month: 6),
        WidgetHolidayRule(name: "holiday.hostdagjamning", isBankHoliday: false, type: .astronomical, month: 9),
        WidgetHolidayRule(name: "holiday.vintersolstand", isBankHoliday: false, type: .astronomical, month: 12),
    ]

    // MARK: - Public API

    /// Get holidays for a specific date
    func getHolidays(for date: Date) -> [WidgetHoliday] {
        let year = calendar.component(.year, from: date)
        let targetDay = calendar.startOfDay(for: date)

        var holidays: [WidgetHoliday] = []

        for rule in swedishHolidayRules {
            if let holidayDate = calculateDate(for: rule, year: year),
               calendar.isDate(holidayDate, inSameDayAs: targetDay) {
                holidays.append(WidgetHoliday(
                    id: rule.name,
                    date: holidayDate,
                    name: rule.name,
                    isBankHoliday: rule.isBankHoliday
                ))
            }
        }

        // Sort: red days first, then alphabetically
        return holidays.sorted { lhs, rhs in
            if lhs.isBankHoliday != rhs.isBankHoliday { return lhs.isBankHoliday }
            return lhs.displayName < rhs.displayName
        }
    }

    /// Get upcoming holidays in the next N days
    func getUpcomingHolidays(from date: Date, days: Int = 30) -> [WidgetHoliday] {
        let year = calendar.component(.year, from: date)
        let nextYear = year + 1
        let startOfToday = calendar.startOfDay(for: date)

        guard let endDate = calendar.date(byAdding: .day, value: days, to: startOfToday) else {
            return []
        }

        var holidays: [WidgetHoliday] = []

        // Check both this year and next year (for holidays near year end)
        for checkYear in [year, nextYear] {
            for rule in swedishHolidayRules {
                if let holidayDate = calculateDate(for: rule, year: checkYear) {
                    let normalizedDate = calendar.startOfDay(for: holidayDate)

                    // Only include if after today and before end date
                    if normalizedDate > startOfToday && normalizedDate <= endDate {
                        holidays.append(WidgetHoliday(
                            id: "\(rule.name)-\(checkYear)",
                            date: normalizedDate,
                            name: rule.name,
                            isBankHoliday: rule.isBankHoliday
                        ))
                    }
                }
            }
        }

        // Sort by date, then by red day status
        return holidays.sorted { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date < rhs.date }
            if lhs.isBankHoliday != rhs.isBankHoliday { return lhs.isBankHoliday }
            return lhs.displayName < rhs.displayName
        }
    }

    /// Check if a specific day has a holiday
    func hasHoliday(on date: Date) -> Bool {
        !getHolidays(for: date).isEmpty
    }

    // MARK: - Date Calculation (mirrors HolidayEngine)

    private func calculateDate(for rule: WidgetHolidayRule, year: Int) -> Date? {
        switch rule.type {
        case .fixed:
            guard let month = rule.month, let day = rule.day else { return nil }
            return DateComponents(calendar: calendar, year: year, month: month, day: day).date

        case .easterRelative:
            guard let offset = rule.daysOffset else { return nil }
            let easter = easterSunday(year: year)
            return calendar.date(byAdding: .day, value: offset, to: easter)

        case .floating:
            guard let month = rule.month,
                  let weekday = rule.weekday,
                  let startDay = rule.dayRangeStart,
                  let endDay = rule.dayRangeEnd else { return nil }
            return findWeekday(weekday, in: year, month: month, range: startDay...endDay)

        case .nthWeekday:
            guard let month = rule.month,
                  let weekday = rule.weekday,
                  let ordinal = rule.ordinal else { return nil }
            return findNthWeekday(ordinal, weekday: weekday, in: year, month: month)

        case .astronomical:
            guard let month = rule.month else { return nil }
            return calculateAstronomicalDate(month: month, year: year)
        }
    }

    // MARK: - Algorithm Implementations

    /// Anonymous Gregorian Computus for Easter Sunday
    private func easterSunday(year: Int) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1

        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        return calendar.date(from: comps) ?? Date()
    }

    /// Find specific weekday in a date range
    private func findWeekday(_ targetWeekday: Int, in year: Int, month: Int, range: ClosedRange<Int>) -> Date? {
        let start = DateComponents(year: year, month: month, day: range.lowerBound)
        guard let startDate = calendar.date(from: start) else { return nil }

        var currentDate = startDate
        let endDay = range.upperBound

        while calendar.component(.day, from: currentDate) <= endDay {
            if calendar.component(.weekday, from: currentDate) == targetWeekday {
                return currentDate
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }
        return nil
    }

    /// Find Nth weekday or Last weekday (-1)
    private func findNthWeekday(_ ordinal: Int, weekday: Int, in year: Int, month: Int) -> Date? {
        var components = DateComponents(year: year, month: month)

        if ordinal == -1 {
            // Find LAST occurrence
            components.month = month + 1
            components.day = 0 // Last day of previous month
            guard let endOfMonth = calendar.date(from: components) else { return nil }

            var currentDate = endOfMonth
            for _ in 0..<7 {
                if calendar.component(.weekday, from: currentDate) == weekday {
                    return currentDate
                }
                guard let prev = calendar.date(byAdding: .day, value: -1, to: currentDate) else { return nil }
                currentDate = prev
            }
        } else {
            // Find Nth occurrence
            components.day = 1
            guard let startOfMonth = calendar.date(from: components) else { return nil }

            var currentDate = startOfMonth
            var count = 0

            while calendar.component(.month, from: currentDate) == month {
                if calendar.component(.weekday, from: currentDate) == weekday {
                    count += 1
                    if count == ordinal {
                        return currentDate
                    }
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { return nil }
                currentDate = next
            }
        }
        return nil
    }

    /// Calculate astronomical events (Solstices/Equinoxes)
    private func calculateAstronomicalDate(month: Int, year: Int) -> Date? {
        let Y = Double(year - 2000)
        var day: Double = 0.0

        switch month {
        case 3:  day = 20.2088 + 0.2422 * Y - floor(Y / 4.0)  // Spring Equinox
        case 6:  day = 20.9126 + 0.2422 * Y - floor(Y / 4.0)  // Summer Solstice
        case 9:  day = 22.5444 + 0.2422 * Y - floor(Y / 4.0)  // Autumn Equinox
        case 12: day = 21.4800 + 0.2422 * Y - floor(Y / 4.0)  // Winter Solstice
        default: return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = Int(day)
        return calendar.date(from: components)
    }

    // MARK: - Icon Helper (Mirrors HolidayManager)
    
    static func holidayIcon(for holidayId: String?) -> String? {
        guard let id = holidayId?.lowercased() else { return nil }

        // Christmas related
        if id.contains("christmas") || id.contains("jul") {
            return "gift.fill"
        }
        // New Year
        if id.contains("new-year") || id.contains("nyar") || id.contains("nyår") {
            return "sparkles"
        }
        // Easter related
        if id.contains("easter") || id.contains("påsk") || id.contains("pask") {
            return "sun.max.fill"
        }
        // Midsummer
        if id.contains("midsommar") || id.contains("midsummer") {
            return "leaf.fill"
        }
        // National day
        if id.contains("national") || id.contains("sverige") {
            return "flag.fill"
        }
        // Valentine's
        if id.contains("valentin") || id.contains("hjärtan") {
            return "heart.fill"
        }
        // All Saints
        if id.contains("saints") || id.contains("helgon") {
            return "candle.fill"
        }
        // Epiphany
        if id.contains("epiphany") || id.contains("tretton") {
            return "star.circle.fill"
        }
        // Ascension
        if id.contains("ascension") || id.contains("himmelsfärd") {
            return "cloud.sun.fill"
        }
        // Pentecost
        if id.contains("pentecost") || id.contains("pingst") {
            return "flame.fill"
        }
        // Mother's/Father's day
        if id.contains("mother") || id.contains("mors") || id.contains("father") || id.contains("fars") {
            return "heart.circle.fill"
        }
        // Walpurgis
        if id.contains("walpurgis") || id.contains("valborg") {
            return "flame"
        }
        // May Day / Labor Day
        if id.contains("labor") || id.contains("första maj") || id.contains("may-day") {
            return "figure.walk"
        }

        return nil
    }
}
