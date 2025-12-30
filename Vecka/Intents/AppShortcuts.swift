//
//  AppShortcuts.swift
//  Vecka
//
//  App Shortcuts provider - defines Siri phrases and shortcut availability
//  Enables voice triggers like "Hey Siri, what week is it?"
//

import AppIntents

/// App Shortcuts provider for Vecka
struct VeckaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Current Week Shortcut
        AppShortcut(
            intent: CurrentWeekIntent(),
            phrases: [
                "What week is it in \(.applicationName)",
                "Get current week in \(.applicationName)",
                "Tell me the week number in \(.applicationName)",
                "What's the week in \(.applicationName)",
                "Current week in \(.applicationName)",
                "Show week number in \(.applicationName)"
            ],
            shortTitle: "Current Week",
            systemImageName: "calendar.badge.clock"
        )

        // Week Overview Shortcut
        AppShortcut(
            intent: WeekOverviewIntent(),
            phrases: [
                "Show week overview in \(.applicationName)",
                "Tell me about this week in \(.applicationName)",
                "Week details in \(.applicationName)",
                "Get week information in \(.applicationName)",
                "This week in \(.applicationName)"
            ],
            shortTitle: "Week Overview",
            systemImageName: "calendar.badge.exclamationmark"
        )
    }

    static var shortcutTileColor: ShortcutTileColor {
        .blue
    }
}

// Note: WeekForDateIntent is available via the Shortcuts app but not as a phrase shortcut
// because App Shortcuts don't support Date parameters directly
