//
//  WidgetRandomFact.swift
//  VeckaWidget
//
//  情報デザイン: Static random facts for widget display
//  Simple, self-contained facts without SwiftData dependency
//

import SwiftUI

// MARK: - Widget Random Fact

struct WidgetRandomFact: Identifiable {
    let id: String
    let text: String
    let icon: String
    let color: Color
    let source: String

    /// Get a deterministic fact based on date (changes daily)
    static func factForDate(_ date: Date) -> WidgetRandomFact {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = dayOfYear % allFacts.count
        return allFacts[index]
    }

    /// Get multiple facts for a date (for grid display)
    static func factsForDate(_ date: Date, count: Int) -> [WidgetRandomFact] {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        var facts: [WidgetRandomFact] = []
        for i in 0..<count {
            let index = (dayOfYear + i * 7) % allFacts.count
            facts.append(allFacts[index])
        }
        return facts
    }

    // MARK: - Static Facts Database (情報デザイン: Curated facts)
    // IDs match main app's quirky-facts.json for deep linking

    static let allFacts: [WidgetRandomFact] = [
        // Swedish/Nordic facts (IDs match quirky-facts.json)
        WidgetRandomFact(
            id: "se008",
            text: "Lagom: not too much, not too little",
            icon: "equal.circle.fill",
            color: Color(hex: "4A90D9"),
            source: "Sweden"
        ),
        WidgetRandomFact(
            id: "se007",
            text: "Fika: coffee breaks are sacred",
            icon: "cup.and.saucer.fill",
            color: Color(hex: "78350F"),
            source: "Sweden"
        ),
        WidgetRandomFact(
            id: "se016",
            text: "Flat-pack furniture? Swedish idea.",
            icon: "shippingbox.fill",
            color: Color(hex: "F39C12"),
            source: "Sweden"
        ),
        WidgetRandomFact(
            id: "uk002",
            text: "Queuing is sacred. Don't skip.",
            icon: "person.3.fill",
            color: Color(hex: "2ECC71"),
            source: "UK"
        ),
        WidgetRandomFact(
            id: "se002",
            text: "Midsommar: dance around a maypole",
            icon: "sun.max.fill",
            color: Color(hex: "FFE566"),
            source: "Sweden"
        ),
        WidgetRandomFact(
            id: "se031",
            text: "A king died from eating too many semla",
            icon: "birthday.cake.fill",
            color: Color(hex: "FECDD3"),
            source: "Sweden"
        ),

        // Vietnamese facts
        WidgetRandomFact(
            id: "vn005",
            text: "6 tones change word meaning entirely",
            icon: "waveform",
            color: Color(hex: "E74C3C"),
            source: "Vietnam"
        ),
        WidgetRandomFact(
            id: "vn003",
            text: "40% are named Nguyen",
            icon: "person.2.fill",
            color: Color(hex: "E74C3C"),
            source: "Vietnam"
        ),
        WidgetRandomFact(
            id: "vn001",
            text: "Egg coffee: Vietnamese specialty",
            icon: "cup.and.saucer.fill",
            color: Color(hex: "F97316"),
            source: "Vietnam"
        ),
        WidgetRandomFact(
            id: "vn018",
            text: "Motorbike nation: 45 million+",
            icon: "bicycle",
            color: Color(hex: "E74C3C"),
            source: "Vietnam"
        ),

        // UK facts
        WidgetRandomFact(
            id: "uk001",
            text: "100 million cups of tea daily",
            icon: "cup.and.saucer.fill",
            color: Color(hex: "2ECC71"),
            source: "UK"
        ),
        WidgetRandomFact(
            id: "uk004",
            text: "Illegal to die in Parliament",
            icon: "building.columns.fill",
            color: Color(hex: "2ECC71"),
            source: "UK"
        ),

        // Sweden - more facts
        WidgetRandomFact(
            id: "se001",
            text: "Swedes count weeks, not dates",
            icon: "number",
            color: Color(hex: "4A90D9"),
            source: "Sweden"
        ),
        WidgetRandomFact(
            id: "se099",
            text: "Donald Duck on TV every Christmas Eve",
            icon: "tv.fill",
            color: Color(hex: "4A90D9"),
            source: "Sweden"
        ),
        WidgetRandomFact(
            id: "se088",
            text: "North Korea owes us 1,000 Volvos",
            icon: "car.fill",
            color: Color(hex: "4A90D9"),
            source: "Sweden"
        ),

        // Nordic facts
        WidgetRandomFact(
            id: "no009",
            text: "Northern Lights capital: Tromsø",
            icon: "sparkles",
            color: Color(hex: "9B59B6"),
            source: "Norway"
        ),
        WidgetRandomFact(
            id: "fi001",
            text: "Finland: 3 million saunas",
            icon: "flame.fill",
            color: Color(hex: "F97316"),
            source: "Finland"
        ),
        WidgetRandomFact(
            id: "dk001",
            text: "Bluetooth named after a Danish king",
            icon: "antenna.radiowaves.left.and.right",
            color: Color(hex: "4A90D9"),
            source: "Denmark"
        ),
    ]
}
