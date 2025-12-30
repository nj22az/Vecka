//
//  WeekOverviewIntent.swift
//  Vecka
//
//  App Intent for Siri: "Show week overview" / "Tell me about this week"
//  Provides comprehensive week information including days remaining
//

import AppIntents
import SwiftUI
import Foundation

/// Intent for getting comprehensive week overview via Siri
struct WeekOverviewIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Week Overview"
    static var description = IntentDescription("Get detailed information about the current week")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let calculator = WeekCalculator.shared
        let info = calculator.weekInfo()

        // Build comprehensive dialog
        var dialogParts: [String] = []
        dialogParts.append("Week \(info.weekNumber): \(info.dateRange).")

        if info.isCurrentWeek && info.daysRemaining > 0 {
            let dayText = info.daysRemaining == 1 ? "day" : "days"
            dialogParts.append("\(info.daysRemaining) \(dayText) remaining in this week.")
        }

        let dialog = IntentDialog(stringLiteral: dialogParts.joined(separator: " "))

        return .result(dialog: dialog)
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Get overview of current week")
    }
}
