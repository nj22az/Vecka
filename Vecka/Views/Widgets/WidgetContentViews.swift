//
//  WidgetContentViews.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) Widget Content Components
//  20 unique widget designs - adaptive content views that scale to fit their container
//

import SwiftUI
import SwiftData

// MARK: - 1. Today Hero Widget

/// Large today display with date, week number, and year
struct TodayHeroWidgetContent: View {
    private let date = Date()
    private let calendar = Calendar.iso8601

    private var dayNumber: Int { calendar.component(.day, from: date) }
    private var weekdayName: String { date.formatted(.dateTime.weekday(.abbreviated)).uppercased() }
    private var monthName: String { date.formatted(.dateTime.month(.abbreviated)).uppercased() }
    private var yearNumber: Int { calendar.component(.year, from: date) }
    private var weekNumber: Int { calendar.component(.weekOfYear, from: date) }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 100
            let isNarrow = geometry.size.width < 150

            HStack(spacing: JohoDimensions.spacingMD) {
                // Large day number with date info
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(dayNumber)")
                        .font(isCompact ? JohoFont.displayMedium : JohoFont.displayLarge)
                        .foregroundStyle(JohoColors.black)
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)

                    Text("\(weekdayName) • \(monthName)")
                        .font(JohoFont.label)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                        .minimumScaleFactor(0.7)

                    Text(verbatim: "\(yearNumber)")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Spacer()

                if !isNarrow {
                    // Week badge
                    VStack(spacing: 0) {
                        Text("W")
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(JohoColors.white.opacity(0.8))
                        Text("\(weekNumber)")
                            .font(isCompact ? JohoFont.headline : JohoFont.displaySmall)
                            .foregroundStyle(JohoColors.white)
                    }
                    .frame(width: isCompact ? 40 : 48, height: isCompact ? 40 : 48)
                    .background(JohoColors.black)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
    }
}

// MARK: - 2. Week Badge Widget

/// Compact week number badge - minimal style
struct WeekBadgeWidgetContent: View {
    private let calendar = Calendar.iso8601
    private var weekNumber: Int { calendar.component(.weekOfYear, from: Date()) }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            VStack(spacing: 0) {
                Text("WEEK")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.white.opacity(0.7))

                Text("\(weekNumber)")
                    .font(.system(size: size * 0.45, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(JohoColors.black)
        }
    }
}

// MARK: - 3. Month Calendar Widget

/// Full month calendar grid with week numbers
struct MonthCalendarWidgetContent: View {
    private let calendar = Calendar.iso8601
    @State private var currentMonth = CalendarMonth.current()

    var body: some View {
        GeometryReader { geometry in
            // At small heights (2x1 or 3x1), show week strip instead of full calendar
            let isCompact = geometry.size.height < 120

            if isCompact {
                weekStripView(geometry: geometry)
            } else {
                fullCalendarView(geometry: geometry)
            }
        }
    }

    // MARK: - Week Strip (for 2x1, 3x1 sizes)

