//
//  ContentView.swift
//  Vecka
//
//  Sophisticated week display with Apple HIG-compliant design
//

import SwiftUI


struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var currentWeekInfo = WeekInfo(for: Date(), localized: true)
    @State private var dragOffset = CGSize.zero
    @State private var isNavigating = false
    // Notes for per-day icon storage + settings state
    @StateObject private var notesManager = NotesManager()
    @ObservedObject private var calendarManager = SystemCalendarManager.shared
    @AppStorage("isMonochromeMode") private var isMonochromeMode: Bool = false
    @AppStorage("isAutoDarkMode") private var isAutoDarkMode: Bool = true
    @State private var showSettings = false
    @State private var selectedCountdown: CountdownType = .newYear
    @State private var showIconPicker = false
    @State private var iconPickerDate: Date? = nil
    @State private var showMonthPicker = false
    @State private var showWeekPicker = false
    @State private var showJumpPicker = false
    @State private var jumpMode: JumpMode = .week
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    @StateObject private var languageManager = LanguageManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private let calendar = Calendar.iso8601
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let isCompact = geometry.size.height < 700
            
            ZStack {
                // Background with authentic glass material
                AppColors.adaptiveBackground(isMonochrome: isMonochromeMode, isAutoDarkMode: isAutoDarkMode)
                    .ignoresSafeArea()
                
                if isLandscape {
                    landscapeLayout(geometry: geometry, isCompact: isCompact)
                } else {
                    portraitLayout(geometry: geometry, isCompact: isCompact)
                }
            }
            .gesture(paperSwipeGesture)
            .offset(x: dragOffset.width)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateWeekInfo()
            languageManager.detectSystemLanguage()
            print("🌍 App language detected: \(languageManager.getLanguageName()) (\(languageManager.currentLanguage))")
        }
        .onChange(of: languageManager.currentLanguage) { _, _ in
            // Refresh UI when language changes
            updateWeekInfo()
        }
        // Top-right controls (Settings with Today underneath), inset into safe area
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                VStack(spacing: 6) {
                    Button(action: { showSettings = true }) {
                        flatIcon(symbol: "gearshape", size: 18, color: AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Settings")
                    Button(action: navigateToToday) {
                        flatIcon(symbol: "target", size: 18, color: AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(Localization.today)
                }
                .padding(.trailing, 8)
            }
        }.presentationDetents([.medium])
    }
    
    // MARK: - Layout Views
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy, isCompact: Bool) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: isCompact ? Spacing.medium : Spacing.large) {
                // Top safe area spacing
                Spacer(minLength: 20)
                
                // Header with contextual navigation
                VStack(spacing: Spacing.small) {
                    HStack(alignment: .center, spacing: 24) {
                        Button(action: navigateToPreviousWeek) {
                            flatIcon(symbol: "chevron.left", size: 20, color: AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(Localization.previousWeek)

                        // Dynamic week number with daily coloring
                        Button(action: { if isPad { showWeekPicker = true } else { jumpMode = .week; showJumpPicker = true } }) {
                            HStack(spacing: 6) {
                                weekNumberDisplay
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode).opacity(0.06))
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Change week")
                        .accessibilityHint("Opens week picker")
                        .popover(isPresented: Binding(get: { isPad && showWeekPicker }, set: { showWeekPicker = $0 })) {
                            WeekPickerSheet(
                                initialWeek: currentWeekInfo.weekNumber,
                                initialYear: currentWeekInfo.year
                            ) { week, year in
                                var comps = DateComponents()
                                comps.weekOfYear = week
                                comps.yearForWeekOfYear = year
                                comps.weekday = 2 // Monday
                                if let date = Calendar.iso8601.date(from: comps) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        selectedDate = date
                                        updateWeekInfo()
                                    }
                                }
                            }
                            .frame(minWidth: 360, minHeight: 340)
                        }

                        Button(action: navigateToNextWeek) {
                            flatIcon(symbol: "chevron.right", size: 20, color: AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(Localization.nextWeek)
                    }
                    // Month + outlined year below
                    Button(action: { if isPad { showMonthPicker = true } else { jumpMode = .month; showJumpPicker = true } }) {
                        HStack(spacing: 6) {
                            monthYearDisplay
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode).opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Change month")
                    .accessibilityHint("Opens month picker")
                    .popover(isPresented: Binding(get: { isPad && showMonthPicker }, set: { showMonthPicker = $0 })) {
                        MonthPickerSheet(
                            initialMonth: Calendar.iso8601.component(.month, from: selectedDate),
                            initialYear: Calendar.iso8601.component(.year, from: selectedDate)
                        ) { month, year in
                            var comps = DateComponents()
                            comps.year = year
                            comps.month = month
                            comps.day = 1
                            if let date = Calendar.iso8601.date(from: comps) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectedDate = date
                                    updateWeekInfo()
                                }
                            }
                        }
                        .frame(minWidth: 360, minHeight: 340)
                    }
                }
                .padding(.horizontal, Spacing.medium)
                
                // Week calendar strip with 7-day navigation
                WeekCalendarStrip(
                    selectedDate: $selectedDate,
                    isMonochrome: isMonochromeMode,
                    showWeekInfo: false,
                    hasEvent: { date in
                        SystemCalendarManager.shared.hasEvents(on: date)
                    },
                    iconProvider: { date in
                        if let userIcon = notesManager.icon(for: date) { return userIcon }
                        return SeasonalIcons.icon(for: date)
                    },
                    onEditIcon: { date in
                        iconPickerDate = date
                        showIconPicker = true
                    },
                    onClearIcon: { date in
                        notesManager.setIcon(nil, for: date)
                    }
                )
                .onChange(of: selectedDate) { _, newDate in
                    updateWeekInfo()
                }
                
                // System Calendar events (squircle card)
                SystemCalendarEventsView(selectedDate: selectedDate, isMonochrome: isMonochromeMode)
                    .padding(.horizontal, Spacing.medium)

                // Bottom safe area spacing
                Spacer(minLength: 20)
            }
        }.presentationDetents([.medium])
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showSettings) {
            SettingsView(selectedCountdown: $selectedCountdown, onCountdownChange: {})
        }
        .sheet(isPresented: $showIconPicker) {
            IconPickerSheet(
                initialSymbol: iconPickerDate.flatMap { notesManager.icon(for: $0) } ?? "",
                date: iconPickerDate ?? selectedDate
            ) { date, symbol in
                let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
                notesManager.setIcon(trimmed.isEmpty ? nil : trimmed, for: date)
            }
        }.presentationDetents([.medium])
        .sheet(isPresented: Binding(get: { !isPad && showJumpPicker }, set: { showJumpPicker = $0 })) {
            JumpPickerSheet(
                initialMode: jumpMode,
                initialYear: Calendar.iso8601.component(.year, from: selectedDate),
                initialMonth: Calendar.iso8601.component(.month, from: selectedDate),
                initialWeek: currentWeekInfo.weekNumber
            ) { date in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    selectedDate = date
                    updateWeekInfo()
                }
            }
        }.presentationDetents([.medium])
    }
    
    @ViewBuilder
    private func landscapeLayout(geometry: GeometryProxy, isCompact: Bool) -> some View {
        HStack(spacing: Spacing.large) {
            // Left side - Week number and date
            VStack(spacing: Spacing.medium) {
                Spacer()
                
                HStack(alignment: .center, spacing: 24) {
                    Button(action: navigateToPreviousWeek) {
                        flatIcon(symbol: "chevron.left", size: 20, color: AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(Localization.previousWeek)
                    
                    Button(action: { showWeekPicker = true }) {
                        HStack(spacing: 6) {
                            weekNumberDisplay
                                .scaleEffect(0.8)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode).opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Change week")
                    .accessibilityHint("Opens week picker")
                    .popover(isPresented: Binding(get: { isPad && showWeekPicker }, set: { showWeekPicker = $0 })) {
                        WeekPickerSheet(
                            initialWeek: currentWeekInfo.weekNumber,
                            initialYear: currentWeekInfo.year
                        ) { week, year in
                            var comps = DateComponents()
                            comps.weekOfYear = week
                            comps.yearForWeekOfYear = year
                            comps.weekday = 2 // Monday
                            if let date = Calendar.iso8601.date(from: comps) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectedDate = date
                                    updateWeekInfo()
                                }
                            }
                        }
                        .frame(minWidth: 360, minHeight: 340)
                    }
                    
                    Button(action: navigateToNextWeek) {
                        flatIcon(symbol: "chevron.right", size: 20, color: AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(Localization.nextWeek)
                }
                
                Button(action: { showMonthPicker = true }) {
                    HStack(spacing: 6) {
                        monthYearDisplay
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode).opacity(0.06)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change month")
                .accessibilityHint("Opens month picker")
                .popover(isPresented: Binding(get: { isPad && showMonthPicker }, set: { showMonthPicker = $0 })) {
                    MonthPickerSheet(
                        initialMonth: Calendar.iso8601.component(.month, from: selectedDate),
                        initialYear: Calendar.iso8601.component(.year, from: selectedDate)
                    ) { month, year in
                        var comps = DateComponents()
                        comps.year = year
                        comps.month = month
                        comps.day = 1
                        if let date = Calendar.iso8601.date(from: comps) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                selectedDate = date
                                updateWeekInfo()
                            }
                        }
                    }
                    .frame(minWidth: 360, minHeight: 340)
                }
                // Holiday info removed for MVP

                Spacer()
            }
            .frame(maxWidth: geometry.size.width * 0.35)
            .padding(.leading, Spacing.medium)
            
            // Right side - Calendar and notes
            VStack(spacing: Spacing.medium) {
                Spacer(minLength: 40)
                
                // Calendar strip
                WeekCalendarStrip(
                    selectedDate: $selectedDate,
                    isMonochrome: isMonochromeMode,
                    showWeekInfo: false,
                    hasEvent: { date in
                        SystemCalendarManager.shared.hasEvents(on: date)
                    },
                    iconProvider: { date in
                        if let userIcon = notesManager.icon(for: date) { return userIcon }
                        return SeasonalIcons.icon(for: date)
                    },
                    onEditIcon: { date in
                        iconPickerDate = date
                        showIconPicker = true
                    },
                    onClearIcon: { date in
                        notesManager.setIcon(nil, for: date)
                    }
                )
                .onChange(of: selectedDate) { _, newDate in
                    updateWeekInfo()
                }
                // System Calendar events card
                SystemCalendarEventsView(selectedDate: selectedDate, isMonochrome: isMonochromeMode)
                    .padding(.horizontal, Spacing.medium)

                Spacer()
                
                // Editor and notes list removed in landscape
                
                Spacer(minLength: 40)
            }
            .frame(maxWidth: geometry.size.width * 0.65)
            .padding(.trailing, Spacing.medium)
        }
    }
    
    // MARK: - Week Number Display
    private var weekNumberDisplay: some View {
        ZStack {
            // Black outline for illustrated effect
            Text("\(currentWeekInfo.weekNumber)")
                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 80 : 72, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .offset(x: 1, y: 1)
            Text("\(currentWeekInfo.weekNumber)")
                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 80 : 72, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .offset(x: -1, y: -1)
            Text("\(currentWeekInfo.weekNumber)")
                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 80 : 72, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .offset(x: 1, y: -1)
            Text("\(currentWeekInfo.weekNumber)")
                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 80 : 72, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .offset(x: -1, y: 1)
            
            // Colored fill
            Text("\(currentWeekInfo.weekNumber)")
                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 80 : 72, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.colorForDay(selectedDate))
        }
        .animation(.easeInOut(duration: 0.3), value: selectedDate)
    }
    
    private var monthYearDisplay: some View {
        let month = DateFormatterCache.monthName.string(from: selectedDate)
        let yearString = String(currentWeekInfo.year)
        let bgColor = (isMonochromeMode
                       ? AppColors.monoTextPrimary
                       : AppColors.colorForDay(selectedDate, isMonochrome: false)).opacity(0.2)
        return HStack(spacing: 8) {
            Text(month)
                .font(Typography.bodyMedium)
                .foregroundColor(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
            outlinedText(
                yearString,
                font: .system(size: 18, weight: .semibold, design: .rounded),
                fill: .white,
                outline: .black,
                offset: 1.0
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(bgColor))
        }
    }

    private func outlinedText(_ text: String, font: Font, fill: Color, outline: Color = .black, offset: CGFloat = 1.0) -> some View {
        ZStack {
            Text(text).font(font).monospacedDigit().foregroundColor(outline).offset(x: offset, y: offset)
            Text(text).font(font).monospacedDigit().foregroundColor(outline).offset(x: -offset, y: -offset)
            Text(text).font(font).monospacedDigit().foregroundColor(outline).offset(x: offset, y: -offset)
            Text(text).font(font).monospacedDigit().foregroundColor(outline).offset(x: -offset, y: offset)
            Text(text).font(font).monospacedDigit().foregroundColor(fill)
        }
    }
    
    // MARK: - Flat Icon
    private func flatIcon(symbol: String, size: CGFloat = 18, color: Color) -> some View {
        Image(systemName: symbol)
            .symbolRenderingMode(.monochrome)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
    }
    
    
    // Holiday UI removed for MVP
    
    // MARK: - Calendar Paper Swipe Navigation
    private var paperSwipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !isNavigating {
                    dragOffset = value.translation
                    // Light haptic feedback on gesture start
                    if abs(value.translation.width) > 10 && dragOffset == CGSize.zero {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            }
            .onEnded { value in
                let swipeThreshold: CGFloat = 100
                
                if value.translation.width > swipeThreshold {
                    // Right swipe = previous week (put back calendar page)
                    navigateToPreviousWeek()
                } else if value.translation.width < -swipeThreshold {
                    // Left swipe = next week (throw away calendar page)
                    navigateToNextWeek()
                } else {
                    // Snap back
                    withAnimation(.spring(response: 0.3)) {
                        dragOffset = CGSize.zero
                    }
                }
            }
    }
    
    // MARK: - Actions
    private func updateWeekInfo() {
        currentWeekInfo = WeekInfo(for: selectedDate, localized: true)
    }
    
    private func navigateToPreviousWeek() {
        guard !isNavigating else { return }
        isNavigating = true
        
        // Medium haptic feedback on completion
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Slide out animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = CGSize(width: UIScreen.main.bounds.width, height: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                selectedDate = newDate
                updateWeekInfo()
            }
            
            dragOffset = CGSize(width: -UIScreen.main.bounds.width, height: 0)
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                dragOffset = CGSize.zero
            }
            
            isNavigating = false
        }
    }
    
    private func navigateToNextWeek() {
        guard !isNavigating else { return }
        isNavigating = true
        
        // Medium haptic feedback on completion
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Slide out animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = CGSize(width: -UIScreen.main.bounds.width, height: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                selectedDate = newDate
                updateWeekInfo()
            }
            
            dragOffset = CGSize(width: UIScreen.main.bounds.width, height: 0)
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                dragOffset = CGSize.zero
            }
            
            isNavigating = false
        }
    }
    
    private func navigateToToday() {
        selectedDate = Date()
        updateWeekInfo()
    }
    
}


// MARK: - Preview
#Preview("ContentView - Light Mode") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("ContentView - Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
