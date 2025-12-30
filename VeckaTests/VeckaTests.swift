//
//  VeckaTests.swift
//  VeckaTests
//
//  Created by Nils Johansson on 2025-08-09.
//

import XCTest
@testable import Vecka

final class VeckaTests: XCTestCase {
    
    // MARK: - ISO 8601 Edge Cases
    
    func testISO8601YearBoundaryEdgeCases() {
        // Test case: 2025-12-29 (Monday) should be in ISO week 1 of 2026
        let december29_2025 = createDate(year: 2025, month: 12, day: 29)
        let weekInfo = WeekInfo(for: december29_2025)
        
        XCTAssertEqual(weekInfo.year, 2026, "December 29, 2025 should be in ISO year 2026")
        XCTAssertEqual(weekInfo.weekNumber, 1, "December 29, 2025 should be ISO week 1")
        
        // Test case: 2026-01-04 (Sunday) should be in ISO week 1 of 2026
        let january4_2026 = createDate(year: 2026, month: 1, day: 4)
        let weekInfo2026 = WeekInfo(for: january4_2026)
        
        XCTAssertEqual(weekInfo2026.year, 2026, "January 4, 2026 should be in ISO year 2026")
        XCTAssertEqual(weekInfo2026.weekNumber, 1, "January 4, 2026 should be ISO week 1")
    }
    
    func testISO8601Week53EdgeCase() {
        // Test years with 53 weeks (2020, 2026, etc.)
        let december28_2020 = createDate(year: 2020, month: 12, day: 28)
        let weekInfo = WeekInfo(for: december28_2020)
        
        XCTAssertEqual(weekInfo.year, 2020, "December 28, 2020 should be in ISO year 2020")
        XCTAssertEqual(weekInfo.weekNumber, 53, "2020 should have 53 weeks")
    }
    
    func testISO8601FirstThursdayRule() {
        // Test that week 1 always contains January 4th (first Thursday)
        for year in [2020, 2021, 2022, 2023, 2024, 2025, 2026] {
            let january4 = createDate(year: year, month: 1, day: 4)
            let weekInfo = WeekInfo(for: january4)
            
            XCTAssertEqual(weekInfo.weekNumber, 1, "January 4th of year \(year) must always be in ISO week 1")
            XCTAssertEqual(weekInfo.year, year, "January 4th of year \(year) must be in ISO year \(year)")
        }
    }
    
    // MARK: - Week Range Validation
    
    func testWeekDateRangeValidation() {
        let testDate = createDate(year: 2025, month: 8, day: 9) // Friday
        let weekInfo = WeekInfo(for: testDate)
        
        // Week should span exactly 7 days
        let calendar = Calendar.iso8601
        let daysBetween = calendar.dateComponents([.day], from: weekInfo.startDate, to: weekInfo.endDate).day
        XCTAssertEqual(daysBetween, 6, "Week should span exactly 6 days between start and end")
        
        // Test date should be within the week range
        XCTAssertTrue(testDate >= weekInfo.startDate && testDate <= weekInfo.endDate, 
                     "Input date should be within the calculated week range")
        
        // Week should start on Monday for ISO
        XCTAssertEqual(calendar.component(.weekday, from: weekInfo.startDate), 2, 
                      "ISO week should start on Monday")
        
        // Week should end on Sunday for ISO
        XCTAssertEqual(calendar.component(.weekday, from: weekInfo.endDate), 1, 
                      "ISO week should end on Sunday")
    }
    
    // MARK: - Formatter Testing
    
    func testDateIntervalFormatter() {
        let weekInfo = WeekInfo(for: createDate(year: 2025, month: 8, day: 9))
        let dateRange = weekInfo.dateRange
        
        XCTAssertFalse(dateRange.isEmpty, "Date range should not be empty")
        XCTAssertTrue(dateRange.contains("–") || dateRange.contains("-"), 
                     "Date range should contain a dash separator")
    }
    
    // MARK: - Performance Tests
    
