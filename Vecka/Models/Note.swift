//
//  Note.swift
//  Vecka
//
//  🎉 UNIFIED NOTE SYSTEM
//  Replaces DailyNote + Memo with single, more powerful model
//  Preserves all features while eliminating redundancy
//
//  Migration: DailyNote + Memo → Note
//

import Foundation
import SwiftData

// MARK: - Priority System (マルバツ from Memo)

/// Simple priority system like circling importance levels
enum NotePriority: String, Codable, CaseIterable {
    case high       // ◎ Important - like circling in a paper planner
    case normal     // ○ Default - standard note
    case low        // △ Maybe later - less important
    
    var symbol: String {
        switch self {
        case .high: return "◎"
        case .normal: return "○"
        case .low: return "△"
        }
    }
    
    var numeric: Int {
        switch self {
        case .high: return 3
        case .normal: return 2
        case .low: return 1
        }
    }
}

// MARK: - Unified Note Model

/// A unified note that combines the best of DailyNote + Memo
/// Supports everything from quick memos to scheduled appointments with expenses
@Model
final class Note {
    // MARK: - Core Identity
    
    /// Unique identifier
    var id: UUID
    
    /// When this note was created
    var createdAt: Date
    
    // MARK: - Core Content
    
    /// The main note content
    var text: String
    
    /// The date this note belongs to (start of day for grouping/querying)
    /// This replaces DailyNote.day and maintains backward compatibility
    var date: Date {
        get {
            // For notes with specific times, use the date as-is
            // For date-only notes, use the day start
            if let scheduledAt = scheduledAt {
                return Calendar.current.startOfDay(for: scheduledAt)
            }
            return Calendar.current.startOfDay(for: _date)
        }
        set {
            _date = newValue
        }
    }
    private var _date: Date = Date()
    
    // MARK: - DailyNote Features (Enhanced Organization)
    
    /// Priority level ("high", "normal", "low") - 情報デザイン マルバツ hierarchy
    var priority: String?
    
    /// Optional SF Symbol name shown for this note
    var symbolName: String?
    
    /// Color category hex (e.g., "FFE566" for yellow)
    var color: String?
    
    /// If true, show this note in the calendar dashboard (e.g., pinned countdown)
    var pinnedToDashboard: Bool?
    
    /// Optional scheduled time for this note (e.g., an appointment time)
    /// The date component should match the day field above
    var scheduledAt: Date?
    
    /// Duration in seconds for time-tracked notes (e.g., meetings, tasks)
    var duration: TimeInterval?
    
    // MARK: - Memo Features (Enhanced Details)
    
    /// Amount (money) - for expense tracking within notes
    var amount: Double?
    
    /// Currency (SEK, USD, EUR, etc.)
    var currency: String?
    
    /// Place (where) - location-based notes
    var place: String?
    
    /// Person (who) - contact-based notes
    var person: String?
    
    
    // MARK: - Computed Properties (Enhanced Logic)
    
    /// Does this note have monetary details?
    var hasMoney: Bool { amount != nil && amount! > 0 }
    
    /// Does this note have a place?
    var hasPlace: Bool { place != nil && !place!.isEmpty }
    
    /// Does this note have a person?
    var hasPerson: Bool { person != nil && !person!.isEmpty }
    
    /// Short preview for lists (truncates at 50 chars)
    var preview: String {
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Note" : String(trimmed.prefix(50))
    }
    
    /// 情報デザイン color based on content (semantic coloring)
    var colorHex: String {
        // Priority-based coloring first
        if priority == NotePriority.high.rawValue {
            return "FF6B6B" // Red for high priority
        }
        
        // Content-based coloring (from Memo system)
        if hasMoney { return "BBF7D0" }      // Green (金) - MONEY
        if hasPlace { return "A5F3FC" }      // Cyan (予定) - PLACE
        if hasPerson { return "E9D5FF" }     // Purple (人) - PERSON
        
        // Use user-defined color, or default yellow
        return color ?? "FFE566"            // Yellow (今) - DEFAULT
    }
    
    /// Formatted amount with currency (from Memo system)
    var formattedAmount: String {
        guard let amount = amount else { return "" }
        let currencyCode = currency ?? "SEK"
        return String(format: "%.0f %@", amount, currencyCode)
    }
    
