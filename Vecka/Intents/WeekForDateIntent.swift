//
//  WeekForDateIntent.swift
//  Vecka
//
//  App Intent for Siri: "What week is Christmas?" / "What week is December 25th?"
//  Enables voice queries for week number of any specific date
//

import AppIntents
import SwiftUI
import Foundation

/// Intent for getting the week number for a specific date via Siri
struct WeekForDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Week for Date"
    static var description = IntentDescription("Find the ISO 8601 week number for a specific date")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Date")
    var date: Date

    init() {
        self.date = Date()
    }

    init(date: Date) {
        self.date = date
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let calculator = WeekCalculator.shared
        let weekInfo = calculator.weekInfo(for: date)

        // Format short date for dialog
        let shortFormatter = DateFormatter()
        shortFormatter.dateFormat = "MMMM d"
        let shortDate = shortFormatter.string(from: date)

        let dialog = IntentDialog(stringLiteral: "\(shortDate) is in week \(weekInfo.weekNumber)")

        return .result(dialog: dialog)
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Get week number for \(\.$date)")
    }
}
