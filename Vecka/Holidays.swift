import Foundation

// MARK: - Minimal Swedish Holiday Provider
/// Lightweight holiday detection for Sweden used only for coloring.
/// Covers fixed-date holidays and common movable holidays.
enum Holidays {
    static func isHoliday(_ date: Date) -> Bool {
        return holidayName(for: date) != nil
    }

    static func holidayName(for date: Date) -> String? {
        let cal = Calendar.iso8601
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)

        // Fixed-date official holidays
        if m == 1 && d == 1 { return "Nyårsdagen" }              // New Year's Day
        if m == 1 && d == 6 { return "Trettondedag jul" }        // Epiphany
        if m == 5 && d == 1 { return "Första maj" }              // May Day
        if m == 6 && d == 6 { return "Sveriges nationaldag" }    // National Day
        if m == 12 && d == 25 { return "Juldagen" }              // Christmas Day
        if m == 12 && d == 26 { return "Annandag jul" }          // Boxing Day

        // Movable: based on Easter Sunday
        let easter = easterSunday(year: y)
        if cal.isDate(date, inSameDayAs: easter.adding(days: -2, calendar: cal)) { return "Långfredagen" }
        if cal.isDate(date, inSameDayAs: easter) { return "Påskdagen" }
        if cal.isDate(date, inSameDayAs: easter.adding(days: 1, calendar: cal)) { return "Annandag påsk" }
        if cal.isDate(date, inSameDayAs: easter.adding(days: 39, calendar: cal)) { return "Kristi himmelsfärdsdag" }
        if cal.isDate(date, inSameDayAs: easter.adding(days: 49, calendar: cal)) { return "Pingstdagen" }

        // Midsummer Day: Saturday between June 20–26
        if m == 6, let midsummer = firstWeekday(.saturday, in: y, month: 6, dayRange: 20...26, calendar: cal), cal.isDate(date, inSameDayAs: midsummer) {
            return "Midsommardagen"
        }

        // All Saints' Day: Saturday between Oct 31 – Nov 6
        if (m == 10 || m == 11), let allSaints = firstWeekday(.saturday, in: y, month: 10, dayRange: 31...31, fallbackMonth: 11, fallbackEndDay: 6, calendar: cal), cal.isDate(date, inSameDayAs: allSaints) {
            return "Alla helgons dag"
        }

        return nil
    }

    // MARK: - Helpers
    private static func easterSunday(year: Int) -> Date {
        // Anonymous Gregorian computus
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

    private static func firstWeekday(_ weekday: Calendar.Weekday, in year: Int, month: Int, dayRange: ClosedRange<Int>, fallbackMonth: Int? = nil, fallbackEndDay: Int? = nil, calendar: Calendar) -> Date? {
        let start = DateComponents(year: year, month: month, day: dayRange.lowerBound)
        guard let startDate = calendar.date(from: start) else { return nil }
        var endMonth = month
        var endDay = dayRange.upperBound
        if let fm = fallbackMonth, let fe = fallbackEndDay, dayRange.lowerBound > dayRange.upperBound {
            endMonth = fm
            endDay = fe
        }
        guard let endDate = calendar.date(from: DateComponents(year: year, month: endMonth, day: endDay)) else { return nil }
        var cursor = startDate
        while cursor <= endDate {
            if calendar.component(.weekday, from: cursor) == weekday.rawValue { return cursor }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return nil
    }
}

private extension Date {
    func adding(days: Int, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: days, to: self) ?? self
    }
}

extension Calendar {
    enum Weekday: Int { case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday }
}
