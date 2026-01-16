//
//  Localization.swift
//  Vecka
//
//  Comprehensive localization system supporting Swedish, English, Japanese, Korean, German, Vietnamese, and Thai
//

import Foundation
import SwiftUI

// MARK: - Language Detection Manager
/// Simple singleton for language detection. No observation needed as we rely on iOS system settings.
final class LanguageManager {
    static let shared = LanguageManager()

    private init() {}

    var currentLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }
}

// MARK: - Localization Manager
struct Localization {
    
    // MARK: - Core App Strings
    static let appName = NSLocalizedString("app.name", value: "ONSEN PLANNER", comment: "App name")
    static let today = NSLocalizedString("common.today", value: "Today", comment: "Today")
    static let goToToday = NSLocalizedString("action.go_to_today", value: "GO TO TODAY", comment: "Go to today action")
    static let cancel = NSLocalizedString("common.cancel", value: "Cancel", comment: "Cancel")
    static let save = NSLocalizedString("common.save", value: "Save", comment: "Save")
    static let delete = NSLocalizedString("common.delete", value: "Delete", comment: "Delete")
    static let settings = NSLocalizedString("common.settings", value: "Settings", comment: "Settings")
    static let done = NSLocalizedString("common.done", value: "Done", comment: "Done")
    static let none = NSLocalizedString("common.none", value: "None", comment: "None")

    // MARK: - Navigation Tabs
    static let calendar = NSLocalizedString("navigation.calendar", value: "Calendar", comment: "Calendar tab")
    static let library = NSLocalizedString("navigation.library", value: "Library", comment: "Library tab")
    static let notes = NSLocalizedString("navigation.notes", value: "Notes", comment: "Notes section")
    static let holidays = NSLocalizedString("navigation.holidays", value: "Holidays", comment: "Holidays section")
    static let observances = NSLocalizedString("navigation.observances", value: "Observances", comment: "Observances section")
    static let contacts = NSLocalizedString("navigation.contacts", value: "Contacts", comment: "Contacts section")
    static let expenses = NSLocalizedString("navigation.expenses", value: "Expenses", comment: "Expenses section")
    static let trips = NSLocalizedString("navigation.trips", value: "Trips", comment: "Trips section")
    static let selectItem = NSLocalizedString("navigation.select_item", value: "Select an item", comment: "Select item placeholder")
    static let menu = NSLocalizedString("navigation.menu", value: "Menu", comment: "Menu accessibility label")
    static let holidaysSection = NSLocalizedString("navigation.holidays_section", value: "Holidays & Events", comment: "Holidays section header")
    static let features = NSLocalizedString("navigation.features", value: "Features", comment: "Features section header")

    // MARK: - Export
    static let export = NSLocalizedString("export.title", value: "Export", comment: "Export menu")
    static let exportDay = NSLocalizedString("export.day", value: "Export Day", comment: "Export day option")
    static let exportWeek = NSLocalizedString("export.week", value: "Export Week", comment: "Export week option")
    static let exportMonth = NSLocalizedString("export.month", value: "Export Month", comment: "Export month option")

    // MARK: - Holidays
    static let holidaysThisWeek = NSLocalizedString("holidays.this_week", value: "Holidays This Week", comment: "Holidays this week header")
    static let selectDay = NSLocalizedString("calendar.select_day", value: "Select a Day", comment: "Select a day prompt")
    static let selectWeek = NSLocalizedString("calendar.select_week", value: "Select a Week", comment: "Select a week prompt")
    static let lunar = NSLocalizedString("calendar.lunar", value: "Lunar", comment: "Lunar calendar label")
    static let tapToAddNote = NSLocalizedString("note.tap_to_add", value: "Tap to add note...", comment: "Tap to add note placeholder")

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
    static let notesForDay = NSLocalizedString("note.notes_for_day", value: "Notes", comment: "Notes for day header")
    static let notesPlaceholder = NSLocalizedString("note.notes_placeholder", value: "Write your notes here...", comment: "Notes placeholder text")
    
    // MARK: - Time Indicators
    static let daysShort = NSLocalizedString("time.days_short", value: "d", comment: "Days abbreviation")
    static let todayLabel = NSLocalizedString("time.today", value: "TODAY", comment: "Today label")
    static let daySingular = NSLocalizedString("time.day_singular", value: "DAY", comment: "Day singular")
    static let dayPlural = NSLocalizedString("time.day_plural", value: "DAYS", comment: "Days plural")

