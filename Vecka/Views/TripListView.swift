//
//  TripListView.swift
//  Vecka
//
//  List of all travel trips.
//

import SwiftUI
import SwiftData

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TravelTrip.startDate, order: .reverse) private var allTrips: [TravelTrip]
    
    @State private var showAddTrip = false
    @State private var selectedTrip: TravelTrip?
    
    var body: some View {
        // Note: This view is embedded in NavigationStack from parent (PhoneLibraryView)
        // Do NOT add NavigationStack here to avoid nested navigation issues
        List {
                if !activeTrips.isEmpty {
                    Section("Active") {
                        ForEach(activeTrips) { trip in
                            TripRow(trip: trip)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        delete(trip)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                
                if !upcomingTrips.isEmpty {
                    Section("Upcoming") {
                        ForEach(upcomingTrips) { trip in
                            TripRow(trip: trip)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        delete(trip)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                
                if !pastTrips.isEmpty {
                    Section("Past") {
                        ForEach(pastTrips) { trip in
                            TripRow(trip: trip)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        delete(trip)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                
                if allTrips.isEmpty {
                     ContentUnavailableView(
                        "No Trips",
                        systemImage: "airplane.departure",
                        description: Text("Tap + to add your first trip")
                    )
                }
            }
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddTrip = true
                    } label: {
                        Label("Add Trip", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTrip) {
                // We'll use a simple form for now or a dedicated TripEntryView if it exists
                // For this implementation, I'm assuming we might need to create a simple AddTripView 
                // or reusing an existing one. Since one doesn't exist, I'll put a placeholder here
                // or a simple inline form.
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(trip.tripName)
                    .font(.headline)
                Text(trip.destination)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(trip.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                Text(trip.endDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        // Note: This view is presented in a sheet with NavigationStack from parent
        ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "airplane.departure")
                                .font(.title2)
                                .foregroundStyle(trip.tripType.color)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(trip.tripName)
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)

                                Text(trip.destination)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Duration")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("\(trip.duration) days")
                                    .font(.body.weight(.medium))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(trip.startDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                Text(trip.endDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .glassCard(cornerRadius: 16, material: .ultraThinMaterial)

                    // Summary Cards
                    HStack(spacing: 16) {
                        // Expenses Card
                        Button {
                            showExpenseList = true
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "creditcard.fill")
                                    .font(.title)
                                    .foregroundStyle(.green)

                                Text("\(expenseCount)")
                                    .font(.title.bold())
                                    .foregroundStyle(.primary)

                                Text("Expenses")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if expenseCount > 0 {
                                    Text(String(format: "%.0f SEK", trip.totalExpenses))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.green)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .glassCard(cornerRadius: 16, material: .ultraThinMaterial)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Expenses: \(expenseCount) items")
                        .accessibilityHint("Double tap to view expense list")

                        // Mileage Card
                        Button {
                            showMileageList = true
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "car.fill")
                                    .font(.title)
                                    .foregroundStyle(AppColors.accentBlue)

                                Text("\(mileageCount)")
                                    .font(.title.bold())
                                    .foregroundStyle(.primary)

                                Text("Mileage")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if mileageCount > 0 {
                                    Text(String(format: "%.1f km", totalMileage))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppColors.accentBlue)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .glassCard(cornerRadius: 16, material: .ultraThinMaterial)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Mileage: \(mileageCount) entries")
                        .accessibilityHint("Double tap to view mileage log")
                    }

                    // Generate Report Button
                    Button {
                        showTripReport = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.body)

                            Text("Generate Report")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accentBlue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Generate trip report")
                    .accessibilityHint("Double tap to create PDF report with expenses and mileage")
                }
                .padding()
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(trip.tripName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
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

struct AddTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let initialStartDate: Date?
    let initialEndDate: Date?

    @State private var name = ""
    @State private var destination = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var tripType: TripType = .business
    @State private var purpose = ""

    init(initialStartDate: Date? = nil, initialEndDate: Date? = nil) {
        self.initialStartDate = initialStartDate
        self.initialEndDate = initialEndDate

        // Pre-fill dates with context from calendar, or default to today
        let start = initialStartDate ?? Date()
        let end = initialEndDate ?? Calendar.iso8601.date(byAdding: .day, value: 7, to: start) ?? start

        _startDate = State(initialValue: start)
        _endDate = State(initialValue: end)
    }

    var body: some View {
        Form {
            Section("Trip Info") {
                TextField("Trip Name", text: $name)
                TextField("Destination", text: $destination)
                TextField("Purpose (Optional)", text: $purpose)
                    .textInputAutocapitalization(.sentences)
            }

            Section("Dates") {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }

            Section("Type") {
                Picker("Trip Type", selection: $tripType) {
                    ForEach([TripType.business, TripType.personal, TripType.mixed], id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("New Trip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let trip = TravelTrip(
                        tripName: name.isEmpty ? "New Trip" : name,
                        destination: destination,
                        startDate: startDate,
                        endDate: endDate,
                        purpose: purpose.isEmpty ? nil : purpose,
                        tripType: tripType
                    )
                    modelContext.insert(trip)
                    try? modelContext.save()
                    dismiss()
                }
                .disabled(destination.isEmpty)
            }
        }
    }
}
