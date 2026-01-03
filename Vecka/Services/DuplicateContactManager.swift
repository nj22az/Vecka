//
//  DuplicateContactManager.swift
//  Vecka
//
//  Intelligent duplicate contact detection and merge functionality
//  Scoring weights are database-driven via AlgorithmParameter
//

import Foundation
import SwiftData

// MARK: - Duplicate Contact Manager

@MainActor
@Observable
class DuplicateContactManager {
    static let shared = DuplicateContactManager()

    /// Default weights (used when database not seeded)
    private static let defaultWeights: [String: Double] = [
        "email": 40,
        "phone": 35,
        "full_name": 25,
        "fuzzy_name": 15,
        "birthday": 20,
        "organization": 10,
        "threshold": 50,
        "fuzzy_similarity_threshold": 0.8,
        "phone_suffix_min_length": 7
    ]

    /// Cached weights from database
    private var cachedWeights: [String: Double]?

    private init() {}

    // MARK: - Database-Driven Configuration

    /// Load scoring weights from database (caches result)
    private func loadWeights(modelContext: ModelContext) -> [String: Double] {
        if let cached = cachedWeights {
            return cached
        }

        let params = ConfigurationManager.shared.getAlgorithmParameters(
            for: "duplicate_contact_detection",
            context: modelContext
        )

        // Merge database params with defaults (database takes precedence)
        var weights = Self.defaultWeights
        for (key, value) in params {
            weights[key] = value
        }

        cachedWeights = weights
        return weights
    }

    /// Get a specific weight value
    private func getWeight(_ key: String, modelContext: ModelContext) -> Double {
        let weights = loadWeights(modelContext: modelContext)
        return weights[key] ?? Self.defaultWeights[key] ?? 0
    }

    /// Invalidate cache (call when parameters change)
    func invalidateCache() {
        cachedWeights = nil
    }

    /// Get duplicate threshold from database
    private func getDuplicateThreshold(modelContext: ModelContext) -> Int {
        Int(getWeight("threshold", modelContext: modelContext))
    }

    // MARK: - Duplicate Detection

    /// Scan all contacts for potential duplicates
    func scanForDuplicates(contacts: [Contact], modelContext: ModelContext) async {
        // Clear any existing pending suggestions for contacts that no longer exist
        await cleanupOrphanedSuggestions(modelContext: modelContext)

        // Get existing dismissed suggestions to avoid re-suggesting
        let dismissedPairs = await getDismissedPairs(modelContext: modelContext)

        var newSuggestions: [DuplicateSuggestion] = []

        // Compare each pair of contacts
        for i in 0..<contacts.count {
            for j in (i + 1)..<contacts.count {
                let contact1 = contacts[i]
                let contact2 = contacts[j]

                // Skip if already dismissed
                let pairKey = makePairKey(contact1.id, contact2.id)
                if dismissedPairs.contains(pairKey) {
                    continue
                }

                // Calculate similarity score (using database-driven weights)
                let result = calculateSimilarity(contact1: contact1, contact2: contact2, modelContext: modelContext)

                let threshold = getDuplicateThreshold(modelContext: modelContext)
                if result.score >= threshold {
                    // Check if suggestion already exists
                    let existingSuggestion = await findExistingSuggestion(
                        contact1Id: contact1.id,
                        contact2Id: contact2.id,
                        modelContext: modelContext
                    )

                    if existingSuggestion == nil {
                        let suggestion = DuplicateSuggestion(
                            contact1Id: contact1.id,
                            contact2Id: contact2.id,
                            score: result.score,
                            matchReasons: result.reasons.map(\.rawValue)
                        )
                        newSuggestions.append(suggestion)
                    }
                }
            }
        }

        // Insert new suggestions
        for suggestion in newSuggestions {
            modelContext.insert(suggestion)
        }

        try? modelContext.save()
    }