    // MARK: - Countdown
    static let selectCountdown = NSLocalizedString("countdown.select", value: "Select Countdown", comment: "Select countdown picker label")
    static let countdownAgo = NSLocalizedString("countdown.ago", value: "AGO", comment: "Countdown in the past")
    static let countdownLeft = NSLocalizedString("countdown.left", value: "LEFT", comment: "Countdown in the future")
    
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
    static let weekColumnHeader = NSLocalizedString("accessibility.week_column", value: "Week number", comment: "Week column header accessibility")
    static let tapToChangeMonth = NSLocalizedString("accessibility.tap_to_change_month", value: "Double tap to change month and year", comment: "Month picker accessibility hint")
    static let calendarAccessNeeded = NSLocalizedString("accessibility.calendar_access_needed", value: "Calendar access needed", comment: "Widget calendar permission notice")

    // MARK: - Settings
    static let calendarHeader = NSLocalizedString("settings.calendar", value: "Calendar", comment: "Calendar section header")
    static let holidaysHint = NSLocalizedString("settings.holidays_hint", value: "Holidays are calculated based on the selected region(s).", comment: "Holiday settings hint")
    static let countdownsHeader = NSLocalizedString("settings.countdowns", value: "Countdowns", comment: "Countdowns section header")
    static let countdownsHint = NSLocalizedString("settings.countdowns_hint", value: "Create and manage up to 10 custom countdowns for special events.", comment: "Countdowns hint")
    static let storageHeader = NSLocalizedString("settings.storage", value: "Storage", comment: "Storage section header")
    static let storageHint = NSLocalizedString("settings.storage_hint", value: "Each note uses 1 Memory Block. Maximum capacity is 1000 blocks.", comment: "Storage hint")
    static let aboutHeader = NSLocalizedString("settings.about", value: "About", comment: "About section header")
    static let appTagline = NSLocalizedString("settings.tagline", value: "Professional Week Number Display", comment: "App tagline")

    // MARK: - Picker Labels
    static let yearLabel = NSLocalizedString("picker.year", value: "Year", comment: "Year picker label")
    static let monthLabel = NSLocalizedString("picker.month", value: "Month", comment: "Month picker label")
    static let weekLabel = NSLocalizedString("picker.week", value: "Week", comment: "Week picker label")
    static let jumpToDate = NSLocalizedString("picker.jump_to_date", value: "Jump to Date", comment: "Jump to date title")
    static let selectEvent = NSLocalizedString("picker.select_event", value: "Select Event", comment: "Select event title")
    static let selectMonthYear = NSLocalizedString("picker.select_month_year", value: "Select Month", comment: "Month picker sheet title")
    static let menuAddItems = NSLocalizedString("menu.add_items", value: "Add", comment: "Add items menu section")
    static let menuActions = NSLocalizedString("menu.actions", value: "Actions", comment: "Actions menu section")
    static let menuNavigation = NSLocalizedString("menu.navigation", value: "Navigation", comment: "Navigation menu section")
    static let goToMonthYear = NSLocalizedString("menu.go_to_month_year", value: "Go to Month...", comment: "Go to month/year action")
    static let thisWeek = NSLocalizedString("calendar.this_week", value: "This week", comment: "This week label")

    // MARK: - Notes
    static let addNote = NSLocalizedString("note.add", value: "Add Note", comment: "Add note button accessibility label")
    static let editNote = NSLocalizedString("note.edit", value: "Edit", comment: "Edit note button")
    static let noteDetails = NSLocalizedString("note.details", value: "Details", comment: "Note details title")
    static let noteSchedule = NSLocalizedString("note.schedule", value: "Schedule", comment: "Note schedule section header")
    static let noteDate = NSLocalizedString("note.date", value: "Date", comment: "Note date label")
    static let noteTime = NSLocalizedString("note.time", value: "Time", comment: "Note time label")
    static let noteAllDay = NSLocalizedString("note.all_day", value: "All-day", comment: "All-day toggle")
    static let noteDashboard = NSLocalizedString("note.dashboard", value: "Dashboard", comment: "Dashboard section header")
    static let notePinnedToDashboard = NSLocalizedString("note.pin_to_dashboard", value: "Pin to Dashboard", comment: "Pin note to dashboard")
    static let notePinnedHint = NSLocalizedString("note.pin_hint", value: "Pinned notes appear under the calendar and show how many days are left.", comment: "Pinned note hint")
    static let pinnedHeader = NSLocalizedString("dashboard.pinned", value: "Pinned", comment: "Pinned notes section header")
    static let noNotesForDay = NSLocalizedString("note.no_notes", value: "No notes for this day", comment: "No notes placeholder")
    static let tapToAddNoteShort = NSLocalizedString("note.tap_to_add_short", value: "Tap to add a note", comment: "Tap to add note hint")
    static let deleteNoteConfirmation = NSLocalizedString("note.delete_confirmation", value: "Are you sure you want to delete this note? This action cannot be undone.", comment: "Delete note confirmation")
    static let noteColor = NSLocalizedString("note.color", value: "Note Color", comment: "Note color")
    static let showAll = NSLocalizedString("common.show_all", value: "Show All", comment: "Show all")
    static let showLess = NSLocalizedString("common.show_less", value: "Show Less", comment: "Show less")
    static let more = NSLocalizedString("common.more", value: "More", comment: "More")
    static let less = NSLocalizedString("common.less", value: "Less", comment: "Less")

