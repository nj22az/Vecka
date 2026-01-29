//
//  ModernCalendarView.swift
//  Vecka
//
//  Three-column layout with persistent icon sidebar
//  iPad: Sidebar | Calendar | Week Detail (side by side)
//  iPhone: Sidebar | Calendar stacked over Week Detail
//

import SwiftUI
import SwiftData

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToPage = Notification.Name("navigateToPage")
}

/// 情報デザイン: Combined context for day detail sheet
/// Ensures day and dataCheck are set atomically to avoid race conditions
struct DayDetailContext: Identifiable {
    var id: String { day.id }
    let day: CalendarDay
    let dataCheck: DayDataCheck
}

struct ModernCalendarView: View {
    // State
    @State private var selectedDate = Date()
    @State private var currentMonth: CalendarMonth = .current()
    @State private var selectedWeek: CalendarWeek?
    @State private var selectedDay: CalendarDay?
    @State private var selectedYear: Int = Calendar.iso8601.component(.year, from: Date())
    @State private var displayMonth: Int = Calendar.iso8601.component(.month, from: Date())
    @State private var isNavigatingMonth = false  // Prevents onChange race conditions
    @State private var isLegendExpanded = false   // 情報デザイン: Expandable legend row

    // Managers
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(NavigationManager.self) private var navigationManager
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Settings
    @AppStorage("systemUIAccent") private var systemUIAccent = "blue"

    @Query private var memos: [Memo]
    @Query private var contacts: [Contact]  // For birthday indicators
    private var holidayManager = HolidayManager.shared

    private var memoColors: [Date: String] {
        var dict: [Date: String] = [:]
        let calendar = Calendar.current
        for memo in memos.sorted(by: { $0.date < $1.date }) {
            let day = calendar.startOfDay(for: memo.date)
            dict[day] = memo.colorHex
        }
        return dict
    }

    // MARK: - Legend Data (情報デザイン)

    /// Legend item representing an indicator type present in the current month
    struct LegendItem: Identifiable {
        let id = UUID()
        let type: String
        let label: String
        let color: Color
    }

    /// Collects indicator types present in the current month view
    /// Priority order: HOL > BDY > OBS > EVT > NTE > TRP > EXP
    private var presentIndicators: [LegendItem] {
        var items: [LegendItem] = []
        var foundTypes: Set<String> = []

        // Scan all days in current month
        let monthDays = currentMonth.weeks.flatMap { $0.days }

        for day in monthDays {
            // Only check days actually in current month
            guard day.isInCurrentMonth else { continue }

            let dataCheck = hasDataForDay(day.date)

            // 1. Holiday - RED (highest priority)
            if dataCheck.hasHoliday && !foundTypes.contains("HOL") {
                items.append(LegendItem(type: "HOL", label: "Holiday", color: JohoColors.red))
                foundTypes.insert("HOL")
            }

            // 2. Birthday - PINK
            if dataCheck.hasBirthday && !foundTypes.contains("BDY") {
                items.append(LegendItem(type: "BDY", label: "Birthday", color: JohoColors.pink))
                foundTypes.insert("BDY")
            }

            // 3. Observance - CYAN (cultural observances)
            if dataCheck.hasObservance && !foundTypes.contains("OBS") {
                items.append(LegendItem(type: "OBS", label: "Observance", color: JohoColors.cyan))
                foundTypes.insert("OBS")
            }

            // 4. Event - PURPLE
            if dataCheck.hasEvent && !foundTypes.contains("EVT") {
                items.append(LegendItem(type: "EVT", label: "Event", color: JohoColors.cyan))
                foundTypes.insert("EVT")
            }

            // 5. Note - YELLOW
            if dataCheck.hasNote && !foundTypes.contains("NTE") {
                items.append(LegendItem(type: "NTE", label: "Note", color: JohoColors.yellow))
                foundTypes.insert("NTE")
            }

            // 6. Trip - BLUE
            if dataCheck.hasTrip && !foundTypes.contains("TRP") {
                items.append(LegendItem(type: "TRP", label: "Trip", color: JohoColors.cyan))
                foundTypes.insert("TRP")
            }

            // 7. Expense - GREEN (lowest priority)
            if dataCheck.hasExpense && !foundTypes.contains("EXP") {
                items.append(LegendItem(type: "EXP", label: "Expense", color: JohoColors.green))
                foundTypes.insert("EXP")
            }

            // Early exit if all 7 types found
            if foundTypes.count == 7 { break }
        }

        return items
    }

    /// Smart add button - show for Contacts and Star page (always visible)
    private var shouldShowAddButton: Bool {
        switch sidebarSelection {
        case .contacts, .specialDays:
            return true  // Always show plus button on these pages
        default:
            return false
        }
    }

