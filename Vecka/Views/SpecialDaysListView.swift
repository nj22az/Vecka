//
//  SpecialDaysListView.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Japanese Information Design
//  Multi-color visual hierarchy that guides the eye
//
//  Design principles:
//  - Multiple accent colors encode meaning
//  - Compact flipcards instead of long rows
//  - Year picker in header (not separate section)
//  - Color-coded by holiday TYPE not just "holiday zone"
//

import SwiftUI
import SwiftData

// MARK: - Special Day Type

enum SpecialDayType: String, CaseIterable {
    case holiday    // Red days (isRedDay = true)
    case observance // Non-red days (isRedDay = false)
    case event      // Personal events (countdowns, etc.)
    case birthday   // Birthdays from contacts
    case note       // Daily notes
    case trip       // Travel trips
    case expense    // Expenses

    var title: String {
        switch self {
        case .holiday: return NSLocalizedString("library.bank_holidays", value: "Bank Holidays", comment: "Bank Holidays")
        case .observance: return NSLocalizedString("library.observances", value: "Observances", comment: "Observances")
        case .event: return NSLocalizedString("library.events", value: "Events", comment: "Events")
        case .birthday: return NSLocalizedString("library.birthdays", value: "Birthdays", comment: "Birthdays")
        case .note: return NSLocalizedString("library.notes", value: "Notes", comment: "Notes")
        case .trip: return NSLocalizedString("library.trips", value: "Trips", comment: "Trips")
        case .expense: return NSLocalizedString("library.expenses", value: "Expenses", comment: "Expenses")
        }
    }

    var prioritySymbol: String {
        switch self {
        case .holiday: return "●"    // Filled circle
        case .observance: return "○" // Outlined circle
        case .event: return "◆"      // Diamond
        case .birthday: return "🎂"  // Cake emoji
        case .note: return "□"       // Square for notes
        case .trip: return "✈"       // Airplane
        case .expense: return "$"    // Dollar sign
        }
    }

    var defaultIcon: String {
        switch self {
        case .holiday: return "star.fill"
        case .observance: return "sparkles"
        case .event: return "calendar.badge.clock"
        case .birthday: return "birthday.cake.fill"
        case .note: return "note.text"
        case .trip: return "airplane"
        case .expense: return "dollarsign.circle.fill"
        }
    }

    /// 情報デザイン: Different accent colors for visual interest
    var accentColor: Color {
        switch self {
        case .holiday: return Color(hex: "E53E3E")    // Red - "day off!"
        case .observance: return Color(hex: "ED8936") // Orange - celebration
        case .event: return Color(hex: "805AD5")      // Purple - personal
        case .birthday: return Color(hex: "D53F8C")   // Pink - birthdays
        case .note: return Color(hex: "ECC94B")       // Yellow - notes
        case .trip: return Color(hex: "3182CE")       // Blue - travel
        case .expense: return Color(hex: "38A169")    // Green - money
        }
    }

    /// 情報デザイン: Light background tints for icon zones (matches MonthTheme pattern)
    var lightBackground: Color {
        switch self {
        case .holiday: return Color(hex: "FDE8E8")    // Light red
        case .observance: return Color(hex: "FEEBC8") // Light orange
        case .event: return Color(hex: "E9D8FD")      // Light purple
        case .birthday: return Color(hex: "FED7E2")   // Light pink
        case .note: return Color(hex: "FEFCBF")       // Light yellow
        case .trip: return Color(hex: "BEE3F8")       // Light blue
        case .expense: return Color(hex: "C6F6D5")    // Light green
        }
    }

    var isRedDay: Bool {
        self == .holiday
    }

    /// 情報デザイン: 3-letter type codes (database-driven)
    var code: String {
        switch self {
        case .holiday: return "HOL"
        case .observance: return "OBS"
        case .event: return "EVT"
        case .birthday: return "BDY"
        case .note: return "NTE"
        case .trip: return "TRP"
        case .expense: return "EXP"
        }
    }
}

// MARK: - Birthday Display Text (情報デザイン: Intelligent messaging for age 0)

/// Returns display text for birthday row metadata - handles age 0 as "born" message
private func birthdayDisplayText(age: Int, date: Date) -> String {
    let isPast = Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    let isToday = Calendar.current.isDateInToday(date)

    if age == 0 {
        return isToday ? "BORN TODAY" : (isPast ? "WAS BORN" : "WILL BE BORN")
    } else {
        let tense = isToday ? "TURNS" : (isPast ? "TURNED" : "TURNS")
        return "\(tense) \(age)"
    }
}

/// Returns expanded display text for birthday card - includes time context
private func birthdayExpandedDisplayText(age: Int, date: Date, daysUntil: Int) -> String {
    let isPast = Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    let isToday = Calendar.current.isDateInToday(date)
    let timeText = isToday ? "TODAY" : (isPast ? "\(abs(daysUntil))D AGO" : "IN \(daysUntil)D")

    if age == 0 {
        return isToday ? "BORN ON THIS DAY" : (isPast ? "WAS BORN · \(timeText)" : "WILL BE BORN · \(timeText)")
    } else {
        let tense = isToday ? "TURNS" : (isPast ? "TURNED" : "TURNS")
        return "\(tense) \(age) · \(timeText)"
    }
}

// MARK: - Month Theme (情報デザイン: Seasonal colors & icons)

struct MonthTheme {
    let month: Int
    let name: String
    let icon: String           // SF Symbol
    let accentColor: Color     // Month's signature color
    let lightBackground: Color // Lighter tint for card background

    /// 情報デザイン month themes - Japanese packaging style with seasonal associations
    static let themes: [MonthTheme] = [
        MonthTheme(month: 1, name: "January", icon: "snowflake",
                   accentColor: Color(hex: "4A90D9"), lightBackground: Color(hex: "E8F4FD")),
        MonthTheme(month: 2, name: "February", icon: "heart.fill",
                   accentColor: Color(hex: "E84393"), lightBackground: Color(hex: "FDE8F3")),
        MonthTheme(month: 3, name: "March", icon: "leaf.fill",
                   accentColor: Color(hex: "00B894"), lightBackground: Color(hex: "E8FDF6")),
        MonthTheme(month: 4, name: "April", icon: "cloud.rain.fill",
                   accentColor: Color(hex: "74B9FF"), lightBackground: Color(hex: "EBF5FF")),
        MonthTheme(month: 5, name: "May", icon: "camera.macro",
                   accentColor: Color(hex: "FDCB6E"), lightBackground: Color(hex: "FFF9E8")),
        MonthTheme(month: 6, name: "June", icon: "sun.max.fill",
                   accentColor: Color(hex: "F39C12"), lightBackground: Color(hex: "FEF3E2")),
        MonthTheme(month: 7, name: "July", icon: "beach.umbrella.fill",
                   accentColor: Color(hex: "00CEC9"), lightBackground: Color(hex: "E8FFFE")),
        MonthTheme(month: 8, name: "August", icon: "flame.fill",
                   accentColor: Color(hex: "E17055"), lightBackground: Color(hex: "FDECE8")),
        MonthTheme(month: 9, name: "September", icon: "leaf.arrow.triangle.circlepath",
                   accentColor: Color(hex: "D35400"), lightBackground: Color(hex: "FDEEE5")),
        MonthTheme(month: 10, name: "October", icon: "moon.fill",
                   accentColor: Color(hex: "6C5CE7"), lightBackground: Color(hex: "EFECFD")),
        MonthTheme(month: 11, name: "November", icon: "wind",
                   accentColor: Color(hex: "636E72"), lightBackground: Color(hex: "F0F2F3")),
        MonthTheme(month: 12, name: "December", icon: "gift.fill",
                   accentColor: Color(hex: "C0392B"), lightBackground: Color(hex: "F9E7E5"))
    ]

    static func theme(for month: Int) -> MonthTheme {
        themes.first(where: { $0.month == month }) ?? themes[0]
    }
}

// MARK: - Holiday Category (for color coding)

enum HolidayCategory {
    case redDay      // Bank holidays - RED
    case religious   // Easter, Christmas etc - PURPLE
    case cultural    // Midsummer, etc - ORANGE
    case personal    // Birthdays, anniversaries - BLUE
    case seasonal    // First day of spring - GREEN

    var pillColor: Color {
        switch self {
        case .redDay: return Color(hex: "E53E3E")      // Red
        case .religious: return Color(hex: "805AD5")   // Purple
        case .cultural: return Color(hex: "ED8936")    // Orange
        case .personal: return Color(hex: "3182CE")    // Blue
        case .seasonal: return Color(hex: "38A169")    // Green
        }
    }

    var textColor: Color {
        switch self {
        case .redDay, .religious, .personal: return JohoColors.white
        case .cultural, .seasonal: return JohoColors.black
        }
    }
}

// NOTE: CountryColorScheme and CountryPill are now in JohoDesignSystem.swift

// MARK: - Day Card Grouping (情報デザイン: Same-day holidays combine)

/// A day card groups all special days that fall on the same date
struct DayCardData: Identifiable {
    let id: String
    let date: Date
    let day: Int
    let items: [SpecialDayRow]

    /// Card size based on content (情報デザイン: expand to fit data)
    var cardSize: DayCardSize {
        if items.count >= 2 {
            return .expanded  // 2 columns wide for multiple items
        }
        return .standard     // 1 column for single item
    }

    /// Primary item (first holiday/observance, or first item)
    var primaryItem: SpecialDayRow? { items.first }

    /// All unique regions in this card
    var regions: [String] {
        Array(Set(items.compactMap { $0.region.isEmpty ? nil : $0.region }))
    }
}

enum DayCardSize {
    case standard   // 1x1 grid cell
    case expanded   // 2x1 grid cells (spans 2 columns)
}

// MARK: - Data Structures

struct SpecialDayRow: Identifiable {
    let id: String
    let ruleID: String        // HolidayRule ID or CountdownEvent ID
    let region: String
    let date: Date
    let title: String
    let type: SpecialDayType
    let symbolName: String?
    let iconColor: String?
    let notes: String?
    let isCustom: Bool
    let isCountdown: Bool     // True if this is a countdown event
    let originalBirthday: Date?  // For birthdays: the original birth date (to calculate age)
    let turningAge: Int?         // For birthdays: the age they're turning

    /// Determine category based on holiday characteristics
    var category: HolidayCategory {
        if type == .holiday {
            return .redDay
        }
        if type == .event || type == .birthday {
            return .personal
        }
        // Could be enhanced with more logic based on holiday name/type
        return .cultural
    }

    /// Days until this event (for countdowns)
    var daysUntil: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    /// Whether this row has a supported country color scheme
    var hasCountryPill: Bool {
        CountryColorScheme.scheme(for: region) != nil
    }

    /// Whether this is a system holiday (vs user-created)
    var isSystem: Bool {
        !isCustom
    }
}

