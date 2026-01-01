//
//  TripListView.swift
//  Vecka
//
//  List of all travel trips with Japanese Jōhō Dezain styling.
//

import SwiftUI
import SwiftData

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TravelTrip.startDate, order: .reverse) private var allTrips: [TravelTrip]

    @State private var showAddTrip = false
    @State private var selectedTrip: TravelTrip?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JohoDimensions.spacingLG) {
                // Page header with inline actions (情報デザイン)
                HStack(alignment: .top) {
                    JohoPageHeader(
                        title: "Travel Trips",
                        badge: "TRIPS"
                    )

                    Spacer()

                    Button {
                        showAddTrip = true
                    } label: {
                        JohoActionButton(icon: "plus")
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)

                // Active trips section
                if !activeTrips.isEmpty {
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "ACTIVE", style: .whiteOnBlack, size: .medium)
                            .padding(.horizontal, JohoDimensions.spacingLG)

                        ForEach(activeTrips, id: \.id) { trip in
                            TripRow(trip: trip, status: "ACTIVE")
                                .padding(.horizontal, JohoDimensions.spacingLG)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                                .accessibilityLabel("\(trip.tripName), active trip to \(trip.destination)")
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                }

                // Upcoming trips section
                if !upcomingTrips.isEmpty {
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "UPCOMING", style: .whiteOnBlack, size: .medium)
                            .padding(.horizontal, JohoDimensions.spacingLG)

                        ForEach(upcomingTrips, id: \.id) { trip in
                            TripRow(trip: trip, status: "UPCOMING")
                                .padding(.horizontal, JohoDimensions.spacingLG)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                                .accessibilityLabel("\(trip.tripName), upcoming trip to \(trip.destination)")
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                }

                // Past trips section
                if !pastTrips.isEmpty {
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "PAST", style: .whiteOnBlack, size: .medium)
                            .padding(.horizontal, JohoDimensions.spacingLG)

                        ForEach(pastTrips, id: \.id) { trip in
                            TripRow(trip: trip, status: "PAST")
                                .padding(.horizontal, JohoDimensions.spacingLG)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                                .accessibilityLabel("\(trip.tripName), past trip to \(trip.destination)")
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                }

                // Empty state
                if allTrips.isEmpty {
                    JohoEmptyState(
                        title: "No Trips",
                        message: "Tap + to add your first trip",
                        icon: "airplane.departure",
                        zone: .trips
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding(.vertical, JohoDimensions.spacingLG)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddTrip) {
            NavigationStack {
                AddTripView()
            }
        }
        .sheet(item: $selectedTrip) { trip in
            NavigationStack {
                TripDetailView(trip: trip)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var activeTrips: [TravelTrip] {
        let now = Date()
        return allTrips.filter { $0.startDate <= now && $0.endDate >= now }
    }
    
    private var upcomingTrips: [TravelTrip] {
        let now = Date()
        return allTrips.filter { $0.startDate > now }.sorted(by: { $0.startDate < $1.startDate })
    }
    
    private var pastTrips: [TravelTrip] {
        let now = Date()
        return allTrips.filter { $0.endDate < now }
    }
    
    private func delete(_ trip: TravelTrip) {
        modelContext.delete(trip)
        try? modelContext.save()
    }
}

// MARK: - Subviews

struct TripRow: View {
    let trip: TravelTrip
    var status: String = ""

    private var durationText: String {
        "\(trip.duration)d"
    }

    var body: some View {
        JohoCard {
            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                // Top row: Status pill and duration
                HStack {
                    if !status.isEmpty {
                        JohoPill(text: status, style: .colored(SectionZone.trips.background), size: .small)
                    }

                    Spacer()

                    JohoPill(text: durationText, style: .whiteOnBlack, size: .small)
                }

                // Trip name
                Text(trip.tripName)
                    .font(JohoFont.headline)
                    .foregroundStyle(JohoColors.black)

                // Destination
                HStack(spacing: JohoDimensions.spacingXS) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JohoColors.black.opacity(0.6))

                    Text(trip.destination)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black.opacity(0.8))
                }

                // Date range
                HStack(spacing: JohoDimensions.spacingXS) {
                    Text(trip.startDate.formatted(.dateTime.month(.abbreviated).day()))
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))

                    Text("→")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))

                    Text(trip.endDate.formatted(.dateTime.month(.abbreviated).day()))
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                // Trip type if not business
                if trip.tripType != .business {
                    JohoPill(text: trip.tripType.rawValue, style: .blackOnWhite, size: .small)
                }
            }
        }
    }
}

struct TripDetailView: View {
    let trip: TravelTrip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showExpenseList = false
    @State private var showMileageList = false
    @State private var showTripReport = false

    private var expenseCount: Int {
        trip.expenses?.count ?? 0
    }

