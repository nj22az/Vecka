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

    init(
        month: CalendarMonth,
        selectedWeek: CalendarWeek?,
        selectedDay: CalendarDay?,
        onDayTap: @escaping (CalendarDay) -> Void,
        onWeekTap: @escaping (CalendarWeek) -> Void,
        onDayLongPress: ((CalendarDay) -> Void)? = nil,
        hasDataForDay: ((Date) -> DayDataCheck)? = nil
    ) {
        self.month = month
        self.selectedWeek = selectedWeek
        self.selectedDay = selectedDay
        self.onDayTap = onDayTap
        self.onWeekTap = onWeekTap
        self.onDayLongPress = onDayLongPress
        self.hasDataForDay = hasDataForDay
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

    static let empty = DayDataCheck()
}

extension CalendarGridView {

    // HIG: 8 columns (1 for week number + 7 days)
    private var columns: [GridItem] {
        [
            GridItem(.fixed(weekColumnWidth), spacing: JohoDimensions.spacingXS), // Week Number Column
            GridItem(.flexible(), spacing: JohoDimensions.spacingXS),             // Mon
            GridItem(.flexible(), spacing: JohoDimensions.spacingXS),             // Tue
            GridItem(.flexible(), spacing: JohoDimensions.spacingXS),             // Wed
            GridItem(.flexible(), spacing: JohoDimensions.spacingXS),             // Thu
            GridItem(.flexible(), spacing: JohoDimensions.spacingXS),             // Fri
            GridItem(.flexible(), spacing: JohoDimensions.spacingXS),             // Sat
            GridItem(.flexible(), spacing: JohoDimensions.spacingXS)              // Sun
        ]
    }

    var body: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            // Calendar grid with thick-bordered cells
            LazyVGrid(columns: columns, spacing: JohoDimensions.spacingXS) {
                // Header Row
                headerRow

                // Weeks and Days
                ForEach(month.weeks) { week in
                    // Week Number Cell
                    weekNumberCell(week)

                    // Day Cells
                    ForEach(week.days) { day in
                        dayCell(day)
                    }
                }
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .padding(.vertical, JohoDimensions.spacingSM)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Header Row

    @ViewBuilder
    private var headerRow: some View {
        // Week column header - inverted background (black in light, white in dark)
        // 情報デザイン: Show moon icon when lunar calendar is active
        HStack(spacing: 2) {
            Text("W")
                .font(JohoFont.label)
                .foregroundStyle(colors.primaryInverted)

            if showLunarCalendar {
                Image(systemName: "moon.fill")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.yellow)
            }
        }
        .frame(height: 28)
        .frame(maxWidth: .infinity)
        .background(colors.surfaceInverted)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .accessibilityLabel(showLunarCalendar ? "Week, Lunar calendar active" : Localization.weekColumnHeader)

        // Day Headers (MON-SUN) - UPPERCASE, bold, rounded
        ForEach(0..<7, id: \.self) { index in
            weekdayHeaderCell(for: index)
        }
    }

    private func weekdayHeaderCell(for index: Int) -> some View {
        let isWeekend = index >= 5 // Saturday (5) and Sunday (6)
        // Dark mode: Slightly lighter background for header contrast
        let weekdayBg = colorMode == .dark ? Color(hex: "2A2A2A") : Color(hex: "F0F0F0")
        let weekendBg = isWeekend ? JohoColors.pink.opacity(colorMode == .dark ? 0.4 : 0.3) : weekdayBg

        return Text(weekdaySymbol(for: index).uppercased())
            .font(JohoFont.label)
            .foregroundStyle(colors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(weekendBg)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(colors.border, lineWidth: JohoDimensions.borderThin)
            )
            .accessibilityLabel(weekdayName(for: index))
    }

    // MARK: - Cells

