//
//  CalendarModels.swift
//  Vecka
//
//  Data models for the calendar grid system
//  Following Apple HIG layout principles
//

import Foundation

// MARK: - Calendar Month Model

/// Represents a complete month with all weeks and days for calendar display
struct CalendarMonth: Identifiable, Hashable {
    var id: String { "\(year)-\(month)" }
    let year: Int
    let month: Int  // 1-12
    let weeks: [CalendarWeek]

    /// Generate all months for a given year
    static func generateYear(_ year: Int, noteColors: [Date: String] = [:]) -> [CalendarMonth] {
        (1...12).map { CalendarMonth(year: year, month: $0, noteColors: noteColors) }
    }

    /// Display name for the month (localized)
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        if let date = Calendar.iso8601.date(from: components) {
            return formatter.string(from: date)
        }
        return ""
    }

    /// Abbreviated month name (localized, e.g., "Dec" instead of "December")
    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        if let date = Calendar.iso8601.date(from: components) {
            return formatter.string(from: date)
        }
        return ""
    }

    /// First day of the month
    var firstDay: Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        return Calendar.iso8601.date(from: components)
    }

    /// Check if this month contains today
    var containsToday: Bool {
        let now = Date()
        let calendar = Calendar.iso8601
        let nowYear = calendar.component(.year, from: now)
        let nowMonth = calendar.component(.month, from: now)
        return year == nowYear && month == nowMonth
    }

    init(year: Int, month: Int, noteColors: [Date: String] = [:]) {
        self.year = year
        self.month = month
        self.weeks = CalendarMonth.generateWeeks(for: year, month: month, noteColors: noteColors)
    }

    /// Generate all weeks for a given month
    static func generateWeeks(for year: Int, month: Int, noteColors: [Date: String] = [:]) -> [CalendarWeek] {
        let calendar = Calendar.iso8601

        // Get first day of month
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let firstDayOfMonth = calendar.date(from: components) else {
            return []
        }

        // Get last day of month
        guard let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth) else {
            return []
        }

        // Find Monday of the week containing the first day (ISO 8601 week starts Monday)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysFromMonday = (firstWeekday == 1) ? 6 : firstWeekday - 2
        guard let startDate = calendar.date(byAdding: .day, value: -daysFromMonday, to: firstDayOfMonth) else {
            return []
        }

        // Find Sunday of the week containing the last day
        let lastWeekday = calendar.component(.weekday, from: lastDayOfMonth)
        let daysToSunday = (lastWeekday == 1) ? 0 : 7 - lastWeekday + 1
        guard let endDate = calendar.date(byAdding: .day, value: daysToSunday, to: lastDayOfMonth) else {
            return []
        }

        // Generate weeks
        var weeks: [CalendarWeek] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let weekInfo = WeekCalculator.shared.weekInfo(for: currentDate)
            let days = generateDaysForWeek(startingFrom: currentDate, inMonth: month, year: year, noteColors: noteColors)

            let week = CalendarWeek(
                weekNumber: weekInfo.weekNumber,
                year: weekInfo.year,
                days: days,
                startDate: weekInfo.startDate
            )

            weeks.append(week)

            // Move to next week (add 7 days)
            guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: currentDate) else {
                break
            }
            currentDate = nextWeek
        }

        return weeks
    }

    /// Generate 7 days for a week
    private static func generateDaysForWeek(startingFrom start: Date, inMonth month: Int, year: Int, noteColors: [Date: String] = [:]) -> [CalendarDay] {
        let calendar = Calendar.iso8601
        var days: [CalendarDay] = []

        // Note: Secondary calendar feature temporarily disabled due to async access complexity
        // Will be re-enabled with proper async support in future iteration
        let secondaryCalendar: Calendar? = nil

        let secondaryFormatter = DateFormatter()
        if let secCal = secondaryCalendar {
            secondaryFormatter.calendar = secCal
            secondaryFormatter.dateStyle = .short
            secondaryFormatter.timeStyle = .none
            // For Chinese/Lunar, short style usually gives "Month/Day" or similar.
            // We can customize format if needed, but .short is a good start for "Database Driven" generic support.
        }

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: start) else {
                continue
            }

            let dayMonth = calendar.component(.month, from: date)
            let dayYear = calendar.component(.year, from: date)
            let dayNumber = calendar.component(.day, from: date)

            let isInCurrentMonth = (dayMonth == month && dayYear == year)
            let isToday = calendar.isDateInToday(date)
            
            // Calculate secondary date string
            var secondaryString: String?
            if let _ = secondaryCalendar {
                secondaryString = secondaryFormatter.string(from: date)
            }

            let day = CalendarDay(
                date: date,
                dayNumber: dayNumber,
                isInCurrentMonth: isInCurrentMonth,
                isToday: isToday,
                noteColor: noteColors[Calendar.current.startOfDay(for: date)],
                secondaryDateString: secondaryString
            )

            days.append(day)
        }

        return days
    }
}

