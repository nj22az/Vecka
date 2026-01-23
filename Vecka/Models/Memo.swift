//
//  Memo.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) Unified Entry System
//  One model to rule them all: Notes, Trips, Expenses, Mileage, Events, Countdowns
//  Replaces: DailyNote, TravelTrip, ExpenseItem, MileageEntry, CountdownEvent
//

import Foundation
import SwiftData

// MARK: - Memo Type (Legacy - kept for backward compatibility)

/// What kind of memo this is - determines which fields are relevant
/// NOTE: This is the PRIMARY type for display and categorization.
/// Use MemoFeature for combinable capabilities.
enum MemoType: String, Codable, CaseIterable {
    case note       // 📝 Daily note, journal entry
    case trip       // ✈️ Travel trip (parent for expenses/mileage)
    case expense    // 💰 Expense item
    case mileage    // 🚗 Mileage/distance tracking
    case event      // ⭐ Calendar event
    case countdown  // ⏱️ Countdown to future date

    /// SF Symbol for this type
    var icon: String {
        switch self {
        case .note: return "note.text"
        case .trip: return "airplane"
        case .expense: return "yensign.circle"
        case .mileage: return "car"
        case .event: return "star"
        case .countdown: return "timer"
        }
    }

    /// Display name
    var displayName: String {
        switch self {
        case .note: return "Note"
        case .trip: return "Trip"
        case .expense: return "Expense"
        case .mileage: return "Mileage"
        case .event: return "Event"
        case .countdown: return "Countdown"
        }
    }

    /// Joho semantic color hex
    var colorHex: String {
        switch self {
        case .note: return "FFE566"      // Yellow (今) - NOW
        case .trip: return "A5F3FC"      // Cyan (予定) - SCHEDULED
        case .expense: return "BBF7D0"   // Green (金) - MONEY
        case .mileage: return "BBF7D0"   // Green (金) - MONEY
        case .event: return "A5F3FC"     // Cyan (予定) - SCHEDULED
        case .countdown: return "FECDD3" // Pink (祝) - CELEBRATION
        }
    }

    /// Convert MemoType to equivalent MemoFeature
    var toFeature: MemoFeature {
        switch self {
        case .note: return .note
        case .trip: return .trip
        case .expense: return .expense
        case .mileage: return .mileage
        case .event: return .event
        case .countdown: return .countdown
        }
    }
}

// MARK: - Memo Feature (Combinable Flags)

/// 情報デザイン: Combinable feature flags for memos
/// Unlike MemoType (exclusive), features can be combined:
/// e.g., expense + debt + trip link
enum MemoFeature: String, Codable, CaseIterable, Identifiable {
    case note       // Text content, priority
    case expense    // Amount, currency, category
    case trip       // Destination, date range, container
    case mileage    // Distance, from/to locations
    case event      // Calendar event
    case countdown  // Target date countdown
    case debt       // Linked to contact with direction

    var id: String { rawValue }

    /// SF Symbol for this feature
    var icon: String {
        switch self {
        case .note: return "note.text"
        case .expense: return "yensign.circle"
        case .trip: return "airplane"
        case .mileage: return "car"
        case .event: return "star"
        case .countdown: return "timer"
        case .debt: return "person.2.circle"
        }
    }

    /// Display name
    var displayName: String {
        switch self {
        case .note: return "Note"
        case .expense: return "Expense"
        case .trip: return "Trip"
        case .mileage: return "Mileage"
        case .event: return "Event"
        case .countdown: return "Countdown"
        case .debt: return "Debt"
        }
    }

    /// Chip label - full word for clarity (情報デザイン: no abbreviations)
    var chipLabel: String {
        switch self {
        case .note: return "Note"
        case .expense: return "Expense"
        case .trip: return "Trip"
        case .mileage: return "Mileage"
        case .event: return "Event"
        case .countdown: return "Countdown"
        case .debt: return "Debt"
        }
    }

    /// Legacy short label (deprecated - use chipLabel)
    @available(*, deprecated, message: "Use chipLabel for full words")
    var shortLabel: String { chipLabel }

