//
//  HolidayChangeLog.swift
//  Vecka
//
//  情報デザイン: Audit trail for holiday database changes
//  Provides transparency and traceability for all modifications
//

import Foundation
import SwiftData

// MARK: - Change Action Types

enum HolidayChangeAction: String, Codable {
    case created = "CREATED"           // New rule added
    case modified = "MODIFIED"         // Existing rule edited
    case deleted = "DELETED"           // Rule removed
    case enabled = "ENABLED"           // Rule re-enabled
    case disabled = "DISABLED"         // Rule disabled (soft delete)
    case reset = "RESET"               // Rule reset to default
    case migrated = "MIGRATED"         // System migration
    case defaultsLoaded = "DEFAULTS"   // Load defaults triggered
}

enum HolidayChangeSource: String, Codable {
    case user = "USER"                 // User action in UI
    case system = "SYSTEM"             // App migration/seed
    case sync = "SYNC"                 // External sync (future)
    case restore = "RESTORE"           // Backup restore
}

// MARK: - Change Log Entry

@Model
final class HolidayChangeLog {
    @Attribute(.unique) var id: UUID

    var timestamp: Date
    var action: HolidayChangeAction
    var source: HolidayChangeSource

    // What was changed
    var ruleId: String              // The HolidayRule.id
    var ruleName: String            // Snapshot of name at time of change
    var region: String              // SE, US, VN, CUSTOM

    // Change details (JSON for flexibility)
    var beforeJSON: String?         // State before change
    var afterJSON: String?          // State after change
    var changeDescription: String   // Human-readable summary

    // Optional metadata
    var appVersion: String?
    var notes: String?

    init(
        action: HolidayChangeAction,
        source: HolidayChangeSource,
        ruleId: String,
        ruleName: String,
        region: String,
        beforeJSON: String? = nil,
        afterJSON: String? = nil,
        changeDescription: String,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.action = action
        self.source = source
        self.ruleId = ruleId
        self.ruleName = ruleName
        self.region = region
        self.beforeJSON = beforeJSON
        self.afterJSON = afterJSON
        self.changeDescription = changeDescription
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        self.notes = notes
    }

    // MARK: - Display Helpers

    var actionIcon: String {
        switch action {
        case .created: return "plus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .deleted: return "trash.circle.fill"
        case .enabled: return "checkmark.circle.fill"
        case .disabled: return "xmark.circle.fill"
        case .reset: return "arrow.counterclockwise.circle.fill"
        case .migrated: return "arrow.triangle.2.circlepath.circle.fill"
        case .defaultsLoaded: return "arrow.down.circle.fill"
        }
    }

    var actionColor: String {
        switch action {
        case .created: return "green"
        case .modified: return "orange"
        case .deleted: return "red"
        case .enabled: return "green"
        case .disabled: return "gray"
        case .reset: return "blue"
        case .migrated: return "purple"
        case .defaultsLoaded: return "cyan"
        }
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var sourceLabel: String {
        switch source {
        case .user: return "User"
        case .system: return "System"
        case .sync: return "Sync"
        case .restore: return "Restore"
        }
    }
}

// MARK: - Change Log Service

@MainActor
final class HolidayChangeLogService {
    static let shared = HolidayChangeLogService()
    private init() {}

    /// Log a holiday rule creation
    func logCreation(
        rule: HolidayRule,
        source: HolidayChangeSource,
        context: ModelContext,
        notes: String? = nil
    ) {
        let entry = HolidayChangeLog(
            action: .created,
            source: source,
            ruleId: rule.id,
            ruleName: rule.name,
            region: rule.region,
            afterJSON: encodeRule(rule),
            changeDescription: "Created '\(rule.name)' in \(regionName(rule.region))",
            notes: notes
        )
        context.insert(entry)
        saveContext(context)
    }

    /// Log a holiday rule modification
    func logModification(
        rule: HolidayRule,
        beforeState: HolidayRuleSnapshot,
        source: HolidayChangeSource,
        context: ModelContext,
        notes: String? = nil
    ) {
        let changes = describeChanges(before: beforeState, after: rule)
        let entry = HolidayChangeLog(
            action: .modified,
            source: source,
            ruleId: rule.id,
            ruleName: rule.name,
            region: rule.region,
            beforeJSON: encodeSnapshot(beforeState),
            afterJSON: encodeRule(rule),
            changeDescription: "Modified '\(rule.name)': \(changes)",
            notes: notes
        )
        context.insert(entry)
        saveContext(context)
    }

    /// Log a holiday rule deletion
    func logDeletion(
        rule: HolidayRule,
        source: HolidayChangeSource,
        context: ModelContext,
        notes: String? = nil
    ) {
        let entry = HolidayChangeLog(
            action: .deleted,
            source: source,
            ruleId: rule.id,
            ruleName: rule.name,
            region: rule.region,
            beforeJSON: encodeRule(rule),
            changeDescription: "Deleted '\(rule.name)' from \(regionName(rule.region))",
            notes: notes
        )
        context.insert(entry)
        saveContext(context)
    }

    /// Log enabling a rule
    func logEnabled(
        rule: HolidayRule,
        source: HolidayChangeSource,
        context: ModelContext
    ) {
        let entry = HolidayChangeLog(
            action: .enabled,
            source: source,
            ruleId: rule.id,
            ruleName: rule.name,
            region: rule.region,
            changeDescription: "Enabled '\(rule.name)'"
        )
        context.insert(entry)
        saveContext(context)
    }

