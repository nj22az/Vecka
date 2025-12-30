//
//  HolidayEngine.swift
//  Vecka
//
//  The "Brain" that interprets HolidayRules.
//  Pure logic: Input (Rule + Year) -> Output (Date)
//

import Foundation

struct HolidayEngine {
    private let calendar = Calendar.current
    
    /// Calculate the specific date for a rule in a given year
    func calculateDate(for rule: HolidayRule, year: Int) -> Date? {
        switch rule.type {
        case .fixed:
            guard let month = rule.month, let day = rule.day else { return nil }
            return DateComponents(calendar: calendar, year: year, month: month, day: day).date
            
        case .easterRelative:
            guard let offset = rule.daysOffset else { return nil }
            let easter = easterSunday(year: year)
            return calendar.date(byAdding: .day, value: offset, to: easter)
            
        case .floating:
            // e.g., Midsummer: Saturday between June 20-26
            guard let month = rule.month,
                  let weekday = rule.weekday,
                  let startDay = rule.dayRangeStart,
                  let endDay = rule.dayRangeEnd else { return nil }
            
            return findWeekday(weekday, in: year, month: month, range: startDay...endDay)
            
        case .nthWeekday:
            // e.g., Mother's Day: Last Sunday in May (ordinal: -1)
            // e.g., Father's Day: 2nd Sunday in Nov (ordinal: 2)
            guard let month = rule.month,
                  let weekday = rule.weekday,
                  let ordinal = rule.ordinal else { return nil }
            
            return findNthWeekday(ordinal, weekday: weekday, in: year, month: month)
            
        case .lunar:
            // e.g., Tet: 1st day of 1st Lunar Month
            guard let lunarMonth = rule.month,
                  let lunarDay = rule.day else { return nil }
            
            return calculateLunarDate(month: lunarMonth, day: lunarDay, inGregorianYear: year)
            
        case .astronomical:
            // Solstices and Equinoxes
            // We use the 'month' field to identify which event (3=Spring, 6=Summer, 9=Autumn, 12=Winter)
            guard let month = rule.month else { return nil }
            return calculateAstronomicalDate(month: month, year: year)
        }
    }
    
    // MARK: - Algorithms
    
    /// Find specific weekday in a date range (e.g., Saturday between 20-26)
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
    
    /// Find Nth weekday (e.g., 2nd Sunday) or Last weekday (-1)
    private func findNthWeekday(_ ordinal: Int, weekday: Int, in year: Int, month: Int) -> Date? {
        var components = DateComponents(year: year, month: month)
        
        if ordinal == -1 {
            // Find LAST occurrence
            // Start from next month's 1st day and go backwards
            components.month = month + 1
            components.day = 0 // Last day of previous month (our target month)
            guard let endOfMonth = calendar.date(from: components) else { return nil }
            
            var currentDate = endOfMonth
            // Look backwards up to 7 days
            for _ in 0..<7 {
                if calendar.component(.weekday, from: currentDate) == weekday {
                    return currentDate
                }
                guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    Log.w("Failed to calculate previous date in findNthWeekday")
                    return nil
                }
                currentDate = previousDate
            }
        } else {
            // Find Nth occurrence (1st, 2nd, 3rd, 4th)
            components.day = 1
            guard let startOfMonth = calendar.date(from: components) else { return nil }
            
            var currentDate = startOfMonth
            var count = 0
            
            // Scan the whole month
            while calendar.component(.month, from: currentDate) == month {
                if calendar.component(.weekday, from: currentDate) == weekday {
                    count += 1
                    if count == ordinal {
                        return currentDate
                    }
                }
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                    Log.w("Failed to calculate next date in findNthWeekday")
                    return nil
                }
                currentDate = nextDate
            }
        }
        return nil
    }
    
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
        return Calendar.iso8601.date(from: comps) ?? Date()
    }
    
    /// Calculate Gregorian date from Lunar Month/Day
    private func calculateLunarDate(month: Int, day: Int, inGregorianYear year: Int) -> Date? {
        let chinese = Calendar(identifier: .chinese)
        
        // Strategy: Find the Chinese Year that overlaps significantly with the Gregorian Year.
        // We pick a date in the middle of the Gregorian year (June 15) to find the Chinese Year.
        let midYearComps = DateComponents(year: year, month: 6, day: 15)
        guard let midYearDate = calendar.date(from: midYearComps) else { return nil }
        
        let chineseYear = chinese.component(.year, from: midYearDate)
        
        // Construct the target Lunar Date
        var targetComps = DateComponents()
        targetComps.year = chineseYear
        targetComps.month = month
        targetComps.day = day
        // Note: We ignore leap month logic for simplicity unless specifically requested.
        // Most major holidays (Tet) are on standard months.
        
        return chinese.date(from: targetComps)
    }

    /// Calculate Astronomical Events (Solstices/Equinoxes)
    /// Uses simplified Meeus algorithms (accurate to the day for calendar purposes)
    private func calculateAstronomicalDate(month: Int, year: Int) -> Date? {
        let Y = Double(year - 2000)
        var day: Double = 0.0
        
        switch month {
        case 3: // Spring Equinox
            day = 20.2088 + 0.2422 * Y - floor(Y / 4.0)
        case 6: // Summer Solstice
            day = 20.9126 + 0.2422 * Y - floor(Y / 4.0)
        case 9: // Autumn Equinox
            day = 22.5444 + 0.2422 * Y - floor(Y / 4.0)
        case 12: // Winter Solstice
            day = 21.4800 + 0.2422 * Y - floor(Y / 4.0)
        default:
            return nil
        }
        
        // Construct date
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = Int(day)
        
        return calendar.date(from: components)
    }
}
