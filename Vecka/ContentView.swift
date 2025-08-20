//
//  ContentView.swift
//  Vecka
//
//  Created by Nils Johansson on 2025-08-09.
//

import SwiftUI
import UIKit

// MARK: - Performance Optimizations
private enum DateFormatterCache {
    static let monthName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()
    
    static let weekdayShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()
    
    static let dayNumber: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()
    
    static let weekRange: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()
}

// MARK: - Calendar Extension (Shared)
extension Calendar {
    static let iso8601: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.locale = .autoupdatingCurrent
        cal.timeZone = .autoupdatingCurrent
        return cal
    }()
}

// MARK: - Week Info (Shared)
struct WeekInfo {
    let weekNumber: Int
    let year: Int
    let dateRange: String
    let startDate: Date
    let endDate: Date
    
    init(for date: Date = Date()) {
        let calendar = Calendar.iso8601
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2 // Monday
        let startDate = calendar.date(from: components) ?? date
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? date
        
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        
        self.weekNumber = week
        self.year = year
        self.dateRange = "\(startString) – \(endString)"
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Calendar Day Info (Shared)
struct CalendarDayInfo {
    let date: Date
    let dayNumber: Int
    let isToday: Bool
    let isSelected: Bool
    let isCurrentMonth: Bool
    let weekNumber: Int
    
    init(date: Date, dayNumber: Int, isToday: Bool, isSelected: Bool, isCurrentMonth: Bool, weekNumber: Int) {
        self.date = date
        self.dayNumber = dayNumber
        self.isToday = isToday
        self.isSelected = isSelected
        self.isCurrentMonth = isCurrentMonth
        self.weekNumber = weekNumber
    }
}

// MARK: - Countdown Models
struct CustomCountdown: Codable {
    let name: String
    let date: Date
    let isAnnual: Bool
    
    // Cache month and day components to avoid XPC-sensitive operations
    private let cachedMonth: Int?
    private let cachedDay: Int?
    
    // MARK: - Initializers
    
    init(name: String, date: Date, isAnnual: Bool) {
        self.name = name
        self.date = date
        self.isAnnual = isAnnual
        
        // Pre-compute and cache month/day components during initialization
        // This avoids XPC-sensitive calendar operations during navigation
        if isAnnual {
            let calendar = Calendar.iso8601
            let components = calendar.dateComponents([.month, .day], from: date)
            self.cachedMonth = components.month
            self.cachedDay = components.day
        } else {
            self.cachedMonth = nil
            self.cachedDay = nil
        }
    }
    
    // MARK: - Codable Support with Backward Compatibility
    
    private enum CodingKeys: String, CodingKey {
        case name, date, isAnnual, cachedMonth, cachedDay
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        date = try container.decode(Date.self, forKey: .date)
        isAnnual = try container.decode(Bool.self, forKey: .isAnnual)
        
        // Handle cached components with backward compatibility
        if let month = try container.decodeIfPresent(Int.self, forKey: .cachedMonth),
           let day = try container.decodeIfPresent(Int.self, forKey: .cachedDay) {
            // Use existing cached values
            self.cachedMonth = month
            self.cachedDay = day
        } else if isAnnual {
            // Legacy data - compute cached values now
            let calendar = Calendar.iso8601
            let components = calendar.dateComponents([.month, .day], from: date)
            self.cachedMonth = components.month
            self.cachedDay = components.day
        } else {
            self.cachedMonth = nil
            self.cachedDay = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(date, forKey: .date)
        try container.encode(isAnnual, forKey: .isAnnual)
        try container.encodeIfPresent(cachedMonth, forKey: .cachedMonth)
        try container.encodeIfPresent(cachedDay, forKey: .cachedDay)
    }
    
    // MARK: - Public Interface
    
    func displayName() -> String {
        return name.uppercased()
    }
    
    func targetDate(for currentYear: Int) -> Date? {
        if isAnnual {
            // Use cached components to avoid XPC-sensitive operations
            guard let month = cachedMonth,
                  let day = cachedDay else {
                // Fallback to original date if cached components are invalid
                return date
            }
            
            // Create date components using cached values
            let components = DateComponents(year: currentYear, month: month, day: day)
            
            // Safe date creation with fallback - this is the only calendar operation needed
            return Calendar.iso8601.date(from: components) ?? date
        } else {
            return date
        }
    }
}

enum CountdownType: Codable {
    case newYear
    case christmas
    case summer
    case valentine
    case halloween
    case midsummer
    case custom(CustomCountdown)
    
    var displayName: String {
        switch self {
        case .newYear:
            return "NEW YEAR"
        case .christmas:
            return "CHRISTMAS"
        case .summer:
            return "SUMMER"
        case .valentine:
            return "VALENTINE'S"
        case .halloween:
            return "HALLOWEEN"
        case .midsummer:
            return "MIDSUMMER"
        case .custom(let customCountdown):
            return customCountdown.displayName()
        }
    }
    
    var icon: String {
        switch self {
        case .newYear:
            return "calendar.badge.plus"
        case .christmas:
            return "gift"
        case .summer:
            return "sun.max"
        case .valentine:
            return "heart"
        case .halloween:
            return "moon.stars"
        case .midsummer:
            return "leaf"
        case .custom:
            return "calendar.badge.clock"
        }
    }
    
    func targetDate(for year: Int) -> Date? {
        let calendar = Calendar.iso8601
        switch self {
        case .newYear:
            return calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        case .christmas:
            return calendar.date(from: DateComponents(year: year, month: 12, day: 24))
        case .summer:
            return calendar.date(from: DateComponents(year: year, month: 6, day: 21))
        case .valentine:
            return calendar.date(from: DateComponents(year: year, month: 2, day: 14))
        case .halloween:
            return calendar.date(from: DateComponents(year: year, month: 10, day: 31))
        case .midsummer:
            return calendar.date(from: DateComponents(year: year, month: 6, day: 20))
        case .custom(let customCountdown):
            return customCountdown.targetDate(for: year)
        }
    }
    
    static var predefinedCases: [CountdownType] {
        return [.newYear, .christmas, .summer, .valentine, .halloween, .midsummer]
    }
}


// MARK: - ContentView
struct ContentView: View {
    @AppStorage("selectedDate") private var selectedDateData: Data = Data()
    @AppStorage("countdownType") private var countdownTypeData: Data = Data()
    @State private var selectedDate = Date()
    @State private var cachedWeekInfo: WeekInfo?
    @State private var cachedWeekInfoDate: Date?
    @State private var holidayCalculator: SwedishHolidayCalculator?
    @State private var selectedCountdown: CountdownType = .newYear
    @State private var showingSettings = false
    @State private var isNavigationInProgress = false // Prevent concurrent navigation
    @AppStorage("isMonochromeMode") private var isMonochromeMode: Bool = false
    
    // Direct color evaluation for optimal performance
    
    // Easter egg for birthday
    @State private var januaryTapCount = 0
    @State private var showingBirthdayMessage = false
    
    // Performance optimization: cache device type to avoid repeated UIDevice.current calls
    @State private var isIPadDevice = UIDevice.current.userInterfaceIdiom == .pad
    
    // Interactive week number states
    @State private var weekNumberScale: CGFloat = 1.0
    @State private var weekNumberOffset: CGFloat = 0.0
    @State private var isDraggingWeek = false
    
    // Optimized computed property for stable week info
    private var currentWeekInfo: WeekInfo {
        // Check cache with more efficient comparison
        if let cached = cachedWeekInfo,
           let cachedDate = cachedWeekInfoDate,
           Calendar.iso8601.isDate(cachedDate, equalTo: selectedDate, toGranularity: .weekOfYear) {
            return cached
        }
        
        // Generate new week info and cache synchronously (no async overhead)
        let newWeekInfo = WeekInfo(for: selectedDate)
        cachedWeekInfo = newWeekInfo
        cachedWeekInfoDate = selectedDate
        return newWeekInfo
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height
                
                if isIPadDevice && isLandscape {
                    // iPad Landscape Layout
                    ipadLandscapeLayout
                } else {
                    // iPhone Portrait or iPad Portrait Layout
                    portraitLayout
                }
            }
            .background(safeAdaptiveBackground(isMonochrome: isMonochromeMode).ignoresSafeArea())
            
            // Floating Action Buttons - Settings and Today
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // Settings Button
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(isMonochromeMode ? AppColors.monoTextPrimary : .primary)
                                .frame(width: 44, height: 44) // Apple HIG minimum touch target
                                .background(
                                    Circle()
                                        .fill(isMonochromeMode ? 
                                              AppColors.monoSurfaceElevated : 
                                              safeAdaptiveSurface(isMonochrome: isMonochromeMode))
                                        .overlay(
                                            Circle()
                                                .stroke(isMonochromeMode ? 
                                                       AppColors.monoGlow : 
                                                       AppColors.divider, lineWidth: 0.5)
                                        )
                                        .shadow(color: isMonochromeMode ? 
                                               .black.opacity(0.5) : 
                                               .black.opacity(0.1), 
                                               radius: isMonochromeMode ? 8 : 4, 
                                               x: 0, y: 2)
                                )
                        }
                        .accessibilityLabel("Settings")
                        .accessibilityHint("Open settings to customize app appearance")
                        
                        // Today Button - Always visible, shows current date number
                        Button(action: {
                            // Safe today navigation
                            if !isNavigationInProgress {
                                isNavigationInProgress = true
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedDate = Date()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    isNavigationInProgress = false
                                }
                            }
                        }) {
                            Text(todayDateNumber())
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(Calendar.iso8601.isDateInToday(selectedDate) ? 
                                               .white : 
                                               (isMonochromeMode ? AppColors.monoTextPrimary : AppColors.accentBlue))
                                .frame(width: 44, height: 44) // Same size as settings button
                                .background(
                                    Circle()
                                        .fill(Calendar.iso8601.isDateInToday(selectedDate) ? 
                                              AppColors.accentBlue : 
                                              (isMonochromeMode ? 
                                               AppColors.monoSurfaceElevated : 
                                               safeAdaptiveSurface(isMonochrome: isMonochromeMode)))
                                        .overlay(
                                            Circle()
                                                .stroke(isMonochromeMode ? 
                                                       AppColors.monoGlow : 
                                                       AppColors.divider, 
                                                       lineWidth: 0.5)
                                        )
                                        .shadow(color: isMonochromeMode ? 
                                               .black.opacity(0.5) : 
                                               .black.opacity(0.1), 
                                               radius: isMonochromeMode ? 8 : 4, 
                                               x: 0, y: 2)
                                )
                        }
                        .accessibilityLabel("Go to today - \(todayButtonText())")
                        .accessibilityHint("Returns to the current date")
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 16)
                Spacer()
            }
        }
        .onAppear {
            // Enhanced initialization with error recovery
            Task {
                await performSafeInitialization()
            }
        }
        .onDisappear {
            // Clean up any ongoing operations to prevent XPC conflicts
            isNavigationInProgress = false
            isDraggingWeek = false
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            // XPC-Safe debounced saving with immediate execution for countdown navigation
            if isNavigationInProgress {
                // Skip automatic saving during navigation to prevent XPC conflicts
                // Manual saving will be handled by the navigation function
                return
            }
            
            // Standard debounced saving for other interactions
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second debounce
                if selectedDate == newValue { // Only save if still current
                    saveSelectedDate()
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                selectedCountdown: $selectedCountdown, 
                onCountdownChange: {
                    // Ensure safe countdown preference saving
                    Task {
                        await MainActor.run {
                            saveCountdownPreference()
                        }
                    }
                }
            )
            .interactiveDismissDisabled(false) // Allow swipe to dismiss
        }
        .alert("Happy Birthday, Nils!", isPresented: $showingBirthdayMessage) {
            Button("Thank you!") {
                showingBirthdayMessage = false
            }
        } message: {
            Text("🎂 January 30, 1983 - The birthday of Nils Johansson, the developer of Vecka!\n\n🎉 Thank you for discovering this hidden easter egg by tapping January 30 thirty times!")
        }
    }
    
    // MARK: - Portrait Layout (iPhone and iPad Portrait)
    private var portraitLayout: some View {
        VStack(spacing: 8) {
            Spacer()
            
            // Week number - hero element
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                    Text("VECKA")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                        .tracking(2)
                }
                
                Text("\(currentWeekInfo.weekNumber)")
                    .font(.system(size: 120, weight: .black, design: .rounded))
                    .foregroundStyle(safeColorForDay(selectedDate, isMonochrome: isMonochromeMode))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .scaleEffect(weekNumberScale)
                    .offset(x: weekNumberOffset)
                    .overlay(
                        // Monochrome glow effect
                        isMonochromeMode ? 
                        Text("\(currentWeekInfo.weekNumber)")
                            .font(.system(size: 120, weight: .black, design: .rounded))
                            .foregroundStyle(AppColors.monoGlow)
                            .blur(radius: 12)
                            .scaleEffect(weekNumberScale)
                            .offset(x: weekNumberOffset) : nil
                    )
                    .overlay(
                        // Subtle interaction indicator
                        isDraggingWeek ?
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(safeColorForDay(selectedDate, isMonochrome: isMonochromeMode).opacity(0.3), lineWidth: 2)
                            .scaleEffect(weekNumberScale * 1.1)
                            .animation(.easeOut(duration: 0.1), value: isDraggingWeek) : nil
                    )
                    .accessibilityLabel("Week \(currentWeekInfo.weekNumber) of \(currentWeekInfo.year)")
                    .accessibilityHint("Swipe anywhere on screen left for next week, swipe right for previous week")
                    .accessibilityAddTraits(.isButton)
                
                VStack(spacing: 4) {
                    Text(monthName(for: selectedDate))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                    
                    Text(String(currentWeekInfo.year))
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                }
            }
            
            Spacer()
            
            // Subtle swipe indicator (only shown briefly)
            if isDraggingWeek {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                        .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode).opacity(0.6))
                    
                    Text("Swipe to change week")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode).opacity(0.6))
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode).opacity(0.6))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.easeInOut(duration: 0.2), value: isDraggingWeek)
                .padding(.bottom, 12)
            }
            
            // Week dates - minimal strip
            HStack(spacing: 8) {
                ForEach(generateWeekDates(for: selectedDate), id: \.self) { date in
                    let isSelected = Calendar.iso8601.isDate(date, inSameDayAs: selectedDate)
                    let isToday = Calendar.iso8601.isDateInToday(date)
                    let dayColors = getDayColors(for: date)
                    
                    VStack(spacing: 4) {
                        Text(shortWeekday(date))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(dayColors.weekday)
                            .textCase(.uppercase)
                        
                        Text(dayNumber(date))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(isSelected ? .white : dayColors.day)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isSelected ? AppColors.accentBlue : .clear)
                                    .overlay(
                                        Circle()
                                            .stroke(AppColors.accentBlue, lineWidth: isSelected ? 0 : (isToday ? 2 : 0))
                                    )
                            )
                        
                        // Today indicator (small dot below)
                        Circle()
                            .frame(width: 4, height: 4)
                            .foregroundStyle(AppColors.accentBlue)
                            .opacity(isToday && !isSelected ? 1 : 0)
                    }
                    .frame(minWidth: 44, minHeight: 44) // Ensure minimum touch target size
                    .contentShape(Rectangle())
                    .accessibilityLabel("\(shortWeekday(date)), \(dayNumber(date))")
                    .accessibilityHint(isSelected ? "Currently selected" : "Tap to select this date")
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                    .onTapGesture {
                        // Check for birthday easter egg
                        let calendar = Calendar.iso8601
                        let month = calendar.component(.month, from: date)
                        let day = calendar.component(.day, from: date)
                        
                        if month == 1 && day == 30 {
                            januaryTapCount += 1
                            if januaryTapCount >= 30 {
                                showingBirthdayMessage = true
                                januaryTapCount = 0
                            }
                        } else if month != 1 || day != 30 {
                            // Only reset when tapping dates other than January 30
                            januaryTapCount = 0
                        }
                        
                        // Safe date selection with validation
                        let validDate = validateDateForNavigation(date, fallback: Date())
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedDate = validDate
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Intelligent Mini Dashboard
            VStack(spacing: 16) {
                // Primary Information Row
                HStack(spacing: 16) {
                    // Month Progress
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar")
                                .font(.caption2)
                                .foregroundStyle(AppColors.accentBlue)
                            Text("MONTH")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                        }
                        Text("\(Int(getMonthProgress() * 100))% complete")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                    }
                    
                    Spacer()
                    
                    // Countdown Section (Enhanced XPC-Safe Tappable)
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(selectedCountdown.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            Image(systemName: selectedCountdown.icon)
                                .font(.caption2)
                                .foregroundStyle(AppColors.accentYellow)
                        }
                        Text(countdownDaysText())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                    }
                    .contentShape(Rectangle()) // Ensure full area is tappable
                    .onTapGesture {
                        // Safe countdown navigation with haptic feedback
                        safeNavigateToCountdownDate()
                    }
                    .accessibilityLabel("\(selectedCountdown.displayName) countdown")
                    .accessibilityHint("\(countdownDaysText()). Tap to navigate to countdown date")
                    .accessibilityAddTraits(.isButton)
                }
                
                // Next Holiday Information
                if let nextHoliday = getNextUpcomingHoliday() {
                    Button(action: {
                        navigateToDate(nextHoliday.date)
                    }) {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.accentRed)
                                Text("NEXT EVENT")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                                Spacer()
                                Text(daysUntilText(for: nextHoliday))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppColors.adaptiveTextTertiary(isMonochrome: isMonochromeMode))
                            }
                            
                            Text(holidayDisplayName(for: nextHoliday))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(nextHoliday.isOfficial ? AppColors.accentRed : AppColors.accentBlue)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Next event: \(holidayDisplayName(for: nextHoliday))")
                    .accessibilityHint("\(daysUntilText(for: nextHoliday)). Tap to navigate to this date")
                }
                
                // Selected Date Information (if different from today)
                if let holidayName = getHolidayName(for: selectedDate) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "star")
                                .font(.caption2)
                                .foregroundStyle(AppColors.accentRed)
                            let displayText = Calendar.iso8601.isDateInToday(selectedDate) ? "TODAY" : "SELECTED"
                            Text(displayText)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            Spacer()
                        }
                        
                        Text(holidayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.accentRed)
                            .multilineTextAlignment(.center)
                    }
                } else if !Calendar.iso8601.isDateInToday(selectedDate) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundStyle(AppColors.adaptiveTextTertiary(isMonochrome: isMonochromeMode))
                            Text("SELECTED")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            Spacer()
                        }
                        
                        Text(selectedDateText())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.adaptiveTextTertiary(isMonochrome: isMonochromeMode))
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(safeAdaptiveSurface(isMonochrome: isMonochromeMode))
                    .overlay(
                        // Monochrome mode glass effect
                        isMonochromeMode ? 
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.monoGlow, lineWidth: 0.5) : nil
                    )
                    .shadow(color: isMonochromeMode ? .black.opacity(0.4) : .black.opacity(0.05), 
                           radius: isMonochromeMode ? 12 : 8, x: 0, y: 4)
            )
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .contentShape(Rectangle()) // Enable full-screen touch detection
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    // Only respond to horizontal swipes (avoid conflicts with vertical scrolling)
                    let horizontalMovement = abs(value.translation.width)
                    let verticalMovement = abs(value.translation.height)
                    
                    // Require horizontal movement to be significantly more than vertical
                    guard horizontalMovement > verticalMovement * 1.5 else { return }
                    
                    // Subtle haptic feedback on start
                    if !isDraggingWeek {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        isDraggingWeek = true
                    }
                    
                    // Tinder-like visual feedback on week number
                    let dragAmount = value.translation.width
                    weekNumberOffset = dragAmount * 0.2 // Subtle movement
                    
                    // Subtle scale effect based on drag distance
                    let scaleAmount = 1.0 + (abs(dragAmount) / 2000) // Very subtle growth
                    weekNumberScale = min(1.03, scaleAmount)
                }
                .onEnded { value in
                    let dragDistance = value.translation.width
                    let velocity = value.predictedEndTranslation.width
                    
                    // Tinder-style thresholds for swipe detection
                    let distanceThreshold: CGFloat = 100
                    let velocityThreshold: CGFloat = 400
                    
                    var shouldChangeWeek = false
                    var direction = 0
                    
                    if dragDistance > distanceThreshold || velocity > velocityThreshold {
                        // Swipe right - previous week (Tinder-style: throwing current away)
                        shouldChangeWeek = true
                        direction = -1
                    } else if dragDistance < -distanceThreshold || velocity < -velocityThreshold {
                        // Swipe left - next week (Tinder-style: throwing current away)
                        shouldChangeWeek = true
                        direction = 1
                    }
                    
                    if shouldChangeWeek {
                        // Success haptic
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        
                        // Safe week change with reduced animation complexity
                        if !isNavigationInProgress {
                            isNavigationInProgress = true
                            withAnimation(.easeInOut(duration: 0.4)) {
                                changeWeek(direction)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isNavigationInProgress = false
                            }
                        }
                    }
                    
                    // Reset visual state with safer animation
                    withAnimation(.easeOut(duration: 0.3)) {
                        weekNumberOffset = 0
                        weekNumberScale = 1.0
                        isDraggingWeek = false
                    }
                }
        )
    }
    
    // MARK: - iPad Landscape Layout
    private var ipadLandscapeLayout: some View {
        HStack(spacing: 0) {
            // Left Side - Week Information (1/3 of screen)
            VStack(spacing: 20) {
                Spacer()
                
                // Week number - hero element
                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                        Text("VECKA")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            .tracking(2)
                    }
                    
                    Text("\(currentWeekInfo.weekNumber)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundStyle(safeColorForDay(selectedDate, isMonochrome: isMonochromeMode))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .overlay(
                            // Monochrome glow effect
                            isMonochromeMode ? 
                            Text("\(currentWeekInfo.weekNumber)")
                                .font(.system(size: 80, weight: .black, design: .rounded))
                                .foregroundStyle(AppColors.monoGlow)
                                .blur(radius: 8) : nil
                        )
                    
                    VStack(spacing: 4) {
                        Text(monthName(for: selectedDate))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                        
                        Text(String(currentWeekInfo.year))
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                    }
                }
                
                Spacer()
                
                // Mini Dashboard
                VStack(spacing: 12) {
                    // Month Progress & Countdown
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 3) {
                                Image(systemName: "chart.bar")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.accentBlue)
                                Text("MONTH")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            }
                            Text("\(Int(getMonthProgress() * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                        }
                        
                        Spacer()
                        
                        // Enhanced XPC-Safe Countdown Button for iPad
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 3) {
                                Text(selectedCountdown.displayName)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                                Image(systemName: selectedCountdown.icon)
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.accentYellow)
                            }
                            Text(countdownDaysText())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                        }
                        .contentShape(Rectangle()) // Ensure full area is tappable
                        .onTapGesture {
                            // Safe countdown navigation with haptic feedback
                            safeNavigateToCountdownDate()
                        }
                        .accessibilityLabel("\(selectedCountdown.displayName) countdown")
                        .accessibilityHint("\(countdownDaysText()). Tap to navigate to countdown date")
                        .accessibilityAddTraits(.isButton)
                    }
                    
                    // Next Event
                    if let nextHoliday = getNextUpcomingHoliday() {
                        Button(action: {
                            navigateToDate(nextHoliday.date)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.accentRed)
                                
                                Text(holidayDisplayName(for: nextHoliday))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(nextHoliday.isOfficial ? AppColors.accentRed : AppColors.accentBlue)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(daysUntilText(for: nextHoliday))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppColors.adaptiveTextTertiary(isMonochrome: isMonochromeMode))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Next event: \(holidayDisplayName(for: nextHoliday))")
                        .accessibilityHint("\(daysUntilText(for: nextHoliday)). Tap to navigate to this date")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(safeAdaptiveSurface(isMonochrome: isMonochromeMode))
                        .overlay(
                            // Monochrome mode glass effect
                            isMonochromeMode ? 
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppColors.monoGlow, lineWidth: 0.5) : nil
                        )
                        .shadow(color: isMonochromeMode ? .black.opacity(0.4) : .black.opacity(0.05), 
                               radius: isMonochromeMode ? 10 : 6, x: 0, y: 3)
                )
                
                Spacer()
                
                // Navigation
                HStack(spacing: 16) {
                    Button("◀") {
                        changeWeek(-1)
                    }
                    .font(.title3)
                    .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                    .accessibilityLabel("Previous week")
                    .accessibilityHint("Go to the previous week")
                    
                    Text(currentWeekInfo.dateRange)
                        .font(.caption)
                        .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                        .monospacedDigit()
                    
                    Button("▶") {
                        changeWeek(1)
                    }
                    .font(.title3)
                    .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                    .accessibilityLabel("Next week")
                    .accessibilityHint("Go to the next week")
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            
            // Divider
            Rectangle()
                .fill(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode).opacity(0.2))
                .frame(width: 1)
                .padding(.vertical, 40)
            
            // Right Side - Week Calendar (2/3 of screen)
            VStack(spacing: 16) {
                Spacer()
                
                // Week dates grid for iPad landscape
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 16) {
                    ForEach(generateWeekDates(for: selectedDate), id: \.self) { date in
                        let isSelected = Calendar.iso8601.isDate(date, inSameDayAs: selectedDate)
                        let isToday = Calendar.iso8601.isDateInToday(date)
                        let dayColors = getDayColors(for: date)
                        
                        VStack(spacing: 8) {
                            Text(shortWeekday(date))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(dayColors.weekday)
                                .textCase(.uppercase)
                            
                            Text(dayNumber(date))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(isSelected ? .white : dayColors.day)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(isSelected ? AppColors.accentBlue : .clear)
                                        .overlay(
                                            Circle()
                                                .stroke(AppColors.accentBlue, lineWidth: isSelected ? 0 : (isToday ? 2 : 0))
                                        )
                                )
                            
                            // Today indicator
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundStyle(AppColors.accentBlue)
                                .opacity(isToday && !isSelected ? 1 : 0)
                        }
                        .frame(minWidth: 44, minHeight: 44) // Ensure minimum touch target size
                        .contentShape(Rectangle())
                        .accessibilityLabel("\(shortWeekday(date)), \(dayNumber(date))")
                        .accessibilityHint(isSelected ? "Currently selected" : "Tap to select this date")
                        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                        .onTapGesture {
                            // Birthday easter egg logic
                            let calendar = Calendar.iso8601
                            let month = calendar.component(.month, from: date)
                            let day = calendar.component(.day, from: date)
                            
                            if month == 1 && day == 30 {
                                januaryTapCount += 1
                                if januaryTapCount >= 30 {
                                    showingBirthdayMessage = true
                                    januaryTapCount = 0
                                }
                            } else if month != 1 || day != 30 {
                                januaryTapCount = 0
                            }
                            
                            // Safe date selection with validation for iPad
                            let validDate = validateDateForNavigation(date, fallback: Date())
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedDate = validDate
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Simplified Helper Functions
    
    private func shortWeekday(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
    }
    
    private func dayNumber(_ date: Date) -> String {
        date.formatted(.dateTime.day())
    }
    
    private func monthName(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide))
    }
    
    private func getHolidayName(for date: Date) -> String? {
        guard let calculator = holidayCalculator else { return nil }
        let year = Calendar.iso8601.component(.year, from: date)
        do {
            let holidays = try calculator.holidays(for: year)
            if let holiday = holidays.first(where: { Calendar.iso8601.isDate($0.date, inSameDayAs: date) }) {
                return holidayDisplayName(for: holiday)
            }
            return nil
        } catch {
            return nil
        }
    }
    
    private func selectedDateText() -> String {
        selectedDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func todayButtonText() -> String {
        let today = Date()
        return today.formatted(.dateTime.month(.abbreviated).day())
    }
    
    private func todayDateNumber() -> String {
        let today = Date()
        return today.formatted(.dateTime.day())
    }
    
    // MARK: - Dashboard Helper Functions
    
    private func getMonthProgress() -> Double {
        return holidayCalculator?.monthProgress(for: selectedDate) ?? 0.0
    }
    
    private func getDaysUntilCountdown() -> Int {
        // Always calculate from today's actual date, not selectedDate
        let today = Date()
        let currentYear = Calendar.iso8601.component(.year, from: today)
        
        // Handle custom countdowns specially
        if case .custom(let customCountdown) = selectedCountdown {
            if customCountdown.isAnnual {
                // Annual logic - find next occurrence
                guard let thisYearDate = customCountdown.targetDate(for: currentYear) else { return 0 }
                let targetDate = thisYearDate <= today ? 
                    (customCountdown.targetDate(for: currentYear + 1) ?? thisYearDate) : thisYearDate
                return Calendar.iso8601.dateComponents([.day], from: today, to: targetDate).day ?? 0
            } else {
                // One-time event - show actual countdown (can be negative if passed)
                let targetDate = customCountdown.date
                // Use start of day for both dates to avoid time-of-day issues
                let todayStartOfDay = Calendar.iso8601.startOfDay(for: today)
                let targetStartOfDay = Calendar.iso8601.startOfDay(for: targetDate)
                return Calendar.iso8601.dateComponents([.day], from: todayStartOfDay, to: targetStartOfDay).day ?? 0
            }
        }
        
        // Existing logic for predefined countdowns
        var targetYear = currentYear
        if let targetDate = selectedCountdown.targetDate(for: currentYear),
           targetDate <= today {
            targetYear = currentYear + 1
        }
        
        guard let targetDate = selectedCountdown.targetDate(for: targetYear) else {
            return 0
        }
        
        return Calendar.iso8601.dateComponents([.day], from: today, to: targetDate).day ?? 0
    }
    
    private func getNextUpcomingHoliday() -> HolidayDate? {
        return holidayCalculator?.nextUpcomingHoliday(from: selectedDate)
    }
    
    private func daysUntilText(for holiday: HolidayDate) -> String {
        let days = Calendar.iso8601.dateComponents([.day], from: selectedDate, to: holiday.date).day ?? 0
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "\(days) days"
        }
    }
    
    private func countdownDaysText() -> String {
        let days = getDaysUntilCountdown()
        if days < 0 {
            return "\(abs(days)) days ago"
        } else if days == 0 {
            return "Today!"
        } else if days == 1 {
            return "Tomorrow!"
        } else {
            return "\(days) days"
        }
    }
    
    private func holidayDisplayName(for holiday: HolidayDate) -> String {
        let locale = Locale.current
        let isSwedish = locale.language.languageCode?.identifier == "sv"
        return isSwedish ? holiday.nameSV : holiday.nameEN
    }
    
    private func navigateToDate(_ date: Date) {
        // Enhanced safe navigation with validation
        guard !isRunningInPreview() else {
            selectedDate = date
            return
        }
        
        // Prevent concurrent navigation
        guard !isNavigationInProgress else { return }
        
        isNavigationInProgress = true
        
        // Validate and navigate to date
        let validDate = validateDateForNavigation(date, fallback: Date())
        
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = validDate
        }
        
        // Reset navigation state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isNavigationInProgress = false
        }
    }
    
    private func navigateToCountdownDate() {
        // Enhanced XPC-safe preview detection
        guard !isRunningInPreview() else {
            // In preview mode, provide safe fallback behavior
            if let countdownDate = safeTargetDate() {
                // Use immediate assignment without animation in previews
                selectedDate = countdownDate
            }
            return
        }
        
        // Prevent concurrent navigation operations
        guard !isNavigationInProgress else { return }
        
        // Set navigation state to prevent reentrancy
        isNavigationInProgress = true
        
        // Safe navigation with comprehensive error handling
        guard let countdownDate = safeTargetDate() else {
            // Fallback: navigate to today if countdown date calculation fails
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDate = Date()
            }
            // Reset navigation state after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isNavigationInProgress = false
            }
            return
        }
        
        // Validate countdown date is reasonable
        let now = Date()
        let validDate = validateDateForNavigation(countdownDate, fallback: now)
        
        // Provide haptic feedback for user confirmation
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Use immediate synchronous update to prevent XPC conflicts
        selectedDate = validDate
        
        // Manual AppStorage save after state is stable
        saveSelectedDateManually()
        
        // Reset navigation state immediately
        isNavigationInProgress = false
    }
    
    private func saveSelectedDateManually() {
        guard !isRunningInPreview() else { return }
        
        do {
            let encoded = try JSONEncoder().encode(selectedDate.timeIntervalSince1970)
            selectedDateData = encoded
        } catch {
            print("Warning: Failed to encode selectedDate: \(error)")
        }
    }
    
    /// XPC-Safe immediate countdown navigation without async dispatch
    private func immediateNavigateToCountdownDate() {
        // Enhanced XPC-safe preview detection
        guard !isRunningInPreview() else {
            // In preview mode, provide safe fallback behavior
            if let countdownDate = safeTargetDate() {
                // Use immediate assignment without animation in previews
                selectedDate = countdownDate
            }
            return
        }
        
        // Prevent concurrent navigation operations
        guard !isNavigationInProgress else { return }
        
        // Set navigation state to prevent reentrancy
        isNavigationInProgress = true
        
        // Set flag to disable AppStorage auto-save during navigation to prevent XPC conflicts
        // (selectedDate will be updated below)
        
        // Safe navigation with comprehensive error handling
        guard let countdownDate = safeTargetDate() else {
            // Fallback: navigate to today if countdown date calculation fails
            selectedDate = Date()
            // Reset navigation state immediately to prevent XPC conflicts
            isNavigationInProgress = false
            return
        }
        
        // Validate countdown date is reasonable
        let now = Date()
        let validDate = validateDateForNavigation(countdownDate, fallback: now)
        
        // Use immediate assignment without animation to prevent XPC conflicts
        selectedDate = validDate
        
        // Reset navigation state immediately
        isNavigationInProgress = false
        
        // Manual save to AppStorage after state is stable
        saveSelectedDateManually()
    }
    
    /// Validate date is within reasonable bounds for navigation
    private func validateDateForNavigation(_ date: Date, fallback: Date) -> Date {
        let now = Date()
        let fiveYearsAgo = Calendar.iso8601.date(byAdding: .year, value: -5, to: now) ?? now
        let fiveYearsFromNow = Calendar.iso8601.date(byAdding: .year, value: 5, to: now) ?? now
        
        // Return validated date or fallback if out of range
        return (date >= fiveYearsAgo && date <= fiveYearsFromNow) ? date : fallback
    }
    
    /// Enhanced thread-safe preview environment detection
    private func isRunningInPreview() -> Bool {
        // Multiple fallback checks for preview detection with thread safety
        let environment = ProcessInfo.processInfo.environment
        let processName = ProcessInfo.processInfo.processName
        
        return environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ||
               processName.contains("Preview") ||
               processName.contains("SwiftUI") ||
               NSClassFromString("SwiftUI.PreviewHost") != nil ||
               NSClassFromString("XCPreviewAgent") != nil
    }
    
    /// Thread-safe target date calculation with comprehensive error handling
    private func safeTargetDate() -> Date? {
        // Prevent any potential XPC calls during countdown date calculation
        guard !isRunningInPreview() else {
            // In preview, return a static safe date
            return Calendar.iso8601.date(from: DateComponents(year: 2024, month: 12, day: 25))
        }
        
        let currentYear = Calendar.iso8601.component(.year, from: Date())
        
        // Thread-safe countdown target date calculation
        let targetDate = selectedCountdown.targetDate(for: currentYear)
        
        // Validate the target date before returning
        if let date = targetDate {
            let now = Date()
            let fiveYearsFromNow = Calendar.iso8601.date(byAdding: .year, value: 5, to: now) ?? now
            let oneYearAgo = Calendar.iso8601.date(byAdding: .year, value: -1, to: now) ?? now
            
            // Ensure target date is within reasonable bounds
            if date >= oneYearAgo && date <= fiveYearsFromNow {
                return date
            }
        }
        
        // Fallback to today if target date is invalid
        return Date()
    }
    
    /// Enhanced XPC-safe countdown navigation with haptic feedback
    private func safeNavigateToCountdownDate() {
        // Prevent double-tap issues with state guard
        guard !isDraggingWeek else { return }
        
        // Provide haptic feedback for user confirmation
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // XPC-Safe navigation with immediate state update and no async dispatch
        immediateNavigateToCountdownDate()
    }
    
    // MARK: - Countdown Persistence
    
    private func loadCountdownPreference() {
        guard !countdownTypeData.isEmpty,
              let countdown = try? JSONDecoder().decode(CountdownType.self, from: countdownTypeData) else {
            selectedCountdown = .newYear
            return
        }
        selectedCountdown = countdown
    }
    
    private func saveCountdownPreference() {
        // Enhanced XPC-safe countdown preference saving
        guard !isRunningInPreview() else { return }
        
        // Prevent saving during navigation to avoid XPC conflicts
        guard !isNavigationInProgress else {
            // Defer save until navigation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.saveCountdownPreference()
            }
            return
        }
        
        // Simple synchronous approach to prevent XPC issues
        guard let encoded = try? JSONEncoder().encode(selectedCountdown) else {
            print("Warning: Failed to encode countdown preference")
            return
        }
        countdownTypeData = encoded
    }
    
    private struct DayColors {
        let weekday: Color
        let day: Color
    }
    
    private func getDayColors(for date: Date) -> DayColors {
        let weekday = Calendar.iso8601.component(.weekday, from: date)
        
        // Check if it's a holiday first
        if let calculator = holidayCalculator, calculator.isHoliday(date) {
            return DayColors(weekday: AppColors.accentRed, day: AppColors.accentRed)
        }
        
        switch weekday {
        case 7: // Saturday
            return DayColors(weekday: AppColors.accentBlue, day: AppColors.accentBlue)
        case 1: // Sunday
            return DayColors(weekday: AppColors.accentRed, day: AppColors.accentRed)
        default:
            return DayColors(
                weekday: AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode), 
                day: AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode)
            )
        }
    }
    
    // Keep these for backward compatibility if needed elsewhere
    private func weekdayColor(for date: Date) -> Color {
        return getDayColors(for: date).weekday
    }
    
    private func weekendDayColor(for date: Date) -> Color {
        return getDayColors(for: date).day
    }
    
    
    // MARK: - Helper Functions
    
    private func generateWeekDates(for date: Date) -> [Date] {
        let calendar = Calendar.iso8601
        let weekInfo = WeekInfo(for: date)
        var dates: [Date] = []
        
        for i in 0..<7 {
            if let weekDate = calendar.date(byAdding: .day, value: i, to: weekInfo.startDate) {
                dates.append(weekDate)
            }
        }
        
        return dates
    }
    
    // MARK: - Navigation Helper Functions
    
    private func changeWeek(_ direction: Int) {
        // Safe week navigation with validation
        guard let newDate = Calendar.iso8601.date(byAdding: .weekOfYear, value: direction, to: selectedDate) else {
            // Fallback to today if calculation fails
            selectedDate = Date()
            cachedWeekInfo = nil
            return
        }
        
        // Validate new date is within reasonable bounds
        let validatedDate = validateDateForNavigation(newDate, fallback: selectedDate)
        selectedDate = validatedDate
        
        // Safely invalidate cache
        cachedWeekInfo = nil
        cachedWeekInfoDate = nil
    }
    
    private func saveSelectedDate() {
        // Enhanced XPC-safe preview detection
        guard !isRunningInPreview() else {
            return
        }
        
        // Prevent saving during navigation to avoid XPC conflicts
        guard !isNavigationInProgress else {
            return
        }
        
        // Simple synchronous approach to prevent XPC issues
        guard let encoded = try? JSONEncoder().encode(selectedDate.timeIntervalSince1970) else {
            print("Warning: Failed to encode selectedDate")
            return
        }
        selectedDateData = encoded
    }
    
    /// Manual AppStorage save that bypasses navigation state checks
    
    
    private func loadSelectedDate() {
        // Enhanced XPC-safe preview detection
        guard !isRunningInPreview() else {
            selectedDate = Date()
            return
        }
        
        // Simple synchronous approach to prevent XPC issues
        guard !selectedDateData.isEmpty,
              let timeInterval = try? JSONDecoder().decode(TimeInterval.self, from: selectedDateData) else {
            selectedDate = Date()
            return
        }
        
        let decodedDate = Date(timeIntervalSince1970: timeInterval)
        
        // Validate date is reasonable (within 10 years of now)
        let now = Date()
        let tenYearsAgo = Calendar.iso8601.date(byAdding: .year, value: -10, to: now) ?? now
        let tenYearsFromNow = Calendar.iso8601.date(byAdding: .year, value: 10, to: now) ?? now
        
        selectedDate = (decodedDate >= tenYearsAgo && decodedDate <= tenYearsFromNow) ? decodedDate : now
    }
    
    private func initializeHolidayCalculator() {
        do {
            holidayCalculator = try SwedishHolidayCalculator()
        } catch {
            print("Failed to initialize holiday calculator: \(error.localizedDescription)")
            // Continue without holiday calculator rather than crashing
            holidayCalculator = nil
        }
    }
    
    /// Enhanced safe initialization with comprehensive error recovery
    @MainActor
    private func performSafeInitialization() async {
        // Initialize components in safe order with individual error handling
        // Load saved date first
        loadSelectedDate()
        
        // Initialize holiday calculator
        initializeHolidayCalculator()
        
        // Load countdown preference
        loadCountdownPreference()
        
        // Validate current state
        if !isRunningInPreview() {
            selectedDate = validateDateForNavigation(selectedDate, fallback: Date())
        }
    }
    
    // MARK: - Direct Color Helper Functions
    
    /// Direct color evaluation for day colors
    private func safeColorForDay(_ date: Date, isMonochrome: Bool) -> Color {
        return AppColors.colorForDay(date, isMonochrome: isMonochrome)
    }
    
    /// Direct adaptive background color
    private func safeAdaptiveBackground(isMonochrome: Bool) -> Color {
        return AppColors.adaptiveBackground(isMonochrome: isMonochrome)
    }
    
    /// Direct adaptive surface color
    private func safeAdaptiveSurface(isMonochrome: Bool) -> Color {
        return AppColors.adaptiveSurface(isMonochrome: isMonochrome)
    }
}