    private var mileageCount: Int {
        trip.mileageEntries?.count ?? 0
    }

    private var totalMileage: Double {
        trip.mileageEntries?.reduce(0) { $0 + $1.totalDistance } ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Page header
                JohoPageHeader(
                    title: trip.tripName,
                    badge: "TRIP DETAILS"
                )
                .padding(.horizontal, JohoDimensions.spacingLG)

                // Trip Info Section
                JohoSectionBox(title: "Trip Info", zone: .trips, icon: "airplane.departure") {
                    VStack(spacing: JohoDimensions.spacingSM) {
                        // Destination
                        HStack {
                            Text("Destination")
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black)
                            Spacer()
                            Text(trip.destination)
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black)
                                .bold()
                        }

                        JohoDivider()

                        // Duration
                        HStack {
                            Text("Duration")
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black)
                            Spacer()
                            Text("\(trip.duration) days")
                                .font(JohoFont.monoMedium)
                                .foregroundStyle(JohoColors.black)
                        }

                        JohoDivider()

                        // Date range
                        VStack(spacing: JohoDimensions.spacingXS) {
                            HStack {
                                Text("Start")
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(JohoColors.black.opacity(0.7))
                                Spacer()
                                Text(trip.startDate.formatted(.dateTime.month(.abbreviated).day().year()))
                                    .font(JohoFont.monoMedium)
                                    .foregroundStyle(JohoColors.black)
                            }

                            HStack {
                                Text("End")
                                    .font(JohoFont.bodySmall)
                                    .foregroundStyle(JohoColors.black.opacity(0.7))
                                Spacer()
                                Text(trip.endDate.formatted(.dateTime.month(.abbreviated).day().year()))
                                    .font(JohoFont.monoMedium)
                                    .foregroundStyle(JohoColors.black)
                            }
                        }

                        JohoDivider()