    /// Whether this note should be displayed prominently
    var isImportant: Bool {
        priority == NotePriority.high.rawValue || pinnedToDashboard == true
    }
    
    // MARK: - Initialization

    init(
        text: String = "",
        date: Date = Date(),
        priority: String? = nil,
        color: String? = nil,
        symbolName: String? = nil,
        pinnedToDashboard: Bool? = nil,
        scheduledAt: Date? = nil,
        duration: TimeInterval? = nil,
        amount: Double? = nil,
        currency: String? = nil,
        place: String? = nil,
        person: String? = nil
    ) {
        self.id = UUID()
        self.text = text
        self._date = date
        self.createdAt = Date()
        self.priority = priority
        self.color = color
        self.symbolName = symbolName
        self.pinnedToDashboard = pinnedToDashboard
        self.scheduledAt = scheduledAt
        self.duration = duration
        self.amount = amount
        self.currency = currency
        self.place = place
        self.person = person
    }
    
    // MARK: - Quick Factory Methods

    /// Quick memo (from Memo system)
    static func quick(_ text: String, date: Date = Date()) -> Note {
        Note(text: text, date: date, priority: NotePriority.normal.rawValue)
    }

    /// Memo with amount (from Memo system)
    static func withAmount(_ text: String, amount: Double, currency: String = "SEK", date: Date = Date()) -> Note {
        let note = Note(text: text, date: date, priority: NotePriority.normal.rawValue)
        note.amount = amount
        note.currency = currency
        return note
    }

    /// Memo with place (from Memo system)
    static func withPlace(_ text: String, place: String, date: Date = Date()) -> Note {
        let note = Note(text: text, date: date, priority: NotePriority.normal.rawValue)
        note.place = place
        return note
    }

    /// Memo with person (from Memo system)
    static func withPerson(_ text: String, person: String, date: Date = Date()) -> Note {
        let note = Note(text: text, date: date, priority: NotePriority.normal.rawValue)
        note.person = person
        return note
    }

    /// Important memo (from both systems)
    static func important(_ text: String, date: Date = Date()) -> Note {
        Note(text: text, date: date, priority: NotePriority.high.rawValue, pinnedToDashboard: true)
    }

    /// Scheduled appointment note
    static func appointment(_ text: String, date: Date, time: Date, duration: TimeInterval = 3600) -> Note {
        let note = Note(text: text, date: date, priority: NotePriority.high.rawValue)
        note.scheduledAt = time
        note.duration = duration
        return note
    }
    
    /// Meeting note (scheduled + duration)
    static func meeting(_ text: String, date: Date, time: Date, duration: TimeInterval) -> Note {
        appointment(text, date: date, time: time, duration: duration)
    }
}

// MARK: - Queries for Unified System

extension Note {
    
    /// Fetch notes for a specific day (replaces DailyNote.forDate)
    static func forDate(_ date: Date, in context: ModelContext) -> [Note] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate<Note> { note in
                note.date >= dayStart && note.date < dayEnd
            },
            sortBy: [SortDescriptor(\.date, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Fetch all notes with amounts (replaces Memo.withAmounts)
    static func withAmounts(in context: ModelContext) -> [Note] {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate<Note> { note in
                note.amount != nil && note.amount! > 0
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Fetch important notes (pinned or high priority)
    static func important(in context: ModelContext) -> [Note] {
        let highPriority = NotePriority.high.rawValue
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate<Note> { note in
                note.priority == highPriority || note.pinnedToDashboard == true
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch notes by person (from Memo system functionality)
    static func forPerson(_ person: String, in context: ModelContext) -> [Note] {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate<Note> { note in
                note.person?.contains(person) == true
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch notes by place (from Memo system functionality)
    static func forPlace(_ place: String, in context: ModelContext) -> [Note] {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate<Note> { note in
                note.place?.contains(place) == true
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch all notes with pagination (for performance)
    static func all(limit: Int = 100, offset: Int = 0, in context: ModelContext) -> [Note] {
        var descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Search notes by text content
    static func search(_ searchText: String, in context: ModelContext) -> [Note] {
        guard !searchText.isEmpty else { return [] }

        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate<Note> { note in
                note.text.contains(searchText)
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }
}