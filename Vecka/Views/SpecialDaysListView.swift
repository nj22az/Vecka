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
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Header with year picker (always visible)
                headerWithYearPicker

                // Content: Month grid or month detail
                if !showHolidays {
                    disabledState
                } else if let month = selectedMonth {
                    // Month detail view
                    monthDetailView(for: month)
                } else {
                    // Month grid
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
        .sheet(isPresented: $isPresentingNewSpecialDay) {
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
        .sheet(item: $editingSpecialDay) { specialDay in
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
        .overlay(alignment: .bottom) {
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
                            .font(JohoFont.displaySmall)
                            .foregroundStyle(JohoColors.black)
                            .lineLimit(1)

                        // 情報デザイン: Compact subtitle that doesn't truncate on iPhone
                        Text(compactSubtitle)
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.7))
                            .lineLimit(2)
                    }
                }

                Spacer()

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
                            onToggle: { toggleExpand(dayCard) }
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

    private let calendar = Calendar.iso8601

    // Group items by type
    private var holidays: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .holiday }
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
                    // Today pill
                    if isToday {
                        JohoPill(text: "Today", style: .colored(JohoColors.yellow), size: .small)
                    }

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
            // Holidays section (pink background)
            if !holidays.isEmpty {
                specialDaySection(
                    title: "Holidays",
                    items: holidays,
                    zone: .holidays,
                    icon: "star.fill"
                )
            }

            // Observances section (orange tint)
            if !observances.isEmpty {
                specialDaySection(
                    title: "Observances",
                    items: observances,
                    zone: .countdowns,  // Orange for observances
                    icon: "sparkles"
                )
            }

            // Events section (cyan background)
            if !events.isEmpty {
                specialDaySection(
                    title: "Events",
                    items: events,
                    zone: .calendar,
                    icon: "calendar.badge.clock"
                )
            }

            // Birthdays section (pink tint - separate zone from holidays)
            if !birthdays.isEmpty {
                specialDaySection(
                    title: "Birthdays",
                    items: birthdays,
                    zone: .birthdays,
                    icon: "birthday.cake.fill"
                )
            }

            // Notes section (yellow tint)
            if !notes.isEmpty {
                specialDaySection(
                    title: "Notes",
                    items: notes,
                    zone: .notes,
                    icon: "note.text"
                )
            }

            // Trips section (blue tint)
            if !tripsForDay.isEmpty {
                specialDaySection(
                    title: "Trips",
                    items: tripsForDay,
                    zone: .calendar,  // Blue for travel
                    icon: "airplane"
                )
            }

            // Expenses section (green tint)
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

    // MARK: - Section Box

    @ViewBuilder
    private func specialDaySection(title: String, items: [SpecialDayRow], zone: SectionZone, icon: String) -> some View {
        JohoSectionBox(title: title, zone: zone, icon: icon) {
            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                ForEach(items) { item in
                    specialDayItemRow(item)
                }
            }
        }
    }

    // MARK: - Item Row (情報デザイン: Icon + Title + Country Pill)

    @ViewBuilder
    private func specialDayItemRow(_ item: SpecialDayRow) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Type indicator dot
            typeIndicatorDot(for: item.type)

            // Title
            Text(item.title)
                .font(JohoFont.bodySmall)
                .foregroundStyle(JohoColors.black)
                .lineLimit(2)

            Spacer()

            // Birthday age or countdown (intelligent tense)
            if item.type == .birthday, let age = item.turningAge {
                let isPast = Calendar.current.startOfDay(for: item.date) < Calendar.current.startOfDay(for: Date())
                let isToday = Calendar.current.isDateInToday(item.date)
                let tense = isToday ? "TURNS" : (isPast ? "TURNED" : "TURNS")
                Text("\(tense) \(age)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            } else if item.isCountdown && item.type == .event {
                let daysText = item.daysUntil == 0 ? "TODAY" :
                              item.daysUntil == 1 ? "IN 1D" :
                              "IN \(item.daysUntil)D"
                Text(daysText)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }

            // Country pill (for holidays/observances)
            if item.hasCountryPill {
                CountryPill(region: item.region)
            }

            // Type code pill (情報デザイン: 3-letter code from database)
            if item.type == .holiday {
                JohoPill(text: item.type.code, style: .colored(item.type.accentColor), size: .small)
            }
        }
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
                    if row.type == .birthday, let age = row.turningAge {
                        Rectangle().fill(JohoColors.black.opacity(0.1)).frame(height: 1)
                        let isPast = Calendar.current.startOfDay(for: row.date) < Calendar.current.startOfDay(for: Date())
                        let isToday = Calendar.current.isDateInToday(row.date)
                        let tense = isToday ? "TURNS" : (isPast ? "TURNED" : "TURNS")
                        let timeText = isToday ? "TODAY" : (isPast ? "\(abs(row.daysUntil))D AGO" : "IN \(row.daysUntil)D")
                        Text("\(tense) \(age) · \(timeText)")
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
    @State private var selectedMonth: Int = 1
    @State private var selectedDay: Int = 1
    @State private var selectedSymbol: String = "star.fill"
    @State private var selectedIconColor: String? = nil
    @State private var selectedRegion: String = ""
    @State private var showingIconPicker = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var iconBackgroundColor: Color {
        if let hex = selectedIconColor {
            return Color(hex: hex)
        }
        return type.accentColor.opacity(0.3)
    }

    private var iconColorPalette: [(hex: String, name: String)] {
        [
            ("E53E3E", "Red"),
            ("ED8936", "Orange"),
            ("ECC94B", "Yellow"),
            ("38A169", "Green"),
            ("3182CE", "Blue"),
            ("805AD5", "Purple"),
            ("D53F8C", "Pink"),
            ("718096", "Gray")
        ]
    }

    private var selectedDate: Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        return calendar.date(from: DateComponents(year: year, month: selectedMonth, day: selectedDay)) ?? Date()
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
            _selectedMonth = State(initialValue: calendar.component(.month, from: Date()))
            _selectedDay = State(initialValue: calendar.component(.day, from: Date()))
            _selectedSymbol = State(initialValue: type.defaultIcon)
            _selectedIconColor = State(initialValue: nil)
            _selectedRegion = State(initialValue: defaultRegion)
        case .edit(let editName, let editDate, let editSymbol, let editIconColor, let editNotes, let editRegion):
            _name = State(initialValue: editName)
            _notes = State(initialValue: editNotes ?? "")
            _selectedMonth = State(initialValue: calendar.component(.month, from: editDate))
            _selectedDay = State(initialValue: calendar.component(.day, from: editDate))
            _selectedSymbol = State(initialValue: editSymbol)
            _selectedIconColor = State(initialValue: editIconColor)
            _selectedRegion = State(initialValue: editRegion)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingMD)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    Spacer()

                    Button {
                        let notesValue = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(
                            name.trimmingCharacters(in: .whitespacesAndNewlines),
                            selectedDate,
                            selectedSymbol,
                            selectedIconColor,
                            notesValue.isEmpty ? nil : notesValue,
                            selectedRegion
                        )
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(JohoFont.body.bold())
                            .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.4))
                            .padding(.horizontal, JohoDimensions.spacingLG)
                            .padding(.vertical, JohoDimensions.spacingMD)
                            .background(canSave ? type.accentColor : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }
                    .disabled(!canSave)
                }
                .padding(.top, JohoDimensions.spacingLG)

                // Main content card
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Title with type indicator - 情報デザイン: Filled circle with BLACK border
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Circle()
                            .fill(type.accentColor)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
                        Text(isEditing ? "Edit \(type.title.dropLast())" : "New \(type.title.dropLast())")
                            .font(JohoFont.displaySmall)
                            .foregroundStyle(JohoColors.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Icon & Color row
                    HStack(spacing: JohoDimensions.spacingMD) {
                        // Icon selector
                        Button { showingIconPicker = true } label: {
                            Image(systemName: selectedSymbol)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(JohoColors.black)
                                .frame(width: 56, height: 56)
                                .background(iconBackgroundColor)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
                                )
                        }

                        // Color picker (compact)
                        HStack(spacing: 8) {
                            ForEach(iconColorPalette.prefix(6), id: \.hex) { color in
                                Button {
                                    selectedIconColor = color.hex
                                    HapticManager.selection()
                                } label: {
                                    Circle()
                                        .fill(Color(hex: color.hex))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(JohoColors.black, lineWidth: selectedIconColor == color.hex ? 3 : 1)
                                        )
                                }
                            }
                        }
                    }

                    // Name field
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "NAME", style: .whiteOnBlack, size: .small)

                        TextField(type == .holiday ? "e.g., Christmas" : "e.g., Birthday", text: $name)
                            .font(JohoFont.headline)
                            .foregroundStyle(JohoColors.black)
                            .padding(JohoDimensions.spacingMD)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    // Date picker (compact)
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "DATE", style: .whiteOnBlack, size: .small)

                        HStack(spacing: JohoDimensions.spacingMD) {
                            // Month
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MONTH")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                Menu {
                                    ForEach(1...12, id: \.self) { month in
                                        Button { selectedMonth = month } label: {
                                            Text(monthName(month))
                                        }
                                    }
                                } label: {
                                    Text(monthName(selectedMonth))
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)
                                        .padding(JohoDimensions.spacingSM)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                        )
                                }
                            }

                            // Day
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DAY")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                Menu {
                                    ForEach(1...daysInMonth(selectedMonth), id: \.self) { day in
                                        Button { selectedDay = day } label: {
                                            Text("\(day)")
                                        }
                                    }
                                } label: {
                                    Text("\(selectedDay)")
                                        .font(JohoFont.body)
                                        .monospacedDigit()
                                        .foregroundStyle(JohoColors.black)
                                        .padding(JohoDimensions.spacingSM)
                                        .frame(width: 60)
                                        .background(JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                        )
                                }
                            }
                        }
                    }

                    // Notes field (optional)
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "NOTES (OPTIONAL)", style: .whiteOnBlack, size: .small)

                        TextEditor(text: $notes)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .frame(height: 80)
                            .scrollContentBackground(.hidden)  // 情報デザイン: Hide system background for white
                            .padding(JohoDimensions.spacingSM)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    // Region selector (for holidays only)
                    if type == .holiday {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            JohoPill(text: "REGION", style: .whiteOnBlack, size: .small)

                            Menu {
                                Button { selectedRegion = "SE" } label: {
                                    Text("Sweden (SE)")
                                }
                                Button { selectedRegion = "US" } label: {
                                    Text("United States (US)")
                                }
                                Button { selectedRegion = "INTL" } label: {
                                    Text("International")
                                }
                            } label: {
                                HStack {
                                    Text(regionDisplayName(selectedRegion))
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(JohoColors.black.opacity(0.5))
                                }
                                .padding(JohoDimensions.spacingMD)
                                .background(JohoColors.white)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                )
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

                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .sheet(isPresented: $showingIconPicker) {
            JohoIconPickerSheet(selectedSymbol: $selectedSymbol)
        }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2024, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }

    private func daysInMonth(_ month: Int) -> Int {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2024, month: month, day: 1)) ?? Date()
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

private struct JohoIconPickerSheet: View {
    @Binding var selectedSymbol: String
    @Environment(\.dismiss) private var dismiss

    private let symbolCategories: [(name: String, symbols: [String])] = [
        ("MARU-BATSU", ["circle", "circle.fill", "xmark", "xmark.circle.fill", "triangle", "triangle.fill", "square", "square.fill", "diamond", "diamond.fill"]),
        ("EVENTS", ["star.fill", "sparkles", "gift.fill", "birthday.cake.fill", "party.popper.fill", "balloon.fill", "heart.fill", "bell.fill"]),
        ("NATURE", ["leaf.fill", "flower.fill", "sun.max.fill", "moon.fill", "snowflake", "cloud.sun.fill", "flame.fill", "drop.fill"]),
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
                                        .foregroundStyle(selectedSymbol == symbol ? JohoColors.white : JohoColors.black)
                                        .frame(width: 52, height: 52)
                                        .background(selectedSymbol == symbol ? JohoColors.black : JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
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