    // MARK: - Countdown Management
    static let systemCountdowns = NSLocalizedString("countdown.system", value: "System Countdowns", comment: "System countdowns header")
    static let systemCountdownsHint = NSLocalizedString("countdown.system_hint", value: "System countdowns are automatically updated each year.", comment: "System countdowns hint")
    static let myCountdowns = NSLocalizedString("countdown.my_countdowns", value: "My Countdowns", comment: "My countdowns header")
    static let addCountdownHint = NSLocalizedString("countdown.add_hint", value: "Add your own countdowns like birthdays, vacations, or special events.", comment: "Add countdown hint")
    static let iconLabel = NSLocalizedString("countdown.icon", value: "Icon", comment: "Icon label")
    static let colorLabel = NSLocalizedString("countdown.color", value: "Color", comment: "Color label")
    static let eventDetailsHeader = NSLocalizedString("countdown.event_details", value: "Event Details", comment: "Event details header")

    // MARK: - Memory Card
    static let memoryCard = NSLocalizedString("memory.card", value: "MEMORY CARD", comment: "Memory card label")
    static let blocksFree = NSLocalizedString("memory.blocks_free", value: "BLOCKS FREE", comment: "Blocks free label")

    // MARK: - Activity Chart
    static let noActivity = NSLocalizedString("activity.no_activity", value: "No Activity", comment: "No activity title")
    static let noActivityHint = NSLocalizedString("activity.no_activity_hint", value: "Start writing notes to see your activity here.", comment: "No activity hint")

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

    // MARK: - Library Subtitles
    static let noNotesYet = NSLocalizedString("library.no_notes", value: "No notes yet", comment: "No notes yet subtitle")
    static let noHolidaysConfigured = NSLocalizedString("library.no_holidays", value: "No holidays configured", comment: "No holidays configured subtitle")
    static let noTripsPlanned = NSLocalizedString("library.no_trips", value: "No trips planned", comment: "No trips planned subtitle")
    static let noExpensesRecorded = NSLocalizedString("library.no_expenses", value: "No expenses recorded", comment: "No expenses recorded subtitle")
    static let noContactsSaved = NSLocalizedString("library.no_contacts", value: "No contacts saved", comment: "No contacts saved subtitle")
    static let specialObservances = NSLocalizedString("library.special_observances", value: "Special observances", comment: "Special observances subtitle")
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

    // MARK: - Expenses & Trips
    static let expenses = NSLocalizedString("expenses.title", value: "Expenses", comment: "Expenses title")
    static let trips = NSLocalizedString("trips.title", value: "Trips", comment: "Trips title")
    static let amount = NSLocalizedString("expenses.amount", value: "Amount", comment: "Amount label")
    static let category = NSLocalizedString("expenses.category", value: "Category", comment: "Category label")
    static let details = NSLocalizedString("expenses.details", value: "Details", comment: "Details label")
    static let receipt = NSLocalizedString("expenses.receipt", value: "Receipt", comment: "Receipt label")
    static let exchangeRate = NSLocalizedString("expenses.exchange_rate", value: "Exchange Rate", comment: "Exchange rate label")
    static let convertedAmount = NSLocalizedString("expenses.converted_amount", value: "Converted Amount", comment: "Converted amount label")
    static let currencyConversion = NSLocalizedString("expenses.currency_conversion", value: "Currency Conversion", comment: "Currency conversion header")
    static let notes = NSLocalizedString("expenses.notes", value: "Notes (Optional)", comment: "Notes label")
    static let trip = NSLocalizedString("expenses.trip", value: "Trip", comment: "Trip label")
    static let rateFor = NSLocalizedString("expenses.rate_for", value: "Rate for", comment: "Rate for date prefix")

