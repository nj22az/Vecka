//
//  Localization.swift
//  Vecka
//
//  Comprehensive localization system supporting Swedish, English, Japanese, Korean, German, Vietnamese, and Thai
//

import Foundation
import SwiftUI

// MARK: - Language Detection Manager
class LanguageManager: ObservableObject {
    @Published var currentLanguage: String = "en"
    @Published var supportedLanguages: [String] = ["en", "sv", "ja", "ko", "de", "vi", "th"]
    
    static let shared = LanguageManager()
    
    private init() {
        detectSystemLanguage()
    }
    
    func detectSystemLanguage() {
        let preferredLanguages = Locale.preferredLanguages
        let currentLocale = Locale.current
        
        // Try to find a supported language from user's preferred languages
        for preferredLang in preferredLanguages {
            let langCode = String(preferredLang.prefix(2))
            if supportedLanguages.contains(langCode) {
                currentLanguage = langCode
                print("✅ Detected system language: \(langCode)")
                return
            }
        }
        
        // Fall back to current locale language
        if let langCode = currentLocale.language.languageCode?.identifier,
           supportedLanguages.contains(langCode) {
            currentLanguage = langCode
            print("✅ Using current locale language: \(langCode)")
        } else {
            currentLanguage = "en" // Final fallback
            print("⚠️ Falling back to English")
        }
    }
    
    func getLanguageName() -> String {
        switch currentLanguage {
        case "sv": return "Swedish"
        case "ja": return "Japanese"
        case "ko": return "Korean" 
        case "de": return "German"
        case "vi": return "Vietnamese"
        case "th": return "Thai"
        default: return "English"
        }
    }
    
    func getLocaleName() -> String {
        switch currentLanguage {
        case "sv": return "sv_SE"
        case "ja": return "ja_JP"
        case "ko": return "ko_KR"
        case "de": return "de_DE"
        case "vi": return "vi_VN"
        case "th": return "th_TH"
        default: return "en_US"
        }
    }
}

// MARK: - Localization Manager
struct Localization {
    
    // MARK: - Core App Strings
    static let appName = NSLocalizedString("app.name", value: "WEEK BUDDY", comment: "App name")
    static let today = NSLocalizedString("common.today", value: "Today", comment: "Today")
    static let goToToday = NSLocalizedString("action.go_to_today", value: "GO TO TODAY", comment: "Go to today action")
    static let cancel = NSLocalizedString("common.cancel", value: "Cancel", comment: "Cancel")
    static let save = NSLocalizedString("common.save", value: "Save", comment: "Save")
    static let delete = NSLocalizedString("common.delete", value: "Delete", comment: "Delete")

    // MARK: - Picker & Events Management
    static let favoritesCountFormat = NSLocalizedString("picker.favorites_count", value: "Favorites %d/4", comment: "Favorites count footer")
    static let predefined = NSLocalizedString("picker.predefined", value: "Predefined", comment: "Predefined section header")
    static let customEvents = NSLocalizedString("picker.custom_events", value: "Custom Events", comment: "Custom events section header")
    static let createCustom = NSLocalizedString("picker.create_custom", value: "Create Custom…", comment: "Create custom event action")
    static let favorite = NSLocalizedString("picker.favorite", value: "Favorite", comment: "Favorite action")
    static let unfavorite = NSLocalizedString("picker.unfavorite", value: "Unfavorite", comment: "Unfavorite action")
    static let remove = NSLocalizedString("picker.remove", value: "Remove", comment: "Remove action")
    static let manageEvents = NSLocalizedString("picker.manage_events", value: "Manage Events…", comment: "Manage events button")
    static let reorderFavorites = NSLocalizedString("picker.reorder_favorites", value: "Reorder Favorites…", comment: "Reorder favorites button")
    static let noCustomsHint = NSLocalizedString("picker.no_customs_hint", value: "No custom events yet.", comment: "Empty custom events hint")
    static let addFavoritesHint = NSLocalizedString("picker.add_favorites_hint", value: "Add your frequently used events to Favorites for quick access.", comment: "Favorites empty hint")
    static let selectedHeader = NSLocalizedString("picker.selected", value: "Selected", comment: "Selected section header")
    
