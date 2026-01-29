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
//  IMPORTANT: Icons are DATABASE-DRIVEN
//  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  Category icons (holiday, observance, memo) come from customCategoryIcon(for:)
//  which reads from @AppStorage("categoryCustomizations").
//  NEVER hardcode icons - always use:
//    customCategoryIcon(for: .category) ?? DisplayCategory.category.outlineIcon
//
//

import SwiftUI
import SwiftData

// MARK: - Local Helper Types (fileprivate to SpecialDaysListView)

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

/// 情報デザイン: Wrapper for month customization editing (makes Int identifiable for sheet binding)
fileprivate struct MonthLabelEdit: Identifiable {
    let id: Int  // Month number (1-12)
    var month: Int { id }
}

/// 情報デザイン: Custom icon, color, and message for a month card
struct MonthCustomization: Codable, Equatable {
    var icon: String?         // SF Symbol name (nil = use default seasonal icon)
    var iconColorHex: String? // Icon color hex (nil = use theme accent color)
    var colorHex: String?     // Background color hex (nil = use default seasonal color)
    var message: String?      // Personal note (nil = no message)
}

/// 情報デザイン: Custom icon for category cards (color is locked to category)
struct CategoryCustomization: Codable, Equatable {
    var icon: String?  // SF Symbol name (nil = use default category icon)
}

// MARK: - Special Days List View (情報デザイン Redesign)