    // MARK: - Location & Weather
    static let searching = NSLocalizedString("location.searching", value: "Searching...", comment: "Searching indicator")
    static let noLocationsFound = NSLocalizedString("location.no_locations_found", value: "No locations found", comment: "No locations found message")
    static let searchResults = NSLocalizedString("location.search_results", value: "Search Results", comment: "Search results header")
    static let quickAdd = NSLocalizedString("location.quick_add", value: "Quick Add", comment: "Quick add header")
    static let manualEntry = NSLocalizedString("location.manual_entry", value: "Manual Entry", comment: "Manual entry header")
    static let manualEntryHint = NSLocalizedString("location.manual_entry_hint", value: "Enter coordinates in decimal degrees (e.g., 59.3293, 18.0686)", comment: "Manual entry hint")
    static let autoDetect = NSLocalizedString("location.auto_detect", value: "Auto-Detect", comment: "Auto-detect button")
    static let autoDetectHint = NSLocalizedString("location.auto_detect_hint", value: "Use your device's current location", comment: "Auto-detect hint")
    static let savedLocations = NSLocalizedString("location.saved_locations", value: "Saved Locations", comment: "Saved locations header")

    // MARK: - Holidays & Observances
    static let holidays = NSLocalizedString("holidays.title", value: "Holidays", comment: "Holidays title")
    static let turnOnHolidays = NSLocalizedString("holidays.turn_on_hint", value: "Turn on Holidays in the Holidays screen to see observances.", comment: "Turn on holidays hint")
    static let turnOnHolidaysAbove = NSLocalizedString("holidays.turn_on_above", value: "Turn on Holidays above to see holidays.", comment: "Turn on holidays above hint")
    static let addObservances = NSLocalizedString("holidays.add_observances", value: "Add observances like birthdays or milestones.", comment: "Add observances hint")
    static let addCustomHolidays = NSLocalizedString("holidays.add_custom", value: "Add custom holidays with +, or adjust your region.", comment: "Add custom holidays hint")

    // MARK: - PDF Export
    static let exportType = NSLocalizedString("pdf.export_type", value: "Export Type", comment: "Export type header")
    static let dateSelection = NSLocalizedString("pdf.date_selection", value: "Date Selection", comment: "Date selection header")
    static let exportOptions = NSLocalizedString("pdf.export_options", value: "Export Options", comment: "Export options header")
    static let exportIncludes = NSLocalizedString("pdf.export_includes", value: "Export includes selected data for the chosen date range", comment: "Export includes hint")
    static let loadingPreview = NSLocalizedString("pdf.loading_preview", value: "Loading preview...", comment: "Loading preview message")
    static let activityPreview = NSLocalizedString("pdf.activity_preview", value: "Activity Preview", comment: "Activity preview title")
    static let selectOptionsHint = NSLocalizedString("pdf.select_options_hint", value: "Select options to preview report content", comment: "Select options hint")
    static let preview = NSLocalizedString("pdf.preview", value: "Preview", comment: "Preview label")
    static let previewUpdates = NSLocalizedString("pdf.preview_updates", value: "Preview updates as you change options", comment: "Preview updates hint")
    static let previewUnavailable = NSLocalizedString("pdf.preview_unavailable", value: "Preview unavailable", comment: "Preview unavailable")

    // MARK: - Common UI
    static let week = NSLocalizedString("common.week", value: "Week", comment: "Week label")
    static let edit = NSLocalizedString("common.edit", value: "Edit", comment: "Edit button")
    static let total = NSLocalizedString("common.total", value: "Total", comment: "Total label")
    static let duration = NSLocalizedString("common.duration", value: "Duration", comment: "Duration label")
    // Note: 'category' is defined in Expenses section
    static let noEvents = NSLocalizedString("common.no_events", value: "No events", comment: "No events placeholder")
    static let seeAll = NSLocalizedString("common.see_all", value: "See All", comment: "See all button")
    static let tryAgain = NSLocalizedString("common.try_again", value: "Try Again", comment: "Try again button")
    static let retry = NSLocalizedString("common.retry", value: "Retry", comment: "Retry button")

    // MARK: - Contacts
    static let noContacts = NSLocalizedString("contacts.no_contacts", value: "No Contacts", comment: "No contacts title")
    static let importContacts = NSLocalizedString("contacts.import", value: "Import from your address book or add contacts manually", comment: "Import contacts hint")
    static let importFromAddressBook = NSLocalizedString("contacts.import_from_address_book", value: "Import from Address Book", comment: "Import from address book button")
    static let importOptions = NSLocalizedString("contacts.import_options", value: "Import Options", comment: "Import options header")
    static let newContact = NSLocalizedString("contacts.new_contact", value: "New Contact", comment: "New contact button")
    static let importAllContacts = NSLocalizedString("contacts.import_all", value: "Import All Contacts", comment: "Import all contacts button")
    static let selectContactsToImport = NSLocalizedString("contacts.select_to_import", value: "Select Contacts to Import", comment: "Select contacts to import button")
    static let grantContactsPermission = NSLocalizedString("contacts.grant_permission", value: "Grant Contacts Permission", comment: "Grant permission button")

