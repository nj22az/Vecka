//
//  Memo.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Paper Planner Style
//  Like writing in a paper planner. Everything is just a memo.
//  Add details if you need them: amount, place, person.
//

import Foundation
import SwiftData

// MARK: - Priority (マルバツ)

/// Simple priority - like circling something important
enum MemoPriority: String, Codable, CaseIterable {
    case high       // ◎ Important
    case normal     // ○ Default
    case low        // △ Maybe later

    var symbol: String {
        switch self {
        case .high: return "◎"
        case .normal: return "○"
        case .low: return "△"
        }
    }
}

// MARK: - Memo Model

/// A memo is just something you write down.
/// Like a paper planner - write something, optionally add details.
@Model
final class Memo {

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Core (Every memo has these)
    // ═══════════════════════════════════════════════════════════════════

    var id: UUID

    /// What you want to remember
    var text: String

    /// When
    var date: Date

    /// Priority (optional)
    var priorityRaw: String?
    var priority: MemoPriority {
        get { MemoPriority(rawValue: priorityRaw ?? "") ?? .normal }
        set { priorityRaw = newValue.rawValue }
    }

    /// When created
    var createdAt: Date

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Optional Details (Add if needed)
    // ═══════════════════════════════════════════════════════════════════

    /// Amount (money)
    var amount: Double?

    /// Currency (SEK, USD, EUR, etc.)
    var currency: String?

    /// Place (where)
    var place: String?

    /// Person (who)
    var person: String?

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Computed
    // ═══════════════════════════════════════════════════════════════════

    /// Does this memo have money details?
    var hasMoney: Bool { amount != nil && amount! > 0 }

    /// Does this memo have a place?
    var hasPlace: Bool { place != nil && !place!.isEmpty }

    /// Does this memo have a person?
    var hasPerson: Bool { person != nil && !person!.isEmpty }

    /// Short preview for lists
    var preview: String {
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Memo" : String(trimmed.prefix(50))
    }

    /// 情報デザイン color based on content
    var colorHex: String {
        if hasMoney { return "BBF7D0" }      // Green (金) - MONEY
        if hasPlace { return "A5F3FC" }      // Cyan (予定) - PLACE
        if hasPerson { return "E9D5FF" }     // Purple (人) - PERSON
        return "FFE566"                       // Yellow (今) - DEFAULT
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Init
    // ═══════════════════════════════════════════════════════════════════

    init(
        text: String = "",
        date: Date = Date()
    ) {
        self.id = UUID()
        self.text = text
        self.date = date
        self.createdAt = Date()
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Simple Factory Methods
    // ═══════════════════════════════════════════════════════════════════

    /// Quick memo
    static func quick(_ text: String, date: Date = Date()) -> Memo {
        Memo(text: text, date: date)
    }

    /// Memo with amount
    static func withAmount(_ text: String, amount: Double, currency: String = "SEK", date: Date = Date()) -> Memo {
        let memo = Memo(text: text, date: date)
        memo.amount = amount
        memo.currency = currency
        return memo
    }

    /// Memo with place
    static func withPlace(_ text: String, place: String, date: Date = Date()) -> Memo {
        let memo = Memo(text: text, date: date)
        memo.place = place
        return memo
    }

    /// Memo with person
    static func withPerson(_ text: String, person: String, date: Date = Date()) -> Memo {
        let memo = Memo(text: text, date: date)
        memo.person = person
        return memo
    }
}

// MARK: - Queries

extension Memo {

    /// Fetch memos for a date
    static func forDate(_ date: Date, in context: ModelContext) -> [Memo] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.date >= dayStart && memo.date < dayEnd
            },
            sortBy: [SortDescriptor(\.date)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch all memos with amounts (expenses)
    static func withAmounts(in context: ModelContext) -> [Memo] {
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.amount != nil
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }
}
