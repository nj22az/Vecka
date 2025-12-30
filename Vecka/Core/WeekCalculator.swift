//
//  WeekCalculator.swift
//  Vecka
//
//  Production-grade ISO 8601 week number calculator
//  Thread-safe, cached, optimized for performance
//

import Foundation

/// Thread-safe, high-performance ISO 8601 week number calculator
final class WeekCalculator {

    // MARK: - Singleton
    static let shared = WeekCalculator()

    // MARK: - Properties
    private var calendar: Calendar
    // Thread-safe cache using lock
    private let cacheLock = NSLock()
    private var _cache: [String: WeekInfo] = [:]

    private var cache: [String: WeekInfo] {
        get {
            cacheLock.lock()
            defer { cacheLock.unlock() }
            return _cache
        }
        set {
            cacheLock.lock()
            defer { cacheLock.unlock() }
            _cache = newValue
        }
    }

    // MARK: - Initialization
    private init() {
        // Default fallback (ISO 8601 / Sweden)
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        cal.minimumDaysInFirstWeek = 4 // ISO 8601
        cal.locale = Locale(identifier: "sv_SE")
        cal.timeZone = TimeZone.autoupdatingCurrent
        self.calendar = cal
    }
    
    /// Configure the calculator with a rule from the database
    @MainActor
    func configure(with rule: CalendarRule) {
        // Parse calendar identifier from rule
        let identifier: Calendar.Identifier
        if let parsed = Calendar.Identifier.from(rule.identifier) {
            identifier = parsed
        } else {
            identifier = .gregorian  // Fallback to gregorian
        }

        var cal = Calendar(identifier: identifier)
        cal.firstWeekday = rule.firstWeekday
        cal.minimumDaysInFirstWeek = rule.minimumDaysInFirstWeek
        cal.locale = Locale(identifier: rule.localeIdentifier)
        cal.timeZone = TimeZone.autoupdatingCurrent

        // Update the internal calendar
        self.calendar = cal

        // Clear cache as rules changed (thread-safe via setter)
        cache = [:]
        Log.i("WeekCalculator configured with rule: \(rule.id) (FirstDay: \(rule.firstWeekday), MinDays: \(rule.minimumDaysInFirstWeek))")
    }

    // MARK: - Public API

    /// Get the current ISO 8601 week number
    func currentWeekNumber() -> Int {
        weekNumber(for: Date())
    }

    /// Get the current year for week numbering
    func currentYear() -> Int {
        calendar.component(.yearForWeekOfYear, from: Date())
    }

    /// Get the ISO 8601 week number for a specific date
    func weekNumber(for date: Date) -> Int {
        calendar.component(.weekOfYear, from: date)
    }

    /// Get comprehensive week information for a date
    func weekInfo(for date: Date = Date()) -> WeekInfo {
        // Check cache first
        let key = cacheKey(for: date)
        if let cached = cache[key] {
            return cached
        }

        // Calculate
        let info = calculateWeekInfo(for: date)

        // Cache result
        cache[key] = info

        return info
    }

