//
//  MemoMigrationService.swift
//  Vecka
//
//  One-time migration from legacy models to unified Memo model.
//  Runs on app launch, migrates data, then marks complete.
//

import Foundation
import SwiftData

/// Migrates legacy data models to the unified Memo model
/// DailyNote, CountdownEvent, ExpenseItem, TravelTrip → Memo
@MainActor
enum MemoMigrationService {
    private static let migrationCompleteKey = "MemoMigrationComplete_v1"

    /// Run migration if not already completed
    static func migrateIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationCompleteKey) else {
            Log.d("MemoMigration: Already completed, skipping")
            return
        }

        Log.i("MemoMigration: Starting migration...")

        var totalMigrated = 0

        // Migrate each legacy type
        totalMigrated += migrateDailyNotes(context: context)
        totalMigrated += migrateCountdowns(context: context)
        totalMigrated += migrateExpenses(context: context)
        totalMigrated += migrateTrips(context: context)

        // Save changes
        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: migrationCompleteKey)
            Log.i("MemoMigration: Complete. Migrated \(totalMigrated) entries.")
        } catch {
            Log.e("MemoMigration: Failed to save - \(error)")
        }
    }

    /// Reset migration flag (for testing)
    static func reset() {
        UserDefaults.standard.removeObject(forKey: migrationCompleteKey)
        Log.d("MemoMigration: Reset")
    }

    // MARK: - DailyNote Migration

    private static func migrateDailyNotes(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<DailyNote>()
        guard let notes = try? context.fetch(descriptor), !notes.isEmpty else {
            Log.d("MemoMigration: No DailyNotes to migrate")
            return 0
        }

        var count = 0
        for note in notes {
            let memo = Memo(text: note.content, date: note.day)
            memo.scheduledAt = note.scheduledAt
            memo.duration = note.duration
            memo.symbolName = note.symbolName
            memo.pinnedToDashboard = note.pinnedToDashboard
            memo.color = note.color
            memo.priorityRaw = note.priority
            memo.type = .note  // Set type discriminator

            context.insert(memo)
            count += 1
        }

        Log.i("MemoMigration: Migrated \(count) DailyNotes")
        return count
    }

    // MARK: - CountdownEvent Migration

    private static func migrateCountdowns(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<CountdownEvent>()
        guard let countdowns = try? context.fetch(descriptor), !countdowns.isEmpty else {
            Log.d("MemoMigration: No CountdownEvents to migrate")
            return 0
        }

        var count = 0
        for countdown in countdowns {
            let memo = Memo(text: countdown.title, date: countdown.targetDate)
            memo.isCountdown = true
            memo.countdownIcon = countdown.icon
            memo.color = countdown.colorHex.replacingOccurrences(of: "#", with: "")
            memo.isSystemCountdown = countdown.isSystem
            memo.type = .countdown  // Set type discriminator

            context.insert(memo)
            count += 1
        }

        Log.i("MemoMigration: Migrated \(count) CountdownEvents")
        return count
    }

    // MARK: - ExpenseItem Migration

    private static func migrateExpenses(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<ExpenseItem>()
        guard let expenses = try? context.fetch(descriptor), !expenses.isEmpty else {
            Log.d("MemoMigration: No ExpenseItems to migrate")
            return 0
        }

        var count = 0
        for expense in expenses {
            let text = expense.itemDescription.isEmpty ? (expense.merchantName ?? "Expense") : expense.itemDescription
            let memo = Memo(text: text, date: expense.date)
            memo.amount = expense.amount
            memo.currency = expense.currency
            memo.place = expense.merchantName
            memo.type = .expense  // Set type discriminator

            // Add notes as extended text if present
            if let notes = expense.notes, !notes.isEmpty {
                memo.text = "\(text)\n\(notes)"
            }

            context.insert(memo)
            count += 1
        }

        Log.i("MemoMigration: Migrated \(count) ExpenseItems")
        return count
    }

    // MARK: - TravelTrip Migration

    private static func migrateTrips(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<TravelTrip>()
        guard let trips = try? context.fetch(descriptor), !trips.isEmpty else {
            Log.d("MemoMigration: No TravelTrips to migrate")
            return 0
        }

        var count = 0
        for trip in trips {
            let memo = Memo(text: trip.tripName, date: trip.startDate)
            memo.tripEndDate = trip.endDate
            memo.place = trip.destination
            memo.tripPurpose = trip.purpose
            memo.type = .trip  // Set type discriminator

            context.insert(memo)
            count += 1
        }

        Log.i("MemoMigration: Migrated \(count) TravelTrips")
        return count
    }
}