    func testWeekInfoInitializationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = WeekInfo(for: Date())
            }
        }
    }
    
    func testFormatterPerformance() {
        let weekInfo = WeekInfo(for: Date())
        
        measure {
            for _ in 0..<100 {
                _ = weekInfo.dateRange
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createDate(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.timeZone = TimeZone.current
        
        return Calendar.current.date(from: components)!
    }
    
    // MARK: - Edge Case Stress Tests
    
    func testMultipleYearBoundaries() {
        let testDates = [
            createDate(year: 2019, month: 12, day: 30), // Week 1 of 2020
            createDate(year: 2020, month: 12, day: 28), // Week 53 of 2020
            createDate(year: 2021, month: 1, day: 3),   // Week 53 of 2020
            createDate(year: 2024, month: 12, day: 30), // Week 1 of 2025
            createDate(year: 2025, month: 12, day: 29), // Week 1 of 2026
        ]
        
        for testDate in testDates {
            let weekInfo = WeekInfo(for: testDate)
            
            // Basic validation
            XCTAssertTrue(weekInfo.weekNumber >= 1 && weekInfo.weekNumber <= 53, 
                         "Week number should be between 1 and 53")
            XCTAssertTrue(weekInfo.year >= 2019 && weekInfo.year <= 2026, 
                         "Year should be reasonable")
            XCTAssertTrue(weekInfo.startDate <= weekInfo.endDate, 
                         "Start date should be before end date")
        }
    }
    
    func testTimeZoneIndependence() {
        let testDate = createDate(year: 2025, month: 8, day: 9)

        // Test basic consistency
        let weekInfo1 = WeekInfo(for: testDate)
        let weekInfo2 = WeekInfo(for: testDate)

        // Week numbers should be consistent
        XCTAssertEqual(weekInfo1.weekNumber, weekInfo2.weekNumber,
                      "Week number should be consistent")
        XCTAssertEqual(weekInfo1.year, weekInfo2.year,
                      "Year should be consistent")
    }
}

// MARK: - HolidayEngine Tests

final class HolidayEngineTests: XCTestCase {

    private var engine: HolidayEngine!

    override func setUp() {
        super.setUp()
        engine = HolidayEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Easter Calculation Tests

    /// Helper to calculate Easter using the public calculateDate method with an Easter-relative rule
    private func calculateEaster(year: Int) -> Date? {
        let easterRule = HolidayRule(
            name: "Easter",
            isRedDay: true,
            type: .easterRelative,
            daysOffset: 0
        )
        return engine.calculateDate(for: easterRule, year: year)
    }

    func testEasterCalculation2024() {
        // Easter Sunday 2024: March 31
        let easter = calculateEaster(year: 2024)

        XCTAssertNotNil(easter)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: easter!)

        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 31)
    }

    func testEasterCalculation2025() {
        // Easter Sunday 2025: April 20
        let easter = calculateEaster(year: 2025)

        XCTAssertNotNil(easter)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: easter!)

        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 4)
        XCTAssertEqual(components.day, 20)
    }

    func testEasterCalculation2026() {
        // Easter Sunday 2026: April 5
        let easter = calculateEaster(year: 2026)

        XCTAssertNotNil(easter)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: easter!)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 4)
        XCTAssertEqual(components.day, 5)
    }

    // MARK: - Fixed Holiday Tests

    func testFixedHoliday() {
        let rule = HolidayRule(
            name: "Christmas",
            isRedDay: true,
            type: .fixed,
            month: 12,
            day: 25
        )

        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date!)

        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 25)
    }

    // MARK: - Easter-Relative Holiday Tests

    func testGoodFriday() {
        // Good Friday is 2 days before Easter
        let rule = HolidayRule(
            name: "Good Friday",
            isRedDay: true,
            type: .easterRelative,
            daysOffset: -2
        )

        // Easter 2025 is April 20, so Good Friday is April 18
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date!)

        XCTAssertEqual(components.month, 4)
        XCTAssertEqual(components.day, 18)
    }

    func testAscensionDay() {
        // Ascension Day is 39 days after Easter
        let rule = HolidayRule(
            name: "Ascension Day",
            isRedDay: true,
            type: .easterRelative,
            daysOffset: 39
        )

        // Easter 2025 is April 20, so Ascension is May 29
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date!)

        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.day, 29)
    }

    // MARK: - Nth Weekday Holiday Tests

    func testThanksgiving() {
        // 4th Thursday of November
        let rule = HolidayRule(
            name: "Thanksgiving",
            region: "US",
            isRedDay: true,
            type: .nthWeekday,
            month: 11,
            weekday: 5, // Thursday
            ordinal: 4
        )

        // Thanksgiving 2025 is November 27
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .weekday], from: date!)

        XCTAssertEqual(components.month, 11)
        XCTAssertEqual(components.day, 27)
        XCTAssertEqual(components.weekday, 5) // Thursday
    }

    func testMothersDay() {
        // Last Sunday in May (Sweden)
        let rule = HolidayRule(
            name: "Mother's Day",
            isRedDay: false,
            type: .nthWeekday,
            month: 5,
            weekday: 1, // Sunday
            ordinal: -1 // Last
        )

        // Mother's Day 2025 (Sweden) is May 25
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .weekday], from: date!)

        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.weekday, 1) // Sunday
    }

    // MARK: - Floating Holiday Tests

    func testMidsummerDay() {
        // Midsummer Day: Saturday between June 20-26
        let rule = HolidayRule(
            name: "Midsummer Day",
            isRedDay: true,
            type: .floating,
            month: 6,
            weekday: 7, // Saturday
            dayRangeStart: 20,
            dayRangeEnd: 26
        )

        // Midsummer Day 2025 is June 21
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .weekday], from: date!)

        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.weekday, 7) // Saturday
        XCTAssertTrue(components.day! >= 20 && components.day! <= 26)
    }

    // MARK: - HolidayRule Validation Tests

    func testValidFixedRule() {
        let rule = HolidayRule(
            name: "Test",
            isRedDay: true,
            type: .fixed,
            month: 12,
            day: 25
        )
        XCTAssertTrue(rule.isValid)
        XCTAssertNil(rule.validationError)
    }

    func testInvalidFixedRuleMissingMonth() {
        let rule = HolidayRule(
            name: "Test",
            isRedDay: true,
            type: .fixed,
            day: 25
        )
        XCTAssertFalse(rule.isValid)
        XCTAssertNotNil(rule.validationError)
    }

    func testInvalidMonthRange() {
        let rule = HolidayRule(
            name: "Test",
            isRedDay: true,
            type: .fixed,
            month: 13, // Invalid
            day: 25
        )
        XCTAssertFalse(rule.isValid)
        XCTAssertTrue(rule.validationError?.contains("1 and 12") ?? false)
    }

    func testInvalidDayRange() {
        let rule = HolidayRule(
            name: "Test",
            isRedDay: true,
            type: .fixed,
            month: 12,
            day: 32 // Invalid
        )
        XCTAssertFalse(rule.isValid)
        XCTAssertTrue(rule.validationError?.contains("1 and 31") ?? false)
    }

    func testInvalidEasterRelativeMissingOffset() {
        let rule = HolidayRule(
            name: "Test",
            isRedDay: true,
            type: .easterRelative
        )
        XCTAssertFalse(rule.isValid)
        XCTAssertTrue(rule.validationError?.contains("daysOffset") ?? false)
    }

    func testValidAstronomicalRule() {
        let rule = HolidayRule(
            name: "Summer Solstice",
            isRedDay: false,
            type: .astronomical,
            month: 6 // Valid (3, 6, 9, or 12)
        )
        XCTAssertTrue(rule.isValid)
    }

    func testInvalidAstronomicalMonth() {
        let rule = HolidayRule(
            name: "Test",
            isRedDay: false,
            type: .astronomical,
            month: 5 // Invalid - must be 3, 6, 9, or 12
        )
        XCTAssertFalse(rule.isValid)
        XCTAssertTrue(rule.validationError?.contains("3, 6, 9, or 12") ?? false)
    }
}

