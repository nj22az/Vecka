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
    @Environment(\.johoColorMode) private var colorMode
    @Query(sort: \Memo.date, order: .reverse) private var allMemos: [Memo]

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    @State private var showAddTrip = false
    @State private var selectedTrip: Memo?

    /// Filtered trips from Memo
    private var allTrips: [Memo] {
        allMemos.filter { $0.type == .trip }
    }

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
                if activeTrips.isNotEmpty {
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "ACTIVE", style: .whiteOnBlack, size: .medium)
                            .padding(.horizontal, JohoDimensions.spacingLG)

                        ForEach(activeTrips, id: \.id) { trip in
                            MemoTripRow(memo: trip, status: "ACTIVE")
                                .padding(.horizontal, JohoDimensions.spacingLG)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                                .accessibilityLabel("\(trip.text), active trip to \(trip.place ?? "")")
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                }

                // Upcoming trips section
                if upcomingTrips.isNotEmpty {
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "UPCOMING", style: .whiteOnBlack, size: .medium)
                            .padding(.horizontal, JohoDimensions.spacingLG)

                        ForEach(upcomingTrips, id: \.id) { trip in
                            MemoTripRow(memo: trip, status: "UPCOMING")
                                .padding(.horizontal, JohoDimensions.spacingLG)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                                .accessibilityLabel("\(trip.text), upcoming trip to \(trip.place ?? "")")
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                }

                // Past trips section
                if pastTrips.isNotEmpty {
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "PAST", style: .whiteOnBlack, size: .medium)
                            .padding(.horizontal, JohoDimensions.spacingLG)

                        ForEach(pastTrips, id: \.id) { trip in
                            MemoTripRow(memo: trip, status: "PAST")
                                .padding(.horizontal, JohoDimensions.spacingLG)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                                .accessibilityLabel("\(trip.text), past trip to \(trip.place ?? "")")
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
                    .padding(.top, JohoDimensions.spacingSM)
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
                MemoTripDetailView(memo: trip)
            }
        }
    }

    // MARK: - Helpers

    private var activeTrips: [Memo] {
        let now = Date()
        return allTrips.filter { memo in
            guard let endDate = memo.tripEndDate else { return false }
            return memo.date <= now && endDate >= now
        }
    }

    private var upcomingTrips: [Memo] {
        let now = Date()
        return allTrips.filter { $0.date > now }.sorted(by: { $0.date < $1.date })
    }

    private var pastTrips: [Memo] {
        let now = Date()
        return allTrips.filter { memo in
            guard let endDate = memo.tripEndDate else { return false }
            return endDate < now
        }
    }

    private func delete(_ trip: Memo) {
        modelContext.delete(trip)
        try? modelContext.save()
    }
}

// MARK: - Subviews

/// Trip row using Memo model
struct MemoTripRow: View {
    let memo: Memo
    var status: String = ""
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private var durationText: String {
        guard let duration = memo.tripDuration else { return "0d" }
        return "\(duration)d"
    }

    var body: some View {
        JohoCard {
            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                // Top row: Status pill and duration
                HStack {
                    if status.isNotEmpty {
                        JohoPill(text: status, style: .colored(SectionZone.trips.background), size: .small)
                    }

                    Spacer()

                    JohoPill(text: durationText, style: .whiteOnBlack, size: .small)
                }

                // Trip name
                Text(memo.text)
                    .font(JohoFont.headline)
                    .foregroundStyle(colors.primary)

                // Destination
                if let destination = memo.place {
                    HStack(spacing: JohoDimensions.spacingXS) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.6))

                        Text(destination)
                            .font(JohoFont.body)
                            .foregroundStyle(colors.primary.opacity(0.8))
                    }
                }

                // Date range
                if let endDate = memo.tripEndDate {
                    HStack(spacing: JohoDimensions.spacingXS) {
                        Text(memo.date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(colors.primary.opacity(0.6))

                        Text("→")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(colors.primary.opacity(0.6))

                        Text(endDate.formatted(.dateTime.month(.abbreviated).day()))
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(colors.primary.opacity(0.6))
                    }
                }

                // Trip type/purpose
                if let purpose = memo.tripPurpose, !purpose.isEmpty {
                    JohoPill(text: purpose, style: .blackOnWhite, size: .small)
                }
            }
        }
    }
}

/// Trip detail view using Memo model
struct MemoTripDetailView: View {
    let memo: Memo
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // 情報デザイン: Status bar safe zone
                Spacer().frame(height: 44)

                // Page header
                JohoPageHeader(
                    title: memo.text,
                    badge: "TRIP DETAILS"
                )
                .padding(.horizontal, JohoDimensions.spacingLG)

