//
//  ExpenseModels.swift
//  Vecka
//
//  Comprehensive expense tracking models (Concur-style)
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Expense Category

@Model
final class ExpenseCategory {
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var isDefault: Bool
    var sortOrder: Int
    var dateCreated: Date

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \ExpenseItem.category)
    var expenses: [ExpenseItem]?

    @Relationship(deleteRule: .cascade)
    var templates: [ExpenseTemplate]?

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "creditcard.fill",
        colorHex: String = "#007AFF",
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.dateCreated = Date()
    }

    var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Expense Template

@Model
final class ExpenseTemplate {
    var id: UUID
    var name: String
    var defaultAmount: Double?
    var defaultCurrency: String
    var notes: String?
    var isDefault: Bool

    // Relationship - inverse required for SwiftData to properly manage parent-child
    @Relationship(inverse: \ExpenseCategory.templates)
    var category: ExpenseCategory?

    init(
        id: UUID = UUID(),
        name: String,
        defaultAmount: Double? = nil,
        defaultCurrency: String = "SEK",
        notes: String? = nil,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.defaultAmount = defaultAmount
        self.defaultCurrency = defaultCurrency
        self.notes = notes
        self.isDefault = isDefault
    }
}

// MARK: - Expense Item

@Model
final class ExpenseItem {
    var id: UUID
    var date: Date
    var amount: Double
    var currency: String
    var exchangeRate: Double?
    var convertedAmount: Double?
    var merchantName: String?
    var itemDescription: String
    var notes: String?
    var isReimbursable: Bool
    var isPersonal: Bool
    var status: ExpenseStatus
    var dateCreated: Date
    var dateModified: Date

    // Receipt data (stored as Data for photos)
    var receiptImageData: Data?
    var receiptFileName: String?

    // Relationships - @Relationship required for SwiftData to properly manage references
    @Relationship
    var category: ExpenseCategory?

    @Relationship(inverse: \TravelTrip.expenses)
    var trip: TravelTrip?

    // Computed
    var dayDate: Date {
        Calendar.iso8601.startOfDay(for: date)
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Double,
        currency: String = "SEK",
        exchangeRate: Double? = nil,
        merchantName: String? = nil,
        itemDescription: String,
        notes: String? = nil,
        isReimbursable: Bool = true,
        isPersonal: Bool = false,
        status: ExpenseStatus = .draft
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.currency = currency
        self.exchangeRate = exchangeRate
        self.merchantName = merchantName
        self.itemDescription = itemDescription
        self.notes = notes
        self.isReimbursable = isReimbursable
        self.isPersonal = isPersonal
        self.status = status
        self.dateCreated = Date()
        self.dateModified = Date()

        // Auto-calculate converted amount if rate provided
        if let rate = exchangeRate {
            self.convertedAmount = amount * rate
        }
    }

    // Update converted amount when rate changes
    func updateConvertedAmount(baseCurrency: String = "SEK") {
        if let rate = exchangeRate {
            self.convertedAmount = amount * rate
        }
        self.dateModified = Date()
    }
}

// MARK: - Expense Status

enum ExpenseStatus: String, Codable {
    case draft = "Draft"
    case submitted = "Submitted"
    case approved = "Approved"
    case rejected = "Rejected"
    case reimbursed = "Reimbursed"

    var color: Color {
        switch self {
        case .draft: return .gray
        case .submitted: return .blue
        case .approved: return .green
        case .rejected: return .red
        case .reimbursed: return .purple
        }
    }

    var icon: String {
        switch self {
        case .draft: return "doc.text"
        case .submitted: return "arrow.up.circle"
        case .approved: return "checkmark.circle"
        case .rejected: return "xmark.circle"
        case .reimbursed: return "dollarsign.circle"
        }
    }
}

// MARK: - Travel Trip

@Model
final class TravelTrip {
    var id: UUID
    var tripName: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var purpose: String?
    var tripType: TripType
    var status: TripStatus
    var dateCreated: Date

    // Relationships
    @Relationship(deleteRule: .cascade)
    var expenses: [ExpenseItem]?

    @Relationship(deleteRule: .cascade)
    var mileageEntries: [MileageEntry]?