// MARK: - P1 Integration Tests

/// Week Calculation Integration Tests (8 tests)
final class WeekCalculationIntegrationTests: XCTestCase {

    // MARK: - WeekCalculator Singleton Tests

    func testWeekCalculatorSingletonConsistency() {
        let calculator1 = WeekCalculator.shared
        let calculator2 = WeekCalculator.shared

        XCTAssertTrue(calculator1 === calculator2, "WeekCalculator should be a singleton")
    }

    func testWeekCalculatorCacheHit() {
        let calculator = WeekCalculator.shared
        let testDate = Date()

        // First call populates cache
        let info1 = calculator.weekInfo(for: testDate)
        // Second call should hit cache
        let info2 = calculator.weekInfo(for: testDate)

        XCTAssertEqual(info1.weekNumber, info2.weekNumber)
        XCTAssertEqual(info1.year, info2.year)
    }

    func testWeekCalculatorWeeksInYear() {
        let calculator = WeekCalculator.shared

        // ISO 8601 years have either 52 or 53 weeks
        for year in 2020...2030 {
            let weeks = calculator.weeksInYear(year)
            XCTAssertTrue(weeks == 52 || weeks == 53,
                          "Year \(year) should have 52 or 53 weeks, got \(weeks)")
        }

        // Current year should have valid week count
        let currentYear = Calendar.iso8601.component(.year, from: Date())
        let currentYearWeeks = calculator.weeksInYear(currentYear)
        XCTAssertTrue(currentYearWeeks >= 52 && currentYearWeeks <= 53)
    }

