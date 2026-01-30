//
//  CalendarGridView.swift
//  Vecka
//
//  Japanese packaging design - Bold borders, bright colors, maximum contrast
//  情報デザイン (Jōhō Dezain)
//

import SwiftUI
// MARK: - Weather Disabled (Isolated for Future Update)
// import WeatherKit

struct CalendarGridView: View {
    let month: CalendarMonth
    let selectedWeek: CalendarWeek?
    let selectedDay: CalendarDay? // Added for selection styling
    let onDayTap: (CalendarDay) -> Void
    let onWeekTap: (CalendarWeek) -> Void
    /// 情報デザイン: Long-press callback for day detail sheet
    let onDayLongPress: ((CalendarDay) -> Void)?
    /// 情報デザイン: Data check callback for showing colored indicators
    /// Returns which special day types exist for a given date
    let hasDataForDay: ((Date) -> DayDataCheck)?

    // MARK: - Environment for dark mode
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // MARK: - Lunar Calendar Support (Âm Lịch)
    @AppStorage("showLunarCalendar") private var showLunarCalendar = false
    private let lunarService = LunarCalendarService.shared

    /// 情報デザイン: Callback when calendar icon is tapped (opens month picker)
    let onCalendarIconTap: (() -> Void)?

    init(
        month: CalendarMonth,
        selectedWeek: CalendarWeek?,
        selectedDay: CalendarDay?,
        onDayTap: @escaping (CalendarDay) -> Void,
        onWeekTap: @escaping (CalendarWeek) -> Void,
        onDayLongPress: ((CalendarDay) -> Void)? = nil,
        hasDataForDay: ((Date) -> DayDataCheck)? = nil,
        onCalendarIconTap: (() -> Void)? = nil
    ) {
        self.month = month
        self.selectedWeek = selectedWeek
        self.selectedDay = selectedDay
        self.onDayTap = onDayTap
        self.onWeekTap = onWeekTap
        self.onDayLongPress = onDayLongPress
        self.hasDataForDay = hasDataForDay
        self.onCalendarIconTap = onCalendarIconTap
    }
}

// MARK: - Day Data Check (情報デザイン: Unified special day types)

/// Position of a day within a multi-day trip span
enum TripDayPosition {
    case single    // Single-day trip (or isolated day)
    case start     // First day of multi-day trip [▶
    case middle    // Middle day of multi-day trip ──
    case end       // Last day of multi-day trip ◀]
}

/// Tracks which special day types exist for a calendar day
struct DayDataCheck {
    var hasHoliday: Bool = false      // RED - HOL
    var hasObservance: Bool = false   // ORANGE - OBS
    var hasEvent: Bool = false        // PURPLE - EVT
    var hasBirthday: Bool = false     // PINK - BDY (from Contacts)
    var hasNote: Bool = false         // YELLOW - NTE
    var hasTrip: Bool = false         // BLUE - TRP
    var hasExpense: Bool = false      // GREEN - EXP

    /// 情報デザイン: Trip span position for edge indicators
    var tripPosition: TripDayPosition?

    /// 情報デザイン: Pre-computed holiday info for DayDetailSheet
    /// Avoids accessing HolidayManager computed properties during sheet presentation
    var holidayName: String?
    var holidaySymbolName: String?

    /// 情報デザイン: Actual entry data for DayDetailSheet previews
    var observanceNames: [String] = []
    var eventNames: [String] = []
    var birthdayNames: [String] = []
    var noteContent: String?
    var tripDestination: String?
    var expenseAmount: Double?

    static let empty = DayDataCheck()
}

extension CalendarGridView {

    // 情報デザイン: Bento grid dimensions
    private var rowHeight: CGFloat { 48 }
    private var headerHeight: CGFloat { 28 }
    private var wallWidth: CGFloat { 1.5 }  // Vertical wall between compartments
    private var dividerWidth: CGFloat { 1.5 }  // Horizontal divider between rows

