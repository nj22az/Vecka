//
//  HolidayRegionSelection.swift
//  Vecka
//

import Foundation

struct HolidayRegionSelection: RawRepresentable, Equatable, Hashable, Sendable {
    private(set) var regions: [String]

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

    static func normalized(_ input: [String], maxCount: Int = 2) -> [String] {
        var seen = Set<String>()
        var output: [String] = []
        output.reserveCapacity(min(maxCount, input.count))

        for raw in input {
            let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard !code.isEmpty else { continue }
            guard !seen.contains(code) else { continue }
            seen.insert(code)
            output.append(code)
            if output.count >= maxCount { break }
        }

        return output
    }

    var primaryRegion: String? {
        regions.first
    }

    var containsVietnam: Bool {
        regions.contains("VN")
    }

    mutating func addRegionIfPossible(_ code: String, maxCount: Int = 2) -> Bool {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { return false }
        guard !regions.contains(normalized) else { return true }
        guard regions.count < maxCount else { return false }
        regions.append(normalized)
        return true
    }

    mutating func removeRegionIfPossible(_ code: String, minimumCount: Int = 1) -> Bool {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard regions.contains(normalized) else { return false }
        guard regions.count > minimumCount else { return false }
        regions.removeAll(where: { $0 == normalized })
        return true
    }
}

