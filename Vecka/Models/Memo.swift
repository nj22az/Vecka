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
    // MARK: - Scheduling (from DailyNote)
    // ═══════════════════════════════════════════════════════════════════

    /// Scheduled time for this memo (e.g., an appointment)
    var scheduledAt: Date?

    /// Duration in seconds (for meetings, tasks)
    var duration: TimeInterval?

    /// SF Symbol name for visual categorization
    var symbolName: String?

    /// Pin to dashboard for quick access
    var pinnedToDashboard: Bool?

    /// User-defined color hex (overrides semantic color)
    var color: String?

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Countdown (from CountdownEvent)
    // ═══════════════════════════════════════════════════════════════════

    /// Is this a countdown event?
    var isCountdown: Bool?

    /// SF Symbol for countdown display
    var countdownIcon: String?

    /// Is this a system-generated countdown (like "Next Christmas")?
    var isSystemCountdown: Bool?

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Trip (from TravelTrip)
    // ═══════════════════════════════════════════════════════════════════

    /// End date for trips (date field is start date)
    var tripEndDate: Date?

    /// Trip purpose/type
    var tripPurpose: String?

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Computed
    // ═══════════════════════════════════════════════════════════════════

    /// Does this memo have money details?
    var hasMoney: Bool { amount != nil && amount! > 0 }

    /// Does this memo have a place?
    var hasPlace: Bool { place != nil && !place!.isEmpty }

    /// Does this memo have a person?
    var hasPerson: Bool { person != nil && !person!.isEmpty }

    /// Is this a countdown?
    var hasCountdown: Bool { isCountdown == true }

    /// Is this a trip?
    var hasTrip: Bool { tripEndDate != nil }

    /// Is this scheduled?
    var hasSchedule: Bool { scheduledAt != nil }

    /// Is this pinned?
    var isPinned: Bool { pinnedToDashboard == true }

    /// Short preview for lists
    var preview: String {
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Memo" : String(trimmed.prefix(50))
    }

    /// 情報デザイン color based on content
    var colorHex: String {
        // User-defined color takes precedence
        if let customColor = color, !customColor.isEmpty {
            return customColor
        }
        // Countdown events use pink (celebration)
        if hasCountdown { return "FECDD3" }   // Pink (祝) - CELEBRATION
        // Money memos use green
        if hasMoney { return "BBF7D0" }       // Green (金) - MONEY
        // Place/trip memos use cyan
        if hasPlace || hasTrip { return "A5F3FC" }  // Cyan (予定) - SCHEDULED
        // Person memos use purple
        if hasPerson { return "E9D5FF" }      // Purple (人) - PERSON
        // Default is yellow
        return "FFE566"                        // Yellow (今) - NOW
    }

    /// Days until countdown target
    var daysUntilTarget: Int? {
        guard hasCountdown else { return nil }
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: now, to: target).day
    }

    /// Trip duration in days
    var tripDuration: Int? {
        guard let endDate = tripEndDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: endDate)
        return (components.day ?? 0) + 1
    }

    /// Formatted amount with currency
    var formattedAmount: String {
        guard let amount = amount else { return "" }
        let currencyCode = currency ?? "SEK"
        return String(format: "%.0f %@", amount, currencyCode)
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

    /// Countdown event
    static func countdown(_ title: String, targetDate: Date, icon: String = "star.fill", colorHex: String? = nil) -> Memo {
        let memo = Memo(text: title, date: targetDate)
        memo.isCountdown = true
        memo.countdownIcon = icon
        memo.color = colorHex
        return memo
    }

    /// System countdown (auto-calculated like "Next Christmas")
    static func systemCountdown(_ title: String, targetDate: Date, icon: String) -> Memo {
        let memo = countdown(title, targetDate: targetDate, icon: icon)
        memo.isSystemCountdown = true
        return memo
    }

    /// Trip event
    static func trip(_ name: String, startDate: Date, endDate: Date, destination: String? = nil, purpose: String? = nil) -> Memo {
        let memo = Memo(text: name, date: startDate)
        memo.tripEndDate = endDate
        memo.place = destination
        memo.tripPurpose = purpose
        return memo
    }

    /// Scheduled appointment
    static func scheduled(_ text: String, date: Date, time: Date, duration: TimeInterval? = nil, symbol: String? = nil) -> Memo {
        let memo = Memo(text: text, date: date)
        memo.scheduledAt = time
        memo.duration = duration
        memo.symbolName = symbol
        return memo
    }

    /// Pinned memo
    static func pinned(_ text: String, date: Date = Date()) -> Memo {
        let memo = Memo(text: text, date: date)
        memo.pinnedToDashboard = true
        memo.priority = .high
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

    /// Fetch all countdowns
    static func countdowns(in context: ModelContext) -> [Memo] {
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.isCountdown == true
            },
            sortBy: [SortDescriptor(\.date)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch future countdowns only
    static func futureCountdowns(in context: ModelContext) -> [Memo] {
        let now = Date()
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.isCountdown == true && memo.date > now
            },
            sortBy: [SortDescriptor(\.date)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch all trips
    static func trips(in context: ModelContext) -> [Memo] {
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.tripEndDate != nil
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch pinned memos
    static func pinned(in context: ModelContext) -> [Memo] {
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.pinnedToDashboard == true
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch scheduled memos for a date
    static func scheduled(for date: Date, in context: ModelContext) -> [Memo] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.scheduledAt != nil &&
                memo.scheduledAt! >= dayStart &&
                memo.scheduledAt! < dayEnd
            },
            sortBy: [SortDescriptor(\.scheduledAt)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch all memos (for migration and listing)
    static func all(in context: ModelContext) -> [Memo] {
        let descriptor = FetchDescriptor<Memo>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }
}
