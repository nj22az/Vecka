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

/// Tracks which special day types exist for a calendar day
struct DayDataCheck {
    var hasHoliday: Bool = false      // RED - HOL
    var hasObservance: Bool = false   // ORANGE - OBS
    var hasEvent: Bool = false        // PURPLE - EVT
    var hasBirthday: Bool = false     // PINK - BDY (from Contacts)
    var hasNote: Bool = false         // YELLOW - NTE
    var hasTrip: Bool = false         // BLUE - TRP
    var hasExpense: Bool = false      // GREEN - EXP

    static let empty = DayDataCheck()
}

extension CalendarGridView {

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

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
        // Week column header - black background with white text
        Text("W")
            .font(JohoFont.label)
            .foregroundStyle(JohoColors.white)
            .frame(height: 28)
            .frame(maxWidth: .infinity)
            .background(JohoColors.black)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .accessibilityLabel(Localization.weekColumnHeader)

        // Day Headers (MON-SUN) - UPPERCASE, bold, rounded
        ForEach(0..<7, id: \.self) { index in
            weekdayHeaderCell(for: index)
        }
    }

    private func weekdayHeaderCell(for index: Int) -> some View {
        let isWeekend = index >= 5 // Saturday (5) and Sunday (6)
        return Text(weekdaySymbol(for: index).uppercased())
            .font(JohoFont.label)
            .foregroundStyle(JohoColors.black)
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(isWeekend ? JohoColors.pink.opacity(0.3) : Color(hex: "F0F0F0"))
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin)
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
                    // Background - black squircle like JohoWeekBadge
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .fill(JohoColors.black)

                    // Border - white when selected/current, dark otherwise
                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                        .stroke(
                            (week.isCurrentWeek || isSelected) ? JohoColors.white : JohoColors.black.opacity(0.3),
                            lineWidth: (week.isCurrentWeek || isSelected) ? JohoDimensions.borderMedium : JohoDimensions.borderThin
                        )

                    // Week number
                    Text("\(week.weekNumber)")
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.white)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .frame(height: cellSize)

                // Subtle vertical separator after week number
                Rectangle()
                    .fill(JohoColors.white.opacity(0.2))
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

                // Border - thick black border, extra thick for today/selected
                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                    .stroke(
                        JohoColors.black,
                        lineWidth: (day.isToday || isSelected) ? JohoDimensions.borderThick : JohoDimensions.borderThin
                    )

                // Day number - bold rounded font
                VStack(spacing: 2) {
                    Text("\(day.dayNumber)")
                        .font(isPad ? JohoFont.headline : JohoFont.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(dayTextColor(for: day, isSelected: isSelected))
                        .monospacedDigit()

                    // 情報デザイン: Priority-filtered indicators (max 3 + overflow)
                    // Priority: HOL > BDY > OBS > EVT > NTE > TRP > EXP
                    priorityIndicators(for: day, dataCheck: dataCheck)
                }
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

    // Cell background following Joho style
    private func cellBackground(for day: CalendarDay, isSelected: Bool) -> Color {
        // Selected = black background (white text)
        if isSelected {
            return JohoColors.black
        }
        // Today = yellow background (black text)
        if day.isToday {
            return JohoColors.yellow
        }
        // Default = white background (black text)
        return JohoColors.white
    }

    // Text color following Joho contrast rules
    private func dayTextColor(for day: CalendarDay, isSelected: Bool) -> Color {
        // Selected day = white text on black background
        if isSelected {
            return JohoColors.white
        }
        // All other days = black text for maximum contrast
        return JohoColors.black
    }

    // MARK: - Priority Indicators (情報デザイン)

    /// Returns max 3 indicators + overflow badge based on priority
    /// Priority order: HOL > BDY > OBS > EVT > NTE > TRP > EXP
    @ViewBuilder
    private func priorityIndicators(for day: CalendarDay, dataCheck: DayDataCheck?) -> some View {
        let indicators = collectIndicators(for: day, dataCheck: dataCheck)
        let displayIndicators = Array(indicators.prefix(3))
        let overflow = indicators.count - 3

        HStack(spacing: 3) {
            ForEach(displayIndicators, id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            }

            // Overflow badge when >3 indicators
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: 6, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 1)
                    .background(JohoColors.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(JohoColors.black, lineWidth: 0.5))
            }
        }
        .frame(height: 8)
    }

    /// Collects indicator colors in priority order
    /// Priority: HOL > BDY > OBS > EVT > NTE > TRP > EXP
    private func collectIndicators(for day: CalendarDay, dataCheck: DayDataCheck?) -> [Color] {
        var indicators: [Color] = []

        // 1. Holiday - RED (highest priority)
        if day.isHoliday || dataCheck?.hasHoliday == true {
            indicators.append(JohoColors.red)
        }

        // 2. Birthday - PINK
        if dataCheck?.hasBirthday == true {
            indicators.append(JohoColors.pink)
        }

        // 3. Observance - ORANGE
        if dataCheck?.hasObservance == true {
            indicators.append(JohoColors.orange)
        }

        // 4. Event - PURPLE
        if dataCheck?.hasEvent == true {
            indicators.append(JohoColors.eventPurple)
        }

        // 5. Note - YELLOW
        if dataCheck?.hasNote == true {
            indicators.append(JohoColors.yellow)
        }

        // 6. Trip - BLUE
        if dataCheck?.hasTrip == true {
            indicators.append(JohoColors.tripBlue)
        }

        // 7. Expense - GREEN (lowest priority)
        if dataCheck?.hasExpense == true {
            indicators.append(JohoColors.green)
        }

        return indicators
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

    private var weekColumnWidth: CGFloat {
        isPad ? 54 : 44
    }

    private var cellSize: CGFloat {
        isPad ? 64 : 48
    }

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
