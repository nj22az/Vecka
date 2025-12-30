//
//  DailyNote.swift
//  Vecka
//
//  SwiftData model for persistent daily notes
//  Replaces legacy UserDefaults storage
//

import Foundation
import SwiftData

@Model
final class DailyNote {
    /// The day this note belongs to (start of day, used for querying/grouping).
    /// Stored separately from `date` so the app can support multiple notes per day.
    var day: Date = Date.distantPast
    
    /// The date/time of the note entry (creation timestamp)
    var date: Date
    
    /// The actual note content
    var content: String
    
    /// Timestamp of the last edit
    var lastModified: Date
    
    /// Color category (e.g., "red", "blue", "default")
    var color: String?

    /// Optional SF Symbol name shown for this note.
    var symbolName: String?

    /// If true, show this note in the calendar dashboard (e.g. pinned countdown).
    var pinnedToDashboard: Bool?

    /// Optional scheduled time for this note (e.g. an appointment time).
    /// The date component should match `day`.
    var scheduledAt: Date?
    
    init(
        date: Date,
        content: String,
        color: String? = nil,
        symbolName: String? = nil,
        scheduledAt: Date? = nil,
        pinnedToDashboard: Bool? = nil
    ) {
        self.date = date
        self.day = Calendar.current.startOfDay(for: date)
        self.content = content
        self.color = color
        self.symbolName = symbolName
        self.scheduledAt = scheduledAt
        self.pinnedToDashboard = pinnedToDashboard
        self.lastModified = Date()
    }
}
