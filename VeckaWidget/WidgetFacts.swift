//
//  WidgetFacts.swift
//  VeckaWidget
//
//  Random facts for widget display when no special day
//  Mix of: Date-based, Swedish/Nordic, Fun trivia
//

import Foundation

enum WidgetFacts {

    // MARK: - Fact Types

    enum FactType {
        case dateBased
        case nordic
        case trivia
    }

    struct Fact {
        let text: String
        let symbol: String  // SF Symbol name
        let type: FactType
    }

    // MARK: - Date-Based Facts

    static func dateFact(for date: Date) -> Fact {
        let calendar = Calendar(identifier: .iso8601)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let isLeapYear = calendar.range(of: .day, in: .year, for: date)?.count == 366
        let totalDays = isLeapYear ? 366 : 365
        let percentComplete = Int((Double(dayOfYear) / Double(totalDays)) * 100)
        let daysRemaining = totalDays - dayOfYear

        // Seasonal calculations
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let facts: [Fact] = [
            Fact(text: "Day \(dayOfYear) of \(totalDays)", symbol: "calendar", type: .dateBased),
            Fact(text: "\(percentComplete)% of \(year) complete", symbol: "chart.pie.fill", type: .dateBased),
            Fact(text: "\(daysRemaining) days left in \(year)", symbol: "hourglass", type: .dateBased),
        ]

        // Add seasonal facts
        var seasonalFacts = facts

        // Summer solstice countdown (June 21)
        if month < 6 || (month == 6 && day < 21) {
            if let summer = calendar.date(from: DateComponents(year: year, month: 6, day: 21)) {
                let daysToSummer = calendar.dateComponents([.day], from: date, to: summer).day ?? 0
                if daysToSummer > 0 && daysToSummer < 100 {
                    seasonalFacts.append(Fact(text: "\(daysToSummer) days to summer", symbol: "sun.max.fill", type: .dateBased))
                }
            }
        }

        // Christmas countdown (Dec 25)
        if month >= 10 || month == 1 {
            let christmasYear = month == 1 ? year : year
            if let christmas = calendar.date(from: DateComponents(year: christmasYear, month: 12, day: 25)) {
                let daysToChristmas = calendar.dateComponents([.day], from: date, to: christmas).day ?? 0
                if daysToChristmas > 0 && daysToChristmas < 90 {
                    seasonalFacts.append(Fact(text: "\(daysToChristmas) days to Christmas", symbol: "gift.fill", type: .dateBased))
                }
            }
        }

        // Pick based on day of year for consistency
        return seasonalFacts[dayOfYear % seasonalFacts.count]
    }

    // MARK: - Nordic/Swedish Facts

    static let nordicFacts: [Fact] = [
        Fact(text: "Fika time is sacred", symbol: "cup.and.saucer.fill", type: .nordic),
        Fact(text: "Lagom is just right", symbol: "equal.circle.fill", type: .nordic),
        Fact(text: "Hygge: cozy contentment", symbol: "flame.fill", type: .nordic),
        Fact(text: "Friluftsliv: open-air living", symbol: "leaf.fill", type: .nordic),
        Fact(text: "Allemansratten: freedom to roam", symbol: "figure.hiking", type: .nordic),
        Fact(text: "Mys: Swedish coziness", symbol: "house.fill", type: .nordic),
        Fact(text: "Jantelagen: humility matters", symbol: "person.2.fill", type: .nordic),
        Fact(text: "Smorgasbord: abundance", symbol: "fork.knife", type: .nordic),
    ]

    // MARK: - Fun Trivia

    static let triviaFacts: [Fact] = [
        Fact(text: "Flamingos: a flamboyance", symbol: "bird.fill", type: .trivia),
        Fact(text: "Crows: a murder", symbol: "bird.fill", type: .trivia),
        Fact(text: "Owls: a parliament", symbol: "bird.fill", type: .trivia),
        Fact(text: "Otters hold hands while sleeping", symbol: "heart.fill", type: .trivia),
        Fact(text: "Honey never spoils", symbol: "drop.fill", type: .trivia),
        Fact(text: "Octopi have three hearts", symbol: "heart.fill", type: .trivia),
        Fact(text: "Bananas are berries", symbol: "leaf.fill", type: .trivia),
        Fact(text: "A jiffy is 1/100th second", symbol: "clock.fill", type: .trivia),
        Fact(text: "Sharks predate trees", symbol: "fish.fill", type: .trivia),
        Fact(text: "Scotland's unicorn is national", symbol: "star.fill", type: .trivia),
    ]

    // MARK: - Get Random Fact

    /// Returns a consistent fact for the given date (same fact all day)
    static func randomFact(for date: Date) -> Fact {
        let calendar = Calendar(identifier: .iso8601)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        // Rotate through types based on day
        let typeIndex = dayOfYear % 3

        switch typeIndex {
        case 0:
            return dateFact(for: date)
        case 1:
            return nordicFacts[dayOfYear % nordicFacts.count]
        default:
            return triviaFacts[dayOfYear % triviaFacts.count]
        }
    }
}
