//
//  LunarCalendarService.swift
//  Vecka
//
//  Vietnamese Lunar Calendar (Âm Lịch) support
//  Uses the Chinese calendar as base for lunar date calculations
//

import Foundation

/// Service for converting Gregorian dates to Vietnamese Lunar dates (Âm Lịch)
final class LunarCalendarService {

    static let shared = LunarCalendarService()

    private let chineseCalendar: Calendar

    private init() {
        var calendar = Calendar(identifier: .chinese)
        calendar.locale = Locale(identifier: "vi_VN")
        self.chineseCalendar = calendar
    }

    // MARK: - Public API

    /// Get lunar date components for a Gregorian date
    /// - Parameter date: Gregorian date
    /// - Returns: LunarDate with day, month, year, and leap month indicator
    func lunarDate(from date: Date) -> LunarDate {
        let components = chineseCalendar.dateComponents([.day, .month, .year, .isLeapMonth], from: date)

        return LunarDate(
            day: components.day ?? 1,
            month: components.month ?? 1,
            year: components.year ?? 1,
            isLeapMonth: components.isLeapMonth ?? false
        )
    }

    /// Get formatted lunar date string (e.g., "15/8" for Mid-Autumn Festival)
    /// - Parameter date: Gregorian date
    /// - Returns: Formatted string "day/month" or "day/month*" for leap months
    func formattedLunarDate(from date: Date) -> String {
        let lunar = lunarDate(from: date)
        let suffix = lunar.isLeapMonth ? "*" : ""
        return "\(lunar.day)/\(lunar.month)\(suffix)"
    }

    /// Get short lunar day string for calendar display
    /// - Parameter date: Gregorian date
    /// - Returns: Lunar day number as string (e.g., "15", "1", "30")
    func lunarDayString(from date: Date) -> String {
        let lunar = lunarDate(from: date)
        return String(lunar.day)
    }

    /// Check if date is the first day of a lunar month (Mùng 1)
    /// - Parameter date: Gregorian date
    /// - Returns: True if it's the first day of a lunar month
    func isFirstDayOfLunarMonth(date: Date) -> Bool {
        let lunar = lunarDate(from: date)
        return lunar.day == 1
    }

    /// Check if date is the 15th day of a lunar month (Rằm)
    /// - Parameter date: Gregorian date
    /// - Returns: True if it's the 15th day (full moon)
    func isFullMoonDay(date: Date) -> Bool {
        let lunar = lunarDate(from: date)
        return lunar.day == 15
    }

    /// Get lunar month name in Vietnamese
    /// - Parameter month: Lunar month number (1-12)
    /// - Returns: Vietnamese month name
    func lunarMonthName(month: Int) -> String {
        switch month {
        case 1: return "Tháng Giêng"
        case 2: return "Tháng Hai"
        case 3: return "Tháng Ba"
        case 4: return "Tháng Tư"
        case 5: return "Tháng Năm"
        case 6: return "Tháng Sáu"
        case 7: return "Tháng Bảy"
        case 8: return "Tháng Tám"
        case 9: return "Tháng Chín"
        case 10: return "Tháng Mười"
        case 11: return "Tháng Mười Một"
        case 12: return "Tháng Chạp"
        default: return "Tháng \(month)"
        }
    }

    /// Get the Vietnamese zodiac animal for a lunar year
    /// - Parameter year: Lunar year
    /// - Returns: Vietnamese zodiac name and symbol
    func zodiacAnimal(year: Int) -> (name: String, symbol: String) {
        let animals: [(String, String)] = [
            ("Tý", "🐀"),      // Rat
            ("Sửu", "🐂"),     // Ox
            ("Dần", "🐅"),     // Tiger
            ("Mão", "🐇"),     // Rabbit
            ("Thìn", "🐉"),    // Dragon
            ("Tỵ", "🐍"),      // Snake
            ("Ngọ", "🐎"),     // Horse
            ("Mùi", "🐐"),     // Goat
            ("Thân", "🐒"),    // Monkey
            ("Dậu", "🐓"),     // Rooster
            ("Tuất", "🐕"),    // Dog
            ("Hợi", "🐖")      // Pig
        ]

        // Chinese calendar cycles every 12 years starting from year 4 (Tý)
        let index = (year - 4) % 12
        let adjustedIndex = index < 0 ? index + 12 : index
        return animals[adjustedIndex]
    }
}

// MARK: - Lunar Date Model

/// Represents a date in the Vietnamese Lunar Calendar
struct LunarDate: Equatable {
    let day: Int
    let month: Int
    let year: Int
    let isLeapMonth: Bool

    /// Format as "Mùng X" for days 1-10, or just the number for other days
    var vietnameseDayName: String {
        if day <= 10 {
            return "Mùng \(day)"
        }
        return String(day)
    }

    /// Short format for calendar display
    var shortFormat: String {
        if isLeapMonth {
            return "\(day)/\(month)*"
        }
        return "\(day)/\(month)"
    }
}
