//
//  CalendarGridView.swift
//  Vecka
//
//  Elegant borderless calendar grid with floating dates
//  Dark slate design language - negative space is the hero
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
    let hasDataForDay: ((Date) -> (hasNotes: Bool, hasExpenses: Bool, hasTrips: Bool))?
    // MARK: - Weather parameters (Disabled)
    // let showWeather: Bool
    // let weatherData: [Date: DayWeather]

    init(
        month: CalendarMonth,
        selectedWeek: CalendarWeek?,
        selectedDay: CalendarDay?,
        onDayTap: @escaping (CalendarDay) -> Void,
        onWeekTap: @escaping (CalendarWeek) -> Void,
        hasDataForDay: ((Date) -> (hasNotes: Bool, hasExpenses: Bool, hasTrips: Bool))? = nil
        // Weather parameters disabled
        // showWeather: Bool = false,
        // weatherData: [Date: DayWeather] = [:]
    ) {
        self.month = month
        self.selectedWeek = selectedWeek
        self.selectedDay = selectedDay
        self.onDayTap = onDayTap
        self.onWeekTap = onWeekTap
        self.hasDataForDay = hasDataForDay
        // self.showWeather = showWeather
        // self.weatherData = weatherData
    }

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    // HIG: 8 columns (1 for week number + 7 days)
    private var columns: [GridItem] {
        [
            GridItem(.fixed(weekColumnWidth), spacing: 0), // Week Number Column
            GridItem(.flexible(), spacing: 0),             // Mon
            GridItem(.flexible(), spacing: 0),             // Tue
            GridItem(.flexible(), spacing: 0),             // Wed
            GridItem(.flexible(), spacing: 0),             // Thu
            GridItem(.flexible(), spacing: 0),             // Fri
            GridItem(.flexible(), spacing: 0),             // Sat
            GridItem(.flexible(), spacing: 0)              // Sun
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Calendar grid with subtle squircle cells
            LazyVGrid(columns: columns, spacing: 4) {
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
            .padding(.horizontal, Spacing.extraSmall)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Header Row

    @ViewBuilder
    private var headerRow: some View {
        // Week column header
        Text("W")
            .font(.caption.weight(.semibold))
            .foregroundStyle(SlateColors.tertiaryText)
            .frame(height: 32)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(Localization.weekColumnHeader)

        // Day Headers (MON-SUN)
        ForEach(0..<7, id: \.self) { index in
            weekdayHeaderCell(for: index)
        }
    }

    private func weekdayHeaderCell(for index: Int) -> some View {
        let isSunday = index == 6

        return Text(weekdaySymbol(for: index))
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSunday ? SlateColors.sundayBlue : SlateColors.secondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .accessibilityLabel(weekdayName(for: index))
    }

    // MARK: - Cells

    private func weekNumberCell(_ week: CalendarWeek) -> some View {
        let isSelected = selectedWeek?.id == week.id

        return Button(action: {
            onWeekTap(week)
            HapticManager.impact(.light)
        }) {
            ZStack {
                // Background squircle
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? SlateColors.selectionHighlight : SlateColors.mediumSlate.opacity(0.3))

                Text("\(week.weekNumber)")
                    .font(.system(size: isPad ? 13 : 11, weight: .medium))
                    .foregroundStyle(week.isCurrentWeek ? SlateColors.sidebarActiveBar : SlateColors.tertiaryText)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .frame(height: cellSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Week \(week.weekNumber)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func dayCell(_ day: CalendarDay) -> some View {
        let isSaturday = Calendar.iso8601.component(.weekday, from: day.date) == 7
        let isSunday = Calendar.iso8601.component(.weekday, from: day.date) == 1
        let isSelected = selectedDay?.id == day.id

        return Button {
            onDayTap(day)
            HapticManager.impact(.light)
        } label: {
            ZStack {
                // Base cell background - subtle squircle for visual structure
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(cellBackground(for: day, isSelected: isSelected))

                // Content - just the number, clean and uniform
                Text("\(day.dayNumber)")
                    .font(.system(size: isPad ? 17 : 15, weight: cellFontWeight(for: day, isSelected: isSelected)))
                    .foregroundStyle(dayTextColor(for: day, isSaturday: isSaturday, isSunday: isSunday))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .frame(height: cellSize)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: day))
        .accessibilityHint((day.noteColor != nil || day.holidayName != nil) ? "Has details" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // Cell background based on state
    private func cellBackground(for day: CalendarDay, isSelected: Bool) -> Color {
        if day.isToday {
            return SlateColors.todayHighlight
        }
        if isSelected {
            return SlateColors.selectionHighlight
        }
        if day.isHoliday {
            return Color.red.opacity(0.15)
        }
        if day.isInCurrentMonth {
            return SlateColors.mediumSlate.opacity(0.5)
        }
        // Out of month - more subtle
        return SlateColors.mediumSlate.opacity(0.2)
    }

    // Font weight based on state
    private func cellFontWeight(for day: CalendarDay, isSelected: Bool) -> Font.Weight {
        if day.isToday || isSelected {
            return .bold
        }
        if day.isHoliday {
            return .semibold
        }
        return .regular
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

    private func dayTextColor(for day: CalendarDay, isSaturday: Bool, isSunday: Bool) -> Color {
        // Out of month days are muted
        if !day.isInCurrentMonth {
            return SlateColors.mutedText
        }
        // Holidays are red
        if day.isHoliday {
            return .red
        }
        // Sunday is blue (not red!)
        if isSunday {
            return SlateColors.sundayBlue
        }
        // Saturday is normal (not blue!)
        // Today and all other days use primary text
        return SlateColors.primaryText
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
        isPad ? 50 : 44
    }

    private var cellSize: CGFloat {
        isPad ? 60 : 44
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