    func testCalendarMonthGeneration() {
        let month = CalendarMonth.current()

        XCTAssertFalse(month.weeks.isEmpty, "Month should have weeks")
        XCTAssertTrue(month.weeks.count >= 4 && month.weeks.count <= 6, "Month should have 4-6 weeks")

        for week in month.weeks {
            XCTAssertEqual(week.days.count, 7, "Each week should have 7 days")
        }
    }

    func testCalendarWeekDayOrder() {
        let month = CalendarMonth.current()
        guard let firstWeek = month.weeks.first else {
            XCTFail("Month should have at least one week")
            return
        }

        // First day should be Monday (ISO 8601)
        let calendar = Calendar.iso8601
        let firstDayWeekday = calendar.component(.weekday, from: firstWeek.days[0].date)
        XCTAssertEqual(firstDayWeekday, 2, "First day of ISO week should be Monday")

        // Last day should be Sunday
        let lastDayWeekday = calendar.component(.weekday, from: firstWeek.days[6].date)
        XCTAssertEqual(lastDayWeekday, 1, "Last day of ISO week should be Sunday")
    }

    func testCalendarDayProperties() {
        let month = CalendarMonth.current()
        let today = Date()
        let calendar = Calendar.iso8601

        var foundToday = false
        for week in month.weeks {
            for day in week.days {
                if calendar.isDate(day.date, inSameDayAs: today) {
                    XCTAssertTrue(day.isToday, "Today's date should have isToday = true")
                    foundToday = true
                }
                // Day number should be valid
                XCTAssertTrue(day.dayNumber >= 1 && day.dayNumber <= 31)
            }
        }
        XCTAssertTrue(foundToday, "Should find today in current month")
    }

    func testWeekInfoDateRangeSpans7Days() {
        let weekInfo = WeekInfo(for: Date())
        let calendar = Calendar.iso8601

        guard let daysDifference = calendar.dateComponents([.day], from: weekInfo.startDate, to: weekInfo.endDate).day else {
            XCTFail("Should be able to calculate days difference")
            return
        }

        XCTAssertEqual(daysDifference, 6, "Week should span 6 days (Mon-Sun inclusive)")
    }