/// Consolidated holiday: Groups same-date holidays from multiple regions into one row
/// 情報デザイン: Same semantic holiday (same date + type) = ONE row with multiple country pills
///
/// Example: January 1st holidays consolidate regardless of localized names:
/// - Sweden: "Nyårsdagen" + USA: "New Year's Day" + Vietnam: "Tết Dương lịch"
/// → ONE row showing device-locale name with [SWE][❄️] [USA][🎆] [VN][🎊]
struct ConsolidatedHoliday: Identifiable {
    let id: String                      // "holiday-1704067200" (date timestamp)
    let date: Date
    let type: SpecialDayType            // .holiday
    let regions: [String]               // ["SE", "US", "VN"]
    let names: [String: String]         // ["SE": "Nyårsdagen", "US": "New Year's Day", "VN": "Tết Dương lịch"]
    let icons: [String: String]         // ["SE": "snowflake", "US": "fireworks", "VN": "sparkles"]
    let isSystemHoliday: Bool           // All source rows are system holidays

    /// Get the best display name for the current locale
    /// 情報デザイン: Show the user's locale name, fallback to English, then first available
    func displayName(for locale: Locale) -> String {
        // 1. Try device locale region (e.g., "SE" for Swedish)
        if let regionCode = locale.region?.identifier,
           let localeName = names[regionCode] {
            return localeName
        }

        // 2. Try English name (US)
        if let englishName = names["US"] {
            return englishName
        }

        // 3. Fallback to first available name
        return names.values.first ?? "Holiday"
    }

    /// Create from a group of same-DATE holidays (not same-name)
    /// 情報デザイン: Semantic grouping - same date + same type = same holiday
    static func from(holidays: [SpecialDayRow]) -> ConsolidatedHoliday? {
        guard let first = holidays.first else { return nil }

        return ConsolidatedHoliday(
            id: "holiday-\(first.date.timeIntervalSince1970)",
            date: first.date,
            type: .holiday,
            regions: holidays.map { $0.region },
            names: Dictionary(uniqueKeysWithValues: holidays.map { ($0.region, $0.title) }),
            icons: Dictionary(uniqueKeysWithValues: holidays.compactMap { holiday in
                let icon = holiday.symbolName ?? SpecialDayType.holiday.defaultIcon
                return (holiday.region, icon)
            }),
            isSystemHoliday: holidays.allSatisfy { $0.isSystem }
        )
    }
}

fileprivate struct EditingSpecialDay: Identifiable {
    let id: String
    let ruleID: String
    let name: String
    let date: Date
    let type: SpecialDayType
    let symbolName: String?
    let iconColor: String?
    let notes: String?
    let region: String
}

fileprivate struct DeletedSpecialDay {
    let ruleID: String
    let name: String
    let date: Date
    let type: SpecialDayType
    let symbol: String
    let iconColor: String?
    let notes: String?
    let region: String
}

// MARK: - Special Days List View (情報デザイン Redesign)

