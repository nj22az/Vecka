//
//  JohoCalendarWidgets.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Authentic Japanese Packaging Style
//  Inspired by Muhi, Rohto, and classic Japanese OTC medicine packaging
//

import SwiftUI

// MARK: - Today Banner (今日のバナー)
// Prominent banner showing today's date - goes at the VERY TOP

struct JohoTodayBanner: View {
    let date: Date
    var weekNumber: Int
    var onTapToday: (() -> Void)? = nil
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var dayNumber: Int {
        Calendar.iso8601.component(.day, from: date)
    }

    private var weekdayName: String {
        date.formatted(.dateTime.weekday(.wide)).uppercased()
    }

    private var monthName: String {
        date.formatted(.dateTime.month(.wide))
    }

    private var yearString: String {
        String(Calendar.iso8601.component(.year, from: date))
    }

    var body: some View {
        Button(action: { onTapToday?() }) {
            HStack(spacing: JohoDimensions.spacingMD) {
                // Large day number (always black on yellow)
                Text("\(dayNumber)")
                    .font(JohoFont.displayLarge)
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 72)

                // Vertical separator (always black on yellow)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 3, height: 56)

                // Date info (always black on yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text(weekdayName)
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)

                    Text("\(monthName) \(yearString)")
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black.opacity(JohoDimensions.opacityBold))
                }

                Spacer()

                // Week badge (inverted colors)
                VStack(spacing: 0) {
                    Text("WEEK")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(colors.primaryInverted.opacity(JohoDimensions.opacityDense))

                    Text("\(weekNumber)")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(colors.primaryInverted)
                }
                .frame(width: 56, height: 56)
                .background(colors.primary)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            }
            .padding(JohoDimensions.spacingMD)
            .background(JohoColors.yellow)  // Yellow is semantic color - always yellow
            .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick, borderColor: colors.border)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Today, \(weekdayName), \(monthName) \(dayNumber), \(yearString), Week \(weekNumber)")
        .accessibilityHint("Tap to jump to today")
    }
}

// MARK: - Month Selector (月選択)
// Compact month/year display with navigation arrows

struct JohoMonthSelector: View {
    let monthName: String
    let year: Int
    var onPrevious: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors based on color mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Previous month button (情報デザイン: Minimum 44pt touch target)
            Button(action: { onPrevious?() }) {
                Image(systemName: IconCatalog.chevronLeft)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .johoTouchTarget()
                    .background(colors.surface)
                    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
            }
            .buttonStyle(.plain)

            // Month/Year button
            Button(action: { onTap?() }) {
                HStack(spacing: 6) {
                    Text(monthName.uppercased())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .lineLimit(1)

                    Text(verbatim: "\(year)")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityBold))

                    Image(systemName: IconCatalog.chevronDown)
                        .font(JohoFont.labelBold)
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .background(colors.surface)
                .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
            }
            .buttonStyle(.plain)

            // Next month button (情報デザイン: Minimum 44pt touch target)
            Button(action: { onNext?() }) {
                Image(systemName: IconCatalog.chevronRight)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .johoTouchTarget()
                    .background(colors.surface)
                    .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Calendar Container (カレンダー枠)
// White container with thick black border for the entire calendar grid

struct JohoCalendarContainer<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        content
            .padding(JohoDimensions.spacingSM)
            .background(colors.surface)
            .johoBordered(cornerRadius: JohoDimensions.radiusLarge, borderWidth: JohoDimensions.borderThick, borderColor: colors.border)
    }
}

// MARK: - Weekday Header (曜日ヘッダー)
// Header row showing weekday abbreviations

struct JohoWeekdayHeader: View {
    let weekdays: [String] // ["M", "T", "W", "T", "F", "S", "S"]
    var showWeekColumn: Bool = true
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingXS) {
            // Week column header
            if showWeekColumn {
                Text("W")
                    .font(JohoFont.label)
                    .foregroundStyle(colors.primary)
                    .frame(width: 36, height: 28)
                    .background(colors.primary.opacity(JohoDimensions.opacitySubtle))
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
            }

            // Day headers
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(JohoFont.label)
                    .foregroundStyle(colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
            }
        }
    }
}

// MARK: - Week Number Cell (週番号セル)
// Tappable week number in calendar grid

