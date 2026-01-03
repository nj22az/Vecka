//
//  DuplicateSuggestion.swift
//  Vecka
//
//  SwiftData model for tracking duplicate contact suggestions
//

import Foundation
import SwiftData

/// Represents a potential duplicate contact pair detected by the duplicate detection system
@Model
final class DuplicateSuggestion {
    /// Unique identifier
    var id: UUID

    /// When this suggestion was created
    var createdAt: Date

    /// First contact's persistent ID
    var contact1Id: UUID

    /// Second contact's persistent ID
    var contact2Id: UUID

    /// Calculated similarity score (0-100)
    /// Threshold of 50+ indicates likely duplicate
    var score: Int

    /// Comma-separated list of match reasons (e.g., "email,phone,name")
    var matchReasons: String

    /// Status: "pending", "merged", "dismissed"
    var status: String

    /// When the user made a decision (merged or dismissed)
    var decidedAt: Date?

    init(
        contact1Id: UUID,
        contact2Id: UUID,
        score: Int,
        matchReasons: [String]
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.contact1Id = contact1Id
        self.contact2Id = contact2Id
        self.score = score
        self.matchReasons = matchReasons.joined(separator: ",")
        self.status = "pending"
        self.decidedAt = nil
    }

    /// Parse match reasons back to array
    var matchReasonsArray: [String] {
        matchReasons.split(separator: ",").map(String.init)
    }

    /// Check if this suggestion involves a specific contact
    func involvesContact(id: UUID) -> Bool {
        contact1Id == id || contact2Id == id
    }
}

// MARK: - Match Reason Types

enum DuplicateMatchReason: String, CaseIterable {
    case email = "email"
    case phone = "phone"
    case fullName = "name"
    case fuzzyName = "fuzzy_name"
    case birthday = "birthday"
    case organization = "organization"

    var displayName: String {
        switch self {
        case .email: return "Email"
        case .phone: return "Phone"
        case .fullName: return "Name"
        case .fuzzyName: return "Similar Name"
        case .birthday: return "Birthday"
        case .organization: return "Organization"
        }
    }

    var icon: String {
        switch self {
        case .email: return "envelope.fill"
        case .phone: return "phone.fill"
        case .fullName, .fuzzyName: return "person.fill"
        case .birthday: return "gift.fill"
        case .organization: return "building.2.fill"
        }
    }

    /// Weight for scoring
    var weight: Int {
        switch self {
        case .email: return 40      // Strong indicator
        case .phone: return 35      // Strong indicator
        case .fullName: return 25   // Moderate indicator
        case .fuzzyName: return 15  // Weak indicator
        case .birthday: return 20   // Supporting evidence
        case .organization: return 10 // Supporting evidence
        }
    }
}
