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

    // Managers
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(NavigationManager.self) private var navigationManager
    @Query private var notes: [DailyNote]
    @Query private var expenses: [ExpenseItem]
    @Query private var trips: [TravelTrip]
    @Query private var contacts: [Contact]  // For birthday indicators
    @Query private var countdownEvents: [CountdownEvent]  // For event indicators
    @Query(sort: \WorkspaceWidget.zIndex) private var workspaceWidgets: [WorkspaceWidget]
    private var holidayManager = HolidayManager.shared

    /// Check if widgets need repacking (have gaps that could be collapsed)
    private var widgetsNeedRepack: Bool {
        guard workspaceWidgets.count > 1 else { return false }

        // Get effective columns (use reasonable default for iPad)
        let columns = 4

        // Build occupied grid
        var occupiedGrid: [[Bool]] = Array(
            repeating: Array(repeating: false, count: columns),
            count: 100
        )

        // Sort widgets like autoPackWidgets does
        let sortedWidgets = workspaceWidgets.sorted { w1, w2 in
            if w1.gridY != w2.gridY { return w1.gridY < w2.gridY }
            return w1.gridX < w2.gridX
        }

        // Check if any widget would move during repack
        for widget in sortedWidgets {
            // Find where this widget WOULD go if repacked
            var bestX = 0
            var bestY = 0
            outer: for y in 0..<100 {
                for x in 0...(columns - widget.columns) {
                    var canPlace = true
                    for row in y..<min(y + widget.rows, 100) {
                        for col in x..<min(x + widget.columns, columns) {
                            if occupiedGrid[row][col] {
                                canPlace = false
                                break
                            }
                        }
                        if !canPlace { break }
                    }
                    if canPlace {
                        bestX = x
                        bestY = y
                        break outer
                    }
                }
            }

            // Would widget move?
            if bestX != widget.gridX || bestY != widget.gridY {
                return true
            }

            // Mark position as occupied for next widget
            for row in bestY..<min(bestY + widget.rows, 100) {
                for col in bestX..<min(bestX + widget.columns, columns) {
                    occupiedGrid[row][col] = true
                }
            }
        }

        return false
    }

    private var noteColors: [Date: String] {
        var dict: [Date: String] = [:]
        // Sort notes by date so later notes overwrite earlier ones (showing latest color)
        let sortedNotes = notes.sorted { $0.date < $1.date }
        
        for note in sortedNotes {
            dict[note.day] = note.color ?? "default"
        }
        return dict
    }

    // Layout
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    /// Smart add button - show for Tools, Contacts, and Star page (always visible)
    private var shouldShowAddButton: Bool {
        switch sidebarSelection {
        case .tools, .contacts, .specialDays:
            return true  // Always show plus button on these pages
        default:
            return false
        }
    }

    /// Add button color - matches page accent colors (情報デザイン)
    private var addButtonColor: Color {
        switch sidebarSelection {
        case .tools:
            return JohoColors.cyan       // Tools = Cyan
        case .contacts:
            return JohoColors.pink       // Contacts = Pink
        case .specialDays:
            return JohoColors.yellow     // Star page = Yellow
        default:
            return JohoColors.cyan
        }
    }

    // HIG-compliant margins (Ref: Layout | Apple Developer Documentation)
    // iPhone (Compact): 16pt standard
    // iPad (Regular): 24pt standard for grid layouts
    private var screenMargin: CGFloat {
        isPad ? 24 : 16
    }

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

    // Context-aware add sheets (triggered from sidebar +)
    @State private var showExpenseEditor = false
    @State private var showTripEditor = false
    @State private var showContactEditor = false
    @State private var showObservanceEditor = false
    @State private var showHolidayEditor = false
    @State private var showSpecialDayMenu = false
    @State private var showContactMenu = false
    @State private var contactEditorMode: JohoContactEditorMode = .birthday
    @State private var showCountdownEditor = false
    @State private var countdownEditorName: String = ""
    @State private var countdownEditorDate: Date = Date()
    @State private var countdownEditorIsAnnual: Bool = false
    @State private var countdownEditorType: CountdownType = .custom

    // Star page month detail state (for smart + button)
    @State private var isInSpecialDaysMonthDetail = false

    // NavigationSplitView column visibility
    // .automatic lets the system decide based on device orientation and size
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var sidebarSelection: SidebarSelection? = .calendar

    private enum PhoneTab: Hashable {
        case calendar
        case library
        case settings
    }

    @State private var phoneTab: PhoneTab = .calendar

    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])

    @State private var lunarConfig: LunarConfig?

    @Environment(\.locale) private var locale

    // MARK: - iPad Detail View

    @ViewBuilder
    private var detailView: some View {
        if let selection = sidebarSelection {
            switch selection {
            case .tools:
                NavigationStack {
                    DashboardView()
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

    var body: some View {
        Group {
            if isPad {
                // iPad: 3-column layout - Sidebar | Content | Week Detail
                HStack(spacing: 0) {
                    IconStripSidebar(
                        selection: $sidebarSelection,
                        onAdd: shouldShowAddButton ? {
                            // Context-aware add action based on current selection
                            switch sidebarSelection {
                            case .tools:
                                NotificationCenter.default.post(name: .addWidgetRequested, object: nil)
                            case .contacts:
                                showContactMenu = true
                            case .specialDays:
                                showSpecialDayMenu = true  // Show add menu when in month detail
                            default:
                                break
                            }
                        } : nil,
                        addButtonColor: addButtonColor,
                        showRepackButton: sidebarSelection == .tools && widgetsNeedRepack,
                        onRepack: {
                            NotificationCenter.default.post(name: .repackWidgetsRequested, object: nil)
                        },
                        onExport: sidebarSelection == .calendar ? {
                            pdfExportContext = .summary
                            showPDFExport = true
                        } : nil
                    )

                    // Main content area (full width - week details moved to Star page)
                    detailView
                        .frame(maxWidth: .infinity)
                }
                .johoBackground()
            } else {
                // iPhone: Tab bar navigation with full-width calendar
                TabView(selection: $phoneTab) {
                    // Calendar Tab - NO navigation bar, content goes to top
                    NavigationStack {
                        calendarDetailView
                            .navigationBarHidden(true)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                    .tabItem {
                        Label(Localization.calendar, systemImage: "calendar")
                    }
                    .tag(PhoneTab.calendar)

                    // Library Tab
                    NavigationStack {
                        PhoneLibraryView()
                    }
                    .tabItem {
                        Label(Localization.library, systemImage: "books.vertical")
                    }
                    .tag(PhoneTab.library)

                    // Settings Tab
                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem {
                        Label(Localization.settings, systemImage: "gearshape")
                    }
                    .tag(PhoneTab.settings)
                }
                .tint(JohoColors.cyan)
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
                },
                onSelectBirthday: {
                    showContactMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        contactEditorMode = .birthday
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
        .sheet(isPresented: $showSpecialDayMenu) {
            JohoAddSpecialDaySheet(
                onSelectHoliday: {
                    showSpecialDayMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showHolidayEditor = true
                    }
                },
                onSelectObservance: {
                    showSpecialDayMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showObservanceEditor = true
                    }
                },
                onSelectEvent: {
                    showSpecialDayMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCountdownEditor = true
                    }
                },
                onSelectBirthday: {
                    showSpecialDayMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showContactEditor = true
                    }
                },
                onSelectNote: {
                    showSpecialDayMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showNoteEditor = true
                    }
                },
                onSelectTrip: {
                    showSpecialDayMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showTripEditor = true
                    }
                },
                onSelectExpense: {
                    showSpecialDayMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showExpenseEditor = true
                    }
                }
            )
            // Note: Presentation styling is now controlled by the sheet itself
            // for proper 情報デザイン compliance (squircle, clear background)
        }
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
        .onChange(of: displayMonth) { _, newMonth in
            handleMonthChange(month: newMonth, year: selectedYear)
        }
        .onChange(of: selectedYear) { _, newYear in
            handleMonthChange(month: displayMonth, year: newYear)
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: newYear)
        }
        .onChange(of: navigationManager.targetDate) { _, newDate in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selectedDate = newDate
                sidebarSelection = .calendar
                if !isPad {
                    phoneTab = .calendar
                }
            }
        }
    }

    // MARK: - Calendar Detail View

    private var calendarDetailView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: JohoDimensions.spacingMD) {
                // TODAY Banner - at the VERY TOP (no dead space)
                JohoTodayBanner(
                    date: Date(),
                    weekNumber: Calendar.iso8601.component(.weekOfYear, from: Date()),
                    onTapToday: jumpToToday
                )
                .padding(.horizontal, screenMargin)

                // Month Selector + Action Menu
                HStack {
                    JohoMonthSelector(
                        monthName: monthTitle,
                        year: currentMonth.year,
                        onPrevious: navigateToPreviousMonth,
                        onNext: navigateToNextMonth,
                        onTap: { showMonthPicker = true }
                    )

                    Spacer()

                    // Action menu button
                    actionMenuButton
                }
                .padding(.horizontal, screenMargin)

                // Calendar Grid in WHITE container with thick black border
                JohoCalendarContainer {
                    CalendarGridView(
                        month: currentMonth,
                        selectedWeek: selectedWeek,
                        selectedDay: selectedDay,
                        onDayTap: handleDayTap,
                        onWeekTap: handleWeekTap,
                        hasDataForDay: hasDataForDay
                    )
                    .id("\(currentMonth.month)-\(currentMonth.year)-\(contacts.count)-\(notes.count)-\(countdownEvents.count)")
                }
                .padding(.horizontal, screenMargin)
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            handleSwipe(translation: value.translation)
                        }
                )

                // Day Dashboard (shows on iPad below calendar, hidden on iPhone when week panel visible)
                if isPad || selectedWeek == nil {
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
                        onOpenExpenses: nil
                    )
                    .id(dashboardDate)
                    .padding(.horizontal, screenMargin)
                }
            }
            .padding(.top, JohoDimensions.spacingSM) // Small top padding after safe area
            .padding(.bottom, JohoDimensions.spacingLG)
            .safeAreaPadding(.top) // Respect status bar
        }
        .scrollBounceBehavior(.basedOnSize)
        .johoBackground()
    }

    // MARK: - Action Menu Button

    private var actionMenuButton: some View {
        Menu {
            // Export options
            Menu {
                    Button {
                        pdfExportContext = .day(selectedDay?.date ?? selectedDate)
                        showPDFExport = true
                    } label: {
                        Label(Localization.exportDay, systemImage: "calendar.day.timeline.left")
                    }

                    Button {
                        let week = Calendar.iso8601.component(.weekOfYear, from: selectedDate)
                        pdfExportContext = .week(weekNumber: week, year: currentMonth.year)
                        showPDFExport = true
                    } label: {
                        Label(Localization.exportWeek, systemImage: "calendar")
                    }

                    Button {
                        pdfExportContext = .month(month: displayMonth, year: selectedYear)
                        showPDFExport = true
                    } label: {
                        Label(Localization.exportMonth, systemImage: "calendar.badge.clock")
                    }
            } label: {
                Label(Localization.export, systemImage: "square.and.arrow.up")
            }
        } label: {
            JohoActionButton(icon: "square.and.arrow.up")
        }
        .accessibilityLabel(Localization.menu)
        .sheet(isPresented: $showMonthPicker) {
            MonthPickerSheet(
                initialMonth: displayMonth,
                initialYear: selectedYear
            ) { newMonth, newYear in
                displayMonth = newMonth
                selectedYear = newYear
            }
            .presentationDetents([.medium, .large])
        }
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
                        .foregroundStyle(JohoColors.white.opacity(0.6))

                    Text(monthTitle)
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.white)
                }

                Image(systemName: "chevron.down")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.white.opacity(0.7))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(JohoColors.black)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(JohoColors.white, lineWidth: 1.5))
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
                if holiday.isRedDay {
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

        // Check trips (day falls within trip range)
        check.hasTrip = trips.contains { trip in
            let tripStart = Calendar.iso8601.startOfDay(for: trip.startDate)
            let tripEnd = Calendar.iso8601.startOfDay(for: trip.endDate)
            return day >= tripStart && day <= tripEnd
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

    private func color(for colorName: String) -> Color {
        switch colorName {
        case "red": return JohoColors.pink
        case "blue": return JohoColors.cyan
        case "green": return JohoColors.green
        case "orange": return JohoColors.orange
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
                isRedDay: holiday.isRedDay,
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

    private func handleSwipe(translation: CGSize) {
        if translation.width > 50 {
            navigateToPreviousMonth()
        } else if translation.width < -50 {
            navigateToNextMonth()
        }
    }

    private func navigateToPreviousMonth() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if displayMonth == 1 {
                displayMonth = 12
                selectedYear -= 1
            } else {
                displayMonth -= 1
            }
        }
    }

    private func navigateToNextMonth() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if displayMonth == 12 {
                displayMonth = 1
                selectedYear += 1
            } else {
                displayMonth += 1
            }
        }
    }

    private func handleDayTap(_ day: CalendarDay) {
        if selectedDay?.id == day.id {
            // Already selected -> open the day sheet
            dayNotesDate = day.date
            dayNotesStartCreating = false
            dayNotesDetent = .medium
            showDayNotesSheet = true
        } else {
            // Select Day
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = day.date
                selectedDay = day
                if let week = currentMonth.weeks.first(where: { $0.days.contains(where: { $0.id == day.id }) }) {
                    selectedWeek = week
                }
            }
        }
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

        // On iPhone, show week detail as bottom sheet
        if !isPad {
            showWeekDetailSheet = true
        }
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
            isRedDay: false,
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
            isRedDay: true,  // Red day = holiday
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