// MARK: - Calendar Week Model

/// Represents a single week in the calendar grid
struct CalendarWeek: Identifiable, Hashable {
    var id: String { "\(year)-W\(weekNumber)" }
    let weekNumber: Int
    let year: Int
    let days: [CalendarDay]
    let startDate: Date

    /// Check if this week contains today
    var containsToday: Bool {
        days.contains { $0.isToday }
    }

    /// Get today if it's in this week
    var today: CalendarDay? {
        days.first { $0.isToday }
    }

    /// Check if this is the current week
    var isCurrentWeek: Bool {
        let now = Date()
        let calendar = Calendar.iso8601
        return calendar.isDate(startDate, equalTo: now, toGranularity: .weekOfYear)
    }

    /// Formatted date range (e.g., "Nov 25 – Dec 1")
    var dateRange: String {
        let endDate = Calendar.iso8601.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let startStr = formatter.string(from: startDate)
        let endStr = formatter.string(from: endDate)

        return "\(startStr) – \(endStr)"
    }

    /// Generate all weeks for a given year
    static func generateWeeks(forYear year: Int) -> [CalendarWeek] {
        let calendar = Calendar.iso8601
        var weeks: [CalendarWeek] = []
        
        // Start from week 1
        // Note: ISO 8601 years have 52 or 53 weeks
        // We'll iterate until the year changes
        
        var currentWeekNum = 1
        
        while true {
            guard let weekDate = calendar.date(from: DateComponents(weekOfYear: currentWeekNum, yearForWeekOfYear: year)) else {
                break
            }
            
            // Check if we've moved to the next year
            let weekYear = calendar.component(.yearForWeekOfYear, from: weekDate)
            if weekYear != year {
                break
            }
            
            // Generate days for this week
            // We can reuse CalendarMonth.generateDaysForWeek logic or simplify
            // For the sidebar, we mainly need the week object.
            // Let's create a minimal version or reuse the logic if accessible.
            // Since generateDaysForWeek is private in CalendarMonth, we'll duplicate the day generation logic briefly here
            // or just store empty days if the sidebar doesn't show days (it doesn't).
            // BUT, the detail view might need days if we pass this object around.
            // Let's implement a helper to get days.
            
            let days = CalendarWeek.generateDays(for: weekDate)
            
            let week = CalendarWeek(
                weekNumber: currentWeekNum,
                year: year,
                days: days,
                startDate: weekDate
            )
            weeks.append(week)
            
            currentWeekNum += 1
            // Safety break
            if currentWeekNum > 53 { break }
        }
        
        return weeks
    }
    
    private static func generateDays(for startDate: Date) -> [CalendarDay] {
        let calendar = Calendar.iso8601
        var days: [CalendarDay] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            
            let dayNumber = calendar.component(.day, from: date)
            let isToday = calendar.isDateInToday(date)
            
            // Note: isInCurrentMonth is tricky here as a week can span months.
            // For the sidebar purpose, it matters less. We can just say true or check against the week's majority month?
            // Let's set it to true for now as this context is week-centric.
            
            let day = CalendarDay(
                date: date,
                dayNumber: dayNumber,
                isInCurrentMonth: true, 
                isToday: isToday,
                noteColor: nil, // Sidebar doesn't show notes
                secondaryDateString: nil
            )
            days.append(day)
        }
        return days
    }
}

// MARK: - Calendar Day Model

/// Represents a single day cell in the calendar grid
struct CalendarDay: Identifiable, Hashable {
    /// Thread-safe ID generation using Calendar components instead of DateFormatter
    /// DateFormatter is NOT thread-safe and SwiftUI may access id from background threads
    var id: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    let date: Date
    let dayNumber: Int
    let isInCurrentMonth: Bool
    let isToday: Bool
    let noteColor: String? // Added for color-coded note indicator