struct JohoWeekNumberCell: View {
    let weekNumber: Int
    var isCurrentWeek: Bool = false
    var isSelected: Bool = false
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        ZStack {
            // Background
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .fill(colors.primary)

            // Border when current/selected
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(
                    (isCurrentWeek || isSelected) ? colors.primaryInverted : colors.primary.opacity(JohoDimensions.opacityMedium),
                    lineWidth: (isCurrentWeek || isSelected) ? JohoDimensions.borderMedium : JohoDimensions.borderThin
                )

            // Week number - smaller font for better padding with 2-digit numbers
            Text("\(weekNumber)")
                .font(JohoFont.bodySmall)
                .foregroundStyle(colors.primaryInverted)
                .monospacedDigit()
        }
        // 情報デザイン: Minimum 44pt touch target in both dimensions
        .frame(width: 44, height: 44)
    }
}

// MARK: - Calendar Day Cell (カレンダー日セル)
// Individual day cell for calendar grid with borders

struct JohoCalendarDayCell: View {
    let dayNumber: Int
    var isToday: Bool = false
    var isSelected: Bool = false
    var isInCurrentMonth: Bool = true
    var isHoliday: Bool = false
    var hasNotes: Bool = false
    var hasExpenses: Bool = false
    var hasTrips: Bool = false
    var hasEvents: Bool = false  // NEW: Generic events indicator
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        ZStack {
            // Background
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .fill(backgroundColor)

            // Border - ALL cells have borders
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(
                    colors.border,
                    lineWidth: (isToday || isSelected) ? JohoDimensions.borderThick : JohoDimensions.borderThin
                )

            // Content
            VStack(spacing: 2) {
                Text("\(dayNumber)")
                    .font(JohoFont.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(textColor)
                    .monospacedDigit()

                // Event indicators (6-color palette)
                // YELLOW=notes, CYAN=scheduled(trips+events), PINK=celebration, GREEN=money
                HStack(spacing: 2) {
                    if isHoliday {
                        Circle()
                            .fill(JohoColors.pink)      // CELEBRATION
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                    }
                    if hasNotes {
                        Circle()
                            .fill(JohoColors.yellow)    // NOW
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                    }
                    if hasExpenses {
                        Circle()
                            .fill(JohoColors.green)     // MONEY
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                    }
                    if hasTrips || hasEvents {
                        Circle()
                            .fill(JohoColors.cyan)      // SCHEDULED (unified)
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(colors.border, lineWidth: JohoDimensions.borderThin))
                    }
                }
                .frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .opacity(isInCurrentMonth ? 1.0 : JohoDimensions.opacityModerate)
    }

    private var backgroundColor: Color {
        if isSelected { return colors.primary }
        if isToday { return JohoColors.yellow }
        return colors.surface
    }

    private var textColor: Color {
        if isSelected { return colors.primaryInverted }
        if isToday { return JohoColors.black }  // Black on yellow is always readable
        return colors.primary
    }
}

// MARK: - Action Menu Button (メニューボタン)
// Circular action button for toolbar

struct JohoActionButton: View {
    let icon: String
    var size: CGFloat = 44
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
            .foregroundStyle(colors.primary)
            .frame(width: size, height: size)
            .background(colors.surface)
            .johoBordered(cornerRadius: size * 0.3, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
    }
}

// MARK: - Hotel Clock Widget (情報デザイン)

/// Prominent world clock display like hotel reception or airport wall
/// Used in the Onsen landing page Bento grid
struct HotelClockWidget: View {
    let clock: WorldClock
    var isLarge: Bool = false
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var timeSize: CGFloat { isLarge ? 48 : 32 }
    private var codeSize: CGFloat { isLarge ? 12 : 10 }

    var body: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            // City code pill
            Text(clock.cityCode)
                .font(.system(size: codeSize, weight: .black, design: .rounded))
                .foregroundStyle(colors.primaryInverted)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(colors.primary)
                .clipShape(Capsule())

            // Large time display
            Text(clock.formattedTime)
                .font(.system(size: timeSize, weight: .bold, design: .monospaced))
                .foregroundStyle(colors.primary)
                .monospacedDigit()

            // City name
            Text(clock.cityName.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityBold))

            // Offset badge + Day/Night
            HStack(spacing: 6) {
                // Offset
                Text(clock.offsetFromLocal)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        clock.offsetFromLocal == "LOCAL"
                            ? JohoColors.green
                            : colors.primary.opacity(JohoDimensions.opacityStrong)
                    )
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        clock.offsetFromLocal == "LOCAL"
                            ? JohoColors.green.opacity(JohoDimensions.opacityLight)
                            : colors.primary.opacity(JohoDimensions.opacityFaint)
                    )
                    .clipShape(Capsule())

                // Day/Night icon
                Image(systemName: clock.isDaytime ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(
                        clock.isDaytime
                            ? JohoColors.yellow
                            : colors.primary.opacity(JohoDimensions.opacityStrong)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium, borderColor: colors.border)
    }
}

// MARK: - Year Picker

