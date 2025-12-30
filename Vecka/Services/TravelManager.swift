//
//  TravelManager.swift
//  Vecka
//
//  Travel trip and mileage management service
//

import Foundation
import SwiftData
import CoreLocation

@MainActor
class TravelManager {

    // MARK: - Singleton
    static let shared = TravelManager()

    private init() {}

    // MARK: - Trip Operations

    /// Get all trips
    func getAllTrips(context: ModelContext) throws -> [TravelTrip] {
        let descriptor = FetchDescriptor<TravelTrip>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// Get active trips (currently ongoing)
    func getActiveTrips(context: ModelContext) throws -> [TravelTrip] {
        let now = Date()
        let allTrips = try getAllTrips(context: context)
        return allTrips.filter {
            $0.status == .active &&
            $0.startDate <= now &&
            $0.endDate >= now
        }
    }

    /// Get trips for date range
    func getTrips(overlapping startDate: Date, endDate: Date, context: ModelContext) throws -> [TravelTrip] {
        let descriptor = FetchDescriptor<TravelTrip>(
            predicate: #Predicate { trip in
                // Trips that overlap with the date range
                trip.startDate <= endDate && trip.endDate >= startDate
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// Get trip for specific date
    func getTrip(for date: Date, context: ModelContext) throws -> TravelTrip? {
        let dayDate = Calendar.iso8601.startOfDay(for: date)
        let descriptor = FetchDescriptor<TravelTrip>(
            predicate: #Predicate { trip in
                trip.startDate <= dayDate && trip.endDate >= dayDate
            }
        )
        return try context.fetch(descriptor).first
    }

    /// Update trip status based on dates
    func updateTripStatus(_ trip: TravelTrip) {
        let now = Date()
        let calendar = Calendar.iso8601

        if calendar.startOfDay(for: now) < calendar.startOfDay(for: trip.startDate) {
            trip.status = .planned
        } else if calendar.startOfDay(for: now) > calendar.startOfDay(for: trip.endDate) {
            trip.status = .completed
        } else {
            trip.status = .active
        }
    }

    // MARK: - Mileage Operations

    /// Get all mileage entries
    func getAllMileage(context: ModelContext) throws -> [MileageEntry] {
        let descriptor = FetchDescriptor<MileageEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// Get mileage for specific date
    func getMileage(for date: Date, context: ModelContext) throws -> [MileageEntry] {
        let allMileage = try getAllMileage(context: context)
        let dayDate = Calendar.iso8601.startOfDay(for: date)
        return allMileage.filter {
            Calendar.iso8601.startOfDay(for: $0.date) == dayDate
        }
    }

    /// Get mileage for date range
    func getMileage(from startDate: Date, to endDate: Date, context: ModelContext) throws -> [MileageEntry] {
        let start = Calendar.iso8601.startOfDay(for: startDate)
        let end = Calendar.iso8601.startOfDay(for: endDate)

        let allMileage = try getAllMileage(context: context)
        return allMileage.filter {
            let entryDay = Calendar.iso8601.startOfDay(for: $0.date)
            return entryDay >= start && entryDay <= end
        }
    }

    /// Get mileage for trip
    func getMileage(for trip: TravelTrip, context: ModelContext) throws -> [MileageEntry] {
        let allMileage = try getAllMileage(context: context)
        return allMileage.filter { $0.trip?.id == trip.id }
    }

    /// Calculate total mileage
    func calculateTotalMileage(entries: [MileageEntry]) -> Double {
        entries.reduce(0) { $0 + $1.totalDistance }
    }

    /// Calculate distance between two coordinates (optional GPS tracking)
    func calculateDistance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)

        // Distance in meters, convert to kilometers
        let distanceInMeters = fromLocation.distance(from: toLocation)
        return distanceInMeters / 1000.0
    }

    // MARK: - Auto-tracking (Future Feature)

    /// Start GPS tracking for mileage
    /// This is a placeholder for future implementation
    func startMileageTracking() {
        // TODO: Implement GPS-based mileage tracking
        // - Request location permission
        // - Start CLLocationManager updates
        // - Store route coordinates
        // - Calculate distance continuously
        Log.i("Mileage auto-tracking not yet implemented")
    }

    /// Stop GPS tracking and create mileage entry
    func stopMileageTracking() {
        // TODO: Stop tracking and save entry
        Log.i("Mileage auto-tracking not yet implemented")
    }

    // MARK: - Per Diem Calculations (Future Feature)

    /// Calculate per diem allowance for trip
    /// Different countries have different per diem rates
    func calculatePerDiem(
        for trip: TravelTrip,
        ratePerDay: Double = 450.0 // Default SEK rate
    ) -> Double {
        let days = Double(trip.duration)
        return days * ratePerDay
    }

    // MARK: - Export Data

    /// Get comprehensive trip report data
    func getTripReport(
        for trip: TravelTrip,
        context: ModelContext
    ) throws -> TripReportData {
        let expenses = try ExpenseManager.shared.getExpenses(for: trip, context: context)
        let mileage = try getMileage(for: trip, context: context)

        let totalExpenses = ExpenseManager.shared.calculateTotal(expenses: expenses)
        let totalMileage = calculateTotalMileage(entries: mileage)

        return TripReportData(
            trip: trip,
            expenses: expenses,
            mileageEntries: mileage,
            totalExpenses: totalExpenses,
            totalMileage: totalMileage
        )
    }
}

// MARK: - Trip Report Data

struct TripReportData {
    let trip: TravelTrip
    let expenses: [ExpenseItem]
    let mileageEntries: [MileageEntry]
    let totalExpenses: Double
    let totalMileage: Double

    var expenseCount: Int {
        expenses.count
    }

    var mileageEntryCount: Int {
        mileageEntries.count
    }
}