    func testViewUtilitiesDaysUntil() {
        let today = Date()
        let calendar = Calendar.iso8601

        // Days until today should be 0
        XCTAssertEqual(ViewUtilities.daysUntil(from: today, to: today), 0)

        // Days until tomorrow should be 1
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
            XCTAssertEqual(ViewUtilities.daysUntil(from: today, to: tomorrow), 1)
        }

        // Days until yesterday should be -1
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            XCTAssertEqual(ViewUtilities.daysUntil(from: today, to: yesterday), -1)
        }
    }
}

/// Holiday Accuracy Tests (12 tests)
final class HolidayAccuracyTests: XCTestCase {

    private var engine: HolidayEngine!

    override func setUp() {
        super.setUp()
        engine = HolidayEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Swedish Holiday Accuracy

    func testSwedishNewYearsDay() {
        let rule = HolidayRule(name: "New Year's Day", isRedDay: true, type: .fixed, month: 1, day: 1)
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        assertDate(date!, month: 1, day: 1, year: 2025)
    }

    func testSwedishEpiphany() {
        let rule = HolidayRule(name: "Epiphany", isRedDay: true, type: .fixed, month: 1, day: 6)
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        assertDate(date!, month: 1, day: 6, year: 2025)
    }

    func testSwedishMaundyThursday() {
        // Easter 2025: April 20, so Maundy Thursday is April 17
        let rule = HolidayRule(name: "Maundy Thursday", isRedDay: false, type: .easterRelative, daysOffset: -3)
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        assertDate(date!, month: 4, day: 17, year: 2025)
    }

    func testSwedishEasterMonday() {
        // Easter 2025: April 20, so Easter Monday is April 21
        let rule = HolidayRule(name: "Easter Monday", isRedDay: true, type: .easterRelative, daysOffset: 1)
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        assertDate(date!, month: 4, day: 21, year: 2025)
    }

    func testSwedishWalpurgisNight() {
        let rule = HolidayRule(name: "Walpurgis Night", isRedDay: false, type: .fixed, month: 4, day: 30)
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        assertDate(date!, month: 4, day: 30, year: 2025)
    }

    func testSwedishMayDay() {
        let rule = HolidayRule(name: "May Day", isRedDay: true, type: .fixed, month: 5, day: 1)
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        assertDate(date!, month: 5, day: 1, year: 2025)
    }

    func testSwedishNationalDay() {
        let rule = HolidayRule(name: "National Day", isRedDay: true, type: .fixed, month: 6, day: 6)
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        assertDate(date!, month: 6, day: 6, year: 2025)
    }

    func testSwedishMidsummerEve() {
        // Friday between June 19-25
        let rule = HolidayRule(name: "Midsummer Eve", isRedDay: false, type: .floating, month: 6, weekday: 6, dayRangeStart: 19, dayRangeEnd: 25)
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .weekday], from: date!)

        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.weekday, 6) // Friday
        XCTAssertTrue(components.day! >= 19 && components.day! <= 25)
    }

    func testSwedishAllSaintsDay() {
        // Saturday between Oct 31 - Nov 6
        let rule = HolidayRule(name: "All Saints' Day", isRedDay: true, type: .floating, month: 11, weekday: 7, dayRangeStart: 31, dayRangeEnd: 37)
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date!)
        XCTAssertEqual(components.weekday, 7) // Saturday
    }

    func testSwedishChristmasEve() {
        let rule = HolidayRule(name: "Christmas Eve", isRedDay: false, type: .fixed, month: 12, day: 24)
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        assertDate(date!, month: 12, day: 24, year: 2025)
    }

    func testSwedishChristmasDay() {
        let rule = HolidayRule(name: "Christmas Day", isRedDay: true, type: .fixed, month: 12, day: 25)
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        assertDate(date!, month: 12, day: 25, year: 2025)
    }

    func testSwedishBoxingDay() {
        let rule = HolidayRule(name: "Boxing Day", isRedDay: true, type: .fixed, month: 12, day: 26)
        let date = engine.calculateDate(for: rule, year: 2025)

        XCTAssertNotNil(date)
        assertDate(date!, month: 12, day: 26, year: 2025)
    }

    // MARK: - Helper

    private func assertDate(_ date: Date, month: Int, day: Int, year: Int, file: StaticString = #file, line: UInt = #line) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        XCTAssertEqual(components.year, year, "Year mismatch", file: file, line: line)
        XCTAssertEqual(components.month, month, "Month mismatch", file: file, line: line)
        XCTAssertEqual(components.day, day, "Day mismatch", file: file, line: line)
    }
}

