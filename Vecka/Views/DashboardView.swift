//
//  DashboardView.swift
//  Vecka
//
//  Data dashboard - shows at-a-glance information
//  情報デザイン (Jōhō Dezain) - Adaptive grid, no truncation
//
//  Future: Will become "Stats" or "Data" page
//

import SwiftUI
import SwiftData

// MARK: - Dashboard View

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    // Unified Memo query - filter by type in computed properties
    @Query(sort: \Memo.date, order: .reverse) private var allMemos: [Memo]
    @Query private var contacts: [Contact]

    // Managers
    private var holidayManager = HolidayManager.shared

    // Random spotlight state - changes each view appearance
    @State private var spotlightItem: SpotlightItem?

    // Computed: Filter memos by type
    private var allNotes: [Memo] {
        allMemos.filter { $0.type == .note }
    }

    private var allExpenses: [Memo] {
        allMemos.filter { $0.type == .expense }
    }

    private var allTrips: [Memo] {
        allMemos.filter { $0.type == .trip }
    }

    private var countdownMemos: [Memo] {
        allMemos.filter { $0.type == .countdown }
    }

    // Computed active trips (end date >= today)
    private var activeTrips: [Memo] {
        let today = Calendar.iso8601.startOfDay(for: Date())
        return allTrips.filter { memo in
            guard let endDate = memo.tripEndDate else { return false }
            return Calendar.iso8601.startOfDay(for: endDate) >= today
        }
    }

    // Computed stats for stats row
    private var notesCount: Int { allNotes.count }
    private var expensesCount: Int { getThisMonthExpenses().count }
    private var tripsCount: Int { activeTrips.count }
    private var specialDaysCount: Int { getAllUpcomingSpecialDays().count }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: JohoDimensions.spacingMD) {
                    // 情報デザイン: Bento-style page header (Golden Standard Pattern)
                    dataPageHeader
                        .padding(.horizontal, JohoDimensions.spacingLG)
                        .padding(.top, JohoDimensions.spacingSM)

                    // Adaptive grid layout - cards flow naturally
                    adaptiveCardGrid(geometry: geometry)
                }
                .padding(.bottom, JohoDimensions.spacingLG)
            }
            .scrollContentBackground(.hidden)
        }
        .johoBackground()
        .onAppear {
            pickRandomSpotlight()
        }
    }

    // MARK: - Data Page Header (情報デザイン: Golden Standard Pattern)

    private var dataPageHeader: some View {
        VStack(spacing: 0) {
            // TOP ROW: Icon + Title | WALL | Card count
            HStack(spacing: 0) {
                // LEFT COMPARTMENT: Icon + Title
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Icon zone with Tools accent color (Teal)
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(PageHeaderColor.tools.accent)
                        .frame(width: 40, height: 40)
                        .background(PageHeaderColor.tools.lightBackground)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.black, lineWidth: 1.5)
                        )

                    Text("DATA")
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

                // VERTICAL WALL (separator)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)

                // RIGHT COMPARTMENT: Card count
                HStack(spacing: 4) {
                    Text("7")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(JohoColors.black)
                    Text("CARDS")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                }
                .frame(width: 80)
            }
            .frame(height: 56)

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // STATS ROW (full width) - shows colored indicators like Star Page
            HStack(spacing: JohoDimensions.spacingMD) {
                statsRow
                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Stats Row (情報デザイン: Colored indicators like Star Page)

    private var statsRow: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            if notesCount > 0 {
                statIndicator(count: notesCount, color: JohoColors.yellow, label: "notes")
            }
            if expensesCount > 0 {
                statIndicator(count: expensesCount, color: JohoColors.green, label: "expenses")
            }
            if tripsCount > 0 {
                statIndicator(count: tripsCount, color: JohoColors.cyan, label: "trips")
            }
            if specialDaysCount > 0 {
                statIndicator(count: specialDaysCount, color: JohoColors.pink, label: "upcoming")
            }

            if notesCount == 0 && expensesCount == 0 && tripsCount == 0 && specialDaysCount == 0 {
                Text("Your data at a glance")
                    .font(JohoFont.bodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
        }
    }

    private func statIndicator(count: Int, color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
            Text("\(count)")
                .font(JohoFont.labelSmall)
                .foregroundStyle(JohoColors.black)
        }
        .accessibilityLabel("\(count) \(label)")
    }

    // MARK: - Adaptive Card Grid (情報デザイン: No truncation, natural flow)

    @ViewBuilder
    private func adaptiveCardGrid(geometry: GeometryProxy) -> some View {
        let spacing: CGFloat = JohoDimensions.spacingMD
        let horizontalPadding: CGFloat = JohoDimensions.spacingLG
        let availableWidth = geometry.size.width - (horizontalPadding * 2)

        // Determine column count based on available width
        // Min card width ~160pt for readability
        let minCardWidth: CGFloat = 160
        let maxColumns = max(1, Int(availableWidth / minCardWidth))
        let columns = min(maxColumns, 3) // Cap at 3 columns

        let cardWidth = (availableWidth - (spacing * CGFloat(columns - 1))) / CGFloat(columns)

        VStack(spacing: spacing) {
            // Row 1: Today (full width hero card)
            todayCard
                .padding(.horizontal, horizontalPadding)

            // Row 2: Week + Year (or stacked on narrow screens)
            if columns >= 2 {
                HStack(alignment: .top, spacing: spacing) {
                    weekInfoCard
                        .frame(width: cardWidth)
                    yearProgressCard
                        .frame(width: cardWidth)
                    if columns == 3 {
                        spotlightCard
                            .frame(width: cardWidth)
                    }
                }
                .padding(.horizontal, horizontalPadding)

                // Spotlight card for 2-column layout (full width)
                if columns == 2 {
                    spotlightCard
                        .padding(.horizontal, horizontalPadding)
                }
            } else {
                VStack(spacing: spacing) {
                    weekInfoCard
                    yearProgressCard
                    spotlightCard
                }
                .padding(.horizontal, horizontalPadding)
            }

            // Row 3: Upcoming + Notes (or stacked)
            if columns >= 2 {
                HStack(alignment: .top, spacing: spacing) {
                    upcomingHolidaysCard
                        .frame(width: cardWidth)
                    recentNotesCard
                        .frame(width: cardWidth)
                    if columns == 3 {
                        expenseSummaryCard
                            .frame(width: cardWidth)
                    }
                }
                .padding(.horizontal, horizontalPadding)

                // Extra row for 2-column layout
                if columns == 2 {
                    expenseSummaryCard
                        .padding(.horizontal, horizontalPadding)
                }
            } else {
                VStack(spacing: spacing) {
                    upcomingHolidaysCard
                    recentNotesCard
                    expenseSummaryCard
                }
                .padding(.horizontal, horizontalPadding)
            }

            // Row 4: Active trip (full width, if any)
            if !activeTrips.isEmpty {
                activeTripCard
                    .padding(.horizontal, horizontalPadding)
            }
        }
    }

    // MARK: - Today Card (情報デザイン: Yellow = NOW/Present)

    private var todayCard: some View {
        let today = Date()
        let calendar = Calendar.iso8601
        let dayNumber = calendar.component(.day, from: today)
        let weekday = today.formatted(.dateTime.weekday(.wide)).uppercased()
        let monthYear = today.formatted(.dateTime.month(.wide).year())

        return DataCard(title: "TODAY", icon: "sun.max.fill", zone: .notes) {
            HStack(spacing: JohoDimensions.spacingLG) {
                // Large day number - 情報デザイン: Hero display size
                Text("\(dayNumber)")
                    .font(JohoFont.displayLarge)
                    .foregroundStyle(JohoColors.black)

                VStack(alignment: .leading, spacing: 4) {
                    Text(weekday)
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)

                    Text(monthYear)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                }

                Spacer()
            }
        }
    }

    // MARK: - Week Info Card (情報デザイン: Cyan = Scheduled Time)

    private var weekInfoCard: some View {
        let weekNumber = WeekCalculator.shared.weekNumber(for: Date())
        let daysLeft = daysLeftInWeek()

        return DataCard(title: "WEEK", icon: "calendar.badge.clock", zone: .calendar) {
            VStack(spacing: JohoDimensions.spacingSM) {
                Text("W\(weekNumber)")
                    .font(JohoFont.displayMedium)
                    .foregroundStyle(JohoColors.black)

                Text("\(daysLeft) days left")
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Year Progress Card (情報デザイン: Green = Growth)

    private var yearProgressData: (progress: Double, totalDays: Int, daysPassed: Int)? {
        let calendar = Calendar.iso8601
        let today = Date()
        let year = calendar.component(.year, from: today)
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)),
              let totalDays = calendar.dateComponents([.day], from: startOfYear, to: endOfYear).day,
              let daysPassed = calendar.dateComponents([.day], from: startOfYear, to: today).day,
              totalDays > 0 else { return nil }
        return (Double(daysPassed) / Double(totalDays), totalDays, daysPassed)
    }

    private var yearProgressCard: some View {
        DataCard(title: "YEAR", icon: "chart.bar.fill", zone: .expenses) {
            if let data = yearProgressData {
                VStack(spacing: JohoDimensions.spacingSM) {
                    Text("\(Int(data.progress * 100))%")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(JohoColors.black)

                    // Progress bar - 情報デザイン: Squircle with black border
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Squircle(cornerRadius: 4)
                                .fill(JohoColors.black.opacity(0.1))
                                .frame(height: 10)

                            Squircle(cornerRadius: 4)
                                .fill(JohoColors.green)
                                .frame(width: geo.size.width * data.progress, height: 10)
                        }
                        .overlay(
                            Squircle(cornerRadius: 4)
                                .stroke(JohoColors.black, lineWidth: 1)
                                .frame(height: 10)
                        )
                    }
                    .frame(height: 10)

                    Text("\(data.totalDays - data.daysPassed) days left")
                        .font(JohoFont.caption)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("--")
                    .font(JohoFont.displaySmall)
                    .foregroundStyle(JohoColors.black)
            }
        }
    }

    // MARK: - Spotlight Card (Random special day countdown)

    private var spotlightCard: some View {
        DataCard(title: "SPOTLIGHT", icon: "sparkles", zone: .events) {
            if let item = spotlightItem {
                VStack(spacing: JohoDimensions.spacingSM) {
                    // Days countdown - large number
                    Text("\(item.daysUntil)")
                        .font(JohoFont.displayMedium)
                        .foregroundStyle(item.color)

                    Text("days until")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.5))

                    // Event name
                    Text(item.name)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Type indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: JohoDimensions.borderThin))
                        Text(item.typeLabel)
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.3))

                    Text("No upcoming events")
                        .font(JohoFont.caption)
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Upcoming Holidays Card (情報デザイン: Pink = Special Days)

    private var upcomingHolidaysCard: some View {
        let upcomingHolidays = getUpcomingHolidays(limit: 3)

        return DataCard(title: "HOLIDAYS", icon: "star.fill", zone: .holidays) {
            if upcomingHolidays.isEmpty {
                Text("No upcoming holidays")
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.5))
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: JohoDimensions.spacingSM) {
                    ForEach(upcomingHolidays, id: \.name) { holiday in
                        HStack {
                            JohoIndicatorCircle(color: JohoColors.red, size: .small)

                            Text(holiday.name)
                                .font(JohoFont.bodySmall)
                                .foregroundStyle(JohoColors.black)
                                .lineLimit(1)

                            Spacer()

                            Text(daysUntilText(holiday.date))
                                .font(JohoFont.labelSmall)
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Notes Card (情報デザイン: Cream = Personal/Notes)

    private var recentNotesCard: some View {
        let recentNotes = Array(allNotes.prefix(3))

        return DataCard(title: "NOTES", icon: "note.text", zone: .notes) {
            if recentNotes.isEmpty {
                Text("No notes yet")
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.5))
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: JohoDimensions.spacingSM) {
                    ForEach(recentNotes) { note in
                        HStack {
                            JohoIndicatorCircle(color: JohoColors.yellow, size: .small)

                            Text(note.text.prefix(25) + (note.text.count > 25 ? "..." : ""))
                                .font(JohoFont.caption)
                                .foregroundStyle(JohoColors.black)
                                .lineLimit(1)

                            Spacer()

                            Text(note.date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(JohoFont.labelSmall)
                                .foregroundStyle(JohoColors.black.opacity(0.5))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Expense Summary Card (情報デザイン: Green = Money/Expenses)

    private var expenseSummaryCard: some View {
        let thisMonth = getThisMonthExpenses()
        let total = thisMonth.reduce(0) { $0 + ($1.amount ?? 0) }

        return DataCard(title: "EXPENSES", icon: "dollarsign.circle", zone: .expenses) {
            VStack(spacing: JohoDimensions.spacingSM) {
                Text(formatCurrency(total))
                    .font(JohoFont.displaySmall)
                    .foregroundStyle(JohoColors.black)

                Text("this month")
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.6))

                Text("\(thisMonth.count) transaction\(thisMonth.count == 1 ? "" : "s")")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Active Trip Card (情報デザイン: Orange = Movement/Trips)

    private var activeTripCard: some View {
        guard let trip = activeTrips.first else {
            return AnyView(EmptyView())
        }

        let daysLeft = Calendar.iso8601.dateComponents([.day], from: Date(), to: trip.tripEndDate ?? Date()).day ?? 0

        return AnyView(
            DataCard(title: "ACTIVE TRIP", icon: "airplane", zone: .trips) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.text)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)

                        Text(trip.place ?? "")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.7))
                    }

                    Spacer()

                    // Days left badge - 情報デザイン: Black badge with white text
                    VStack(spacing: 2) {
                        Text("\(max(0, daysLeft))")
                            .font(JohoFont.displaySmall)
                            .foregroundStyle(JohoColors.white)

                        Text("days")
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(JohoColors.white.opacity(0.8))
                    }
                    .frame(width: 56, height: 56)
                    .background(JohoColors.black)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                }
            }
        )
    }

    // MARK: - Spotlight Item (Random special day)

    private struct SpotlightItem {
        let name: String
        let daysUntil: Int
        let color: Color
        let typeLabel: String
    }

    private func pickRandomSpotlight() {
        let allSpecialDays = getAllUpcomingSpecialDays()
        guard !allSpecialDays.isEmpty else {
            spotlightItem = nil
            return
        }

        // Pick a random one (safe - guard above ensures non-empty)
        spotlightItem = allSpecialDays.randomElement()
    }

    private func getAllUpcomingSpecialDays() -> [SpotlightItem] {
        let today = Calendar.iso8601.startOfDay(for: Date())
        let calendar = Calendar.iso8601
        var items: [SpotlightItem] = []

        // 1. Holidays from cache
        for (date, cachedHolidays) in holidayManager.holidayCache {
            if date > today {
                let days = calendar.dateComponents([.day], from: today, to: date).day ?? 0
                for holiday in cachedHolidays {
                    let color = holiday.isBankHoliday ? JohoColors.red : JohoColors.cyan
                    let typeLabel = holiday.isBankHoliday ? "HOLIDAY" : "OBSERVANCE"
                    items.append(SpotlightItem(name: holiday.displayTitle, daysUntil: days, color: color, typeLabel: typeLabel))
                }
            }
        }

        // 2. Birthdays from contacts (within next 365 days)
        let currentYear = calendar.component(.year, from: today)
        for contact in contacts {
            guard let birthday = contact.birthday else { continue }
            let bMonth = calendar.component(.month, from: birthday)
            let bDay = calendar.component(.day, from: birthday)

            // Check this year and next year
            for yearOffset in 0...1 {
                if let nextBirthday = calendar.date(from: DateComponents(year: currentYear + yearOffset, month: bMonth, day: bDay)),
                   nextBirthday > today {
                    let days = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0
                    if days <= 365 {
                        let name = contact.displayName.isEmpty ? "Birthday" : "\(contact.displayName)'s Birthday"
                        items.append(SpotlightItem(name: name, daysUntil: days, color: JohoColors.pink, typeLabel: "BIRTHDAY"))
                        break
                    }
                }
            }
        }

        // 3. Countdown events (from Memo)
        for event in countdownMemos {
            let eventDate = calendar.startOfDay(for: event.date)
            if eventDate > today {
                let days = calendar.dateComponents([.day], from: today, to: eventDate).day ?? 0
                items.append(SpotlightItem(name: event.text, daysUntil: days, color: JohoColors.cyan, typeLabel: "EVENT"))
            }
        }

        // 4. New Year (always include)
        let year = calendar.component(.year, from: today)
        if let newYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) {
            let days = calendar.dateComponents([.day], from: today, to: newYear).day ?? 0
            items.append(SpotlightItem(name: "New Year \(year + 1)", daysUntil: days, color: JohoColors.cyan, typeLabel: "NEW YEAR"))
        }

        return items.filter { $0.daysUntil > 0 && $0.daysUntil <= 365 }
    }

    // MARK: - Helper Functions

    private func daysLeftInWeek() -> Int {
        let calendar = Calendar.iso8601
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // ISO week: Monday = 2, Sunday = 1
        let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
        return 7 - adjustedWeekday
    }

    private func getUpcomingHolidays(limit: Int) -> [(name: String, date: Date)] {
        let today = Calendar.iso8601.startOfDay(for: Date())

        var holidays: [(name: String, date: Date)] = []

        for (date, cachedHolidays) in holidayManager.holidayCache {
            if date >= today {
                for holiday in cachedHolidays {
                    holidays.append((holiday.displayTitle, date))
                }
            }
        }

        return Array(holidays.sorted { $0.date < $1.date }.prefix(limit))
    }

    private func getThisMonthExpenses() -> [Memo] {
        let calendar = Calendar.iso8601
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!

        return allExpenses.filter { $0.date >= startOfMonth }
    }

    private func daysUntilText(_ date: Date) -> String {
        let days = Calendar.iso8601.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "\(days)d"
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Data Card Component (情報デザイン: Bento compartment style)

private struct DataCard<Content: View>: View {
    let title: String
    let icon: String
    let zone: SectionZone
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with icon zone - 情報デザイン: Colored icon in zone background
            HStack(spacing: JohoDimensions.spacingSM) {
                // Icon zone - uses SectionZone background for proper semantic color
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 28, height: 28)
                    .background(zone.background)
                    .clipShape(Squircle(cornerRadius: 6))
                    .overlay(
                        Squircle(cornerRadius: 6)
                            .stroke(JohoColors.black, lineWidth: 1)
                    )

                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(JohoColors.black)

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            // Divider - 情報デザイン: Black border between compartments
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // Content
            content
                .padding(JohoDimensions.spacingMD)
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }
}

// MARK: - Preview

#Preview("Data Dashboard - Portrait") {
    DashboardView()
        .frame(width: 820, height: 1180)
}

#Preview("Data Dashboard - Landscape") {
    DashboardView()
        .frame(width: 1180, height: 820)
}

#Preview("Data Dashboard - iPhone") {
    DashboardView()
        .frame(width: 393, height: 852)
}
