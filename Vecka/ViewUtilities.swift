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
// WeekInfo is now defined in Core/WeekCalculator.swift for production-grade implementation

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

    /// Calculate days between two dates (ISO 8601 calendar)
    /// - Parameters:
    ///   - from: Start date (defaults to today at start of day)
    ///   - to: Target date (at start of day)
    /// - Returns: Number of days between dates (positive for future, negative for past)
    static func daysUntil(from: Date = Date(), to target: Date) -> Int {
        let calendar = Calendar.iso8601
        let startDay = calendar.startOfDay(for: from)
        let targetDay = calendar.startOfDay(for: target)
        return calendar.dateComponents([.day], from: startDay, to: targetDay).day ?? 0
    }

    /// Get the number of ISO 8601 weeks in a given year
    /// - Parameter year: The year to check
    /// - Returns: Number of weeks (52 or 53)
    static func weeksInYear(_ year: Int) -> Int {
        WeekCalculator.shared.weeksInYear(year)
    }

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
        return JohoColors.cyan
    }
    
    /// Dynamic color selection for today/selected states
    static func dynamicStateColor(isToday: Bool) -> Color {
        return isToday ? JohoColors.cyan : JohoColors.green
    }
}

// MARK: - Animation Constants
/// Consistent animation values following Apple HIG
enum AnimationConstants {
    // Base values
    static let springResponse: Double = 0.4
    static let springDampingFraction: Double = 0.8

    // Named animations for common use cases
    /// Quick, snappy spring for selection feedback (0.3s, 0.7 damping)
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)
    /// Standard spring for general transitions (0.4s, 0.8 damping)
    static let standardSpring = Animation.spring(response: springResponse, dampingFraction: springDampingFraction, blendDuration: 0.1)
    /// Gentle spring for subtle movements (0.5s, 0.9 damping)
    static let gentleSpring = Animation.spring(response: 0.5, dampingFraction: 0.9, blendDuration: 0.2)

    // UI-specific animations
    /// Sidebar/navigation selection spring (0.3s, 0.8 damping)
    static let sidebarSpring = Animation.spring(response: 0.3, dampingFraction: 0.8)
    /// Calendar navigation spring (0.35s, 0.85 damping)
    static let calendarSpring = Animation.spring(response: 0.35, dampingFraction: 0.85)
    /// Dashboard card expansion spring (0.35s, 0.9 damping)
    static let dashboardSpring = Animation.spring(response: 0.35, dampingFraction: 0.9)
    /// Button press feedback (0.15s ease)
    static let buttonPress = Animation.easeInOut(duration: 0.15)
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

// MARK: - Conditional View Modifier
extension View {
    /// Conditionally applies a modifier to a view
    /// - Parameters:
    ///   - condition: Boolean condition
    ///   - transform: The modifier to apply if condition is true
    /// - Returns: Either the modified or original view
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#if canImport(UIKit)
// MARK: - Keyboard Utilities
extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