    /// Calculate similarity between two contacts (using database-driven weights)
    private func calculateSimilarity(contact1: Contact, contact2: Contact, modelContext: ModelContext) -> (score: Int, reasons: [DuplicateMatchReason]) {
        var score = 0
        var reasons: [DuplicateMatchReason] = []

        // Check email matches
        if hasMatchingEmail(contact1: contact1, contact2: contact2) {
            score += Int(getWeight("email", modelContext: modelContext))
            reasons.append(.email)
        }

        // Check phone matches (normalized)
        if hasMatchingPhone(contact1: contact1, contact2: contact2, modelContext: modelContext) {
            score += Int(getWeight("phone", modelContext: modelContext))
            reasons.append(.phone)
        }

        // Check exact name match
        let name1 = contact1.displayName.lowercased().trimmingCharacters(in: .whitespaces)
        let name2 = contact2.displayName.lowercased().trimmingCharacters(in: .whitespaces)

        if !name1.isEmpty && name1 == name2 {
            score += Int(getWeight("full_name", modelContext: modelContext))
            reasons.append(.fullName)
        } else if !name1.isEmpty && !name2.isEmpty {
            // Check fuzzy name match (database-driven threshold)
            let similarity = calculateNameSimilarity(name1: name1, name2: name2)
            let fuzzyThreshold = getWeight("fuzzy_similarity_threshold", modelContext: modelContext)
            if similarity >= fuzzyThreshold {
                score += Int(getWeight("fuzzy_name", modelContext: modelContext))
                reasons.append(.fuzzyName)
            }
        }

        // Check birthday match
        if let bday1 = contact1.birthday, let bday2 = contact2.birthday {
            let calendar = Calendar.current
            if calendar.isDate(bday1, equalTo: bday2, toGranularity: .day) {
                score += Int(getWeight("birthday", modelContext: modelContext))
                reasons.append(.birthday)
            }
        }

        // Check organization match
        if let org1 = contact1.organizationName?.lowercased().trimmingCharacters(in: .whitespaces),
           let org2 = contact2.organizationName?.lowercased().trimmingCharacters(in: .whitespaces),
           !org1.isEmpty && org1 == org2 {
            score += Int(getWeight("organization", modelContext: modelContext))
            reasons.append(.organization)
        }

        return (score, reasons)
    }

    // MARK: - Email Matching

    private func hasMatchingEmail(contact1: Contact, contact2: Contact) -> Bool {
        let emails1 = Set(contact1.emailAddresses.map { $0.value.lowercased().trimmingCharacters(in: .whitespaces) })
        let emails2 = Set(contact2.emailAddresses.map { $0.value.lowercased().trimmingCharacters(in: .whitespaces) })

        return !emails1.isDisjoint(with: emails2)
    }

    // MARK: - Phone Matching (Normalized)

    private func hasMatchingPhone(contact1: Contact, contact2: Contact, modelContext: ModelContext) -> Bool {
        let phones1 = contact1.phoneNumbers.map { normalizePhone($0.value) }
        let phones2 = contact2.phoneNumbers.map { normalizePhone($0.value) }

        let minLength = Int(getWeight("phone_suffix_min_length", modelContext: modelContext))

        for phone1 in phones1 {
            for phone2 in phones2 {
                if phonesMatch(phone1, phone2, minLength: minLength) {
                    return true
                }
            }
        }
        return false
    }

    /// Normalize phone number by removing non-digits and handling country codes
    private func normalizePhone(_ phone: String) -> String {
        // Remove all non-digit characters
        var digits = phone.filter { $0.isNumber }

        // Handle Swedish numbers: +46 or 0046 → remove prefix, add 0
        if digits.hasPrefix("46") && digits.count >= 10 {
            digits = "0" + digits.dropFirst(2)
        } else if digits.hasPrefix("0046") {
            digits = "0" + digits.dropFirst(4)
        }

        // Handle US numbers: +1 or 001 → remove prefix
        if digits.hasPrefix("1") && digits.count == 11 {
            digits = String(digits.dropFirst())
        } else if digits.hasPrefix("001") && digits.count >= 12 {
            digits = String(digits.dropFirst(3))
        }

        return digits
    }

    /// Check if two normalized phone numbers match (also checks suffix match for partial numbers)
    private func phonesMatch(_ phone1: String, _ phone2: String, minLength: Int) -> Bool {
        // Exact match
        if phone1 == phone2 && !phone1.isEmpty {
            return true
        }

        // Suffix match (for partial international numbers)
        if phone1.count >= minLength && phone2.count >= minLength {
            let suffix1 = String(phone1.suffix(minLength))
            let suffix2 = String(phone2.suffix(minLength))
            if suffix1 == suffix2 {
                return true
            }
        }

        return false
    }

    // MARK: - Name Similarity (Levenshtein Distance)

    private func calculateNameSimilarity(name1: String, name2: String) -> Double {
        let distance = levenshteinDistance(name1, name2)
        let maxLength = max(name1.count, name2.count)
        guard maxLength > 0 else { return 1.0 }
        return 1.0 - (Double(distance) / Double(maxLength))
    }

    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count