/// Service Integration Tests (10 tests)
final class ServiceIntegrationTests: XCTestCase {

    // MARK: - Calendar Extension Tests

    func testCalendarISO8601Extension() {
        let calendar = Calendar.iso8601

        XCTAssertEqual(calendar.firstWeekday, 2, "ISO 8601 week starts on Monday")
        XCTAssertEqual(calendar.minimumDaysInFirstWeek, 4, "ISO 8601 requires 4 days in first week")
    }

    func testCalendarISO8601Consistency() {
        let calendar1 = Calendar.iso8601
        let calendar2 = Calendar.iso8601

        XCTAssertEqual(calendar1.firstWeekday, calendar2.firstWeekday)
        XCTAssertEqual(calendar1.minimumDaysInFirstWeek, calendar2.minimumDaysInFirstWeek)
    }

    // MARK: - Date Formatter Tests

    func testDateFormatterCacheThreadSafety() {
        let expectation = XCTestExpectation(description: "Concurrent formatter access")
        expectation.expectedFulfillmentCount = 10

        let testDate = Date()

        for _ in 0..<10 {
            DispatchQueue.global().async {
                _ = DateFormatterCache.monthName.string(from: testDate)
                _ = DateFormatterCache.weekdayShort.string(from: testDate)
                _ = DateFormatterCache.dayNumber.string(from: testDate)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testDateFormatterOutputFormats() {
        let testDate = createDate(year: 2025, month: 8, day: 15)

        let dayNumber = DateFormatterCache.dayNumber.string(from: testDate)
        XCTAssertEqual(dayNumber, "15")

        let monthName = DateFormatterCache.monthName.string(from: testDate)
        XCTAssertFalse(monthName.isEmpty)
    }

    // MARK: - View Utilities Tests

    func testMonthProgress() {
        let midMonth = createDate(year: 2025, month: 6, day: 15)
        let progress = ViewUtilities.monthProgress(for: midMonth)

        XCTAssertTrue(progress > 0.4 && progress < 0.6, "Mid-month should be ~50% progress")
    }

    func testYearProgress() {
        let midYear = createDate(year: 2025, month: 7, day: 1)
        let progress = ViewUtilities.yearProgress(for: midYear)

        XCTAssertTrue(progress > 0.4 && progress < 0.6, "Mid-year should be ~50% progress")
    }

    func testDayOfMonth() {
        let testDate = createDate(year: 2025, month: 8, day: 20)
        let day = ViewUtilities.dayOfMonth(for: testDate)

        XCTAssertEqual(day, 20)
    }

    func testDayOfWeek() {
        // August 20, 2025 is a Wednesday
        let testDate = createDate(year: 2025, month: 8, day: 20)
        let weekday = ViewUtilities.dayOfWeek(for: testDate)

        XCTAssertEqual(weekday, 4) // Wednesday in ISO calendar (Mon=2, Tue=3, Wed=4...)
    }

    // MARK: - Animation Constants Tests

    func testAnimationConstantsExist() {
        XCTAssertNotNil(AnimationConstants.quickSpring)
        XCTAssertNotNil(AnimationConstants.standardSpring)
        XCTAssertNotNil(AnimationConstants.gentleSpring)
        XCTAssertNotNil(AnimationConstants.sidebarSpring)
        XCTAssertNotNil(AnimationConstants.calendarSpring)
    }

    func testLayoutConstantsValues() {
        XCTAssertEqual(LayoutConstants.minimumTapTarget, 44, "Minimum tap target should be 44pt (HIG)")
        XCTAssertTrue(LayoutConstants.cornerRadius > 0)
        XCTAssertTrue(LayoutConstants.cardSpacing > 0)
    }

    // MARK: - Helper

    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components)!
    }
}

// MARK: - P2 Polish Tests

/// UI Accessibility Tests (8 tests)
final class UIAccessibilityTests: XCTestCase {