    private func weekNumberCell(_ week: CalendarWeek) -> some View {
        let isSelected = selectedWeek?.id == week.id

        return Button(action: {
            onWeekTap(week)
            HapticManager.impact(.light)
        }) {
            HStack(spacing: 0) {
                ZStack {
                    // Background - inverted squircle (black in light, white in dark)
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .fill(colors.surfaceInverted)

                    // Border - highlight when selected/current
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(
                            (week.isCurrentWeek || isSelected) ? colors.primaryInverted : colors.surfaceInverted.opacity(0.3),
                            lineWidth: (week.isCurrentWeek || isSelected) ? JohoDimensions.borderMedium : JohoDimensions.borderThin
                        )

                    // Week number
                    Text("\(week.weekNumber)")
                        .font(JohoFont.headline)
                        .foregroundStyle(colors.primaryInverted)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .frame(height: cellSize)

                // Subtle vertical separator after week number
                Rectangle()
                    .fill(colors.primaryInverted.opacity(0.2))
                    .frame(width: 1)
                    .frame(height: cellSize - 8)
                    .padding(.leading, JohoDimensions.spacingXS)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Week \(week.weekNumber)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func dayCell(_ day: CalendarDay) -> some View {
        let isSelected = selectedDay?.id == day.id
        let dataCheck = hasDataForDay?(day.date)

        return Button {
            onDayTap(day)
            HapticManager.impact(.light)
        } label: {
            ZStack {
                // Base cell background following JohoDayCell pattern
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .fill(cellBackground(for: day, isSelected: isSelected))

                // Border - dynamic color, extra thick for today/selected
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(
                        cellBorderColor(for: day, isSelected: isSelected),
                        lineWidth: (day.isToday || isSelected) ? JohoDimensions.borderThick : JohoDimensions.borderThin
                    )

                // Day number - bold rounded font
                VStack(spacing: showLunarCalendar ? 0 : 2) {
                    Text("\(day.dayNumber)")
                        .font(showLunarCalendar ? JohoFont.label : JohoFont.subheadline) // Smaller when lunar shown
                        .fontWeight(.bold)
                        .foregroundStyle(dayTextColor(for: day, isSelected: isSelected))
                        .monospacedDigit()

                    // Lunar date (Âm Lịch) when enabled
                    if showLunarCalendar {
                        lunarDateView(for: day.date, isToday: day.isToday, isSelected: isSelected)
                    }

                    // 情報デザイン: Priority-filtered indicators (max 3 + overflow)
                    // Priority: HOL > BDY > OBS > EVT > NTE > TRP > EXP
                    priorityIndicators(for: day, dataCheck: dataCheck)
                }

                // 情報デザイン: Trip indicators shown as orbs only (no connecting lines)
                // The span bar was removed - too visually noisy, orbs communicate better
            }
            .frame(maxWidth: .infinity)
            .frame(height: cellSize)
            .contentShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .opacity(day.isInCurrentMonth ? 1.0 : 0.4) // Dim out-of-month days
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    HapticManager.impact(.medium)
                    onDayLongPress?(day)
                }
        )
        .accessibilityLabel(accessibilityLabel(for: day))
        .accessibilityHint((day.noteColor != nil || day.holidayName != nil) ? "Long press for details, tap to select" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Trip Span Indicator (情報デザイン)

    /// Renders trip span bar at bottom of day cell
    /// - Start: rounded left edge, extends to right
    /// - Middle: full width bar
    /// - End: rounded right edge, extends to left
    /// - Single: no bar (just regular indicator)
    @ViewBuilder
    private func tripSpanIndicator(position: TripDayPosition, isToday: Bool) -> some View {
        let tripColor = JohoColors.tripBlue
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
        // Today = yellow background (always - it's a semantic color)
        if day.isToday {
            return JohoColors.yellow
        }
        // Selected = inverted from default (black in light, white in dark)
        if isSelected {
            return colors.surfaceInverted
        }
        // Default = surface color (white in light, black in dark)
        return colors.surface
    }

    // Text color following Joho contrast rules
    private func dayTextColor(for day: CalendarDay, isSelected: Bool) -> Color {
        // Today = always black text (yellow background needs black for contrast)
        if day.isToday {
            return JohoColors.black
        }
        // Selected = inverted text color
        if isSelected {
            return colors.primaryInverted
        }
        // Default = primary color (black in light, white in dark)
        return colors.primary
    }

    // Border color for day cells
    private func cellBorderColor(for day: CalendarDay, isSelected: Bool) -> Color {
        // Today = black border (on yellow background)
        if day.isToday {
            return JohoColors.black
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

    /// Returns max 3 indicators + overflow badge based on priority
    /// Priority order: HOL > BDY > OBS > EVT > NTE > TRP > EXP
    /// Uses SF Symbol icons for consistency with Star page and Database
    @ViewBuilder
    private func priorityIndicators(for day: CalendarDay, dataCheck: DayDataCheck?) -> some View {
        let indicators = collectIndicators(for: day, dataCheck: dataCheck)
        let displayIndicators = Array(indicators.prefix(3))
        let overflow = indicators.count - 3

        HStack(spacing: 2) {
            ForEach(displayIndicators, id: \.self) { info in
                Image(systemName: info.icon)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(info.color)
            }

            // Overflow badge when >3 indicators
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: 6, weight: .black, design: .rounded))
                    .foregroundStyle(day.isToday ? JohoColors.black : colors.primary)
            }
        }
        .frame(height: 10)
    }

    /// Collects indicator info (icon + color) in priority order
    /// Priority: HOL > BDY > OBS > EVT > NTE > TRP > EXP
    /// Icons match SpecialDayType.defaultIcon for app-wide consistency
    private func collectIndicators(for day: CalendarDay, dataCheck: DayDataCheck?) -> [IndicatorInfo] {
        var indicators: [IndicatorInfo] = []

        // 1. Holiday - star.fill RED (highest priority)
        if day.isHoliday || dataCheck?.hasHoliday == true {
            indicators.append(IndicatorInfo(icon: "star.fill", color: JohoColors.red))
        }

        // 2. Birthday - birthday.cake.fill PINK
        if dataCheck?.hasBirthday == true {
            indicators.append(IndicatorInfo(icon: "birthday.cake.fill", color: JohoColors.pink))
        }

        // 3. Observance - sparkles ORANGE
        if dataCheck?.hasObservance == true {
            indicators.append(IndicatorInfo(icon: "sparkles", color: JohoColors.orange))
        }

        // 4. Event - calendar.badge.clock PURPLE
        if dataCheck?.hasEvent == true {
            indicators.append(IndicatorInfo(icon: "calendar.badge.clock", color: JohoColors.eventPurple))
        }

        // 5. Note - note.text YELLOW
        if dataCheck?.hasNote == true {
            indicators.append(IndicatorInfo(icon: "note.text", color: JohoColors.yellow))
        }

        // 6. Trip - airplane BLUE
        if dataCheck?.hasTrip == true {
            indicators.append(IndicatorInfo(icon: "airplane", color: JohoColors.tripBlue))
        }

        // 7. Expense - dollarsign.circle.fill GREEN (lowest priority)
        if dataCheck?.hasExpense == true {
            indicators.append(IndicatorInfo(icon: "dollarsign.circle.fill", color: JohoColors.green))
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

        // Color: Red for Mùng 1, Orange for Rằm, subtle otherwise
        let textColor: Color = {
            if isFirstDay {
                return JohoColors.red
            } else if isFullMoon {
                return JohoColors.orange
            } else if isToday {
                return JohoColors.black.opacity(0.6)
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
    private var weekColumnWidth: CGFloat { 44 }
    private var cellSize: CGFloat { 48 }

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
            onWeekTap: { _ in }
        )
        .padding()
    }
}

#Preview("Calendar Grid") {
    CalendarGridView_Preview()
}
