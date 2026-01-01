//
//  OverviewDashboardView.swift
//  Vecka
//
//  Comprehensive overview dashboard showing summary of all user data
//  Design: Japanese packaging style with zone-based color coding
//

import SwiftUI
import SwiftData

struct OverviewDashboardView: View {
    @Environment(\.modelContext) private var modelContext

    // Data queries
    @Query(sort: \TravelTrip.startDate, order: .forward) private var allTrips: [TravelTrip]
    @Query(sort: \ExpenseItem.date, order: .reverse) private var allExpenses: [ExpenseItem]
    @Query(sort: \DailyNote.date, order: .reverse) private var allNotes: [DailyNote]
    @Query(sort: \CountdownEvent.targetDate) private var allCountdowns: [CountdownEvent]

    @State private var showPDFExport = false

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    // Current week number
    private var currentWeekNumber: Int {
        Calendar.iso8601.component(.weekOfYear, from: Date())
    }

    // Computed properties
    private var upcomingTrips: [TravelTrip] {
        let now = Date()
        return allTrips.filter { $0.startDate >= now }.prefix(2).map { $0 }
    }

    private var activeTrips: [TravelTrip] {
        let now = Date()
        return allTrips.filter { $0.startDate <= now && $0.endDate >= now }
    }

    private var recentExpenses: [ExpenseItem] {
        Array(allExpenses.prefix(5))
    }

    private var todayNotes: [DailyNote] {
        let calendar = Calendar.iso8601
        let today = calendar.startOfDay(for: Date())
        return Array(allNotes.filter { calendar.isDate($0.date, inSameDayAs: today) })
    }

    private var activeCountdowns: [CountdownEvent] {
        Array(allCountdowns.filter { $0.targetDate >= Date() }.prefix(3))
    }

