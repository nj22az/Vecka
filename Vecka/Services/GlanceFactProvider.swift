//
//  GlanceFactProvider.swift
//  Vecka
//
//  情報デザイン: Database-driven fact provider for GLANCE tiles
//  Minimal code, queries SwiftData
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Glance Fact (Display Model)

struct GlanceFact: Identifiable, Equatable {
    let id: String
    let text: String
    let icon: String?
    let color: Color
    let explanation: String  // 情報デザイン: Detailed explanation for tap-to-expand

    static func == (lhs: GlanceFact, rhs: GlanceFact) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Glance Fact Provider

@MainActor
final class GlanceFactProvider: ObservableObject {

    private let context: ModelContext
    private let selectedRegions: [String]
    private let today: Date
    private var usedFactIDs: Set<String> = []
    private let easterEggChance: Double = 0  // 情報デザイン: Disabled - facts must be understandable at a glance

    init(context: ModelContext, selectedRegions: [String] = ["SE", "VN", "UK"], date: Date = Date()) {
        self.context = context
        self.selectedRegions = selectedRegions
        self.today = date
    }

    // MARK: - Public API

    func nextFact() -> GlanceFact {
        // Small chance for easter egg
        if Double.random(in: 0...1) < easterEggChance,
           let egg = randomEasterEgg() {
            return egg
        }

        // 情報デザイン: 20% chance for calendar fact, 80% database facts for variety
        // This ensures interesting region facts dominate while still showing relevant date info
        if Double.random(in: 0...1) < 0.2,
           let calendarFact = randomCalendarFact() {
            return calendarFact
        }

        // Primarily show database facts for maximum variety
        return randomRegionFact()
    }

    func reset() {
        usedFactIDs.removeAll()
    }

    // MARK: - Database Queries

    private func randomRegionFact() -> GlanceFact {
        // Query facts for selected regions
        let regions = selectedRegions
        let descriptor = FetchDescriptor<QuirkyFact>(
            predicate: #Predicate { regions.contains($0.region) }
        )

        let facts = (try? context.fetch(descriptor)) ?? []
        let available = facts.filter { !usedFactIDs.contains($0.id) }
        let pool = available.isEmpty ? facts : available

        guard !pool.isEmpty else {
            return GlanceFact(
                id: "fallback",
                text: "Week numbers matter.",
                icon: "calendar",
                color: JohoColors.cyan,
                explanation: "ISO 8601 week numbers are the international standard for numbering weeks. This app helps you track weeks the Swedish way."
            )
        }

        // 情報デザイン: True random selection for maximum variety
        let fact = pool.randomElement()!

        usedFactIDs.insert(fact.id)

        return GlanceFact(
            id: fact.id,
            text: fact.text,
            icon: iconFor(category: fact.factCategory),
            color: colorFor(category: fact.factCategory),
            explanation: fact.explanation.isEmpty ? fact.text : fact.explanation
        )
    }

    private func randomEasterEgg() -> GlanceFact? {
        let descriptor = FetchDescriptor<QuirkyFact>(
            predicate: #Predicate { $0.region == "XX" }
        )

        let eggs = (try? context.fetch(descriptor)) ?? []
        let available = eggs.filter { !usedFactIDs.contains($0.id) }
        guard !available.isEmpty else { return nil }

        let day = Calendar.current.component(.day, from: today)
        let egg = available[day % available.count]

        usedFactIDs.insert(egg.id)

        return GlanceFact(
            id: egg.id,
            text: egg.text,
            icon: "sparkles",
            color: JohoColors.yellow,
            explanation: egg.explanation.isEmpty ? egg.text : egg.explanation
        )
    }

    // MARK: - Calendar Facts (情報デザイン: Strong distinct colors per fact type)

    private func randomCalendarFact() -> GlanceFact? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        let day = calendar.component(.day, from: today)
        let month = calendar.component(.month, from: today)
        let weekOfYear = calendar.component(.weekOfYear, from: today)

        // (id, text, icon, color, explanation) - each fact has distinct strong color
        var facts: [(id: String, text: String, icon: String, color: Color, explanation: String)] = []

        // Days until Friday - celebration pink
        let daysUntilFriday = (6 - weekday + 7) % 7
        if daysUntilFriday > 0 && daysUntilFriday < 5 {
            facts.append(("cal_friday", "\(daysUntilFriday) day\(daysUntilFriday == 1 ? "" : "s") until Friday", "party.popper.fill", JohoColors.pink, "The weekend is almost here! Friday marks the end of the work week and the start of well-deserved rest."))
        }