    /// Joho semantic color hex
    var colorHex: String {
        switch self {
        case .note: return "FFE566"      // Yellow (今) - NOW
        case .trip: return "A5F3FC"      // Cyan (予定) - SCHEDULED
        case .expense: return "BBF7D0"   // Green (金) - MONEY
        case .mileage: return "BBF7D0"   // Green (金) - MONEY
        case .event: return "A5F3FC"     // Cyan (予定) - SCHEDULED
        case .countdown: return "FECDD3" // Pink (祝) - CELEBRATION
        case .debt: return "E9D5FF"      // Purple (人) - PEOPLE
        }
    }

    /// Convert MemoFeature to equivalent MemoType (for primary type)
    var toType: MemoType {
        switch self {
        case .note: return .note
        case .expense: return .expense
        case .trip: return .trip
        case .mileage: return .mileage
        case .event: return .event
        case .countdown: return .countdown
        case .debt: return .expense  // Debt is typically associated with expense
        }
    }

    /// Feature priority for determining primary type (lower = higher priority)
    var priority: Int {
        switch self {
        case .trip: return 0       // Trip is container, highest priority
        case .expense: return 1    // Expense is key feature
        case .mileage: return 2    // Mileage is key feature
        case .event: return 3      // Event is time-based
        case .countdown: return 4  // Countdown is time-based
        case .note: return 5       // Note is base feature
        case .debt: return 6       // Debt is modifier, lowest priority
        }
    }
}

// MARK: - Debt Direction

/// Direction of debt: who owes whom
enum DebtDirection: String, Codable, CaseIterable {
    case iOwe      // I owe this person
    case theyOwe   // They owe me

    var displayName: String {
        switch self {
        case .iOwe: return "I Owe"
        case .theyOwe: return "They Owe Me"
        }
    }

    var icon: String {
        switch self {
        case .iOwe: return "arrow.up.right"
        case .theyOwe: return "arrow.down.left"
        }
    }
}

// MARK: - Memo Status
// Note: TripType is defined in ExpenseModels.swift and shared across models

/// Workflow status for memos
enum MemoStatus: String, Codable, CaseIterable {
    case draft      // Not finalized
    case active     // In progress
    case completed  // Done
    case cancelled  // Cancelled

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Memo Priority (マルバツ)

/// Priority levels using マルバツ hierarchy
enum MemoPriority: String, Codable, CaseIterable {
    case high       // ◎ Important
    case normal     // ○ Default
    case low        // △ Low priority

    var symbol: String {
        switch self {
        case .high: return "◎"
        case .normal: return "○"
        case .low: return "△"
        }
    }

    var displayName: String {
        switch self {
        case .high: return "High"
        case .normal: return "Normal"
        case .low: return "Low"
        }
    }
}

// MARK: - Memo Model

@Model
final class Memo {

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Core Fields (all memos have these)
    // ═══════════════════════════════════════════════════════════════════

    var id: UUID

    /// What kind of memo this is
    var typeRaw: String
    var type: MemoType {
        get { MemoType(rawValue: typeRaw) ?? .note }
        set { typeRaw = newValue.rawValue }
    }

    /// Optional short headline
    var title: String?

    /// Main content - notes, descriptions, details
    var body: String

    /// Start date (or only date for single-day memos)
    var startDate: Date

    /// End date for multi-day memos (trips, events)
    var endDate: Date?

    /// User-defined tags for filtering
    var tags: [String]?

