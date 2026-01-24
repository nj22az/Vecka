//
//  CSVExportService.swift
//  Vecka
//
//  CSV export for expenses and mileage data
//  Spreadsheet-friendly format for accounting/reporting
//  Migrated to support unified Memo model
//

import Foundation
import SwiftData

@MainActor
class CSVExportService {

    // MARK: - Singleton
    static let shared = CSVExportService()
    private init() {}

    // MARK: - Memo Expense Export (New - Unified Model)

    /// Export Memo expenses to CSV
    func exportMemoExpenses(_ expenses: [Memo]) throws -> URL {
        guard !expenses.isEmpty else {
            throw CSVExportError.noData
        }

        var csv = "Date,Amount,Currency,Merchant,Description,Notes\n"

        let sortedExpenses = expenses.sorted { $0.date < $1.date }

        for expense in sortedExpenses {
            let row = [
                formatDate(expense.date),
                String(format: "%.2f", expense.amount ?? 0),
                expense.currency ?? "SEK",
                escapeCSV(expense.place ?? ""),
                escapeCSV(expense.text),
                ""  // Notes field - Memo doesn't have separate notes
            ]
            csv += row.joined(separator: ",") + "\n"
        }

        return try saveCSV(csv, filename: "Expenses")
    }

    /// Export Memo expenses for a date range
    func exportMemoExpenses(
        from startDate: Date,
        to endDate: Date,
        context: ModelContext
    ) throws -> URL {
        let calendar = Calendar.iso8601
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate).addingTimeInterval(86400)