// MARK: - Countdown Picker Sheets

struct CountdownCard: View {
    let countdown: CountdownType
    let isSelected: Bool
    let onTap: () -> Void
    @AppStorage("isMonochromeMode") private var isMonochromeMode: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.accentYellow.gradient)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: countdown.icon)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
                
                Text(countdown.displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.adaptiveSurface(isMonochrome: isMonochromeMode))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? AppColors.accentBlue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct CountdownPickerSheet: View {
    @Binding var selectedCountdown: CountdownType
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isMonochromeMode") private var isMonochromeMode: Bool = false
    
    // Performance optimization: cache device type to avoid repeated UIDevice.current calls
    @State private var isIPadDevice = UIDevice.current.userInterfaceIdiom == .pad
    
    // Direct color evaluation for optimal performance
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let isIPad = isIPadDevice
                let columns = isIPad ? 4 : 2
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header Section
                        VStack(spacing: 8) {
                            Text("Choose Countdown")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                            
                            Text("Select an event to countdown to")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                        }
                        .padding(.top, 24)
                        
                        // Cards Grid
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: columns),
                            spacing: 16
                        ) {
                            ForEach(CountdownType.predefinedCases, id: \.displayName) { countdown in
                                CountdownOptionCard(
                                    countdown: countdown,
                                    isSelected: selectedCountdown.displayName == countdown.displayName,
                                    onTap: {
                                        selectedCountdown = countdown
                                        onSave()
                                        dismiss()
                                    }
                                )
                            }
                            
                    }
                    .padding(.horizontal, 20)
                    
                        Spacer(minLength: 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .background(safeAdaptiveBackground(isMonochrome: isMonochromeMode).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.accentBlue)
                    .accessibilityLabel("Done")
                    .accessibilityHint("Close countdown picker")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Direct Color Helper Functions
    
    /// Direct adaptive background color
    private func safeAdaptiveBackground(isMonochrome: Bool) -> Color {
        return AppColors.adaptiveBackground(isMonochrome: isMonochrome)
    }
    
    /// Direct adaptive surface color
    private func safeAdaptiveSurface(isMonochrome: Bool) -> Color {
        return AppColors.adaptiveSurface(isMonochrome: isMonochrome)
    }
}