    /// Log disabling a rule
    func logDisabled(
        rule: HolidayRule,
        source: HolidayChangeSource,
        context: ModelContext
    ) {
        let entry = HolidayChangeLog(
            action: .disabled,
            source: source,
            ruleId: rule.id,
            ruleName: rule.name,
            region: rule.region,
            changeDescription: "Disabled '\(rule.name)'"
        )
        context.insert(entry)
        saveContext(context)
    }

    /// Log resetting a rule to default
    func logReset(
        rule: HolidayRule,
        beforeState: HolidayRuleSnapshot,
        source: HolidayChangeSource,
        context: ModelContext
    ) {
        let entry = HolidayChangeLog(
            action: .reset,
            source: source,
            ruleId: rule.id,
            ruleName: rule.name,
            region: rule.region,
            beforeJSON: encodeSnapshot(beforeState),
            afterJSON: encodeRule(rule),
            changeDescription: "Reset '\(rule.name)' to default"
        )
        context.insert(entry)
        saveContext(context)
    }

    /// Log loading defaults for a region
    func logDefaultsLoaded(
        region: String,
        rulesCount: Int,
        source: HolidayChangeSource,
        context: ModelContext
    ) {
        let entry = HolidayChangeLog(
            action: .defaultsLoaded,
            source: source,
            ruleId: "BATCH-\(region)",
            ruleName: "Load Defaults",
            region: region,
            changeDescription: "Loaded \(rulesCount) default rules for \(regionName(region))"
        )
        context.insert(entry)
        saveContext(context)
    }

    /// Log system migration
    func logMigration(
        description: String,
        affectedRules: Int,
        context: ModelContext
    ) {
        let entry = HolidayChangeLog(
            action: .migrated,
            source: .system,
            ruleId: "MIGRATION-\(Date().timeIntervalSince1970)",
            ruleName: "System Migration",
            region: "ALL",
            changeDescription: "\(description) (\(affectedRules) rules)"
        )
        context.insert(entry)
        saveContext(context)
    }

    // MARK: - Query Methods

    /// Get all changelog entries, newest first
    func getAllEntries(context: ModelContext) -> [HolidayChangeLog] {
        let descriptor = FetchDescriptor<HolidayChangeLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get entries for a specific region
    func getEntries(for region: String, context: ModelContext) -> [HolidayChangeLog] {
        let descriptor = FetchDescriptor<HolidayChangeLog>(
            predicate: #Predicate { $0.region == region },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get entries for a specific rule
    func getEntries(forRuleId ruleId: String, context: ModelContext) -> [HolidayChangeLog] {
        let descriptor = FetchDescriptor<HolidayChangeLog>(
            predicate: #Predicate { $0.ruleId == ruleId },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get recent entries (last N)
    func getRecentEntries(limit: Int, context: ModelContext) -> [HolidayChangeLog] {
        var descriptor = FetchDescriptor<HolidayChangeLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Private Helpers

    private func saveContext(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            Log.w("Failed to save changelog: \(error)")
        }
    }

    private func regionName(_ code: String) -> String {
        switch code {
        case "SE": return "Sweden"
        case "US": return "United States"
        case "VN": return "Vietnam"
        case "CUSTOM": return "Custom"
        case "ALL": return "All Regions"
        default: return code
        }
    }

    private func encodeRule(_ rule: HolidayRule) -> String {
        let snapshot = HolidayRuleSnapshot(from: rule)
        return encodeSnapshot(snapshot)
    }

    private func encodeSnapshot(_ snapshot: HolidayRuleSnapshot) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(snapshot),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    private func describeChanges(before: HolidayRuleSnapshot, after: HolidayRule) -> String {
        var changes: [String] = []

        if before.name != after.name {
            changes.append("name: '\(before.name)' → '\(after.name)'")
        }
        if before.isBankHoliday != after.isBankHoliday {
            changes.append("type: \(before.isBankHoliday ? "Holiday" : "Observance") → \(after.isBankHoliday ? "Holiday" : "Observance")")
        }
        if before.month != after.month || before.day != after.day {
            changes.append("date changed")
        }
        if before.symbolName != after.symbolName {
            changes.append("icon changed")
        }

        return changes.isEmpty ? "minor changes" : changes.joined(separator: ", ")
    }
}

// MARK: - Rule Snapshot (for before/after comparison)

struct HolidayRuleSnapshot: Codable {
    let id: String
    let name: String
    let region: String
    let isBankHoliday: Bool
    let titleOverride: String?
    let symbolName: String?
    let iconColor: String?
    let type: String
    let month: Int?
    let day: Int?
    let daysOffset: Int?
    let weekday: Int?
    let ordinal: Int?
    let dayRangeStart: Int?
    let dayRangeEnd: Int?

    init(from rule: HolidayRule) {
        self.id = rule.id
        self.name = rule.name
        self.region = rule.region
        self.isBankHoliday = rule.isBankHoliday
        self.titleOverride = rule.titleOverride
        self.symbolName = rule.symbolName
        self.iconColor = rule.iconColor
        self.type = rule.type.rawValue
        self.month = rule.month
        self.day = rule.day
        self.daysOffset = rule.daysOffset
        self.weekday = rule.weekday
        self.ordinal = rule.ordinal
        self.dayRangeStart = rule.dayRangeStart
        self.dayRangeEnd = rule.dayRangeEnd
    }
}