    /// Add button color - matches page accent colors (情報デザイン)
    private var addButtonColor: Color {
        switch sidebarSelection {
        case .contacts:
            return JohoColors.pink       // Contacts = Pink
        case .specialDays:
            return JohoColors.yellow     // Star page = Yellow
        default:
            return JohoColors.cyan
        }
    }

    /// System UI accent for buttons (database-driven via settings)
    private var systemAccentColor: Color {
        (SystemUIAccent(rawValue: systemUIAccent) ?? .indigo).color
    }

    // 情報デザイン: Unified margins across all devices (iPhone golden standard)
    private var screenMargin: CGFloat { 16 }

    // Memo editor sheet
    @State private var showMemoSheet = false
    @State private var memoEditorDate: Date = Date()


    // Day Detail sheet (long-press on calendar day)
    // 情報デザイン: Combined context ensures day+dataCheck are set atomically
    @State private var dayDetailContext: DayDetailContext?

    // MARK: - Helper for sidebar add action
    private var sidebarAddAction: (() -> Void)? {
        guard shouldShowAddButton else { return nil }
        return {
            switch sidebarSelection {
            case .contacts:
                showContactMenu = true
            case .specialDays:
                showMemoSheet = true
            default:
                break
            }
        }
    }

    // Contact editor
    @State private var showContactEditor = false
    @State private var showObservanceEditor = false
    @State private var showHolidayEditor = false
    @State private var showContactMenu = false
    @State private var contactEditorMode: JohoContactEditorMode = .birthday

    // Star page month detail state (for smart + button)
    @State private var isInSpecialDaysMonthDetail = false

