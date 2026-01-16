//
//  PDFExportService.swift
//  Vecka
//
//  Core PDF export service for generating beautifully formatted reports
//

import Foundation
import SwiftData
import SwiftUI

/// PDF Export Service - Main coordinator for PDF generation
@MainActor
class PDFExportService {

    // MARK: - Singleton
    static let shared = PDFExportService()

    private init() {}

    // MARK: - Public API

    /// Generate PDF for specified scope
    /// - Parameters:
    ///   - scope: Export scope (day, week, month, year, custom range)
    ///   - context: SwiftData model context for data queries
    ///   - options: Export options (weather, statistics, etc.)
    /// - Returns: URL to generated PDF file
    func generatePDF(
        scope: PDFExportScope,
        context: ModelContext,
        options: PDFExportOptions = PDFExportOptions()
    ) async throws -> URL {

        Log.i("Starting PDF generation for scope: \(scope.title)")

        // Fetch data for the specified scope
        let days = try await fetchDays(for: scope, context: context, options: options)

        guard !days.isEmpty else {
            throw PDFExportError.noData
        }

        // Generate PDF using renderer
        let renderer = PDFRenderer(options: options, modelContext: context)
        let pdfData = try await renderer.render(days: days, scope: scope)

        // Save to temporary file
        let filename = generateFilename(for: scope)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        try pdfData.write(to: tempURL)

        Log.i("PDF generated successfully: \(tempURL.lastPathComponent)")

        return tempURL
    }

    /// Generate PDF for travel trip report
    /// - Parameters:
    ///   - trip: The travel trip to generate report for
    ///   - context: SwiftData model context
    ///   - mileageRate: Rate per kilometer for reimbursement calculation
    /// - Returns: URL to generated PDF file
    func generateTripReport(
        trip: TravelTrip,
        context: ModelContext,
        mileageRate: Double = 18.50
    ) async throws -> URL {

        Log.i("Starting trip report generation for: \(trip.tripName)")

        // Fetch trip data
        let reportData = try await fetchTripReportData(
            trip: trip,
            context: context,
            mileageRate: mileageRate
        )

        // Generate PDF using renderer
        let renderer = PDFRenderer(options: PDFExportOptions(), modelContext: context)
        let pdfData = try await renderer.renderTripReport(reportData: reportData)

        // Save to temporary file
        let filename = generateTripFilename(for: trip)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        try pdfData.write(to: tempURL)

        Log.i("Trip report generated successfully: \(tempURL.lastPathComponent)")

        return tempURL
    }

    // MARK: - Data Fetching

    private func fetchDays(
        for scope: PDFExportScope,
        context: ModelContext,
        options: PDFExportOptions
    ) async throws -> [DayExportData] {

        let dateRange = getDateRange(for: scope)
        var days: [DayExportData] = []

        // Iterate through each day in range
        var currentDate = dateRange.start
        while currentDate <= dateRange.end {
            let dayData = try await fetchDayData(
                for: currentDate,
                context: context,
                options: options
            )
            days.append(dayData)

            // Move to next day
            currentDate = Calendar.iso8601.date(byAdding: .day, value: 1, to: currentDate) ?? dateRange.end
        }

        return days
    }

    private func fetchDayData(
        for date: Date,
        context: ModelContext,
        options: PDFExportOptions
    ) async throws -> DayExportData {

        let calendar = Calendar.iso8601
        let weekNumber = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)

        // Fetch holidays
        var holidays: [HolidayExportInfo] = []
        if options.includeHolidays {
            // Use Calendar.current to match HolidayManager cache keying
            let startOfDay = Calendar.current.startOfDay(for: date)
            if let dayHolidays = HolidayManager.cache[startOfDay] {
                holidays = dayHolidays.map { holiday in
                    HolidayExportInfo(
                        name: holiday.displayTitle,
                        isBankHoliday: holiday.isBankHoliday,
                        symbol: holiday.symbolName,
                        description: nil
                    )
                }
            }
        }

        // Fetch notes
        var notes: [NoteExportInfo] = []
        var wordCount = 0
        var charCount = 0

        if options.includeNotes {
            let startOfDay = calendar.startOfDay(for: date)
            let dayNotes = try context.fetch(
                FetchDescriptor<DailyNote>(
                    predicate: #Predicate { $0.day == startOfDay },
                    sortBy: [SortDescriptor(\DailyNote.date)]
                )
            )

            notes = dayNotes.map { note in
                let words = note.content.split(separator: " ").count
                wordCount += words
                charCount += note.content.count

                return NoteExportInfo(
                    content: note.content,
                    date: note.date,
                    day: note.day,
                    colorHex: note.color,
                    tags: [], // Tags not implemented in current model
                    isPinned: note.pinnedToDashboard ?? false,
                    scheduledAt: note.scheduledAt
                )
            }
        }

        // Fetch expenses
        var expenses: [ExpenseExportInfo] = []
        var totalExpenseAmount: Decimal = 0

        if options.includeExpenses {
            let startOfDay = calendar.startOfDay(for: date)

            let allExpenses = try context.fetch(
                FetchDescriptor<ExpenseItem>(
                    sortBy: [SortDescriptor(\ExpenseItem.date)]
                )
            )

            // Filter expenses manually
            let dayExpenses = allExpenses.filter { expense in
                let expenseDay = calendar.startOfDay(for: expense.date)
                return expenseDay == startOfDay
            }

            expenses = dayExpenses.map { expense in
                totalExpenseAmount += Decimal(expense.amount)
                return ExpenseExportInfo(
                    amount: Decimal(expense.amount),
                    currency: expense.currency,
                    category: expense.category?.name ?? "Uncategorized",
                    notes: expense.notes,
                    date: expense.date,
                    location: expense.merchantName
                )
            }
        }

