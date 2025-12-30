//
//  CountdownManager.swift
//  Vecka
//
//  Manages Countdowns: Seeding & Updates
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class CountdownManager {
    static let shared = CountdownManager()
    
    private init() {}
    
    /// Initialize: Seed Countdowns if empty, update system countdowns
    func initialize(context: ModelContext) {
        seedDefaultCountdowns(context: context)
        updateSystemCountdowns(context: context)
    }

    /// Update existing system countdown titles
    private func updateSystemCountdowns(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<CountdownEvent>(predicate: #Predicate<CountdownEvent> { $0.isSystem })
            let systemEvents = try context.fetch(descriptor)

            for event in systemEvents {
                // Update Christmas to Christmas Eve
                if event.title == "Christmas" {
                    event.title = "Christmas Eve"
                    Log.d("Updated Christmas → Christmas Eve")
                }
                // Update New Year to New Year's Day
                if event.title == "New Year" {
                    event.title = "New Year's Day"
                    Log.d("Updated New Year → New Year's Day")
                }
            }

            do {
                try context.save()
            } catch {
                Log.w("Failed to save countdown title updates: \(error.localizedDescription)")
            }
        } catch {
            Log.w("Failed to update system countdowns: \(error.localizedDescription)")
        }
    }
    
    /// Seed default countdowns
    private func seedDefaultCountdowns(context: ModelContext) {
        let descriptor = FetchDescriptor<CountdownEvent>()
        let count: Int
        do {
            count = try context.fetchCount(descriptor)
        } catch {
            Log.w("Failed to fetch countdown count: \(error.localizedDescription)")
            return
        }

        if count == 0 {
            Log.d("Seeding Default Countdowns...")

            let currentYear = Calendar.current.component(.year, from: Date())

            // Christmas Eve
            guard let christmasDate = Calendar.current.date(from: DateComponents(year: currentYear, month: 12, day: 24)),
                  let newYearDate = Calendar.current.date(from: DateComponents(year: currentYear + 1, month: 1, day: 1)),
                  let vacationDate = Calendar.current.date(from: DateComponents(year: currentYear + 1, month: 6, day: 15)) else {
                Log.w("Failed to create countdown dates")
                return
            }

            let christmas = CountdownEvent(
                title: "Christmas Eve",
                targetDate: christmasDate,
                icon: "gift.fill",
                colorHex: "#FF3B30", // Red
                isSystem: true
            )

            // New Year's Day
            let newYear = CountdownEvent(
                title: "New Year's Day",
                targetDate: newYearDate,
                icon: "sparkles",
                colorHex: "#FFD60A", // Yellow
                isSystem: true
            )

            // Summer Vacation (Example)
            let vacation = CountdownEvent(
                title: "Summer Vacation",
                targetDate: vacationDate,
                icon: "airplane.departure",
                colorHex: "#007AFF", // Blue
                isSystem: false
            )

            context.insert(christmas)
            context.insert(newYear)
            context.insert(vacation)

            do {
                try context.save()
                Log.i("Seeded Countdowns.")
            } catch {
                Log.w("Failed to save seeded countdowns: \(error.localizedDescription)")
            }
        }
    }
}
