//
//  CountdownMigration.swift
//  Vecka
//
//  Cleanup for deprecated countdown feature.
//

import Foundation
import SwiftData

@MainActor
enum CountdownMigration {
    private static let cleanupKey = "didCleanupCountdownEvents_v1"

    static func cleanupIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: cleanupKey) else { return }

        do {
            let all = try context.fetch(FetchDescriptor<CountdownEvent>())

            for event in all {
                context.delete(event)
            }

            if context.hasChanges {
                try context.save()
            }

            UserDefaults.standard.removeObject(forKey: "selectedCountdownID")
            UserDefaults.standard.set(true, forKey: cleanupKey)
            Log.i("CountdownMigration: removed \(all.count) countdown events")
        } catch {
            Log.w("CountdownMigration: cleanup failed: \(error.localizedDescription)")
        }
    }
}