                // Trip Info Section
                JohoSectionBox(title: "Trip Info", zone: .trips) {
                    VStack(spacing: JohoDimensions.spacingSM) {
                        // Destination
                        if let destination = memo.place {
                            HStack {
                                Text("Destination")
                                    .font(JohoFont.body)
                                    .foregroundStyle(colors.primary)
                                Spacer()
                                Text(destination)
                                    .font(JohoFont.body)
                                    .foregroundStyle(colors.primary)
                                    .bold()
                            }

                            JohoDivider()
                        }

                        // Duration
                        if let duration = memo.tripDuration {
                            HStack {
                                Text("Duration")
                                    .font(JohoFont.body)
                                    .foregroundStyle(colors.primary)
                                Spacer()
                                Text("\(duration) days")
                                    .font(JohoFont.monoMedium)
                                    .foregroundStyle(colors.primary)
                            }

                            JohoDivider()
                        }

                        // Date range
                        if let endDate = memo.tripEndDate {
                            VStack(spacing: JohoDimensions.spacingXS) {
                                HStack {
                                    Text("Start")
                                        .font(JohoFont.bodySmall)
                                        .foregroundStyle(colors.primary.opacity(0.7))
                                    Spacer()
                                    Text(memo.date.formatted(.dateTime.month(.abbreviated).day().year()))
                                        .font(JohoFont.monoMedium)
                                        .foregroundStyle(colors.primary)
                                }

                                HStack {
                                    Text("End")
                                        .font(JohoFont.bodySmall)
                                        .foregroundStyle(colors.primary.opacity(0.7))
                                    Spacer()
                                    Text(endDate.formatted(.dateTime.month(.abbreviated).day().year()))
                                        .font(JohoFont.monoMedium)
                                        .foregroundStyle(colors.primary)
                                }
                            }

                            JohoDivider()
                        }

                        // Trip type/purpose
                        if let purpose = memo.tripPurpose, !purpose.isEmpty {
                            HStack {
                                Text("Type")
                                    .font(JohoFont.body)
                                    .foregroundStyle(colors.primary)
                                Spacer()
                                JohoPill(text: purpose, style: .whiteOnBlack, size: .small)
                            }
                        }
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
            }
            .padding(.vertical, JohoDimensions.spacingLG)
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            HStack {
                Button { dismiss() } label: {
                    JohoActionButton(icon: "xmark")
                }
                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.top, JohoDimensions.spacingSM)
            .background(colors.canvas)
        }
    }
}

// MARK: - 情報デザイン Trip Editor Sheet (Standalone - like Event editor)

/// Standalone trip editor sheet matching the Event editor pattern
/// Used when creating trips from the + menu
struct JohoTripEditorSheet: View {
    let selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    @State private var name: String = ""
    @State private var destination: String = ""
    @State private var startYear: Int
    @State private var startMonth: Int
    @State private var startDay: Int
    @State private var endYear: Int
    @State private var endMonth: Int
    @State private var endDay: Int
    @State private var notes: String = ""

    private let calendar = Calendar.current

    // 情報デザイン: Trips use cyan (予定/place) color scheme
    private var tripAccentColor: Color { JohoColors.cyan }
    private var tripLightBackground: Color { JohoColors.cyanLight }

    private var canSave: Bool {
        !destination.trimmed.isEmpty
    }

    private var startDate: Date {
        let components = DateComponents(year: startYear, month: startMonth, day: startDay)
        return calendar.date(from: components) ?? Date()
    }

    private var endDate: Date {
        let components = DateComponents(year: endYear, month: endMonth, day: endDay)
        return calendar.date(from: components) ?? Date()
    }

    private var yearRange: [Int] {
        let current = calendar.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }

    init(selectedDate: Date = Date()) {
        self.selectedDate = selectedDate
        let calendar = Calendar.current
        let endDateDefault = calendar.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate

        _startYear = State(initialValue: calendar.component(.year, from: selectedDate))
        _startMonth = State(initialValue: calendar.component(.month, from: selectedDate))
        _startDay = State(initialValue: calendar.component(.day, from: selectedDate))
        _endYear = State(initialValue: calendar.component(.year, from: endDateDefault))
        _endMonth = State(initialValue: calendar.component(.month, from: endDateDefault))
        _endDay = State(initialValue: calendar.component(.day, from: endDateDefault))
    }

