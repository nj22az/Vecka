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
//  Category icons resolve via DisplayCategory.categoryAwareIcon
//  which reads from @AppStorage("categoryCustomizations").
//  NEVER hardcode icons - always use DisplayCategory.categoryAwareIcon
//
//  Sub-components (all in Views/Holidays/):
//  - SpecialDaysGridView      — 4×3 month tile grid
//  - SpecialDaysMonthDetail   — Single-month category cards + day list
//  - SpecialDayCard           — CollapsibleSpecialDayCard per-day bento
//  - SpecialDayEditor         — EditingSpecialDay / DeletedSpecialDay structs
//

import SwiftUI
import SwiftData
import WidgetKit

// MARK: - Shared Types

/// 情報デザイン: Custom icon, color, and message for a month card
struct MonthCustomization: Codable, Equatable {
    var icon: String?         // SF Symbol name (nil = use default seasonal icon)
    var iconColorHex: String? // Icon color hex (nil = use theme accent color)
    var colorHex: String?     // Background color hex (nil = use default seasonal color)
    var message: String?      // Personal note (nil = no message)
}

// MARK: - Special Days List View (情報デザイン Redesign)

struct SpecialDaysListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }
    private var holidayManager = HolidayManager.shared

    // All contacts needed: birthdays are projected into the selected year for any contact.
    @Query private var contacts: [Contact]

    // All memos needed: the selected year can be changed at runtime; predicating on year
    // would require re-creating the @Query dynamically, which SwiftData does not support
    // for a plain @Query property. Filtering happens inside rebuildRowCache().
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

    // 情報デザイン: Holiday Database Explorer
    @State private var showingDatabaseExplorer = false

    // 情報デザイン: Special day detail sheet
    @State private var selectedDetailItem: SpecialDayRow?

    // 情報デザイン: Category filter toggles (tap stat icons to filter)
    @State private var activeFilters: Set<DisplayCategory> = [.holiday, .observance, .memo]

    // 情報デザイン: Category navigation within month (nil = show category cards, set = show filtered list)
    @State private var selectedCategory: DisplayCategory? = nil

    // 情報デザイン: FAB for creating custom holidays/observances
    @State private var showingHolidayCreator = false

    // Cached row arrays rebuilt only when source data changes (memos, contacts, selectedYear,
    // or holiday cache). Prevents rows(for:) from being called repeatedly on every render.
    @State private var cachedHolidayRows: [SpecialDayRow] = []
    @State private var cachedObservanceRows: [SpecialDayRow] = []
    @State private var cachedBirthdayRows: [SpecialDayRow] = []
    @State private var cachedMemoRows: [SpecialDayRow] = []

    private var years: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 20)...(current + 20))
    }

    // MARK: - Month Customization Helpers

    private var monthCustomizations: [Int: MonthCustomization] {
        get {
            guard !monthCustomizationsData.isEmpty,
                  let decoded = try? JSONDecoder().decode([Int: MonthCustomization].self, from: monthCustomizationsData) else {
                return [:]
            }
            return decoded
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

    // 情報デザイン: Force refresh when customizations change (SwiftUI dependency workaround)
    private var categoryCustomizationsVersion: Int {
        categoryCustomizationsData.hashValue
    }

    // MARK: - Computed Data

    // Returns rows from the cache. The cache is rebuilt via rebuildRowCache() whenever
    // memos, contacts, selectedYear, or the holiday cache changes.
    private func rows(for type: SpecialDayType) -> [SpecialDayRow] {
        switch type {
        case .holiday:    return cachedHolidayRows
        case .observance: return cachedObservanceRows
        case .birthday:   return cachedBirthdayRows
        case .memo:       return cachedMemoRows
        default:          return []
        }
    }

    // Rebuilds all four row caches from source data (memos, contacts, holidayCache).
    // Called from .onAppear and .onChange triggers — never from body rendering paths.
    private func rebuildRowCache() {
        let calendar = Calendar.current
        let year = selectedYear

        // Memos for the selected year
        let newMemoRows = memos
            .filter { calendar.component(.year, from: $0.date) == year }
            .map { memo -> SpecialDayRow in
                SpecialDayRow(
                    id: "memo-\(memo.id.uuidString)",
                    ruleID: memo.id.uuidString,
                    region: "",
                    date: memo.date,
                    title: memo.preview,
                    type: .memo,
                    symbolName: memo.symbolName ?? (memo.hasMoney ? IconCatalog.expense : (memo.hasPlace ? "mappin.circle.fill" : IconCatalog.memo)),
                    iconColor: memo.colorHex,
                    notes: memo.text,
                    isCustom: true,
                    isMemo: true,
                    originalBirthday: nil,
                    turningAge: nil
                )
            }
            .sorted { $0.date < $1.date }

        // Birthdays projected into the selected year
        let newBirthdayRows = contacts
            .compactMap { contact -> SpecialDayRow? in
                guard let birthday = contact.birthday else { return nil }
                let birthYear = calendar.component(.year, from: birthday)
                let month = calendar.component(.month, from: birthday)
                let day = calendar.component(.day, from: birthday)
                guard let birthdayForSelectedYear = calendar.date(from: DateComponents(
                    year: year, month: month, day: day
                )) else { return nil }
                let ageAtBirthday = year - birthYear
                return SpecialDayRow(
                    id: "birthday-\(contact.id.uuidString)",
                    ruleID: contact.id.uuidString,
                    region: "",
                    date: birthdayForSelectedYear,
                    title: contact.displayName,
                    type: .birthday,
                    symbolName: IconCatalog.birthday,
                    iconColor: "D53F8C",  // Pink
                    notes: nil,
                    isCustom: false,
                    isMemo: false,
                    originalBirthday: birthday,
                    turningAge: ageAtBirthday
                )
            }
            .sorted { $0.date < $1.date }

        // Holidays and observances from the manager cache
        let holidayEntries = holidayManager.holidayCache
            .filter { (date, _) in calendar.component(.year, from: date) == year }
            .sorted(by: { $0.key < $1.key })

        var newHolidayRows: [SpecialDayRow] = []
        var newObservanceRows: [SpecialDayRow] = []
        for (date, holidays) in holidayEntries {
            for holiday in holidays {
                let row = SpecialDayRow(
                    id: "\(date.timeIntervalSinceReferenceDate)-\(holiday.id)",
                    ruleID: holiday.id,
                    region: holiday.region,
                    date: date,
                    title: holiday.displayTitle,
                    type: holiday.isBankHoliday ? .holiday : .observance,
                    symbolName: holiday.symbolName,
                    iconColor: holiday.iconColor,
                    notes: holiday.notes,
                    isCustom: holiday.isCustom,
                    isMemo: false,
                    originalBirthday: nil,
                    turningAge: nil,
                    mergedRegions: holiday.mergedRegions
                )
                if holiday.isBankHoliday {
                    newHolidayRows.append(row)
                } else {
                    newObservanceRows.append(row)
                }
            }
        }

        cachedHolidayRows = newHolidayRows
        cachedObservanceRows = newObservanceRows
        cachedBirthdayRows = newBirthdayRows
        cachedMemoRows = newMemoRows
    }

    private var holidayCount: Int { rows(for: .holiday).count }
    private var observanceCount: Int { rows(for: .observance).count }
    private var birthdayCount: Int { rows(for: .birthday).count }
    private var memoCount: Int { rows(for: .memo).count }

    // MARK: - Unique Date Counting

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

    private var uniqueHolidayCount: Int { uniqueDateCount(for: .holiday) }
    private var uniqueObservanceCount: Int { uniqueDateCount(for: .observance) }
    private var uniqueMemoCount: Int { uniqueDateCount(for: .memo) }

    private var compactSubtitle: String {
        var parts: [String] = []
        if holidayCount > 0 { parts.append("\(holidayCount) holidays") }
        if observanceCount > 0 { parts.append("\(observanceCount) observances") }
        if birthdayCount > 0 { parts.append("\(birthdayCount) birthdays") }
        if memoCount > 0 { parts.append("\(memoCount) memos") }

        if parts.isEmpty { return "No entries yet" }
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

    /// Get UNIQUE date counts for a specific month by category
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
        var monthRows: [SpecialDayRow] = []

        if activeFilters.contains(.holiday) {
            monthRows += rows(for: .holiday).filter { calendar.component(.month, from: $0.date) == month }
        }
        if activeFilters.contains(.observance) {
            monthRows += rows(for: .observance).filter { calendar.component(.month, from: $0.date) == month }
        }
        if activeFilters.contains(.memo) {
            // Memo category includes birthdays + memos
            monthRows += rows(for: .birthday).filter { calendar.component(.month, from: $0.date) == month }
            monthRows += rows(for: .memo).filter { calendar.component(.month, from: $0.date) == month }
        }

        return monthRows.sorted { $0.date < $1.date }
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

    // MARK: - Body

    var body: some View {
        mainContent
            .sheet(isPresented: $isPresentingNewSpecialDay) { newSpecialDaySheet }
            .sheet(item: $editingSpecialDay) { specialDay in editSpecialDaySheet(specialDay) }
            .sheet(item: $editingContact) { contact in contactEditorSheet(contact) }
            .sheet(item: $editingMemo) { memo in memoEditorSheet(memo) }
            .sheet(isPresented: $showingDatabaseExplorer) { HolidayDatabaseExplorer() }
            .sheet(item: $selectedDetailItem) { item in SpecialDayDetailSheet(item: item) }
            .sheet(isPresented: $showingHolidayCreator) { holidayCreatorSheet }
            .overlay(alignment: .bottom) { undoToastOverlay }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingPage) {
                headerWithYearPicker

                // 情報デザイン: Inline region picker (replaces globe navigation)
                if selectedMonth == nil && showHolidays {
                    regionQuickPickerSection
                }

                if !showHolidays {
                    disabledState
                } else if let month = selectedMonth {
                    SpecialDaysMonthDetail(
                        month: month,
                        dayCardsForMonth: { dayCardsForMonth(month) },
                        filteredDayCards: { category in filteredDayCardsForMonth(month, category: category) },
                        monthUniqueCounts: { monthUniqueCounts(for: month) },
                        categoryCustomizationsVersion: categoryCustomizationsVersion,
                        isEditable: isEditable,
                        deleteRow: deleteRow,
                        openEditor: openEditor,
                        showDetail: { item in selectedDetailItem = item },
                        selectedCategory: $selectedCategory,
                        expandedItemID: $expandedItemID
                    )
                } else {
                    SpecialDaysGridView(
                        monthCounts: { monthCounts(for: $0) },
                        customIcon: { customIcon(for: $0) },
                        customIconColor: { customIconColor(for: $0) },
                        customMessage: { customMessage(for: $0) },
                        onSelectMonth: { month in
                            selectedMonth = month
                        }
                    )
                }
                Spacer(minLength: JohoDimensions.spacingXL)
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
            rebuildRowCache()
        }
        .onChange(of: selectedYear) { _, newYear in
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: newYear)
            rebuildRowCache()
        }
        .onChange(of: holidayRegions) { _, newRegions in
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
            WorldClockStorage.syncFromRegions(newRegions)
            WidgetCenter.shared.reloadTimelines(ofKind: "VeckaWidget")
            rebuildRowCache()
        }
        .onChange(of: showHolidays) { _, _ in
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
            rebuildRowCache()
        }
        .onChange(of: memos) { _, _ in
            rebuildRowCache()
        }
        .onChange(of: contacts) { _, _ in
            rebuildRowCache()
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

    // MARK: - Sheet Views

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
                symbol: specialDay.symbolName ?? specialDay.type.categoryAwareIcon,
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

    private var holidayCreatorSheet: some View {
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

    // MARK: - Header with Year Picker

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
                                if selectedCategory != nil {
                                    selectedCategory = nil
                                } else {
                                    selectedMonth = nil
                                }
                            }
                            HapticManager.selection()
                        } label: {
                            Image(systemName: IconCatalog.chevronLeft)
                                .font(JohoFont.bodySmallBold)
                                .foregroundStyle(colors.primary)
                                .johoTouchTarget()
                                .background(colors.inputBackground)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                        }
                    }

                    // Icon zone
                    if let month = selectedMonth, let theme = theme {
                        let headerIcon = customIcon(for: month) ?? theme.icon
                        let headerIconColor: Color = customIconColor(for: month).map { Color(hex: $0) } ?? theme.accentColor

                        JohoSticker(content: .icon(headerIcon), color: headerIconColor, size: 40)
                    } else {
                        JohoSticker(content: .icon(IconCatalog.holiday), color: PageHeaderColor.specialDays.accent, size: 40)
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
            .background(PageHeaderColor.specialDays.lightBackground)

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // STATS ROW
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
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: 2)
        .padding(.horizontal, JohoDimensions.spacingPage)
        .padding(.top, JohoDimensions.spacingLG)
    }

    // MARK: - Bento Stats Row

    private var displayCategoryCounts: (holidays: Int, observances: Int, memos: Int) {
        return (uniqueHolidayCount, uniqueObservanceCount, uniqueMemoCount)
    }

    private var bentoStatsRow: some View {
        let counts = displayCategoryCounts
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
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
            }

            Spacer()
        }
    }

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
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
            }

            Spacer()
        }
    }

    // MARK: - Month Subtitle Row

    private func monthSubtitleRow(for month: Int) -> some View {
        let counts = monthUniqueCounts(for: month)

        return HStack(spacing: JohoDimensions.spacingMD) {
            HStack(spacing: JohoDimensions.spacingSM) {
                monthCategoryDot(
                    category: .holiday,
                    count: counts.holidays,
                    color: CategoryColorSettings.shared.color(for: .holiday)
                )
                monthCategoryDot(
                    category: .observance,
                    count: counts.observances,
                    color: CategoryColorSettings.shared.color(for: .observance)
                )
                monthCategoryDot(
                    category: .memo,
                    count: counts.memos,
                    color: CategoryColorSettings.shared.color(for: .memo)
                )
            }

            Spacer()

            unifiedAddButton
        }
    }

    @State private var showingCustomHolidayCreator = false

    private var systemAccentColor: Color {
        (SystemUIAccent(rawValue: systemUIAccent) ?? .indigo).color
    }

    private var unifiedAddButton: some View {
        Button {
            showingCustomHolidayCreator = true
            HapticManager.impact(.light)
        } label: {
            Image(systemName: IconCatalog.plus)
                .font(JohoFont.label)
                .foregroundStyle(systemAccentColor.contrastingForeground)
                .frame(width: 28, height: 28)
                .background(systemAccentColor)
                .clipShape(Circle())
                .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingCustomHolidayCreator) {
            UnifiedEntryCreator(
                config: .fullContext(
                    date: selectedMonthDate,
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
        do { try modelContext.save() } catch { Log.e("Failed to save: \(error)") }

        holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
        HapticManager.notification(.success)
    }

    private func createMemo(text: String, date: Date, amount: Double?, currency: String?, place: String?, contactID: UUID?, photoData: Data?) {
        let memo = Memo(text: text, date: date)
        memo.amount = amount
        memo.currency = currency
        memo.place = place
        memo.linkedContactID = contactID
        memo.photoData = photoData
        modelContext.insert(memo)
        do { try modelContext.save() } catch { Log.e("Failed to save: \(error)") }
        HapticManager.notification(.success)
    }

    private func monthCategoryDot(category: DisplayCategory, count: Int, color: Color) -> some View {
        let isSelected = selectedCategory == category
        let hasItems = count > 0

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedCategory == category {
                    selectedCategory = nil
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
                    .font(JohoFont.label)
                    .foregroundStyle(hasItems ? colors.primary : colors.primary.opacity(JohoDimensions.opacityModerate))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? color.opacity(JohoDimensions.opacityMedium) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                    .stroke(isSelected ? colors.border : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(hasItems ? 1.0 : 0.5)
    }

    // MARK: - Region Quick Picker Section

    private var regionQuickPickerSection: some View {
        RegionQuickPicker(selectedRegions: $holidayRegions)
            .padding(.horizontal, JohoDimensions.spacingPage)
    }

    private func categoryIndicator(category: DisplayCategory, count: Int) -> some View {
        let isActive = activeFilters.contains(category)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                HapticManager.selection()
                if activeFilters.contains(category) {
                    if activeFilters.count > 1 {
                        activeFilters.remove(category)
                    }
                } else {
                    activeFilters.insert(category)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(isActive ? CategoryColorSettings.shared.color(for: category) : colors.primary.opacity(JohoDimensions.opacityMild))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(colors.border, lineWidth: 0.5)
                    )

                if isActive {
                    Text(category.localizedLabel)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .lineLimit(1)
                }

                Text(String(count))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isActive ? colors.primary : colors.primary.opacity(JohoDimensions.opacityModerate))
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(isActive ? CategoryColorSettings.shared.color(for: category).opacity(0.12) : Color.clear)
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

    // MARK: - Disabled State

    private var disabledState: some View {
        JohoEmptyState(
            title: "Holidays Are Off",
            message: "Enable in Settings → Show Holidays",
            icon: "calendar.badge.exclamationmark",
            zone: .holidays
        )
        .padding(.horizontal, JohoDimensions.spacingPage)
        .padding(.top, JohoDimensions.spacingLG)
    }
}

// MARK: - SpecialDaysListView Data Operations

extension SpecialDaysListView {

    private func createSpecialDay(type: SpecialDayType, name: String, date: Date, symbol: String, iconColor: String?, notes: String?, region: String) {
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

    private func isEditable(_ row: SpecialDayRow) -> Bool {
        switch row.type {
        case .holiday, .observance:
            return row.isCustom
        case .birthday, .memo, .note, .event, .trip, .expense:
            return true
        }
    }

    // MARK: - Edit Handler

    private func openEditor(_ row: SpecialDayRow) {
        switch row.type {
        case .holiday, .observance:
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
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<Contact>(predicate: #Predicate<Contact> { $0.id == uuid })
                editingContact = try? modelContext.fetch(descriptor).first
            }

        case .memo, .note, .event, .trip, .expense:
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<Memo>(predicate: #Predicate<Memo> { $0.id == uuid })
                editingMemo = try? modelContext.fetch(descriptor).first
            }
        }
    }

    // MARK: - Delete Handler

    private func deleteRow(_ row: SpecialDayRow) {
        switch row.type {
        case .holiday, .observance:
            deleteWithUndo(row: row)

        case .birthday:
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<Contact>(predicate: #Predicate<Contact> { $0.id == uuid })
                if let contact = try? modelContext.fetch(descriptor).first {
                    modelContext.delete(contact)
                    do { try modelContext.save() } catch { Log.e("Failed to save: \(error)") }
                    HapticManager.notification(.success)
                }
            }

        case .memo, .note, .event, .trip, .expense:
            if let uuid = UUID(uuidString: row.ruleID) {
                let descriptor = FetchDescriptor<Memo>(predicate: #Predicate<Memo> { $0.id == uuid })
                if let memo = try? modelContext.fetch(descriptor).first {
                    modelContext.delete(memo)
                    do { try modelContext.save() } catch { Log.e("Failed to save: \(error)") }
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
            symbol: row.symbolName ?? row.type.categoryAwareIcon,
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

                Task {
                    try? await Task.sleep(for: JohoDurations.notificationDuration)
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