/// 情報デザイン: Compact year stepper with chevron buttons
/// Reusable across Star Page, Calendar, Expenses, Countdowns, etc.
struct JohoYearPicker: View {
    @Binding var year: Int
    var minYear: Int = 1900
    var maxYear: Int = 2100

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: 4) {
            // Decrement button
            Button {
                if year > minYear {
                    withAnimation(.easeInOut(duration: 0.15)) { year -= 1 }
                    HapticManager.selection()
                }
            } label: {
                Image(systemName: IconCatalog.chevronLeft)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(year > minYear ? colors.primary : colors.primary.opacity(JohoDimensions.opacityMedium))
                    .frame(width: 24, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(year <= minYear)

            // Year text - tap to reset to current year
            let currentYear = Calendar.current.component(.year, from: Date())
            let isCurrentYear = year == currentYear

            Button {
                if !isCurrentYear {
                    withAnimation(.easeInOut(duration: 0.15)) { year = currentYear }
                    HapticManager.notification(.success)
                }
            } label: {
                Text(String(year))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isCurrentYear ? colors.primary : colors.primary.opacity(JohoDimensions.opacityBold))
                    .underline(!isCurrentYear, color: colors.primary.opacity(JohoDimensions.opacityMedium))
                    .fixedSize()
            }
            .buttonStyle(.plain)

            // Increment button
            Button {
                if year < maxYear {
                    withAnimation(.easeInOut(duration: 0.15)) { year += 1 }
                    HapticManager.selection()
                }
            } label: {
                Image(systemName: IconCatalog.chevronRight)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(year < maxYear ? colors.primary : colors.primary.opacity(JohoDimensions.opacityMedium))
                    .frame(width: 24, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(year >= maxYear)
        }
    }
}


// MARK: - JohoCalendarPicker (情報デザイン: Unified Date Picker)

/// A 情報デザイン compliant calendar picker matching the Calendar page design
/// Features: Week numbers, bordered cells, yellow today highlight, week selection
struct JohoCalendarPicker: View {
    @Binding var selectedDate: Date
    let accentColor: Color
    let onDone: () -> Void
    let onCancel: () -> Void

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    @State private var displayedMonth: Date

    init(selectedDate: Binding<Date>, accentColor: Color = JohoColors.pink, onDone: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self._selectedDate = selectedDate
        self.accentColor = accentColor
        self.onDone = onDone
        self.onCancel = onCancel
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue)
    }

    private let calendar = Calendar.iso8601
    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(spacing: 0) {
            // Header with buttons
            headerRow

            JohoDivider()

            // Month navigation
            monthNavigationRow

            JohoDivider(weight: 1.5)

            // Calendar grid
            calendarGrid
                .padding(JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: JohoDimensions.radiusLarge, style: .continuous)
                .stroke(colors.border, lineWidth: 3)
        )
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            Button {
                onCancel()
                HapticManager.selection()
            } label: {
                Text("CANCEL")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                            .stroke(colors.border, lineWidth: 1.5)
                    )
            }

            Spacer()

            Text("SELECT DATE")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(colors.primary)

            Spacer()

            Button {
                onDone()
                HapticManager.selection()
            } label: {
                Text("DONE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primaryInverted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                            .stroke(colors.border, lineWidth: 1.5)
                    )
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingMD)
    }

    // MARK: - Month Navigation

    private var monthNavigationRow: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
                HapticManager.selection()
            } label: {
                Image(systemName: IconCatalog.chevronLeft)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(monthYearString)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }
                HapticManager.selection()
            } label: {
                Image(systemName: IconCatalog.chevronRight)
                    .font(JohoFont.bodySmallBold)
                    .foregroundStyle(colors.primary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingXS)
    }

    private var monthYearString: String {
        DateFormatterCache.monthYear.string(from: displayedMonth).uppercased()
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let weeks = weeksInMonth()

        return VStack(spacing: JohoDimensions.spacingXS) {
            // Weekday header row
            HStack(spacing: JohoDimensions.spacingXS) {
                // Week column header
                Text("W")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primaryInverted)
                    .frame(width: 28, height: 28)
                    .background(colors.surfaceInverted)
                    .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous))

                // Day headers
                ForEach(0..<7, id: \.self) { index in
                    let isWeekend = index >= 5
                    Text(weekdays[index])
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(isWeekend ? accentColor.opacity(JohoDimensions.opacityMild) : colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous)
                                .stroke(colors.border, lineWidth: 1)
                        )
                }
            }

            // Week rows
            ForEach(weeks, id: \.self) { week in
                HStack(spacing: JohoDimensions.spacingXS) {
                    // Week number cell (tappable to select first day of week)
                    weekNumberCell(for: week)

                    // Day cells
                    ForEach(week, id: \.self) { day in
                        dayCell(for: day)
                    }
                }
            }
        }
    }

    private func weekNumberCell(for week: [Date]) -> some View {
        let weekNumber = calendar.component(.weekOfYear, from: week.first ?? Date())
        let firstDayOfWeek = week.first { calendar.component(.month, from: $0) == calendar.component(.month, from: displayedMonth) } ?? week.first ?? Date()

        return Button {
            selectedDate = firstDayOfWeek
            HapticManager.impact(.light)
        } label: {
            Text("\(weekNumber)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(colors.primaryInverted)
                .frame(width: 28, height: 40)
                .background(colors.surfaceInverted)
                .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func dayCell(for date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isCurrentMonth = calendar.component(.month, from: date) == calendar.component(.month, from: displayedMonth)
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

        return Button {
            selectedDate = date
            HapticManager.impact(.light)
        } label: {
            Text("\(day)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(dayTextColor(isToday: isToday, isSelected: isSelected, isCurrentMonth: isCurrentMonth))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(dayBackground(isToday: isToday, isSelected: isSelected))
                .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous)
                        .stroke(
                            dayBorderColor(isToday: isToday, isSelected: isSelected),
                            lineWidth: (isToday || isSelected) ? 2 : 1
                        )
                )
                .opacity(isCurrentMonth ? 1.0 : JohoDimensions.opacityMedium)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Styling Helpers

    private func dayBackground(isToday: Bool, isSelected: Bool) -> Color {
        if isToday { return JohoColors.yellow }
        if isSelected { return accentColor }
        return colors.surface
    }

    private func dayTextColor(isToday: Bool, isSelected: Bool, isCurrentMonth: Bool) -> Color {
        if isToday { return colors.primary }
        if isSelected { return colors.primaryInverted }
        return colors.primary
    }

    private func dayBorderColor(isToday: Bool, isSelected: Bool) -> Color {
        if isToday || isSelected { return colors.border }
        return colors.border.opacity(JohoDimensions.opacityHeavy)
    }

    // MARK: - Date Calculations

    private func weeksInMonth() -> [[Date]] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              calendar.range(of: .day, in: .month, for: monthStart) != nil else {
            return []
        }

        // Find the Monday of the week containing the 1st
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        // ISO 8601: Monday = 1, Sunday = 7
        // Calendar weekday: Sunday = 1, Monday = 2, etc.
        let daysToSubtract = (firstWeekday + 5) % 7 // Convert to ISO weekday offset
        guard let gridStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: monthStart) else {
            return []
        }

        var weeks: [[Date]] = []
        var currentDate = gridStart

        // Generate 6 weeks to cover all possible month layouts
        for _ in 0..<6 {
            var week: [Date] = []
            for _ in 0..<7 {
                week.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            weeks.append(week)

            // Stop if we've passed the end of the month and completed the week
            if calendar.component(.month, from: currentDate) != calendar.component(.month, from: monthStart)
                && calendar.component(.day, from: currentDate) > 7 {
                break
            }
        }

        return weeks
    }
}

// MARK: - JohoCalendarPicker Sheet Wrapper

/// Overlay modifier for presenting JohoCalendarPicker floating over content
struct JohoCalendarPickerOverlay: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    // Calendar picker floating over content
                    JohoCalendarPicker(
                        selectedDate: $selectedDate,
                        accentColor: accentColor,
                        onDone: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented = false
                            }
                        },
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented = false
                            }
                        }
                    )
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

extension View {
    /// Present a floating calendar picker overlay
    func johoCalendarPicker(
        isPresented: Binding<Bool>,
        selectedDate: Binding<Date>,
        accentColor: Color
    ) -> some View {
        modifier(JohoCalendarPickerOverlay(
            isPresented: isPresented,
            selectedDate: selectedDate,
            accentColor: accentColor
        ))
    }
}

/// Legacy wrapper - redirects to overlay for backward compatibility
struct JohoCalendarPickerSheet: View {
    @Binding var selectedDate: Date
    let accentColor: Color
    @Binding var isPresented: Bool

    var body: some View {
        // This is now just the picker itself for sheet contexts
        JohoCalendarPicker(
            selectedDate: $selectedDate,
            accentColor: accentColor,
            onDone: { isPresented = false },
            onCancel: { isPresented = false }
        )
        .padding(JohoDimensions.spacingMD)
        .presentationDetents([.medium])
        .presentationCornerRadius(20)
        .presentationDragIndicator(.hidden)
        .presentationBackground(JohoColors.black)
    }
}

