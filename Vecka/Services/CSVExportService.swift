//
//  CSVExportService.swift
//  Vecka
//
//  CSV export for expenses using unified Memo model
//  Spreadsheet-friendly format for accounting/reporting
//

import Foundation
import SwiftData

@MainActor
class CSVExportService {

    // MARK: - Singleton
    static let shared = CSVExportService()
    private init() {}

    // MARK: - Memo Expense Export

    /// Export Memo expenses to CSV
    func exportMemoExpenses(_ expenses: [Memo]) throws -> URL {
        guard !expenses.isEmpty else {
            throw CSVExportError.noData
        }

        var csv = "Date,Amount,Currency,Merchant,Description\n"

        let sortedExpenses = expenses.sorted { $0.date < $1.date }

        for expense in sortedExpenses {
            let row = [
                formatDate(expense.date),
                String(format: "%.2f", expense.amount ?? 0),
                expense.currency ?? "SEK",
                escapeCSV(expense.place ?? ""),
                escapeCSV(expense.text)
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

    /// Export Memo expenses for a specific week
    func exportMemoExpensesForWeek(
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

        return try exportMemoExpenses(from: startOfWeek, to: endOfWeek, context: context)
    }

    /// Export Memo expenses for a specific month
    func exportMemoExpensesForMonth(
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

        return try exportMemoExpenses(from: startOfMonth, to: endOfMonth, context: context)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

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
