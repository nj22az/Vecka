//
//  LandingPageView.swift
//  Vecka
//
//  情報デザイン: Today's Data Dashboard - the app's home screen
//  Combines landing page + data dashboard into one entry point
//

import SwiftUI
import SwiftData

struct LandingPageView: View {
    @Environment(\.modelContext) private var modelContext

    // Data queries
    @Query(sort: \DailyNote.date, order: .reverse) private var allNotes: [DailyNote]
    @Query(sort: \ExpenseItem.date, order: .reverse) private var allExpenses: [ExpenseItem]
    @Query private var allTrips: [TravelTrip]
    @Query private var contacts: [Contact]
    @Query private var countdownEvents: [CountdownEvent]

    // Managers
    private var holidayManager = HolidayManager.shared

    // Random spotlight state
    @State private var spotlightItem: SpotlightItem?

    // MARK: - Computed Properties

    private var today: Date { Date() }

    private var weekNumber: Int {
        Calendar.iso8601.component(.weekOfYear, from: today)
    }

    private var dayNumber: Int {
        Calendar.iso8601.component(.day, from: today)
    }

    private var weekday: String {
        today.formatted(.dateTime.weekday(.abbreviated)).uppercased()
    }

    private var year: Int {
        Calendar.iso8601.component(.year, from: today)
    }

    private var activeTrips: [TravelTrip] {
        let todayStart = Calendar.iso8601.startOfDay(for: today)
        return allTrips.filter { Calendar.iso8601.startOfDay(for: $0.endDate) >= todayStart }
    }