    @ViewBuilder
    private func weekStripView(geometry: GeometryProxy) -> some View {
        let currentWeek = currentMonth.weeks.first(where: { $0.isCurrentWeek }) ?? currentMonth.weeks[0]
        let dayWidth = (geometry.size.width - 32) / 7

        VStack(spacing: JohoDimensions.spacingXS) {
            // Week number header
            HStack {
                JohoPill(text: "Week \(currentWeek.weekNumber)", style: .whiteOnBlack, size: .small)
                Spacer()
            }

            // Days strip
            HStack(spacing: 4) {
                ForEach(currentWeek.days) { day in
                    VStack(spacing: 2) {
                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(day.isToday ? JohoColors.white : JohoColors.black.opacity(0.5))

                        Text("\(day.dayNumber)")
                            .font(day.isToday ? JohoFont.headline : JohoFont.body)
                            .foregroundStyle(day.isToday ? JohoColors.white : JohoColors.black)
                    }
                    .frame(width: dayWidth)
                    .padding(.vertical, 4)
                    .background(day.isToday ? JohoColors.black : Color.clear)
                    .clipShape(Squircle(cornerRadius: 6))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(JohoDimensions.spacingMD)
    }

    // MARK: - Full Calendar (for 2x2, 4x2, etc.)

    @ViewBuilder
    private func fullCalendarView(geometry: GeometryProxy) -> some View {
        let cellHeight = min(24, (geometry.size.height - 50) / CGFloat(currentMonth.weeks.count + 1))

        VStack(spacing: 2) {
            // Month header
            HStack {
                Text(currentMonth.monthName.uppercased())
                    .font(JohoFont.label)
                    .foregroundStyle(JohoColors.black)

                Text(verbatim: "\(currentMonth.year)")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.5))

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingSM)

            // Weekday headers
            HStack(spacing: 2) {
                Text("W")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
                    .frame(width: 24)

                ForEach(0..<7, id: \.self) { index in
                    let symbol = weekdaySymbol(for: index)
                    Text(symbol)
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(index == 6 ? JohoColors.cyan : JohoColors.black.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            ForEach(currentMonth.weeks) { week in
                HStack(spacing: 2) {
                    Text("\(week.weekNumber)")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.white)
                        .frame(width: 24, height: cellHeight)
                        .background(JohoColors.black)
                        .clipShape(Squircle(cornerRadius: 4))

                    ForEach(week.days) { day in
                        MiniDayCell(day: day.dayNumber, isToday: day.isToday, isCurrentMonth: day.isInCurrentMonth, height: cellHeight)
                    }
                }
            }
        }
        .padding(JohoDimensions.spacingSM)
    }

    private func weekdaySymbol(for index: Int) -> String {
        let adjustedIndex = (index + 1) % 7
        return calendar.veryShortWeekdaySymbols[adjustedIndex]
    }
}

// MARK: - 4. Week Strip Widget

/// Horizontal 7-day strip with today highlighted
struct WeekStripWidgetContent: View {
    private let calendar = Calendar.iso8601
    private let currentWeek: CalendarWeek

    init() {
        currentWeek = CalendarMonth.current().weeks.first(where: { $0.isCurrentWeek }) ?? CalendarMonth.current().weeks[0]
    }

    var body: some View {
        GeometryReader { geometry in
            let dayWidth = (geometry.size.width - 32) / 7

            VStack(spacing: JohoDimensions.spacingXS) {
                // Week number header
                HStack {
                    JohoPill(text: "Week \(currentWeek.weekNumber)", style: .whiteOnBlack, size: .small)
                    Spacer()
                }

                // Days strip
                HStack(spacing: 4) {
                    ForEach(currentWeek.days) { day in
                        VStack(spacing: 2) {
                            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                                .font(JohoFont.labelSmall)
                                .foregroundStyle(day.isToday ? JohoColors.white : JohoColors.black.opacity(0.5))

                            Text("\(day.dayNumber)")
                                .font(day.isToday ? JohoFont.headline : JohoFont.body)
                                .foregroundStyle(day.isToday ? JohoColors.white : JohoColors.black)
                        }
                        .frame(width: dayWidth)
                        .padding(.vertical, 4)
                        .background(day.isToday ? JohoColors.black : Color.clear)
                        .clipShape(Squircle(cornerRadius: 6))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(JohoDimensions.spacingMD)
        }
    }
}

// MARK: - 5. Year Progress Widget

/// Year completion percentage with visual bar
struct YearProgressWidgetContent: View {
    private let calendar = Calendar.iso8601
    private let now = Date()

    private var progress: Double {
        let year = calendar.component(.year, from: now)
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else { return 0 }
        let totalDays = calendar.dateComponents([.day], from: startOfYear, to: endOfYear).day ?? 365
        let daysPassed = calendar.dateComponents([.day], from: startOfYear, to: now).day ?? 0
        return Double(daysPassed) / Double(totalDays)
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 80

            VStack(alignment: .leading, spacing: isCompact ? 4 : JohoDimensions.spacingSM) {
                HStack {
                    Text("YEAR")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)
                }

                // Progress bar
                GeometryReader { barGeometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(JohoColors.cream)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(JohoColors.cyan)
                            .frame(width: barGeometry.size.width * progress)
                    }
                }
                .frame(height: isCompact ? 8 : 12)

                if !isCompact {
                    Text(verbatim: "\(calendar.component(.year, from: now))")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Spacer(minLength: 0)
            }
            .padding(JohoDimensions.spacingMD)
        }
    }
}

// MARK: - 6. Month Progress Widget

/// Month completion percentage
struct MonthProgressWidgetContent: View {
    private let calendar = Calendar.iso8601
    private let now = Date()

    private var progress: Double {
        let day = calendar.component(.day, from: now)
        let range = calendar.range(of: .day, in: .month, for: now)
        let totalDays = range?.count ?? 30
        return Double(day) / Double(totalDays)
    }

    private var monthName: String {
        now.formatted(.dateTime.month(.abbreviated)).uppercased()
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 80

            VStack(alignment: .leading, spacing: isCompact ? 4 : JohoDimensions.spacingSM) {
                HStack {
                    Text(monthName)
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)
                }

                // Progress bar
                GeometryReader { barGeometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(JohoColors.cream)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(JohoColors.green)
                            .frame(width: barGeometry.size.width * progress)
                    }
                }
                .frame(height: isCompact ? 8 : 12)

                Spacer(minLength: 0)
            }
            .padding(JohoDimensions.spacingMD)
        }
    }
}

// MARK: - 7. Quarter View Widget

/// Quarter overview with months
struct QuarterViewWidgetContent: View {
    private let calendar = Calendar.iso8601
    private let now = Date()