        let expenseType = MemoType.expense.rawValue
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate { memo in
                memo.memoTypeRaw == expenseType && memo.date >= start && memo.date < end
            },
            sortBy: [SortDescriptor(\Memo.date)]
        )

        let expenses = try context.fetch(descriptor)
        return try exportMemoExpenses(expenses)
    }

    // MARK: - Legacy Expense Export (For backward compatibility)

    /// Export expenses to CSV (Legacy - ExpenseItem)
    /// - Parameters:
    ///   - expenses: Array of expenses to export
    ///   - includeReceipts: Whether to include receipt filename column
    /// - Returns: URL to generated CSV file
    func exportExpenses(_ expenses: [ExpenseItem], includeReceipts: Bool = false) throws -> URL {
        guard !expenses.isEmpty else {
            throw CSVExportError.noData
        }

        var csv = buildExpenseHeader(includeReceipts: includeReceipts)

        let sortedExpenses = expenses.sorted { $0.date < $1.date }

        for expense in sortedExpenses {
            csv += buildExpenseRow(expense, includeReceipts: includeReceipts)
        }

        return try saveCSV(csv, filename: "Expenses")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Export expenses for a date range
    func exportExpenses(
        from startDate: Date,
        to endDate: Date,
        context: ModelContext
    ) throws -> URL {
        let calendar = Calendar.iso8601
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate).addingTimeInterval(86400) // Include end day

        let descriptor = FetchDescriptor<ExpenseItem>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\ExpenseItem.date)]
        )

        let expenses = try context.fetch(descriptor)
        return try exportExpenses(expenses)
    }

    /// Export expenses for a specific week
    func exportExpensesForWeek(
        weekNumber: Int,
        year: Int,
        context: ModelContext
    ) throws -> URL {
        let calendar = Calendar.iso8601
        var components = DateComponents()
        components.yearForWeekOfYear = year
        components.weekOfYear = weekNumber
        components.weekday = 2 // Monday

        guard let startOfWeek = calendar.date(from: components),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
            throw CSVExportError.invalidDateRange
        }

        return try exportExpenses(from: startOfWeek, to: endOfWeek, context: context)
    }

    /// Export expenses for a specific month
    func exportExpensesForMonth(
        month: Int,
        year: Int,
        context: ModelContext
    ) throws -> URL {
        let calendar = Calendar.iso8601
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = month
        startComponents.day = 1

        guard let startOfMonth = calendar.date(from: startComponents),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            throw CSVExportError.invalidDateRange
        }

        return try exportExpenses(from: startOfMonth, to: endOfMonth, context: context)
    }

    /// Export expenses for a trip
    func exportExpensesForTrip(_ trip: TravelTrip) throws -> URL {
        guard let expenses = trip.expenses, !expenses.isEmpty else {
            throw CSVExportError.noData
        }
        return try exportExpenses(expenses)
    }

    // MARK: - Mileage Export

    /// Export mileage entries to CSV
    func exportMileage(_ entries: [MileageEntry]) throws -> URL {
        guard !entries.isEmpty else {
            throw CSVExportError.noData
        }

        var csv = buildMileageHeader()

        let sortedEntries = entries.sorted { $0.date < $1.date }

        for entry in sortedEntries {
            csv += buildMileageRow(entry)
        }

        return try saveCSV(csv, filename: "Mileage")
    }

    /// Export mileage for a trip
    func exportMileageForTrip(_ trip: TravelTrip) throws -> URL {
        guard let entries = trip.mileageEntries, !entries.isEmpty else {
            throw CSVExportError.noData
        }
        return try exportMileage(entries)
    }

    // MARK: - CSV Building

    private func buildExpenseHeader(includeReceipts: Bool) -> String {
        var header = "Date,Amount,Currency,Category,Merchant,Description,Notes,Reimbursable,Personal,Status"
        if includeReceipts {
            header += ",Receipt"
        }
        header += "\n"
        return header
    }

    private func buildExpenseRow(_ expense: ExpenseItem, includeReceipts: Bool) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var row = [
            dateFormatter.string(from: expense.date),
            String(format: "%.2f", expense.amount),
            expense.currency,
            escapeCSV(expense.category?.name ?? "Uncategorized"),
            escapeCSV(expense.merchantName ?? ""),
            escapeCSV(expense.itemDescription),
            escapeCSV(expense.notes ?? ""),
            expense.isReimbursable ? "Yes" : "No",
            expense.isPersonal ? "Yes" : "No",
            expense.status.rawValue
        ]

        if includeReceipts {
            row.append(escapeCSV(expense.receiptFileName ?? ""))
        }

        return row.joined(separator: ",") + "\n"
    }

    private func buildMileageHeader() -> String {
        return "Date,Distance (km),Start Location,End Location,Purpose,Round Trip,Tracking Method\n"
    }

    private func buildMileageRow(_ entry: MileageEntry) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let row = [
            dateFormatter.string(from: entry.date),
            String(format: "%.1f", entry.distance),
            escapeCSV(entry.startLocation ?? ""),
            escapeCSV(entry.endLocation ?? ""),
            escapeCSV(entry.purpose ?? ""),
            entry.isRoundTrip ? "Yes" : "No",
            entry.trackingMethod.rawValue
        ]

        return row.joined(separator: ",") + "\n"
    }

    // MARK: - Helpers

    /// Escape CSV special characters
    private func escapeCSV(_ value: String) -> String {
        var escaped = value
        // If contains comma, quote, or newline, wrap in quotes
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            // Escape existing quotes by doubling them
            escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
            escaped = "\"\(escaped)\""
        }
        return escaped
    }

    /// Save CSV string to temporary file
    private func saveCSV(_ content: String, filename: String) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let fullFilename = "Onsen_\(filename)_\(timestamp).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fullFilename)

        try content.write(to: url, atomically: true, encoding: .utf8)

        Log.i("CSV exported: \(fullFilename)")
        return url
    }
}

// MARK: - Errors

enum CSVExportError: LocalizedError {
    case noData
    case invalidDateRange
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .noData:
            return "No data available to export"
        case .invalidDateRange:
            return "Invalid date range specified"
        case .writeFailed:
            return "Failed to write CSV file"
        }
    }
}