    /// Workflow status
    var statusRaw: String
    var status: MemoStatus {
        get { MemoStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    /// When created
    var createdAt: Date

    /// When last modified
    var modifiedAt: Date

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Expense Fields (type == .expense)
    // ═══════════════════════════════════════════════════════════════════

    /// Expense amount
    var amount: Double?

    /// Currency code (SEK, USD, EUR, JPY, etc.)
    var currency: String?

    /// Expense category (food, transport, accommodation, etc.)
    var category: String?

    /// Can this expense be reimbursed?
    var isReimbursable: Bool?

    /// Receipt photo stored as Data
    var receiptImageData: Data?

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Trip Fields (type == .trip)
    // ═══════════════════════════════════════════════════════════════════

    /// Type of trip
    var tripTypeRaw: String?
    var tripType: TripType? {
        get { tripTypeRaw.flatMap { TripType(rawValue: $0) } }
        set { tripTypeRaw = newValue?.rawValue }
    }

    /// Destination city/country
    var destination: String?

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Mileage Fields (type == .mileage)
    // ═══════════════════════════════════════════════════════════════════

    /// Distance traveled (in kilometers) - can be entered directly or calculated from odometer
    var distance: Double?

    /// Starting location/address
    var startLocation: String?

    /// Ending location/address
    var endLocation: String?

    /// Is this a round trip? (doubles the distance)
    var isRoundTrip: Bool?

    /// Odometer reading at start (km) - for accurate mileage tracking
    var odometerStart: Double?

    /// Odometer reading at end (km) - for accurate mileage tracking
    var odometerEnd: Double?

    /// Vehicle identifier (for multi-vehicle tracking)
    var vehicleId: String?

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Note/Event Fields
    // ═══════════════════════════════════════════════════════════════════

    /// Priority level (マルバツ hierarchy)
    var priorityRaw: String?
    var priority: MemoPriority? {
        get { priorityRaw.flatMap { MemoPriority(rawValue: $0) } }
        set { priorityRaw = newValue?.rawValue }
    }

    /// Custom SF Symbol icon
    var icon: String?

    /// Custom color (hex string)
    var colorHex: String?

    /// Pin to dashboard/landing page
    var pinnedToDashboard: Bool?

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Feature Flags (combinable capabilities)
    // ═══════════════════════════════════════════════════════════════════

    /// Raw storage for feature flags (SwiftData stores as JSON array)
    var featuresRaw: [String] = []

    /// Active features as a Set (computed property)
    var features: Set<MemoFeature> {
        get { Set(featuresRaw.compactMap { MemoFeature(rawValue: $0) }) }
        set { featuresRaw = newValue.map(\.rawValue).sorted() }
    }

    /// Primary feature (highest priority among active features)
    var primaryFeature: MemoFeature {
        features.min(by: { $0.priority < $1.priority }) ?? type.toFeature
    }

    /// Check if a specific feature is active
    func hasFeature(_ feature: MemoFeature) -> Bool {
        features.contains(feature)
    }

    /// Add a feature
    func addFeature(_ feature: MemoFeature) {
        var current = features
        current.insert(feature)
        features = current
    }

    /// Remove a feature
    func removeFeature(_ feature: MemoFeature) {
        var current = features
        current.remove(feature)
        features = current
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Debt Tracking Fields
    // ═══════════════════════════════════════════════════════════════════

    /// Contact linked to this memo for debt tracking
    var linkedContact: Contact?

    /// Direction of debt (I owe / They owe)
    var debtDirectionRaw: String?
    var debtDirection: DebtDirection? {
        get { debtDirectionRaw.flatMap { DebtDirection(rawValue: $0) } }
        set { debtDirectionRaw = newValue?.rawValue }
    }

    /// Whether the debt has been settled
    var isDebtSettled: Bool = false

    /// When the debt was settled
    var debtSettledAt: Date?

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Relationships (hierarchy)
    // ═══════════════════════════════════════════════════════════════════

    /// Parent memo (e.g., expense belongs to trip)
    var parent: Memo?

    /// Child memos (e.g., trip has expenses)
    @Relationship(deleteRule: .cascade, inverse: \Memo.parent)
    var children: [Memo]?

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Computed Properties
    // ═══════════════════════════════════════════════════════════════════

    /// True if this memo has an expense amount
    var isExpense: Bool {
        type == .expense && amount != nil && amount! > 0
    }

    /// True if this memo spans multiple days
    var isMultiDay: Bool {
        guard let end = endDate else { return false }
        return !Calendar.current.isDate(startDate, inSameDayAs: end)
    }

    /// Number of days this memo spans
    var daySpan: Int {
        guard let end = endDate else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: startDate, to: end).day ?? 0
        return max(1, days + 1)
    }

    /// Preview text for lists (first line, truncated)
    var preview: String {
        let firstLine = body.components(separatedBy: .newlines).first ?? body
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        if trimmed.count > 50 {
            return String(trimmed.prefix(47)) + "..."
        }
        return trimmed.isEmpty ? title ?? "" : trimmed
    }

    /// Display title: uses title if set, otherwise preview
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        return preview
    }

    /// Total mileage distance (considers round trip)
    var totalDistance: Double {
        guard let dist = distance else { return 0 }
        return isRoundTrip == true ? dist * 2 : dist
    }

    /// Total expenses for a trip (sum of children)
    var totalExpenses: Double {
        guard type == .trip else { return 0 }
        return children?.compactMap { $0.amount }.reduce(0, +) ?? 0
    }

    /// Semantic color for this memo type
    var semanticColorHex: String {
        colorHex ?? type.colorHex
    }

    /// True if this memo tracks a debt
    var isDebt: Bool {
        hasFeature(.debt) && linkedContact != nil
    }

    /// Debt amount (uses expense amount when debt feature is active)
    var debtAmount: Double? {
        guard isDebt else { return nil }
        return amount
    }

    /// Description of the debt for display
    var debtDescription: String? {
        guard isDebt, let contact = linkedContact, let direction = debtDirection else { return nil }
        let name = contact.displayName
        let amountStr = amount.map { String(format: "%.2f", $0) } ?? "?"
        let currencyStr = currency ?? "SEK"

        switch direction {
        case .iOwe:
            return "You owe \(name) \(amountStr) \(currencyStr)"
        case .theyOwe:
            return "\(name) owes you \(amountStr) \(currencyStr)"
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Initializer
    // ═══════════════════════════════════════════════════════════════════

    init(
        id: UUID = UUID(),
        type: MemoType = .note,
        title: String? = nil,
        body: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        tags: [String]? = nil,
        status: MemoStatus = .active,
        features: Set<MemoFeature>? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.title = title
        self.body = body
        self.startDate = startDate
        self.endDate = endDate
        self.tags = tags
        self.statusRaw = status.rawValue
        self.createdAt = Date()
        self.modifiedAt = Date()

        // Set features - use provided features or derive from type
        if let features = features {
            self.featuresRaw = features.map(\.rawValue).sorted()
        } else {
            self.featuresRaw = [type.toFeature.rawValue]
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Migration & Validation
    // ═══════════════════════════════════════════════════════════════════

    /// Migrate from typeRaw to featuresRaw if needed (call on existing memos)
    func migrateToFeatures() {
        if featuresRaw.isEmpty {
            featuresRaw = [type.toFeature.rawValue]
        }
    }

    /// Validate and auto-fix feature dependencies
    /// e.g., debt requires expense
    func validateFeatures() {
        var current = features

        // Debt requires expense (need amount)
        if current.contains(.debt) && !current.contains(.expense) {
            current.insert(.expense)
        }

        // Event and countdown are mutually exclusive
        if current.contains(.event) && current.contains(.countdown) {
            current.remove(.countdown)
        }

        // Update type to match primary feature
        let primary = current.min(by: { $0.priority < $1.priority })
        if let primary = primary {
            typeRaw = primary.toType.rawValue
        }

        features = current
    }

    // ═══════════════════════════════════════════════════════════════════
    // MARK: - Factory Methods
    // ═══════════════════════════════════════════════════════════════════

    /// Create a note memo
    static func note(
        title: String? = nil,
        body: String,
        date: Date = Date(),
        priority: MemoPriority = .normal,
        tags: [String]? = nil
    ) -> Memo {
        let memo = Memo(type: .note, title: title, body: body, startDate: date, tags: tags)
        memo.priority = priority
        return memo
    }

    /// Create a trip memo
    static func trip(
        name: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        tripType: TripType = .personal,
        tags: [String]? = nil
    ) -> Memo {
        let memo = Memo(type: .trip, title: name, body: "", startDate: startDate, endDate: endDate, tags: tags)
        memo.destination = destination
        memo.tripType = tripType
        return memo
    }

    /// Create an expense memo
    static func expense(
        description: String,
        amount: Double,
        currency: String,
        category: String? = nil,
        date: Date = Date(),
        parent: Memo? = nil,
        tags: [String]? = nil
    ) -> Memo {
        let memo = Memo(type: .expense, body: description, startDate: date, tags: tags)
        memo.amount = amount
        memo.currency = currency
        memo.category = category
        memo.parent = parent
        return memo
    }

    /// Create a mileage memo
    static func mileage(
        from startLocation: String,
        to endLocation: String,
        distance: Double? = nil,
        odometerStart: Double? = nil,
        odometerEnd: Double? = nil,
        isRoundTrip: Bool = false,
        vehicleId: String? = nil,
        date: Date = Date(),
        parent: Memo? = nil,
        tags: [String]? = nil
    ) -> Memo {
        let memo = Memo(type: .mileage, body: "\(startLocation) → \(endLocation)", startDate: date, tags: tags)
        memo.startLocation = startLocation
        memo.endLocation = endLocation
        memo.odometerStart = odometerStart
        memo.odometerEnd = odometerEnd
        memo.vehicleId = vehicleId
        memo.isRoundTrip = isRoundTrip
        memo.parent = parent

        // Calculate distance from odometer if not provided directly
        if let distance = distance {
            memo.distance = distance
        } else if let start = odometerStart, let end = odometerEnd, end > start {
            memo.distance = end - start
        }
        return memo
    }

    /// Create an event memo
    static func event(
        title: String,
        date: Date,
        endDate: Date? = nil,
        tags: [String]? = nil
    ) -> Memo {
        let memo = Memo(type: .event, title: title, body: "", startDate: date, endDate: endDate, tags: tags)
        return memo
    }

    /// Create a countdown memo
    static func countdown(
        title: String,
        targetDate: Date,
        icon: String? = nil,
        colorHex: String? = nil
    ) -> Memo {
        let memo = Memo(type: .countdown, title: title, body: "", startDate: targetDate)
        memo.icon = icon
        memo.colorHex = colorHex
        return memo
    }
}

// MARK: - Queries

extension Memo {

    /// Fetch memos for a specific date (includes multi-day memos spanning this date)
    static func forDate(_ date: Date, in context: ModelContext) -> [Memo] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                // Single day memo on this date
                (memo.endDate == nil && memo.startDate >= dayStart && memo.startDate < dayEnd) ||
                // Multi-day memo that includes this date
                (memo.endDate != nil && memo.startDate <= dayEnd && memo.endDate! >= dayStart)
            },
            sortBy: [SortDescriptor(\.startDate)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch all memos of a specific type
    static func ofType(_ type: MemoType, in context: ModelContext) -> [Memo] {
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.typeRaw == typeRaw
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch all expenses in a date range
    static func expenses(from start: Date, to end: Date, in context: ModelContext) -> [Memo] {
        let expenseType = MemoType.expense.rawValue
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.typeRaw == expenseType && memo.startDate >= start && memo.startDate <= end
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch active trips (ongoing or future)
    static func activeTrips(in context: ModelContext) -> [Memo] {
        let tripType = MemoType.trip.rawValue
        let today = Calendar.current.startOfDay(for: Date())

        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.typeRaw == tripType && (memo.endDate == nil || memo.endDate! >= today)
            },
            sortBy: [SortDescriptor(\.startDate)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch memos with specific tag
    static func withTag(_ tag: String, in context: ModelContext) -> [Memo] {
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.tags != nil && memo.tags!.contains(tag)
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch pinned memos for dashboard
    static func pinned(in context: ModelContext) -> [Memo] {
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.pinnedToDashboard == true
            },
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }
}

// MARK: - DTO for JSON/Widget

struct MemoDTO: Codable, Identifiable {
    let id: UUID
    var type: String
    var title: String?
    var body: String
    var startDate: Date
    var endDate: Date?
    var amount: Double?
    var currency: String?
    var category: String?
    var tags: [String]?
    var status: String
    var createdAt: Date
    var modifiedAt: Date

    init(from memo: Memo) {
        self.id = memo.id
        self.type = memo.typeRaw
        self.title = memo.title
        self.body = memo.body
        self.startDate = memo.startDate
        self.endDate = memo.endDate
        self.amount = memo.amount
        self.currency = memo.currency
        self.category = memo.category
        self.tags = memo.tags
        self.status = memo.statusRaw
        self.createdAt = memo.createdAt
        self.modifiedAt = memo.modifiedAt
    }
}