struct CountdownOptionCard: View {
    let countdown: CountdownType
    let isSelected: Bool
    let onTap: () -> Void
    @AppStorage("isMonochromeMode") private var isMonochromeMode: Bool = false
    
    // Direct color evaluation for optimal performance
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon with glassmorphism background
                ZStack {
                    Circle()
                        .fill(isSelected ? .white.opacity(0.2) : AppColors.accentBlue.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: countdown.icon)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? .white : AppColors.accentBlue)
                }
                
                // Text content
                VStack(spacing: 2) {
                    Text(countdown.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    
                    if let daysText = getDaysUntilText(for: countdown) {
                        Text(daysText)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ? 
                        AppColors.accentBlue :
                        safeAdaptiveSurface(isMonochrome: isMonochromeMode)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? 
                                AppColors.accentBlue.opacity(0.3) : 
                                Color.clear,
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
                    .shadow(
                        color: isSelected ? 
                        AppColors.accentBlue.opacity(0.3) : 
                        .black.opacity(0.06),
                        radius: isSelected ? 8 : 6,
                        x: 0,
                        y: isSelected ? 4 : 3
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .accessibilityLabel("\(countdown.displayName) countdown")
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to select this countdown")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
    
    private func getDaysUntilText(for countdown: CountdownType) -> String? {
        let today = Date()
        let currentYear = Calendar.iso8601.component(.year, from: today)
        
        // Handle custom countdowns specially
        if case .custom(let customCountdown) = countdown {
            if customCountdown.isAnnual {
                // Annual logic - find next occurrence
                guard let thisYearDate = customCountdown.targetDate(for: currentYear) else { return nil }
                let targetDate = thisYearDate <= today ? 
                    (customCountdown.targetDate(for: currentYear + 1) ?? thisYearDate) : thisYearDate
                let days = Calendar.iso8601.dateComponents([.day], from: today, to: targetDate).day ?? 0
                return days == 0 ? "Today" : days == 1 ? "Tomorrow" : "\(days) days"
            } else {
                // One-time event
                let targetDate = customCountdown.date
                let todayStartOfDay = Calendar.iso8601.startOfDay(for: today)
                let targetStartOfDay = Calendar.iso8601.startOfDay(for: targetDate)
                let days = Calendar.iso8601.dateComponents([.day], from: todayStartOfDay, to: targetStartOfDay).day ?? 0
                
                if days < 0 {
                    return "\(abs(days)) days ago"
                } else if days == 0 {
                    return "Today"
                } else if days == 1 {
                    return "Tomorrow"
                } else {
                    return "\(days) days"
                }
            }
        }
        
        // Existing logic for predefined countdowns
        var targetYear = currentYear
        if let targetDate = countdown.targetDate(for: currentYear),
           targetDate <= today {
            targetYear = currentYear + 1
        }
        
        guard let targetDate = countdown.targetDate(for: targetYear) else {
            return nil
        }
        
        let days = Calendar.iso8601.dateComponents([.day], from: today, to: targetDate).day ?? 0
        return days == 0 ? "Today" : days == 1 ? "Tomorrow" : "\(days) days"
    }
    
    // MARK: - Direct Color Helper Functions
    
    /// Direct adaptive surface color
    private func safeAdaptiveSurface(isMonochrome: Bool) -> Color {
        return AppColors.adaptiveSurface(isMonochrome: isMonochrome)
    }
}

struct CustomCountdownDialog: View {
    @Binding var name: String
    @Binding var date: Date
    @Binding var isAnnual: Bool
    @Binding var selectedCountdown: CountdownType
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isMonochromeMode") private var isMonochromeMode: Bool = false
    
    private var isValidInput: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && 
               trimmedName.count <= 30 && 
               trimmedName.allSatisfy { $0.isLetter || $0.isNumber || $0.isWhitespace || ".-_".contains($0) } &&
               !containsProfanity(trimmedName)
    }
    
    private func containsProfanity(_ text: String) -> Bool {
        let lowercaseText = text.lowercased()
        let profanityList = [
            "damn", "hell", "shit", "fuck", "ass", "bitch", "bastard", "piss", "crap",
            "suck", "stupid", "idiot", "moron", "retard", "gay", "fag", "whore", "slut"
        ]
        
        return profanityList.contains { profanity in
            lowercaseText.contains(profanity)
        }
    }
    
    private func getValidationMessage() -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return "Name cannot be empty"
        } else if trimmedName.count > 30 {
            return "Name must be 30 characters or less"
        } else if !trimmedName.allSatisfy({ $0.isLetter || $0.isNumber || $0.isWhitespace || ".-_".contains($0) }) {
            return "Name can only contain letters, numbers, spaces, dots, dashes, and underscores"
        } else if containsProfanity(trimmedName) {
            return "Please choose a more appropriate name"
        } else {
            return "Invalid name"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Create Custom Countdown")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                VStack(spacing: 20) {
                    // Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Countdown Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                        
                        TextField("Enter countdown name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                        
                        if !name.isEmpty && !isValidInput {
                            Text(getValidationMessage())
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.top, 4)
                        }
                    }
                    
                    // Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                        
                        DatePicker(
                            "Target Date",
                            selection: $date,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                    
                    // Annual Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Repeat Type")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppColors.adaptiveTextPrimary(isMonochrome: isMonochromeMode))
                                
                                Text(isAnnual ? "Repeats every year" : "One-time event")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isAnnual)
                                .labelsHidden()
                        }
                        
                        Text(isAnnual ? "Perfect for birthdays, anniversaries, and holidays" : "Great for specific dates like project deadlines")
                            .font(.caption2)
                            .foregroundStyle(AppColors.adaptiveTextSecondary(isMonochrome: isMonochromeMode))
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Cancel creating custom countdown")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let customCountdown = CustomCountdown(
                            name: trimmedName,
                            date: date,
                            isAnnual: isAnnual
                        )
                        selectedCountdown = .custom(customCountdown)
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidInput)
                    .accessibilityLabel("Save")
                    .accessibilityHint("Save custom countdown and close dialog")
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Current Week") {
    ContentView()
        .environment(\.locale, Locale(identifier: "en_US"))
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ContentView()
        .environment(\.locale, Locale(identifier: "en_US"))
        .preferredColorScheme(.dark)
}

#Preview("Swedish Locale") {
    ContentView()
        .environment(\.locale, Locale(identifier: "sv_SE"))
        .preferredColorScheme(.light)
}