    // Computed
    var duration: Int {
        let calendar = Calendar.iso8601
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1
    }

    var totalExpenses: Double {
        expenses?.reduce(0) { $0 + ($1.convertedAmount ?? $1.amount) } ?? 0
    }

    var totalMileage: Double {
        mileageEntries?.reduce(0) { $0 + $1.distance } ?? 0
    }

    init(
        id: UUID = UUID(),
        tripName: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        purpose: String? = nil,
        tripType: TripType = .business,
        status: TripStatus = .planned
    ) {
        self.id = id
        self.tripName = tripName
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.purpose = purpose
        self.tripType = tripType
        self.status = status
        self.dateCreated = Date()
    }
}

// MARK: - Trip Type

enum TripType: String, Codable, CaseIterable {
    case business = "Business"
    case personal = "Personal"
    case mixed = "Mixed"

    var color: Color {
        switch self {
        case .business: return .blue
        case .personal: return .green
        case .mixed: return .orange
        }
    }
}

// MARK: - Trip Status

enum TripStatus: String, Codable {
    case planned = "Planned"
    case active = "Active"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .planned: return .blue
        case .active: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

// MARK: - Mileage Entry

@Model
final class MileageEntry {
    var id: UUID
    var date: Date
    var startLocation: String?
    var endLocation: String?
    var distance: Double // in kilometers
    var purpose: String?
    var isRoundTrip: Bool
    var trackingMethod: MileageTrackingMethod
    var dateCreated: Date

    // GPS tracking data (optional)
    var startLatitude: Double?
    var startLongitude: Double?
    var endLatitude: Double?
    var endLongitude: Double?

    // Relationship - @Relationship required for SwiftData to properly manage references
    @Relationship(inverse: \TravelTrip.mileageEntries)
    var trip: TravelTrip?

    // Computed
    var totalDistance: Double {
        isRoundTrip ? distance * 2 : distance
    }

    var dayDate: Date {
        Calendar.iso8601.startOfDay(for: date)
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        startLocation: String? = nil,
        endLocation: String? = nil,
        distance: Double,
        purpose: String? = nil,
        isRoundTrip: Bool = false,
        trackingMethod: MileageTrackingMethod = .manual
    ) {
        self.id = id
        self.date = date
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.distance = distance
        self.purpose = purpose
        self.isRoundTrip = isRoundTrip
        self.trackingMethod = trackingMethod
        self.dateCreated = Date()
    }
}

// MARK: - Mileage Tracking Method

enum MileageTrackingMethod: String, Codable {
    case manual = "Manual Entry"
    case gps = "GPS Tracked"

    var icon: String {
        switch self {
        case .manual: return "hand.tap"
        case .gps: return "location.fill"
        }
    }
}

// MARK: - Exchange Rate

@Model
final class ExchangeRate {
    var id: UUID
    var fromCurrency: String
    var toCurrency: String
    var date: Date
    var rate: Double
    var isManualOverride: Bool
    var source: String?
    var dateCreated: Date
    var dateModified: Date

    // Computed
    var dayDate: Date {
        Calendar.iso8601.startOfDay(for: date)
    }

    init(
        id: UUID = UUID(),
        fromCurrency: String,
        toCurrency: String,
        date: Date,
        rate: Double,
        isManualOverride: Bool = false,
        source: String? = nil
    ) {
        self.id = id
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.date = Calendar.iso8601.startOfDay(for: date)
        self.rate = rate
        self.isManualOverride = isManualOverride
        self.source = source
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}

// MARK: - Currency Helpers
// Note: CurrencyDefinition is defined in Localization.swift

extension CurrencyDefinition {
    static func symbol(for code: String) -> String {
        defaultCurrencies.first { $0.code == code }?.symbol ?? code
    }

    static func name(for code: String) -> String {
        defaultCurrencies.first { $0.code == code }?.name ?? code
    }
}

// MARK: - Expense Report Summary

struct ExpenseReportSummary {
    let totalExpenses: Double
    let expenseCount: Int
    let totalMileage: Double
    let currencyBreakdown: [String: Double]
    let categoryBreakdown: [String: Double]
    let tripBreakdown: [String: Double]
}
