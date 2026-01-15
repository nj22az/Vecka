//
//  NotesMigration.swift
//  Vecka
//
//  One-time migrations for the notes model (data normalization + cleanup).
//

import Foundation
import SwiftData

@MainActor
enum NotesMigration {
    private static let backfillDayKey = "didBackfillDailyNoteDay_v1"
    private static let cleanupInvalidKey = "didCleanupInvalidDailyNotes_v1"

    static func runIfNeeded(context: ModelContext) {
        backfillDayIfNeeded(context: context)
        cleanupInvalidNotesIfNeeded(context: context)
    }

    private static func backfillDayIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: backfillDayKey) else { return }

        do {
            let all = try context.fetch(FetchDescriptor<DailyNote>())
            let calendar = Calendar.current

            for note in all {
                let computedDay = calendar.startOfDay(for: note.date)
                if note.day != computedDay {
                    note.day = computedDay
                }
            }

            try context.save()
            UserDefaults.standard.set(true, forKey: backfillDayKey)
            Log.i("NotesMigration: day backfill completed")
        } catch {
            Log.w("NotesMigration: failed: \(error.localizedDescription)")
        }
    }

    private static func cleanupInvalidNotesIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: cleanupInvalidKey) else { return }

        do {
            let all = try context.fetch(FetchDescriptor<DailyNote>())
            let calendar = Calendar.current
            var deleted = 0
            var normalized = 0

            for note in all {
                let trimmed = note.content.trimmed
                if trimmed.isEmpty {
                    context.delete(note)
                    deleted += 1
                    continue
                }

                if note.content != trimmed {
                    note.content = trimmed
                    normalized += 1
                }

                let computedDay = calendar.startOfDay(for: note.date)
                if note.day != computedDay {
                    note.day = computedDay
                    normalized += 1
                }
            }

            try context.save()
            UserDefaults.standard.set(true, forKey: cleanupInvalidKey)
            Log.i("NotesMigration: cleanup completed (deleted: \(deleted), normalized: \(normalized))")
        } catch {
            Log.w("NotesMigration: cleanup failed: \(error.localizedDescription)")
        }
    }
}