    // MARK: - Note System
    static let createNote = NSLocalizedString("note.create", value: "Create Note", comment: "Create note")
    static let addEvent = NSLocalizedString("note.add_event", value: "ADD EVENT", comment: "Add event label")
    static let yourEvent = NSLocalizedString("note.your_event", value: "YOUR EVENT", comment: "Your event label")
    static let newEvent = NSLocalizedString("note.new_event", value: "New Event", comment: "New event title")
    static let eventTitle = NSLocalizedString("note.event_title", value: "Event Title", comment: "Event title placeholder")
    static let eventDetails = NSLocalizedString("note.event_details", value: "Details (optional)", comment: "Event details placeholder")
    static let eventDate = NSLocalizedString("note.event_date", value: "Event Date", comment: "Event date label")
    static let untitled = NSLocalizedString("note.untitled", value: "Untitled", comment: "Untitled event")
    
    // MARK: - Time Indicators
    static let daysShort = NSLocalizedString("time.days_short", value: "d", comment: "Days abbreviation")
    static let todayLabel = NSLocalizedString("time.today", value: "TODAY", comment: "Today label")
    
    // MARK: - Weekdays (Short)
    static func weekdayShort(_ weekday: Int) -> String {
        switch weekday {
        case 1: return NSLocalizedString("weekday.sun", value: "SUN", comment: "Sunday short")
        case 2: return NSLocalizedString("weekday.mon", value: "MON", comment: "Monday short")
        case 3: return NSLocalizedString("weekday.tue", value: "TUE", comment: "Tuesday short")
        case 4: return NSLocalizedString("weekday.wed", value: "WED", comment: "Wednesday short")
        case 5: return NSLocalizedString("weekday.thu", value: "THU", comment: "Thursday short")
        case 6: return NSLocalizedString("weekday.fri", value: "FRI", comment: "Friday short")
        case 7: return NSLocalizedString("weekday.sat", value: "SAT", comment: "Saturday short")
        default: return ""
        }
    }
    
    // MARK: - Navigation
    static let previousWeek = NSLocalizedString("navigation.previous_week", value: "Previous week", comment: "Previous week accessibility")
    static let nextWeek = NSLocalizedString("navigation.next_week", value: "Next week", comment: "Next week accessibility")
    
    // MARK: - Accessibility
    static let selectedDay = NSLocalizedString("accessibility.selected", value: "selected", comment: "Selected day accessibility")
    static let holidayDay = NSLocalizedString("accessibility.holiday", value: "holiday", comment: "Holiday accessibility")
    
    // MARK: - Date Formatting
    static func formatDateRange(_ startDate: Date, _ endDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d"
        
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        
        let separator = NSLocalizedString("date.range_separator", value: " – ", comment: "Date range separator")
        return "\(startString)\(separator)\(endString)"
    }
    
    static func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    static func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // MARK: - Week Display
    static func weekDisplayText(_ weekNumber: Int) -> String {
        return String.localizedStringWithFormat(
            NSLocalizedString("week.display", value: "Week %d", comment: "Week display format"),
            weekNumber
        )
    }
    
    static func daysUntilText(_ days: Int) -> String {
        if days == 0 {
            return NSLocalizedString("countdown.today", value: "TODAY", comment: "Today countdown")
        } else if days == 1 {
            return NSLocalizedString("countdown.tomorrow", value: "TOMORROW", comment: "Tomorrow countdown")
        } else if days < 0 {
            return NSLocalizedString("countdown.passed", value: "PASSED", comment: "Passed countdown")
        } else {
            return String.localizedStringWithFormat(
                NSLocalizedString("countdown.days", value: "%d DAYS", comment: "Days countdown format"),
                days
            )
        }
    }
}

// MARK: - Locale-Aware Date Formatters
extension DateFormatterCache {
    static let localizedMonthName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale.current
        return formatter
    }()
    
    static let localizedWeekdayShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale.current
        return formatter
    }()
    
    static let localizedFullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale.current
        return formatter
    }()
    
    static let localizedWeekRange: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale.current
        return formatter
    }()
}

// MARK: - Localized WeekInfo
extension WeekInfo {
    init(for date: Date = Date(), localized: Bool = true) {
        let calendar = Calendar.iso8601
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2 // Monday
        let startDate = calendar.date(from: components) ?? date
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? date
        
        let dateRange: String
        if localized {
            dateRange = Localization.formatDateRange(startDate, endDate)
        } else {
            let formatter = DateFormatterCache.weekRange
            let startString = formatter.string(from: startDate)
            let endString = formatter.string(from: endDate)
            dateRange = "\(startString) – \(endString)"
        }
        
        self.weekNumber = week
        self.year = year
        self.dateRange = dateRange
        self.startDate = startDate
        self.endDate = endDate
    }
}