    @State private var sidebarSelection: SidebarSelection? = .landing  // 情報デザイン: Landing page first

    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])

    @State private var lunarConfig: LunarConfig?

    @Environment(\.locale) private var locale

    // MARK: - iPad Detail View

    @ViewBuilder
    private var detailView: some View {
        if let selection = sidebarSelection {
            switch selection {
            case .landing:
                NavigationStack {
                    LandingPageView()
                        .navigationBarHidden(true)
                        .toolbar(.hidden, for: .navigationBar)
                }
            case .calendar:
                NavigationStack {
                    calendarDetailView
                        .navigationBarHidden(true)
                        .toolbar(.hidden, for: .navigationBar)
                }
            case .specialDays:
                NavigationStack {
                    SpecialDaysListView(isInMonthDetail: $isInSpecialDaysMonthDetail)
                        .johoBackground()
                        .johoNavigation()
                }
            case .contacts:
                NavigationStack {
                    ContactListView()
                        .johoBackground()
                        .johoNavigation()
                }
            case .settings:
                NavigationStack {
                    SettingsView()
                        .johoBackground()
                        .johoNavigation()
                }
            }
        } else {
            ContentUnavailableView(
                Localization.selectItem,
                systemImage: "sidebar.left"
            )
            .johoBackground()
        }
    }

    // MARK: - Page Content for Swipe Navigation

    /// 情報デザイン: Content for each page in swipe navigation
    @ViewBuilder
    private func pageContent(for page: SidebarSelection?) -> some View {
        switch page {
        case .landing, .none:
            NavigationStack {
                LandingPageView()
                    .navigationBarHidden(true)
                    .toolbar(.hidden, for: .navigationBar)
            }
        case .calendar:
            NavigationStack {
                calendarDetailView
                    .navigationBarHidden(true)
                    .toolbar(.hidden, for: .navigationBar)
            }
        case .specialDays:
            NavigationStack {
                SpecialDaysListView(isInMonthDetail: $isInSpecialDaysMonthDetail)
                    .johoBackground()
                    .johoNavigation()
            }
        case .contacts:
            NavigationStack {
                ContactListView()
                    .johoBackground()
                    .johoNavigation()
            }
        case .settings:
            NavigationStack {
                SettingsView()
                    .johoBackground()
                    .johoNavigation()
            }
        }
    }

    /// Add action for iPhone dock (context-aware)
    /// 情報デザイン: Skip intermediate menu, go directly to unified entry form
    private var iPhoneDockAddAction: (() -> Void)? {
        guard shouldShowAddButton else { return nil }
        return {
            switch sidebarSelection {
            case .contacts:
                showContactMenu = true
            case .specialDays:
                showMemoSheet = true
            default:
                break
            }
        }
    }

    var body: some View {
        mainContent
            .sheet(item: $dayDetailContext) { context in
                DayDetailSheet(day: context.day, dataCheck: context.dataCheck)
            }
            .sheet(isPresented: $showMemoSheet) {
                memoEditorSheet
            }
            .sheet(isPresented: $showContactEditor) {
                JohoContactEditorSheet(mode: contactEditorMode)
                    .presentationCornerRadius(20)
            }
            .sheet(isPresented: $showContactMenu) {
                contactMenuSheet
            }
            .sheet(isPresented: $showObservanceEditor) {
                observanceEditorSheet
            }
            .sheet(isPresented: $showHolidayEditor) {
                holidayEditorSheet
            }
            .johoYearPicker(
                isPresented: $showMonthPicker,
                selectedMonth: $displayMonth,
                selectedYear: $selectedYear,
                accentColor: (SystemUIAccent(rawValue: systemUIAccent) ?? .indigo).color
            )
            .onChange(of: displayMonth) { _, newMonth in
                currentMonth = CalendarMonth(year: selectedYear, month: newMonth, noteColors: memoColors)
                updateSelectedWeekAndDay()
            }
            .onAppear {
                AppInitializer.initialize(context: modelContext)
                updateLunarConfig()
                updateMonthFromDate()
            }
            .onChange(of: holidayRegions) { _, _ in
                updateLunarConfig()
                holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
            }
            .onChange(of: selectedDate) { _, newDate in
                updateMonthFromDate(from: newDate)
            }
            .onChange(of: memos) { _, _ in
                updateMonthFromDate()
            }
            .onChange(of: contacts) { _, _ in
                updateMonthFromDate()
            }
            .onChange(of: selectedYear) { _, newYear in
                currentMonth = CalendarMonth(year: newYear, month: displayMonth, noteColors: memoColors)
                updateSelectedWeekAndDay()
                holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: newYear)
            }
            .onChange(of: navigationManager.targetDate) { _, newDate in
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDate = newDate
                }
            }
            .onChange(of: navigationManager.shouldNavigateToPage) { _, shouldNavigate in
                if shouldNavigate {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        sidebarSelection = navigationManager.targetPage
                    }
                    navigationManager.shouldNavigateToPage = false
                }
            }
    }

    // MARK: - Main Content (Extracted for Type-Checker)

    @ViewBuilder
    private var mainContent: some View {
        if horizontalSizeClass == .regular {
            iPadLayout
        } else {
            iPhoneSwipeLayout
        }
    }

    // MARK: - iPad Layout (NavigationSplitView)

    private var iPadLayout: some View {
        NavigationSplitView {
            AppSidebar(selection: $sidebarSelection)
                .johoBackground()
        } detail: {
            detailView
        }
        .johoBackground()
        .onAppear {
            if sidebarSelection == nil {
                sidebarSelection = .landing
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToPage)) { notification in
            if let page = notification.object as? SidebarSelection {
                withAnimation(.easeInOut(duration: 0.3)) {
                    sidebarSelection = page
                }
            }
        }
    }

    // MARK: - iPhone Layout (Swipe Navigation)

    private var iPhoneSwipeLayout: some View {
        VStack(spacing: 0) {
            SwipeNavigationContainer(selection: $sidebarSelection) { page in
                pageContent(for: page)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Rectangle()
                .fill(colors.border)
                .frame(height: 2)

            IconStripDock(selection: $sidebarSelection)
        }
        .johoBackground()
        .onAppear {
            if sidebarSelection == nil {
                sidebarSelection = .landing
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToPage)) { notification in
            if let page = notification.object as? SidebarSelection {
                withAnimation(.easeInOut(duration: 0.3)) {
                    sidebarSelection = page
                }
            }
        }
    }

    // MARK: - Sheet Contents (Extracted for Type-Checker)

    // 情報デザイン: Unified entry creator for calendar context (Memo only)
    private var memoEditorSheet: some View {
        UnifiedEntryCreator(
            config: .calendarContext(date: memoEditorDate),
            onSaveMemo: { text, date, amount, currency, place, contactID, photoData in
                saveMemo(text: text, date: date, amount: amount, currency: currency, place: place, contactID: contactID, photoData: photoData)
            }
        )
        .presentationDetents([.large])
        .presentationCornerRadius(20)
    }

    private func saveMemo(text: String, date: Date, amount: Double?, currency: String?, place: String?, contactID: UUID?, photoData: Data?) {
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

    /// 情報デザイン: Create a holiday/observance from unified entry creator
    private func createHolidayRule(type: SpecialDayType, name: String, about: String?, region: String, year: Int, month: Int, day: Int) {
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

    private var contactMenuSheet: some View {
        JohoAddContactSheet(
            onSelectContact: {
                showContactMenu = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    contactEditorMode = .contact
                    showContactEditor = true
                }
            }
        )
    }

    private var observanceEditorSheet: some View {
        JohoSpecialDayEditorSheet(
            mode: .create,
            type: .observance,
            defaultRegion: holidayRegions.primaryRegion ?? "SE",
            onSave: { name, date, symbol, iconColor, notes, region in
                createObservance(name: name, date: date, symbol: symbol, iconColor: iconColor, notes: notes, region: region)
            }
        )
        .presentationCornerRadius(20)
    }

    private var holidayEditorSheet: some View {
        JohoSpecialDayEditorSheet(
            mode: .create,
            type: .holiday,
            defaultRegion: holidayRegions.primaryRegion ?? "SE",
            onSave: { name, date, symbol, iconColor, notes, region in
                createHoliday(name: name, date: date, symbol: symbol, iconColor: iconColor, notes: notes, region: region)
            }
        )
        .presentationCornerRadius(20)
    }

    // monthPickerSheet removed - now using JohoYearPicker overlay

    // MARK: - Calendar Detail View

    private var calendarDetailView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: JohoDimensions.spacingMD) {
                // 情報デザイン: Bento-style page header (Golden Standard Pattern)
                calendarPageHeader
                    .padding(.horizontal, screenMargin)

                // Calendar Grid in WHITE container with thick black border
                // 情報デザイン: No swipe gesture - use month picker in header instead
                JohoCalendarContainer {
                    CalendarGridView(
                        month: currentMonth,
                        selectedWeek: selectedWeek,
                        selectedDay: selectedDay,
                        onDayTap: handleDayTap,
                        onWeekTap: handleWeekTap,
                        onDayLongPress: handleDayLongPress,
                        hasDataForDay: hasDataForDay
                    )
                    .id("\(currentMonth.month)-\(currentMonth.year)-\(contacts.count)-\(memos.count)")
                }
                .padding(.horizontal, screenMargin)

                // 情報デザイン: Legend moved to Settings for cleaner calendar view

                // 情報デザイン: Day Dashboard - each section is its own Bento (matches landing page)
                let dashboardDate = Calendar.iso8601.startOfDay(for: selectedDay?.date ?? selectedDate)
                DayDashboardView(
                    date: dashboardDate,
                    memos: memosForDay(dashboardDate),
                    holidays: holidayInfo(for: dashboardDate),
                    birthdays: birthdaysForDay(dashboardDate),
                    secondaryDateText: lunarDashboardText(for: dashboardDate),
                    onOpenMemos: { targetDate in
                        memoEditorDate = targetDate
                        showMemoSheet = true
                    }
                )
                .id(dashboardDate)
                .padding(.horizontal, screenMargin)
            }
            .padding(.top, JohoDimensions.spacingSM) // 情報デザイン: Consistent with all pages
            .padding(.bottom, JohoDimensions.spacingLG)
        }
        .scrollBounceBehavior(.basedOnSize)
        .johoBackground()
    }

    // MARK: - Calendar Legend (情報デザイン)

    /// Expandable legend row showing indicator types present in current month
    private var calendarLegend: some View {
        VStack(spacing: 0) {
            // Header row - tappable to expand/collapse
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isLegendExpanded.toggle()
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Icon zone - list bullet in cyan squircle
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 24, height: 24)
                        .background(JohoColors.cyan.opacity(0.3))
                        .clipShape(Squircle(cornerRadius: 5))
                        .overlay(Squircle(cornerRadius: 5).stroke(colors.border, lineWidth: 1))

                    Text("LEGEND")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(colors.primary)

                    Image(systemName: isLegendExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.secondary)

                    Spacer()

                    // Count badge showing number of indicator types
                    if !presentIndicators.isEmpty {
                        Text("\(presentIndicators.count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.secondary)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
            }
            .buttonStyle(.plain)

            // Expanded content - shows indicator types with colors
            if isLegendExpanded && !presentIndicators.isEmpty {
                Rectangle()
                    .fill(colors.border.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, JohoDimensions.spacingMD)

                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: JohoDimensions.spacingSM)
                ], spacing: JohoDimensions.spacingSM) {
                    ForEach(presentIndicators) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(colors.border, lineWidth: 1))

                            Text(item.label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)
                        }
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Legend, \(presentIndicators.count) indicator types")
        .accessibilityHint(isLegendExpanded ? "Tap to collapse" : "Tap to expand")
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Toolbar is now minimal - main controls moved to in-content unified menu
        // Keep empty for clean appearance, or add back navigation if needed
        ToolbarItem(placement: .principal) {
            EmptyView()
        }
    }



    // MARK: - Month/Year Header

    @State private var showMonthPicker = false

    private var monthYearHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showMonthPicker = true
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "\(currentMonth.year)")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primaryInverted.opacity(0.6))

                    Text(monthTitle)
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primaryInverted)
                }

                Image(systemName: "chevron.down")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(colors.primaryInverted.opacity(0.7))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(colors.surfaceInverted)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(colors.primaryInverted, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(monthTitle) \(currentMonth.year)")
        .accessibilityHint(Localization.tapToChangeMonth)
    }

    private var monthTitle: String {
        let language = locale.language.languageCode?.identifier

        // Always use full month name as per user request (no truncation)
        let monthName = currentMonth.monthName

        if language == "sv" {
            return monthName.capitalized(with: locale)
        }
        return monthName
    }

    // MARK: - Calendar Page Header (情報デザイン: Golden Standard Pattern)

    /// Bento-style page header matching Star Page pattern
    private var calendarPageHeader: some View {
        let today = Date()
        let dayNumber = Calendar.iso8601.component(.day, from: today)
        let weekday = today.formatted(.dateTime.weekday(.abbreviated)).uppercased()
        let weekNumber = Calendar.iso8601.component(.weekOfYear, from: today)
        let isViewingToday = Calendar.iso8601.isDate(selectedDate, inSameDayAs: today)

        return VStack(spacing: 0) {
            // MAIN ROW: Icon + Title | WALL | Month Picker
            HStack(spacing: 0) {
                // LEFT COMPARTMENT: Icon + Title
                HStack(spacing: JohoDimensions.spacingSM) {
                    // 情報デザイン: Purple calendar icon (app identity, not seasonal)
                    Image(systemName: "calendar")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(PageHeaderColor.calendar.accent)
                        .frame(width: 40, height: 40)
                        .background(PageHeaderColor.calendar.lightBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(colors.border, lineWidth: 1.5)
                        )

                    // Title
                    Text("CALENDAR")
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primary)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

                // VERTICAL WALL
                Rectangle()
                    .fill(colors.border)
                    .frame(width: 1.5)

                // RIGHT COMPARTMENT: Month/Year Picker
                calendarMonthPicker
                    .padding(.horizontal, JohoDimensions.spacingSM)
            }
            .frame(minHeight: 56)

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // TODAY ROW: Today info + Add button + Go to Today button + Week badge
            HStack(spacing: JohoDimensions.spacingSM) {
                // Today info display
                HStack(spacing: JohoDimensions.spacingXS) {
                    // Day number
                    Text("\(dayNumber)")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(colors.primary)

                    // Weekday
                    Text(weekday)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.secondary)
                }

                Spacer()

                // 情報デザイン: Go to Today button (Yellow = NOW/Present)
                // Only show when not viewing today
                if !isViewingToday {
                    Button(action: jumpToToday) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Text("TODAY")
                                .font(JohoFont.labelSmall)
                        }
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(JohoColors.yellow)
                        .clipShape(Squircle(cornerRadius: 6))
                        .overlay(
                            Squircle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Week badge
                Text("W\(weekNumber)")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(colors.primaryInverted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colors.surfaceInverted)
                    .clipShape(Capsule())

                // 情報デザイン: Add entry button (matches Star page month detail - far right)
                Button {
                    memoEditorDate = selectedDay?.date ?? selectedDate
                    showMemoSheet = true
                    HapticManager.impact(.light)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(systemAccentColor)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
        )
    }

    /// Month picker for Calendar header (< January 2026 >)
    private var calendarMonthPicker: some View {
        HStack(spacing: 4) {
            Button { navigateToPreviousMonth() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 24, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMonthPicker = true
                }
                HapticManager.selection()
            } label: {
                VStack(spacing: 0) {
                    Text(monthTitle)
                        .font(JohoFont.bodySmall.bold())
                        .foregroundStyle(colors.primary)
                    Text(String(currentMonth.year))
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(colors.secondary)
                        .monospacedDigit()
                }
            }
            .buttonStyle(.plain)

            Button { navigateToNextMonth() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(width: 24, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Notes Helpers

    private func memosForDay(_ date: Date) -> [Memo] {
        let day = Calendar.iso8601.startOfDay(for: date)
        return memos.filter {
            Calendar.iso8601.startOfDay(for: $0.date) == day
        }.sorted(by: { $0.date < $1.date })
    }

    /// 情報デザイン: Check all special day types for calendar indicators
    private func hasDataForDay(_ date: Date) -> DayDataCheck {
        // 情報デザイン: Use Calendar.current for holiday cache lookup (matches HolidayManager key format)
        let day = Calendar.current.startOfDay(for: date)

        var check = DayDataCheck()

        // Check holidays and observances from cache
        // 情報デザイン: Pre-compute holiday info to avoid accessing computed properties during sheet presentation
        // Use static HolidayManager.cache to avoid MainActor isolation issues
        if let cachedHolidays = HolidayManager.cache[day] {
            var observanceNames: [String] = []
            for holiday in cachedHolidays {
                if holiday.isBankHoliday {
                    check.hasHoliday = true
                    // Capture first bank holiday's info for the detail sheet
                    if check.holidayName == nil {
                        check.holidayName = holiday.displayTitle
                        check.holidaySymbolName = holiday.symbolName
                    }
                } else {
                    check.hasObservance = true
                    observanceNames.append(holiday.displayTitle)
                }
            }
            check.observanceNames = observanceNames
        }

        // Check memos for the day
        let dayMemos = memos.filter { Calendar.current.startOfDay(for: $0.date) == day }

        // Check for notes (memos WITHOUT money AND WITHOUT place - pure text notes)
        let noteMemos = dayMemos.filter { !$0.hasMoney && !$0.hasPlace }
        if let firstNote = noteMemos.first {
            check.hasNote = true
            check.noteContent = firstNote.text
        }

        // Check expenses - calculate total amount for the day
        let expenseMemos = dayMemos.filter { $0.hasMoney }
        if !expenseMemos.isEmpty {
            check.hasExpense = true
            check.expenseAmount = expenseMemos.reduce(0.0) { $0 + ($1.amount ?? 0) }
        }

        // Check trips (memos with place)
        if let tripMemo = dayMemos.first(where: { $0.hasPlace }) {
            check.hasTrip = true
            check.tripDestination = tripMemo.place
            check.tripPosition = .single // Single day for memo-based trips
        }

        // Check birthdays from contacts (match month/day regardless of year)
        let calendar = Calendar.current
        let month = calendar.component(.month, from: day)
        let dayOfMonth = calendar.component(.day, from: day)

        var birthdayNames: [String] = []
        for contact in contacts {
            guard let birthday = contact.birthday else { continue }
            let bMonth = calendar.component(.month, from: birthday)
            let bDay = calendar.component(.day, from: birthday)
            if bMonth == month && bDay == dayOfMonth {
                birthdayNames.append(contact.displayName)
            }
        }
        if !birthdayNames.isEmpty {
            check.hasBirthday = true
            check.birthdayNames = birthdayNames
        }

        return check
    }

    // MARK: - Week Detail Helpers

    private func holidaysForWeek(_ week: CalendarWeek) -> [HolidayCacheItem] {
        var result: [HolidayCacheItem] = []
        for day in week.days {
            let dayStart = Calendar.iso8601.startOfDay(for: day.date)
            if let holidays = holidayManager.holidayCache[dayStart] {
                result.append(contentsOf: holidays)
            }
        }
        return result
    }

    private func color(for colorName: String) -> Color {
        switch colorName {
        case "red": return JohoColors.pink
        case "blue": return JohoColors.cyan
        case "green": return JohoColors.green
        case "orange": return JohoColors.cyan
        case "purple": return JohoColors.pink
        case "yellow": return JohoColors.yellow
        default: return JohoColors.cyan
        }
    }

    private func holidayInfo(for date: Date) -> [DayDashboardView.HolidayInfo] {
        // 情報デザイン: Use Calendar.current to match HolidayManager cache key format
        let day = Calendar.current.startOfDay(for: date)
        let holidays = holidayManager.holidayCache[day] ?? []
        return holidays.map { holiday in
            DayDashboardView.HolidayInfo(
                id: holiday.id,
                name: holiday.displayTitle,
                isBankHoliday: holiday.isBankHoliday,
                symbolName: holiday.symbolName,
                regionCode: holiday.region
            )
        }
    }

    /// 情報デザイン: Get contact birthdays matching a specific day (month/day comparison)
    private func birthdaysForDay(_ date: Date) -> [DayDashboardView.BirthdayInfo] {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let dayOfMonth = calendar.component(.day, from: date)
        let currentYear = calendar.component(.year, from: date)

        var result: [DayDashboardView.BirthdayInfo] = []
        for contact in contacts {
            guard let birthday = contact.birthday else { continue }
            let bMonth = calendar.component(.month, from: birthday)
            let bDay = calendar.component(.day, from: birthday)
            if bMonth == month && bDay == dayOfMonth {
                // Calculate age if birth year is known
                let birthYear = calendar.component(.year, from: birthday)
                // If birth year is reasonable (not 1604 placeholder), calculate age
                let age: Int? = birthYear > 1900 ? currentYear - birthYear : nil
                result.append(DayDashboardView.BirthdayInfo(
                    id: contact.id.uuidString,
                    name: contact.displayName,
                    age: age
                ))
            }
        }
        return result
    }

    private struct LunarConfig: Equatable {
        let calendarIdentifier: Calendar.Identifier
        let localeIdentifier: String
    }

    private func updateLunarConfig() {
        guard holidayRegions.containsVietnam else {
            lunarConfig = nil
            return
        }

        do {
            let descriptor = FetchDescriptor<CalendarRule>(predicate: #Predicate<CalendarRule> { $0.id == "VN" })
            let rules = try modelContext.fetch(descriptor)
            if let rule = rules.first,
               let secondary = rule.secondaryCalendarIdentifier,
               let identifier = Calendar.Identifier.from(secondary) {
                lunarConfig = LunarConfig(calendarIdentifier: identifier, localeIdentifier: rule.localeIdentifier)
            } else {
                lunarConfig = LunarConfig(calendarIdentifier: .chinese, localeIdentifier: "vi_VN")
            }
        } catch {
            lunarConfig = LunarConfig(calendarIdentifier: .chinese, localeIdentifier: "vi_VN")
        }
    }

    private func lunarDateString(for date: Date) -> String? {
        guard let config = lunarConfig else { return nil }
        let calendar = Calendar(identifier: config.calendarIdentifier)
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let day = components.day, let month = components.month else { return nil }
        return "\(day)/\(month)"
    }

    private func lunarDashboardText(for date: Date) -> String? {
        guard let lunar = lunarDateString(for: date) else { return nil }
        return "\(Localization.lunar) \(lunar)"
    }

    // MARK: - Actions

    // MARK: - Month Navigation (情報デザイン: Clear, Predictable Logic)
    //
    // Design Principle: "Same date, different month"
    // - Jan 15 → Feb 15 (same day)
    // - Jan 30 → Feb 28 (clamped to valid day)
    // - Dec 31 → Jan 31 (same day)
    //
    // Implementation: selectedDate is the SINGLE SOURCE OF TRUTH.
    // Navigation updates selectedDate, onChange handlers sync all derived state.

    private func navigateToPreviousMonth() {
        selectedDate = calculateMonthOffset(from: selectedDate, months: -1)
    }

    private func navigateToNextMonth() {
        selectedDate = calculateMonthOffset(from: selectedDate, months: 1)
    }

    /// Calculate a date offset by N months, preserving the day number where possible.
    /// Clamps to the last valid day if the target month has fewer days.
    ///
    /// Examples:
    /// - Jan 15, +1 month → Feb 15
    /// - Jan 30, +1 month → Feb 28 (or 29 in leap year)
    /// - Mar 31, -1 month → Feb 28 (or 29 in leap year)
    /// - Dec 31, +1 month → Jan 31
    private func calculateMonthOffset(from date: Date, months: Int) -> Date {
        let calendar = Calendar.iso8601

        // Extract current date components
        let currentDay = calendar.component(.day, from: date)
        let currentMonth = calendar.component(.month, from: date)
        let currentYear = calendar.component(.year, from: date)

        // Calculate target month and year
        var targetMonth = currentMonth + months
        var targetYear = currentYear

        // Handle month overflow/underflow
        while targetMonth > 12 {
            targetMonth -= 12
            targetYear += 1
        }
        while targetMonth < 1 {
            targetMonth += 12
            targetYear -= 1
        }

        // Find the maximum valid day in the target month
        var components = DateComponents()
        components.year = targetYear
        components.month = targetMonth
        components.day = 1

        guard let firstOfTargetMonth = calendar.date(from: components),
              let rangeOfDays = calendar.range(of: .day, in: .month, for: firstOfTargetMonth) else {
            // Fallback: just add months using Calendar (may shift day unexpectedly)
            return calendar.date(byAdding: .month, value: months, to: date) ?? date
        }

        let maxDayInTarget = rangeOfDays.count

        // Clamp the day to valid range
        let clampedDay = min(currentDay, maxDayInTarget)

        // Build the final date
        components.day = clampedDay
        return calendar.date(from: components) ?? date
    }

    /// Update selected week and day after month navigation
    private func updateSelectedWeekAndDay() {
        if let week = selectedWeek {
            let weekInNewMonth = currentMonth.weeks.contains(where: { $0.weekNumber == week.weekNumber })
            if !weekInNewMonth {
                selectedWeek = currentMonth.weeks.first
                // Pick a day that's actually IN this month (ISO weeks can span months)
                if let firstWeek = selectedWeek {
                    let targetMonth = currentMonth.month
                    let dayInMonth = firstWeek.days.first(where: {
                        Calendar.iso8601.component(.month, from: $0.date) == targetMonth
                    }) ?? firstWeek.days.first
                    selectedDay = dayInMonth
                    selectedDate = dayInMonth?.date ?? selectedDate
                }
            }
        }
    }

    private func handleDayTap(_ day: CalendarDay) {
        // 情報デザイン: Single tap selects day, shows day content below
        // Use + button in DayDashboard to add entries
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = day.date
            selectedDay = day
            if let week = currentMonth.weeks.first(where: { $0.days.contains(where: { $0.id == day.id }) }) {
                selectedWeek = week
            }
        }
    }

    /// 情報デザイン: Long-press opens day detail sheet
    private func handleDayLongPress(_ day: CalendarDay) {
        // Get base data check from hasDataForDay (expenses, notes, trips, events, birthdays)
        var dataCheck = hasDataForDay(day.date)

        // Debug: Check what's in the cache
        // 情報デザイン: Use CalendarDay's computed properties for holiday info
        // These are known to work (they show the red star) and are thread-safe
        if day.isHoliday {
            dataCheck.hasHoliday = true
            dataCheck.holidayName = day.holidayName
            dataCheck.holidaySymbolName = day.holidaySymbolName
        } else if day.isSignificant {
            dataCheck.hasObservance = true
        }

        // 情報デザイン: Set combined context atomically to avoid race conditions
        dayDetailContext = DayDetailContext(day: day, dataCheck: dataCheck)
    }



    private func handleWeekTap(_ week: CalendarWeek) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedWeek = week
            if let today = week.today {
                selectedDay = today
                selectedDate = today.date
            } else {
                selectedDay = week.days.first
                selectedDate = week.days.first?.date ?? selectedDate
            }
        }

    }

    private func handleMonthChange(month: Int, year: Int) {
        withAnimation {
            currentMonth = CalendarMonth(year: year, month: month, noteColors: memoColors)
            if let week = selectedWeek {
                let weekInNewMonth = currentMonth.weeks.contains(where: { $0.weekNumber == week.weekNumber })
                if !weekInNewMonth {
                    selectedWeek = currentMonth.weeks.first
                    selectedDay = selectedWeek?.days.first
                    selectedDate = selectedDay?.date ?? selectedDate
                }
            }
        }
    }

    private func jumpToToday() {
        withAnimation {
            selectedDate = Date()
            displayMonth = Calendar.iso8601.component(.month, from: Date())
            selectedYear = Calendar.iso8601.component(.year, from: Date())
            currentMonth = .current(noteColors: memoColors)

            if let week = currentMonth.weeks.first(where: { $0.isCurrentWeek }) {
                selectedWeek = week
                selectedDay = week.today
            }
        }
    }

    private func updateMonthFromDate(from date: Date? = nil) {
        let dateToUse = date ?? selectedDate
        let month = Calendar.iso8601.component(.month, from: dateToUse)
        let year = Calendar.iso8601.component(.year, from: dateToUse)

        displayMonth = month
        selectedYear = year

        if currentMonth.month != month || currentMonth.year != year {
            currentMonth = CalendarMonth(year: year, month: month, noteColors: memoColors)
        } else {
            currentMonth = CalendarMonth(year: currentMonth.year, month: currentMonth.month, noteColors: memoColors)
        }

        if let week = currentMonth.weeks.first(where: { week in
            week.days.contains(where: { Calendar.iso8601.isDate($0.date, inSameDayAs: dateToUse) })
        }) {
            selectedWeek = week
            selectedDay = week.days.first(where: { Calendar.iso8601.isDate($0.date, inSameDayAs: dateToUse) })
        }
    }

    // MARK: - Observance Creation (sidebar +)

    private func createObservance(name: String, date: Date, symbol: String, iconColor: String?, notes: String?, region: String) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let rule = HolidayRule(
            name: name,
            region: region.isEmpty ? (holidayRegions.primaryRegion ?? "SE") : region,
            isBankHoliday: false,
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
            Log.w("Failed to create observance: \(error.localizedDescription)")
            HapticManager.notification(.error)
        }
    }

    // MARK: - Holiday Creation (sidebar +)

    private func createHoliday(name: String, date: Date, symbol: String, iconColor: String?, notes: String?, region: String) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let rule = HolidayRule(
            name: name,
            region: region.isEmpty ? (holidayRegions.primaryRegion ?? "SE") : region,
            isBankHoliday: true,  // Red day = holiday
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
            Log.w("Failed to create holiday: \(error.localizedDescription)")
            HapticManager.notification(.error)
        }
    }

}

// MARK: - Preview

#Preview("iPad Pro 13\"") {
    Group {
        if let container = try? ModelContainer(
            for: HolidayRule.self, CalendarRule.self, Memo.self, Contact.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ) {
            ModernCalendarView()
                .modelContainer(container)
                .environment(NavigationManager())
        } else {
            Text("Preview unavailable")
        }
    }
}

#Preview("iPhone 16e") {
    Group {
        if let container = try? ModelContainer(
            for: HolidayRule.self, CalendarRule.self, Memo.self, Contact.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ) {
            ModernCalendarView()
                .modelContainer(container)
                .environment(NavigationManager())
        } else {
            Text("Preview unavailable")
        }
    }
}
