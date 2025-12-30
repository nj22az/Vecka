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

    // Layout
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

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
            case .summary:
                NavigationStack {
                    OverviewDashboardView()
                        .background(SlateColors.deepSlate)
                }
            case .calendar:
                NavigationStack {
                    calendarDetailView
                        .navigationTitle("")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { toolbarContent }
                }
            case .notes:
                NavigationStack {
                    NotesListView()
                        .background(SlateColors.deepSlate)
                }
            case .holidays:
                NavigationStack {
                    HolidayListView()
                        .background(SlateColors.deepSlate)
                }
            case .observances:
                NavigationStack {
                    ObservancesListView()
                        .background(SlateColors.deepSlate)
                }
            case .contacts:
                NavigationStack {
                    ContactListView()
                        .background(SlateColors.deepSlate)
                }
            case .expenses:
                NavigationStack {
                    ExpenseListView()
                        .background(SlateColors.deepSlate)
                }
            case .trips:
                NavigationStack {
                    TripListView()
                        .background(SlateColors.deepSlate)
                }
            case .settings:
                NavigationStack {
                    SettingsView()
                        .background(SlateColors.deepSlate)
                }
            }
        } else {
            ContentUnavailableView(
                Localization.selectItem,
                systemImage: "sidebar.left"
            )
            .background(SlateColors.deepSlate)
        }
    }

    var body: some View {
        Group {
            if isPad {
                // iPad: 3-column layout - Sidebar | Content | Week Detail
                HStack(spacing: 0) {
                    IconStripSidebar(selection: $sidebarSelection)

                    // Main content area
                    detailView
                        .frame(maxWidth: .infinity)

                    // Week Detail Panel (shown when week selected and on calendar view)
                    if sidebarSelection == .calendar, let week = selectedWeek {
                        WeekDetailPanel(
                            week: week,
                            selectedDay: selectedDay,
                            notes: notesForWeek(week),
                            holidays: holidaysForWeek(week),
                            onDayTap: handleDayTap
                        )
                    }
                }
                .background(SlateColors.deepSlate)
            } else {
                // iPhone: Tab bar navigation with full-width calendar
                TabView(selection: $phoneTab) {
                    // Calendar Tab
                    NavigationStack {
                        calendarDetailView
                            .navigationTitle("")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar { toolbarContent }
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
                .tint(SlateColors.sidebarActiveBar)
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
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
                .presentationBackground(SlateColors.mediumSlate)
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
            NavigationStack {
                DailyNotesView(selectedDate: noteEditorDate, isModal: true, startCreating: true)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
            VStack(spacing: isPad ? 24 : 16) {
                // Stacked Date Header with Unified Menu Button
                dateHeaderWithMenu
                    .padding(.horizontal, screenMargin)

                // Calendar Grid
                CalendarGridView(
                    month: currentMonth,
                    selectedWeek: selectedWeek,
                    selectedDay: selectedDay,
                    onDayTap: handleDayTap,
                    onWeekTap: handleWeekTap,
                    hasDataForDay: hasDataForDay
                )
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
            .padding(.vertical, Spacing.medium)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(SlateColors.deepSlate)
    }
    
    // MARK: - Stacked Date Header with Unified Menu
    
    private var dateHeaderWithMenu: some View {
        let displayDate = selectedDay?.date ?? selectedDate
        let dayNumber = Calendar.iso8601.component(.day, from: displayDate)

        return HStack(alignment: .center, spacing: 12) {
            // Stacked Date Display (Year, Month, Day)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(currentMonth.year))
                    .font(.caption)
                    .foregroundStyle(SlateColors.secondaryText)

                Text(monthTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(SlateColors.primaryText)

                Text(String(dayNumber))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(SlateColors.primaryText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(monthTitle) \(dayNumber), \(currentMonth.year)")

            Spacer()

            // Unified circular menu button
            unifiedMenuButton
        }
    }
    
    // MARK: - Unified Menu Button
    
    private var unifiedMenuButton: some View {
        Menu {
            // Quick Actions
            Section {
                Button(action: openNotesEditor) {
                    Label(Localization.addNote, systemImage: "note.text.badge.plus")
                }
            }

            // Navigation
            Section {
                Button(action: { showMonthPicker = true }) {
                    Label(Localization.goToMonthYear, systemImage: "calendar")
                }
                Button(action: jumpToToday) {
                    Label(Localization.today, systemImage: "scope")
                }
            }

            // Export
            Section {
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
            }
        } label: {
            // Squircle plus button (continuous corner radius)
            Image(systemName: "plus")
                .font(Typography.labelLarge)
                .foregroundStyle(SlateColors.primaryText)
                .frame(width: 40, height: 40)
                .background(SlateColors.lightSlate)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                    Text(String(currentMonth.year))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(monthTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(.ultraThinMaterial, in: Capsule())
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

    private func hasDataForDay(_ date: Date) -> (hasNotes: Bool, hasExpenses: Bool, hasTrips: Bool) {
        let day = Calendar.iso8601.startOfDay(for: date)
        let hasNotes = notes.contains { $0.day == day }
        let hasExpenses = expenses.contains { Calendar.iso8601.startOfDay(for: $0.date) == day }
        let hasTrips = trips.contains { trip in
            let tripStart = Calendar.iso8601.startOfDay(for: trip.startDate)
            let tripEnd = Calendar.iso8601.startOfDay(for: trip.endDate)
            return day >= tripStart && day <= tripEnd
        }
        return (hasNotes, hasExpenses, hasTrips)
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
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        default: return AppColors.accentBlue
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