    // Stats
    private var notesCount: Int { allNotes.count }
    private var expensesCount: Int { getThisMonthExpenses().count }
    private var tripsCount: Int { activeTrips.count }
    private var specialDaysCount: Int { getAllUpcomingSpecialDays().count }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: JohoDimensions.spacingMD) {
                    // 情報デザイン: Bento-style header with mascot
                    landingHeader
                        .padding(.horizontal, JohoDimensions.spacingLG)
                        .padding(.top, JohoDimensions.spacingSM)

                    // Adaptive data card grid
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

    // MARK: - Landing Header (情報デザイン: Bento with mascot)

    private var landingHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // LEFT: Mascot + Title
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Geometric mascot (情報デザイン compliant)
                    GeometricMascotView(size: 44, showOuterBorder: false)

                    Text("TODAY")
                        .font(JohoFont.headline)
                        .foregroundStyle(JohoColors.black)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

                // VERTICAL WALL
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)

                // RIGHT: Day + Weekday
                HStack(spacing: 4) {
                    Text("\(dayNumber)")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(JohoColors.black)
                    Text(weekday)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                }
                .frame(width: 80)
            }
            .frame(height: 56)

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // Stats row
            HStack(spacing: JohoDimensions.spacingMD) {
                statsRow
                Spacer()
                // Week badge
                Text("W\(weekNumber)")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(JohoColors.black)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusLarge)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            if notesCount > 0 {
                statIndicator(count: notesCount, color: JohoColors.yellow, label: "notes")
            }
            if expensesCount > 0 {
                statIndicator(count: expensesCount, color: JohoColors.green, label: "expenses")
            }
            if tripsCount > 0 {
                statIndicator(count: tripsCount, color: JohoColors.orange, label: "trips")
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

    // MARK: - Adaptive Card Grid

    @ViewBuilder
    private func adaptiveCardGrid(geometry: GeometryProxy) -> some View {
        let spacing: CGFloat = JohoDimensions.spacingMD
        let horizontalPadding: CGFloat = JohoDimensions.spacingLG
        let availableWidth = geometry.size.width - (horizontalPadding * 2)

        let minCardWidth: CGFloat = 160
        let maxColumns = max(1, Int(availableWidth / minCardWidth))
        let columns = min(maxColumns, 3)

        let cardWidth = (availableWidth - (spacing * CGFloat(columns - 1))) / CGFloat(columns)

        VStack(spacing: spacing) {
            // Row 1: Today (full width hero)
            todayCard
                .padding(.horizontal, horizontalPadding)

            // Row 2: Week + Year (+ Spotlight on wide screens)
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

            // Row 3: Holidays + Notes (+ Expenses on wide screens)
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

            // Row 4: Active trip (if any)
            if !activeTrips.isEmpty {
                activeTripCard
                    .padding(.horizontal, horizontalPadding)
            }
        }
    }

    // MARK: - Today Card (情報デザイン: Yellow = NOW)

    private var todayCard: some View {
        let weekdayFull = today.formatted(.dateTime.weekday(.wide)).uppercased()
        let monthYear = today.formatted(.dateTime.month(.wide).year())

        return LandingDataCard(title: "TODAY", icon: "sun.max.fill", zone: .notes) {
            HStack(spacing: JohoDimensions.spacingLG) {
                Text("\(dayNumber)")
                    .font(JohoFont.displayLarge)
                    .foregroundStyle(JohoColors.black)

                VStack(alignment: .leading, spacing: 4) {
                    Text(weekdayFull)
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

    // MARK: - Week Info Card (情報デザイン: Cyan = Scheduled)

    private var weekInfoCard: some View {
        let daysLeft = daysLeftInWeek()

        return LandingDataCard(title: "WEEK", icon: "calendar.badge.clock", zone: .calendar) {
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

    private var yearProgressCard: some View {
        let calendar = Calendar.iso8601
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        let totalDays = calendar.dateComponents([.day], from: startOfYear, to: endOfYear).day!
        let daysPassed = calendar.dateComponents([.day], from: startOfYear, to: today).day!
        let progress = Double(daysPassed) / Double(totalDays)

        return LandingDataCard(title: "YEAR", icon: "chart.bar.fill", zone: .expenses) {
            VStack(spacing: JohoDimensions.spacingSM) {
                Text("\(Int(progress * 100))%")
                    .font(JohoFont.displaySmall)
                    .foregroundStyle(JohoColors.black)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Squircle(cornerRadius: 4)
                            .fill(JohoColors.black.opacity(0.1))
                            .frame(height: 10)

                        Squircle(cornerRadius: 4)
                            .fill(JohoColors.green)
                            .frame(width: geo.size.width * progress, height: 10)
                    }
                    .overlay(
                        Squircle(cornerRadius: 4)
                            .stroke(JohoColors.black, lineWidth: 1)
                            .frame(height: 10)
                    )
                }
                .frame(height: 10)

                Text("\(totalDays - daysPassed) days left")
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Spotlight Card

    private var spotlightCard: some View {
        LandingDataCard(title: "SPOTLIGHT", icon: "sparkles", zone: .events) {
            if let item = spotlightItem {
                VStack(spacing: JohoDimensions.spacingSM) {
                    Text("\(item.daysUntil)")
                        .font(JohoFont.displayMedium)
                        .foregroundStyle(item.color)

                    Text("days until")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.5))

                    Text(item.name)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                        Text(item.typeLabel)
                            .font(JohoFont.labelSmall)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(JohoColors.black.opacity(0.3))

                    Text("No upcoming events")
                        .font(JohoFont.caption)
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Upcoming Holidays Card (情報デザイン: Pink = Special)

    private var upcomingHolidaysCard: some View {
        let upcomingHolidays = getUpcomingHolidays(limit: 3)

        return LandingDataCard(title: "HOLIDAYS", icon: "star.fill", zone: .holidays) {
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

    // MARK: - Recent Notes Card (情報デザイン: Yellow = Notes)

    private var recentNotesCard: some View {
        let recentNotes = Array(allNotes.prefix(3))

        return LandingDataCard(title: "NOTES", icon: "note.text", zone: .notes) {
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

                            Text(String(note.content.prefix(25)) + (note.content.count > 25 ? "..." : ""))
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

    // MARK: - Expense Summary Card (情報デザイン: Green = Money)

    private var expenseSummaryCard: some View {
        let thisMonth = getThisMonthExpenses()
        let total = thisMonth.reduce(0) { $0 + $1.amount }

        return LandingDataCard(title: "EXPENSES", icon: "dollarsign.circle", zone: .expenses) {
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

    // MARK: - Active Trip Card (情報デザイン: Orange = Movement)

    private var activeTripCard: some View {
        guard let trip = activeTrips.first else {
            return AnyView(EmptyView())
        }

        let daysLeft = Calendar.iso8601.dateComponents([.day], from: today, to: trip.endDate).day ?? 0

        return AnyView(
            LandingDataCard(title: "ACTIVE TRIP", icon: "airplane", zone: .trips) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.tripName)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)

                        Text(trip.destination)
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.7))
                    }

                    Spacer()

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

    // MARK: - Spotlight Item

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
        spotlightItem = allSpecialDays.randomElement()
    }

    private func getAllUpcomingSpecialDays() -> [SpotlightItem] {
        let todayStart = Calendar.iso8601.startOfDay(for: today)
        let calendar = Calendar.iso8601
        var items: [SpotlightItem] = []

        // Holidays
        for (date, cachedHolidays) in holidayManager.holidayCache {
            if date > todayStart {
                let days = calendar.dateComponents([.day], from: todayStart, to: date).day ?? 0
                for holiday in cachedHolidays {
                    let color = holiday.isRedDay ? JohoColors.red : JohoColors.orange
                    let typeLabel = holiday.isRedDay ? "HOLIDAY" : "OBSERVANCE"
                    items.append(SpotlightItem(name: holiday.displayTitle, daysUntil: days, color: color, typeLabel: typeLabel))
                }
            }
        }

        // Birthdays
        let currentYear = calendar.component(.year, from: todayStart)
        for contact in contacts {
            guard let birthday = contact.birthday else { continue }
            let bMonth = calendar.component(.month, from: birthday)
            let bDay = calendar.component(.day, from: birthday)

            for yearOffset in 0...1 {
                if let nextBirthday = calendar.date(from: DateComponents(year: currentYear + yearOffset, month: bMonth, day: bDay)),
                   nextBirthday > todayStart {
                    let days = calendar.dateComponents([.day], from: todayStart, to: nextBirthday).day ?? 0
                    if days <= 365 {
                        let name = contact.displayName.isEmpty ? "Birthday" : "\(contact.displayName)'s Birthday"
                        items.append(SpotlightItem(name: name, daysUntil: days, color: JohoColors.pink, typeLabel: "BIRTHDAY"))
                        break
                    }
                }
            }
        }

        // Countdown events
        for event in countdownEvents {
            let eventDate = calendar.startOfDay(for: event.targetDate)
            if eventDate > todayStart {
                let days = calendar.dateComponents([.day], from: todayStart, to: eventDate).day ?? 0
                items.append(SpotlightItem(name: event.title, daysUntil: days, color: JohoColors.eventPurple, typeLabel: "EVENT"))
            }
        }

        // New Year
        if let newYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) {
            let days = calendar.dateComponents([.day], from: todayStart, to: newYear).day ?? 0
            items.append(SpotlightItem(name: "New Year \(year + 1)", daysUntil: days, color: JohoColors.cyan, typeLabel: "NEW YEAR"))
        }

        return items.filter { $0.daysUntil > 0 && $0.daysUntil <= 365 }
    }

    // MARK: - Helper Functions

    private func daysLeftInWeek() -> Int {
        let calendar = Calendar.iso8601
        let weekday = calendar.component(.weekday, from: today)
        let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
        return 7 - adjustedWeekday
    }

    private func getUpcomingHolidays(limit: Int) -> [(name: String, date: Date)] {
        let todayStart = Calendar.iso8601.startOfDay(for: today)
        var holidays: [(name: String, date: Date)] = []

        for (date, cachedHolidays) in holidayManager.holidayCache {
            if date >= todayStart {
                for holiday in cachedHolidays {
                    holidays.append((holiday.displayTitle, date))
                }
            }
        }

        return Array(holidays.sorted { $0.date < $1.date }.prefix(limit))
    }

    private func getThisMonthExpenses() -> [ExpenseItem] {
        let calendar = Calendar.iso8601
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        return allExpenses.filter { $0.date >= startOfMonth }
    }

    private func daysUntilText(_ date: Date) -> String {
        let days = Calendar.iso8601.dateComponents([.day], from: today, to: date).day ?? 0
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

// MARK: - Landing Data Card (情報デザイン: Bento compartment)

private struct LandingDataCard<Content: View>: View {
    let title: String
    let icon: String
    let zone: SectionZone
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: JohoDimensions.spacingSM) {
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

            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

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

#Preview("Landing Data Dashboard") {
    LandingPageView()
}
