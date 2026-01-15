//
//  EntryType.swift
//  Vecka
//
//  情報デザイン: Unified entry type for ALL calendar entries
//  Single entry point with type-based dynamic forms
//  SF Pro symbols only - NO emojis
//

import SwiftUI

/// Entry type for unified form
/// Each type maps to an existing SwiftData model:
/// - .note → DailyNote
/// - .trip → TravelTrip
/// - .expense → ExpenseItem
/// - .holiday → HolidayRule
/// - .birthday → Contact (birthday field)
enum EntryType: String, CaseIterable, Identifiable {
    case note = "note"
    case trip = "trip"
    case expense = "expense"
    case holiday = "holiday"
    case birthday = "birthday"
    case event = "event"

    var id: String { rawValue }

    /// SF Symbol icon for this entry type (情報デザイン: clear, self-explanatory icons)
    var icon: String {
        switch self {
        case .note: return "square.and.pencil"      // Clear "write note" icon
        case .trip: return "airplane"               // Universally understood
        case .expense: return "dollarsign.circle"    // Clean money icon
        case .holiday: return "star.fill"           // Celebration/special
        case .birthday: return "gift.fill"          // Birthday gift
        case .event: return "calendar.badge.clock"  // Countdown/event
        }
    }

    /// Semantic color for this entry type (情報デザイン 6-color palette)
    /// Yellow=NOW, Cyan=SCHEDULED, Pink=CELEBRATION, Green=MONEY
    var color: Color {
        switch self {
        case .note: return JohoColors.yellow        // NOW - present moment items
        case .trip: return JohoColors.cyan          // SCHEDULED - time-based items
        case .expense: return JohoColors.green      // MONEY - financial items
        case .holiday: return JohoColors.pink       // CELEBRATION - special days
        case .birthday: return Color(hex: "78350F") // PEOPLE - matches contacts brown
        case .event: return JohoColors.cyan         // SCHEDULED - countdown events
        }
    }

    /// Light background tint for form sections
    var lightBackground: Color {
        color.opacity(0.1)
    }

    /// Header background color
    var headerBackground: Color {
        color.opacity(0.7)
    }

    /// Display name for UI (情報デザイン: uppercase, compact)
    var displayName: String {
        switch self {
        case .note: return "NOTE"
        case .trip: return "TRIP"
        case .expense: return "EXPENSE"
        case .holiday: return "HOLIDAY"
        case .birthday: return "BIRTHDAY"
        case .event: return "EVENT"
        }
    }

    /// Short code for compact display (3 chars)
    var code: String {
        switch self {
        case .note: return "NOT"
        case .trip: return "TRP"
        case .expense: return "EXP"
        case .holiday: return "HOL"
        case .birthday: return "BDY"
        case .event: return "EVT"
        }
    }

    /// Subtitle hint for UI
    var subtitle: String {
        switch self {
        case .note: return "Quick note or reminder"
        case .trip: return "Plan your journey"
        case .expense: return "Track spending"
        case .holiday: return "Official or observance"
        case .birthday: return "Add to contacts"
        case .event: return "Countdown with tasks"
        }
    }

    /// Required fields description
    var requiredFieldsHint: String {
        switch self {
        case .note: return "Content"
        case .trip: return "Destination"
        case .expense: return "Amount + Description"
        case .holiday: return "Name + Date"
        case .birthday: return "Name + Date"
        case .event: return "Name + Date"
        }
    }
}

/// Combined Entry button styling
extension EntryType {
    /// Black color for unified Entry button (情報デザイン: neutral)
    static var entryButtonColor: Color {
        JohoColors.black
    }

    /// Icon for unified Entry button
    static var entryButtonIcon: String {
        "plus"
    }
}