struct SpecialDaysListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    private var holidayManager = HolidayManager.shared

    // Query contacts for birthdays
    @Query private var contacts: [Contact]

    // Query memos (unified: notes, events, trips, expenses)
    @Query(sort: \Memo.date) private var memos: [Memo]

    @AppStorage("showHolidays") private var showHolidays = true
    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])
    @AppStorage("monthCustomizations") private var monthCustomizationsData: Data = Data()  // 情報デザイン: Custom icon + color per month
    @AppStorage("categoryCustomizations") private var categoryCustomizationsData: Data = Data()  // 情報デザイン: Custom icon per category
    @AppStorage("systemUIAccent") private var systemUIAccent = "blue"  // 情報デザイン: System UI accent color

    // View mode - exposed via binding for sidebar integration
    @Binding var isInMonthDetail: Bool
    @State private var selectedMonth: Int? = nil  // nil = show grid, Int = show month detail

    // Custom init to allow the binding
    init(isInMonthDetail: Binding<Bool>) {
        self._isInMonthDetail = isInMonthDetail
    }

    // Year selection
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    // 情報デザイン: Computed date for selected month (for unified entry creator)
    private var selectedMonthDate: Date {
        let month = selectedMonth ?? Calendar.current.component(.month, from: Date())
        return Calendar.current.date(from: DateComponents(year: selectedYear, month: month, day: 1)) ?? Date()
    }

    // Editor state
    @State private var isPresentingNewSpecialDay = false
    @State private var newSpecialDayType: SpecialDayType = .holiday
    @State private var editingSpecialDay: EditingSpecialDay?

    // Undo functionality
    @State private var deletedSpecialDay: DeletedSpecialDay?
    @State private var showUndoToast = false

    // Type-specific editors
    @State private var editingContact: Contact?  // For BDY (birthday)
    @State private var editingMemo: Memo?         // For unified memos

    // Item expansion state (情報デザイン: tap to show details)
    @State private var expandedItemID: String?

    // 情報デザイン: Tappable stat indicators show type name
    // Removed: selectedStatType (now using popovers)

    // 情報デザイン: Holiday Database Explorer
    @State private var showingDatabaseExplorer = false

    // 情報デザイン: Special day detail sheet
    @State private var selectedDetailItem: SpecialDayRow?

    // 情報デザイン: Region quick picker expansion
    @State private var isRegionPickerExpanded = false

    // 情報デザイン: Personal month label editing
    @State private var editingMonthLabel: MonthLabelEdit? = nil

    // 情報デザイン: Category filter toggles (tap stat icons to filter)
    @State private var activeFilters: Set<DisplayCategory> = [.holiday, .observance, .memo]

    // 情報デザイン: Category navigation within month (nil = show category cards, set = show filtered list)
    @State private var selectedCategory: DisplayCategory? = nil

    // 情報デザイン: FAB for creating custom holidays/observances
    @State private var showingHolidayCreator = false

    private var years: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 20)...(current + 20))
    }

    // 情報デザイン: Month customization storage helpers
    private var monthCustomizations: [Int: MonthCustomization] {
        get {
            guard !monthCustomizationsData.isEmpty,
                  let decoded = try? JSONDecoder().decode([Int: MonthCustomization].self, from: monthCustomizationsData) else {
                return [:]
            }
            return decoded
        }
    }

    private func setMonthCustomization(_ customization: MonthCustomization?, for month: Int) {
        var customizations = monthCustomizations
        if let customization = customization {
            customizations[month] = customization
        } else {
            customizations.removeValue(forKey: month)
        }
        if let encoded = try? JSONEncoder().encode(customizations) {
            monthCustomizationsData = encoded
        }
    }

    private func customIcon(for month: Int) -> String? {
        monthCustomizations[month]?.icon
    }

    private func customIconColor(for month: Int) -> String? {
        monthCustomizations[month]?.iconColorHex
    }

    private func customColor(for month: Int) -> String? {
        monthCustomizations[month]?.colorHex
    }

    private func customMessage(for month: Int) -> String? {
        monthCustomizations[month]?.message
    }

    // 情報デザイン: Category customization storage helpers
    private var categoryCustomizations: [String: CategoryCustomization] {
        get {
            guard !categoryCustomizationsData.isEmpty,
                  let decoded = try? JSONDecoder().decode([String: CategoryCustomization].self, from: categoryCustomizationsData) else {
                return [:]
            }
            return decoded
        }
    }

    private func setCategoryCustomization(_ customization: CategoryCustomization?, for category: DisplayCategory) {
        var customizations = categoryCustomizations
        if let customization = customization {
            customizations[category.rawValue] = customization
        } else {
            customizations.removeValue(forKey: category.rawValue)
        }
        if let encoded = try? JSONEncoder().encode(customizations) {
            categoryCustomizationsData = encoded
        }
    }

    private func customCategoryIcon(for category: DisplayCategory) -> String? {
        categoryCustomizations[category.rawValue]?.icon
    }

    @State private var editingCategoryLabel: DisplayCategory? = nil

    // 情報デザイン: Force refresh when customizations change (SwiftUI dependency workaround)
    private var categoryCustomizationsVersion: Int {
        categoryCustomizationsData.hashValue
    }

    // MARK: - Computed Data

    private func rows(for type: SpecialDayType) -> [SpecialDayRow] {
        let calendar = Calendar.current

        // Handle memo type (unified: notes, events, trips, expenses)
        if type == .memo {
            return memos
                .filter { calendar.component(.year, from: $0.date) == selectedYear }
                .map { memo in
                    SpecialDayRow(
                        id: "memo-\(memo.id.uuidString)",
                        ruleID: memo.id.uuidString,
                        region: "",
                        date: memo.date,
                        title: memo.preview,
                        type: .memo,
                        symbolName: memo.hasMoney ? "yensign.circle.fill" : (memo.hasPlace ? "mappin.circle.fill" : "note.text"),
                        iconColor: memo.colorHex,
                        notes: memo.text,
                        isCustom: true,
                        isMemo: true,
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
                        isMemo: false,
                        originalBirthday: birthday,
                        turningAge: ageAtBirthday
                    )
                }
                .sorted { $0.date < $1.date }
        }

        // Handle holidays and observances
        let isBankHoliday = type.isBankHoliday

        return holidayManager.holidayCache
            .filter { (date, _) in calendar.component(.year, from: date) == selectedYear }
            .sorted(by: { $0.key < $1.key })
            .flatMap { (date, holidays) in
                holidays.filter { $0.isBankHoliday == isBankHoliday }.map { holiday in
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
                        isMemo: false,
                        originalBirthday: nil,
                        turningAge: nil
                    )
                }
            }
    }

    private var holidayCount: Int { rows(for: .holiday).count }
    private var observanceCount: Int { rows(for: .observance).count }
    private var birthdayCount: Int { rows(for: .birthday).count }
    private var memoCount: Int { rows(for: .memo).count }

    // MARK: - Unique Date Counting (情報デザイン: Show unique dates, not duplicate regional variants)

    /// Count unique dates for a category (Dec 24 = 1 holiday, not 5 regional variants)
    private func uniqueDateCount(for category: DisplayCategory) -> Int {
        let calendar = Calendar.current
        var uniqueDates = Set<DateComponents>()

        switch category {
        case .holiday:
            for row in rows(for: .holiday) {
                let components = calendar.dateComponents([.year, .month, .day], from: row.date)
                uniqueDates.insert(components)
            }
        case .observance:
            for row in rows(for: .observance) {
                let components = calendar.dateComponents([.year, .month, .day], from: row.date)
                uniqueDates.insert(components)
            }
        case .memo:
            // Memos + birthdays combined
            for row in rows(for: .birthday) {
                let components = calendar.dateComponents([.year, .month, .day], from: row.date)
                uniqueDates.insert(components)
            }
            for row in rows(for: .memo) {
                let components = calendar.dateComponents([.year, .month, .day], from: row.date)
                uniqueDates.insert(components)
            }
        }
        return uniqueDates.count
    }

    /// Unique holiday date count
    private var uniqueHolidayCount: Int { uniqueDateCount(for: .holiday) }
    /// Unique observance date count
    private var uniqueObservanceCount: Int { uniqueDateCount(for: .observance) }
    /// Unique memo date count (includes birthdays)
    private var uniqueMemoCount: Int { uniqueDateCount(for: .memo) }

    /// 情報デザイン: Compact subtitle that fits iPhone screens
    private var compactSubtitle: String {
        var parts: [String] = []
        if holidayCount > 0 { parts.append("\(holidayCount) holidays") }
        if observanceCount > 0 { parts.append("\(observanceCount) observances") }
        if birthdayCount > 0 { parts.append("\(birthdayCount) birthdays") }
        if memoCount > 0 { parts.append("\(memoCount) memos") }

        if parts.isEmpty {
            return "No entries yet"
        }

        // Join with bullets for better iPhone readability
        return parts.joined(separator: " • ")
    }

    /// Get counts for a specific month
    private func monthCounts(for month: Int) -> (holidays: Int, observances: Int, birthdays: Int, memos: Int) {
        let calendar = Calendar.current
        let allHolidays = rows(for: .holiday).filter { calendar.component(.month, from: $0.date) == month }
        let allObservances = rows(for: .observance).filter { calendar.component(.month, from: $0.date) == month }
        let allBirthdays = rows(for: .birthday).filter { calendar.component(.month, from: $0.date) == month }
        let allMemos = rows(for: .memo).filter { calendar.component(.month, from: $0.date) == month }
        return (allHolidays.count, allObservances.count, allBirthdays.count, allMemos.count)
    }

    /// 情報デザイン: Get UNIQUE date counts for a specific month by category
    /// Shows unique dates, not duplicate regional variants (Dec 24 = 1 holiday, not 5)
    private func monthUniqueCounts(for month: Int) -> (holidays: Int, observances: Int, memos: Int) {
        let calendar = Calendar.current

        func uniqueDates(for type: SpecialDayType) -> Int {
            var dates = Set<DateComponents>()
            for row in rows(for: type) where calendar.component(.month, from: row.date) == month {
                dates.insert(calendar.dateComponents([.year, .month, .day], from: row.date))
            }
            return dates.count
        }

        let holidays = uniqueDates(for: .holiday)
        let observances = uniqueDates(for: .observance)

        // Memos combine birthdays + memos
        var memoDates = Set<DateComponents>()
        for row in rows(for: .birthday) where calendar.component(.month, from: row.date) == month {
            memoDates.insert(calendar.dateComponents([.year, .month, .day], from: row.date))
        }
        for row in rows(for: .memo) where calendar.component(.month, from: row.date) == month {
            memoDates.insert(calendar.dateComponents([.year, .month, .day], from: row.date))
        }

        return (holidays, observances, memoDates.count)
    }

    /// Get rows for a specific month, filtered by active category filters
    private func rowsForMonth(_ month: Int) -> [SpecialDayRow] {
        let calendar = Calendar.current
        var result: [SpecialDayRow] = []

        // 情報デザイン: Only include categories that are active in the filter
        if activeFilters.contains(.holiday) {
            result += rows(for: .holiday).filter { calendar.component(.month, from: $0.date) == month }
        }
        if activeFilters.contains(.observance) {
            result += rows(for: .observance).filter { calendar.component(.month, from: $0.date) == month }
        }
        if activeFilters.contains(.memo) {
            // Memo category includes birthdays + memos
            result += rows(for: .birthday).filter { calendar.component(.month, from: $0.date) == month }
            result += rows(for: .memo).filter { calendar.component(.month, from: $0.date) == month }
        }

        return result.sorted { $0.date < $1.date }
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
            .sheet(item: $editingMemo) { memo in memoEditorSheet(memo) }
            .sheet(isPresented: $showingDatabaseExplorer) { HolidayDatabaseExplorer() }
            .sheet(item: $selectedDetailItem) { item in SpecialDayDetailSheet(item: item) }
            .sheet(item: $editingMonthLabel) { edit in monthLabelEditorSheet(for: edit.month) }
            .sheet(isPresented: $showingHolidayCreator) { holidayCreatorSheet }
            .overlay(alignment: .bottom) { undoToastOverlay }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                headerWithYearPicker

                // 情報デザイン: Inline region picker (replaces globe navigation)
                if selectedMonth == nil && showHolidays {
                    regionQuickPickerSection
                }

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
        .onDisappear {
            // 情報デザイン: Reset to year overview when leaving Star tab
            selectedMonth = nil
            selectedCategory = nil
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

    private func memoEditorSheet(_ memo: Memo) -> some View {
        MemoEditorView(date: memo.date, existingMemo: memo)
            .presentationCornerRadius(20)
    }

    // 情報デザイン: Holiday/observance creator sheet (triggered from subtitle plus buttons)
    private var holidayCreatorSheet: some View {
        // Use newSpecialDayType which is set by addCategoryButton
        let type: SpecialDayType = newSpecialDayType
        return JohoSpecialDayEditorSheet(
            mode: .create,
            type: type,
            defaultRegion: holidayRegions.primaryRegion ?? "SE",
            onSave: { name, date, symbol, iconColor, notes, region in
                createCustomHoliday(type: type, name: name, date: date, symbol: symbol, notes: notes, region: region)
            }
        )
        .presentationCornerRadius(20)
    }

    /// 情報デザイン: Create a custom holiday/observance linked to a region
    private func createCustomHoliday(type: SpecialDayType, name: String, date: Date, symbol: String, notes: String?, region: String) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let rule = HolidayRule(
            name: name,
            region: region,
            isBankHoliday: type == .holiday,
            titleOverride: name,
            symbolName: symbol,
            iconColor: nil,
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
            Log.w("Failed to create custom holiday: \(error.localizedDescription)")
            HapticManager.notification(.error)
        }
    }

    // 情報デザイン: Personal month label editor
    private func monthLabelEditorSheet(for month: Int) -> some View {
        MonthCustomizationSheet(
            month: month,
            currentCustomization: monthCustomizations[month] ?? MonthCustomization(),
            onSave: { customization in
                // Save if any customization is set (icon, icon color, or message)
                // Note: colorHex is locked to seasonal theme (季節の色)
                if customization.icon != nil || customization.iconColorHex != nil || customization.message != nil {
                    setMonthCustomization(customization, for: month)
                } else {
                    setMonthCustomization(nil, for: month)
                }
                editingMonthLabel = nil
            },
            onCancel: {
                editingMonthLabel = nil
            },
            onReset: {
                setMonthCustomization(nil, for: month)
                editingMonthLabel = nil
            }
        )
        .presentationDetents([.height(520)])
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

    // MARK: - Header with Year Picker (情報デザイン: Bento Compartments)

    private var headerWithYearPicker: some View {
        let theme: MonthTheme? = selectedMonth.map { MonthTheme.theme(for: $0) }

        return VStack(spacing: 0) {
            // TOP ROW: Back button (if needed) + Icon + Title | WALL | Year Picker
            HStack(spacing: 0) {
                // LEFT COMPARTMENT: Navigation + Icon + Title
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Back button when in month detail or category view
                    if selectedMonth != nil {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                // 情報デザイン: Two-level navigation
                                // If in category view, go back to category cards
                                // If in category cards, go back to month grid
                                if selectedCategory != nil {
                                    selectedCategory = nil
                                } else {
                                    selectedMonth = nil
                                }
                            }
                            HapticManager.selection()
                        } label: {
                            // 情報デザイン: Minimum 44pt touch target
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(colors.primary)
                                .johoTouchTarget()
                                .background(colors.inputBackground)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                        }
                    }

                    // Icon zone - star for main view, month icon for detail
                    // 情報デザイン: 44pt touch target for consistency
                    if let theme = theme {
                        Image(systemName: theme.icon)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.accentColor)
                            .johoTouchTarget()
                            .background(theme.lightBackground)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                            )
                    } else {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(PageHeaderColor.specialDays.accent)
                            .johoTouchTarget()
                            .background(PageHeaderColor.specialDays.lightBackground)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    // Title
                    if let theme = theme {
                        Text(verbatim: "\(theme.name.uppercased())")
                            .font(JohoFont.headline)
                            .foregroundStyle(colors.primary)
                    } else {
                        Text("SPECIAL DAYS")
                            .font(JohoFont.headline)
                            .foregroundStyle(colors.primary)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

                // VERTICAL WALL (separator)
                Rectangle()
                    .fill(colors.border)
                    .frame(width: 1.5)

                // RIGHT COMPARTMENT: Year Picker
                if selectedMonth == nil {
                    JohoYearPicker(year: $selectedYear)
                } else {
                    // Show year when in month detail (read-only)
                    Text(String(selectedYear))
                        .font(JohoFont.headline)
                        .monospacedDigit()
                        .foregroundStyle(colors.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(width: 100)
                }
            }
            .frame(height: 56)

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // STATS ROW (full width)
            // 情報デザイン: Show colored dots + add buttons when inside a month
            if let month = selectedMonth {
                monthSubtitleRow(for: month)
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .padding(.vertical, JohoDimensions.spacingSM)
            } else {
                HStack(spacing: JohoDimensions.spacingSM) {
                    bentoStatsRow
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: 2)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.top, JohoDimensions.spacingSM)
    }

    // MARK: - Bento Stats Row (情報デザイン: 3-category outline icons)

    /// 情報デザイン: Calculate UNIQUE date counts by DisplayCategory
    /// Shows unique dates, not duplicate regional variants (Dec 24 = 1 holiday, not 5)
    private var displayCategoryCounts: (holidays: Int, observances: Int, memos: Int) {
        return (uniqueHolidayCount, uniqueObservanceCount, uniqueMemoCount)
    }

    private var bentoStatsRow: some View {
        let counts = displayCategoryCounts
        let totalCount = counts.holidays + counts.observances + counts.memos

        return HStack(spacing: JohoDimensions.spacingMD) {
            // 情報デザイン: 3-category outline icons with counts
            // [○ 19]  [◇ 18]  [📄 5]
            //  祝日    記念日    メモ
            if counts.holidays > 0 {
                categoryIndicator(category: .holiday, count: counts.holidays)
            }
            if counts.observances > 0 {
                categoryIndicator(category: .observance, count: counts.observances)
            }
            if counts.memos > 0 {
                categoryIndicator(category: .memo, count: counts.memos)
            }

            // Show empty state only when no entries exist
            if totalCount == 0 {
                Text("No entries yet")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(colors.primary.opacity(0.5))
            }

            Spacer()
        }
    }

    /// 情報デザイン: Month-specific stats row with filter pills
    /// Same behavior as main bentoStatsRow but with month-scoped counts
    private func monthBentoStatsRow(for month: Int) -> some View {
        let counts = monthUniqueCounts(for: month)
        let totalCount = counts.holidays + counts.observances + counts.memos

        return HStack(spacing: JohoDimensions.spacingMD) {
            if counts.holidays > 0 {
                categoryIndicator(category: .holiday, count: counts.holidays)
            }
            if counts.observances > 0 {
                categoryIndicator(category: .observance, count: counts.observances)
            }
            if counts.memos > 0 {
                categoryIndicator(category: .memo, count: counts.memos)
            }

            if totalCount == 0 {
                Text("No entries yet")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(colors.primary.opacity(0.5))
            }

            Spacer()
        }
    }

    // MARK: - Month Subtitle Row (情報デザイン: Colored dots + Add buttons)

    /// 情報デザイン: Subtitle row when viewing a month
    /// Shows colored category dots and plus buttons to add new items
    private func monthSubtitleRow(for month: Int) -> some View {
        let counts = monthUniqueCounts(for: month)

        return HStack(spacing: JohoDimensions.spacingMD) {
            // Category filter dots (tap to filter)
            HStack(spacing: JohoDimensions.spacingSM) {
                // Holidays dot
                monthCategoryDot(
                    category: .holiday,
                    count: counts.holidays,
                    color: DisplayCategory.holiday.accentColor
                )

                // Observances dot
                monthCategoryDot(
                    category: .observance,
                    count: counts.observances,
                    color: DisplayCategory.observance.accentColor
                )

                // Memos dot
                monthCategoryDot(
                    category: .memo,
                    count: counts.memos,
                    color: DisplayCategory.memo.accentColor
                )
            }

            Spacer()

            // 情報デザイン: Unified add button (tap to choose Holiday or Observance)
            unifiedAddButton
        }
    }

    /// 情報デザイン: State for unified add button sheet
    @State private var showingCustomHolidayCreator = false

    /// System UI accent for buttons (database-driven via settings)
    private var systemAccentColor: Color {
        (SystemUIAccent(rawValue: systemUIAccent) ?? .indigo).color
    }

    /// 情報デザイン: Unified add button - uses system UI accent color
    private var unifiedAddButton: some View {
        Button {
            showingCustomHolidayCreator = true
            HapticManager.impact(.light)
        } label: {
            // 情報デザイン: System UI accent plus button (matches date picker)
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(systemAccentColor)
                .clipShape(Circle())
                .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingCustomHolidayCreator) {
            // 情報デザイン: Unified entry creator for full context (Holiday/Observance/Memo)
            UnifiedEntryCreator(
                config: .fullContext(
                    date: selectedMonthDate,
                    holidayIcon: customCategoryIcon(for: .holiday) ?? DisplayCategory.holiday.outlineIcon,
                    observanceIcon: customCategoryIcon(for: .observance) ?? DisplayCategory.observance.outlineIcon,
                    memoIcon: customCategoryIcon(for: .memo) ?? DisplayCategory.memo.outlineIcon,
                    enabledRegions: holidayRegions.regions
                ),
                onSaveHoliday: { type, name, about, region, year, month, day in
                    createCustomHoliday(type: type, name: name, about: about, region: region, year: year, month: month, day: day)
                },
                onSaveMemo: { text, date, amount, currency, place, contactID, photoData in
                    createMemo(text: text, date: date, amount: amount, currency: currency, place: place, contactID: contactID, photoData: photoData)
                }
            )
            .presentationDetents([.large])
            .presentationCornerRadius(20)
        }
    }

    /// 情報デザイン: Create a custom holiday/observance from user input
    private func createCustomHoliday(type: SpecialDayType, name: String, about: String?, region: String, year: Int, month: Int, day: Int) {
        let rule = HolidayRule(
            name: name,
            region: region,
            isBankHoliday: type == .holiday,
            titleOverride: name,
            notes: about,
            type: .fixed,
            month: month,
            day: day,
            isSystemDefault: false,
            isEnabled: true
        )
        rule.userModifiedAt = Date()

        modelContext.insert(rule)
        try? modelContext.save()

        // Refresh cache
        holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
        HapticManager.notification(.success)
    }

    /// 情報デザイン: Create a memo from unified entry creator
    private func createMemo(text: String, date: Date, amount: Double?, currency: String?, place: String?, contactID: UUID?, photoData: Data?) {
        let memo = Memo(text: text, date: date)
        memo.amount = amount
        memo.currency = currency
        memo.place = place
        memo.linkedContactID = contactID
        memo.photoData = photoData
        modelContext.insert(memo)
        try? modelContext.save()
        HapticManager.notification(.success)
    }

    /// 情報デザイン: Category dot with count (tap to filter)
    private func monthCategoryDot(category: DisplayCategory, count: Int, color: Color) -> some View {
        let isSelected = selectedCategory == category
        let hasItems = count > 0

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedCategory == category {
                    selectedCategory = nil  // Deselect to show category cards
                } else {
                    selectedCategory = category
                }
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(hasItems && (isSelected || selectedCategory == nil) ? color : colors.inputBackground)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(colors.border, lineWidth: 1))

                Text("\(count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(hasItems ? colors.primary : colors.primary.opacity(0.4))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? color.opacity(0.3) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? colors.border : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(hasItems ? 1.0 : 0.5)
    }

    // MARK: - Region Quick Picker Section

    private var regionQuickPickerSection: some View {
        RegionQuickPicker(selectedRegions: $holidayRegions)
            .padding(.horizontal, JohoDimensions.spacingLG)
    }

    /// 情報デザイン: Active popover tracking for categories
    @State private var activePopoverCategory: DisplayCategory?

    /// 情報デザイン: Compact category indicator (subtitle-style)
    /// Colored dot + count - TAP TO TOGGLE FILTER
    /// When active: Shows full label (e.g., "● Holidays 36")
    /// When inactive: Shows only dot + count (e.g., "○ 36")
    private func categoryIndicator(category: DisplayCategory, count: Int) -> some View {
        let isActive = activeFilters.contains(category)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                HapticManager.selection()
                // Toggle filter state
                if activeFilters.contains(category) {
                    // Don't allow disabling the last active filter
                    if activeFilters.count > 1 {
                        activeFilters.remove(category)
                    }
                } else {
                    activeFilters.insert(category)
                }
            }
        } label: {
            HStack(spacing: 4) {
                // Colored filled dot (category color) - dimmed when inactive
                Circle()
                    .fill(isActive ? category.accentColor : colors.primary.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(colors.border, lineWidth: 0.5)
                    )

                // 情報デザイン: Show full label only when active (tap reveals meaning)
                if isActive {
                    Text(category.localizedLabel)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .lineLimit(1)
                }

                // Count numeral - dimmed when inactive
                Text(String(count))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isActive ? colors.primary : colors.primary.opacity(0.4))
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(isActive ? category.accentColor.opacity(0.12) : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isActive ? colors.border : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.localizedLabel): \(count)")
        .accessibilityHint(isActive ? "Tap to hide \(category.localizedLabel)" : "Tap to show \(category.localizedLabel)")
    }

    /// 情報デザイン: Compact popover showing category details
    /// Icons are database-driven via customCategoryIcon(for:)
    private func categoryPopover(category: DisplayCategory, count: Int) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: customCategoryIcon(for: category) ?? category.outlineIcon)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .frame(width: 32, height: 32)
                .background(colors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(colors.border, lineWidth: 1.5)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(category.localizedLabel.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(colors.primary)

                Text("\(count) in " + String(selectedYear))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.7))
            }
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .presentationCompactAdaptation(.popover)
    }

    /// 情報デザイン: Icon-only stat indicator with popover details (legacy)
    @State private var activePopoverType: SpecialDayType?

    private func statIndicator(type: SpecialDayType, count: Int) -> some View {
        Button {
            HapticManager.selection()
            activePopoverType = type
        } label: {
            HStack(spacing: 4) {
                Image(systemName: type.defaultIcon)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(type.accentColor)

                Text(String(count))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(colors.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(type.lightBackground.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .popover(isPresented: Binding(
            get: { activePopoverType == type },
            set: { if !$0 { activePopoverType = nil } }
        )) {
            statPopover(type: type, count: count)
        }
        .accessibilityLabel("\(type.title): \(count)")
        .accessibilityHint("Tap for details")
    }

    /// 情報デザイン: Compact popover showing type details
    private func statPopover(type: SpecialDayType, count: Int) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Image(systemName: type.defaultIcon)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(type.accentColor)
                .frame(width: 32, height: 32)
                .background(type.lightBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(type.accentColor, lineWidth: 1.5)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(type.title.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(colors.primary)

                Text("\(count) in " + String(selectedYear))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(type.accentColor)
            }
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .presentationCompactAdaptation(.popover)
    }

    /// 情報デザイン: Category-colored dots for month cards
    /// Each dot represents a category present in this month:
    /// - Pink = holidays, Cyan = observances, Yellow = memos
    private func monthCategoryDots(holidays: Int, observances: Int, memos: Int) -> some View {
        HStack(spacing: 3) {
            if holidays > 0 {
                Circle()
                    .fill(DisplayCategory.holiday.accentColor)
                    .frame(width: 6, height: 6)
                    .overlay(Circle().stroke(colors.border, lineWidth: 0.5))
            }
            if observances > 0 {
                Circle()
                    .fill(DisplayCategory.observance.accentColor)
                    .frame(width: 6, height: 6)
                    .overlay(Circle().stroke(colors.border, lineWidth: 0.5))
            }
            if memos > 0 {
                Circle()
                    .fill(DisplayCategory.memo.accentColor)
                    .frame(width: 6, height: 6)
                    .overlay(Circle().stroke(colors.border, lineWidth: 0.5))
            }
        }
    }

    /// 情報デザイン: Clean colored dot for month cards (legacy - maintains symmetry)
    private func monthCardDot(type: SpecialDayType, count: Int) -> some View {
        Circle()
            .fill(type.accentColor)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(colors.border, lineWidth: 0.5)
            )
            .accessibilityLabel("\(count) \(type.title)")
    }

    // MARK: - Month Grid (情報デザイン: 12 Month Flipcards in 3-Column Bento)

    private var monthGrid: some View {
        // 情報デザイン: Use Grid (not LazyVGrid) for automatic row height synchronization
        Grid(horizontalSpacing: JohoDimensions.spacingSM, verticalSpacing: JohoDimensions.spacingSM) {
            ForEach(0..<4, id: \.self) { row in
                GridRow {
                    ForEach(1...3, id: \.self) { col in
                        let month = row * 3 + col
                        monthFlipcard(for: month)
                    }
                }
            }
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Month Flipcard (情報デザイン: Compartmentalized Bento Style)

    @ViewBuilder
    private func monthFlipcard(for month: Int) -> some View {
        let theme = MonthTheme.theme(for: month)
        let counts = monthCounts(for: month)
        let totalCount = counts.holidays + counts.observances + counts.birthdays + counts.memos
        let hasItems = totalCount > 0

        // 情報デザイン: Allow custom icon and icon color (background color locked to seasonal theme)
        let displayIcon = customIcon(for: month) ?? theme.icon
        let customIconColorHex = customIconColor(for: month)
        // 情報デザイン: Custom icon color takes priority, then always theme accent (季節の色 defines identity)
        let displayIconColor: Color = {
            if let hex = customIconColorHex {
                return Color(hex: hex)
            } else {
                return theme.accentColor
            }
        }()
        // 情報デザイン: Banner color is LOCKED to seasonal theme (users cannot change it)
        let displayColor: Color = theme.lightBackground
        let message = customMessage(for: month)

        VStack(spacing: 0) {
            // TOP: Icon zone (情報デザイン: Strong accent color on light tint background)
            // Fixed height ensures banner dividers align across all cards
            VStack {
                Image(systemName: displayIcon)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(displayIconColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)  // Fixed height for aligned banners
            .background(displayColor)

            // Divider (情報デザイン: Black wall between compartments)
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // BOTTOM: Centered text with stacked dots in corner
            // Fixed height ensures all card bottoms align
            HStack(spacing: 0) {
                Spacer(minLength: 16)

                // Centered text
                VStack(spacing: 2) {
                    Text(theme.name.uppercased())
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .multilineTextAlignment(.center)

                    // Custom message (always rendered, invisible when empty for height consistency)
                    Text(message ?? " ")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(message != nil ? 0.6 : 0))
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)  // Fixed height for aligned bottoms
            .background(colors.surface)
            .overlay(alignment: .bottomTrailing) {
                // 情報デザイン: Vertical dot stack with black borders (holidays → observances → memos)
                if hasItems {
                    VStack(spacing: 3) {
                        if counts.holidays > 0 {
                            Circle()
                                .fill(DisplayCategory.holiday.accentColor)
                                .frame(width: 7, height: 7)
                                .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        }
                        if counts.observances > 0 {
                            Circle()
                                .fill(DisplayCategory.observance.accentColor)
                                .frame(width: 7, height: 7)
                                .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        }
                        if (counts.birthdays + counts.memos) > 0 {
                            Circle()
                                .fill(DisplayCategory.memo.accentColor)
                                .frame(width: 7, height: 7)
                                .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        }
                    }
                    .padding(.trailing, 6)
                    .padding(.bottom, 6)
                }
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        // 情報デザイン: NO opacity change - colors define identity regardless of content
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    HapticManager.impact(.medium)
                    editingMonthLabel = MonthLabelEdit(id: month)
                }
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedMonth = month
            }
            HapticManager.selection()
        }
    }

    // MARK: - Month Detail View (情報デザイン: Category Cards → Filtered List)

    @State private var expandedDays: Set<String> = []

    @ViewBuilder
    private func monthDetailView(for month: Int) -> some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            if selectedCategory == nil {
                // 情報デザイン: Show category cards grid (mirrors month grid structure)
                categoryCardsGrid(for: month)
            } else {
                // Show filtered day cards for selected category
                let dayCards = filteredDayCardsForMonth(month, category: selectedCategory!)

                if dayCards.isEmpty {
                    // 情報デザイン: Use customized icon if set, otherwise default
                    let displayIcon = customCategoryIcon(for: selectedCategory!) ?? selectedCategory!.outlineIcon
                    JohoEmptyState(
                        title: "No \(selectedCategory!.localizedLabel)",
                        message: "Tap + to add",
                        icon: displayIcon,
                        zone: selectedCategory!.sectionZone
                    )
                    .padding(.top, JohoDimensions.spacingSM)
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
                                showDetail: { item in selectedDetailItem = item },
                                holidayIcon: customCategoryIcon(for: .holiday) ?? DisplayCategory.holiday.outlineIcon,
                                observanceIcon: customCategoryIcon(for: .observance) ?? DisplayCategory.observance.outlineIcon,
                                memoIcon: customCategoryIcon(for: .memo) ?? DisplayCategory.memo.outlineIcon,
                                expandedItemID: $expandedItemID
                            )
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }
            }
        }
        .onAppear { initializeExpandedDays(for: dayCardsForMonth(month)) }
        .onChange(of: selectedMonth) { _, _ in
            expandedDays.removeAll()
            selectedCategory = nil
            initializeExpandedDays(for: dayCardsForMonth(month))
        }
        .onChange(of: selectedCategory) { _, _ in
            expandedDays.removeAll()
            if let month = selectedMonth {
                let dayCards = selectedCategory != nil
                    ? filteredDayCardsForMonth(month, category: selectedCategory!)
                    : dayCardsForMonth(month)
                initializeExpandedDays(for: dayCards)
            }
        }
    }

    // MARK: - Category Cards Grid (情報デザイン: Bento cards mirroring month grid)

    @ViewBuilder
    private func categoryCardsGrid(for month: Int) -> some View {
        let counts = monthUniqueCounts(for: month)

        // 情報デザイン: Grid (not LazyVGrid) ensures synchronized row heights
        Grid(horizontalSpacing: JohoDimensions.spacingSM, verticalSpacing: JohoDimensions.spacingSM) {
            GridRow {
                categoryCard(category: .holiday, count: counts.holidays)
                categoryCard(category: .observance, count: counts.observances)
                categoryCard(category: .memo, count: counts.memos)
            }
        }
        .id(categoryCustomizationsVersion)  // 情報デザイン: Force refresh when customizations change
        .padding(.horizontal, JohoDimensions.spacingLG)
        .sheet(item: $editingCategoryLabel) { category in
            let counts = monthUniqueCounts(for: selectedMonth ?? 1)
            let count: Int = {
                switch category {
                case .holiday: return counts.holidays
                case .observance: return counts.observances
                case .memo: return counts.memos
                }
            }()
            CategoryCustomizationSheet(
                category: category,
                count: count,
                currentCustomization: categoryCustomizations[category.rawValue] ?? CategoryCustomization(),
                onSave: { customization in
                    if customization.icon == nil {
                        setCategoryCustomization(nil, for: category)
                    } else {
                        setCategoryCustomization(customization, for: category)
                    }
                    editingCategoryLabel = nil
                },
                onReset: {
                    setCategoryCustomization(nil, for: category)
                    editingCategoryLabel = nil
                },
                onDismiss: {
                    editingCategoryLabel = nil
                }
            )
            .presentationCornerRadius(20)
        }
    }

    // MARK: - Category Card (情報デザイン: Bento card mirroring month flipcard)

    @ViewBuilder
    private func categoryCard(category: DisplayCategory, count: Int) -> some View {
        // 情報デザイン: Custom icon allowed, color locked to category
        let displayIcon = customCategoryIcon(for: category) ?? category.outlineIcon
        let categoryColor = category.accentColor

        VStack(spacing: 0) {
            // TOP: Icon zone (情報デザイン: Category color background)
            // Fixed height ensures banner dividers align across all cards
            VStack {
                Image(systemName: displayIcon)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)  // Fixed height for aligned banners
            .background(categoryColor)

            // Divider (情報デザイン: Black wall between compartments)
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // BOTTOM: Category name + count (情報デザイン: Like message on month cards)
            // minHeight ensures all cards end at same line
            HStack(spacing: 0) {
                Spacer(minLength: 16)

                VStack(spacing: 2) {
                    Text(category.localizedLabel.uppercased())
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .multilineTextAlignment(.center)

                    // Count always rendered for consistent height (invisible when 0)
                    Text(count > 0 ? "\(count)" : " ")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(count > 0 ? 0.6 : 0))
                }

                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(colors.surface)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        // 情報デザイン: NO opacity change - colors define identity regardless of content
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    HapticManager.impact(.medium)
                    editingCategoryLabel = category
                }
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
            HapticManager.selection()
        }
    }

    // MARK: - Filtered Day Cards (情報デザイン: Filter by category)

    private func filteredDayCardsForMonth(_ month: Int, category: DisplayCategory) -> [DayCardData] {
        let allCards = dayCardsForMonth(month)

        return allCards.compactMap { card -> DayCardData? in
            let filteredItems = card.items.filter { item in
                switch category {
                case .holiday:
                    return item.type == .holiday
                case .observance:
                    return item.type == .observance
                case .memo:
                    return item.type == .memo || item.type == .birthday
                }
            }

            guard !filteredItems.isEmpty else {
                return nil
            }

            return DayCardData(
                id: card.id,
                date: card.date,
                day: card.day,
                items: filteredItems
            )
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
            // Only auto-expand TODAY (情報デザイン: minimal default expansion)
            if cardDay == today {
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
    let showDetail: (SpecialDayRow) -> Void

    // Category icons (database-driven via customCategoryIcon in parent)
    let holidayIcon: String
    let observanceIcon: String
    let memoIcon: String

    // Item expansion state (情報デザイン: tap row to show details)
    @Binding var expandedItemID: String?

    // Locale for displaying localized holiday names (情報デザイン: show user's locale name)
    @Environment(\.locale) private var locale
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
    private var birthdays: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .birthday }
    }
    private var memosForDay: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .memo }
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

    /// Date status pill for the day header (情報デザイン: Only TODAY highlighted)
    @ViewBuilder
    private var dateStatusPill: some View {
        if daysFromToday == 0 {
            // TODAY - Yellow inverted pill (only status worth highlighting)
            JohoPill(text: "TODAY", style: .coloredInverted(JohoColors.yellow), size: .small)
        }
        // Past/future dates: no pill needed (date is already visible)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row (always visible)
            headerRow

            // Expanded content
            if isExpanded {
                // Thin divider
                Rectangle()
                    .fill(colors.border.opacity(0.15))
                    .frame(height: 1)

                expandedContent
                    .padding(.top, JohoDimensions.spacingSM)
                    .padding(.bottom, JohoDimensions.spacingMD)
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: isToday ? JohoDimensions.borderThick : JohoDimensions.borderMedium)
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
                    .foregroundStyle(colors.primary)

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
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
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
        .foregroundStyle(isToday ? Color.black : colors.primary)
        .padding(.horizontal, JohoDimensions.spacingSM)
        .padding(.vertical, JohoDimensions.spacingXS)
        .background(isToday ? JohoColors.yellow : colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
        )
    }

    // MARK: - Content Indicator Icons (情報デザイン: Black outline shapes)

    private var contentIndicatorDots: some View {
        HStack(spacing: 6) {
            // 情報デザイン: 3-category indicator system
            // Colored dots are FIXED (pink, cyan, yellow) - colors encode category meaning
            // Icons are separate and customizable via database

            // Holidays - Red dot
            if holidays.isNotEmpty {
                HStack(spacing: 2) {
                    Circle()
                        .fill(DisplayCategory.holiday.accentColor)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(colors.border, lineWidth: 0.5))
                    Text("\(holidays.count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                }
            }

            // Observances - Blue dot
            if observances.isNotEmpty {
                HStack(spacing: 2) {
                    Circle()
                        .fill(DisplayCategory.observance.accentColor)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(colors.border, lineWidth: 0.5))
                    Text("\(observances.count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                }
            }

            // Memos + Birthdays - Green dot
            if birthdays.isNotEmpty || memosForDay.isNotEmpty {
                HStack(spacing: 2) {
                    Circle()
                        .fill(DisplayCategory.memo.accentColor)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(colors.border, lineWidth: 0.5))
                    Text("\(birthdays.count + memosForDay.count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                }
            }
        }
    }

    // MARK: - Expanded Content

    /// Combined birthdays + memos for 情報デザイン 3-category system
    private var combinedMemos: [SpecialDayRow] {
        // Birthdays + memos combined under メモ category (YELLOW = now/personal)
        (birthdays + memosForDay).sorted { $0.date < $1.date }
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            // 情報デザイン: 3-category system
            // PINK = Celebration (holidays, observances)
            // YELLOW = Now/Personal (memos + birthdays)

            // Icons are database-driven via customCategoryIcon(for:)
            // Fallback to DisplayCategory.outlineIcon only if no custom icon set

            // Holidays (PINK zone)
            // Icons are database-driven - passed from parent via holidayIcon/observanceIcon/memoIcon

            if consolidatedHolidays.isNotEmpty {
                consolidatedHolidaySection(
                    title: DisplayCategory.holiday.localizedLabel,
                    items: consolidatedHolidays,
                    zone: .holidays,
                    icon: holidayIcon
                )
            }

            // Observances (CYAN zone)
            if observances.isNotEmpty {
                specialDaySection(
                    title: DisplayCategory.observance.localizedLabel,
                    items: observances,
                    zone: .observances,
                    icon: observanceIcon
                )
            }

            // Memos (YELLOW zone - includes birthdays)
            if combinedMemos.isNotEmpty {
                specialDaySection(
                    title: DisplayCategory.memo.localizedLabel,
                    items: combinedMemos,
                    zone: .notes,
                    icon: memoIcon
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
                    .fill(colors.border)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Icon compartment
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 40)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 32)
            .background(zone.background(for: colorMode).opacity(0.5))  // Colored header

            // Horizontal divider between header and items
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Items on WHITE background (情報デザイン: white content backgrounds)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    specialDayItemRow(item, zone: zone)

                    // Divider between items (not after last)
                    if index < items.count - 1 {
                        Rectangle()
                            .fill(colors.border.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, 6)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(colors.surface)  // WHITE body instead of colored
        }
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
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
                    .fill(colors.border)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Icon compartment
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 40)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 32)
            .background(zone.background(for: colorMode).opacity(0.5))  // Colored header

            // Horizontal divider between header and items
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Items on WHITE background (情報デザイン: white content backgrounds)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    consolidatedHolidayRow(item, zone: zone)

                    // Divider between items (not after last)
                    if index < items.count - 1 {
                        Rectangle()
                            .fill(colors.border.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, 6)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(colors.surface)  // WHITE body instead of colored
        }
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
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
        HStack(spacing: JohoDimensions.spacingSM) {
            // Holiday name (情報デザイン: icon already in header, no need to repeat)
            Text(item.displayName(for: locale))
                .padding(.leading, JohoDimensions.spacingMD)
                .font(JohoFont.body)
                .foregroundStyle(colors.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            // Region codes as plain text (情報デザイン: Clean, minimal)
            regionCodesText(regions: item.regions)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        // 情報デザイン: Tap shows detail sheet for first item in consolidated group
        .onTapGesture {
            if let firstItem = item.sourceRows.first {
                showDetail(firstItem)
                HapticManager.selection()
            }
        }
    }

    // MARK: - Region Codes Text (情報デザイン: Clean plain text codes)

    /// Shows region codes as plain text ("NO SE FI") with optional overflow indicator
    @ViewBuilder
    private func regionCodesText(regions: [String]) -> some View {
        let maxVisible = 4
        let visibleRegions = Array(regions.prefix(maxVisible))
        let overflowCount = regions.count - maxVisible

        HStack(spacing: 4) {
            Text(visibleRegions.joined(separator: " "))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary.opacity(0.6))

            if overflowCount > 0 {
                Text("+\(overflowCount)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.4))
            }
        }
        .padding(.trailing, JohoDimensions.spacingMD)
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
            // MAIN ROW (情報デザイン: vertical growth, no truncation)
            HStack(alignment: .top, spacing: JohoDimensions.spacingSM) {
                // Content area - grows vertically as needed
                if item.type == .birthday {
                    // Birthday: two-line layout (name + 🎂 age)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(JohoFont.body)
                            .foregroundStyle(colors.primary)
                        if let age = item.turningAge {
                            // 情報デザイン: Icon + number (no words needed)
                            HStack(spacing: 4) {
                                Image(systemName: "birthday.cake")
                                    .font(.system(size: 10, weight: .medium))
                                Text("\(age)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(colors.primary.opacity(0.6))
                        }
                    }
                    .padding(.leading, JohoDimensions.spacingMD)
                } else {
                    // Regular memo/observance: single text, wraps vertically
                    Text(item.title)
                        .font(JohoFont.body)
                        .padding(.leading, JohoDimensions.spacingMD)
                        .foregroundStyle(colors.primary)
                }

                Spacer(minLength: 8)

                // Region code as plain text (情報デザイン: Clean, minimal)
                if item.hasCountryPill {
                    Text(item.region)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.6))
                        .padding(.trailing, JohoDimensions.spacingMD)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            // 情報デザイン: Tap shows detail sheet, long-press expands inline
            .contentShape(Rectangle())
            .onTapGesture {
                showDetail(item)
                HapticManager.selection()
            }
            .onLongPressGesture(minimumDuration: 0.3) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedItemID = isExpanded ? nil : item.id
                }
                HapticManager.impact(.light)
            }

            // EXPANDED DETAILS (情報デザイン: tap to reveal)
            if isExpanded {
                // Horizontal divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // Details area - separate from tap gesture
                HStack(spacing: 8) {
                    // 情報デザイン: Only show notes if they ADD information beyond title
                    // For .note type, notes = full content, title = first line
                    // Don't show if notes == title (single-line note)
                    if let notes = item.notes,
                       !notes.isEmpty,
                       notes != item.title {
                        // Show additional content (lines beyond first)
                        let additionalLines = notes.components(separatedBy: .newlines).dropFirst().joined(separator: "\n")
                        if !additionalLines.isEmpty {
                            Text(additionalLines)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.8))
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    // Date badge
                    Text(formatDate(item.date))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(colors.border.opacity(0.05))
                        .clipShape(Capsule())

                    // Edit button (for user entries) - 情報デザイン: 44pt touch target
                    if canEdit {
                        Button {
                            openEditor(item)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                Text("EDIT")
                            }
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(JohoColors.cyan)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(colors.border, lineWidth: 1.5))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
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

    // MARK: - Type Indicator Dot (情報デザイン: Black outline shapes)
    // Icons are database-driven - use passed icon parameters from parent

    private func iconForType(_ type: SpecialDayType) -> String {
        switch type.displayCategory {
        case .holiday: return holidayIcon
        case .observance: return observanceIcon
        case .memo: return memoIcon
        }
    }

    @ViewBuilder
    private func typeIndicatorDot(for type: SpecialDayType) -> some View {
        Image(systemName: iconForType(type))
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(colors.primary)
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
            // Only holidays/observances use the special day editor
            if row.type == .holiday || row.type == .observance {
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
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(iconColor)

                        Text("\(day)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                    .padding(.leading, 10)

                    Spacer()

                    // RIGHT: Month (monospace, technical look)
                    Text(monthName)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .padding(.trailing, 10)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(headerBgColor)

                // Thin divider (情報デザイン: 1px distinct border)
                Rectangle()
                    .fill(colors.border.opacity(0.3))
                    .frame(height: 1)

                // BODY: Event row (white background)
                VStack(spacing: 0) {
                    // Main event row
                    HStack(spacing: 6) {
                        // Type indicator dot
                        typeIndicatorDot(for: row.type)

                        // Event name (sans-serif for human data)
                        Text(row.title)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary)
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
                        Rectangle().fill(colors.border.opacity(0.1)).frame(height: 1)
                        Text(birthdayExpandedDisplayText(age: age, date: row.date, daysUntil: row.daysUntil))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(colors.primary.opacity(0.5))
                            .padding(.vertical, 6)
                    } else if row.isMemo {
                        Rectangle().fill(colors.border.opacity(0.1)).frame(height: 1)
                        let daysText = row.daysUntil == 0 ? "TODAY" :
                                       row.daysUntil == 1 ? "IN 1 DAY" :
                                       "IN \(row.daysUntil) DAYS"
                        Text(daysText)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(colors.primary.opacity(0.5))
                            .padding(.vertical, 6)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(colors.border.opacity(0.2), lineWidth: 1)  // Thin technical border
            )
            .shadow(color: colors.border.opacity(0.05), radius: 2, x: 0, y: 1)
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
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(iconColor)

                    Text("\(dayCard.day)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)
                }
                .padding(.leading, 10)

                Spacer()

                Text(monthName)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(colors.primary.opacity(0.5))
                    .padding(.trailing, 10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(headerBgColor)

            // Thin divider
            Rectangle()
                .fill(colors.border.opacity(0.3))
                .frame(height: 1)

            // BODY: List of events with hairline dividers
            VStack(spacing: 0) {
                ForEach(Array(dayCard.items.enumerated()), id: \.element.id) { index, item in
                    // Hairline divider between items (not before first)
                    if index > 0 {
                        Rectangle()
                            .fill(colors.border.opacity(0.08))
                            .frame(height: 1)
                            .padding(.horizontal, 10)
                    }

                    // Event row
                    HStack(spacing: 6) {
                        typeIndicatorDot(for: item.type)

                        Text(item.title)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary)
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
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(colors.border.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: colors.border.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Type Indicator Dot (情報デザイン: Black outline shapes)
    // Icons are database-driven via customCategoryIcon(for:)

    @ViewBuilder
    private func typeIndicatorDot(for type: SpecialDayType) -> some View {
        let category = type.displayCategory
        Image(systemName: customCategoryIcon(for: category) ?? category.outlineIcon)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(colors.primary)
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
        .padding(.top, JohoDimensions.spacingSM)
    }

    // MARK: - Data Operations

    private func createSpecialDay(type: SpecialDayType, name: String, date: Date, symbol: String, iconColor: String?, notes: String?, region: String) {
        // Memos are stored as Memo
        if type == .memo {
            let memo = Memo(text: name, date: date)
            modelContext.insert(memo)
            do {
                try modelContext.save()
                HapticManager.notification(.success)
            } catch {
                Log.w("Failed to create memo: \(error.localizedDescription)")
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
            isBankHoliday: type.isBankHoliday,
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
        // Note: Memos are updated via MemoEditorView, not this function

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
        case .birthday, .memo, .note, .event, .trip, .expense:
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

        case .birthday:
            // Fetch Contact by UUID
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<Contact>(predicate: #Predicate<Contact> { $0.id == uuid })
                editingContact = try? modelContext.fetch(descriptor).first
            }

        case .memo, .note, .event, .trip, .expense:
            // Fetch Memo by UUID
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<Memo>(predicate: #Predicate<Memo> { $0.id == uuid })
                editingMemo = try? modelContext.fetch(descriptor).first
            }
        }
    }

    // MARK: - Delete Handler

    /// Deletes a row based on its type
    private func deleteRow(_ row: SpecialDayRow) {
        switch row.type {
        case .holiday, .observance:
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

        case .memo, .note, .event, .trip, .expense:
            // Delete the memo
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<Memo>(predicate: #Predicate<Memo> { $0.id == uuid })
                if let memo = try? modelContext.fetch(descriptor).first {
                    modelContext.delete(memo)
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

// Note: JohoUndoToast, JohoSpecialDayEditorSheet, JohoIconPickerSheet,
// JohoAddSpecialDaySheet, and JohoEventEditorSheet have been extracted to
// Views/JohoEditorSheets.swift for 情報デザイン spritesheet reuse.

// MARK: - Month Label Editor Sheet (情報デザイン: Personal notes for months)

/// Simple editor sheet for adding personal labels to months
/// Long-press on a month card in Star page to trigger
/// 情報デザイン: Month customization sheet for icon and background color
struct MonthCustomizationSheet: View {
    let month: Int
    let currentCustomization: MonthCustomization
    let onSave: (MonthCustomization) -> Void
    let onCancel: () -> Void
    let onReset: () -> Void

    @State private var selectedIcon: String?
    @State private var selectedIconColor: String?
    @State private var selectedColor: String?
    @State private var messageText: String = ""

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var monthTheme: MonthTheme {
        MonthTheme.theme(for: month)
    }

    // 情報デザイン: Curated icon set for months (PlayStation-style shapes + seasonal)
    private let iconOptions: [String] = [
        // Seasonal
        "snowflake", "heart.fill", "leaf.fill", "sun.max.fill", "cloud.rain.fill", "drop.fill",
        // Nature
        "tree.fill", "moon.fill", "star.fill", "sparkles", "wind", "bolt.fill",
        // Objects
        "gift.fill", "flag.fill", "bell.fill", "airplane", "car.fill", "house.fill",
        // PlayStation-style shapes (using SF Symbols that match the style)
        "circle", "xmark", "triangle", "square", "diamond", "plus"
    ]

    // 情報デザイン: 6-color palette for backgrounds
    private let colorOptions: [(name: String, hex: String, color: Color)] = [
        ("Yellow", "FFE566", JohoColors.yellow),
        ("Cyan", "A5F3FC", JohoColors.cyan),
        ("Pink", "FECDD3", JohoColors.pink),
        ("Green", "BBF7D0", JohoColors.green),
        ("Purple", "E9D5FF", JohoColors.purple),
        ("White", "FFFFFF", JohoColors.white)
    ]

    // 情報デザイン: Icon colors (darker/more saturated for visibility)
    private let iconColorOptions: [(name: String, hex: String, color: Color)] = [
        ("Black", "1A1A1A", JohoColors.black),
        ("Yellow", "D4A900", Color(hex: "D4A900")),
        ("Cyan", "0891B2", Color(hex: "0891B2")),
        ("Pink", "E11D48", Color(hex: "E11D48")),
        ("Green", "16A34A", Color(hex: "16A34A")),
        ("Purple", "9333EA", Color(hex: "9333EA"))
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.6))
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthTheme.name.uppercased())
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(colors.primary)

                Spacer()

                Button {
                    let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                    // 情報デザイン: colorHex is locked to seasonal theme (季節の色)
                    onSave(MonthCustomization(
                        icon: selectedIcon,
                        iconColorHex: selectedIconColor,
                        colorHex: nil,  // Locked to theme
                        message: trimmedMessage.isEmpty ? nil : trimmedMessage
                    ))
                } label: {
                    Text("Save")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.surface)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(colors.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.top, JohoDimensions.spacingLG)
            .padding(.bottom, JohoDimensions.spacingMD)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            ScrollView {
                VStack(alignment: .leading, spacing: JohoDimensions.spacingLG) {
                    // Icon picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ICON")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                            ForEach(iconOptions, id: \.self) { icon in
                                iconButton(icon)
                            }
                        }
                    }

                    // Icon color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ICON COLOR")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))

                        HStack(spacing: 8) {
                            ForEach(iconColorOptions, id: \.hex) { option in
                                iconColorButton(option)
                            }
                        }
                    }

                    // 情報デザイン: Background color is LOCKED to seasonal theme (季節の色)
                    // Users can only customize icons, icon colors, and messages

                    // Message field (情報デザイン: personal note)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MESSAGE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))

                        TextField("e.g., Birthday month...", text: $messageText)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(colors.inputBackground)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
                            )
                    }

                    // Reset button
                    Button {
                        HapticManager.selection()
                        onReset()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .medium))
                            Text("Reset to default")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(colors.primary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingMD)
            }

            Spacer()
        }
        .background(colors.surface)
        .onAppear {
            selectedIcon = currentCustomization.icon
            selectedIconColor = currentCustomization.iconColorHex
            selectedColor = currentCustomization.colorHex
            messageText = currentCustomization.message ?? ""
        }
    }

    private func iconButton(_ icon: String) -> some View {
        let isSelected = selectedIcon == icon
        let isDefault = icon == monthTheme.icon && selectedIcon == nil

        return Button {
            HapticManager.selection()
            selectedIcon = (selectedIcon == icon) ? nil : icon
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isSelected || isDefault ? colors.surface : colors.primary)
                .frame(width: 44, height: 44)
                .background(isSelected || isDefault ? colors.primary : colors.inputBackground)
                .clipShape(Squircle(cornerRadius: 10))
                .overlay(
                    Squircle(cornerRadius: 10)
                        .stroke(colors.border, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func colorButton(_ option: (name: String, hex: String, color: Color)) -> some View {
        let isSelected = selectedColor == option.hex

        return Button {
            HapticManager.selection()
            selectedColor = (selectedColor == option.hex) ? nil : option.hex
        } label: {
            option.color
                .frame(width: 44, height: 44)
                .clipShape(Squircle(cornerRadius: 10))
                .overlay(
                    Squircle(cornerRadius: 10)
                        .stroke(colors.border, lineWidth: isSelected ? 2.5 : 1)
                )
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(colors.primary)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func iconColorButton(_ option: (name: String, hex: String, color: Color)) -> some View {
        let isSelected = selectedIconColor == option.hex

        return Button {
            HapticManager.selection()
            selectedIconColor = (selectedIconColor == option.hex) ? nil : option.hex
        } label: {
            option.color
                .frame(width: 44, height: 44)
                .clipShape(Squircle(cornerRadius: 10))
                .overlay(
                    Squircle(cornerRadius: 10)
                        .stroke(colors.border, lineWidth: isSelected ? 2.5 : 1)
                )
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(option.name == "Black" ? colors.surface : colors.primary)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Customization Sheet (情報デザイン: Icon-only customization for categories)

/// Simple editor sheet for customizing category card icons
/// Long-press on a category card in month detail to trigger
/// 情報デザイン: Color is locked to category - only icon can be customized
struct CategoryCustomizationSheet: View {
    let category: DisplayCategory
    let count: Int
    let currentCustomization: CategoryCustomization
    let onSave: (CategoryCustomization) -> Void
    let onReset: () -> Void
    let onDismiss: () -> Void

    @State private var selectedIcon: String?

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // 情報デザイン: Curated icon set for categories (shapes + conceptual)
    private let iconOptions: [String] = [
        // Shapes (core category icons)
        "circle", "diamond", "doc.text", "square", "triangle", "plus",
        // Conceptual
        "star.fill", "heart.fill", "flag.fill", "bell.fill", "gift.fill", "bookmark.fill",
        // Status
        "checkmark.circle", "xmark.circle", "exclamationmark.circle", "questionmark.circle",
        // Nature
        "leaf.fill", "sun.max.fill", "moon.fill", "sparkles"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 情報デザイン: Bento-style header with category color banner
            VStack(spacing: 0) {
                // Banner with category color
                HStack {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.7))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(category.localizedLabel.uppercased())
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)

                    Spacer()

                    Button {
                        onSave(CategoryCustomization(icon: selectedIcon))
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(category.accentColor)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(
                                Squircle(cornerRadius: 8)
                                    .stroke(colors.border, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.vertical, JohoDimensions.spacingMD)
                .background(category.accentColor.opacity(0.3))

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)
            }

            // Content
            VStack(alignment: .leading, spacing: JohoDimensions.spacingLG) {
                // 情報デザイン: Preview card - bento style
                HStack {
                    Spacer()
                    categoryPreview
                    Spacer()
                }

                // Icon picker with category-colored section header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(category.accentColor)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        Text("ICON")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                        ForEach(iconOptions, id: \.self) { icon in
                            iconButton(icon)
                        }
                    }
                }

                // Reset button
                Button {
                    onReset()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Text("Reset to Default")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(colors.primary.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(colors.inputBackground)
                    .clipShape(Squircle(cornerRadius: 10))
                    .overlay(
                        Squircle(cornerRadius: 10)
                            .stroke(colors.border, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(JohoDimensions.spacingLG)

            Spacer()
        }
        .background(colors.surface)
        .onAppear {
            selectedIcon = currentCustomization.icon
        }
    }

    // 情報デザイン: Preview card showing current selection (bento style)
    private var categoryPreview: some View {
        let displayIcon = selectedIcon ?? category.outlineIcon

        return VStack(spacing: 0) {
            // TOP: Icon zone with full-width category color
            VStack {
                Image(systemName: displayIcon)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(category.accentColor)

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // BOTTOM: Show count (header already shows category name)
            VStack(spacing: 2) {
                Text(category.localizedLabel.uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(colors.primary)

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(colors.surface)
        }
        .frame(width: 100)
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(colors.border, lineWidth: 1.5)
        )
    }

    private func iconButton(_ icon: String) -> some View {
        let isSelected = selectedIcon == icon
        let isDefault = (selectedIcon == nil && icon == category.outlineIcon)

        return Button {
            HapticManager.selection()
            // Toggle selection: if selecting current default, clear; otherwise set
            if icon == category.outlineIcon && selectedIcon == nil {
                // Already at default, do nothing
            } else if selectedIcon == icon {
                selectedIcon = nil  // Clear to default
            } else {
                selectedIcon = icon
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .frame(width: 44, height: 44)
                .background((isSelected || isDefault) ? category.accentColor : colors.inputBackground)
                .clipShape(Squircle(cornerRadius: 10))
                .overlay(
                    Squircle(cornerRadius: 10)
                        .stroke(colors.border, lineWidth: (isSelected || isDefault) ? 2.5 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Holiday Creator Sheet (情報デザイン)

/// 情報デザイン: Sheet for creating custom holidays/observances
struct CustomHolidayCreatorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // 情報デザイン: Initial month context (can be changed)
    let initialMonth: Int
    let holidayIcon: String      // Custom icon from category customization
    let observanceIcon: String   // Custom icon from category customization
    let enabledRegions: [String]
    let onSave: (SpecialDayType, String, String?, String, Int, Int, Int) -> Void  // type, name, about, region, year, month, day

    // Form state
    @State private var selectedType: SpecialDayType = .holiday
    @State private var name: String = ""
    @State private var about: String = ""
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = 1
    @State private var selectedDay: Int = 1
    @State private var selectedRegion: String = "PERSONAL"
    @State private var showingCustomRegionInput = false
    @State private var customRegionName: String = ""

    private var yearRange: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 5)...(current + 10))
    }

    // 情報デザイン: Custom regions stored in UserDefaults
    @AppStorage("customHolidayRegions") private var customRegionsData: Data = Data()

    private var customRegions: [String] {
        guard !customRegionsData.isEmpty,
              let decoded = try? JSONDecoder().decode([String].self, from: customRegionsData) else {
            return []
        }
        return decoded
    }

    private func addCustomRegion(_ name: String) {
        var regions = customRegions
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty, !regions.contains(normalized) else { return }
        regions.append(normalized)
        if let encoded = try? JSONEncoder().encode(regions) {
            customRegionsData = encoded
        }
    }

    // 情報デザイン: System UI accent for universal creator (not category-specific)
    @AppStorage("systemUIAccent") private var systemUIAccent = "blue"

    private var accentColor: Color {
        (SystemUIAccent(rawValue: systemUIAccent) ?? .indigo).color
    }

    // 情報デザイン: Use customized icons from category picker
    private var typeIcon: String {
        selectedType == .holiday ? holidayIcon : observanceIcon
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let date = Calendar.current.date(from: DateComponents(year: 2024, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }

    private var daysInSelectedMonth: Int {
        let date = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) ?? Date()
        return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 31
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with month context
            headerRow

            Rectangle().fill(colors.border).frame(height: 2)

            // Type selector (Holiday/Observance)
            typeRow

            Rectangle().fill(colors.border).frame(height: 1.5)

            // Date picker (day of month)
            dateRow

            Rectangle().fill(colors.border).frame(height: 1.5)

            // Name input
            nameRow

            Rectangle().fill(colors.border).frame(height: 1.5)

            // About/Purpose input
            aboutRow

            Rectangle().fill(colors.border).frame(height: 1.5)

            // Region picker
            regionRow

            Rectangle().fill(colors.border).frame(height: 2)

            // Save button
            saveRow

            Spacer()
        }
        .background(colors.canvas)
        .johoCalendarPicker(
            isPresented: $showingDatePicker,
            selectedDate: Binding(
                get: { selectedDate },
                set: { newDate in
                    selectedYear = Calendar.current.component(.year, from: newDate)
                    selectedMonth = Calendar.current.component(.month, from: newDate)
                    selectedDay = Calendar.current.component(.day, from: newDate)
                }
            ),
            accentColor: accentColor
        )
        .sheet(isPresented: $showingCustomRegionInput) {
            customRegionInputSheet
        }
        .onAppear {
            // Initialize from context
            selectedMonth = initialMonth
            let today = Calendar.current.component(.day, from: Date())
            let currentMonth = Calendar.current.component(.month, from: Date())
            selectedDay = (initialMonth == currentMonth) ? today : 1
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 32, height: 32)
                    .background(colors.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
            }

            Spacer()

            // 情報デザイン: Simple header
            Text("NEW ENTRY")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(colors.primary)

            Spacer()

            // Placeholder for symmetry
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.vertical, JohoDimensions.spacingMD)
        .background(colors.surface)
    }

    // MARK: - Date Picker Row (情報デザイン: Single button, opens sheet, no glass)

    @State private var showingDatePicker = false

    private var selectedDate: Date {
        get {
            Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)) ?? Date()
        }
        set {
            selectedYear = Calendar.current.component(.year, from: newValue)
            selectedMonth = Calendar.current.component(.month, from: newValue)
            selectedDay = Calendar.current.component(.day, from: newValue)
        }
    }

    private var formattedDate: String {
        let y = String(format: "%04d", selectedYear)
        let m = String(format: "%02d", selectedMonth)
        let d = String(format: "%02d", selectedDay)
        return "\(y)  \(m)  \(d)"
    }

    private var dateRow: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingDatePicker = true
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: 0) {
                // Icon column (tappable indicator)
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 48).frame(maxHeight: .infinity)

                Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

                // Formatted date display: YYYY  MM  DD
                Text(formattedDate)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(colors.primary)
                    .padding(.horizontal, JohoDimensions.spacingMD)

                Spacer()

                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(colors.primary.opacity(0.4))
                    .padding(.trailing, JohoDimensions.spacingMD)
            }
            .frame(height: 48)
            .background(colors.surface)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Type Selector Row

    private var typeRow: some View {
        HStack(spacing: 0) {
            // Icon column - shows the currently selected type's custom icon
            Image(systemName: typeIcon)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .frame(width: 48).frame(maxHeight: .infinity)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

            // Type pills with custom icons from category customization
            HStack(spacing: JohoDimensions.spacingSM) {
                typePill(.holiday, label: "HOLIDAY", icon: holidayIcon)
                typePill(.observance, label: "OBSERVANCE", icon: observanceIcon)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 56)
        .background(accentColor.opacity(0.15))
    }

    private func typePill(_ type: SpecialDayType, label: String, icon: String) -> some View {
        let isSelected = selectedType == type

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedType = type
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text(label)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : colors.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? accentColor : colors.surface)
            .clipShape(Squircle(cornerRadius: 10))
            .overlay(Squircle(cornerRadius: 10).stroke(colors.border, lineWidth: isSelected ? 2 : 1.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Name Input Row

    private var nameRow: some View {
        HStack(spacing: 0) {
            // Icon column
            Image(systemName: "pencil")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .frame(width: 48).frame(maxHeight: .infinity)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

            // Text field
            TextField("Name (e.g., Earth Day)", text: $name)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .frame(maxHeight: .infinity)
        }
        .frame(height: 48)
        .background(colors.surface)
    }

    // MARK: - About Input Row

    private var aboutRow: some View {
        HStack(spacing: 0) {
            // Icon column
            Image(systemName: "doc.text")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .frame(width: 48).frame(maxHeight: .infinity)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

            // Text field
            TextField("About / Purpose (optional)", text: $about)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .frame(maxHeight: .infinity)
        }
        .frame(height: 48)
        .background(colors.surface)
    }

    // MARK: - Region Picker Row (情報デザイン: Menu dropdown, no horizontal scroll)

    private var regionRow: some View {
        HStack(spacing: 0) {
            // Icon column
            Image(systemName: "globe")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .frame(width: 48).frame(maxHeight: .infinity)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

            // Region dropdown (Menu)
            Menu {
                // Personal option
                Button {
                    selectedRegion = "PERSONAL"
                    HapticManager.selection()
                } label: {
                    Label("Personal", systemImage: "person.fill")
                }

                Divider()

                // Enabled regions from settings
                ForEach(enabledRegions, id: \.self) { region in
                    Button {
                        selectedRegion = region
                        HapticManager.selection()
                    } label: {
                        Label(regionDisplayName(region), systemImage: "flag.fill")
                    }
                }

                // Custom regions (if any)
                if !customRegions.isEmpty {
                    Divider()
                    ForEach(customRegions, id: \.self) { region in
                        Button {
                            selectedRegion = region
                            HapticManager.selection()
                        } label: {
                            Label(region, systemImage: "star.fill")
                        }
                    }
                }

                Divider()

                // Create custom region
                Button {
                    showingCustomRegionInput = true
                } label: {
                    Label("Create Custom...", systemImage: "plus")
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: regionIcon(for: selectedRegion))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Text(selectedRegion == "PERSONAL" ? "Personal" : regionDisplayName(selectedRegion))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(colors.primary.opacity(0.5))
                }
                .foregroundStyle(colors.primary)
                .padding(.horizontal, JohoDimensions.spacingMD)
                .frame(maxHeight: .infinity)
            }
        }
        .frame(height: 48)
        .background(colors.surface)
    }

    private func regionIcon(for code: String) -> String {
        if code == "PERSONAL" { return "person.fill" }
        if customRegions.contains(code) { return "star.fill" }
        return "flag.fill"
    }

    private func regionDisplayName(_ code: String) -> String {
        switch code {
        case "SE": return "Sweden"
        case "US": return "USA"
        case "VN": return "Vietnam"
        case "NO": return "Norway"
        case "DK": return "Denmark"
        case "FI": return "Finland"
        case "JP": return "Japan"
        case "NORDIC": return "Nordic"
        default: return code
        }
    }

    // MARK: - Save Row

    private var saveRow: some View {
        Button {
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                HapticManager.notification(.error)
                return
            }
            onSave(selectedType, name.trimmingCharacters(in: .whitespacesAndNewlines),
                   about.isEmpty ? nil : about.trimmingCharacters(in: .whitespacesAndNewlines),
                   selectedRegion, selectedYear, selectedMonth, selectedDay)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("SAVE")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(name.isEmpty ? colors.primary.opacity(0.4) : colors.primaryInverted)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(name.isEmpty ? colors.inputBackground : accentColor)
            .clipShape(Squircle(cornerRadius: 12))
            .overlay(Squircle(cornerRadius: 12).stroke(colors.border, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(name.isEmpty)
        .padding(JohoDimensions.spacingLG)
    }

    // MARK: - Custom Region Input Sheet

    private var customRegionInputSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    showingCustomRegionInput = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 32, height: 32)
                        .background(colors.surface)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
                }

                Spacer()

                Text("CREATE REGION")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(colors.primary)

                Spacer()

                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(colors.surface)

            Rectangle().fill(colors.border).frame(height: 2)

            // Input row
            HStack(spacing: 0) {
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 48).frame(maxHeight: .infinity)

                Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

                TextField("Region name (e.g., FAMILY)", text: $customRegionName)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .textInputAutocapitalization(.characters)
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 48)
            .background(colors.surface)

            Rectangle().fill(colors.border).frame(height: 2)

            // Add button
            Button {
                let trimmed = customRegionName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    HapticManager.notification(.error)
                    return
                }
                addCustomRegion(trimmed)
                selectedRegion = trimmed.uppercased()
                customRegionName = ""
                showingCustomRegionInput = false
                HapticManager.notification(.success)
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text("ADD REGION")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(customRegionName.isEmpty ? colors.primary.opacity(0.4) : colors.primaryInverted)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(customRegionName.isEmpty ? colors.inputBackground : accentColor)
                .clipShape(Squircle(cornerRadius: 12))
                .overlay(Squircle(cornerRadius: 12).stroke(colors.border, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .disabled(customRegionName.isEmpty)
            .padding(JohoDimensions.spacingLG)

            Spacer()
        }
        .background(colors.canvas)
        .presentationDetents([.height(220)])
        .presentationCornerRadius(20)
    }
}

// MARK: - Preview

#Preview {
    if let container = try? ModelContainer(
        for: HolidayRule.self, CalendarRule.self, Memo.self, Contact.self,
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
