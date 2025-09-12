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