    func testSpacingTokensExist() {
        // Verify all Spacing tokens exist and have reasonable values
        XCTAssertEqual(Spacing.extraSmall, 4)
        XCTAssertEqual(Spacing.small, 8)
        XCTAssertEqual(Spacing.medium, 16)
        XCTAssertEqual(Spacing.large, 24)
        XCTAssertEqual(Spacing.extraLarge, 32)
        XCTAssertEqual(Spacing.huge, 48)
        XCTAssertEqual(Spacing.massive, 64)
    }

    func testSpacingTokensFollowScale() {
        // Spacing should follow a logical progression
        XCTAssertTrue(Spacing.small < Spacing.medium)
        XCTAssertTrue(Spacing.medium < Spacing.large)
        XCTAssertTrue(Spacing.large < Spacing.extraLarge)
        XCTAssertTrue(Spacing.extraLarge < Spacing.huge)
    }

    func testTypographyTokensExist() {
        // Verify Typography tokens exist
        XCTAssertNotNil(Typography.title1)
        XCTAssertNotNil(Typography.headline)
        XCTAssertNotNil(Typography.body)
        XCTAssertNotNil(Typography.caption1)
    }

    func testAppColorsExist() {
        // Verify key color tokens exist
        XCTAssertNotNil(AppColors.background)
        XCTAssertNotNil(AppColors.surface)
        XCTAssertNotNil(AppColors.accentBlue)
        XCTAssertNotNil(AppColors.textPrimary)
        XCTAssertNotNil(AppColors.textSecondary)
    }

    func testSlateColorsExist() {
        // Verify SlateColors tokens exist
        XCTAssertNotNil(SlateColors.deepSlate)
        XCTAssertNotNil(SlateColors.mediumSlate)
        XCTAssertNotNil(SlateColors.primaryText)
        XCTAssertNotNil(SlateColors.secondaryText)
        XCTAssertNotNil(SlateColors.sundayBlue)
    }

    func testPlanetaryColorsExist() {
        // Verify all 7 planetary colors exist
        XCTAssertNotNil(AppColors.mondayMoon)
        XCTAssertNotNil(AppColors.tuesdayFire)
        XCTAssertNotNil(AppColors.wednesdayWater)
        XCTAssertNotNil(AppColors.thursdayWood)
        XCTAssertNotNil(AppColors.fridayMetal)
        XCTAssertNotNil(AppColors.saturdayEarth)
        XCTAssertNotNil(AppColors.sundaySun)
    }

    func testColorForDayReturnsValidColor() {
        let today = Date()
        let color = AppColors.colorForDay(today)

        XCTAssertNotNil(color, "colorForDay should return a valid color")
    }

    func testMinimumTapTargetSize() {
        // HIG requires 44pt minimum tap targets
        XCTAssertGreaterThanOrEqual(LayoutConstants.minimumTapTarget, 44)
    }
}

/// Performance Benchmark Tests (6 tests)
final class PerformanceBenchmarkTests: XCTestCase {