    private var todayHolidays: [HolidayCacheItem] {
        let calendar = Calendar.iso8601
        let today = calendar.startOfDay(for: Date())
        return HolidayManager.shared.holidayCache[today] ?? []
    }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Page Header with Share Button
                HStack(alignment: .top) {
                    JohoPageHeader(
                        title: "Week \(currentWeekNumber)",
                        badge: "OVERVIEW",
                        subtitle: Date().formatted(date: .complete, time: .omitted)
                    )

                    Spacer()

                    // Share button
                    Button {
                        showPDFExport = true
                    } label: {
                        JohoActionButton(icon: "square.and.arrow.up")
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)
                .safeAreaPadding(.top)

                // Active Trips (if any)
                if !activeTrips.isEmpty {
                    activeTripCards
                }

                // Upcoming Trips
                if !upcomingTrips.isEmpty {
                    upcomingTripsCard
                }

                // Recent Expenses
                if !recentExpenses.isEmpty {
                    recentExpensesCard
                }

                // Today's Notes
                if !todayNotes.isEmpty {
                    todayNotesCard
                }

                // Active Countdowns
                if !activeCountdowns.isEmpty {
                    countdownsCard
                }

                // Today's Holidays
                if !todayHolidays.isEmpty {
                    holidaysCard
                }

                // Empty State
                if activeTrips.isEmpty && upcomingTrips.isEmpty &&
                   recentExpenses.isEmpty && todayNotes.isEmpty &&
                   activeCountdowns.isEmpty && todayHolidays.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.bottom, JohoDimensions.spacingLG)
        }
        .johoBackground()
        .sheet(isPresented: $showPDFExport) {
            OverviewPDFExportSheet(
                weekNumber: currentWeekNumber,
                activeTrips: activeTrips,
                upcomingTrips: upcomingTrips,
                recentExpenses: recentExpenses,
                todayNotes: todayNotes,
                activeCountdowns: activeCountdowns,
                todayHolidays: todayHolidays
            )
        }
    }

    // MARK: - Active Trips

    private var activeTripCards: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            ForEach(activeTrips) { trip in
                NavigationLink(destination: TripDetailView(trip: trip)) {
                    JohoSectionBox(title: "Active Trip", zone: .trips, icon: "airplane.departure") {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                            // Trip name and destination
                            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                                Text(trip.tripName)
                                    .font(JohoFont.headline)
                                    .foregroundStyle(JohoColors.black)

                                Text(trip.destination)
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(JohoColors.black.opacity(0.7))
                            }

                            // Progress
                            HStack {
                                JohoPill(
                                    text: "Day \(daysIntoTrip(trip)) of \(trip.duration)",
                                    style: .whiteOnBlack,
                                    size: .medium
                                )

                                Spacer()
                            }

                            // Date range
                            Text("\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) - \(trip.endDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(JohoFont.bodySmall)
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Upcoming Trips

    private var upcomingTripsCard: some View {
        JohoSectionBox(title: "Upcoming Trips", zone: .trips, icon: "airplane") {
            VStack(spacing: JohoDimensions.spacingSM) {
                ForEach(upcomingTrips) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        JohoCard(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderThin) {
                            HStack(spacing: JohoDimensions.spacingMD) {
                                // Icon
                                JohoIconBadge(icon: "airplane.departure", zone: .trips, size: 36)

                                // Content
                                VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                                    Text(trip.tripName)
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)

                                    Text(trip.destination)
                                        .font(JohoFont.bodySmall)
                                        .foregroundStyle(JohoColors.black.opacity(0.6))

                                    Text(trip.startDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(JohoFont.bodySmall)
                                        .foregroundStyle(JohoColors.black.opacity(0.5))
                                }

                                Spacer()

                                // Days until
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(daysUntil(trip.startDate))
                                        .font(JohoFont.monoMedium)
                                        .foregroundStyle(JohoColors.black)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    if trip.id != upcomingTrips.last?.id {
                        JohoDivider()
                    }
                }
            }
        }
    }

    // MARK: - Recent Expenses

    private var recentExpensesCard: some View {
        JohoSectionBox(title: "Recent Expenses", zone: .expenses, icon: "creditcard") {
            VStack(spacing: JohoDimensions.spacingSM) {
                ForEach(recentExpenses) { expense in
                    JohoCard(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderThin) {
                        HStack(spacing: JohoDimensions.spacingMD) {
                            // Icon
                            if let category = expense.category {
                                JohoIconBadge(icon: category.iconName, zone: .expenses, size: 36)
                            } else {
                                JohoIconBadge(icon: "creditcard", zone: .expenses, size: 36)
                            }

                            // Content
                            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                                Text(expense.itemDescription)
                                    .font(JohoFont.body)
                                    .foregroundStyle(JohoColors.black)
                                    .lineLimit(1)

                                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(JohoColors.black.opacity(0.6))
                            }

                            Spacer()

                            // Amount
                            Text(expense.amount, format: .currency(code: expense.currency))
                                .font(JohoFont.monoMedium)
                                .foregroundStyle(JohoColors.black)
                        }
                    }

                    if expense.id != recentExpenses.last?.id {
                        JohoDivider()
                    }
                }
            }
        }
    }

    // MARK: - Today's Notes

    private var todayNotesCard: some View {
        JohoSectionBox(title: "Today's Notes", zone: .notes, icon: "note.text") {
            VStack(spacing: JohoDimensions.spacingSM) {
                ForEach(todayNotes, id: \.date) { note in
                    JohoCard(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderThin) {
                        HStack(spacing: JohoDimensions.spacingMD) {
                            // Icon
                            if let symbolName = note.symbolName {
                                JohoIconBadge(icon: symbolName, zone: .notes, size: 36)
                            } else {
                                JohoIconBadge(icon: "note.text", zone: .notes, size: 36)
                            }

                            // Content
                            Text(note.content)
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black)
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if note.date != todayNotes.last?.date {
                        JohoDivider()
                    }
                }
            }
        }
    }

    // MARK: - Countdowns

    private var countdownsCard: some View {
        JohoSectionBox(title: "Active Countdowns", zone: .calendar, icon: "timer") {
            VStack(spacing: JohoDimensions.spacingSM) {
                ForEach(activeCountdowns, id: \.id) { countdown in
                    JohoCard(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderThin) {
                        HStack(spacing: JohoDimensions.spacingMD) {
                            // Icon
                            JohoIconBadge(icon: countdown.icon, zone: .calendar, size: 36)

                            // Content
                            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                                Text(countdown.title)
                                    .font(JohoFont.body)
                                    .foregroundStyle(JohoColors.black)

                                Text(countdown.targetDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(JohoColors.black.opacity(0.6))
                            }

                            Spacer()

                            // Days until
                            Text(daysUntil(countdown.targetDate))
                                .font(JohoFont.monoMedium)
                                .foregroundStyle(JohoColors.black)
                        }
                    }

                    if countdown.id != activeCountdowns.last?.id {
                        JohoDivider()
                    }
                }
            }
        }
    }

    // MARK: - Holidays

    private var holidaysCard: some View {
        JohoSectionBox(title: "Today's Holidays", zone: .holidays, icon: "star.fill") {
            VStack(spacing: JohoDimensions.spacingSM) {
                ForEach(todayHolidays, id: \.id) { holiday in
                    JohoCard(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderThin) {
                        HStack(spacing: JohoDimensions.spacingMD) {
                            // Icon
                            JohoIconBadge(
                                icon: holiday.isRedDay ? "flag.fill" : "flag",
                                zone: .holidays,
                                size: 36
                            )

                            // Content
                            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                                Text(holiday.displayTitle)
                                    .font(JohoFont.body)
                                    .foregroundStyle(JohoColors.black)

                                Text(holiday.isRedDay ? "Public Holiday" : "Observance")
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(JohoColors.black.opacity(0.6))
                            }

                            Spacer()

                            // Badge for red days
                            if holiday.isRedDay {
                                JohoPill(text: "RED DAY", style: .colored(JohoColors.pink), size: .small)
                            }
                        }
                    }

                    if holiday.id != todayHolidays.last?.id {
                        JohoDivider()
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        JohoEmptyState(
            title: "No Recent Activity",
            message: "Your trips, expenses, and notes will appear here",
            icon: "tray",
            zone: .calendar
        )
    }

    // MARK: - Helper Methods

    private func daysUntil(_ date: Date) -> String {
        let calendar = Calendar.iso8601
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: date)).day ?? 0

        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days < 7 {
            return "In \(days) days"
        } else {
            let weeks = days / 7
            return "In \(weeks) week\(weeks > 1 ? "s" : "")"
        }
    }

    private func daysIntoTrip(_ trip: TravelTrip) -> Int {
        let calendar = Calendar.iso8601
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: trip.startDate), to: calendar.startOfDay(for: Date())).day ?? 0
        return days + 1
    }
}

// MARK: - Overview PDF Export Sheet

struct OverviewPDFExportSheet: View {
    @Environment(\.dismiss) private var dismiss

    let weekNumber: Int
    let activeTrips: [TravelTrip]
    let upcomingTrips: [TravelTrip]
    let recentExpenses: [ExpenseItem]
    let todayNotes: [DailyNote]
    let activeCountdowns: [CountdownEvent]
    let todayHolidays: [HolidayCacheItem]

    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: JohoDimensions.spacingLG) {
                    // Header
                    JohoPageHeader(
                        title: "Week \(weekNumber) Overview",
                        badge: "EXPORT",
                        subtitle: Date().formatted(date: .complete, time: .omitted)
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)

                    // Summary Stats
                    HStack(spacing: JohoDimensions.spacingSM) {
                        JohoStatBox(value: String(activeTrips.count + upcomingTrips.count), label: "Trips", zone: .trips)
                        JohoStatBox(value: String(recentExpenses.count), label: "Expenses", zone: .expenses)
                        JohoStatBox(value: String(todayNotes.count), label: "Notes", zone: .notes)
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)

                    // Trips Section
                    if !activeTrips.isEmpty || !upcomingTrips.isEmpty {
                        JohoSectionBox(title: "TRIPS", zone: .trips, icon: "airplane") {
                            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                                ForEach(activeTrips + upcomingTrips) { trip in
                                    HStack {
                                        Text(trip.tripName)
                                            .font(JohoFont.body)
                                            .foregroundStyle(JohoColors.black)
                                        Spacer()
                                        Text(trip.destination)
                                            .font(JohoFont.bodySmall)
                                            .foregroundStyle(JohoColors.black.opacity(0.7))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, JohoDimensions.spacingLG)
                    }

                    // Expenses Section
                    if !recentExpenses.isEmpty {
                        JohoSectionBox(title: "RECENT EXPENSES", zone: .expenses, icon: "creditcard") {
                            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                                ForEach(recentExpenses) { expense in
                                    HStack {
                                        Text(expense.itemDescription)
                                            .font(JohoFont.body)
                                            .foregroundStyle(JohoColors.black)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(expense.amount, format: .currency(code: expense.currency))
                                            .font(JohoFont.monoMedium)
                                            .foregroundStyle(JohoColors.black)
                                    }
                                }

                                JohoDivider()

                                HStack {
                                    Text("Total")
                                        .font(JohoFont.headline)
                                        .foregroundStyle(JohoColors.black)
                                    Spacer()
                                    Text(totalExpenses, format: .currency(code: "SEK"))
                                        .font(JohoFont.monoMedium)
                                        .foregroundStyle(JohoColors.black)
                                }
                            }
                        }
                        .padding(.horizontal, JohoDimensions.spacingLG)
                    }

                    // Notes Section
                    if !todayNotes.isEmpty {
                        JohoSectionBox(title: "TODAY'S NOTES", zone: .notes, icon: "note.text") {
                            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                                ForEach(todayNotes, id: \.date) { note in
                                    Text(note.content)
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)
                                        .lineLimit(3)
                                }
                            }
                        }
                        .padding(.horizontal, JohoDimensions.spacingLG)
                    }

                    // Holidays Section
                    if !todayHolidays.isEmpty {
                        JohoSectionBox(title: "TODAY'S HOLIDAYS", zone: .holidays, icon: "star.fill") {
                            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                                ForEach(todayHolidays, id: \.id) { holiday in
                                    HStack {
                                        Text(holiday.displayTitle)
                                            .font(JohoFont.body)
                                            .foregroundStyle(JohoColors.black)
                                        Spacer()
                                        if holiday.isRedDay {
                                            JohoPill(text: "RED DAY", style: .colored(JohoColors.pink), size: .small)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, JohoDimensions.spacingLG)
                    }
                }
                .padding(.vertical, JohoDimensions.spacingLG)
            }
            .johoBackground()
            .navigationTitle("Export Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: generateTextSummary()) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(20)
    }

    private var totalExpenses: Double {
        recentExpenses.reduce(0.0) { $0 + $1.amount }
    }

    private func generateTextSummary() -> String {
        var summary = """
        📅 WEEK \(weekNumber) OVERVIEW
        \(Date().formatted(date: .complete, time: .omitted))

        """

        if !activeTrips.isEmpty || !upcomingTrips.isEmpty {
            summary += "\n✈️ TRIPS\n"
            for trip in activeTrips + upcomingTrips {
                summary += "• \(trip.tripName) - \(trip.destination)\n"
            }
        }

        if !recentExpenses.isEmpty {
            summary += "\n💰 RECENT EXPENSES\n"
            for expense in recentExpenses {
                summary += "• \(expense.itemDescription): \(expense.amount) \(expense.currency)\n"
            }
            summary += "Total: \(String(format: "%.2f", totalExpenses)) SEK\n"
        }

        if !todayNotes.isEmpty {
            summary += "\n📝 TODAY'S NOTES\n"
            for note in todayNotes {
                let preview = String(note.content.prefix(100))
                summary += "• \(preview)\n"
            }
        }

        if !todayHolidays.isEmpty {
            summary += "\n⭐ TODAY'S HOLIDAYS\n"
            for holiday in todayHolidays {
                summary += "• \(holiday.displayTitle)\(holiday.isRedDay ? " (Red Day)" : "")\n"
            }
        }

        summary += "\n---\nGenerated by WeekGrid"

        return summary
    }
}

#Preview {
    NavigationStack {
        OverviewDashboardView()
            .modelContainer(for: [TravelTrip.self, ExpenseItem.self, DailyNote.self, CountdownEvent.self], inMemory: true)
    }
}
