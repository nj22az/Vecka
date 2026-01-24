//
//  HolidayRegionSelection.swift
//  Vecka
//

import Foundation

struct HolidayRegionSelection: RawRepresentable, Equatable, Hashable, Sendable {
    private(set) var regions: [String]

    // MARK: - Nordic Unified Region
    /// 情報デザイン: "NORDIC" expands to all Nordic countries and territories
    /// SE=Sweden, NO=Norway, DK=Denmark, FI=Finland, IS=Iceland, GL=Greenland, FO=Faroe Islands
    static let nordicCountries = ["SE", "NO", "DK", "FI", "IS", "GL", "FO"]
    static let nordicCode = "NORDIC"

    init(regions: [String]) {
        self.regions = Self.normalized(regions)
    }

    init(rawValue: String) {
        let codes = rawValue
            .split(separator: ",")
            .map { String($0) }
        self.regions = Self.normalized(codes)
    }

    var rawValue: String {
        regions.joined(separator: ",")
    }

    static func normalized(_ input: [String], maxCount: Int = 5) -> [String] {
        var seen = Set<String>()
        var output: [String] = []
        output.reserveCapacity(min(maxCount, input.count))

        for raw in input {
            let code = raw.trimmed.uppercased()
            guard !code.isEmpty else { continue }
            guard !seen.contains(code) else { continue }
            seen.insert(code)
            output.append(code)
            if output.count >= maxCount { break }
        }

        return output
    }

    /// Expands unified regions (like NORDIC) to their component countries
    /// Use this when querying holidays or facts from the database
    var expandedRegions: [String] {
        var result: [String] = []
        for region in regions {
            if region == Self.nordicCode {
                result.append(contentsOf: Self.nordicCountries)
            } else {
                result.append(region)
            }
        }
        return result
    }

    /// Check if Nordic is selected
    var containsNordic: Bool {
        regions.contains(Self.nordicCode)
    }

    var primaryRegion: String? {
        regions.first
    }

    var containsVietnam: Bool {
        regions.contains("VN")
    }

    mutating func addRegionIfPossible(_ code: String, maxCount: Int = 5) -> Bool {
        let normalized = code.trimmed.uppercased()
        guard !normalized.isEmpty else { return false }
        guard !regions.contains(normalized) else { return true }
        guard regions.count < maxCount else { return false }
        regions.append(normalized)
        return true
    }

    mutating func removeRegionIfPossible(_ code: String, minimumCount: Int = 1) -> Bool {
        let normalized = code.trimmed.uppercased()
        guard regions.contains(normalized) else { return false }
        guard regions.count > minimumCount else { return false }
        regions.removeAll(where: { $0 == normalized })
        return true
    }
}

