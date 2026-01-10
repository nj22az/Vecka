//
//  EntryTypeDetector.swift
//  Vecka
//
//  Smart input analyzer for unified entry form
//  Detects likely entry types from user text input
//

import Foundation

/// Smart detection service for entry type suggestions
/// Analyzes user input and suggests the most likely entry type
struct EntryTypeDetector {

    // MARK: - Detection Result

    struct DetectionResult {
        let suggestedType: EntryType
        let confidence: Double // 0.0 - 1.0
        let matchedPattern: String?
    }

    // MARK: - Pattern Definitions

    /// Currency/number patterns for expenses
    private static let expensePatterns: [String] = [
        #"\$\d+"#,                           // $50
        #"\d+\s*(kr|sek|usd|eur|vnd|dong)"#, // 100kr, 50 SEK, 1000 vnd
        #"\d+[.,]\d{2}\b"#,                  // 20.50 or 20,50
        #"^\d+$"#,                           // Just a number
        #"\d+\s*(dollars?|kronor?|euro)"#    // 50 dollars, 100 kronor
    ]

    /// Location/trip keywords (English + Swedish)
    private static let tripKeywords: [String] = [
        "trip to", "flight to", "travel to", "visit", "vacation",
        "holiday in", "going to", "flying to", "drive to",
        "resa till", "flyg till", "semester", "åka till"
    ]

    /// Holiday/celebration keywords (English + Swedish)
    private static let holidayKeywords: [String] = [
        "christmas", "easter", "new year", "midsummer", "thanksgiving",
        "halloween", "valentine", "national day", "independence",
        "jul", "påsk", "nyår", "midsommar", "alla helgons",
        "lucia", "valborg", "kräftskiva"
    ]

    /// Name patterns for birthday/contact detection
    private static let namePatterns: [String] = [
        #"^[A-ZÅÄÖ][a-zåäö]+$"#,                           // Single name: Anna
        #"^[A-ZÅÄÖ][a-zåäö]+\s+[A-ZÅÄÖ][a-zåäö]+$"#,     // Full name: Anna Svensson
        #"^[A-ZÅÄÖ][a-zåäö]+\s+[A-ZÅÄÖ]\.$"#              // Name + initial: Anna S.
    ]

    // MARK: - Main Detection

    /// Analyze input text and suggest an entry type
    /// Returns nil if no strong match is found (user stays on current type)
    static func analyze(_ input: String) -> DetectionResult? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count >= 2 else { return nil }

        // Priority 1: Expense patterns (highest specificity)
        if matchesAny(text: trimmed, patterns: expensePatterns) {
            return DetectionResult(
                suggestedType: .expense,
                confidence: 0.85,
                matchedPattern: "currency/number"
            )
        }

        // Priority 2: Trip keywords
        if containsAnyKeyword(text: trimmed, keywords: tripKeywords) {
            return DetectionResult(
                suggestedType: .trip,
                confidence: 0.80,
                matchedPattern: "trip keyword"
            )
        }

        // Priority 3: Holiday keywords
        if containsAnyKeyword(text: trimmed, keywords: holidayKeywords) {
            return DetectionResult(
                suggestedType: .holiday,
                confidence: 0.75,
                matchedPattern: "holiday keyword"
            )
        }

        // Priority 4: Name patterns (birthday)
        if matchesAny(text: trimmed, patterns: namePatterns) {
            return DetectionResult(
                suggestedType: .birthday,
                confidence: 0.65,
                matchedPattern: "name pattern"
            )
        }

        // No strong match - return nil (no suggestion)
        return nil
    }

    // MARK: - Helpers

    private static func matchesAny(text: String, patterns: [String]) -> Bool {
        patterns.contains { pattern in
            text.range(
                of: pattern,
                options: [.regularExpression, .caseInsensitive]
            ) != nil
        }
    }

    private static func containsAnyKeyword(text: String, keywords: [String]) -> Bool {
        let lowercased = text.lowercased()
        return keywords.contains { lowercased.contains($0) }
    }
}
