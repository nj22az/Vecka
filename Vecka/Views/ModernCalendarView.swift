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
    @Query private var notes: [DailyNote]
    @Query private var expenses: [ExpenseItem]
    @Query private var trips: [TravelTrip]
    @Query private var contacts: [Contact]  // For birthday indicators
    @Query private var countdownEvents: [CountdownEvent]  // For event indicators
    private var holidayManager = HolidayManager.shared

    private var noteColors: [Date: String] {
        var dict: [Date: String] = [:]
        // Sort notes by date so later notes overwrite earlier ones (showing latest color)
        let sortedNotes = notes.sorted { $0.date < $1.date }

        for note in sortedNotes {
            dict[note.day] = note.color ?? "default"
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

            // 3. Observance - PINK (celebration category)
            if dataCheck.hasObservance && !foundTypes.contains("OBS") {
                items.append(LegendItem(type: "OBS", label: "Observance", color: JohoColors.pink))
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

    // 情報デザイン: Unified margins across all devices (iPhone golden standard)
    private var screenMargin: CGFloat { 16 }

    // Day Notes sheet (Apple Calendar-style bottom sheet)
    @State private var showDayNotesSheet = false
    @State private var dayNotesDate: Date = Date()
    @State private var dayNotesStartCreating = false
    @State private var dayNotesDetent: PresentationDetent = .medium
    
    // Direct note editor (skips notes list, opens editor immediately)
    @State private var showNoteEditor = false
    @State private var noteEditorDate: Date = Date()


    // PDF Export sheet
    @State private var showPDFExport = false
    @State private var pdfExportContext: PDFExportContext = .summary

    // Week Detail sheet (iPhone only)
    @State private var showWeekDetailSheet = false

    // Day Detail sheet (long-press on calendar day)
    // Note: Day detail sheet is controlled via .sheet(item: $dayDetailDay)
    @State private var dayDetailDay: CalendarDay?
    @State private var dayDetailDataCheck: DayDataCheck?

    // Context-aware add sheets (triggered from sidebar +)
    @State private var showExpenseEditor = false

    // MARK: - Helper for sidebar add action (extracted for type checking)
    // 情報デザイン: Skip intermediate menu, go directly to unified entry form
    private var sidebarAddAction: (() -> Void)? {
        guard shouldShowAddButton else { return nil }
        return {
            switch sidebarSelection {
            case .contacts:
                showContactMenu = true
            case .specialDays:
                showUnifiedEntry = true  // 情報デザイン: Direct to unified entry (5 types)
            default:
                break
            }
        }
    }

    // Export action removed - share functionality not ready yet
    private var sidebarExportAction: (() -> Void)? {
        return nil
    }
    @State private var showTripEditor = false
    @State private var showContactEditor = false
    @State private var showObservanceEditor = false
    @State private var showHolidayEditor = false
    // showSpecialDayMenu removed - 情報デザイン: Go directly to unified entry form
    @State private var showContactMenu = false
    @State private var contactEditorMode: JohoContactEditorMode = .birthday
    @State private var showCountdownEditor = false
    @State private var countdownEditorName: String = ""
    @State private var countdownEditorDate: Date = Date()
    @State private var countdownEditorIsAnnual: Bool = false
    @State private var countdownEditorType: CountdownType = .custom

    // 情報デザイン: Unified Entry sheet (Note/Trip/Expense)
    @State private var showUnifiedEntry = false

    // Star page month detail state (for smart + button)
    @State private var isInSpecialDaysMonthDetail = false

    // NavigationSplitView column visibility
    // .automatic lets the system decide based on device orientation and size
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
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

    // MARK: - iPhone Layout (Icon Strip Dock)

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            // Content area
            Group {
                switch sidebarSelection {
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
                case .contacts:
                    NavigationStack {
                        ContactListView()
                            .johoBackground()
                            .johoNavigation()
                    }
                case .specialDays:
                    NavigationStack {
                        SpecialDaysListView(isInMonthDetail: $isInSpecialDaysMonthDetail)
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
            .frame(maxHeight: .infinity)

            // Bottom dock (5 navigation items only)
            IconStripDock(selection: $sidebarSelection)
        }
        .johoBackground()
        .onAppear {
            // Initialize sidebarSelection for iPhone if nil
            if sidebarSelection == nil {
                sidebarSelection = .calendar
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
                showUnifiedEntry = true  // 情報デザイン: Direct to unified entry (5 types)
            default:
                break
            }
        }
    }

    var body: some View {
        Group {
            // Both iPad and iPhone: Bottom dock navigation (情報デザイン)
            // User preference: unified design across devices
            VStack(spacing: 0) {
                // Content area (dock-only navigation)
                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 情報デザイン: Thick border between content and dock
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // Bottom dock (5 navigation items only)
                IconStripDock(selection: $sidebarSelection)
            }
            .johoBackground()
            .onAppear {
                if sidebarSelection == nil {
                    sidebarSelection = .landing
                }
            }
            // Handle navigation from Onsen Map tiles
            .onReceive(NotificationCenter.default.publisher(for: .navigateToPage)) { notification in
                if let page = notification.object as? SidebarSelection {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        sidebarSelection = page
                    }
                }
            }
        }
        // Week Detail Sheet (iPhone only - slides up when week tapped)
        .sheet(isPresented: $showWeekDetailSheet) {
            if let week = selectedWeek {
                NavigationStack {
                    WeekDetailSheetContent(
                        week: week,
                        selectedDay: selectedDay,
                        notes: notesForWeek(week),
                        holidays: holidaysForWeek(week),
                        trips: tripsForWeek(week),  // 情報デザイン: Pass trips for week
                        onDayTap: { day in
                            handleDayTap(day)
                            showWeekDetailSheet = false
                        }
                    )
                    .navigationTitle("Week \(week.weekNumber)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showWeekDetailSheet = false
                            }
                        }
                    }
                    .johoNavigation()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(JohoColors.background)
            }
        }
        .sheet(isPresented: $showDayNotesSheet, onDismiss: {
            dayNotesStartCreating = false
            dayNotesDetent = .medium
        }) {
            NavigationStack {
                DailyNotesView(selectedDate: dayNotesDate, isModal: true, startCreating: dayNotesStartCreating)
            }
            .presentationDetents([.medium, .large], selection: $dayNotesDetent)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
            .presentationBackground(JohoColors.background)  // 情報デザイン: BLACK sheet background for AMOLED
        }
        // 情報デザイン: Day Detail Sheet (long-press on calendar day)
        .sheet(item: $dayDetailDay) { day in
            DayDetailSheet(day: day, dataCheck: dayDetailDataCheck)
        }
        .sheet(isPresented: $showPDFExport) {
            SimplePDFExportView(exportContext: pdfExportContext)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showNoteEditor) {
            JohoNoteEditorSheet(selectedDate: noteEditorDate)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        // Context-aware add sheets (triggered from sidebar +)
        .sheet(isPresented: $showExpenseEditor) {
            ExpenseEntryView()
                .presentationCornerRadius(20)
        }
        // 情報デザイン: Unified Entry sheet (Note/Trip/Expense)
        .sheet(isPresented: $showUnifiedEntry) {
            JohoUnifiedEntrySheet(selectedDate: selectedDate)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showTripEditor) {
            NavigationStack {
                AddTripView()
            }
            .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showContactEditor) {
            JohoContactEditorSheet(mode: contactEditorMode)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showContactMenu) {
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
        .sheet(isPresented: $showObservanceEditor) {
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
        .sheet(isPresented: $showHolidayEditor) {
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
        // 情報デザイン: Intermediate menu removed - unified entry form has all 5 types
        // (note, trip, expense, holiday, birthday)
        .sheet(isPresented: $showCountdownEditor) {
            NavigationStack {
                CustomCountdownDialog(
                    name: $countdownEditorName,
                    date: $countdownEditorDate,
                    isAnnual: $countdownEditorIsAnnual,
                    selectedCountdown: $countdownEditorType,
                    onSave: {
                        // Reset for next time
                        countdownEditorName = ""
                        countdownEditorDate = Date()
                        countdownEditorIsAnnual = false
                    }
                )
            }
            .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showMonthPicker) {
            MonthPickerSheet(
                initialMonth: displayMonth,
                initialYear: selectedYear
            ) { newMonth, newYear in
                // Update currentMonth FIRST so onChange handlers see correct state
                currentMonth = CalendarMonth(year: newYear, month: newMonth, noteColors: noteColors)
                displayMonth = newMonth
                selectedYear = newYear
                updateSelectedWeekAndDay()
            }
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(20)
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
        .onChange(of: notes) { _, _ in
            updateMonthFromDate()
        }
        .onChange(of: contacts) { _, _ in
            // Force calendar grid to update when contacts change
            updateMonthFromDate()
        }
        .onChange(of: countdownEvents) { _, _ in
            // Force calendar grid to update when events change
            updateMonthFromDate()
        }
        // Note: Month navigation is handled directly by navigateToPreviousMonth/navigateToNextMonth
        // and MonthPickerSheet callback. Only year change triggers holiday recalculation.
        .onChange(of: selectedYear) { _, newYear in
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: newYear)
        }
        .onChange(of: navigationManager.targetDate) { _, newDate in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selectedDate = newDate
            }
        }
        // 情報デザイン: Widget deep links navigate to landing page (Onsen is home)
        .onChange(of: navigationManager.shouldNavigateToPage) { _, shouldNavigate in
            if shouldNavigate {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    sidebarSelection = navigationManager.targetPage
                }
                navigationManager.shouldNavigateToPage = false
            }
        }
    }

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
                    .id("\(currentMonth.month)-\(currentMonth.year)-\(contacts.count)-\(notes.count)-\(countdownEvents.count)")
                }
                .padding(.horizontal, screenMargin)

                // 情報デザイン: Legend moved to Settings for cleaner calendar view

                // 情報デザイン: Day Dashboard ALWAYS shows selected day content
                let dashboardDate = Calendar.iso8601.startOfDay(for: selectedDay?.date ?? selectedDate)
                DayDashboardView(
                    date: dashboardDate,
                    notes: notesForDay(dashboardDate),
                    pinnedNotes: pinnedNotesForDashboard,
                    holidays: holidayInfo(for: dashboardDate),
                    expenses: expensesForDay(dashboardDate),
                    trips: tripsForDay(dashboardDate),
                    secondaryDateText: lunarDashboardText(for: dashboardDate),
                    onOpenNotes: { targetDate in
                        dayNotesDate = targetDate
                        dayNotesStartCreating = false
                        dayNotesDetent = .large
                        showDayNotesSheet = true
                    },
                    onOpenExpenses: nil,
                    onAddEntry: {
                        // 情報デザイン: Opens unified entry form directly (5 types)
                        noteEditorDate = dashboardDate
                        countdownEditorDate = dashboardDate
                        showUnifiedEntry = true
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

    private func openNotesEditor() {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        noteEditorDate = selectedDay?.date ?? selectedDate
        showNoteEditor = true
    }


    // MARK: - Month/Year Header

    @State private var showMonthPicker = false

    private var monthYearHeader: some View {
        Button(action: { showMonthPicker = true }) {
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
                    // Icon zone with Calendar accent color (Deep Indigo)
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

            // TODAY ROW: Today info + Go to Today button + Week badge
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
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(JohoColors.yellow)
                        .clipShape(Squircle(cornerRadius: 6))
                        .overlay(
                            Squircle(cornerRadius: 6)
                                .stroke(JohoColors.black, lineWidth: 1.5)
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

            Button { showMonthPicker = true } label: {
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

    private func expensesForDay(_ date: Date) -> [ExpenseItem] {
        let day = Calendar.iso8601.startOfDay(for: date)
        return expenses.filter {
            Calendar.iso8601.startOfDay(for: $0.date) == day
        }
    }

    private func notesForDay(_ date: Date) -> [DailyNote] {
        let day = Calendar.iso8601.startOfDay(for: date)
        return notes
            .filter { $0.day == day }
    }

    private func tripsForDay(_ date: Date) -> [TravelTrip] {
        let day = Calendar.iso8601.startOfDay(for: date)
        return trips.filter { trip in
            let tripStart = Calendar.iso8601.startOfDay(for: trip.startDate)
            let tripEnd = Calendar.iso8601.startOfDay(for: trip.endDate)
            return day >= tripStart && day <= tripEnd
        }
    }

    /// 情報デザイン: Check all special day types for calendar indicators
    private func hasDataForDay(_ date: Date) -> DayDataCheck {
        let day = Calendar.iso8601.startOfDay(for: date)

        var check = DayDataCheck()

        // Check holidays and observances from cache
        if let cachedHolidays = holidayManager.holidayCache[day] {
            for holiday in cachedHolidays {
                if holiday.isBankHoliday {
                    check.hasHoliday = true
                } else {
                    check.hasObservance = true
                }
            }
        }

        // Check notes
        check.hasNote = notes.contains { $0.day == day }

        // Check expenses
        check.hasExpense = expenses.contains { Calendar.iso8601.startOfDay(for: $0.date) == day }

        // Check trips (day falls within trip range) and determine position
        for trip in trips {
            let tripStart = Calendar.iso8601.startOfDay(for: trip.startDate)
            let tripEnd = Calendar.iso8601.startOfDay(for: trip.endDate)

            if day >= tripStart && day <= tripEnd {
                check.hasTrip = true

                // Determine trip position for edge indicators
                let isSingleDay = tripStart == tripEnd
                let isStartDay = day == tripStart
                let isEndDay = day == tripEnd

                if isSingleDay {
                    check.tripPosition = .single
                } else if isStartDay {
                    check.tripPosition = .start
                } else if isEndDay {
                    check.tripPosition = .end
                } else {
                    check.tripPosition = .middle
                }
                break // Use first matching trip
            }
        }

        // Check birthdays from contacts (match month/day regardless of year)
        let calendar = Calendar.iso8601
        let month = calendar.component(.month, from: day)
        let dayOfMonth = calendar.component(.day, from: day)

        check.hasBirthday = contacts.contains { contact in
            guard let birthday = contact.birthday else { return false }
            let bMonth = calendar.component(.month, from: birthday)
            let bDay = calendar.component(.day, from: birthday)
            return bMonth == month && bDay == dayOfMonth
        }

        // Check countdown events (match the event date)
        check.hasEvent = countdownEvents.contains { event in
            let eventDay = calendar.startOfDay(for: event.targetDate)
            return eventDay == day
        }

        return check
    }

    private var pinnedNotesForDashboard: [DailyNote] {
        notes.filter { $0.pinnedToDashboard == true }
    }

    // MARK: - Week Detail Helpers

    private func notesForWeek(_ week: CalendarWeek) -> [DailyNote] {
        let weekDates = Set(week.days.map { Calendar.iso8601.startOfDay(for: $0.date) })
        return notes.filter { weekDates.contains($0.day) }
    }

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

    // 情報デザイン: Get trips that overlap with week (for week detail view)
    private func tripsForWeek(_ week: CalendarWeek) -> [TravelTrip] {
        let weekStart = Calendar.iso8601.startOfDay(for: week.startDate)
        guard let weekEnd = Calendar.iso8601.date(byAdding: .day, value: 6, to: weekStart) else { return [] }

        return trips.filter { trip in
            let tripStart = Calendar.iso8601.startOfDay(for: trip.startDate)
            let tripEnd = Calendar.iso8601.startOfDay(for: trip.endDate)
            // Trip overlaps with week if: tripStart <= weekEnd && tripEnd >= weekStart
            return tripStart <= weekEnd && tripEnd >= weekStart
        }
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
        let day = Calendar.iso8601.startOfDay(for: date)
        let holidays = holidayManager.holidayCache[day] ?? []
        return holidays.map { holiday in
            DayDashboardView.HolidayInfo(
                id: holiday.id,
                name: holiday.displayTitle,
                isBankHoliday: holiday.isBankHoliday,
                symbolName: holiday.symbolName
            )
        }
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
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedDate = day.date
            selectedDay = day
            if let week = currentMonth.weeks.first(where: { $0.days.contains(where: { $0.id == day.id }) }) {
                selectedWeek = week
            }
        }
    }

    /// 情報デザイン: Long-press opens day detail sheet
    private func handleDayLongPress(_ day: CalendarDay) {
        dayDetailDataCheck = hasDataForDay(day.date)
        dayDetailDay = day  // This triggers the sheet to show via .sheet(item:)
    }



    private func handleWeekTap(_ week: CalendarWeek) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedWeek = week
            if let today = week.today {
                selectedDay = today
                selectedDate = today.date
            } else {
                selectedDay = week.days.first
                selectedDate = week.days.first?.date ?? selectedDate
            }
        }

        // 情報デザイン: Show week detail sheet (unified behavior)
        showWeekDetailSheet = true
    }

    private func handleMonthChange(month: Int, year: Int) {
        withAnimation {
            currentMonth = CalendarMonth(year: year, month: month, noteColors: noteColors)
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
            currentMonth = .current(noteColors: noteColors)

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
            currentMonth = CalendarMonth(year: year, month: month, noteColors: noteColors)
        } else {
            currentMonth = CalendarMonth(year: currentMonth.year, month: currentMonth.month, noteColors: noteColors)
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
            for: HolidayRule.self, CalendarRule.self, CountdownEvent.self, DailyNote.self, ExpenseItem.self, ExpenseCategory.self, TravelTrip.self,
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
            for: HolidayRule.self, CalendarRule.self, CountdownEvent.self, DailyNote.self, ExpenseItem.self, ExpenseCategory.self, TravelTrip.self,
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