    /// Is this day a holiday (Bank Holiday)?
    /// Note: HolidayManager.holidayCache is nonisolated and thread-safe, so no @MainActor needed
    var isHoliday: Bool {
        let normalized = Calendar.current.startOfDay(for: date)
        return (HolidayManager.shared.holidayCache[normalized] ?? []).contains(where: { $0.isBankHoliday })
    }

    /// Name of the holiday (if any)
    /// Note: HolidayManager.holidayCache is nonisolated and thread-safe, so no @MainActor needed
    var holidayName: String? {
        let normalized = Calendar.current.startOfDay(for: date)
        return HolidayManager.shared.holidayCache[normalized]?.first?.displayTitle
    }

    /// SF Symbol for the holiday (if any)
    /// Note: HolidayManager.holidayCache is nonisolated and thread-safe, so no @MainActor needed
    var holidaySymbolName: String? {
        let normalized = Calendar.current.startOfDay(for: date)
        return HolidayManager.shared.holidayCache[normalized]?.first?.symbolName
    }

    /// Is this a significant day (Named but not Red)?
    var isSignificant: Bool {
        return holidayName != nil && !isHoliday
    }

    /// Weekday index (0 = Monday, 6 = Sunday)
    var weekdayIndex: Int {
        let calendar = Calendar.iso8601
        let weekday = calendar.component(.weekday, from: date)
        // Convert Sunday (1) to 6, Monday (2) to 0, etc.
        return weekday == 1 ? 6 : weekday - 2
    }

    /// Is this a weekend day?
    var isWeekend: Bool {
        weekdayIndex >= 5  // Saturday or Sunday
    }
    
    /// Secondary calendar date (e.g. Lunar)
    let secondaryDateString: String?
}

// MARK: - Calendar Navigation

/// Helper for navigating between months
extension CalendarMonth {
    /// Get the next month
    func nextMonth(noteColors: [Date: String] = [:]) -> CalendarMonth {
        if month == 12 {
            return CalendarMonth(year: year + 1, month: 1, noteColors: noteColors)
        } else {
            return CalendarMonth(year: year, month: month + 1, noteColors: noteColors)
        }
    }

    /// Get the previous month
    func previousMonth(noteColors: [Date: String] = [:]) -> CalendarMonth {
        if month == 1 {
            return CalendarMonth(year: year - 1, month: 12, noteColors: noteColors)
        } else {
            return CalendarMonth(year: year, month: month - 1, noteColors: noteColors)
        }
    }

    /// Create a month for today
    static func current(noteColors: [Date: String] = [:]) -> CalendarMonth {
        let now = Date()
        let calendar = Calendar.iso8601
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        return CalendarMonth(year: year, month: month, noteColors: noteColors)
    }

    /// Create a month containing a specific date
    static func containing(_ date: Date, noteColors: [Date: String] = [:]) -> CalendarMonth {
        let calendar = Calendar.iso8601
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return CalendarMonth(year: year, month: month, noteColors: noteColors)
    }
}

// MARK: - Calendar Identifier Helper

// Helper to map string to Calendar.Identifier
extension Calendar.Identifier {
    static func from(_ string: String) -> Calendar.Identifier? {
        switch string.lowercased() {
        case "gregorian": return .gregorian
        case "chinese": return .chinese
        case "hebrew": return .hebrew
        case "islamic": return .islamic
        case "buddhist": return .buddhist
        case "japanese": return .japanese
        case "iso8601": return .iso8601
        default: return nil
        }
    }
}

// MARK: - Sidebar Helper

struct MonthSection: Identifiable {
    let id: String
    let monthName: String
    let weeks: [CalendarWeek]
}

extension CalendarWeek {
    static func groupWeeksByMonth(_ weeks: [CalendarWeek]) -> [MonthSection] {
        let grouped = Dictionary(grouping: weeks) { week -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            return formatter.string(from: week.startDate)
        }
        
        // Sort months by date (using the first week of the group)
        let sortedKeys = grouped.keys.sorted { name1, name2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            let date1 = formatter.date(from: name1) ?? Date.distantPast
            let date2 = formatter.date(from: name2) ?? Date.distantPast
            return date1 < date2
        }
        
        return sortedKeys.compactMap { monthName in
            guard let weeks = grouped[monthName] else { return nil }
            let weeksInMonth = weeks.sorted { $0.weekNumber < $1.weekNumber }
            return MonthSection(id: monthName, monthName: monthName, weeks: weeksInMonth)
        }
    }
}
