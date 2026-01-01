//
//  DashboardView.swift
//  Vecka
//
//  Predefined dashboard for iPad - shows at-a-glance information
//  情報デザイン (Jōhō Dezain) - Fixed layout, no user customization
//

import SwiftUI
import SwiftData

// MARK: - Dashboard View (iPad Only)

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    // Data queries
    @Query(sort: \DailyNote.date, order: .reverse) private var allNotes: [DailyNote]
    @Query(sort: \ExpenseItem.date, order: .reverse) private var allExpenses: [ExpenseItem]
    @Query private var allTrips: [TravelTrip]

    // Managers
    private var holidayManager = HolidayManager.shared

    // Computed active trips (end date >= today)
    private var activeTrips: [TravelTrip] {
        let today = Calendar.iso8601.startOfDay(for: Date())
        return allTrips.filter { Calendar.iso8601.startOfDay(for: $0.endDate) >= today }
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ScrollView {
                if isLandscape {
                    landscapeLayout(geometry: geometry)
                } else {
                    portraitLayout(geometry: geometry)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .background(JohoColors.background)
    }

    // MARK: - Landscape Layout (3 columns)

    @ViewBuilder
    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        let spacing: CGFloat = JohoDimensions.spacingMD
        let columnWidth = (geometry.size.width - spacing * 4) / 3

        HStack(alignment: .top, spacing: spacing) {
            // Column 1: Today + Week
            VStack(spacing: spacing) {
                todayCard
                weekInfoCard
                yearProgressCard
            }
            .frame(width: columnWidth)

            // Column 2: Upcoming
            VStack(spacing: spacing) {
                upcomingHolidaysCard
                countdownsCard
            }
            .frame(width: columnWidth)

            // Column 3: Activity
            VStack(spacing: spacing) {
                recentNotesCard
                expenseSummaryCard
                if !activeTrips.isEmpty {
                    activeTripCard
                }
            }
            .frame(width: columnWidth)
        }
        .padding(spacing)
    }

    // MARK: - Portrait Layout (2 columns)

    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        let spacing: CGFloat = JohoDimensions.spacingMD
        let columnWidth = (geometry.size.width - spacing * 3) / 2

        VStack(spacing: spacing) {
            // Row 1: Today hero (full width)
            todayCard

            // Row 2: Week + Year progress
            HStack(alignment: .top, spacing: spacing) {
                weekInfoCard
                    .frame(width: columnWidth)
                yearProgressCard
                    .frame(width: columnWidth)
            }

            // Row 3: Upcoming holidays + Countdowns
            HStack(alignment: .top, spacing: spacing) {
                upcomingHolidaysCard
                    .frame(width: columnWidth)
                countdownsCard
                    .frame(width: columnWidth)
            }

            // Row 4: Notes + Expenses
            HStack(alignment: .top, spacing: spacing) {
                recentNotesCard
                    .frame(width: columnWidth)
                expenseSummaryCard
                    .frame(width: columnWidth)
            }

            // Row 5: Active trip (full width, if any)
            if !activeTrips.isEmpty {
                activeTripCard
            }
        }
        .padding(spacing)
    }

    // MARK: - Today Card

    private var todayCard: some View {
        let today = Date()
        let calendar = Calendar.iso8601
        let dayNumber = calendar.component(.day, from: today)
        let weekday = today.formatted(.dateTime.weekday(.wide)).uppercased()
        let monthYear = today.formatted(.dateTime.month(.wide).year())

        return DashboardCard(title: "TODAY", icon: "sun.max.fill", accentColor: JohoColors.yellow) {
            HStack(spacing: JohoDimensions.spacingLG) {
                // Large day number
                Text("\(dayNumber)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                VStack(alignment: .leading, spacing: 4) {
                    Text(weekday)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    Text(monthYear)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                }

                Spacer()
            }
        }
    }

    // MARK: - Week Info Card

    private var weekInfoCard: some View {
        let weekNumber = WeekCalculator.shared.weekNumber(for: Date())
        let daysLeft = daysLeftInWeek()

        return DashboardCard(title: "WEEK", icon: "calendar.badge.clock", accentColor: JohoColors.cyan) {
            VStack(spacing: JohoDimensions.spacingSM) {
                Text("W\(weekNumber)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                Text("\(daysLeft) days left")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Year Progress Card

    private var yearProgressCard: some View {
        let calendar = Calendar.iso8601
        let today = Date()
        let year = calendar.component(.year, from: today)
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        let totalDays = calendar.dateComponents([.day], from: startOfYear, to: endOfYear).day!
        let daysPassed = calendar.dateComponents([.day], from: startOfYear, to: today).day!
        let progress = Double(daysPassed) / Double(totalDays)

        return DashboardCard(title: "YEAR", icon: "chart.bar.fill", accentColor: JohoColors.green) {
            VStack(spacing: JohoDimensions.spacingSM) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(JohoColors.black.opacity(0.1))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(JohoColors.green)
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(totalDays - daysPassed) days left in \(year)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Upcoming Holidays Card

    private var upcomingHolidaysCard: some View {
        let upcomingHolidays = getUpcomingHolidays(limit: 3)

        return DashboardCard(title: "HOLIDAYS", icon: "star.fill", accentColor: JohoColors.pink) {
            if upcomingHolidays.isEmpty {
                Text("No upcoming holidays")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: JohoDimensions.spacingSM) {
                    ForEach(upcomingHolidays, id: \.name) { holiday in
                        HStack {
                            JohoIndicatorCircle(color: JohoColors.red, size: .small)

                            Text(holiday.name)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                                .lineLimit(1)

                            Spacer()

                            Text(daysUntilText(holiday.date))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Countdowns Card

    private var countdownsCard: some View {
        let countdowns = getUpcomingCountdowns(limit: 3)

        return DashboardCard(title: "COUNTDOWNS", icon: "timer", accentColor: JohoColors.orange) {
            if countdowns.isEmpty {
                Text("No countdowns set")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: JohoDimensions.spacingSM) {
                    ForEach(countdowns, id: \.name) { countdown in
                        HStack {
                            JohoIndicatorCircle(color: JohoColors.orange, size: .small)

                            Text(countdown.name)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                                .lineLimit(1)

                            Spacer()

                            Text("\(countdown.days)d")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.orange)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Notes Card

    private var recentNotesCard: some View {
        let recentNotes = Array(allNotes.prefix(3))

        return DashboardCard(title: "NOTES", icon: "note.text", accentColor: JohoColors.cream) {
            if recentNotes.isEmpty {
                Text("No notes yet")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: JohoDimensions.spacingSM) {
                    ForEach(recentNotes) { note in
                        HStack {
                            JohoIndicatorCircle(color: JohoColors.yellow, size: .small)

                            Text(note.content.prefix(30) + (note.content.count > 30 ? "..." : ""))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                                .lineLimit(1)

                            Spacer()

                            Text(note.date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.5))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Expense Summary Card

    private var expenseSummaryCard: some View {
        let thisMonth = getThisMonthExpenses()
        let total = thisMonth.reduce(0) { $0 + $1.amount }

        return DashboardCard(title: "EXPENSES", icon: "dollarsign.circle", accentColor: JohoColors.green) {
            VStack(spacing: JohoDimensions.spacingSM) {
                Text(formatCurrency(total))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                Text("this month")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.6))

                Text("\(thisMonth.count) transaction\(thisMonth.count == 1 ? "" : "s")")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Active Trip Card

    private var activeTripCard: some View {
        guard let trip = activeTrips.first else {
            return AnyView(EmptyView())
        }

        let daysLeft = Calendar.iso8601.dateComponents([.day], from: Date(), to: trip.endDate).day ?? 0

        return AnyView(
            DashboardCard(title: "ACTIVE TRIP", icon: "airplane", accentColor: JohoColors.orange) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.tripName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black)

                        Text(trip.destination)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.7))
                    }

                    Spacer()

                    VStack {
                        Text("\(max(0, daysLeft))")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(JohoColors.orange)

                        Text("days left")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                }
            }
        )
    }

    // MARK: - Helper Functions

    private func daysLeftInWeek() -> Int {
        let calendar = Calendar.iso8601
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // ISO week: Monday = 2, Sunday = 1
        // Days until Sunday (end of week)
        let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
        return 7 - adjustedWeekday
    }

    private func getUpcomingHolidays(limit: Int) -> [(name: String, date: Date)] {
        let today = Calendar.iso8601.startOfDay(for: Date())

        var holidays: [(name: String, date: Date)] = []

        // Get holidays from HolidayManager cache
        for (date, cachedHolidays) in holidayManager.holidayCache {
            if date >= today {
                for holiday in cachedHolidays {
                    holidays.append((holiday.displayTitle, date))
                }
            }
        }

        // Sort by date and take first N
        return Array(holidays.sorted { $0.date < $1.date }.prefix(limit))
    }

    private func getUpcomingCountdowns(limit: Int) -> [(name: String, days: Int)] {
        var countdowns: [(name: String, days: Int)] = []

        // Add some predefined countdowns
        let calendar = Calendar.iso8601
        let today = Date()
        let year = calendar.component(.year, from: today)

        // New Year
        if let newYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) {
            let days = calendar.dateComponents([.day], from: today, to: newYear).day ?? 0
            if days > 0 {
                countdowns.append(("New Year \(year + 1)", days))
            }
        }

        return Array(countdowns.sorted { $0.days < $1.days }.prefix(limit))
    }

    private func getThisMonthExpenses() -> [ExpenseItem] {
        let calendar = Calendar.iso8601
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!

        return allExpenses.filter { $0.date >= startOfMonth }
    }

    private func daysUntilText(_ date: Date) -> String {
        let days = Calendar.iso8601.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "\(days) days"
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Dashboard Card Component

private struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with icon zone
            HStack(spacing: JohoDimensions.spacingSM) {
                // Icon zone - 情報デザイン: Colored icon zone
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 28, height: 28)
                    .background(accentColor.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
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

            // Divider
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // Content
            content
                .padding(JohoDimensions.spacingMD)
        }
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: JohoDimensions.radiusMedium, style: .continuous)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }
}

// MARK: - Preview

#Preview("Dashboard - Portrait") {
    DashboardView()
        .frame(width: 820, height: 1180)
}

#Preview("Dashboard - Landscape") {
    DashboardView()
        .frame(width: 1180, height: 820)
}
