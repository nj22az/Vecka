//
//  ViewUtilities.swift
//  Vecka
//
//  Master Swift refactoring - Shared utilities and formatters
//  Following Apple Design Guidelines and Liquid Glass principles
//

import SwiftUI
import Foundation

// MARK: - Performance-Optimized Date Formatters
/// Thread-safe, cached formatters following Apple performance guidelines
enum DateFormatterCache {
    static let monthName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale.current
        return formatter
    }()
    
    static let weekdayShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale.current
        return formatter
    }()
    
    static let dayNumber: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        formatter.locale = Locale.current
        return formatter
    }()
    
    static let weekRange: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale.current
        return formatter
    }()
    
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale.current
        return formatter
    }()
    
    static let longDateWithYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        formatter.locale = Locale.current
        return formatter
    }()
}

// MARK: - Calendar Extension (ISO 8601)
extension Calendar {
    static let iso8601: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.locale = .autoupdatingCurrent
        cal.timeZone = .autoupdatingCurrent
        return cal
    }()
}

// MARK: - Week Information Model
/// Lightweight model for week display information
struct WeekInfo {
    let weekNumber: Int
    let year: Int
    let dateRange: String
    let startDate: Date
    let endDate: Date
    
    init(for date: Date = Date()) {
        let calendar = Calendar.iso8601
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2 // Monday
        let startDate = calendar.date(from: components) ?? date
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? date
        
        let startString = DateFormatterCache.weekRange.string(from: startDate)
        let endString = DateFormatterCache.weekRange.string(from: endDate)
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)
        
        self.weekNumber = week
        self.year = year
        if startYear == endYear {
            self.dateRange = "\(startString) – \(endString), \(startYear)"
        } else {
            self.dateRange = "\(startString), \(startYear) – \(endString), \(endYear)"
        }
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Calendar Day Model
/// Model for individual calendar day information
struct CalendarDayInfo {
    let date: Date
    let dayNumber: Int
    let isToday: Bool
    let isSelected: Bool
    let isCurrentMonth: Bool
    let weekNumber: Int
    
    init(date: Date, dayNumber: Int, isToday: Bool, isSelected: Bool, isCurrentMonth: Bool, weekNumber: Int) {
        self.date = date
        self.dayNumber = dayNumber
        self.isToday = isToday
        self.isSelected = isSelected
        self.isCurrentMonth = isCurrentMonth
        self.weekNumber = weekNumber
    }
}

// MARK: - View Utility Functions
/// Collection of utility functions for view calculations
struct ViewUtilities {
    
    // MARK: - Date Calculations
    
    static func monthProgress(for date: Date = Date()) -> Double {
        let calendar = Calendar.iso8601
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let monthEnd = calendar.date(from: DateComponents(year: year, month: month + 1, day: 1)),
              let daysInMonth = calendar.dateComponents([.day], from: monthStart, to: monthEnd).day else {
            return 0.0
        }
        
        return Double(day) / Double(daysInMonth)
    }
    
    static func yearProgress(for date: Date = Date()) -> Double {
        let calendar = Calendar.iso8601
        let year = calendar.component(.year, from: date)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        guard let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let yearEnd = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)),
              let daysInYear = calendar.dateComponents([.day], from: yearStart, to: yearEnd).day else {
            return 0.0
        }
        
        return Double(dayOfYear) / Double(daysInYear)
    }
    
    static func dayOfMonth(for date: Date = Date()) -> Int {
        Calendar.iso8601.component(.day, from: date)
    }
    
    static func dayOfWeek(for date: Date = Date()) -> Int {
        Calendar.iso8601.component(.weekday, from: date)
    }
    
    // MARK: - String Formatting
    
    static func selectedDateShort(_ date: Date) -> String {
        DateFormatterCache.dayNumber.string(from: date)
    }
    
    static func currentDateShort(_ date: Date = Date()) -> String {
        DateFormatterCache.dayNumber.string(from: date)
    }
    
    static func todayDateNumber(_ date: Date = Date()) -> String {
        DateFormatterCache.dayNumber.string(from: date)
    }
    
    static func todayButtonText(isToday: Bool) -> String {
        isToday ? "CURRENT" : "GO TO"
    }
    
    // MARK: - Color Utilities
    
    /// Safe color calculation - simplified to use daily colors
    static func safeColorForDay(_ date: Date) -> Color {
        return AppColors.colorForDay(date)
    }
    
    /// Dynamic color selection for today/selected states
    static func dynamicStateColor(isToday: Bool) -> Color {
        return isToday ? AppColors.accentBlue : AppColors.thursdayWood
    }
}

// MARK: - Animation Constants
/// Consistent animation values following Apple HIG
enum AnimationConstants {
    static let springResponse: Double = 0.4
    static let springDampingFraction: Double = 0.8
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)
    static let standardSpring = Animation.spring(response: springResponse, dampingFraction: springDampingFraction, blendDuration: 0.1)
    static let gentleSpring = Animation.spring(response: 0.5, dampingFraction: 0.9, blendDuration: 0.2)
}

// MARK: - Layout Constants
/// Apple HIG-compliant spacing and sizing
enum LayoutConstants {
    static let cornerRadius: CGFloat = 12
    static let cardSpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let gridSpacing: CGFloat = 12
    static let minimumTapTarget: CGFloat = 44
    
    // Glass design specific
    static let glassBlurRadius: CGFloat = 20
    static let glassShadowRadius: CGFloat = 8
    static let glassBorderWidth: CGFloat = 0.5
}

#if canImport(UIKit)
// MARK: - Keyboard Utilities
extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