    private var currentQuarter: Int {
        let month = calendar.component(.month, from: now)
        return (month - 1) / 3 + 1
    }

    private var quarterMonths: [String] {
        let startMonth = (currentQuarter - 1) * 3 + 1
        return (startMonth...(startMonth + 2)).map { month in
            let date = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: month, day: 1)) ?? now
            return date.formatted(.dateTime.month(.abbreviated))
        }
    }

    private var progress: Double {
        let month = calendar.component(.month, from: now)
        let monthInQuarter = (month - 1) % 3 + 1
        let day = calendar.component(.day, from: now)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        return (Double(monthInQuarter - 1) + Double(day) / Double(daysInMonth)) / 3.0
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                HStack {
                    Text("Q\(currentQuarter)")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(JohoColors.black)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                // Month boxes
                HStack(spacing: JohoDimensions.spacingXS) {
                    ForEach(quarterMonths.indices, id: \.self) { index in
                        let isCurrent = index == (calendar.component(.month, from: now) - 1) % 3

                        Text(quarterMonths[index])
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(isCurrent ? JohoColors.white : JohoColors.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(isCurrent ? JohoColors.black : JohoColors.cream)
                            .clipShape(Squircle(cornerRadius: 6))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(JohoDimensions.spacingMD)
        }
    }
}

// MARK: - 8. Clock Widget

/// Current time display
struct ClockWidgetContent: View {
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 100

            VStack(spacing: 0) {
                Text(currentTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: isCompact ? 32 : 48, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)

                Text(currentTime.formatted(.dateTime.weekday(.wide)))
                    .font(JohoFont.label)
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

// MARK: - 9. Next Holiday Widget

/// Single next upcoming holiday with countdown
struct NextHolidayWidgetContent: View {
    private let holidayManager = HolidayManager.shared
    private let calendar = Calendar.iso8601

    private var nextHoliday: (name: String, date: Date, daysUntil: Int)? {
        let today = calendar.startOfDay(for: Date())

        for daysAhead in 0...365 {
            if let date = calendar.date(byAdding: .day, value: daysAhead, to: today),
               let holidays = holidayManager.holidayCache[date],
               let first = holidays.first(where: { $0.isRedDay }) ?? holidays.first {
                return (first.displayTitle, date, daysAhead)
            }
        }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 100

            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                JohoPill(text: "Next Holiday", style: .colored(JohoColors.pink), size: .small)

                if let holiday = nextHoliday {
                    Spacer(minLength: 0)

                    HStack(alignment: .bottom, spacing: JohoDimensions.spacingSM) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(holiday.name)
                                .font(isCompact ? JohoFont.body : JohoFont.headline)
                                .foregroundStyle(JohoColors.black)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)

                            Text(holiday.date.formatted(.dateTime.day().month(.abbreviated).year()))
                                .font(JohoFont.bodySmall)
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }

                        Spacer()

                        if !isCompact {
                            VStack(spacing: 0) {
                                Text("\(holiday.daysUntil)")
                                    .font(JohoFont.displayMedium)
                                    .foregroundStyle(JohoColors.black)
                                Text(holiday.daysUntil == 1 ? "day" : "days")
                                    .font(JohoFont.caption)
                                    .foregroundStyle(JohoColors.black.opacity(0.5))
                            }
                        }
                    }

                    Spacer(minLength: 0)
                } else {
                    emptyState
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "gift")
                .font(.system(size: 20))
                .foregroundStyle(JohoColors.black.opacity(0.6))
            Text("No holidays")
                .font(JohoFont.caption)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 10. Holidays List Widget

/// Multiple upcoming holidays
struct HolidaysListWidgetContent: View {
    private let holidayManager = HolidayManager.shared
    private let calendar = Calendar.iso8601

    private var upcomingHolidays: [(name: String, date: Date, daysUntil: Int)] {
        let today = calendar.startOfDay(for: Date())
        var holidays: [(String, Date, Int)] = []

        for daysAhead in 0...90 {
            if let date = calendar.date(byAdding: .day, value: daysAhead, to: today),
               let dayHolidays = holidayManager.holidayCache[date] {
                for holiday in dayHolidays {
                    holidays.append((holiday.displayTitle, date, daysAhead))
                    if holidays.count >= 6 { return holidays }
                }
            }
        }
        return holidays
    }

    var body: some View {
        GeometryReader { geometry in
            let maxItems = max(1, Int((geometry.size.height - 50) / 22))

            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                HStack {
                    JohoPill(text: "Holidays", style: .colored(JohoColors.pink), size: .small)
                    Spacer()
                    if upcomingHolidays.count > maxItems {
                        Text("+\(upcomingHolidays.count - maxItems)")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                    }
                }

                if upcomingHolidays.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(upcomingHolidays.prefix(maxItems).enumerated()), id: \.offset) { _, holiday in
                        HStack(spacing: JohoDimensions.spacingSM) {
                            Text(holiday.name)
                                .font(JohoFont.bodySmall)
                                .foregroundStyle(JohoColors.black)
                                .lineLimit(1)

                            Spacer()

                            Text("\(holiday.daysUntil)d")
                                .font(JohoFont.caption)
                                .foregroundStyle(JohoColors.black.opacity(0.5))
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "gift.fill")
                .font(.system(size: 20))
                .foregroundStyle(JohoColors.black.opacity(0.6))
            Text("No holidays")
                .font(JohoFont.caption)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 11. Countdown Hero Widget

/// Large single countdown to next event
struct CountdownHeroWidgetContent: View {
    private let calendar = Calendar.iso8601
    @Query private var countdowns: [CountdownEvent]

    private var nextEvent: (name: String, days: Int)? {
        let today = calendar.startOfDay(for: Date())

        for countdown in countdowns.sorted(by: { $0.targetDate < $1.targetDate }) {
            let eventDay = calendar.startOfDay(for: countdown.targetDate)
            let days = calendar.dateComponents([.day], from: today, to: eventDay).day ?? 0
            if days >= 0 {
                return (countdown.title, days)
            }
        }

        // Fallback to New Year
        let year = calendar.component(.year, from: today)
        if let newYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) {
            let days = calendar.dateComponents([.day], from: today, to: newYear).day ?? 0
            return ("New Year", days)
        }

        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 100

            VStack(spacing: JohoDimensions.spacingXS) {
                if let event = nextEvent {
                    Spacer()

                    Text("\(event.days)")
                        .font(.system(size: isCompact ? 48 : 72, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)

                    Text(event.days == 1 ? "day until" : "days until")
                        .font(JohoFont.caption)
                        .foregroundStyle(JohoColors.black.opacity(0.5))

                    Text(event.name)
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer()
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(JohoDimensions.spacingMD)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.system(size: 24))
                .foregroundStyle(JohoColors.black.opacity(0.6))
            Text("No countdowns")
                .font(JohoFont.caption)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
    }
}

// MARK: - 12. Countdown List Widget

/// Multiple countdown events
struct CountdownListWidgetContent: View {
    private let calendar = Calendar.iso8601
    @Query private var countdowns: [CountdownEvent]

    private var activeCountdowns: [(name: String, days: Int)] {
        let today = calendar.startOfDay(for: Date())

        return countdowns.compactMap { countdown in
            let eventDay = calendar.startOfDay(for: countdown.targetDate)
            let days = calendar.dateComponents([.day], from: today, to: eventDay).day ?? 0
            guard days >= 0 else { return nil }
            return (countdown.title, days)
        }.sorted { $0.days < $1.days }
    }

    var body: some View {
        GeometryReader { geometry in
            let maxItems = max(1, Int((geometry.size.height - 50) / 24))

            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                HStack {
                    JohoPill(text: "Countdowns", style: .colored(JohoColors.orange), size: .small)
                    Spacer()
                }

                if activeCountdowns.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(activeCountdowns.prefix(maxItems).enumerated()), id: \.offset) { _, countdown in
                        HStack(spacing: JohoDimensions.spacingSM) {
                            Text("\(countdown.days)")
                                .font(JohoFont.headline)
                                .foregroundStyle(JohoColors.black)
                                .frame(width: 32, alignment: .trailing)

                            Text(countdown.name)
                                .font(JohoFont.bodySmall)
                                .foregroundStyle(JohoColors.black)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "list.number")
                .font(.system(size: 20))
                .foregroundStyle(JohoColors.black.opacity(0.6))
            Text("No countdowns")
                .font(JohoFont.caption)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 13. Notes Preview Widget

/// Recent notes preview
struct NotesPreviewWidgetContent: View {
    @Query(sort: \DailyNote.date, order: .reverse) private var notes: [DailyNote]

    var body: some View {
        GeometryReader { geometry in
            let maxNotes = max(1, Int((geometry.size.height - 50) / 24))
            let extraCount = max(0, notes.count - maxNotes)

            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                HStack {
                    JohoPill(text: "Notes", style: .colored(JohoColors.yellow), size: .small)
                    Spacer()
                    if extraCount > 0 {
                        Text("+\(extraCount)")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                }

                if notes.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(notes.prefix(maxNotes))) { note in
                        NoteRowView(note: note, maxChars: Int(geometry.size.width / 8))
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "note.text")
                .font(.system(size: 20))
                .foregroundStyle(JohoColors.black.opacity(0.6))
            Text("No notes")
                .font(JohoFont.caption)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 14. Pinned Note Widget

/// Single important pinned note
struct PinnedNoteWidgetContent: View {
    @Query(sort: \DailyNote.date, order: .reverse) private var notes: [DailyNote]

    private var pinnedNote: DailyNote? {
        notes.first
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                HStack {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(noteColor)

                    Text("PINNED")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.5))

                    Spacer()
                }

                if let note = pinnedNote {
                    Text(note.content)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(Int(geometry.size.height / 20))

                    Spacer(minLength: 0)

                    Text(note.date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(JohoFont.caption)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                } else {
                    emptyState
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
    }

    private var noteColor: Color {
        guard let note = pinnedNote else { return JohoColors.cyan }
        switch note.color {
        case "red": return JohoColors.pink
        case "blue": return JohoColors.cyan
        case "green": return JohoColors.green
        case "orange": return JohoColors.orange
        case "yellow": return JohoColors.yellow
        default: return JohoColors.cyan
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "pin")
                .font(.system(size: 20))
                .foregroundStyle(JohoColors.black.opacity(0.6))
            Text("No pinned note")
                .font(JohoFont.caption)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 15. Expense Total Widget

/// Monthly expense total
struct ExpenseTotalWidgetContent: View {
    @Query private var expenses: [ExpenseItem]
    private let calendar = Calendar.iso8601

    private var monthlyTotal: Double {
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        return expenses.filter { expense in
            let expenseMonth = calendar.component(.month, from: expense.date)
            let expenseYear = calendar.component(.year, from: expense.date)
            return expenseMonth == month && expenseYear == year
        }.reduce(0) { $0 + $1.amount }
    }

    private var monthYearLabel: String {
        Date().formatted(.dateTime.month(.wide).year()).uppercased()
    }

    private var transactionCount: Int {
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        return expenses.filter { expense in
            let expenseMonth = calendar.component(.month, from: expense.date)
            let expenseYear = calendar.component(.year, from: expense.date)
            return expenseMonth == month && expenseYear == year
        }.count
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 80

            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                Text(monthYearLabel)
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.black.opacity(0.5))

                Text(formatCurrency(monthlyTotal))
                    .font(isCompact ? JohoFont.displaySmall : JohoFont.displayMedium)
                    .foregroundStyle(JohoColors.black)
                    .minimumScaleFactor(0.5)

                if !isCompact {
                    Text("\(transactionCount) transaction\(transactionCount == 1 ? "" : "s")")
                        .font(JohoFont.caption)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Spacer(minLength: 0)
            }
            .padding(JohoDimensions.spacingMD)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "SEK"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0 kr"
    }
}

// MARK: - 18. Recent Expenses Widget

/// Recent expense list
struct RecentExpensesWidgetContent: View {
    @Query(sort: \ExpenseItem.date, order: .reverse) private var expenses: [ExpenseItem]

    var body: some View {
        GeometryReader { geometry in
            let maxItems = max(1, Int((geometry.size.height - 50) / 28))
            let displayExpenses = Array(expenses.prefix(maxItems))

            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                HStack {
                    JohoPill(text: "Expenses", style: .colored(JohoColors.green), size: .small)
                    Spacer()
                }

                if expenses.isEmpty {
                    emptyState
                } else {
                    ForEach(displayExpenses) { expense in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: JohoDimensions.spacingSM) {
                                Text(expense.itemDescription)
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(JohoColors.black)
                                    .lineLimit(1)

                                Spacer()

                                Text(formatAmount(expense.amount))
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(JohoColors.black)
                            }
                            Text(formatDate(expense.date))
                                .font(JohoFont.caption)
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "SEK"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 20))
                .foregroundStyle(JohoColors.black.opacity(0.6))
            Text("No expenses")
                .font(JohoFont.caption)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 19. Active Trip Widget

/// Active trip overview
struct ActiveTripWidgetContent: View {
    @Query(sort: \TravelTrip.startDate, order: .reverse) private var trips: [TravelTrip]

    private var activeTrip: TravelTrip? {
        let now = Date()
        return trips.first(where: { $0.startDate <= now && $0.endDate >= now })
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                HStack {
                    Image(systemName: "airplane")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JohoColors.cyan)

                    Text("TRIP")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.5))

                    Spacer()
                }

                if let trip = activeTrip {
                    Text(trip.tripName)
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(2)

                    Text(trip.destination)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))

                    Spacer(minLength: 0)

                    Text(trip.startDate.formatted(.dateTime.month(.abbreviated).day()))
                        .font(JohoFont.caption)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                } else {
                    emptyState
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 20))
                .foregroundStyle(JohoColors.black.opacity(0.6))
            Text("No active trip")
                .font(JohoFont.caption)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


// MARK: - Shared Components

/// Note row in the widget
private struct NoteRowView: View {
    let note: DailyNote
    var maxChars: Int = 30

    private var displayText: String {
        let prefix = String(note.content.prefix(maxChars))
        return note.content.count > maxChars ? prefix + "…" : prefix
    }

    private var noteColor: Color {
        switch note.color {
        case "red": return JohoColors.pink
        case "blue": return JohoColors.cyan
        case "green": return JohoColors.green
        case "orange": return JohoColors.orange
        case "yellow": return JohoColors.yellow
        default: return JohoColors.cyan
        }
    }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            Circle()
                .fill(noteColor)
                .frame(width: 6, height: 6)

            Text(displayText)
                .font(JohoFont.bodySmall)
                .foregroundStyle(JohoColors.black)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }
}

/// Mini day cell for calendar widgets
struct MiniDayCell: View {
    let day: Int
    var isToday: Bool = false
    var isCurrentMonth: Bool = true
    var height: CGFloat = 28

    var body: some View {
        Text("\(day)")
            .font(JohoFont.bodySmall)
            .fontWeight(isToday ? .bold : .regular)
            .foregroundStyle(isToday ? JohoColors.white : JohoColors.black)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(isToday ? JohoColors.black : Color.clear)
            .clipShape(Squircle(cornerRadius: 4))
            .opacity(isCurrentMonth ? 1.0 : 0.3)
    }
}

// MARK: - 21. Live Seconds Widget (情報デザイン)

/// T-MINUS seconds countdown - updates every second using TimelineView
/// 情報デザイン: Monospaced digits, BLACK on WHITE, bold industrial typography
struct LiveSecondsWidgetContent: View {
    var body: some View {
        // TimelineView creates the "heartbeat" - updates every second
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            GeometryReader { geometry in
                let isCompact = geometry.size.height < 80
                let secondsLeft = calculateSecondsLeftInDay(from: context.date)

                VStack(spacing: 0) {
                    // Label (情報デザイン: technical label)
                    if !isCompact {
                        HStack {
                            Text("T-MINUS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(JohoColors.cyan)
                            Spacer()
                            // Decorative dots (情報デザイン: grid pattern)
                            HStack(spacing: 2) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Circle()
                                        .fill(JohoColors.cyan.opacity(0.5))
                                        .frame(width: 3, height: 3)
                                }
                            }
                        }
                        .padding(.horizontal, JohoDimensions.spacingSM)
                        .padding(.top, JohoDimensions.spacingSM)
                    }

                    Spacer(minLength: 0)

                    // Main counter (情報デザイン: large monospaced digits)
                    Text("\(secondsLeft)")
                        .font(.system(size: isCompact ? 28 : 36, weight: .black, design: .monospaced))
                        .foregroundStyle(JohoColors.black)
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)

                    // Subtitle
                    Text("SECONDS_REMAINING")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(JohoColors.black.opacity(0.5))

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func calculateSecondsLeftInDay(from date: Date) -> Int {
        let calendar = Calendar.iso8601
        let tomorrow = calendar.startOfDay(for: date.addingTimeInterval(86400))
        return Int(tomorrow.timeIntervalSince(date))
    }
}

// MARK: - 22. World Clock Widget (情報デザイン)

/// World clock with UTC offset badge - flight terminal / mission control style
/// 情報デザイン: Zero-padded time, superscript seconds, UTC offset badge
struct WorldClockWidgetContent: View {
    /// Configuration from widget model
    let config: WorldClockConfig

    /// Initialize with configuration (default: Stora Mellösa)
    init(config: WorldClockConfig = .default) {
        self.config = config
    }

    private var timeZone: TimeZone {
        TimeZone(identifier: config.timeZoneID) ?? TimeZone.current
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    private func formatSeconds(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = ":ss"
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    private func offsetString(for date: Date) -> String {
        let targetOffset = timeZone.secondsFromGMT(for: Date())
        let hours = targetOffset / 3600
        let sign = hours >= 0 ? "+" : ""
        return "UTC\(sign)\(hours)"
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 80
            let isNarrow = geometry.size.width < 120

            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                HStack(spacing: JohoDimensions.spacingSM) {
                    // City code and offset (情報デザイン: technical labels)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(config.displayName)
                            .font(.system(size: isCompact ? 10 : 12, weight: .black, design: .monospaced))
                            .foregroundStyle(JohoColors.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        // UTC offset badge (情報デザイン: status indicator)
                        Text(offsetString(for: context.date))
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(JohoColors.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(JohoColors.cyan.opacity(0.3))
                            .clipShape(Squircle(cornerRadius: 3))
                    }

                    Spacer(minLength: 0)

                    // Time display (情報デザイン: large monospaced)
                    if !isNarrow {
                        HStack(spacing: 0) {
                            Text(formatTime(context.date))
                                .font(.system(size: isCompact ? 20 : 28, weight: .bold, design: .monospaced))
                                .foregroundStyle(JohoColors.black)

                            // Superscript seconds (情報デザイン: secondary data)
                            Text(formatSeconds(context.date))
                                .font(.system(size: isCompact ? 10 : 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(JohoColors.cyan)
                                .offset(y: isCompact ? -4 : -6)
                        }
                    }
                }
                .padding(JohoDimensions.spacingMD)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - 23. System Status Widget (情報デザイン)

/// SYSTEM_MONITOR // ACTIVE header - sci-fi control panel style
/// 情報デザイン: Dense information display, technical labels, live status
struct SystemStatusWidgetContent: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            GeometryReader { geometry in
                let isWide = geometry.size.width > 250
                let date = context.date

                HStack(spacing: JohoDimensions.spacingMD) {
                    // System icon (情報デザイン: technical indicator)
                    Image(systemName: "cpu")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JohoColors.cyan)

                    // Status text (情報デザイン: monospaced technical)
                    Text("SYSTEM_MONITOR // ACTIVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(JohoColors.black)

                    Spacer(minLength: 0)

                    if isWide {
                        // Live timestamp (情報デザイン: raw data)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(JohoColors.green)
                                .frame(width: 6, height: 6)

                            Text(date.formatted(.dateTime.hour().minute().second()))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }
                    }

                    // Status dots (情報デザイン: grid pattern)
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(index == 0 ? JohoColors.green : JohoColors.black.opacity(0.2))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(JohoColors.black.opacity(0.05))
            }
        }
    }
}

// MARK: - Preview

#Preview("Widget Contents") {
    ScrollView {
        VStack(spacing: JohoDimensions.spacingLG) {
            // Today Hero
            TodayHeroWidgetContent()
                .frame(width: 200, height: 100)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )

            // Week Badge
            WeekBadgeWidgetContent()
                .frame(width: 80, height: 80)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )

            // Year Progress
            YearProgressWidgetContent()
                .frame(width: 150, height: 80)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )

            // Clock
            ClockWidgetContent()
                .frame(width: 200, height: 100)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )
        }
        .padding(JohoDimensions.spacingLG)
    }
    .johoBackground()
}