    /// Get all dates in a specific week
    func dates(in weekNumber: Int, year: Int) -> [Date] {
        var components = DateComponents()
        components.yearForWeekOfYear = year
        components.weekOfYear = weekNumber
        components.weekday = 2 // Monday (ISO 8601 starts on Monday)

        guard let startDate = calendar.date(from: components) else {
            return []
        }

        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startDate)
        }
    }

    /// Check if a date is in the current week
    func isInCurrentWeek(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// Get the start date of a week
    func startOfWeek(for date: Date) -> Date {
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2 // Monday
        return calendar.date(from: components) ?? date
    }

    /// Get the end date of a week
    func endOfWeek(for date: Date) -> Date {
        let start = startOfWeek(for: date)
        return calendar.date(byAdding: .day, value: 6, to: start) ?? date
    }

    /// Calculate progress through the current week (0.0 to 1.0)
    func weekProgress(for date: Date = Date()) -> Double {
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        // Convert weekday to 0-6 (Monday = 0, Sunday = 6)
        let dayIndex = (weekday == 1) ? 6 : weekday - 2

        // Calculate total minutes elapsed
        let minutesElapsed = (dayIndex * 24 * 60) + (hour * 60) + minute
        let totalMinutesInWeek = 7 * 24 * 60

        return Double(minutesElapsed) / Double(totalMinutesInWeek)
    }

    /// Get the number of weeks in a year
    /// Get the number of weeks in a year (Database Driven)
    func weeksInYear(_ year: Int) -> Int {
        // We pick a date late in the year to ensure we capture the full range
        // Dec 28th is always in the last week or close to it in ISO, but let's use a safer generic approach.
        // Actually, asking for the range of weeks in the yearForWeekOfYear is the most robust method
        // that respects the 'minimumDaysInFirstWeek' rule from the DB.
        
        let components = DateComponents(year: year, month: 1, day: 1)
        guard let date = calendar.date(from: components) else { return 52 }
        
        if let range = calendar.range(of: .weekOfYear, in: .yearForWeekOfYear, for: date) {
            return range.count
        }
        return 52
    }

    // MARK: - Private Methods

    private func calculateWeekInfo(for date: Date) -> WeekInfo {
        let weekNumber = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)

        let startDate = startOfWeek(for: date)
        let endDate = endOfWeek(for: date)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)

        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)

        let dateRange: String
        if startYear == endYear {
            dateRange = "\(startString) – \(endString), \(startYear)"
        } else {
            dateRange = "\(startString), \(startYear) – \(endString), \(endYear)"
        }

        // Calculate days remaining
        let now = Date()
        let daysRemaining: Int
        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let weekday = calendar.component(.weekday, from: now)
            // Convert to 0-6 (Monday = 0)
            let dayIndex = (weekday == 1) ? 6 : weekday - 2
            daysRemaining = 6 - dayIndex
        } else {
            daysRemaining = 0
        }

        return WeekInfo(
            weekNumber: weekNumber,
            year: year,
            startDate: startDate,
            endDate: endDate,
            dateRange: dateRange,
            daysRemaining: daysRemaining,
            isCurrentWeek: calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        )
    }

    private func cacheKey(for date: Date) -> String {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(components.yearForWeekOfYear ?? 0)-\(components.weekOfYear ?? 0)"
    }
}

// MARK: - WeekInfo Model

/// Comprehensive information about an ISO 8601 week
struct WeekInfo: Codable, Hashable {
    let weekNumber: Int
    let year: Int
    let startDate: Date
    let endDate: Date
    let dateRange: String
    let daysRemaining: Int
    let isCurrentWeek: Bool

    /// Formatted week string (e.g., "Week 48")
    var weekString: String {
        "Week \(weekNumber)"
    }

    /// Short week string (e.g., "W48")
    var shortWeekString: String {
        "W\(weekNumber)"
    }

    /// Full description (e.g., "Week 48 of 2025")
    var fullDescription: String {
        "Week \(weekNumber) of \(year)"
    }

    /// Accessibility description
    var accessibilityDescription: String {
        var description = "Week \(weekNumber), \(dateRange)"
        if isCurrentWeek {
            description += ", current week"
            if daysRemaining > 0 {
                description += ", \(daysRemaining) day\(daysRemaining == 1 ? "" : "s") remaining"
            }
        }
        return description
    }

    init(
        weekNumber: Int,
        year: Int,
        startDate: Date,
        endDate: Date,
        dateRange: String,
        daysRemaining: Int = 0,
        isCurrentWeek: Bool = false
    ) {
        self.weekNumber = weekNumber
        self.year = year
        self.startDate = startDate
        self.endDate = endDate
        self.dateRange = dateRange
        self.daysRemaining = daysRemaining
        self.isCurrentWeek = isCurrentWeek
    }

    /// Legacy initializer for compatibility
    init(for date: Date, localized: Bool = false) {
        let calculator = WeekCalculator.shared
        let info = calculator.weekInfo(for: date)
        self = info
    }
}

// MARK: - Extensions

extension WeekInfo {
    /// Get all dates in this week
    var dates: [Date] {
        WeekCalculator.shared.dates(in: weekNumber, year: year)
    }

    /// Check if a date is in this week
    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.iso8601
        return calendar.isDate(date, equalTo: startDate, toGranularity: .weekOfYear)
    }
}
