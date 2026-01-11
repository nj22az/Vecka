//
//  CalendarFact.swift
//  Vecka
//
//  情報デザイン: Database-driven calendar facts
//  Template-based system for dynamic date information
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - SwiftData Model

@Model
final class CalendarFact {
    @Attribute(.unique) var id: String
    var type: String           // "static", "conditional", "weekday", "month"
    var condition: String      // "always", "weekday", "month", "daysUntilFriday", "daysLeftInMonth"
    var conditionValue: Int?   // For weekday (1-7) or month (1-12)
    var conditionMin: Int?     // For range conditions
    var conditionMax: Int?     // For range conditions
    var textTemplate: String   // Template with placeholders like {weekOfYear}
    var icon: String
    var colorSemantic: String  // "pink", "cyan", "yellow", "green", "purple", "orange"
    var explanation: String

    init(id: String, type: String, condition: String, conditionValue: Int? = nil,
         conditionMin: Int? = nil, conditionMax: Int? = nil,
         textTemplate: String, icon: String, colorSemantic: String, explanation: String) {
        self.id = id
        self.type = type
        self.condition = condition
        self.conditionValue = conditionValue
        self.conditionMin = conditionMin
        self.conditionMax = conditionMax
        self.textTemplate = textTemplate
        self.icon = icon
        self.colorSemantic = colorSemantic
        self.explanation = explanation
    }
}

// MARK: - Color Resolution

extension CalendarFact {
    /// 情報デザイン: Resolve semantic color name to actual Color
    var color: Color {
        switch colorSemantic.lowercased() {
        case "pink": return JohoColors.pink
        case "cyan": return JohoColors.cyan
        case "yellow": return JohoColors.yellow
        case "green": return JohoColors.green
        case "purple": return JohoColors.purple
        case "orange": return Color(hex: "F97316")
        default: return JohoColors.cyan
        }
    }
}

// MARK: - Condition Evaluation

extension CalendarFact {
    /// Check if this fact should be shown for the given date
    func isApplicable(for date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        switch type {
        case "static":
            return true

        case "weekday":
            return conditionValue == weekday

        case "month":
            return conditionValue == month

        case "conditional":
            return evaluateConditional(weekday: weekday, month: month, day: day, date: date)

        default:
            return true
        }
    }

    private func evaluateConditional(weekday: Int, month: Int, day: Int, date: Date) -> Bool {
        switch condition {
        case "daysUntilFriday":
            let daysUntilFriday = (6 - weekday + 7) % 7
            return isInRange(daysUntilFriday)

        case "daysLeftInMonth":
            let calendar = Calendar.current
            if let range = calendar.range(of: .day, in: .month, for: date) {
                let daysLeft = range.count - day
                return isInRange(daysLeft)
            }
            return false

        case "month":
            return isInRange(month)

        default:
            return true
        }
    }

    private func isInRange(_ value: Int) -> Bool {
        let min = conditionMin ?? Int.min
        let max = conditionMax ?? Int.max
        return value >= min && value <= max
    }
}

// MARK: - Text Rendering

extension CalendarFact {
    /// Render the template with actual values for the given date
    func renderText(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date)
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        var text = textTemplate

        // Calculate dynamic values
        let daysUntilFriday = (6 - weekday + 7) % 7
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        let daysLeftInMonth = daysInMonth - day
        let monthProgress = Int((Double(day) / Double(daysInMonth)) * 100)
        let yearProgress = Int(Double(dayOfYear) / 365.0 * 100)
        let weeksLeftInYear = 52 - weekOfYear

        let monthName = date.formatted(.dateTime.month(.wide))

        // Replace placeholders
        text = text.replacingOccurrences(of: "{weekOfYear}", with: "\(weekOfYear)")
        text = text.replacingOccurrences(of: "{daysUntilFriday}", with: "\(daysUntilFriday)")
        text = text.replacingOccurrences(of: "{daysLeftInMonth}", with: "\(daysLeftInMonth)")
        text = text.replacingOccurrences(of: "{monthProgress}", with: "\(monthProgress)")
        text = text.replacingOccurrences(of: "{yearProgress}", with: "\(yearProgress)")
        text = text.replacingOccurrences(of: "{dayOfYear}", with: "\(dayOfYear)")
        text = text.replacingOccurrences(of: "{daysInMonth}", with: "\(daysInMonth)")
        text = text.replacingOccurrences(of: "{monthName}", with: monthName)
        text = text.replacingOccurrences(of: "{year}", with: "\(year)")
        text = text.replacingOccurrences(of: "{weeksLeftInYear}", with: "\(weeksLeftInYear)")

        // Handle plural suffix
        text = text.replacingOccurrences(of: "{plural}", with: daysUntilFriday == 1 ? "" : "s")

        return text
    }
}

// MARK: - JSON Loader

enum CalendarFactsLoader {

    /// Seed calendar facts from JSON on first launch
    static func seedIfNeeded(context: ModelContext) {
        // Check if already seeded
        let descriptor = FetchDescriptor<CalendarFact>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        loadFromJSON(context: context)
    }

    /// Force reseed - delete all and reload from JSON
    static func forceReseed(context: ModelContext) {
        // Delete all existing facts
        let descriptor = FetchDescriptor<CalendarFact>()
        if let existing = try? context.fetch(descriptor) {
            for fact in existing {
                context.delete(fact)
            }
        }
        try? context.save()

        loadFromJSON(context: context)
    }

    private static func loadFromJSON(context: ModelContext) {
        guard let url = Bundle.main.url(forResource: "calendar-facts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let facts = try? JSONDecoder().decode([CalendarFactDTO].self, from: data) else {
            Log.e("Failed to load calendar-facts.json")
            return
        }

        for dto in facts {
            let fact = CalendarFact(
                id: dto.id,
                type: dto.type,
                condition: dto.condition,
                conditionValue: dto.conditionValue,
                conditionMin: dto.conditionMin,
                conditionMax: dto.conditionMax,
                textTemplate: dto.textTemplate,
                icon: dto.icon,
                colorSemantic: dto.colorSemantic,
                explanation: dto.explanation
            )
            context.insert(fact)
        }

        try? context.save()
        Log.i("Seeded \(facts.count) calendar facts from JSON")
    }

    /// DTO for JSON decoding
    private struct CalendarFactDTO: Codable {
        let id: String
        let type: String
        let condition: String
        let conditionValue: Int?
        let conditionMin: Int?
        let conditionMax: Int?
        let textTemplate: String
        let icon: String
        let colorSemantic: String
        let explanation: String
    }
}