        if m == 0 { return n }
        if n == 0 { return m }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,       // deletion
                    matrix[i][j - 1] + 1,       // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[m][n]
    }

    // MARK: - Merge Contacts

    /// Merge secondary contact into primary, keeping primary's identity
    func mergeContacts(
        primary: Contact,
        secondary: Contact,
        suggestion: DuplicateSuggestion,
        modelContext: ModelContext
    ) {
        // Merge phone numbers (avoid duplicates)
        let existingPhones = Set(primary.phoneNumbers.map { normalizePhone($0.value) })
        for phone in secondary.phoneNumbers {
            if !existingPhones.contains(normalizePhone(phone.value)) {
                primary.phoneNumbers.append(phone)
            }
        }

        // Merge email addresses (avoid duplicates)
        let existingEmails = Set(primary.emailAddresses.map { $0.value.lowercased() })
        for email in secondary.emailAddresses {
            if !existingEmails.contains(email.value.lowercased()) {
                primary.emailAddresses.append(email)
            }
        }

        // Merge postal addresses (avoid duplicates by comparing formatted address)
        let existingAddresses = Set(primary.postalAddresses.map { $0.formattedAddress.lowercased() })
        for address in secondary.postalAddresses {
            if !existingAddresses.contains(address.formattedAddress.lowercased()) {
                primary.postalAddresses.append(address)
            }
        }

        // Take birthday from secondary if primary doesn't have one
        if primary.birthday == nil && secondary.birthday != nil {
            primary.birthday = secondary.birthday
        }

        // Append notes with separator
        if let secondaryNote = secondary.note, !secondaryNote.isEmpty {
            if let primaryNote = primary.note, !primaryNote.isEmpty {
                primary.note = "\(primaryNote)\n\n---\nMerged from \(secondary.displayName):\n\(secondaryNote)"
            } else {
                primary.note = secondaryNote
            }
        }

        // Take photo from secondary if primary doesn't have one
        if primary.imageData == nil && secondary.imageData != nil {
            primary.imageData = secondary.imageData
        }

        // Take organization from secondary if primary doesn't have one
        if (primary.organizationName == nil || primary.organizationName?.isEmpty == true) &&
           secondary.organizationName != nil && !secondary.organizationName!.isEmpty {
            primary.organizationName = secondary.organizationName
        }

        // Update timestamp
        primary.modifiedAt = Date()

        // Mark suggestion as merged
        suggestion.status = "merged"
        suggestion.decidedAt = Date()

        // Delete secondary contact
        modelContext.delete(secondary)

        try? modelContext.save()
    }

    /// Dismiss a duplicate suggestion (never suggest this pair again)
    func dismissSuggestion(_ suggestion: DuplicateSuggestion, modelContext: ModelContext) {
        suggestion.status = "dismissed"
        suggestion.decidedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Query Helpers

    /// Load all pending duplicate suggestions
    func loadPendingSuggestions(modelContext: ModelContext) -> [DuplicateSuggestion] {
        let descriptor = FetchDescriptor<DuplicateSuggestion>(
            predicate: #Predicate { $0.status == "pending" },
            sortBy: [SortDescriptor(\.score, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Find existing suggestion for a contact pair
    private func findExistingSuggestion(
        contact1Id: UUID,
        contact2Id: UUID,
        modelContext: ModelContext
    ) async -> DuplicateSuggestion? {
        let descriptor = FetchDescriptor<DuplicateSuggestion>(
            predicate: #Predicate {
                ($0.contact1Id == contact1Id && $0.contact2Id == contact2Id) ||
                ($0.contact1Id == contact2Id && $0.contact2Id == contact1Id)
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    /// Get all dismissed contact pairs to avoid re-suggesting
    private func getDismissedPairs(modelContext: ModelContext) async -> Set<String> {
        let descriptor = FetchDescriptor<DuplicateSuggestion>(
            predicate: #Predicate { $0.status == "dismissed" }
        )
        let dismissed = (try? modelContext.fetch(descriptor)) ?? []
        return Set(dismissed.map { makePairKey($0.contact1Id, $0.contact2Id) })
    }

    /// Clean up suggestions where one or both contacts no longer exist
    private func cleanupOrphanedSuggestions(modelContext: ModelContext) async {
        // Get all contact IDs
        let contactDescriptor = FetchDescriptor<Contact>()
        let contacts = (try? modelContext.fetch(contactDescriptor)) ?? []
        let contactIds = Set(contacts.map(\.id))

        // Get all suggestions
        let suggestionDescriptor = FetchDescriptor<DuplicateSuggestion>(
            predicate: #Predicate { $0.status == "pending" }
        )
        let suggestions = (try? modelContext.fetch(suggestionDescriptor)) ?? []

        // Delete orphaned suggestions
        for suggestion in suggestions {
            if !contactIds.contains(suggestion.contact1Id) || !contactIds.contains(suggestion.contact2Id) {
                modelContext.delete(suggestion)
            }
        }

        try? modelContext.save()
    }

    /// Create a unique key for a contact pair (order-independent)
    private func makePairKey(_ id1: UUID, _ id2: UUID) -> String {
        let sorted = [id1.uuidString, id2.uuidString].sorted()
        return "\(sorted[0])_\(sorted[1])"
    }
}