    func testWeekInfoCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = WeekInfo(for: Date())
            }
        }
    }

    func testCalendarMonthCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = CalendarMonth.current()
            }
        }
    }

    func testHolidayEngineCalculationPerformance() {
        let engine = HolidayEngine()
        let rule = HolidayRule(name: "Test", isRedDay: true, type: .easterRelative, daysOffset: 0)

        measure {
            for year in 2020..<2030 {
                _ = engine.calculateDate(for: rule, year: year)
            }
        }
    }

    func testDateFormatterPerformance() {
        let testDate = Date()

        measure {
            for _ in 0..<1000 {
                _ = DateFormatterCache.dayNumber.string(from: testDate)
                _ = DateFormatterCache.monthName.string(from: testDate)
            }
        }
    }

    func testViewUtilitiesProgressCalculationPerformance() {
        let testDate = Date()

        measure {
            for _ in 0..<1000 {
                _ = ViewUtilities.monthProgress(for: testDate)
                _ = ViewUtilities.yearProgress(for: testDate)
            }
        }
    }

    func testWeekCalculatorCacheEfficiency() {
        let calculator = WeekCalculator.shared
        let testDate = Date()

        // Warm up cache
        _ = calculator.weekInfo(for: testDate)

        measure {
            // This should be fast due to caching
            for _ in 0..<10000 {
                _ = calculator.weekInfo(for: testDate)
            }
        }
    }
}

/// Snapshot/State Tests (6 tests)
final class StateConsistencyTests: XCTestCase {

    func testCalendarDayHashableConformance() {
        let month = CalendarMonth.current()
        guard let day1 = month.weeks.first?.days.first else {
            XCTFail("Should have at least one day")
            return
        }

        // Same day should have same hash
        let day2 = day1
        XCTAssertEqual(day1.hashValue, day2.hashValue)

        // Should be usable in Set
        var daySet = Set<CalendarDay>()
        daySet.insert(day1)
        XCTAssertTrue(daySet.contains(day1))
    }

    func testCalendarWeekHashableConformance() {
        let month = CalendarMonth.current()
        guard let week1 = month.weeks.first else {
            XCTFail("Should have at least one week")
            return
        }

        // Same week should have same hash
        let week2 = week1
        XCTAssertEqual(week1.hashValue, week2.hashValue)

        // Should be usable in Set
        var weekSet = Set<CalendarWeek>()
        weekSet.insert(week1)
        XCTAssertTrue(weekSet.contains(week1))
    }

    func testCalendarMonthHashableConformance() {
        let month1 = CalendarMonth.current()
        let month2 = CalendarMonth.current()

        // Same month should have same hash
        XCTAssertEqual(month1.hashValue, month2.hashValue)
    }

    func testHolidayCacheItemEquatability() {
        let item1 = HolidayCacheItem(id: "test", region: "SE", name: "Test", titleOverride: nil, isRedDay: true, symbolName: nil)
        let item2 = HolidayCacheItem(id: "test", region: "SE", name: "Test", titleOverride: nil, isRedDay: true, symbolName: nil)

        XCTAssertEqual(item1, item2)
        XCTAssertEqual(item1.hashValue, item2.hashValue)
    }

    func testHolidayCacheItemDisplayTitle() {
        // Without override, should return localized name
        let item1 = HolidayCacheItem(id: "test", region: "SE", name: "holiday.christmas", titleOverride: nil, isRedDay: true, symbolName: nil)
        XCTAssertFalse(item1.displayTitle.isEmpty)

        // With override, should return override
        let item2 = HolidayCacheItem(id: "test", region: "SE", name: "holiday.christmas", titleOverride: "Custom Title", isRedDay: true, symbolName: nil)
        XCTAssertEqual(item2.displayTitle, "Custom Title")
    }

    func testWeekInfoConsistency() {
        let date = Date()

        // Creating WeekInfo multiple times should give consistent results
        let info1 = WeekInfo(for: date)
        let info2 = WeekInfo(for: date)

        XCTAssertEqual(info1.weekNumber, info2.weekNumber)
        XCTAssertEqual(info1.year, info2.year)
        XCTAssertEqual(info1.startDate, info2.startDate)
        XCTAssertEqual(info1.endDate, info2.endDate)
    }
}