                        // Trip type
                        HStack {
                            Text("Type")
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black)
                            Spacer()
                            JohoPill(text: trip.tripType.rawValue, style: .whiteOnBlack, size: .small)
                        }
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)

                // Stats Section
                HStack(spacing: JohoDimensions.spacingMD) {
                    // Expenses stat
                    Button {
                        showExpenseList = true
                    } label: {
                        JohoStatBox(
                            value: "\(expenseCount)",
                            label: "Expenses",
                            zone: .expenses
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Expenses: \(expenseCount) items")
                    .accessibilityHint("Double tap to view expense list")

                    // Mileage stat
                    Button {
                        showMileageList = true
                    } label: {
                        JohoStatBox(
                            value: "\(mileageCount)",
                            label: "Mileage",
                            zone: .trips
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Mileage: \(mileageCount) entries")
                    .accessibilityHint("Double tap to view mileage log")
                }
                .padding(.horizontal, JohoDimensions.spacingLG)

                // Expense total if any
                if expenseCount > 0 {
                    JohoSectionBox(title: "Total Expenses", zone: .expenses, icon: "creditcard.fill") {
                        Text(String(format: "%.0f SEK", trip.totalExpenses))
                            .font(JohoFont.displaySmall)
                            .foregroundStyle(JohoColors.black)
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                // Mileage total if any
                if mileageCount > 0 {
                    JohoSectionBox(title: "Total Distance", zone: .trips, icon: "car.fill") {
                        Text(String(format: "%.1f km", totalMileage))
                            .font(JohoFont.displaySmall)
                            .foregroundStyle(JohoColors.black)
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                // Generate Report Button
                Button {
                    showTripReport = true
                } label: {
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 18, weight: .bold))

                        Text("Generate Report")
                            .font(JohoFont.headline)
                    }
                    .foregroundStyle(JohoColors.white)
                    .frame(maxWidth: .infinity)
                    .padding(JohoDimensions.spacingMD)
                    .background(JohoColors.black)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, JohoDimensions.spacingLG)
                .accessibilityLabel("Generate trip report")
                .accessibilityHint("Double tap to create PDF report with expenses and mileage")
            }
            .padding(.vertical, JohoDimensions.spacingLG)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            // Inline close button (情報デザイン)
            HStack {
                Button { dismiss() } label: {
                    JohoActionButton(icon: "xmark")
                }
                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.top, JohoDimensions.spacingSM)
            .background(JohoColors.background)
        }
        .sheet(isPresented: $showExpenseList) {
            NavigationStack {
                ExpenseListView()
            }
        }
        // TODO: Restore MileageListView and TripReportPreviewView for database-driven architecture
        // .sheet(isPresented: $showMileageList) {
        //     NavigationStack {
        //         MileageListView(trip: trip)
        //     }
        // }
        // .sheet(isPresented: $showTripReport) {
        //     TripReportPreviewView(trip: trip)
        // }
    }
}

// MARK: - 情報デザイン Trip Editor Sheet (Standalone - like Event editor)

/// Standalone trip editor sheet matching the Event editor pattern
/// Used when creating trips from the + menu
struct JohoTripEditorSheet: View {
    let selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var destination: String = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var tripType: TripType = .business

    // Trip accent color - ORANGE from design system
    private let accentColor = Color(hex: "FED7AA")  // Orange for trips

    private var canSave: Bool {
        !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(selectedDate: Date = Date()) {
        self.selectedDate = selectedDate
        _startDate = State(initialValue: selectedDate)
        _endDate = State(initialValue: Calendar.iso8601.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Header with Cancel/Save buttons (情報デザイン style)
                HStack {
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, JohoDimensions.spacingMD)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    Spacer()

                    Button {
                        saveTrip()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(JohoFont.body.bold())
                            .foregroundStyle(canSave ? JohoColors.black : JohoColors.black.opacity(0.4))
                            .padding(.horizontal, JohoDimensions.spacingLG)
                            .padding(.vertical, JohoDimensions.spacingMD)
                            .background(canSave ? accentColor : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }
                    .disabled(!canSave)
                }
                .padding(.top, JohoDimensions.spacingLG)

                // Main content card
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Title with type indicator (情報デザイン)
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Circle()
                            .fill(Color(hex: "ED8936"))  // Solid orange
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
                        Text("New Trip")
                            .font(JohoFont.displaySmall)
                            .foregroundStyle(JohoColors.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Trip icon - 情報デザイン compartmentalized style
                    ZStack {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 64, height: 64)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 2.5))

                        Image(systemName: "airplane.departure")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(JohoColors.black)
                    }

                    // Destination field
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "DESTINATION", style: .whiteOnBlack, size: .small)

                        TextField("Where are you going?", text: $destination)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .padding(JohoDimensions.spacingMD)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    // Trip name field (optional)
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "NAME", style: .whiteOnBlack, size: .small)

                        TextField("Trip name (optional)", text: $name)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .padding(JohoDimensions.spacingMD)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    // Date range - 情報デザイン styled date buttons
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "DATES", style: .whiteOnBlack, size: .small)

                        HStack(spacing: JohoDimensions.spacingMD) {
                            // Start date - 情報デザイン button style
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FROM")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                johoDateButton(date: $startDate)
                            }

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(JohoColors.black)

                            // End date - 情報デザイン button style
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TO")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                johoDateButton(date: $endDate, minDate: startDate)
                            }
                        }
                    }

                    // Trip type picker - 情報デザイン segmented style
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "TYPE", style: .whiteOnBlack, size: .small)

                        HStack(spacing: 0) {
                            ForEach(Array([TripType.business, TripType.personal, TripType.mixed].enumerated()), id: \.element) { index, type in
                                Button {
                                    tripType = type
                                    HapticManager.selection()
                                } label: {
                                    Text(type.rawValue.uppercased())
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(tripType == type ? JohoColors.black : JohoColors.black.opacity(0.6))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, JohoDimensions.spacingMD)
                                        .background(tripType == type ? accentColor : JohoColors.white)
                                }

                                if index < 2 {
                                    Rectangle()
                                        .fill(JohoColors.black)
                                        .frame(width: JohoDimensions.borderMedium)
                                }
                            }
                        }
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                    }
                }
                .padding(JohoDimensions.spacingLG)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
    }

    // 情報デザイン date button with black border and high contrast
    @ViewBuilder
    private func johoDateButton(date: Binding<Date>, minDate: Date? = nil) -> some View {
        let dateRange: PartialRangeFrom<Date> = (minDate ?? Date.distantPast)...

        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(JohoColors.black)

            // Display the date as black text on white background for readability
            Text(date.wrappedValue.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)

            // Hidden date picker that opens on tap
            DatePicker("", selection: date, in: dateRange, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .scaleEffect(x: 0.01, y: 0.01)
                .frame(width: 1, height: 1)
                .clipped()
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingSM)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
        .overlay(
            // Invisible tap area that triggers the hidden DatePicker
            DatePicker("", selection: date, in: dateRange, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .colorMultiply(.clear)
        )
    }

    private func saveTrip() {
        let trimmedDestination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDestination.isEmpty else { return }

        let trip = TravelTrip(
            tripName: name.isEmpty ? trimmedDestination : name,
            destination: trimmedDestination,
            startDate: startDate,
            endDate: endDate,
            purpose: nil,
            tripType: tripType
        )
        modelContext.insert(trip)

        do {
            try modelContext.save()
            HapticManager.notification(.success)
        } catch {
            Log.w("Failed to save trip: \(error.localizedDescription)")
        }
    }
}

// Legacy AddTripView for backwards compatibility
struct AddTripView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        JohoTripEditorSheet()
    }
}
