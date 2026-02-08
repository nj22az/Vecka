//
//  WidgetFacts.swift
//  VeckaWidget
//
//  Database-driven random facts for widget display
//  Loads from quirky-facts.json (same data as main app)
//  Date-based facts remain dynamic
//

import Foundation

enum WidgetFacts {

    // MARK: - Fact Model

    struct Fact {
        let id: String       // For deep link: vecka://facts/{id}
        let text: String
        let symbol: String   // SF Symbol name
    }

    // MARK: - JSON DTO

    private struct FactDTO: Decodable {
        let id: String
        let region: String
        let category: String
        let text: String
        let explanation: String?
    }

    // MARK: - Category to SF Symbol mapping

    private static func symbol(for category: String) -> String {
        switch category {
        case "tradition": return "sparkles"
        case "food": return "fork.knife"
        case "invention": return "lightbulb.fill"
        case "nature": return "leaf.fill"
        case "history": return "clock.fill"
        case "quirky": return "star.fill"
        default: return "info.circle.fill"
        }
    }

    // MARK: - Cached Facts from JSON

    private static let databaseFacts: [Fact] = {
        guard let url = Bundle.main.url(forResource: "quirky-facts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([FactDTO].self, from: data) else {
            return []
        }
        return dtos.map { Fact(id: $0.id, text: $0.text, symbol: symbol(for: $0.category)) }
    }()

    // MARK: - Date-Based Facts (dynamic)

    static func dateFact(for date: Date) -> Fact {
        let calendar = Calendar(identifier: .iso8601)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let isLeapYear = calendar.range(of: .day, in: .year, for: date)?.count == 366
        let totalDays = isLeapYear ? 366 : 365
        let percentComplete = Int((Double(dayOfYear) / Double(totalDays)) * 100)
        let daysRemaining = totalDays - dayOfYear
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        var facts: [(id: String, text: String, symbol: String)] = [
            ("date-day", "Day \(dayOfYear) of \(totalDays)", "calendar"),
            ("date-pct", "\(percentComplete)% of \(year) complete", "chart.pie.fill"),
            ("date-rem", "\(daysRemaining) days left in \(year)", "hourglass"),
        ]

        // Summer solstice countdown (June 21)
        if month < 6 || (month == 6 && day < 21) {
            if let summer = calendar.date(from: DateComponents(year: year, month: 6, day: 21)) {
                let daysToSummer = calendar.dateComponents([.day], from: date, to: summer).day ?? 0
                if daysToSummer > 0 && daysToSummer < 100 {
                    facts.append(("date-summer", "\(daysToSummer) days to summer", "sun.max.fill"))
                }
            }
        }

        // Christmas countdown (Dec 25)
        if month >= 10 || month == 1 {
            if let christmas = calendar.date(from: DateComponents(year: year, month: 12, day: 25)) {
                let daysToChristmas = calendar.dateComponents([.day], from: date, to: christmas).day ?? 0
                if daysToChristmas > 0 && daysToChristmas < 90 {
                    facts.append(("date-xmas", "\(daysToChristmas) days to Christmas", "gift.fill"))
                }
            }
        }

        let picked = facts[dayOfYear % facts.count]
        return Fact(id: picked.id, text: picked.text, symbol: picked.symbol)
    }

    // MARK: - Get Random Fact

    /// Returns a consistent fact for the given date (same fact all day)
    static func randomFact(for date: Date) -> Fact {
        let calendar = Calendar(identifier: .iso8601)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        // 2 out of 3 days: show a database fact. 1 out of 3: date-based.
        let showDateFact = dayOfYear % 3 == 0

        if showDateFact {
            return dateFact(for: date)
        }

        // Pick from database facts using day of year for consistency
        guard !databaseFacts.isEmpty else {
            return dateFact(for: date)
        }
        return databaseFacts[dayOfYear % databaseFacts.count]
    }
}