        // Create statistics
        let statistics = DayStatistics(
            noteCount: notes.count,
            wordCount: wordCount,
            characterCount: charCount,
            holidayCount: holidays.count,
            observanceCount: 0, // TODO: Add observances when available
            expenseCount: expenses.count,
            totalExpenseAmount: totalExpenseAmount
        )

        return DayExportData(
            date: date,
            weekNumber: weekNumber,
            year: year,
            holidays: holidays,
            observances: [], // TODO: Add observances
            notes: notes,
            expenses: expenses,
            statistics: statistics
        )
    }

    private func fetchTripReportData(
        trip: TravelTrip,
        context: ModelContext,
        mileageRate: Double
    ) async throws -> TripReportExportInfo {

        // Fetch expenses for this trip
        var expenseInfos: [ExpenseExportInfo] = []
        var totalExpenses: Decimal = 0

        if let expenses = trip.expenses {
            expenseInfos = expenses.map { expense in
                let amount = Decimal(expense.amount)
                totalExpenses += amount
                return ExpenseExportInfo(
                    amount: amount,
                    currency: expense.currency,
                    category: expense.category?.name ?? "Uncategorized",
                    notes: expense.notes,
                    date: expense.date,
                    location: expense.merchantName
                )
            }
        }

        // Fetch mileage entries for this trip
        var mileageInfos: [MileageExportInfo] = []
        var totalMileage: Double = 0

        if let mileageEntries = trip.mileageEntries {
            mileageInfos = mileageEntries.map { entry in
                totalMileage += entry.totalDistance
                return MileageExportInfo(
                    date: entry.date,
                    startLocation: entry.startLocation,
                    endLocation: entry.endLocation,
                    distance: entry.distance,
                    purpose: entry.purpose,
                    isRoundTrip: entry.isRoundTrip,
                    trackingMethod: entry.trackingMethod.rawValue
                )
            }
        }

        // Determine currency from expenses or use SEK as default
        let currency = expenseInfos.first?.currency ?? "SEK"

        return TripReportExportInfo(
            tripName: trip.tripName,
            destination: trip.destination,
            startDate: trip.startDate,
            endDate: trip.endDate,
            purpose: trip.purpose,
            tripType: trip.tripType.rawValue,
            duration: trip.duration,
            expenses: expenseInfos,
            mileageEntries: mileageInfos,
            totalExpenses: totalExpenses,
            totalMileage: totalMileage,
            mileageRate: mileageRate,
            currency: currency
        )
    }

    // MARK: - Helper Methods

    private func getDateRange(for scope: PDFExportScope) -> (start: Date, end: Date) {
        let calendar = Calendar.iso8601

        switch scope {
        case .day(let date):
            let start = calendar.startOfDay(for: date)
            let end = start
            return (start, end)

        case .week(let weekNumber, let year):
            var components = DateComponents()
            components.yearForWeekOfYear = year
            components.weekOfYear = weekNumber
            components.weekday = 2 // Monday

            guard let start = calendar.date(from: components),
                  let end = calendar.date(byAdding: .day, value: 6, to: start) else {
                return (Date(), Date())
            }
            return (start, end)

        case .month(let month, let year):
            let components = DateComponents(year: year, month: month, day: 1)
            guard let start = calendar.date(from: components) else {
                return (Date(), Date())
            }

            let endComponents = DateComponents(year: year, month: month + 1, day: 0)
            let end = calendar.date(from: endComponents) ?? start
            return (start, end)

        case .range(let start, let end):
            return (calendar.startOfDay(for: start), calendar.startOfDay(for: end))

        case .year(let year):
            let startComponents = DateComponents(year: year, month: 1, day: 1)
            let endComponents = DateComponents(year: year, month: 12, day: 31)

            let start = calendar.date(from: startComponents) ?? Date()
            let end = calendar.date(from: endComponents) ?? Date()
            return (start, end)
        }
    }

    private func generateFilename(for scope: PDFExportScope) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        let prefix = "Vecka_Export"
        let timestamp = dateFormatter.string(from: Date())

        let scopeName: String
        switch scope {
        case .day(let date):
            scopeName = "Day_\(dateFormatter.string(from: date))"
        case .week(let week, let year):
            scopeName = "Week\(week)_\(year)"
        case .month(let month, let year):
            scopeName = "Month\(month)_\(year)"
        case .range:
            scopeName = "Range_\(timestamp)"
        case .year(let year):
            scopeName = "Year_\(year)"
        }

        return "\(prefix)_\(scopeName).pdf"
    }

    private func generateTripFilename(for trip: TravelTrip) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        // Sanitize trip name for filename
        let sanitizedName = trip.tripName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .prefix(30)

        let startDateStr = dateFormatter.string(from: trip.startDate)

        return "Vecka_TripReport_\(sanitizedName)_\(startDateStr).pdf"
    }
}

// MARK: - Errors

enum PDFExportError: LocalizedError {
    case noData
    case renderingFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .noData:
            return "No data available for the selected date range"
        case .renderingFailed:
            return "Failed to render PDF document"
        case .saveFailed:
            return "Failed to save PDF file"
        }
    }
}
