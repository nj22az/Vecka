//
//  OverviewDashboardView.swift
//  Vecka
//
//  Comprehensive overview dashboard showing summary of all user data
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
            VStack(spacing: isPad ? 24 : 20) {
                // Header
                header

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
            .padding(isPad ? 24 : 16)
        }
        .navigationTitle("Overview")
        .background(AppColors.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPDFExport = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showPDFExport) {
            SimplePDFExportView(exportContext: .summary)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    Text("Week \(Calendar.iso8601.component(.weekOfYear, from: Date()))")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.accentBlue)
                }

                Spacer()
            }
            .padding()
            .glassCard(cornerRadius: 16, material: .ultraThinMaterial)
        }
    }

    // MARK: - Active Trips

    private var activeTripCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Trips")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.extraSmall)

            ForEach(activeTrips) { trip in
                NavigationLink(destination: TripDetailView(trip: trip)) {
                    HStack(spacing: 12) {
                        Image(systemName: "airplane.departure")
                            .font(.title2)
                            .foregroundStyle(trip.tripType.color)
                            .frame(width: 44, height: 44)
                            .background(trip.tripType.color.opacity(0.1))
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.tripName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text(trip.destination)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Day \(daysIntoTrip(trip))/\(trip.duration)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppColors.accentBlue)
                        }
                    }
                    .padding()
                    .glassCard(cornerRadius: 16, material: .ultraThinMaterial)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Upcoming Trips

    private var upcomingTripsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Trips")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                NavigationLink(destination: TripListView()) {
                    Text("See All")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppColors.accentBlue)
                }
            }
            .padding(.horizontal, Spacing.extraSmall)

            ForEach(upcomingTrips) { trip in
                NavigationLink(destination: TripDetailView(trip: trip)) {
                    HStack(spacing: 12) {
                        Image(systemName: "airplane.departure")
                            .font(.title3)
                            .foregroundStyle(trip.tripType.color)
                            .frame(width: 40, height: 40)
                            .background(trip.tripType.color.opacity(0.1))
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.tripName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)

                            Text(trip.destination)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(daysUntil(trip.startDate))
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(trip.startDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding()
                    .glassCard(cornerRadius: 12, material: .ultraThinMaterial)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Recent Expenses

    private var recentExpensesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Expenses")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                NavigationLink(destination: ExpenseListView()) {
                    Text("See All")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppColors.accentBlue)
                }
            }
            .padding(.horizontal, Spacing.extraSmall)

            VStack(spacing: 8) {
                ForEach(recentExpenses) { expense in
                    HStack(spacing: 12) {
                        if let category = expense.category {
                            Image(systemName: category.iconName)
                                .font(.body)
                                .foregroundStyle(category.color)
                                .frame(width: 32, height: 32)
                                .background(category.color.opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            Image(systemName: "creditcard")
                                .font(.body)
                                .foregroundStyle(.green)
                                .frame(width: 32, height: 32)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(expense.itemDescription)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(expense.amount, format: .currency(code: expense.currency))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding()
            .glassCard(cornerRadius: 12, material: .ultraThinMaterial)
        }
    }

    // MARK: - Today's Notes

    private var todayNotesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Notes")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.extraSmall)

            VStack(spacing: 8) {
                ForEach(todayNotes, id: \.date) { note in
                    HStack(spacing: 8) {
                        if let symbolName = note.symbolName {
                            Image(systemName: symbolName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(note.content)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(Spacing.small)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
            .glassCard(cornerRadius: 12, material: .ultraThinMaterial)
        }
    }

    // MARK: - Countdowns

    private var countdownsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Events")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.extraSmall)

            VStack(spacing: 8) {
                ForEach(activeCountdowns, id: \.id) { countdown in
                    HStack(spacing: 12) {
                        Image(systemName: countdown.icon)
                            .font(.body)
                            .foregroundStyle(AppColors.accentBlue)
                            .frame(width: 32, height: 32)
                            .background(AppColors.accentBlue.opacity(0.1))
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(countdown.title)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)

                            Text(countdown.targetDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(daysUntil(countdown.targetDate))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.accentBlue)
                    }
                }
            }
            .padding()
            .glassCard(cornerRadius: 12, material: .ultraThinMaterial)
        }
    }

    // MARK: - Holidays

    private var holidaysCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Holidays")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.extraSmall)

            VStack(spacing: 8) {
                ForEach(todayHolidays, id: \.id) { holiday in
                    HStack(spacing: 12) {
                        Image(systemName: "flag.fill")
                            .font(.body)
                            .foregroundStyle(holiday.isRedDay ? .red : .blue)
                            .frame(width: 32, height: 32)
                            .background((holiday.isRedDay ? Color.red : Color.blue).opacity(0.1))
                            .cornerRadius(8)

                        Text(holiday.displayTitle)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                }
            }
            .padding()
            .glassCard(cornerRadius: 12, material: .ultraThinMaterial)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Recent Activity")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Your trips, expenses, and notes will appear here")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.extraLarge)
        .glassCard(cornerRadius: 16, material: .ultraThinMaterial)
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

#Preview {
    NavigationStack {
        OverviewDashboardView()
            .modelContainer(for: [TravelTrip.self, ExpenseItem.self, DailyNote.self, CountdownEvent.self], inMemory: true)
    }
}
