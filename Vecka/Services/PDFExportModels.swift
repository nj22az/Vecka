//
//  PDFExportModels.swift
//  Vecka
//
//  PDF Export data models and supporting types
//

import Foundation
import SwiftUI

// MARK: - Export Scope

/// Defines the scope of data to export
enum PDFExportScope: Equatable, Hashable {
    case day(Date)
    case week(weekNumber: Int, year: Int)
    case month(month: Int, year: Int)
    case range(start: Date, end: Date)
    case year(Int)

    var title: String {
        switch self {
        case .day(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter.string(from: date)
        case .week(let week, let year):
            return "Week \(week), \(year)"
        case .month(let month, let year):
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let components = DateComponents(year: year, month: month, day: 1)
            if let date = Calendar.iso8601.date(from: components) {
                return formatter.string(from: date)
            }
            return "Month \(month), \(year)"
        case .range(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        case .year(let year):
            return "Year \(year)"
        }
    }
}

// MARK: - Day Export Data

/// Complete data for a single day export
struct DayExportData: Identifiable {
    let id = UUID()
    let date: Date
    let weekNumber: Int
    let year: Int
    let holidays: [HolidayExportInfo]
    let observances: [ObservanceExportInfo]
    let notes: [NoteExportInfo]
    let expenses: [ExpenseExportInfo]
    let statistics: DayStatistics
    var weather: WeatherExportInfo?

    init(
        date: Date,
        weekNumber: Int,
        year: Int,
        holidays: [HolidayExportInfo] = [],
        observances: [ObservanceExportInfo] = [],
        notes: [NoteExportInfo] = [],
        expenses: [ExpenseExportInfo] = [],
        statistics: DayStatistics = DayStatistics(),
        weather: WeatherExportInfo? = nil
    ) {
        self.date = date
        self.weekNumber = weekNumber
        self.year = year
        self.holidays = holidays
        self.observances = observances
        self.notes = notes
        self.expenses = expenses
        self.statistics = statistics
        self.weather = weather
    }
}

// MARK: - Holiday Export Info

struct HolidayExportInfo: Identifiable {
    let id = UUID()
    let name: String
    let isBankHoliday: Bool
    let symbol: String?
    let description: String?

    init(name: String, isBankHoliday: Bool, symbol: String? = nil, description: String? = nil) {
        self.name = name
        self.isBankHoliday = isBankHoliday
        self.symbol = symbol
        self.description = description
    }
}

// MARK: - Observance Export Info

struct ObservanceExportInfo: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String?
    let category: String?

    init(name: String, symbol: String? = nil, category: String? = nil) {
        self.name = name
        self.symbol = symbol
        self.category = category
    }
}

// MARK: - Note Export Info

struct NoteExportInfo: Identifiable {
    let id = UUID()
    let content: String
    let date: Date
    let day: Date
    let colorHex: String?
    let tags: [String]
    let isPinned: Bool
    let scheduledAt: Date?

    init(
        content: String,
        date: Date,
        day: Date,
        colorHex: String? = nil,
        tags: [String] = [],
        isPinned: Bool = false,
        scheduledAt: Date? = nil
    ) {
        self.content = content
        self.date = date
        self.day = day
        self.colorHex = colorHex
        self.tags = tags
        self.isPinned = isPinned
        self.scheduledAt = scheduledAt
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledAt ?? date)
    }
}

// MARK: - Expense Export Info

struct ExpenseExportInfo: Identifiable {
    let id = UUID()
    let amount: Decimal
    let currency: String
    let category: String
    let notes: String?
    let date: Date
    let location: String?

    init(
        amount: Decimal,
        currency: String,
        category: String,
        notes: String? = nil,
        date: Date,
        location: String? = nil
    ) {
        self.amount = amount
        self.currency = currency
        self.category = category
        self.notes = notes
        self.date = date
        self.location = location
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount) \(currency)"
    }
}

// MARK: - Weather Export Info

struct WeatherExportInfo {
    let condition: String
    let symbolName: String
    let highTemperature: String
    let lowTemperature: String
    let precipitationChance: String?
    let humidity: String?
    let windSpeed: String?

    init(
        condition: String,
        symbolName: String,
        highTemperature: String,
        lowTemperature: String,
        precipitationChance: String? = nil,
        humidity: String? = nil,
        windSpeed: String? = nil
    ) {
        self.condition = condition
        self.symbolName = symbolName
        self.highTemperature = highTemperature
        self.lowTemperature = lowTemperature
        self.precipitationChance = precipitationChance
        self.humidity = humidity
        self.windSpeed = windSpeed
    }
}

// MARK: - Mileage Export Info

struct MileageExportInfo: Identifiable {
    let id = UUID()
    let date: Date
    let startLocation: String?
    let endLocation: String?
    let distance: Double
    let purpose: String?
    let isRoundTrip: Bool
    let trackingMethod: String

    init(
        date: Date,
        startLocation: String? = nil,
        endLocation: String? = nil,
        distance: Double,
        purpose: String? = nil,
        isRoundTrip: Bool = false,
        trackingMethod: String = "Manual Entry"
    ) {
        self.date = date
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.distance = distance
        self.purpose = purpose
        self.isRoundTrip = isRoundTrip
        self.trackingMethod = trackingMethod
    }

