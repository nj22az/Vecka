//
//  AppInitializer.swift
//  Vecka
//
//  Centralized app initialization to ensure managers are set up once
//

import Foundation
import SwiftData

/// Centralized initialization for all app managers
/// Call from the main view's onAppear to ensure one-time setup
@MainActor
enum AppInitializer {
    private static var isInitialized = false

    /// Initialize all managers with the given model context
    /// Safe to call multiple times - will only run once
    static func initialize(context: ModelContext) {
        guard !isInitialized else {
            Log.d("AppInitializer: Already initialized, skipping")
            return
        }

        UserDefaults.standard.register(defaults: [
            "showHolidays": true,
            "holidayRegion": "",
            "holidayRegions": ""
        ])

        if UserDefaults.standard.string(forKey: "holidayRegions") == nil {
            let legacy = UserDefaults.standard.string(forKey: "holidayRegion") ?? "SE"
            UserDefaults.standard.set(legacy, forKey: "holidayRegions")
        }

        Log.i("AppInitializer: Starting initialization...")

        // FAST PATH (synchronous, on main): lightweight setup needed before
        // the first frame renders correctly — seeding rules into the DB
        // (only runs once thanks to fetchCount guard) and CalendarManager.
        CalendarManager.shared.initialize(context: context)
        HolidayManager.shared.seedRulesIfNeeded(context: context)

        // DEFERRED PATH (next runloop): the expensive 5-year × 259-rule
        // holiday computation + DB-writing config seeding. Yielding lets
        // the first frame render before these run, so cold launch feels
        // instant. View code that reads `HolidayManager.cache` already
        // tolerates an empty cache (returns no holidays, then redraws
        // when the cache populates).
        Task { @MainActor in
            HolidayManager.shared.calculateAndCacheHolidays(context: context)
            ConfigurationManager.shared.seedDefaultConfiguration(context: context)
            Log.i("AppInitializer: Deferred initialization complete")
        }

        isInitialized = true
        Log.i("AppInitializer: Synchronous init complete; deferred work queued")
    }

    /// Reset initialization state (for testing purposes)
    static func reset() {
        isInitialized = false
        Log.d("AppInitializer: Reset")
    }
}
