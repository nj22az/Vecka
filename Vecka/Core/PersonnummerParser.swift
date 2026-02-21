//
//  PersonnummerParser.swift
//  Vecka
//
//  Swedish personal number (personnummer) parser and birthday extractor
//

import Foundation

/// Represents a parsed Swedish personal number with birthday information
struct BirthdayInfo {
    let name: String
    let birthDate: Date
    let personnummer: String

    var age: Int {
        Calendar.iso8601.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    var nextBirthday: Date {
        let calendar = Calendar.iso8601
        let now = Date()
        let currentYear = calendar.component(.year, from: now)

        var components = calendar.dateComponents([.month, .day], from: birthDate)
        components.year = currentYear

        guard let thisYearBirthday = calendar.date(from: components) else {
            return birthDate
        }

        // If birthday already passed this year, return next year's
        if thisYearBirthday < now {
            components.year = currentYear + 1
            return calendar.date(from: components) ?? birthDate
        }

        return thisYearBirthday
    }

    var daysUntilBirthday: Int {
        let calendar = Calendar.iso8601
        let days = calendar.dateComponents([.day],
                                          from: calendar.startOfDay(for: Date()),
                                          to: calendar.startOfDay(for: nextBirthday)).day ?? 0
        return days
    }

    var ageAtNextBirthday: Int {
        let calendar = Calendar.iso8601
        let years = calendar.dateComponents([.year], from: birthDate, to: nextBirthday).year ?? 0
        return years
    }

    /// Localized birthday description in Swedish
    var localizedDescription: String {
        let birthdayString = DateFormatterCache.swedishDayMonthYear.string(from: nextBirthday)

        if daysUntilBirthday == 0 {
            return "\(name) fyller \(ageAtNextBirthday) år idag! 🎉"
        } else if daysUntilBirthday == 1 {
            return "\(name) fyller \(ageAtNextBirthday) år imorgon (\(birthdayString))"
        } else if daysUntilBirthday < 7 {
            return "\(name) fyller \(ageAtNextBirthday) år om \(daysUntilBirthday) dagar (\(birthdayString))"
        } else if daysUntilBirthday < 30 {
            let weeks = daysUntilBirthday / 7
            return "\(name) fyller \(ageAtNextBirthday) år om \(weeks) \(weeks == 1 ? "vecka" : "veckor") (\(birthdayString))"
        } else if daysUntilBirthday < 90 {
            let months = daysUntilBirthday / 30
            return "\(name) fyller \(ageAtNextBirthday) år om \(months) \(months == 1 ? "månad" : "månader") (\(birthdayString))"
        } else {
            return "\(name) fyller \(ageAtNextBirthday) år den \(birthdayString)"
        }
    }
}

/// Utility for parsing Swedish personal numbers (personnummer)
struct PersonnummerParser {

    /// Attempts to extract birthday information from a note's content
    /// Looks for patterns like "Name födelsedag YYYYMMDDXXXX" or "Name birthday YYYYMMDDXXXX"
    static func extractBirthdayInfo(from text: String) -> BirthdayInfo? {
        // Pattern: Name + (födelsedag|birthday) + 10 or 12 digit personnummer
        let patterns = [
            // Swedish format: "Nils Johansson födelsedag 198301306638" or "19830130-6638"
            "([A-ZÅÄÖ][a-zåäö]+(?: [A-ZÅÄÖ][a-zåäö]+)*?)\\s+(?:födelsedag|birthday)\\s+(\\d{8})[\\-]?(\\d{4})",
            // Short format without hyphen: "Nils Johansson 198301306638"
            "([A-ZÅÄÖ][a-zåäö]+(?: [A-ZÅÄÖ][a-zåäö]+)*?)\\s+(\\d{12})",
            // With hyphen: "Nils Johansson 19830130-6638"
            "([A-ZÅÄÖ][a-zåäö]+(?: [A-ZÅÄÖ][a-zåäö]+)*?)\\s+(\\d{8})\\-(\\d{4})"
        ]

        for pattern in patterns {
            if let info = tryParseWithPattern(text: text, pattern: pattern) {
                return info
            }
        }

        return nil
    }

    private static func tryParseWithPattern(text: String, pattern: String) -> BirthdayInfo? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        // Extract name
        guard let nameRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        let name = String(text[nameRange])

        // Extract date part (YYYYMMDD)
        var dateString: String
        var checkDigits: String

        if match.numberOfRanges == 4 {
            // Pattern with separate date and check digits
            guard let dateRange = Range(match.range(at: 2), in: text),
                  let checkRange = Range(match.range(at: 3), in: text) else {
                return nil
            }
            dateString = String(text[dateRange])
            checkDigits = String(text[checkRange])
        } else if match.numberOfRanges == 3 {
            // 12-digit format
            guard let fullRange = Range(match.range(at: 2), in: text) else {
                return nil
            }
            let fullNumber = String(text[fullRange])
            dateString = String(fullNumber.prefix(8))
            checkDigits = String(fullNumber.suffix(4))
        } else {
            return nil
        }

        // Parse date
        guard let birthDate = parseSwedishDate(dateString) else {
            return nil
        }

        let personnummer = "\(dateString)\(checkDigits)"

        return BirthdayInfo(name: name, birthDate: birthDate, personnummer: personnummer)
    }

    private static func parseSwedishDate(_ dateString: String) -> Date? {
        guard dateString.count == 8 else { return nil }

        let yearString = String(dateString.prefix(4))
        let monthString = String(dateString.dropFirst(4).prefix(2))
        let dayString = String(dateString.suffix(2))

        guard let year = Int(yearString),
              let month = Int(monthString),
              let day = Int(dayString),
              year >= 1900 && year <= 2100,
              month >= 1 && month <= 12,
              day >= 1 && day <= 31 else {
            return nil
        }

        let components = DateComponents(year: year, month: month, day: day)
        return Calendar.iso8601.date(from: components)
    }
}