    var body: some View {
        // 情報デザイン: UNIFIED BENTO PILLBOX - entire editor is one compartmentalized box
        VStack(spacing: 0) {
            Spacer().frame(height: JohoDimensions.spacingLG)

            // UNIFIED BENTO CONTAINER
            VStack(spacing: 0) {
                // ═══════════════════════════════════════════════════════════════
                // HEADER ROW: [<] | [icon] Title/Subtitle | [Save]
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Back button (44pt)
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .johoTouchTarget()
                    }

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Icon + Title/Subtitle
                    HStack(spacing: JohoDimensions.spacingSM) {
                        // Type icon in colored box
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(tripAccentColor)
                            .frame(width: 36, height: 36)
                            .background(tripLightBackground)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(colors.border, lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("NEW TRIP")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(colors.primary)
                            Text("Set destination & dates")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.6))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                    .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // RIGHT: Save button (72pt)
                    Button {
                        saveTrip()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(canSave ? colors.surface : colors.primary.opacity(0.4))
                            .frame(width: 56, height: 32)
                            .background(canSave ? tripAccentColor : colors.surface)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(colors.border, lineWidth: 1.5))
                    }
                    .disabled(!canSave)
                    .frame(width: 72)
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 56)
                .background(tripAccentColor.opacity(0.7))  // 情報デザイン: Darker header like Month Page sections

                // Thick divider after header
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // DESTINATION ROW: [📍] | Destination text field
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Location icon (40pt)
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(tripAccentColor)
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Destination field
                    TextField("Where are you going?", text: $destination)
                        .font(JohoFont.body)
                        .foregroundStyle(colors.primary)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 48)
                .background(tripLightBackground)

                // Row divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // NAME ROW: [●] | Trip name (optional)
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Type indicator dot (40pt)
                    Circle()
                        .fill(tripAccentColor)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Name field (optional)
                    TextField("Trip name (optional)", text: $name)
                        .font(JohoFont.body)
                        .foregroundStyle(colors.primary)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 48)
                .background(tripLightBackground)

                // Row divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // START DATE ROW: [📅] | Year | Month | Day (compartmentalized)
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Calendar icon (40pt)
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // YEAR compartment
                    Menu {
                        ForEach(yearRange, id: \.self) { year in
                            Button { startYear = year } label: { Text(String(year)) }
                        }
                    } label: {
                        Text(String(startYear))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // MONTH compartment
                    Menu {
                        ForEach(1...12, id: \.self) { month in
                            Button { startMonth = month } label: { Text(monthName(month)) }
                        }
                    } label: {
                        Text(monthName(startMonth))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // DAY compartment
                    Menu {
                        ForEach(1...daysInMonth(startMonth, year: startYear), id: \.self) { day in
                            Button { startDay = day } label: { Text("\(day)") }
                        }
                    } label: {
                        Text("\(startDay)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(colors.primary)
                            .frame(width: 44)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(height: 48)
                .background(tripLightBackground)

                // Row divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // END DATE ROW: [📅] | Year | Month | Day (compartmentalized)
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Calendar icon (40pt)
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // YEAR compartment
                    Menu {
                        ForEach(yearRange, id: \.self) { year in
                            Button { endYear = year } label: { Text(String(year)) }
                        }
                    } label: {
                        Text(String(endYear))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // MONTH compartment
                    Menu {
                        ForEach(1...12, id: \.self) { month in
                            Button { endMonth = month } label: { Text(monthName(month)) }
                        }
                    } label: {
                        Text(monthName(endMonth))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // DAY compartment
                    Menu {
                        ForEach(1...daysInMonth(endMonth, year: endYear), id: \.self) { day in
                            Button { endDay = day } label: { Text("\(day)") }
                        }
                    } label: {
                        Text("\(endDay)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(colors.primary)
                            .frame(width: 44)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(height: 48)
                .background(tripLightBackground)

                // Row divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // NOTES ROW: [icon] | Notes text field (optional)
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Notes icon (40pt)
                    Image(systemName: "note.text")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(tripAccentColor)
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Notes field
                    TextField("Notes (optional)", text: $notes)
                        .font(JohoFont.body)
                        .foregroundStyle(colors.primary)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 48)
                .background(tripLightBackground)
            }
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
            )
            .padding(.horizontal, JohoDimensions.spacingLG)

            Spacer()
        }
        .johoBackground()
        .navigationBarHidden(true)
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let components = DateComponents(year: 2024, month: month, day: 1)
        let tempDate = calendar.date(from: components) ?? Date()
        return formatter.string(from: tempDate)
    }

    private func daysInMonth(_ month: Int, year: Int) -> Int {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let tempDate = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: tempDate) else {
            return 31
        }
        return range.count
    }

    private func saveTrip() {
        let trimmedDestination = destination.trimmed
        guard !trimmedDestination.isEmpty else { return }

        // Create trip as Memo - just destination + dates, optionally notes
        let memo = Memo.trip(
            name.isEmpty ? trimmedDestination : name,
            startDate: startDate,
            endDate: endDate,
            destination: trimmedDestination,
            purpose: notes.trimmed.isEmpty ? nil : notes.trimmed
        )
        modelContext.insert(memo)

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