    var body: some View {
        // 情報デザイン: TRUE BENTO with full-height column lines
        // Use GeometryReader + ZStack overlay for continuous vertical lines
        let edgeExtension = JohoDimensions.spacingSM

        return GeometryReader { geometry in
            ZStack {
                // CONTENT LAYER
                VStack(spacing: 0) {
                    // HEADER ROW
                    bentoHeaderRow

                    // Horizontal divider after header
                    Rectangle()
                        .fill(colors.border)
                        .frame(height: dividerWidth)
                        .padding(.horizontal, -edgeExtension)

                    // WEEK ROWS
                    ForEach(Array(month.weeks.enumerated()), id: \.element.id) { index, week in
                        bentoWeekRow(week)

                        // Horizontal divider between weeks (not after last)
                        if index < month.weeks.count - 1 {
                            Rectangle()
                                .fill(colors.border.opacity(0.4))
                                .frame(height: dividerWidth)
                                .padding(.horizontal, -edgeExtension)
                        }
                    }
                }

                // VERTICAL LINES OVERLAY - continuous top to bottom
                HStack(spacing: 0) {
                    // Week column width + wall
                    Color.clear
                        .frame(width: weekColumnWidth)
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: wallWidth)
                        .padding(.vertical, -edgeExtension)  // Extend to edges

                    // Day columns with dividers between them
                    ForEach(0..<7, id: \.self) { index in
                        Color.clear
                            .frame(maxWidth: .infinity)
                        if index < 6 {
                            Rectangle()
                                .fill(colors.border.opacity(0.25))
                                .frame(width: dividerWidth)
                                .padding(.vertical, -edgeExtension)
                        }
                    }
                }
            }
        }
        .frame(height: headerHeight + (rowHeight * CGFloat(month.weeks.count)) + (dividerWidth * CGFloat(month.weeks.count)))
    }

    // MARK: - Bento Header Row

    private var bentoHeaderRow: some View {
        HStack(spacing: 0) {
            // LEFT COMPARTMENT: Week column header
            Text("W")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(colors.secondary)
                .frame(width: weekColumnWidth, height: headerHeight)

            // VERTICAL WALL (1.5pt) between week numbers and days
            Rectangle()
                .fill(colors.border)
                .frame(width: wallWidth)

            // RIGHT COMPARTMENT: Day headers
            // 情報デザイン: Saturday = Blue (stark), Sunday = Red (alert/rest)
            ForEach(0..<7, id: \.self) { index in
                let dayColor: Color = {
                    switch index {
                    case 5: return JohoColors.tripBlue   // Saturday = Blue (stark)
                    case 6: return JohoColors.red        // Sunday = Red
                    default: return colors.primary       // Mon-Fri = default
                    }
                }()

                Text(weekdaySymbol(for: index).uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(dayColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: headerHeight)
            }
        }
    }

    // MARK: - Bento Week Row (ONE horizontal compartment)

    private func bentoWeekRow(_ week: CalendarWeek) -> some View {
        HStack(spacing: 0) {
            // LEFT COMPARTMENT: Week number
            bentoCellWeekNumber(week)

            // VERTICAL WALL (1.5pt)
            Rectangle()
                .fill(colors.border)
                .frame(width: wallWidth)

            // RIGHT COMPARTMENT: Days (NO individual borders - just text)
            ForEach(week.days, id: \.id) { day in
                bentoCellDay(day)
            }
        }
        .frame(height: rowHeight)
    }

    // MARK: - Bento Cell: Week Number (NO individual border)

    private func bentoCellWeekNumber(_ week: CalendarWeek) -> some View {
        let isCurrentWeek = week.isCurrentWeek
        let isSelected = selectedWeek?.id == week.id

        return Button {
            onWeekTap(week)
            HapticManager.impact(.light)
        } label: {
            // 情報デザイン: Week number PINNED at fixed position
            // CURRENT week = filled black circle (always shows which week we're in)
            // SELECTED week (not current) = outline only
            ZStack {
                ZStack {
                    if isCurrentWeek {
                        // Current week: filled black circle
                        Circle()
                            .fill(colors.primary)
                            .frame(width: 28, height: 28)
                    } else if isSelected {
                        // Selected but not current: outline only
                        Circle()
                            .stroke(colors.primary, lineWidth: 2)
                            .frame(width: 28, height: 28)
                    }

                    Text("\(week.weekNumber)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(isCurrentWeek ? colors.primaryInverted : colors.primary)
                        .monospacedDigit()
                }
                .frame(height: 28)
                .padding(.top, 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: weekColumnWidth, height: rowHeight)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bento Cell: Day (NO individual border - just text + dots)

    private func bentoCellDay(_ day: CalendarDay) -> some View {
        let isSelected = selectedDay?.id == day.id
        let dataCheck = hasDataForDay?(day.date)

        return Button {
            onDayTap(day)
            HapticManager.impact(.light)
        } label: {
            // 情報デザイン: Day cell with ABSOLUTE positioning
            // Number PINNED at top, dots PINNED at bottom - no flexible spacers
            ZStack {
                // Day number PINNED at top
                ZStack {
                    // Today = orange pill, Selected = inverted pill
                    if day.isToday {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(JohoColors.todayOrange)
                            .frame(width: 32, height: 28)
                    } else if isSelected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(colors.surfaceInverted)
                            .frame(width: 32, height: 28)
                    }

                    Text("\(day.dayNumber)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(dayTextColor(for: day, isSelected: isSelected, dataCheck: dataCheck))
                        .monospacedDigit()
                }
                .frame(height: 28)
                .padding(.top, 6)  // Fixed 6pt from top
                .frame(maxHeight: .infinity, alignment: .top)

                // Dots PINNED at bottom
                priorityIndicators(for: day, dataCheck: dataCheck)
                    .frame(height: 10)
                    .padding(.bottom, 4)  // Fixed 4pt from bottom
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity)
            .frame(height: rowHeight)
            .opacity(day.isInCurrentMonth ? 1.0 : 0.35)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    HapticManager.impact(.medium)
                    onDayLongPress?(day)
                }
        )
    }

    // MARK: - Trip Span Indicator (情報デザイン)

    /// Renders trip span bar at bottom of day cell
    /// - Start: rounded left edge, extends to right
    /// - Middle: full width bar
    /// - End: rounded right edge, extends to left
    /// - Single: no bar (just regular indicator)
    @ViewBuilder
    private func tripSpanIndicator(position: TripDayPosition, isToday: Bool) -> some View {
        let tripColor = JohoColors.cyan
        let barHeight: CGFloat = 4

        VStack {
            Spacer()

            switch position {
            case .single:
                // Single day trips show no span bar (handled by regular indicators)
                EmptyView()

            case .start:
                // Start: rounded left, flat right (extends beyond cell)
                HStack(spacing: 0) {
                    Capsule()
                        .fill(tripColor)
                        .frame(height: barHeight)
                }
                .padding(.leading, 4)
                .padding(.trailing, -4) // Extend beyond cell edge

            case .middle:
                // Middle: flat edges, full width
                Rectangle()
                    .fill(tripColor)
                    .frame(height: barHeight)
                    .padding(.horizontal, -4) // Extend beyond cell edges

            case .end:
                // End: flat left, rounded right
                HStack(spacing: 0) {
                    Capsule()
                        .fill(tripColor)
                        .frame(height: barHeight)
                }
                .padding(.trailing, 4)
                .padding(.leading, -4) // Extend beyond cell edge
            }
        }
        .padding(.bottom, 2)
    }

    // Cell background following Joho style
    // Light mode: white cells, Dark mode: black cells
    private func cellBackground(for day: CalendarDay, isSelected: Bool) -> Color {
        // Today = bright orange background (distinct from yellow memos)
        if day.isToday {
            return JohoColors.todayOrange
        }
        // Selected = inverted from default (black in light, white in dark)
        if isSelected {
            return colors.surfaceInverted
        }
        // Default = surface color (white in light, black in dark)
        return colors.surface
    }

    // Text color following Joho contrast rules
    // 情報デザイン: Weekend/Holiday coloring for semantic meaning
    // - Sunday = Red (rest day)
    // - Saturday = Blue/Cyan (weekend)
    // - Holiday = Red (day off, like Sunday)
    // - Observance = Blue/Cyan (special but not holiday)
    private func dayTextColor(for day: CalendarDay, isSelected: Bool, dataCheck: DayDataCheck?) -> Color {
        // Today = white text on orange background for contrast
        if day.isToday {
            return .white
        }
        // Selected = inverted text color
        if isSelected {
            return colors.primaryInverted
        }

        // Check for holiday first (red - day off)
        if day.isHoliday || dataCheck?.hasHoliday == true {
            return JohoColors.red
        }

        // Check for observance (blue - special but not holiday)
        if dataCheck?.hasObservance == true {
            return JohoColors.tripBlue
        }

        // Weekend colors based on day of week
        let calendar = Calendar.iso8601
        let weekday = calendar.component(.weekday, from: day.date)
        // ISO weekday: 1 = Sunday, 7 = Saturday
        if weekday == 1 { // Sunday
            return JohoColors.red
        }
        if weekday == 7 { // Saturday
            return JohoColors.tripBlue
        }

        // Default = primary color (black in light, white in dark)
        return colors.primary
    }

    // Border color for day cells
    private func cellBorderColor(for day: CalendarDay, isSelected: Bool) -> Color {
        // Today = border color (on yellow background)
        if day.isToday {
            return colors.border
        }
        // Selected = inverted border color
        if isSelected {
            return colors.primaryInverted
        }
        // Default = border color (black in light, white in dark)
        return colors.border
    }

    // MARK: - Priority Indicators (情報デザイン)

    /// Indicator info with icon and color for consistency across app
    private struct IndicatorInfo: Hashable {
        let icon: String
        let color: Color

        func hash(into hasher: inout Hasher) {
            hasher.combine(icon)
        }

        static func == (lhs: IndicatorInfo, rhs: IndicatorInfo) -> Bool {
            lhs.icon == rhs.icon
        }
    }

    /// Returns 3 placeholder dots - filled with color when data exists
    /// 情報デザイン: Consistent visual weight across all cells
    /// Position 1: Holiday (Red), Position 2: Observance (Blue), Position 3: Memo (Green)
    /// Placeholders are almost invisible to avoid visual noise
    @ViewBuilder
    private func priorityIndicators(for day: CalendarDay, dataCheck: DayDataCheck?) -> some View {
        let hasHoliday = day.isHoliday || dataCheck?.hasHoliday == true
        let hasObservance = dataCheck?.hasObservance == true
        let hasMemo = dataCheck?.hasNote == true ||
                      dataCheck?.hasExpense == true ||
                      dataCheck?.hasTrip == true ||
                      dataCheck?.hasBirthday == true ||
                      dataCheck?.hasEvent == true

        HStack(spacing: 3) {
            // Position 1: Holiday (Red) - colored or invisible placeholder
            Circle()
                .fill(hasHoliday ? CategoryColorSettings.shared.color(for: .holiday) : Color.clear)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(hasHoliday ? colors.border.opacity(0.8) : Color.clear, lineWidth: 0.5)
                )

            // Position 2: Observance (Blue) - colored or invisible placeholder
            Circle()
                .fill(hasObservance ? CategoryColorSettings.shared.color(for: .observance) : Color.clear)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(hasObservance ? colors.border.opacity(0.8) : Color.clear, lineWidth: 0.5)
                )

            // Position 3: Memo (Green) - colored or invisible placeholder
            Circle()
                .fill(hasMemo ? CategoryColorSettings.shared.color(for: .memo) : Color.clear)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(hasMemo ? colors.border.opacity(0.8) : Color.clear, lineWidth: 0.5)
                )
        }
        .frame(height: 10)
    }

    /// 情報デザイン: Collects indicators using unified 3-category system
    /// Categories: Holiday (Red), Observance (Blue), Memo (Yellow)
    private func collectIndicators(for day: CalendarDay, dataCheck: DayDataCheck?) -> [IndicatorInfo] {
        var indicators: [IndicatorInfo] = []

        // 1. HOLIDAY (Red) - Bank holidays only (day off, like Sunday)
        if day.isHoliday || dataCheck?.hasHoliday == true {
            indicators.append(IndicatorInfo(icon: "star.fill", color: JohoColors.red))
        }

        // 2. OBSERVANCE (Blue) - Cultural observances (special but not holiday)
        if dataCheck?.hasObservance == true {
            indicators.append(IndicatorInfo(icon: "sparkles", color: JohoColors.tripBlue))
        }

        // 3. MEMO (Green) - All memos: notes, expenses, trips, birthdays
        // 情報デザイン: Stark green for readability
        let hasMemo = dataCheck?.hasNote == true ||
                      dataCheck?.hasExpense == true ||
                      dataCheck?.hasTrip == true ||
                      dataCheck?.hasBirthday == true ||
                      dataCheck?.hasEvent == true
        if hasMemo {
            indicators.append(IndicatorInfo(icon: "note.text", color: JohoColors.green))
        }

        return indicators
    }

    // MARK: - Lunar Calendar View (Âm Lịch)

    /// Displays lunar date below Gregorian day number
    /// - Special highlighting for Mùng 1 (1st) and Rằm (15th)
    @ViewBuilder
    private func lunarDateView(for date: Date, isToday: Bool, isSelected: Bool) -> some View {
        let lunar = lunarService.lunarDate(from: date)
        let isFirstDay = lunar.day == 1
        let isFullMoon = lunar.day == 15

        // Format: "1/M" for first day showing month, or just day number
        let displayText = isFirstDay ? "\(lunar.day)/\(lunar.month)" : "\(lunar.day)"

        // Color: Red for Mùng 1, Pink for Rằm (celebration), subtle otherwise
        let textColor: Color = {
            if isFirstDay {
                return JohoColors.red
            } else if isFullMoon {
                return JohoColors.pink
            } else if isToday {
                return colors.primary.opacity(0.6)
            } else if isSelected {
                return colors.primaryInverted.opacity(0.7)
            } else {
                return colors.primary.opacity(0.5)
            }
        }()

        Text(displayText)
            .font(.system(size: 8, weight: isFirstDay || isFullMoon ? .bold : .medium, design: .rounded))
            .foregroundStyle(textColor)
            .monospacedDigit()
    }

    // MARK: - Helper Methods

    private func weekdaySymbol(for index: Int) -> String {
        let symbols = Calendar.iso8601.veryShortWeekdaySymbols
        // ISO 8601: Monday = 0, Sunday = 6
        // Calendar weekday symbols: Sunday = 0, Monday = 1
        let calendarIndex = index == 6 ? 0 : index + 1
        return symbols[calendarIndex]
    }

    private func weekdayName(for index: Int) -> String {
        let names = Calendar.iso8601.weekdaySymbols
        // ISO 8601: Monday = 0, Sunday = 6
        // Calendar weekday symbols: Sunday = 0, Monday = 1
        let calendarIndex = index == 6 ? 0 : index + 1
        return names[calendarIndex]
    }

    private func accessibilityLabel(for day: CalendarDay) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var label = formatter.string(from: day.date)
        if day.isToday { label += ", today" }
        if let holidayName = day.holidayName { label += ", \(holidayName)" }
        return label
    }

    // MARK: - Layout Constants

    // 情報デザイン: Unified sizing across all devices (iPhone golden standard)
    // Week column narrower to give more space to day columns
    private var weekColumnWidth: CGFloat { 32 }
    private var cellSize: CGFloat { 52 }  // 情報デザイン: Slightly taller for better readability

    private func color(for colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        default: return .secondary
        }
    }
}

// MARK: - Preview

struct CalendarGridView_Preview: View {
    var body: some View {
        CalendarGridView(
            month: CalendarMonth.current(),
            selectedWeek: nil,
            selectedDay: nil,
            onDayTap: { _ in },
            onWeekTap: { _ in },
            onCalendarIconTap: { }
        )
        .padding()
    }
}

#Preview("Calendar Grid") {
    CalendarGridView_Preview()
}