    var totalDistance: Double {
        isRoundTrip ? distance * 2 : distance
    }

    var formattedDistance: String {
        String(format: "%.1f km", totalDistance)
    }

    var routeDescription: String {
        if let start = startLocation, let end = endLocation {
            return "\(start) → \(end)"
        } else if let start = startLocation {
            return "From \(start)"
        } else if let end = endLocation {
            return "To \(end)"
        }
        return "Unknown route"
    }
}

// MARK: - Trip Report Export Info

struct TripReportExportInfo: Identifiable {
    let id = UUID()
    let tripName: String
    let destination: String
    let startDate: Date
    let endDate: Date
    let purpose: String?
    let tripType: String
    let duration: Int
    let expenses: [ExpenseExportInfo]
    let mileageEntries: [MileageExportInfo]
    let totalExpenses: Decimal
    let totalMileage: Double
    let mileageRate: Double
    let currency: String

    init(
        tripName: String,
        destination: String,
        startDate: Date,
        endDate: Date,
        purpose: String? = nil,
        tripType: String,
        duration: Int,
        expenses: [ExpenseExportInfo] = [],
        mileageEntries: [MileageExportInfo] = [],
        totalExpenses: Decimal = 0,
        totalMileage: Double = 0,
        mileageRate: Double = 18.50,
        currency: String = "SEK"
    ) {
        self.tripName = tripName
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.purpose = purpose
        self.tripType = tripType
        self.duration = duration
        self.expenses = expenses
        self.mileageEntries = mileageEntries
        self.totalExpenses = totalExpenses
        self.totalMileage = totalMileage
        self.mileageRate = mileageRate
        self.currency = currency
    }

    var mileageReimbursement: Decimal {
        Decimal(totalMileage * mileageRate)
    }

    var totalReimbursement: Decimal {
        totalExpenses + mileageReimbursement
    }

    var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - Day Statistics

struct DayStatistics {
    let noteCount: Int
    let wordCount: Int
    let characterCount: Int
    let holidayCount: Int
    let observanceCount: Int
    let expenseCount: Int
    let totalExpenseAmount: Decimal

    init(
        noteCount: Int = 0,
        wordCount: Int = 0,
        characterCount: Int = 0,
        holidayCount: Int = 0,
        observanceCount: Int = 0,
        expenseCount: Int = 0,
        totalExpenseAmount: Decimal = 0
    ) {
        self.noteCount = noteCount
        self.wordCount = wordCount
        self.characterCount = characterCount
        self.holidayCount = holidayCount
        self.observanceCount = observanceCount
        self.expenseCount = expenseCount
        self.totalExpenseAmount = totalExpenseAmount
    }
}

// MARK: - PDF Export Options

struct PDFExportOptions {
    // Content Options
    var includeWeather: Bool = false
    var includeStatistics: Bool = true
    var includeNotes: Bool = true
    var includeHolidays: Bool = true
    var includeObservances: Bool = true
    var includeExpenses: Bool = true

    // Layout Options
    var pageSize: PDFPageSize = .a4
    var colorMode: PDFColorMode = .color

    // Header Customization
    var showHeader: Bool = true
    var headerTitle: String = "Vecka"
    var headerSubtitle: String? = nil
    var showHeaderLine: Bool = true

    // Footer Customization
    var showFooter: Bool = true
    var showPageNumbers: Bool = true
    var showTimestamp: Bool = true
    var footerText: String? = nil

    // Style Preset
    var stylePreset: PDFStylePreset = .standard

    enum PDFPageSize {
        case a4
        case letter
        case custom(width: CGFloat, height: CGFloat)

        var size: CGSize {
            switch self {
            case .a4:
                return CGSize(width: 595.2, height: 841.8) // 210mm x 297mm
            case .letter:
                return CGSize(width: 612, height: 792) // 8.5" x 11"
            case .custom(let width, let height):
                return CGSize(width: width, height: height)
            }
        }
    }

    enum PDFColorMode {
        case color
        case grayscale
    }

    enum PDFStylePreset: String, CaseIterable, Identifiable {
        case minimal = "Minimal"
        case standard = "Standard"
        case professional = "Professional"

        var id: String { rawValue }

        var description: String {
            switch self {
            case .minimal:
                return "Clean and simple, essential information only"
            case .standard:
                return "Balanced layout with all key details"
            case .professional:
                return "Comprehensive report with full customization"
            }
        }

        // Apply preset defaults
        mutating func apply(to options: inout PDFExportOptions) {
            switch self {
            case .minimal:
                options.showHeader = true
                options.showHeaderLine = false
                options.showFooter = false
                options.includeStatistics = false
                options.includeObservances = false
                options.headerSubtitle = nil

            case .standard:
                options.showHeader = true
                options.showHeaderLine = true
                options.showFooter = true
                options.showPageNumbers = true
                options.showTimestamp = false
                options.includeStatistics = true
                options.includeObservances = true

            case .professional:
                options.showHeader = true
                options.showHeaderLine = true
                options.showFooter = true
                options.showPageNumbers = true
                options.showTimestamp = true
                options.includeStatistics = true
                options.includeObservances = true
                options.headerSubtitle = "Daily Report"
            }
        }
    }
}
