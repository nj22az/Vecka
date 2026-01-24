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

        // Initialize managers in dependency order
        CalendarManager.shared.initialize(context: context)
        HolidayManager.shared.initialize(context: context)

        // Initialize configuration system (database-driven architecture)
        ConfigurationManager.shared.seedDefaultConfiguration(context: context)
        Log.i("AppInitializer: Configuration system initialized")

        // Migrate legacy models to unified Memo (one-time)
        MemoMigrationService.migrateIfNeeded(context: context)

        isInitialized = true
        Log.i("AppInitializer: Initialization complete")
    }

    /// Reset initialization state (for testing purposes)
    static func reset() {
        isInitialized = false
        Log.d("AppInitializer: Reset")
    }
}