        // Week number - cyan/schedule
        facts.append(("cal_week", "Week \(weekOfYear) of 52", "calendar", JohoColors.cyan, "ISO 8601 divides each year into 52 or 53 weeks. Week 1 is the week containing the first Thursday of the year. Swedes organize their lives by week numbers."))

        if let range = calendar.range(of: .day, in: .month, for: today) {
            let daysLeft = range.count - day
            if daysLeft > 0 && daysLeft <= 10 {
                facts.append(("cal_month_end", "\(daysLeft) days left this month", "clock.fill", JohoColors.purple, "The month is almost over. Time to wrap up monthly goals and prepare for the next chapter."))
            }
            let progress = Int((Double(day) / Double(range.count)) * 100)
            facts.append(("cal_progress", "\(progress)% through the month", "chart.pie.fill", JohoColors.green, "Track your monthly progress. This percentage shows how far through the current month we are."))
        }

        // Year progress - green/growth
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        facts.append(("cal_year", "\(Int(Double(dayOfYear) / 365.0 * 100))% through the year", "chart.bar.fill", JohoColors.green, "Another day, another step through the year. This shows how far along we are in the current calendar year."))

        // Weekday facts - distinct colors
        if weekday == 1 { facts.append(("cal_sunday", "Sunday: rest day", "bed.double.fill", JohoColors.purple, "Sunday is traditionally a day of rest in many cultures. Named after the Sun, it's perfect for recharging before the new week.")) }
        else if weekday == 6 { facts.append(("cal_friday_is", "It's Friday!", "star.fill", JohoColors.yellow, "TGIF! Friday is named after Norse goddess Frigg. In Sweden, Fridays mean 'fredagsmys' - cozy evenings with family, snacks, and TV.")) }
        else if weekday == 7 { facts.append(("cal_saturday", "Saturday vibes", "sun.max.fill", Color(hex: "F97316"), "Saturday is the day for errands, adventures, or simply doing nothing. Named after Saturn, the Roman god of agriculture.")) }

        // Seasonal facts - month-appropriate colors
        switch month {
        case 1: facts.append(("cal_jan", "New year, new week numbers", "star.fill", JohoColors.yellow, "January resets our week counter! Week 1 begins, and Swedes everywhere start planning their year by week numbers."))
        case 6: facts.append(("cal_jun", "Midsommar approaches", "sun.max.fill", Color(hex: "F97316"), "June brings the longest days and Sweden's beloved Midsommar celebration - dancing around the maypole, eating pickled herring, and celebrating the midnight sun."))
        case 12: facts.append(("cal_dec", "December: cozy season", "snowflake", JohoColors.cyan, "December brings Advent calendars, Lucia celebrations, glögg (mulled wine), and of course - Donald Duck on TV at 3 PM on Christmas Eve."))
        default: break
        }

        let available = facts.filter { !usedFactIDs.contains($0.id) }
        guard !available.isEmpty else { return nil }

        // 情報デザイン: True random selection for variety
        let picked = available.randomElement()!
        usedFactIDs.insert(picked.id)

        return GlanceFact(id: picked.id, text: picked.text, icon: picked.icon, color: picked.color, explanation: picked.explanation)
    }

    // MARK: - Helpers (情報デザイン: Strong colors like Star page)

    private func iconFor(category: QuirkyFact.Category) -> String {
        switch category {
        case .tradition: return "person.2.fill"
        case .food: return "fork.knife"
        case .invention: return "lightbulb.fill"
        case .nature: return "leaf.fill"
        case .history: return "book.fill"
        case .quirky: return "star.fill"
        }
    }

    /// 情報デザイン: Use semantic colors by CATEGORY (not region flags)
    /// Strong colors like Star page month icons
    private func colorFor(category: QuirkyFact.Category) -> Color {
        switch category {
        case .tradition: return JohoColors.purple    // People zone
        case .food: return Color(hex: "F97316")      // Orange - warm/food
        case .invention: return JohoColors.yellow    // Ideas/bright
        case .nature: return JohoColors.green        // Nature zone
        case .history: return Color(hex: "78350F")   // Brown - heritage
        case .quirky: return JohoColors.cyan         // General info
        }
    }
}