    // MARK: - QR Code
    static let scanQRCode = NSLocalizedString("qr.scan_hint", value: "Scan this QR code to save contact", comment: "QR code scan hint")
    static let pointCameraAtQR = NSLocalizedString("qr.point_camera", value: "Point camera at QR code", comment: "Point camera hint")
    static let shareQRCode = NSLocalizedString("qr.share", value: "Share QR Code", comment: "Share QR code button")
    static let shareAsQRCode = NSLocalizedString("qr.share_as_qr", value: "Share as QR Code", comment: "Share as QR code button")
    static let shareAsVCard = NSLocalizedString("qr.share_as_vcard", value: "Share as vCard", comment: "Share as vCard button")
    static let exportToContacts = NSLocalizedString("contacts.export_to_ios", value: "Export to iOS Contacts", comment: "Export to iOS contacts button")

    // MARK: - Trips
    static let activeTrips = NSLocalizedString("trips.active", value: "Active Trips", comment: "Active trips section")
    static let upcomingTrips = NSLocalizedString("trips.upcoming", value: "Upcoming Trips", comment: "Upcoming trips section")
    static let addTrip = NSLocalizedString("trips.add", value: "Add Trip", comment: "Add trip button")
    static let generateReport = NSLocalizedString("trips.generate_report", value: "Generate Report", comment: "Generate report button")
    static let mileage = NSLocalizedString("trips.mileage", value: "Mileage", comment: "Mileage label")
    static let refresh = NSLocalizedString("common.refresh", value: "Refresh", comment: "Refresh button")
    static let currentLocation = NSLocalizedString("location.current", value: "Current Location", comment: "Current location button")
    static let addLocation = NSLocalizedString("location.add", value: "Add Location", comment: "Add location button")

    // MARK: - Expenses
    static let addExpense = NSLocalizedString("expenses.add", value: "Add Expense", comment: "Add expense button")
    static let filterOptions = NSLocalizedString("expenses.filter_options", value: "Filter Options", comment: "Filter options button")
    static let options = NSLocalizedString("common.options", value: "Options", comment: "Options button")
    static let allCategories = NSLocalizedString("expenses.all_categories", value: "All Categories", comment: "All categories filter")
    static let allTrips = NSLocalizedString("expenses.all_trips", value: "All Trips", comment: "All trips filter")
    static let useTemplate = NSLocalizedString("expenses.use_template", value: "Use Template", comment: "Use template button")
    static let removeReceipt = NSLocalizedString("expenses.remove_receipt", value: "Remove Receipt", comment: "Remove receipt button")
    static let addReceiptPhoto = NSLocalizedString("expenses.add_receipt_photo", value: "Add Receipt Photo", comment: "Add receipt photo button")
    static let recentExpenses = NSLocalizedString("expenses.recent", value: "Recent Expenses", comment: "Recent expenses section")

    // MARK: - Location Search
    static let enterCoordinatesManually = NSLocalizedString("location.enter_coordinates", value: "Enter Coordinates Manually", comment: "Enter coordinates button")
    static let saveLocation = NSLocalizedString("location.save", value: "Save Location", comment: "Save location button")

    // MARK: - Notes List
    static let searchNotes = NSLocalizedString("notes.search", value: "Search Notes", comment: "Search notes placeholder")
    static let unpin = NSLocalizedString("notes.unpin", value: "Unpin", comment: "Unpin note button")

    // MARK: - Overview Dashboard
    static let upcomingEvents = NSLocalizedString("dashboard.upcoming_events", value: "Upcoming Events", comment: "Upcoming events section")
    static let noRecentActivity = NSLocalizedString("dashboard.no_activity", value: "No Recent Activity", comment: "No recent activity message")

    // MARK: - Sidebar
    static let detailView = NSLocalizedString("navigation.detail_view", value: "Detail View", comment: "Detail view placeholder")

}


// MARK: - Localized WeekInfo
// WeekInfo initialization is now handled by WeekCalculator.shared.weekInfo(for:)
// The production implementation in Core/WeekCalculator.swift provides complete functionality
