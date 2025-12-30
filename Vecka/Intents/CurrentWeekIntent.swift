//
//  CurrentWeekIntent.swift
//  Vecka
//
//  App Intent for Siri: "What week is it?"
//  Enables voice queries for current ISO 8601 week number
//

import AppIntents
import SwiftUI
import Foundation

/// Intent for getting the current ISO 8601 week number via Siri
struct CurrentWeekIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Current Week"
    static var description = IntentDescription("Get the current ISO 8601 week number")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let calculator = WeekCalculator.shared
        let weekNumber = calculator.currentWeekNumber()
        let year = calculator.currentYear()

        // Create detailed response dialog
        let dialog = IntentDialog(stringLiteral: "It's week \(weekNumber) of \(year)")

        return .result(dialog: dialog)
    }
}

// MARK: - App Shortcuts Support

extension CurrentWeekIntent {
    static var parameterSummary: some ParameterSummary {
        Summary("Get current week number")
    }
}