struct SpecialDaysListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    private var holidayManager = HolidayManager.shared

    // Query countdown events (now called "events")
    @Query private var countdownEvents: [CountdownEvent]

    // Query contacts for birthdays
    @Query private var contacts: [Contact]

    // Query daily notes
    @Query private var dailyNotes: [DailyNote]

    // Query trips and expenses
    @Query private var trips: [TravelTrip]
    @Query private var expenses: [ExpenseItem]

    @AppStorage("showHolidays") private var showHolidays = true
    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])

    // View mode - exposed via binding for sidebar integration
    @Binding var isInMonthDetail: Bool
    @State private var selectedMonth: Int? = nil  // nil = show grid, Int = show month detail

    // Custom init to allow the binding
    init(isInMonthDetail: Binding<Bool>) {
        self._isInMonthDetail = isInMonthDetail
    }

    // Year selection
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    // Editor state
    @State private var isPresentingNewSpecialDay = false
    @State private var newSpecialDayType: SpecialDayType = .holiday
    @State private var editingSpecialDay: EditingSpecialDay?

    // Undo functionality
    @State private var deletedSpecialDay: DeletedSpecialDay?
    @State private var showUndoToast = false

    // Type-specific editors
    @State private var editingEvent: CountdownEvent?
    @State private var editingContact: Contact?  // For BDY (birthday)
    @State private var editingNote: DailyNote?
    @State private var editingTrip: TravelTrip?
    @State private var editingExpense: ExpenseItem?

    // Item expansion state (情報デザイン: tap to show details)
    @State private var expandedItemID: String?

    private var years: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 20)...(current + 20))
    }

    // MARK: - Computed Data

    private func rows(for type: SpecialDayType) -> [SpecialDayRow] {
        let calendar = Calendar.current

        // Handle event type (formerly countdown)
        if type == .event {
            return countdownEvents
                .filter { calendar.component(.year, from: $0.targetDate) == selectedYear }
                .map { event in
                    SpecialDayRow(
                        id: "event-\(event.id)",
                        ruleID: event.id,
                        region: "",
                        date: event.targetDate,
                        title: event.title,
                        type: .event,
                        symbolName: event.icon,
                        iconColor: event.colorHex.replacingOccurrences(of: "#", with: ""),
                        notes: nil,
                        isCustom: !event.isSystem,
                        isCountdown: true,
                        originalBirthday: nil,
                        turningAge: nil
                    )
                }
                .sorted { $0.date < $1.date }
        }

        // Handle birthday type from contacts
        if type == .birthday {
            return contacts
                .compactMap { contact -> SpecialDayRow? in
                    guard let birthday = contact.birthday else { return nil }

                    // Get birthday components
                    let birthYear = calendar.component(.year, from: birthday)
                    let month = calendar.component(.month, from: birthday)
                    let day = calendar.component(.day, from: birthday)

                    // Calculate birthday for the selected year
                    // When viewing a specific year, ALWAYS show that year's birthday
                    guard let birthdayForSelectedYear = calendar.date(from: DateComponents(
                        year: selectedYear,
                        month: month,
                        day: day
                    )) else { return nil }

                    // Age they turned/will turn in the selected year
                    let ageAtBirthday = selectedYear - birthYear

                    return SpecialDayRow(
                        id: "birthday-\(contact.id.uuidString)",
                        ruleID: contact.id.uuidString,
                        region: "",
                        date: birthdayForSelectedYear,
                        title: contact.displayName,
                        type: .birthday,
                        symbolName: "birthday.cake.fill",
                        iconColor: "D53F8C",  // Pink
                        notes: nil,
                        isCustom: false,
                        isCountdown: true,
                        originalBirthday: birthday,
                        turningAge: ageAtBirthday
                    )
                }
                .sorted { $0.date < $1.date }
        }

        // Handle notes type
        if type == .note {
            return dailyNotes
                .filter { calendar.component(.year, from: $0.date) == selectedYear }
                .map { note in
                    // Get first line of content as title
                    let firstLine = note.content.components(separatedBy: .newlines).first ?? note.content
                    let title = firstLine.isEmpty ? "Note" : String(firstLine.prefix(50))

                    // Create unique ID from date + content hash
                    let noteId = "note-\(note.date.timeIntervalSinceReferenceDate)-\(note.content.hashValue)"

                    return SpecialDayRow(
                        id: noteId,
                        ruleID: noteId,
                        region: "",
                        date: note.date,
                        title: title,
                        type: .note,
                        symbolName: note.symbolName ?? "note.text",
                        iconColor: note.color ?? "ECC94B",
                        notes: note.content,
                        isCustom: true,
                        isCountdown: false,
                        originalBirthday: nil,
                        turningAge: nil
                    )
                }
                .sorted { $0.date < $1.date }
        }

        // Handle trip type
        if type == .trip {
            return trips
                .filter { calendar.component(.year, from: $0.startDate) == selectedYear ||
                          calendar.component(.year, from: $0.endDate) == selectedYear }
                .map { trip in
                    SpecialDayRow(
                        id: "trip-\(trip.id.uuidString)",
                        ruleID: trip.id.uuidString,
                        region: "",
                        date: trip.startDate,
                        title: trip.tripName,
                        type: .trip,
                        symbolName: "airplane",
                        iconColor: "3182CE",  // Blue
                        notes: trip.destination,
                        isCustom: true,
                        isCountdown: false,
                        originalBirthday: nil,
                        turningAge: nil
                    )
                }
                .sorted { $0.date < $1.date }
        }

        // Handle expense type
        if type == .expense {
            return expenses
                .filter { calendar.component(.year, from: $0.date) == selectedYear }
                .map { expense in
                    let amountText = String(format: "%.2f %@", expense.amount, expense.currency)
                    return SpecialDayRow(
                        id: "expense-\(expense.id.uuidString)",
                        ruleID: expense.id.uuidString,
                        region: "",
                        date: expense.date,
                        title: expense.itemDescription,
                        type: .expense,
                        symbolName: expense.category?.iconName ?? "dollarsign.circle.fill",
                        iconColor: "38A169",  // Green
                        notes: amountText,
                        isCustom: true,
                        isCountdown: false,
                        originalBirthday: nil,
                        turningAge: nil
                    )
                }
                .sorted { $0.date < $1.date }
        }

        // Handle holidays and observances
        let isRedDay = type.isRedDay

        return holidayManager.holidayCache
            .filter { (date, _) in calendar.component(.year, from: date) == selectedYear }
            .sorted(by: { $0.key < $1.key })
            .flatMap { (date, holidays) in
                holidays.filter { $0.isRedDay == isRedDay }.map { holiday in
                    SpecialDayRow(
                        id: "\(date.timeIntervalSinceReferenceDate)-\(holiday.id)",
                        ruleID: holiday.id,
                        region: holiday.region,
                        date: date,
                        title: holiday.displayTitle,
                        type: type,
                        symbolName: holiday.symbolName,
                        iconColor: holiday.iconColor,
                        notes: holiday.notes,
                        isCustom: holiday.isCustom,
                        isCountdown: false,
                        originalBirthday: nil,
                        turningAge: nil
                    )
                }
            }
    }

    private var holidayCount: Int { rows(for: .holiday).count }
    private var observanceCount: Int { rows(for: .observance).count }
    private var eventCount: Int { rows(for: .event).count }
    private var birthdayCount: Int { rows(for: .birthday).count }
    private var noteCount: Int { rows(for: .note).count }
    private var tripCount: Int { rows(for: .trip).count }
    private var expenseCount: Int { rows(for: .expense).count }

    /// 情報デザイン: Compact subtitle that fits iPhone screens
    private var compactSubtitle: String {
        var parts: [String] = []
        if holidayCount > 0 { parts.append("\(holidayCount) holidays") }
        if observanceCount > 0 { parts.append("\(observanceCount) observances") }
        if eventCount > 0 { parts.append("\(eventCount) events") }
        if birthdayCount > 0 { parts.append("\(birthdayCount) birthdays") }

        if parts.isEmpty {
            return "No special days yet"
        }

        // Join with line breaks for better iPhone readability
        return parts.joined(separator: " • ")
    }

    /// Get counts for a specific month
    private func monthCounts(for month: Int) -> (holidays: Int, observances: Int, events: Int, birthdays: Int, notes: Int, trips: Int, expenses: Int) {
        let calendar = Calendar.current
        let allHolidays = rows(for: .holiday).filter { calendar.component(.month, from: $0.date) == month }
        let allObservances = rows(for: .observance).filter { calendar.component(.month, from: $0.date) == month }
        let allEvents = rows(for: .event).filter { calendar.component(.month, from: $0.date) == month }
        let allBirthdays = rows(for: .birthday).filter { calendar.component(.month, from: $0.date) == month }
        let allNotes = rows(for: .note).filter { calendar.component(.month, from: $0.date) == month }
        let allTrips = rows(for: .trip).filter { calendar.component(.month, from: $0.date) == month }
        let allExpenses = rows(for: .expense).filter { calendar.component(.month, from: $0.date) == month }
        return (allHolidays.count, allObservances.count, allEvents.count, allBirthdays.count, allNotes.count, allTrips.count, allExpenses.count)
    }

    /// Get rows for a specific month
    private func rowsForMonth(_ month: Int) -> [SpecialDayRow] {
        let calendar = Calendar.current
        let holidays = rows(for: .holiday).filter { calendar.component(.month, from: $0.date) == month }
        let observances = rows(for: .observance).filter { calendar.component(.month, from: $0.date) == month }
        let events = rows(for: .event).filter { calendar.component(.month, from: $0.date) == month }
        let birthdays = rows(for: .birthday).filter { calendar.component(.month, from: $0.date) == month }
        let notes = rows(for: .note).filter { calendar.component(.month, from: $0.date) == month }
        let tripsForMonth = rows(for: .trip).filter { calendar.component(.month, from: $0.date) == month }
        let expensesForMonth = rows(for: .expense).filter { calendar.component(.month, from: $0.date) == month }
        return (holidays + observances + events + birthdays + notes + tripsForMonth + expensesForMonth).sorted { $0.date < $1.date }
    }

    /// Group rows by date into DayCardData (情報デザイン: same-day holidays combine)
    private func dayCardsForMonth(_ month: Int) -> [DayCardData] {
        let calendar = Calendar.current
        let allRows = rowsForMonth(month)

        // Group by day of month
        var grouped: [Int: [SpecialDayRow]] = [:]
        for row in allRows {
            let day = calendar.component(.day, from: row.date)
            grouped[day, default: []].append(row)
        }

        // Convert to DayCardData sorted by day
        return grouped.keys.sorted().compactMap { day -> DayCardData? in
            guard let items = grouped[day], !items.isEmpty else { return nil }
            let date = items[0].date
            return DayCardData(
                id: "day-\(month)-\(day)",
                date: date,
                day: day,
                items: items
            )
        }
    }

    // MARK: - Body

    var body: some View {
        mainContent
            .sheet(isPresented: $isPresentingNewSpecialDay) { newSpecialDaySheet }
            .sheet(item: $editingSpecialDay) { specialDay in editSpecialDaySheet(specialDay) }
            .sheet(item: $editingContact) { contact in contactEditorSheet(contact) }
            .sheet(item: $editingExpense) { expense in expenseEditorSheet(expense) }
            .sheet(item: $editingNote) { note in noteEditorSheet(note) }
            .sheet(item: $editingTrip) { trip in tripEditorSheet(trip) }
            .sheet(item: $editingEvent) { event in eventEditorSheet(event) }
            .overlay(alignment: .bottom) { undoToastOverlay }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                headerWithYearPicker
                if !showHolidays {
                    disabledState
                } else if let month = selectedMonth {
                    monthDetailView(for: month)
                } else {
                    monthGrid
                }
                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
        }
        .onChange(of: selectedYear) { _, newYear in
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: newYear)
        }
        .onChange(of: holidayRegions) { _, _ in
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
        }
        .onChange(of: showHolidays) { _, _ in
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
        }
        .onChange(of: selectedMonth) { _, newMonth in
            isInMonthDetail = newMonth != nil
        }
    }

    // MARK: - Sheet Views (broken out to reduce body complexity)

    private var newSpecialDaySheet: some View {
        JohoSpecialDayEditorSheet(
            mode: .create,
            type: newSpecialDayType,
            defaultRegion: defaultNewRegion,
            onSave: { name, date, symbol, iconColor, notes, region in
                createSpecialDay(type: newSpecialDayType, name: name, date: date, symbol: symbol, iconColor: iconColor, notes: notes, region: region)
            }
        )
        .presentationCornerRadius(20)
    }

    private func editSpecialDaySheet(_ specialDay: EditingSpecialDay) -> some View {
        JohoSpecialDayEditorSheet(
            mode: .edit(
                name: specialDay.name,
                date: specialDay.date,
                symbol: specialDay.symbolName ?? specialDay.type.defaultIcon,
                iconColor: specialDay.iconColor,
                notes: specialDay.notes,
                region: specialDay.region
            ),
            type: specialDay.type,
            defaultRegion: specialDay.region,
            onSave: { name, date, symbol, iconColor, notes, region in
                updateSpecialDay(ruleID: specialDay.ruleID, type: specialDay.type, name: name, date: date, symbol: symbol, iconColor: iconColor, notes: notes, region: region)
            }
        )
        .presentationCornerRadius(20)
    }

    private func contactEditorSheet(_ contact: Contact) -> some View {
        JohoContactEditorSheet(mode: .birthday, existingContact: contact)
            .presentationCornerRadius(20)
    }

    private func expenseEditorSheet(_ expense: ExpenseItem) -> some View {
        ExpenseEntryView(existingExpense: expense)
            .presentationCornerRadius(20)
    }

    private func noteEditorSheet(_ note: DailyNote) -> some View {
        NavigationStack {
            DailyNotesView(selectedDate: note.day, isModal: true)
        }
        .presentationCornerRadius(20)
    }

    private func tripEditorSheet(_ trip: TravelTrip) -> some View {
        NavigationStack {
            TripDetailView(trip: trip)
        }
        .presentationCornerRadius(20)
    }

    private func eventEditorSheet(_ event: CountdownEvent) -> some View {
        JohoEventEditorSheet(
            event: event,
            onSave: { title, date, icon, colorHex in
                event.title = title
                event.targetDate = date
                event.icon = icon
                event.colorHex = colorHex
                try? modelContext.save()
            }
        )
        .presentationCornerRadius(20)
    }

    @ViewBuilder
    private var undoToastOverlay: some View {
        if showUndoToast {
            JohoUndoToast(
                message: "Deleted \"\(deletedSpecialDay?.name ?? "item")\"",
                onUndo: undoDelete,
                onDismiss: { withAnimation { showUndoToast = false } }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .padding(.bottom, 100)
        }
    }

    // MARK: - Header with Year Picker (情報デザイン: Compact)

    private var headerWithYearPicker: some View {
        let theme: MonthTheme? = selectedMonth.map { MonthTheme.theme(for: $0) }
        let monthRows = selectedMonth.map { rowsForMonth($0) } ?? []

        return VStack(spacing: JohoDimensions.spacingMD) {
            HStack(alignment: .center, spacing: JohoDimensions.spacingMD) {
                // Back button when in month detail
                if selectedMonth != nil {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedMonth = nil
                        }
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(JohoColors.black)
                            .frame(width: 44, height: 44)
                            .background(JohoColors.inputBackground)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                            )
                    }
                }

                // Icon zone - star for main view, month icon for detail
                if let theme = theme {
                    Image(systemName: theme.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(theme.accentColor)
                        .frame(width: 52, height: 52)
                        .background(theme.lightBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                } else {
                    Image(systemName: "star.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 52, height: 52)
                        .background(Color(hex: "FFD700"))  // Gold star
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    if let theme = theme {
                        // Month detail: show "JANUARY 2025" (year is read-only here)
                        Text(verbatim: "\(theme.name.uppercased()) \(String(selectedYear))")
                            .font(JohoFont.displaySmall)
                            .foregroundStyle(JohoColors.black)

                        Text("\(monthRows.count) special days")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.7))
                    } else {
                        Text("Special Days")
                            .font(JohoFont.headline)  // Smaller font to prevent truncation
                            .foregroundStyle(JohoColors.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        // 情報デザイン: Compact subtitle that doesn't truncate on iPhone
                        Text(compactSubtitle)
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.7))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                }
                .layoutPriority(1)  // Prioritize title over year picker

                Spacer(minLength: 8)

                // Year picker (only show when not in month detail for cleaner look)
                if selectedMonth == nil {
                    HStack(spacing: 0) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { selectedYear -= 1 }
                            HapticManager.selection()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(JohoColors.black)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }

                        Menu {
                            ForEach(years, id: \.self) { year in
                                Button {
                                    withAnimation { selectedYear = year }
                                } label: {
                                    HStack {
                                        Text(verbatim: "\(year)")
                                        if year == selectedYear {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text(verbatim: "\(selectedYear)")
                                .font(JohoFont.headline)
                                .monospacedDigit()
                                .foregroundStyle(JohoColors.black)
                                .frame(width: 56)
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { selectedYear += 1 }
                            HapticManager.selection()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(JohoColors.black)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                    }
                    .background(JohoColors.inputBackground)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                    )

                    // 情報デザイン: Add button with entry type menu
                    Menu {
                        Button {
                            newSpecialDayType = .holiday
                            isPresentingNewSpecialDay = true
                        } label: {
                            Label("Holiday", systemImage: "flag.fill")
                        }
                        Button {
                            newSpecialDayType = .observance
                            isPresentingNewSpecialDay = true
                        } label: {
                            Label("Observance", systemImage: "leaf.fill")
                        }
                        Button {
                            newSpecialDayType = .event
                            isPresentingNewSpecialDay = true
                        } label: {
                            Label("Event", systemImage: "calendar.badge.clock")
                        }
                        Button {
                            newSpecialDayType = .birthday
                            isPresentingNewSpecialDay = true
                        } label: {
                            Label("Birthday", systemImage: "birthday.cake.fill")
                        }
                        Button {
                            newSpecialDayType = .note
                            isPresentingNewSpecialDay = true
                        } label: {
                            Label("Note", systemImage: "note.text")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(JohoColors.white)
                            .frame(width: 44, height: 44)
                            .background(JohoColors.black)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                    }
                }
            }
        }
        .padding(JohoDimensions.spacingLG)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.top, JohoDimensions.spacingSM)
    }

    // MARK: - Month Grid (情報デザイン: 12 Month Flipcards in 3-Column Bento)

    private var monthGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: JohoDimensions.spacingSM),
            GridItem(.flexible(), spacing: JohoDimensions.spacingSM),
            GridItem(.flexible(), spacing: JohoDimensions.spacingSM)
        ]

        return VStack(spacing: JohoDimensions.spacingMD) {
            // Month grid (legend shown in header when viewing month details)
            LazyVGrid(columns: columns, spacing: JohoDimensions.spacingSM) {
                ForEach(1...12, id: \.self) { month in
                    monthFlipcard(for: month)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
        }
    }

    // MARK: - Month Flipcard (情報デザイン: Compartmentalized Bento Style)

    @ViewBuilder
    private func monthFlipcard(for month: Int) -> some View {
        let theme = MonthTheme.theme(for: month)
        let counts = monthCounts(for: month)
        let totalCount = counts.holidays + counts.observances + counts.events + counts.birthdays + counts.notes + counts.trips + counts.expenses
        let hasItems = totalCount > 0

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedMonth = month
            }
            HapticManager.selection()
        } label: {
            VStack(spacing: 0) {
                // TOP COMPARTMENT: Icon zone (情報デザイン: distinct visual anchor)
                VStack {
                    Image(systemName: theme.icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(hasItems ? theme.accentColor : JohoColors.black.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(hasItems ? theme.lightBackground : JohoColors.inputBackground)

                // Horizontal divider
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // BOTTOM COMPARTMENT: Data zone
                VStack(spacing: 6) {
                    // Month name (full name, bold)
                    Text(theme.name.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    // Stats row with clear indicators - 情報デザイン: Circles with BLACK borders
                    if hasItems {
                        HStack(spacing: 4) {
                            // Holidays: Red filled circle + count (BLACK border)
                            if counts.holidays > 0 {
                                HStack(spacing: 2) {
                                    Circle()
                                        .fill(JohoColors.red)
                                        .frame(width: 8, height: 8)
                                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                                    Text("\(counts.holidays)")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(JohoColors.black)
                                }
                            }

                            // Observances: Orange filled circle + count (BLACK border)
                            if counts.observances > 0 {
                                HStack(spacing: 2) {
                                    Circle()
                                        .fill(JohoColors.orange)
                                        .frame(width: 8, height: 8)
                                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                                    Text("\(counts.observances)")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(JohoColors.black)
                                }
                            }

                            // Events: Purple circle + count (BLACK border)
                            if counts.events > 0 {
                                HStack(spacing: 2) {
                                    Circle()
                                        .fill(Color(hex: "805AD5"))
                                        .frame(width: 8, height: 8)
                                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                                    Text("\(counts.events)")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(JohoColors.black)
                                }
                            }

                            // Birthdays: Pink circle + count (BLACK border)
                            if counts.birthdays > 0 {
                                HStack(spacing: 2) {
                                    Circle()
                                        .fill(JohoColors.pink)
                                        .frame(width: 8, height: 8)
                                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                                    Text("\(counts.birthdays)")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(JohoColors.black)
                                }
                            }
                        }
                    } else {
                        Text("—")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 110)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(hasItems ? JohoColors.black : JohoColors.black.opacity(0.3), lineWidth: hasItems ? JohoDimensions.borderMedium : JohoDimensions.borderThin)
            )
        }
        .buttonStyle(.plain)
        .opacity(hasItems ? 1.0 : 0.7)
    }

    // MARK: - Month Detail View (情報デザイン: Collapsible Timeline)

    @State private var expandedDays: Set<String> = []

    @ViewBuilder
    private func monthDetailView(for month: Int) -> some View {
        let theme = MonthTheme.theme(for: month)
        let dayCards = dayCardsForMonth(month)

        VStack(spacing: JohoDimensions.spacingMD) {
            if dayCards.isEmpty {
                JohoEmptyState(
                    title: "No Special Days",
                    message: "Tap + to add",
                    icon: theme.icon,
                    zone: .holidays
                )
                .padding(.top, JohoDimensions.spacingXL)
            } else {
                // Collapsible timeline (情報デザイン: clean, expandable day cards)
                VStack(spacing: JohoDimensions.spacingSM) {
                    ForEach(dayCards) { dayCard in
                        CollapsibleSpecialDayCard(
                            dayCard: dayCard,
                            isExpanded: expandedDays.contains(dayCard.id),
                            onToggle: { toggleExpand(dayCard) },
                            isEditable: isEditable,
                            deleteRow: deleteRow,
                            openEditor: openEditor,
                            expandedItemID: $expandedItemID
                        )
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
            }
        }
        .onAppear { initializeExpandedDays(for: dayCards) }
        .onChange(of: selectedMonth) { _, _ in
            expandedDays.removeAll()
            initializeExpandedDays(for: dayCards)
        }
    }

    private func toggleExpand(_ dayCard: DayCardData) {
        if expandedDays.contains(dayCard.id) {
            expandedDays.remove(dayCard.id)
        } else {
            expandedDays.insert(dayCard.id)
        }
    }

    private func initializeExpandedDays(for dayCards: [DayCardData]) {
        let calendar = Calendar.iso8601
        let today = calendar.startOfDay(for: Date())

        for card in dayCards {
            let cardDay = calendar.startOfDay(for: card.date)
            // Auto-expand: today, cards with multiple items, or upcoming events within 7 days
            let daysUntil = calendar.dateComponents([.day], from: today, to: cardDay).day ?? 0
            if cardDay == today || card.items.count > 1 || (daysUntil >= 0 && daysUntil <= 7) {
                expandedDays.insert(card.id)
            }
        }
    }

    // MARK: - Collapsible Special Day Card (情報デザイン: Timeline Ticket)
    //
    // Similar to WeekDetailPanel's CollapsibleDayCard but for special days:
    // ┌─────────────────────────────────────────────────────────────┐
    // │ [THU 1]  January 1, 2026              [TODAY] [chevron]    │ ← Header
    // ├─────────────────────────────────────────────────────────────┤
    // │ ┌─ HOLIDAYS ─────────────────────────────────────────────┐ │
    // │ │ ● New Year's Day                              [SWE]    │ │
    // │ │ ● Tết Dương lịch                               [VN]    │ │
    // │ └────────────────────────────────────────────────────────┘ │
    // │ ┌─ EVENTS ───────────────────────────────────────────────┐ │
    // │ │ ◆ Nyårsdagen                                  00:00    │ │
    // │ └────────────────────────────────────────────────────────┘ │
    // └─────────────────────────────────────────────────────────────┘
}

// MARK: - Collapsible Special Day Card

struct CollapsibleSpecialDayCard: View {
    let dayCard: DayCardData
    let isExpanded: Bool
    let onToggle: () -> Void

    // Closures for data management (passed from parent)
    let isEditable: (SpecialDayRow) -> Bool
    let deleteRow: (SpecialDayRow) -> Void
    let openEditor: (SpecialDayRow) -> Void

    // Item expansion state (情報デザイン: tap row to show details)
    @Binding var expandedItemID: String?

    // Locale for displaying localized holiday names (情報デザイン: show user's locale name)
    @Environment(\.locale) private var locale

    private let calendar = Calendar.iso8601

    // Group items by type
    private var holidays: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .holiday }
    }

    /// Consolidated holidays: Groups same-name holidays into single rows with multiple country pills
    private var consolidatedHolidays: [ConsolidatedHoliday] {
        let holidays = dayCard.items.filter { $0.type == .holiday }
        guard !holidays.isEmpty else { return [] }

        // 情報デザイン: Group by DATE, not by title
        // Same date + same type = same semantic holiday (regardless of localized name)
        // All items in dayCard are already for the same date, so consolidate ALL holidays
        // into one row with multiple country pills
        if let consolidated = ConsolidatedHoliday.from(holidays: holidays) {
            return [consolidated]
        }
        return []
    }
    private var observances: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .observance }
    }
    private var events: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .event }
    }
    private var birthdays: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .birthday }
    }
    private var notes: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .note }
    }
    private var tripsForDay: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .trip }
    }
    private var expensesForDay: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .expense }
    }

    private var isToday: Bool {
        calendar.isDateInToday(dayCard.date)
    }

    /// Days from today (negative = past, positive = future)
    private var daysFromToday: Int {
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: dayCard.date)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    /// Date status pill for the day header (情報デザイン: Shows temporal context)
    @ViewBuilder
    private var dateStatusPill: some View {
        if daysFromToday == 0 {
            // TODAY - Yellow inverted pill
            JohoPill(text: "TODAY", style: .coloredInverted(JohoColors.yellow), size: .small)
        } else if daysFromToday == -1 {
            // YESTERDAY - Muted gray pill
            JohoPill(text: "YESTERDAY", style: .muted, size: .small)
        } else if daysFromToday < -1 {
            // X DAYS AGO - Muted gray pill
            JohoPill(text: "\(abs(daysFromToday)) DAYS AGO", style: .muted, size: .small)
        }
        // Future dates: no status pill shown
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row (always visible)
            headerRow

            // Expanded content
            if isExpanded {
                // Thin divider
                Rectangle()
                    .fill(JohoColors.black.opacity(0.15))
                    .frame(height: 1)

                expandedContent
                    .padding(.top, JohoDimensions.spacingSM)
                    .padding(.bottom, JohoDimensions.spacingMD)
            }
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: isToday ? JohoDimensions.borderThick : JohoDimensions.borderMedium)
        )
    }

    // MARK: - Header Row

    private var headerRow: some View {
        Button(action: onToggle) {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Day badge: [THU 1]
                dayBadge

                // Full date: January 1, 2026
                Text(fullDateText)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)

                Spacer()

                // Status indicators
                HStack(spacing: JohoDimensions.spacingXS) {
                    // Date status pill (情報デザイン: TODAY, YESTERDAY, or X DAYS AGO)
                    dateStatusPill

                    // Content indicator dots (when collapsed)
                    if !isExpanded {
                        contentIndicatorDots
                    }

                    // Expand/collapse chevron
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Day Badge

    private var dayBadge: some View {
        HStack(spacing: 4) {
            Text(weekdayShort)
                .font(JohoFont.labelSmall)
            Text("\(dayCard.day)")
                .font(JohoFont.headline)
        }
        .foregroundStyle(isToday ? JohoColors.black : JohoColors.black)
        .padding(.horizontal, JohoDimensions.spacingSM)
        .padding(.vertical, JohoDimensions.spacingXS)
        .background(isToday ? JohoColors.yellow : JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
        )
    }

    // MARK: - Content Indicator Dots (情報デザイン: Colored circles with BLACK borders)

    private var contentIndicatorDots: some View {
        HStack(spacing: 3) {
            // 情報デザイン: All dots are filled circles with accent color + BLACK border
            if !holidays.isEmpty {
                Circle()
                    .fill(SpecialDayType.holiday.accentColor)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
            if !observances.isEmpty {
                Circle()
                    .fill(SpecialDayType.observance.accentColor)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
            if !events.isEmpty {
                Circle()
                    .fill(SpecialDayType.event.accentColor)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
            if !birthdays.isEmpty {
                Circle()
                    .fill(SpecialDayType.birthday.accentColor)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
            if !notes.isEmpty {
                Circle()
                    .fill(SpecialDayType.note.accentColor)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
            if !tripsForDay.isEmpty {
                Circle()
                    .fill(SpecialDayType.trip.accentColor)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
            if !expensesForDay.isEmpty {
                Circle()
                    .fill(SpecialDayType.expense.accentColor)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }
        }
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            // Holidays section (pink background) - uses consolidated view
            if !consolidatedHolidays.isEmpty {
                consolidatedHolidaySection(
                    title: "Holidays",
                    items: consolidatedHolidays,
                    zone: .holidays,
                    icon: "star.fill"
                )
            }

            // Observances section (orange tint - matches type color)
            if !observances.isEmpty {
                specialDaySection(
                    title: "Observances",
                    items: observances,
                    zone: .observances,
                    icon: "sparkles"
                )
            }

            // Events section (purple tint - matches type color)
            if !events.isEmpty {
                specialDaySection(
                    title: "Events",
                    items: events,
                    zone: .events,
                    icon: "calendar.badge.clock"
                )
            }

            // Birthdays section (pink tint - matches type color)
            if !birthdays.isEmpty {
                specialDaySection(
                    title: "Birthdays",
                    items: birthdays,
                    zone: .birthdays,
                    icon: "birthday.cake.fill"
                )
            }

            // Notes section (yellow tint - matches type color)
            if !notes.isEmpty {
                specialDaySection(
                    title: "Notes",
                    items: notes,
                    zone: .notes,
                    icon: "note.text"
                )
            }

            // Trips section (blue tint - matches type color)
            if !tripsForDay.isEmpty {
                specialDaySection(
                    title: "Trips",
                    items: tripsForDay,
                    zone: .trips,
                    icon: "airplane"
                )
            }

            // Expenses section (green tint - matches type color)
            if !expensesForDay.isEmpty {
                specialDaySection(
                    title: "Expenses",
                    items: expensesForDay,
                    zone: .expenses,
                    icon: "dollarsign.circle.fill"
                )
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
    }

    // MARK: - Section Box (情報デザイン: Bento with compartmentalized header)

    @ViewBuilder
    private func specialDaySection(title: String, items: [SpecialDayRow], zone: SectionZone, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header (情報デザイン: Bento with icon in RIGHT compartment)
            HStack(spacing: 0) {
                // LEFT: Title pill
                JohoPill(text: title.uppercased(), style: .whiteOnBlack, size: .small)
                    .padding(.leading, JohoDimensions.spacingMD)

                Spacer()

                // WALL (vertical divider)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Icon compartment
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 40)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 32)
            .background(zone.background.opacity(0.5))  // Slightly darker header

            // Horizontal divider between header and items
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // Items in VStack for pixel-perfect 情報デザイン layout
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    specialDayItemRow(item, zone: zone)

                    // Divider between items (not after last)
                    if index < items.count - 1 {
                        Rectangle()
                            .fill(JohoColors.black.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, 6)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .background(zone.background)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Consolidated Holiday Section (情報デザイン: Same-name holidays merged)
    //
    // Consolidates same-name holidays from different countries into ONE row
    // ┌─────┬───────────────────────────────────────┬─────────────────────────────┐
    // │ ●   ┃ New Year's Day                        ┃ [SWE][❄️] [USA][🎆]         │
    // └─────┴───────────────────────────────────────┴─────────────────────────────┘
    //  LEFT │           CENTER                      │      RIGHT (multi-country)

    @ViewBuilder
    private func consolidatedHolidaySection(title: String, items: [ConsolidatedHoliday], zone: SectionZone, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header (情報デザイン: Bento with icon in RIGHT compartment)
            HStack(spacing: 0) {
                // LEFT: Title pill
                JohoPill(text: title.uppercased(), style: .whiteOnBlack, size: .small)
                    .padding(.leading, JohoDimensions.spacingMD)

                Spacer()

                // WALL (vertical divider)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Icon compartment
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 40)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 32)
            .background(zone.background.opacity(0.5))  // Slightly darker header

            // Horizontal divider between header and items
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // Items in VStack for pixel-perfect 情報デザイン layout
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    consolidatedHolidayRow(item, zone: zone)

                    // Divider between items (not after last)
                    if index < items.count - 1 {
                        Rectangle()
                            .fill(JohoColors.black.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, 6)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .background(zone.background)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Consolidated Holiday Row (情報デザイン: Multiple countries, one name)
    //
    // Each country keeps its own icon (user decision: Show ALL icons)
    // ┌─────┬───────────────────────────────────────┬─────────────────────────────┐
    // │ ●   ┃ New Year's Day                        ┃ [SWE][❄️] [USA][🎆]         │
    // └─────┴───────────────────────────────────────┴─────────────────────────────┘

    @ViewBuilder
    private func consolidatedHolidayRow(_ item: ConsolidatedHoliday, zone: SectionZone) -> some View {
        HStack(spacing: 0) {
            // LEFT COMPARTMENT: Type indicator (fixed 32pt, centered)
            HStack(alignment: .center, spacing: 3) {
                typeIndicatorDot(for: item.type)
                if item.isSystemHoliday {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
            }
            .frame(width: 32, alignment: .center)
            .frame(maxHeight: .infinity)

            // WALL (vertical divider)
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER COMPARTMENT: Holiday name (flexible)
            // 情報デザイン: Display locale-appropriate name (Swedish user sees "Nyårsdagen", English sees "New Year's Day")
            Text(item.displayName(for: locale))
                .font(JohoFont.bodySmall)
                .foregroundStyle(JohoColors.black)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .frame(maxHeight: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            // WALL (vertical divider)
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // RIGHT COMPARTMENT: Country pills + icons (情報デザイン: Show ALL icons)
            // Each country paired with its decoration icon
            HStack(spacing: 6) {
                ForEach(item.regions, id: \.self) { region in
                    HStack(spacing: 3) {
                        CountryPill(region: region)

                        // Each country keeps its own icon
                        if let icon = item.icons[region] {
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(item.type.accentColor)
                                .frame(width: 20, height: 20)
                                .background(item.type.accentColor.opacity(0.15))
                                .clipShape(Squircle(cornerRadius: 5))
                                .overlay(Squircle(cornerRadius: 5).stroke(JohoColors.black, lineWidth: 1))
                        }
                    }
                }
            }
            .padding(.horizontal, 6)
            .frame(maxHeight: .infinity)
        }
        .frame(minHeight: 36)
        .contentShape(Rectangle())
    }

    // MARK: - Item Row (情報デザイン Bento: Compartmentalized with walls)
    //
    // 情報デザイン BENTO LAYOUT - Compartments with vertical dividers (walls)
    // ┌─────┬─────────────────────────────────┬─────────────────┐
    // │ ●🔒 ┃ New Year's Day                  ┃ [SWE] [HOL]     │
    // └─────┴─────────────────────────────────┴─────────────────┘
    //  LEFT │           CENTER                │      RIGHT
    //  32pt │          flexible               │      84pt
    //
    // Tap → Expand details
    // Swipe LEFT → Delete (red)
    // Swipe RIGHT → Edit (cyan)

    @ViewBuilder
    private func specialDayItemRow(_ item: SpecialDayRow, zone: SectionZone) -> some View {
        let canEdit = isEditable(item)
        let isExpanded = expandedItemID == item.id

        VStack(spacing: 0) {
            // MAIN ROW (情報デザイン Bento with compartment walls)
            HStack(spacing: 0) {
                // LEFT COMPARTMENT: Type indicator + lock (fixed 32pt, centered)
                HStack(alignment: .center, spacing: 3) {
                    typeIndicatorDot(for: item.type)
                    if !canEdit {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                    }
                }
                .frame(width: 32, alignment: .center)
                .frame(maxHeight: .infinity)

                // WALL (vertical divider) - must have maxHeight to expand
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // CENTER COMPARTMENT: Title + metadata (flexible)
                HStack(spacing: JohoDimensions.spacingXS) {
                    Text(item.title)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    // Metadata: age for birthdays (情報デザイン: intelligent messaging)
                    // Note: Countdown removed - temporal status now shown in day header
                    if item.type == .birthday, let age = item.turningAge {
                        // 情報デザイン: Age 0 means birth year - show contextual message
                        Text(birthdayDisplayText(age: age, date: item.date))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                }
                .padding(.horizontal, 8)
                .frame(maxHeight: .infinity)

                // WALL (vertical divider) - must have maxHeight to expand
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT COMPARTMENT: Country pill + Decoration icon (replaces code pill)
                // 情報デザイン: Decoration icon ALWAYS shown (user decision)
                HStack(spacing: 4) {
                    if item.hasCountryPill {
                        CountryPill(region: item.region)
                    }
                    // Decoration icon - always show (custom or default type icon)
                    Image(systemName: item.symbolName ?? item.type.defaultIcon)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(item.type.accentColor)
                        .frame(width: 24, height: 24)
                        .background(item.type.accentColor.opacity(0.15))
                        .clipShape(Squircle(cornerRadius: 6))
                        .overlay(Squircle(cornerRadius: 6).stroke(JohoColors.black, lineWidth: 1))
                }
                .frame(width: 72, alignment: .center)
                .frame(maxHeight: .infinity)
            }
            .frame(minHeight: 36)

            // EXPANDED DETAILS (情報デザイン: tap to reveal)
            if isExpanded {
                // Horizontal divider
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // Details area
                VStack(alignment: .leading, spacing: 6) {
                    // Notes/description if available
                    if let notes = item.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.8))
                            .lineLimit(2)
                    }

                    // Date info
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                        Text(formatDate(item.date))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(JohoColors.black.opacity(0.6))

                        Spacer()

                        // Edit button (for user entries)
                        if canEdit {
                            Button {
                                openEditor(item)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                    Text("EDIT")
                                }
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(JohoColors.cyan)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(JohoColors.black, lineWidth: 1))
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
        // 情報デザイン: NO separate container - rows flow within section
        // The section provides the background, rows just have compartments
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedItemID = isExpanded ? nil : item.id
            }
        }
        // 情報デザイン: Context menu for Edit/Delete (long-press)
        // Clean UI - no swipe clutter, just long-press for actions
        .contextMenu {
            if canEdit {
                Button {
                    openEditor(item)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    deleteRow(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                // System entry - show info only
                Text("System entry (read-only)")
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Type Indicator Dot (情報デザイン: Accent-colored circles with BLACK borders)
    // Circles ALWAYS use their type's accent color - bento boxes use light tints to ensure visibility

    @ViewBuilder
    private func typeIndicatorDot(for type: SpecialDayType) -> some View {
        Circle()
            .fill(type.accentColor)
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
    }

    // MARK: - Formatters

    private var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: dayCard.date).uppercased()
    }

    private var fullDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: dayCard.date)
    }
}

// MARK: - SpecialDaysListView Extension (remaining methods)

extension SpecialDaysListView {

    // MARK: - Special Day Flipcard (情報デザイン: Ticket/Docket Structure)
    //
    // "Information Design" ticket aesthetic:
    // ┌─────────────────────────────────┐
    // │ ❄️ 6    │              JANUARY │  ← Colored header: Icon+Date LEFT, Month RIGHT
    // ├─────────────────────────────────┤  ← Thin black divider
    // │ ● Epiphany                [SWE] │  ← White body with hairline dividers
    // └─────────────────────────────────┘

    @ViewBuilder
    private func specialDayFlipcard(for row: SpecialDayRow) -> some View {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: row.date)
        let monthName = calendar.monthSymbols[calendar.component(.month, from: row.date) - 1].uppercased()

        // Get icon
        let icon = row.symbolName ?? row.type.defaultIcon
        let headerBgColor: Color = row.type.accentColor.opacity(0.15)
        let iconColor: Color = row.type.accentColor

        Button {
            if !row.isCountdown {
                editingSpecialDay = EditingSpecialDay(
                    id: row.id,
                    ruleID: row.ruleID,
                    name: row.title,
                    date: row.date,
                    type: row.type,
                    symbolName: row.symbolName,
                    iconColor: row.iconColor,
                    notes: row.notes,
                    region: row.region
                )
            }
        } label: {
            VStack(spacing: 0) {
                // HEADER (情報デザイン: Docket style)
                // LEFT: Icon + Date | RIGHT: Month (monospace, uppercase)
                HStack(spacing: 0) {
                    // LEFT: Icon + Date grouped
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(iconColor)

                        Text("\(day)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                    }
                    .padding(.leading, 10)

                    Spacer()

                    // RIGHT: Month (monospace, technical look)
                    Text(monthName)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                        .padding(.trailing, 10)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(headerBgColor)

                // Thin divider (情報デザイン: 1px distinct border)
                Rectangle()
                    .fill(JohoColors.black.opacity(0.3))
                    .frame(height: 1)

                // BODY: Event row (white background)
                VStack(spacing: 0) {
                    // Main event row
                    HStack(spacing: 6) {
                        // Type indicator dot
                        typeIndicatorDot(for: row.type)

                        // Event name (sans-serif for human data)
                        Text(row.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(JohoColors.black)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)

                        Spacer(minLength: 4)

                        // Country badge
                        if row.hasCountryPill {
                            CountryPill(region: row.region)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)

                    // Metadata row (monospace for technical data) - intelligent tense
                    // 情報デザイン: Age 0 = birth year, show contextual "born on this day" message
                    if row.type == .birthday, let age = row.turningAge {
                        Rectangle().fill(JohoColors.black.opacity(0.1)).frame(height: 1)
                        Text(birthdayExpandedDisplayText(age: age, date: row.date, daysUntil: row.daysUntil))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                            .padding(.vertical, 6)
                    } else if row.isCountdown {
                        Rectangle().fill(JohoColors.black.opacity(0.1)).frame(height: 1)
                        let daysText = row.daysUntil == 0 ? "TODAY" :
                                       row.daysUntil == 1 ? "IN 1 DAY" :
                                       "IN \(row.daysUntil) DAYS"
                        Text(daysText)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                            .padding(.vertical, 6)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(JohoColors.black.opacity(0.2), lineWidth: 1)  // Thin technical border
            )
            .shadow(color: JohoColors.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Day Card (情報デザイン: Multi-event Ticket)
    //
    // Same ticket structure, multiple events with hairline dividers:
    // ┌─────────────────────────────────┐
    // │ ❄️ 1    │              JANUARY │
    // ├─────────────────────────────────┤
    // │ ● New Year's Day         [SWE] │
    // │─────────────────────────────────│  ← Hairline divider
    // │ ● Tết Dương lịch          [VN] │
    // └─────────────────────────────────┘

    @ViewBuilder
    private func expandedDayCard(for dayCard: DayCardData) -> some View {
        let calendar = Calendar.current
        let monthName = calendar.monthSymbols[calendar.component(.month, from: dayCard.date) - 1].uppercased()

        // Use first item for header styling
        let primaryItem = dayCard.items.first
        let primaryType = primaryItem?.type ?? .holiday
        let icon = primaryItem?.symbolName ?? primaryType.defaultIcon
        let headerBgColor: Color = primaryType.accentColor.opacity(0.15)
        let iconColor: Color = primaryType.accentColor

        VStack(spacing: 0) {
            // HEADER: Icon + Date LEFT, Month RIGHT
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(iconColor)

                    Text("\(dayCard.day)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                }
                .padding(.leading, 10)

                Spacer()

                Text(monthName)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(JohoColors.black.opacity(0.5))
                    .padding(.trailing, 10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(headerBgColor)

            // Thin divider
            Rectangle()
                .fill(JohoColors.black.opacity(0.3))
                .frame(height: 1)

            // BODY: List of events with hairline dividers
            VStack(spacing: 0) {
                ForEach(Array(dayCard.items.enumerated()), id: \.element.id) { index, item in
                    // Hairline divider between items (not before first)
                    if index > 0 {
                        Rectangle()
                            .fill(JohoColors.black.opacity(0.08))
                            .frame(height: 1)
                            .padding(.horizontal, 10)
                    }

                    // Event row
                    HStack(spacing: 6) {
                        typeIndicatorDot(for: item.type)

                        Text(item.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(JohoColors.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer(minLength: 4)

                        if item.hasCountryPill {
                            CountryPill(region: item.region)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(JohoColors.black.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: JohoColors.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Type Indicator Dot (情報デザイン: Accent-colored circles with BLACK borders)

    @ViewBuilder
    private func typeIndicatorDot(for type: SpecialDayType) -> some View {
        Circle()
            .fill(type.accentColor)
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
    }
}

// MARK: - SpecialDaysListView Disabled State Extension

extension SpecialDaysListView {
    // MARK: - Disabled State

    private var disabledState: some View {
        JohoEmptyState(
            title: "Holidays Are Off",
            message: "Enable in Settings → Show Holidays",
            icon: "calendar.badge.exclamationmark",
            zone: .holidays
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.top, JohoDimensions.spacingXL)
    }

    // MARK: - Data Operations

    private func createSpecialDay(type: SpecialDayType, name: String, date: Date, symbol: String, iconColor: String?, notes: String?, region: String) {
        // Events are stored as CountdownEvent, not HolidayRule
        if type == .event {
            let event = CountdownEvent(
                title: name,
                targetDate: date,
                icon: symbol,
                colorHex: iconColor.map { "#\($0)" } ?? "#805AD5",
                isSystem: false
            )
            modelContext.insert(event)
            do {
                try modelContext.save()
                HapticManager.notification(.success)
            } catch {
                Log.w("Failed to create event: \(error.localizedDescription)")
                HapticManager.notification(.error)
            }
            return
        }

        // Holidays and observances are stored as HolidayRule
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let rule = HolidayRule(
            name: name,
            region: region.isEmpty ? (holidayRegions.primaryRegion ?? "SE") : region,
            isRedDay: type.isRedDay,
            titleOverride: name,
            symbolName: symbol,
            iconColor: iconColor,
            userModifiedAt: Date(),
            notes: notes,
            type: .fixed,
            month: month,
            day: day
        )

        modelContext.insert(rule)
        do {
            try modelContext.save()
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
            HapticManager.notification(.success)
        } catch {
            Log.w("Failed to create special day: \(error.localizedDescription)")
            HapticManager.notification(.error)
        }
    }

    private func updateSpecialDay(ruleID: String, type: SpecialDayType, name: String, date: Date, symbol: String, iconColor: String?, notes: String?, region: String) {
        // Events are stored as CountdownEvent
        if type == .event {
            do {
                let descriptor = FetchDescriptor<CountdownEvent>(predicate: #Predicate<CountdownEvent> { $0.id == ruleID })
                if let event = try modelContext.fetch(descriptor).first {
                    event.title = name
                    event.targetDate = date
                    event.icon = symbol
                    event.colorHex = iconColor.map { "#\($0)" } ?? "#805AD5"

                    try modelContext.save()
                    HapticManager.notification(.success)
                }
            } catch {
                Log.w("Failed to update event: \(error.localizedDescription)")
                HapticManager.notification(.error)
            }
            return
        }

        // Holidays and observances are stored as HolidayRule
        do {
            let descriptor = FetchDescriptor<HolidayRule>(predicate: #Predicate<HolidayRule> { $0.id == ruleID })
            if let rule = try modelContext.fetch(descriptor).first {
                let calendar = Calendar.current
                rule.name = name
                rule.titleOverride = name
                rule.symbolName = symbol
                rule.iconColor = iconColor
                rule.notes = notes
                rule.month = calendar.component(.month, from: date)
                rule.day = calendar.component(.day, from: date)
                rule.region = region
                rule.userModifiedAt = Date()

                try modelContext.save()
                holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
                HapticManager.notification(.success)
            }
        } catch {
            Log.w("Failed to update special day: \(error.localizedDescription)")
            HapticManager.notification(.error)
        }
    }

    // MARK: - Editability Check

    /// Determines if a SpecialDayRow can be edited/deleted
    /// System holidays (isCustom=false) are read-only
    private func isEditable(_ row: SpecialDayRow) -> Bool {
        switch row.type {
        case .holiday, .observance:
            return row.isCustom  // Only user-created holidays/observances
        case .event, .birthday, .note, .trip, .expense:
            return true  // Always editable
        }
    }

    // MARK: - Edit Handler

    /// Opens the appropriate editor sheet based on entry type
    private func openEditor(_ row: SpecialDayRow) {
        switch row.type {
        case .holiday, .observance:
            // Use existing editingSpecialDay mechanism
            editingSpecialDay = EditingSpecialDay(
                id: row.id,
                ruleID: row.ruleID,
                name: row.title,
                date: row.date,
                type: row.type,
                symbolName: row.symbolName,
                iconColor: row.iconColor,
                notes: row.notes,
                region: row.region
            )

        case .event:
            // Fetch CountdownEvent by ruleID
            let ruleId = row.ruleID
            let descriptor = FetchDescriptor<CountdownEvent>(predicate: #Predicate<CountdownEvent> { $0.id == ruleId })
            editingEvent = try? modelContext.fetch(descriptor).first

        case .birthday:
            // Fetch Contact by UUID
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<Contact>(predicate: #Predicate<Contact> { $0.id == uuid })
                editingContact = try? modelContext.fetch(descriptor).first
            }

        case .note:
            // Fetch DailyNote by date
            let targetDate = row.date
            let descriptor = FetchDescriptor<DailyNote>(predicate: #Predicate<DailyNote> { $0.day == targetDate })
            editingNote = try? modelContext.fetch(descriptor).first

        case .trip:
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<TravelTrip>(predicate: #Predicate<TravelTrip> { $0.id == uuid })
                editingTrip = try? modelContext.fetch(descriptor).first
            }

        case .expense:
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<ExpenseItem>(predicate: #Predicate<ExpenseItem> { $0.id == uuid })
                editingExpense = try? modelContext.fetch(descriptor).first
            }
        }
    }

    // MARK: - Delete Handler

    /// Deletes a row based on its type
    private func deleteRow(_ row: SpecialDayRow) {
        switch row.type {
        case .holiday, .observance, .event:
            // Use existing deleteWithUndo for these types
            deleteWithUndo(row: row)

        case .birthday:
            // Delete the contact
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<Contact>(predicate: #Predicate<Contact> { $0.id == uuid })
                if let contact = try? modelContext.fetch(descriptor).first {
                    modelContext.delete(contact)
                    try? modelContext.save()
                    HapticManager.notification(.success)
                }
            }

        case .note:
            // Delete the note by date
            let targetDate = row.date
            let descriptor = FetchDescriptor<DailyNote>(predicate: #Predicate<DailyNote> { $0.day == targetDate })
            if let note = try? modelContext.fetch(descriptor).first {
                modelContext.delete(note)
                try? modelContext.save()
                HapticManager.notification(.success)
            }

        case .trip:
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<TravelTrip>(predicate: #Predicate<TravelTrip> { $0.id == uuid })
                if let trip = try? modelContext.fetch(descriptor).first {
                    modelContext.delete(trip)
                    try? modelContext.save()
                    HapticManager.notification(.success)
                }
            }

        case .expense:
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<ExpenseItem>(predicate: #Predicate<ExpenseItem> { $0.id == uuid })
                if let expense = try? modelContext.fetch(descriptor).first {
                    modelContext.delete(expense)
                    try? modelContext.save()
                    HapticManager.notification(.success)
                }
            }
        }
    }

    private func deleteWithUndo(row: SpecialDayRow) {
        deletedSpecialDay = DeletedSpecialDay(
            ruleID: row.ruleID,
            name: row.title,
            date: row.date,
            type: row.type,
            symbol: row.symbolName ?? row.type.defaultIcon,
            iconColor: row.iconColor,
            notes: row.notes,
            region: row.region
        )

        let ruleId = row.ruleID

        // Events are stored as CountdownEvent
        if row.type == .event {
            do {
                let descriptor = FetchDescriptor<CountdownEvent>(predicate: #Predicate<CountdownEvent> { $0.id == ruleId })
                if let event = try modelContext.fetch(descriptor).first {
                    modelContext.delete(event)
                    try modelContext.save()
                    HapticManager.notification(.warning)

                    withAnimation(.easeInOut(duration: 0.2)) {
                        showUndoToast = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation {
                            showUndoToast = false
                        }
                    }
                }
            } catch {
                Log.w("Failed to delete event: \(error.localizedDescription)")
            }
            return
        }

        // Holidays and observances are stored as HolidayRule
        do {
            let descriptor = FetchDescriptor<HolidayRule>(predicate: #Predicate<HolidayRule> { $0.id == ruleId })
            if let rule = try modelContext.fetch(descriptor).first {
                modelContext.delete(rule)
                try modelContext.save()
                holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
                HapticManager.notification(.warning)

                withAnimation(.easeInOut(duration: 0.2)) {
                    showUndoToast = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation {
                        showUndoToast = false
                    }
                }
            }
        } catch {
            Log.w("Failed to delete special day: \(error.localizedDescription)")
        }
    }

    private func undoDelete() {
        guard let deleted = deletedSpecialDay else { return }

        createSpecialDay(
            type: deleted.type,
            name: deleted.name,
            date: deleted.date,
            symbol: deleted.symbol,
            iconColor: deleted.iconColor,
            notes: deleted.notes,
            region: deleted.region
        )

        deletedSpecialDay = nil
        withAnimation {
            showUndoToast = false
        }
    }

    // MARK: - Helpers

    private var defaultNewRegion: String {
        holidayRegions.regions.count == 1 ? (holidayRegions.primaryRegion ?? "SE") : ""
    }
}

// MARK: - Shared Undo Toast (情報デザイン)

struct JohoUndoToast: View {
    let message: String
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            Text(message)
                .font(JohoFont.body)
                .foregroundStyle(JohoColors.white)
                .lineLimit(1)

            Spacer()

            Button {
                HapticManager.selection()
                onUndo()
            } label: {
                Text("Undo")
                    .font(JohoFont.body.bold())
                    .foregroundStyle(JohoColors.cyan)
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.white.opacity(0.6))
            }
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.vertical, JohoDimensions.spacingMD)
        .background(JohoColors.black)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, JohoDimensions.spacingLG)
    }
}

// MARK: - Special Day Editor Sheet (情報デザイン)

struct JohoSpecialDayEditorSheet: View {
    enum Mode {
        case create
        case edit(name: String, date: Date, symbol: String, iconColor: String?, notes: String?, region: String)
    }

    let mode: Mode
    let type: SpecialDayType
    let defaultRegion: String
    let onSave: (String, Date, String, String?, String?, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = 1
    @State private var selectedDay: Int = 1
    @State private var selectedSymbol: String = "star.fill"
    @State private var selectedRegion: String = ""
    @State private var showingIconPicker = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // 情報デザイン Header: Title based on type and mode
    private var headerTitle: String {
        let typeName = String(type.title.dropLast()).uppercased()  // "HOLIDAY", "OBSERVANCE", etc.
        return isEditing ? "EDIT \(typeName)" : "NEW \(typeName)"
    }

    private var headerSubtitle: String {
        isEditing ? "Update details" : "Set date & details"
    }

    private var selectedDate: Date {
        let calendar = Calendar.current
        return calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)) ?? Date()
    }

    private var yearRange: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }

    init(mode: Mode, type: SpecialDayType, defaultRegion: String, onSave: @escaping (String, Date, String, String?, String?, String) -> Void) {
        self.mode = mode
        self.type = type
        self.defaultRegion = defaultRegion
        self.onSave = onSave

        let calendar = Calendar.current
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _notes = State(initialValue: "")
            _selectedYear = State(initialValue: calendar.component(.year, from: Date()))
            _selectedMonth = State(initialValue: calendar.component(.month, from: Date()))
            _selectedDay = State(initialValue: calendar.component(.day, from: Date()))
            _selectedSymbol = State(initialValue: type.defaultIcon)
            _selectedRegion = State(initialValue: defaultRegion)
        case .edit(let editName, let editDate, let editSymbol, _, let editNotes, let editRegion):
            // Note: editIconColor ignored - 情報デザイン uses type's fixed color
            _name = State(initialValue: editName)
            _notes = State(initialValue: editNotes ?? "")
            _selectedYear = State(initialValue: calendar.component(.year, from: editDate))
            _selectedMonth = State(initialValue: calendar.component(.month, from: editDate))
            _selectedDay = State(initialValue: calendar.component(.day, from: editDate))
            _selectedSymbol = State(initialValue: editSymbol)
            _selectedRegion = State(initialValue: editRegion)
        }
    }

    var body: some View {
        // 情報デザイン: UNIFIED BENTO PILLBOX - entire editor is one compartmentalized box
        VStack(spacing: 0) {
            Spacer().frame(height: JohoDimensions.spacingLG)

            // UNIFIED BENTO CONTAINER
            VStack(spacing: 0) {
                // ═══════════════════════════════════════════════════════════════
                // HEADER ROW: [<] | [icon] Title/Subtitle | [Save]
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Back button (44pt)
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(JohoColors.black)
                            .frame(width: 44, height: 44)
                    }

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Icon + Title/Subtitle
                    HStack(spacing: JohoDimensions.spacingSM) {
                        // Type icon in colored box
                        Image(systemName: type.defaultIcon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(type.accentColor)
                            .frame(width: 36, height: 36)
                            .background(type.lightBackground)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(headerTitle)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                            Text(headerSubtitle)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                    .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // RIGHT: Save button (72pt)
                    Button {
                        let notesValue = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(
                            name.trimmingCharacters(in: .whitespacesAndNewlines),
                            selectedDate,
                            selectedSymbol,
                            nil,  // 情報デザイン: Use type's fixed color, no custom colors
                            notesValue.isEmpty ? nil : notesValue,
                            selectedRegion
                        )
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.4))
                            .frame(width: 56, height: 32)
                            .background(canSave ? type.accentColor : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1.5))
                    }
                    .disabled(!canSave)
                    .frame(width: 72)
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 56)
                .background(type.accentColor.opacity(0.7))  // 情報デザイン: Darker header like Month Page sections

                // Thick divider after header
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // NAME ROW: [●] | Name text field
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Type indicator dot (40pt)
                    Circle()
                        .fill(type.accentColor)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Name field (full width)
                    TextField(type == .holiday ? "Holiday name" : "Observance name", text: $name)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 48)
                .background(type.lightBackground)

                // 情報デザイン: Row divider (solid black)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // DATE ROW: [📅] | Year | Month | Day (compartmentalized)
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Calendar icon (40pt)
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // YEAR compartment
                    Menu {
                        ForEach(yearRange, id: \.self) { year in
                            Button { selectedYear = year } label: { Text(String(year)) }
                        }
                    } label: {
                        Text(String(selectedYear))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(JohoColors.black)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // MONTH compartment
                    Menu {
                        ForEach(1...12, id: \.self) { month in
                            Button { selectedMonth = month } label: { Text(monthName(month)) }
                        }
                    } label: {
                        Text(monthName(selectedMonth))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // DAY compartment
                    Menu {
                        ForEach(1...daysInMonth(selectedMonth, year: selectedYear), id: \.self) { day in
                            Button { selectedDay = day } label: { Text("\(day)") }
                        }
                    } label: {
                        Text("\(selectedDay)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(JohoColors.black)
                            .frame(width: 44)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(height: 48)
                .background(type.lightBackground)

                // 情報デザイン: Row divider (solid black)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // ICON PICKER ROW: [icon] | Tap to change icon [>]
                // ═══════════════════════════════════════════════════════════════
                Button {
                    showingIconPicker = true
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 0) {
                        // LEFT: Current icon (40pt)
                        Image(systemName: selectedSymbol)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(type.accentColor)
                            .frame(width: 40)
                            .frame(maxHeight: .infinity)

                        // WALL
                        Rectangle()
                            .fill(JohoColors.black)
                            .frame(width: 1.5)
                            .frame(maxHeight: .infinity)

                        // CENTER: Hint text
                        Text("Tap to change icon")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                            .padding(.leading, JohoDimensions.spacingMD)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(JohoColors.black.opacity(0.4))
                            .padding(.trailing, JohoDimensions.spacingMD)
                    }
                    .frame(height: 48)
                    .background(type.lightBackground)
                }
                .buttonStyle(.plain)
            }
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
            )
            .padding(.horizontal, JohoDimensions.spacingLG)

            Spacer()
        }
        .johoBackground()
        .navigationBarHidden(true)
        .sheet(isPresented: $showingIconPicker) {
            JohoIconPickerSheet(
                selectedSymbol: $selectedSymbol,
                accentColor: type.accentColor,
                lightBackground: type.lightBackground
            )
        }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2024, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }

    private func daysInMonth(_ month: Int, year: Int = Calendar.current.component(.year, from: Date())) -> Int {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 31
    }

    private func regionDisplayName(_ region: String) -> String {
        switch region {
        case "SE": return "Sweden (SE)"
        case "US": return "United States (US)"
        case "INTL": return "International"
        default: return region
        }
    }
}

// MARK: - Icon Picker Sheet (情報デザイン)

struct JohoIconPickerSheet: View {
    @Binding var selectedSymbol: String
    let accentColor: Color
    let lightBackground: Color
    @Environment(\.dismiss) private var dismiss

    private let symbolCategories: [(name: String, symbols: [String])] = [
        ("MARU-BATSU", ["circle", "circle.fill", "xmark", "xmark.circle.fill", "triangle", "triangle.fill", "square", "square.fill", "diamond", "diamond.fill"]),
        ("EVENTS", ["star.fill", "sparkles", "gift.fill", "birthday.cake.fill", "party.popper.fill", "balloon.fill", "heart.fill", "bell.fill", "calendar.badge.clock"]),
        ("NATURE", ["leaf.fill", "camera.macro", "sun.max.fill", "moon.fill", "snowflake", "cloud.sun.fill", "flame.fill", "drop.fill"]),
        ("PEOPLE", ["person.fill", "person.2.fill", "figure.stand", "heart.circle.fill", "hand.raised.fill"]),
        ("TIME", ["calendar", "clock.fill", "hourglass", "timer", "sunrise.fill", "sunset.fill"]),
    ]

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: JohoDimensions.spacingSM)]

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Header
                VStack(spacing: JohoDimensions.spacingSM) {
                    HStack {
                        Button { dismiss() } label: {
                            Text("Cancel")
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black)
                                .padding(.horizontal, JohoDimensions.spacingMD)
                                .padding(.vertical, JohoDimensions.spacingSM)
                                .background(JohoColors.white)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                )
                        }
                        Spacer()
                    }

                    Text("Choose Icon")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(JohoColors.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(JohoDimensions.spacingLG)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingLG)

                // Categories
                ForEach(symbolCategories, id: \.name) { category in
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: category.name, style: .whiteOnBlack, size: .small)

                        LazyVGrid(columns: columns, spacing: JohoDimensions.spacingSM) {
                            ForEach(category.symbols, id: \.self) { symbol in
                                Button {
                                    selectedSymbol = symbol
                                    HapticManager.selection()
                                    dismiss()
                                } label: {
                                    Image(systemName: symbol)
                                        .font(.system(size: 20, weight: .bold))
                                        // 情報デザイン: Accent color on light bg (NOT inverted)
                                        .foregroundStyle(selectedSymbol == symbol ? accentColor : JohoColors.black)
                                        .frame(width: 52, height: 52)
                                        .background(selectedSymbol == symbol ? lightBackground : JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: selectedSymbol == symbol ? JohoDimensions.borderMedium : JohoDimensions.borderThin)
                                        )
                                }
                            }
                        }
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusLarge)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                Spacer(minLength: JohoDimensions.spacingXL)
            }
        }
        .johoBackground()
        .presentationCornerRadius(20)
        .presentationDetents([.large])
    }
}

// MARK: - Add Special Day Sheet (情報デザイン - Jōhō Dezain)

/// 情報デザイン data entry option
private struct JohoInputOption: Identifiable {
    let id = UUID()
    let icon: String      // SF Symbol name
    let code: String      // "HOL", "OBS"...
    let label: String     // "HOLIDAY"
    let meta: String      // "OFFICIAL // WORK_SUSPENDED"
    let color: Color
    let action: () -> Void
}

struct JohoAddSpecialDaySheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectHoliday: () -> Void
    let onSelectObservance: () -> Void
    let onSelectEvent: () -> Void
    var onSelectBirthday: (() -> Void)? = nil
    var onSelectNote: (() -> Void)? = nil
    var onSelectTrip: (() -> Void)? = nil
    var onSelectExpense: (() -> Void)? = nil

    private var options: [JohoInputOption] {
        var opts: [JohoInputOption] = [
            JohoInputOption(icon: "star.fill", code: "HOL", label: "HOLIDAY", meta: "OFFICIAL", color: SpecialDayType.holiday.accentColor, action: onSelectHoliday),
            JohoInputOption(icon: "sparkles", code: "OBS", label: "OBSERVANCE", meta: "NOTABLE", color: SpecialDayType.observance.accentColor, action: onSelectObservance),
            JohoInputOption(icon: "calendar.badge.clock", code: "EVT", label: "EVENT", meta: "COUNTDOWN", color: SpecialDayType.event.accentColor, action: onSelectEvent),
        ]

        if let birthdayAction = onSelectBirthday {
            opts.append(JohoInputOption(icon: "birthday.cake.fill", code: "BDY", label: "BIRTHDAY", meta: "CONTACT", color: SpecialDayType.birthday.accentColor, action: birthdayAction))
        }
        if let noteAction = onSelectNote {
            opts.append(JohoInputOption(icon: "note.text", code: "NTE", label: "NOTE", meta: "MEMO", color: SpecialDayType.note.accentColor, action: noteAction))
        }
        if let tripAction = onSelectTrip {
            opts.append(JohoInputOption(icon: "airplane", code: "TRP", label: "TRIP", meta: "TRAVEL", color: SpecialDayType.trip.accentColor, action: tripAction))
        }
        if let expenseAction = onSelectExpense {
            opts.append(JohoInputOption(icon: "dollarsign.circle.fill", code: "EXP", label: "EXPENSE", meta: "FINANCE", color: SpecialDayType.expense.accentColor, action: expenseAction))
        }
        return opts
    }

    var body: some View {
        VStack(spacing: 0) {
            // 情報デザイン Header - Bold BLACK with thick border
            HStack {
                Text("ADD ENTRY")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(JohoColors.white)

                Spacer()

                Button { dismiss() } label: {
                    ZStack {
                        Circle()
                            .fill(JohoColors.white)
                            .frame(width: 24, height: 24)
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(JohoColors.black)
                    }
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, 12)
            .background(JohoColors.black)

            // Entry list with thick BLACK borders between rows
            VStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    Button {
                        HapticManager.selection()
                        option.action()
                    } label: {
                        JohoCompactInputRow(option: option)
                    }
                    .buttonStyle(.plain)

                    // Thick BLACK divider between rows
                    if index < options.count - 1 {
                        Rectangle()
                            .fill(JohoColors.black)
                            .frame(height: JohoDimensions.borderMedium)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingLG)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(CGFloat(100 + options.count * 64))])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
    }
}

/// 情報デザイン compact row - Bold colors, thick BLACK borders
private struct JohoCompactInputRow: View {
    let option: JohoInputOption

    var body: some View {
        HStack(spacing: 12) {
            // 情報デザイン: Colored circle with BLACK border + Icon
            ZStack {
                Circle()
                    .fill(option.color)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium))

                Image(systemName: option.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JohoColors.white)
            }

            // Code badge - BLACK border around colored pill
            Text(option.code)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(option.color)
                .clipShape(Squircle(cornerRadius: 4))
                .overlay(
                    Squircle(cornerRadius: 4)
                        .stroke(JohoColors.black, lineWidth: 1.5)
                )

            // Label - bold rounded for 情報デザイン
            Text(option.label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)

            Spacer()

            // Arrow - bold BLACK
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(JohoColors.black)
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, 10)
        .background(JohoColors.white)
    }
}

// MARK: - Event Editor Sheet (情報デザイン)

struct JohoEventEditorSheet: View {
    let event: CountdownEvent
    let onSave: (String, Date, String, String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedYear: Int = 2026
    @State private var selectedMonth: Int = 1
    @State private var selectedDay: Int = 1
    @State private var selectedSymbol: String = "calendar.badge.clock"
    @State private var showingIconPicker = false

    private let calendar = Calendar.current

    // 情報デザイン: Events ALWAYS use purple color scheme
    private var eventAccentColor: Color { SpecialDayType.event.accentColor }
    private var eventLightBackground: Color { SpecialDayType.event.lightBackground }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var selectedDate: Date {
        let components = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
        return calendar.date(from: components) ?? Date()
    }

    private var yearRange: [Int] {
        let current = calendar.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }

    init(event: CountdownEvent, onSave: @escaping (String, Date, String, String) -> Void) {
        self.event = event
        self.onSave = onSave
        let calendar = Calendar.current
        _name = State(initialValue: event.title)
        _selectedYear = State(initialValue: calendar.component(.year, from: event.targetDate))
        _selectedMonth = State(initialValue: calendar.component(.month, from: event.targetDate))
        _selectedDay = State(initialValue: calendar.component(.day, from: event.targetDate))
        _selectedSymbol = State(initialValue: event.icon)
    }

    var body: some View {
        // 情報デザイン: UNIFIED BENTO PILLBOX - entire editor is one compartmentalized box
        VStack(spacing: 0) {
            Spacer().frame(height: JohoDimensions.spacingLG)

            // UNIFIED BENTO CONTAINER
            VStack(spacing: 0) {
                // ═══════════════════════════════════════════════════════════════
                // HEADER ROW: [<] | [icon] Title/Subtitle | [Save]
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Back button (44pt)
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(JohoColors.black)
                            .frame(width: 44, height: 44)
                    }

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Icon + Title/Subtitle
                    HStack(spacing: JohoDimensions.spacingSM) {
                        // Type icon in colored box
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(eventAccentColor)
                            .frame(width: 36, height: 36)
                            .background(eventLightBackground)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("EDIT EVENT")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                            Text("Update date & details")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                    .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // RIGHT: Save button (72pt)
                    Button {
                        onSave(
                            name.trimmingCharacters(in: .whitespacesAndNewlines),
                            selectedDate,
                            selectedSymbol,
                            "#805AD5"
                        )
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.4))
                            .frame(width: 56, height: 32)
                            .background(canSave ? eventAccentColor : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1.5))
                    }
                    .disabled(!canSave)
                    .frame(width: 72)
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 56)
                .background(eventAccentColor.opacity(0.7))  // 情報デザイン: Darker header like Month Page sections

                // Thick divider after header
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // NAME ROW: [●] | Event name (no EVT pill - redundant in editor)
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Type indicator dot (40pt)
                    Circle()
                        .fill(eventAccentColor)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Name field (full width - no EVT pill needed)
                    TextField("Event name", text: $name)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 48)
                .background(eventLightBackground)

                // 情報デザイン: Row divider (solid black)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // DATE ROW: [📅] | Year | Month | Day (compartmentalized)
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Calendar icon (40pt)
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // YEAR compartment
                    Menu {
                        ForEach(yearRange, id: \.self) { year in
                            Button { selectedYear = year } label: { Text(String(year)) }
                        }
                    } label: {
                        Text(String(selectedYear))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(JohoColors.black)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // MONTH compartment
                    Menu {
                        ForEach(1...12, id: \.self) { month in
                            Button { selectedMonth = month } label: { Text(monthName(month)) }
                        }
                    } label: {
                        Text(monthName(selectedMonth))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // DAY compartment
                    Menu {
                        ForEach(1...daysInMonth(selectedMonth, year: selectedYear), id: \.self) { day in
                            Button { selectedDay = day } label: { Text("\(day)") }
                        }
                    } label: {
                        Text("\(selectedDay)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(JohoColors.black)
                            .frame(width: 44)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(height: 48)
                .background(eventLightBackground)

                // 情報デザイン: Row divider (solid black)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // ICON PICKER ROW: [icon] | Tap to change icon [>]
                // ═══════════════════════════════════════════════════════════════
                Button {
                    showingIconPicker = true
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 0) {
                        // LEFT: Current icon (40pt)
                        Image(systemName: selectedSymbol)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(eventAccentColor)
                            .frame(width: 40)
                            .frame(maxHeight: .infinity)

                        // WALL
                        Rectangle()
                            .fill(JohoColors.black)
                            .frame(width: 1.5)
                            .frame(maxHeight: .infinity)

                        // CENTER: Hint text
                        Text("Tap to change icon")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                            .padding(.leading, JohoDimensions.spacingMD)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(JohoColors.black.opacity(0.4))
                            .padding(.trailing, JohoDimensions.spacingMD)
                    }
                    .frame(height: 48)
                    .background(eventLightBackground)
                }
                .buttonStyle(.plain)
            }
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
            )
            .padding(.horizontal, JohoDimensions.spacingLG)

            Spacer()
        }
        .johoBackground()
        .navigationBarHidden(true)
        .sheet(isPresented: $showingIconPicker) {
            JohoIconPickerSheet(
                selectedSymbol: $selectedSymbol,
                accentColor: eventAccentColor,
                lightBackground: eventLightBackground
            )
        }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let components = DateComponents(year: 2024, month: month, day: 1)
        let tempDate = calendar.date(from: components) ?? Date()
        return formatter.string(from: tempDate)
    }

    private func daysInMonth(_ month: Int, year: Int) -> Int {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let tempDate = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: tempDate) else {
            return 31
        }
        return range.count
    }
}

// MARK: - Preview

#Preview {
    if let container = try? ModelContainer(
        for: HolidayRule.self, CalendarRule.self, DailyNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) {
        NavigationStack {
            SpecialDaysListView(isInMonthDetail: .constant(false))
        }
        .modelContainer(container)
    } else {
        Text("Preview unavailable")
    }
}
