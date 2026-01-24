//
//  SimplePDFRenderer.swift
//  Onsen Planner
//
//  Simplified PDF rendering - renders views directly to PDF
//

import SwiftUI
import UIKit
import PDFKit
import SwiftData

// MARK: - PDF Export Error

enum PDFExportError: LocalizedError {
    case renderingFailed
    case saveFailed
    case invalidData
    case noData

    var errorDescription: String? {
        switch self {
        case .renderingFailed:
            return "Failed to render PDF"
        case .saveFailed:
            return "Failed to save PDF"
        case .invalidData:
            return "Invalid data for PDF export"
        case .noData:
            return "No data available to export"
        }
    }
}

@MainActor
class SimplePDFRenderer {

    /// Renders a SwiftUI view to PDF
    static func render<Content: View>(
        _ content: Content,
        pageSize: CGSize = CGSize(width: 595, height: 842) // A4
    ) -> URL? {
        let renderer = ImageRenderer(content: content.frame(width: pageSize.width, height: pageSize.height))
        renderer.scale = 2.0

        let tempDir = FileManager.default.temporaryDirectory
        let filename = "Onsen-\(UUID().uuidString).pdf"
        let url = tempDir.appendingPathComponent(filename)

        renderer.render { size, context in
            var mediaBox = CGRect(origin: .zero, size: pageSize)

            guard let pdf = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
                return
            }

            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }

        return url
    }

    /// Renders multiple pages to a single PDF
    static func renderPages<Content: View>(
        _ pages: [Content],
        pageSize: CGSize = CGSize(width: 595, height: 842)
    ) -> URL? {
        guard !pages.isEmpty else { return nil }

        let tempDir = FileManager.default.temporaryDirectory
        let filename = "Onsen-\(UUID().uuidString).pdf"
        let url = tempDir.appendingPathComponent(filename)

        var mediaBox = CGRect(origin: .zero, size: pageSize)

        guard let pdf = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            return nil
        }

        for page in pages {
            let renderer = ImageRenderer(content: page.frame(width: pageSize.width, height: pageSize.height))
            renderer.scale = 2.0

            pdf.beginPDFPage(nil)
            renderer.render { size, context in
                context(pdf)
            }
            pdf.endPDFPage()
        }

        pdf.closePDF()
        return url
    }
}

// MARK: - PDF Export Service

actor SimplePDFExportService {

    @MainActor
    static func exportSummary(modelContext: ModelContext) async throws -> URL {
        let view = PDFSummaryPage()
            .environment(\.modelContext, modelContext)

        guard let url = SimplePDFRenderer.render(view) else {
            throw PDFExportError.renderingFailed
        }
        return url
    }

    @MainActor
    static func exportDay(_ date: Date, modelContext: ModelContext) async throws -> URL {
        let view = PDFDayPage(date: date)
            .environment(\.modelContext, modelContext)

        guard let url = SimplePDFRenderer.render(view) else {
            throw PDFExportError.renderingFailed
        }
        return url
    }

    /// Professional week audit report - ALL 7 days with full details
    @MainActor
    static func exportWeek(weekNumber: Int, year: Int, modelContext: ModelContext) async throws -> URL {
        // Use professional audit report showing all 7 days
        let view = PDFWeekAuditReport(weekNumber: weekNumber, year: year)
            .environment(\.modelContext, modelContext)

        guard let url = SimplePDFRenderer.render(view) else {
            throw PDFExportError.renderingFailed
        }
        return url
    }

    /// Professional month audit report - ALL days with full details (multi-page)
    @MainActor
    static func exportMonth(month: Int, year: Int, modelContext: ModelContext) async throws -> URL {
        // Get all days in the month
        let allDays = PDFMonthAuditReport.getAllMonthDates(month: month, year: year)

        // Paginate: ~15 days per page for readability
        let daysPerPage = 15
        let totalPages = max(1, Int(ceil(Double(allDays.count) / Double(daysPerPage))))

        var pages: [AnyView] = []
        for pageNum in 1...totalPages {
            let startIndex = (pageNum - 1) * daysPerPage
            let endIndex = min(startIndex + daysPerPage, allDays.count)
            let pageDays = Array(allDays[startIndex..<endIndex])

            let page = PDFMonthAuditReport(
                month: month,
                year: year,
                pageNumber: pageNum,
                totalPages: totalPages,
                daysOnThisPage: pageDays
            )
            .environment(\.modelContext, modelContext)

            pages.append(AnyView(page))
        }

        guard let url = SimplePDFRenderer.renderPages(pages) else {
            throw PDFExportError.renderingFailed
        }
        return url
    }

    // MARK: - Week Summary Export (情報デザイン: Single-page week overview)

    @MainActor
    static func exportWeekSummary(weekNumber: Int, year: Int, baseCurrency: String, modelContext: ModelContext) async throws -> URL {
        let view = PDFWeekSummaryPage(weekNumber: weekNumber, year: year, baseCurrency: baseCurrency)
            .environment(\.modelContext, modelContext)

        guard let url = SimplePDFRenderer.render(view) else {
            throw PDFExportError.renderingFailed
        }
        return url
    }

    // MARK: - Expense Report Export (情報デザイン: Detailed expense breakdown)

    @MainActor
    static func exportExpenseReport(
        expenses: [Memo],
        baseCurrency: String,
        title: String,
        dateRange: String
    ) async throws -> URL {
        let view = PDFExpenseReportPage(
            expenses: expenses,
            baseCurrency: baseCurrency,
            dateRange: dateRange,
            title: title
        )

        guard let url = SimplePDFRenderer.render(view) else {
            throw PDFExportError.renderingFailed
        }
        return url
    }

    // MARK: - Filtered Expense Report Export

    @MainActor
    static func exportExpenseReportForWeek(
        weekNumber: Int,
        year: Int,
        baseCurrency: String,
        modelContext: ModelContext
    ) async throws -> URL {
        let weekDates = WeekCalculator.shared.dates(in: weekNumber, year: year)
        guard let start = weekDates.first, let end = weekDates.last else {
            throw PDFExportError.noData
        }

        let calendar = Calendar.iso8601
        let weekEnd = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        let expenseType = MemoType.expense.rawValue

        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate { memo in
                memo.memoTypeRaw == expenseType && memo.date >= start && memo.date < weekEnd
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let expenses = try modelContext.fetch(descriptor)

        guard !expenses.isEmpty else {
            throw PDFExportError.noData
        }

        let dateRange = "\(start.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))"

        return try await exportExpenseReport(
            expenses: expenses,
            baseCurrency: baseCurrency,
            title: "Expense Report – Week \(weekNumber)",
            dateRange: dateRange
        )
    }

    @MainActor
    static func exportExpenseReportForMonth(
        month: Int,
        year: Int,
        baseCurrency: String,
        modelContext: ModelContext
    ) async throws -> URL {
        let calendar = Calendar.iso8601

        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: monthStart),
              let monthEnd = calendar.date(byAdding: .day, value: range.count, to: monthStart) else {
            throw PDFExportError.noData
        }

        let expenseType = MemoType.expense.rawValue
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate { memo in
                memo.memoTypeRaw == expenseType && memo.date >= monthStart && memo.date < monthEnd
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let expenses = try modelContext.fetch(descriptor)

        guard !expenses.isEmpty else {
            throw PDFExportError.noData
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let dateRange = formatter.string(from: monthStart)

        return try await exportExpenseReport(
            expenses: expenses,
            baseCurrency: baseCurrency,
            title: "Expense Report",
            dateRange: dateRange
        )
    }

    @MainActor
    static func exportExpenseReportForTrip(
        trip: Memo,
        baseCurrency: String,
        modelContext: ModelContext
    ) async throws -> URL {
        // For Memo trips, we need to find expenses within the trip date range
        guard let endDate = trip.tripEndDate else {
            throw PDFExportError.noData
        }

        let expenseType = MemoType.expense.rawValue
        let startDate = trip.date
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate { memo in
                memo.memoTypeRaw == expenseType && memo.date >= startDate && memo.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let expenses = try modelContext.fetch(descriptor)

        guard !expenses.isEmpty else {
            throw PDFExportError.noData
        }

        let dateRange = "\(trip.date.formatted(date: .abbreviated, time: .omitted)) – \(endDate.formatted(date: .abbreviated, time: .omitted))"

        return try await exportExpenseReport(
            expenses: expenses,
            baseCurrency: baseCurrency,
            title: "Trip Expenses – \(trip.text)",
            dateRange: dateRange
        )
    }
}

// MARK: - PDF Page Templates

struct PDFSummaryPage: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memo.date, order: .reverse) private var allMemos: [Memo]

    // Filter by type
    private var trips: [Memo] { allMemos.filter { $0.type == .trip } }
    private var expenses: [Memo] { allMemos.filter { $0.type == .expense } }
    private var notes: [Memo] { allMemos.filter { $0.type == .note } }
    private var countdowns: [Memo] { allMemos.filter { $0.type == .countdown } }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("pdf.summary_title", value: "Summary", comment: "PDF summary title"))
                    .font(.system(size: 28, weight: .bold))
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 10)

            Divider()

            // Active Trips
            let activeTrips = trips.filter { trip in
                guard let endDate = trip.tripEndDate else { return false }
                return trip.date <= Date() && endDate >= Date()
            }
            if !activeTrips.isEmpty {
                PDFSection(title: NSLocalizedString("pdf.active_trips", value: "Active Trips", comment: ""), icon: "suitcase.fill") {
                    ForEach(activeTrips) { trip in
                        Text("📍 \(trip.place ?? trip.text)")
                            .font(.system(size: 12))
                    }
                }
            }

            // Recent Expenses
            if !expenses.prefix(5).isEmpty {
                PDFSection(title: NSLocalizedString("pdf.recent_expenses", value: "Recent Expenses", comment: ""), icon: "dollarsign.circle.fill") {
                    ForEach(Array(expenses.prefix(5)), id: \.id) { expense in
                        HStack {
                            Text(expense.text)
                                .font(.system(size: 12))
                            Spacer()
                            Text(expense.amount ?? 0, format: .currency(code: expense.currency ?? "SEK"))
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                }
            }

            // Recent Notes
            if !notes.prefix(5).isEmpty {
                PDFSection(title: NSLocalizedString("pdf.recent_notes", value: "Recent Notes", comment: ""), icon: "note.text") {
                    ForEach(Array(notes.prefix(5)), id: \.id) { note in
                        if let birthdayInfo = PersonnummerParser.extractBirthdayInfo(from: note.text) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🎂 \(birthdayInfo.localizedDescription)")
                                    .font(.system(size: 12, weight: .medium))
                            }
                        } else {
                            Text("• \(note.text)")
                                .font(.system(size: 12))
                                .lineLimit(2)
                        }
                    }
                }
            }

            Spacer()

            // Footer
            Text(NSLocalizedString("pdf.generated_by", value: "Generated by Onsen Planner", comment: ""))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(40)
        .background(Color(.systemBackground))
    }
}

struct PDFDayPage: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext

    private var dayNotes: [Memo] {
        let calendar = Calendar.iso8601
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let noteType = MemoType.note.rawValue

        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.memoTypeRaw == noteType && memo.date >= startOfDay && memo.date < endOfDay
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var dayHolidays: [HolidayCacheItem] {
        // Use Calendar.current to match HolidayManager cache keying
        HolidayManager.cache[Calendar.current.startOfDay(for: date)] ?? []
    }

    private var dayExpenses: [Memo] {
        let calendar = Calendar.iso8601
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let expenseType = MemoType.expense.rawValue

        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.memoTypeRaw == expenseType && memo.date >= startOfDay && memo.date < endOfDay
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var activeTrips: [Memo] {
        let tripType = MemoType.trip.rawValue
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate<Memo> { memo in
                memo.memoTypeRaw == tripType && memo.date <= date && memo.tripEndDate != nil
            }
        )
        let allTrips = (try? modelContext.fetch(descriptor)) ?? []
        return allTrips.filter { trip in
            guard let endDate = trip.tripEndDate else { return false }
            return trip.date <= date && endDate >= date
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(date.formatted(date: .complete, time: .omitted))
                    .font(.system(size: 24, weight: .bold))

                let weekInfo = WeekCalculator.shared.weekInfo(for: date)
                Text(verbatim: "\(NSLocalizedString("pdf.week", value: "Week", comment: "")) \(weekInfo.weekNumber), \(weekInfo.year)")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 10)

            Divider()

            let hasContent = !dayHolidays.isEmpty || !dayNotes.isEmpty || !dayExpenses.isEmpty || !activeTrips.isEmpty

            if hasContent {
                // Active Trips
                if !activeTrips.isEmpty {
                    PDFSection(title: NSLocalizedString("pdf.active_trips", value: "Active Trips", comment: ""), icon: "suitcase.fill") {
                        ForEach(activeTrips, id: \.id) { trip in
                            HStack {
                                Text(trip.text)
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text(trip.place ?? "")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Holidays
                if !dayHolidays.isEmpty {
                    PDFSection(title: NSLocalizedString("pdf.holidays", value: "Holidays", comment: ""), icon: "star.fill") {
                        ForEach(dayHolidays, id: \.id) { holiday in
                            HStack {
                                Image(systemName: holiday.isBankHoliday ? "flag.fill" : "flag")
                                    .foregroundStyle(holiday.isBankHoliday ? .red : .blue)
                                Text(holiday.displayTitle)
                                    .font(.system(size: 12))
                            }
                        }
                    }
                }

                // Notes
                if !dayNotes.isEmpty {
                    PDFSection(title: NSLocalizedString("pdf.notes", value: "Notes", comment: ""), icon: "note.text") {
                        ForEach(dayNotes, id: \.id) { note in
                            if !note.text.isEmpty {
                                if let birthdayInfo = PersonnummerParser.extractBirthdayInfo(from: note.text) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("🎂 \(birthdayInfo.localizedDescription)")
                                            .font(.system(size: 12, weight: .medium))
                                            .padding(.vertical, 4)
                                    }
                                } else {
                                    Text(note.text)
                                        .font(.system(size: 12))
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }

                // Expenses
                if !dayExpenses.isEmpty {
                    PDFSection(title: NSLocalizedString("pdf.expenses", value: "Expenses", comment: ""), icon: "dollarsign.circle.fill") {
                        ForEach(dayExpenses, id: \.id) { expense in
                            HStack {
                                Text(expense.text)
                                    .font(.system(size: 12))
                                Spacer()
                                Text(expense.amount ?? 0, format: .currency(code: expense.currency ?? "SEK"))
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }
                    }
                }
            }

            Spacer()

            // Footer
            Text(NSLocalizedString("pdf.generated_by", value: "Generated by Onsen Planner", comment: ""))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(40)
        .background(Color(.systemBackground))
    }
}

struct PDFSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            } icon: {
                Image(systemName: icon)
            }
            .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 6) {
                content
            }
            .padding(.leading, 8)
        }
    }
}

// MARK: - Week Summary PDF (情報デザイン: Compact week overview)

struct PDFWeekSummaryPage: View {
    let weekNumber: Int
    let year: Int
    let baseCurrency: String

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memo.date, order: .reverse) private var allMemos: [Memo]

    // Filter by type
    private var allExpenses: [Memo] { allMemos.filter { $0.type == .expense } }
    private var allNotes: [Memo] { allMemos.filter { $0.type == .note } }
    private var allTrips: [Memo] { allMemos.filter { $0.type == .trip } }
    private var allCountdowns: [Memo] { allMemos.filter { $0.type == .countdown } }

    private var weekDates: [Date] {
        WeekCalculator.shared.dates(in: weekNumber, year: year)
    }

    private var weekExpenses: [Memo] {
        guard let start = weekDates.first, let end = weekDates.last else { return [] }
        let calendar = Calendar.iso8601
        let weekEnd = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        return allExpenses.filter { $0.date >= start && $0.date < weekEnd }
    }

    private var weekNotes: [Memo] {
        guard let start = weekDates.first, let end = weekDates.last else { return [] }
        let calendar = Calendar.iso8601
        let weekEnd = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        return allNotes.filter { $0.date >= start && $0.date < weekEnd }
    }

    private var activeTrips: [Memo] {
        guard let start = weekDates.first, let end = weekDates.last else { return [] }
        return allTrips.filter { trip in
            guard let endDate = trip.tripEndDate else { return false }
            return trip.date <= end && endDate >= start
        }
    }

    private var weekHolidays: [(date: Date, holidays: [HolidayCacheItem])] {
        weekDates.compactMap { date in
            // Use Calendar.current to match HolidayManager cache keying
            let holidays = HolidayManager.cache[Calendar.current.startOfDay(for: date)] ?? []
            return holidays.isEmpty ? nil : (date, holidays)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header (情報デザイン: Clear week identification)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEEK \(weekNumber)")
                        .font(.system(size: 32, weight: .black, design: .rounded))

                    if let first = weekDates.first, let last = weekDates.last {
                        Text("\(first.formatted(date: .abbreviated, time: .omitted)) – \(last.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Stats summary
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(weekExpenses.count) expenses")
                        .font(.system(size: 12, weight: .medium))
                    Text("\(weekNotes.count) notes")
                        .font(.system(size: 12, weight: .medium))
                    Text("\(weekHolidays.flatMap { $0.holidays }.count) holidays")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            Rectangle()
                .fill(Color.black)
                .frame(height: 2)

            // Expense Summary (情報デザイン: Key financial data)
            if !weekExpenses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(Color(hex: "38A169"))
                        Text("EXPENSES")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Spacer()
                        Text(totalExpenseFormatted)
                            .font(.system(size: 18, weight: .bold))
                    }

                    // Currency breakdown
                    let breakdown = expensesByCurrency
                    if breakdown.count > 1 {
                        HStack(spacing: 16) {
                            ForEach(breakdown, id: \.currency) { item in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.currency)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.secondary)
                                    Text(formatAmount(item.total, currency: item.currency))
                                        .font(.system(size: 12, weight: .medium))
                                }
                            }
                        }
                    }

                    // Top categories
                    let topCategories = expensesByCategory.prefix(3)
                    if !topCategories.isEmpty {
                        HStack(spacing: 12) {
                            ForEach(Array(topCategories), id: \.category) { item in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(JohoColors.green.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                    Text("\(item.category): \(formatAmount(item.total, currency: baseCurrency))")
                                        .font(.system(size: 10))
                                }
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(hex: "BBF7D0").opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            // Active Trips
            if !activeTrips.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundStyle(Color(hex: "F97316"))
                        Text("ACTIVE TRIPS")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                    }

                    ForEach(activeTrips, id: \.id) { trip in
                        HStack {
                            Text(trip.text)
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text(trip.place ?? "")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(hex: "FED7AA").opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            // Holidays
            if !weekHolidays.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Color(hex: "E53935"))
                        Text("HOLIDAYS")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                    }

                    ForEach(weekHolidays, id: \.date) { item in
                        HStack {
                            Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 60, alignment: .leading)

                            ForEach(item.holidays, id: \.id) { holiday in
                                HStack(spacing: 4) {
                                    if holiday.isBankHoliday {
                                        Image(systemName: "flag.fill")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.red)
                                    }
                                    Text(holiday.displayTitle)
                                        .font(.system(size: 11))
                                }
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(hex: "FECDD3").opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            // Notes preview
            if !weekNotes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundStyle(Color(hex: "F59E0B"))
                        Text("NOTES (\(weekNotes.count))")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                    }

                    ForEach(Array(weekNotes.prefix(5)), id: \.id) { note in
                        HStack {
                            Text(note.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 60, alignment: .leading)
                            Text(note.text)
                                .font(.system(size: 11))
                                .lineLimit(1)
                        }
                    }

                    if weekNotes.count > 5 {
                        Text("... and \(weekNotes.count - 5) more")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(Color(hex: "FFE566").opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Spacer()

            // Footer
            HStack {
                Text("Generated by Onsen Planner")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(32)
        .background(Color(.systemBackground))
    }

    // MARK: - Computed Properties

    private var totalExpenseFormatted: String {
        let total = weekExpenses.reduce(0.0) { $0 + ($1.amount ?? 0) }
        return formatAmount(total, currency: baseCurrency)
    }

    private var expensesByCurrency: [(currency: String, total: Double)] {
        let grouped = Dictionary(grouping: weekExpenses) { $0.currency ?? "SEK" }
        return grouped.map { (currency, expenses) in
            let total = expenses.reduce(0.0) { $0 + ($1.amount ?? 0) }
            return (currency, total)
        }.sorted { $0.total > $1.total }
    }

    private var expensesByCategory: [(category: String, total: Double)] {
        // Memo doesn't have categories, group by month instead
        let calendar = Calendar.iso8601
        let grouped = Dictionary(grouping: weekExpenses) { expense in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: expense.date)
        }
        return grouped.map { (day, expenses) in
            let total = expenses.reduce(0.0) { $0 + ($1.amount ?? 0) }
            return (day, total)
        }.sorted { $0.total > $1.total }
    }

    private func formatAmount(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(Int(amount))"
    }
}

// MARK: - Expense Report PDF (情報デザイン: Detailed financial report)

struct PDFExpenseReportPage: View {
    let expenses: [Memo]
    let baseCurrency: String
    let dateRange: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                Text(dateRange)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Rectangle()
                .fill(Color.black)
                .frame(height: 2)

            // Summary card
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(formatTotal)
                        .font(.system(size: 24, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("TRANSACTIONS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text("\(expenses.count)")
                        .font(.system(size: 24, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENCIES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text("\(currencyBreakdown.count)")
                        .font(.system(size: 24, weight: .bold))
                }

                Spacer()
            }
            .padding(16)
            .background(Color(hex: "BBF7D0").opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Currency breakdown
            if currencyBreakdown.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BY CURRENCY")
                        .font(.system(size: 12, weight: .black, design: .rounded))

                    ForEach(currencyBreakdown, id: \.currency) { item in
                        HStack {
                            Text(item.currency)
                                .font(.system(size: 11, weight: .bold))
                                .frame(width: 40)
                                .padding(4)
                                .background(JohoColors.green.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            Text(formatAmount(item.total, currency: item.currency))
                                .font(.system(size: 12))

                            if item.currency != baseCurrency {
                                Text("→ \(formatAmount(item.converted, currency: baseCurrency))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(item.count) items")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            // Category breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("BY CATEGORY")
                    .font(.system(size: 12, weight: .black, design: .rounded))

                ForEach(categoryBreakdown, id: \.category) { item in
                    HStack {
                        Text(item.category)
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: 120, alignment: .leading)

                        // Progress bar
                        GeometryReader { geo in
                            let width = geo.size.width * CGFloat(item.percentage / 100)
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                Rectangle()
                                    .fill(JohoColors.green)
                                    .frame(width: width, height: 8)
                            }
                            .clipShape(Capsule())
                        }
                        .frame(height: 8)

                        Text("\(Int(item.percentage))%")
                            .font(.system(size: 10, weight: .medium))
                            .frame(width: 36, alignment: .trailing)

                        Text(formatAmount(item.total, currency: baseCurrency))
                            .font(.system(size: 11, weight: .medium))
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Recent transactions
            VStack(alignment: .leading, spacing: 8) {
                Text("TRANSACTIONS")
                    .font(.system(size: 12, weight: .black, design: .rounded))

                ForEach(Array(expenses.prefix(15)), id: \.id) { expense in
                    HStack {
                        Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .leading)

                        Text(expense.text)
                            .font(.system(size: 10))
                            .lineLimit(1)

                        Spacer()

                        let expenseCurrency = expense.currency ?? "SEK"
                        if expenseCurrency != baseCurrency {
                            Text(formatAmount(expense.amount ?? 0, currency: expenseCurrency))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            Text("→")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }

                        Text(formatAmount(expense.amount ?? 0, currency: baseCurrency))
                            .font(.system(size: 10, weight: .medium))
                    }
                }

                if expenses.count > 15 {
                    Text("... and \(expenses.count - 15) more transactions")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Spacer()

            // Footer
            HStack {
                Text("Generated by Onsen Planner")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("Base currency: \(baseCurrency)")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(32)
        .background(Color(.systemBackground))
    }

    // MARK: - Computed Properties

    private var formatTotal: String {
        let total = expenses.reduce(0.0) { $0 + ($1.amount ?? 0) }
        return formatAmount(total, currency: baseCurrency)
    }

    private var currencyBreakdown: [(currency: String, total: Double, converted: Double, count: Int)] {
        let grouped = Dictionary(grouping: expenses) { $0.currency ?? "SEK" }
        return grouped.map { (currency, items) in
            let total = items.reduce(0.0) { $0 + ($1.amount ?? 0) }
            // Memo doesn't have convertedAmount, use original
            let converted = total
            return (currency, total, converted, items.count)
        }.sorted { $0.converted > $1.converted }
    }

    private var categoryBreakdown: [(category: String, total: Double, percentage: Double)] {
        let total = expenses.reduce(0.0) { $0 + ($1.amount ?? 0) }
        // Memo doesn't have categories, group by merchant/place instead
        let grouped = Dictionary(grouping: expenses) { $0.place ?? "Other" }
        return grouped.map { (merchant, items) in
            let merchantTotal = items.reduce(0.0) { $0 + ($1.amount ?? 0) }
            let percentage = total > 0 ? (merchantTotal / total) * 100 : 0
            return (merchant, merchantTotal, percentage)
        }.sorted { $0.total > $1.total }
    }

    private func formatAmount(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(Int(amount))"
    }
}

// MARK: - 情報デザイン Compact Week Page

/// Single-page week export with mini calendar and compact day rows
struct PDFWeekCompactPage: View {
    let weekNumber: Int
    let year: Int

    @Query private var allMemos: [Memo]
    @Query private var contacts: [Contact]

    // Filter by type
    private var notes: [Memo] { allMemos.filter { $0.type == .note } }
    private var expenses: [Memo] { allMemos.filter { $0.type == .expense } }
    private var trips: [Memo] { allMemos.filter { $0.type == .trip } }
    private var events: [Memo] { allMemos.filter { $0.type == .countdown } }

    private let calendar = Calendar.iso8601
    private let pageSize = CGSize(width: 595.2, height: 841.8) // A4

    init(weekNumber: Int, year: Int) {
        self.weekNumber = weekNumber
        self.year = year
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection

            // Mini calendar grid
            miniCalendarSection

            // Compact day rows
            dayRowsSection

            Spacer(minLength: 0)

            // Footer
            footerSection
        }
        .padding(32)
        .frame(width: pageSize.width, height: pageSize.height)
        .background(JohoColors.white)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Week \(weekNumber)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)

            Text(dateRangeString)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 2)
        }
    }

    // MARK: - Mini Calendar

    private var miniCalendarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day headers
            HStack(spacing: 0) {
                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            HStack(spacing: 4) {
                ForEach(weekDates, id: \.self) { date in
                    miniDayCell(for: date)
                }
            }
        }
        .padding(12)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }

    private func miniDayCell(for date: Date) -> some View {
        let dayData = getDayData(for: date)
        let isToday = calendar.isDateInToday(date)

        return VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(isToday ? JohoColors.white : JohoColors.black)
                .frame(width: 28, height: 28)
                .background(isToday ? JohoColors.black : Color.clear)
                .clipShape(Circle())

            // Indicator dots
            HStack(spacing: 2) {
                if dayData.hasHoliday { Circle().fill(JohoColors.pink).frame(width: 6, height: 6) }
                if dayData.hasNotes { Circle().fill(JohoColors.yellow).frame(width: 6, height: 6) }
                if dayData.hasExpenses { Circle().fill(JohoColors.green).frame(width: 6, height: 6) }
                if dayData.hasEvents { Circle().fill(JohoColors.cyan).frame(width: 6, height: 6) }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(dayData.hasHoliday ? JohoColors.pink.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Day Rows

    private var dayRowsSection: some View {
        VStack(spacing: 8) {
            ForEach(weekDates, id: \.self) { date in
                compactDayRow(for: date)
            }
        }
    }

    private func compactDayRow(for date: Date) -> some View {
        let dayData = getDayData(for: date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"

        return VStack(alignment: .leading, spacing: 6) {
            // Day header
            HStack {
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                Spacer()

                // Summary badges
                HStack(spacing: 4) {
                    if dayData.noteCount > 0 {
                        badge(count: dayData.noteCount, color: JohoColors.yellow, icon: "note.text")
                    }
                    if dayData.expenseCount > 0 {
                        badge(count: dayData.expenseCount, color: JohoColors.green, icon: "yensign.circle")
                    }
                }
            }

            // Content
            if dayData.isEmpty {
                Text("Nothing logged")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.4))
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    // Holidays
                    ForEach(dayData.holidays, id: \.self) { holiday in
                        HStack(spacing: 4) {
                            Circle().fill(JohoColors.pink).frame(width: 6, height: 6)
                            Text(holiday)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                        }
                    }

                    // Birthdays
                    ForEach(dayData.birthdays, id: \.self) { birthday in
                        HStack(spacing: 4) {
                            Circle().fill(JohoColors.pink).frame(width: 6, height: 6)
                            Text("🎂 \(birthday)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                        }
                    }

                    // Events
                    ForEach(dayData.events, id: \.self) { event in
                        HStack(spacing: 4) {
                            Circle().fill(JohoColors.cyan).frame(width: 6, height: 6)
                            Text(event)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                        }
                    }

                    // Notes (truncated)
                    ForEach(dayData.notes.prefix(2), id: \.self) { note in
                        HStack(spacing: 4) {
                            Circle().fill(JohoColors.yellow).frame(width: 6, height: 6)
                            Text(note)
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                                .lineLimit(1)
                        }
                    }
                    if dayData.notes.count > 2 {
                        Text("... +\(dayData.notes.count - 2) more notes")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                    }

                    // Expenses summary
                    if dayData.expenseTotal > 0 {
                        HStack(spacing: 4) {
                            Circle().fill(JohoColors.green).frame(width: 6, height: 6)
                            Text("Expenses: \(formatExpense(dayData.expenseTotal))")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                        }
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1)
        )
    }

    private func badge(count: Int, color: Color, icon: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text("\(count)")
                .font(.system(size: 9, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color)
        .clipShape(Capsule())
        .foregroundStyle(JohoColors.black)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text("Generated by Onsen Planner")
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.4))

            Spacer()

            Text(Date(), style: .date)
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.4))
        }
    }

    // MARK: - Data Helpers

    private var weekDates: [Date] {
        var components = DateComponents()
        components.yearForWeekOfYear = year
        components.weekOfYear = weekNumber
        components.weekday = 2 // Monday

        guard let monday = calendar.date(from: components) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    private var dateRangeString: String {
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: first)) – \(formatter.string(from: last)), \(year)"
    }

    private struct DayData {
        var holidays: [String] = []
        var birthdays: [String] = []
        var events: [String] = []
        var notes: [String] = []
        var noteCount: Int = 0
        var expenseCount: Int = 0
        var expenseTotal: Double = 0
        var hasHoliday: Bool { !holidays.isEmpty }
        var hasNotes: Bool { noteCount > 0 }
        var hasExpenses: Bool { expenseCount > 0 }
        var hasEvents: Bool { !events.isEmpty || !birthdays.isEmpty }
        var isEmpty: Bool { holidays.isEmpty && birthdays.isEmpty && events.isEmpty && notes.isEmpty && expenseCount == 0 }
    }

    private func getDayData(for date: Date) -> DayData {
        var data = DayData()

        // Holidays from cache
        if let holidays = HolidayManager.cache[Calendar.current.startOfDay(for: date)] {
            data.holidays = holidays.map { $0.displayTitle }
        }

        // Notes (Memo)
        let dayNotes = notes.filter { calendar.isDate($0.date, inSameDayAs: date) }
        data.notes = dayNotes.map { $0.text }
        data.noteCount = dayNotes.count

        // Expenses (Memo)
        let dayExpenses = expenses.filter { calendar.isDate($0.date, inSameDayAs: date) }
        data.expenseCount = dayExpenses.count
        data.expenseTotal = dayExpenses.reduce(0) { $0 + ($1.amount ?? 0) }

        // Birthdays
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        data.birthdays = contacts.compactMap { contact in
            guard let birthday = contact.birthday,
                  calendar.component(.month, from: birthday) == month,
                  calendar.component(.day, from: birthday) == day else { return nil }
            return contact.displayName
        }

        // Events (Memo countdowns)
        data.events = events.filter { calendar.isDate($0.date, inSameDayAs: date) }.map { $0.text }

        return data
    }

    private func formatExpense(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "SEK"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount)) kr"
    }
}

// MARK: - 情報デザイン Compact Month Page

/// Month export with calendar grid and content summary
struct PDFMonthCompactPage: View {
    let month: Int
    let year: Int

    @Query private var allMemos: [Memo]
    @Query private var contacts: [Contact]

    // Filter by type
    private var notes: [Memo] { allMemos.filter { $0.type == .note } }
    private var expenses: [Memo] { allMemos.filter { $0.type == .expense } }
    private var trips: [Memo] { allMemos.filter { $0.type == .trip } }
    private var events: [Memo] { allMemos.filter { $0.type == .countdown } }

    private let calendar = Calendar.iso8601
    private let pageSize = CGSize(width: 595.2, height: 841.8) // A4

    init(month: Int, year: Int) {
        self.month = month
        self.year = year
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection

            // Legend
            legendSection

            // Calendar grid
            calendarGridSection

            // Summary section
            summarySection

            Spacer(minLength: 0)

            // Footer
            footerSection
        }
        .padding(32)
        .frame(width: pageSize.width, height: pageSize.height)
        .background(JohoColors.white)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(monthName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)

            Text(String(year))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 2)
        }
    }

    // MARK: - Legend

    private var legendSection: some View {
        HStack(spacing: 16) {
            legendItem(color: JohoColors.pink, label: "Holidays/Birthdays")
            legendItem(color: JohoColors.yellow, label: "Notes")
            legendItem(color: JohoColors.green, label: "Expenses")
            legendItem(color: JohoColors.cyan, label: "Events")
        }
        .padding(.vertical, 8)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.7))
        }
    }

    // MARK: - Calendar Grid

    private var calendarGridSection: some View {
        VStack(spacing: 0) {
            // Week number + Day headers
            HStack(spacing: 0) {
                Text("W")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.6))
                    .frame(width: 30)

                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            // Week rows
            ForEach(weeksInMonth, id: \.self) { weekStart in
                weekRow(startingFrom: weekStart)
            }
        }
        .padding(12)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }

    private func weekRow(startingFrom weekStart: Date) -> some View {
        let weekNum = calendar.component(.weekOfYear, from: weekStart)

        return HStack(spacing: 0) {
            // Week number
            Text("\(weekNum)")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.5))
                .frame(width: 30)

            // Day cells
            ForEach(0..<7, id: \.self) { offset in
                if let date = calendar.date(byAdding: .day, value: offset, to: weekStart) {
                    calendarDayCell(for: date)
                }
            }
        }
    }

    private func calendarDayCell(for date: Date) -> some View {
        let dayData = getDayData(for: date)
        let isInMonth = calendar.component(.month, from: date) == month
        let isToday = calendar.isDateInToday(date)
        let day = calendar.component(.day, from: date)

        return VStack(spacing: 2) {
            Text("\(day)")
                .font(.system(size: 12, weight: isToday ? .bold : .regular, design: .rounded))
                .foregroundStyle(isInMonth ? JohoColors.black : JohoColors.black.opacity(0.3))

            // Indicator dots
            HStack(spacing: 1) {
                if dayData.hasHoliday { Circle().fill(JohoColors.pink).frame(width: 4, height: 4) }
                if dayData.hasNotes { Circle().fill(JohoColors.yellow).frame(width: 4, height: 4) }
                if dayData.hasExpenses { Circle().fill(JohoColors.green).frame(width: 4, height: 4) }
                if dayData.hasEvents { Circle().fill(JohoColors.cyan).frame(width: 4, height: 4) }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            isToday ? JohoColors.black.opacity(0.1) :
            dayData.hasHoliday ? JohoColors.pink.opacity(0.15) :
            Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(JohoColors.black.opacity(0.1), lineWidth: 0.5)
        )
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Month Summary")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)

            HStack(spacing: 16) {
                summaryCard(title: "Notes", value: "\(monthNotes.count)", color: JohoColors.yellow)
                summaryCard(title: "Expenses", value: formatExpense(monthExpenseTotal), color: JohoColors.green)
                summaryCard(title: "Events", value: "\(monthEvents.count)", color: JohoColors.cyan)
                summaryCard(title: "Holidays", value: "\(monthHolidays.count)", color: JohoColors.pink)
            }

            // Notable items
            if !monthHolidays.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Holidays & Special Days")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.7))

                    ForEach(Array(monthHolidays.prefix(5)), id: \.self) { holiday in
                        HStack(spacing: 4) {
                            Circle().fill(JohoColors.pink).frame(width: 5, height: 5)
                            Text(holiday)
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                        }
                    }
                    if monthHolidays.count > 5 {
                        Text("... +\(monthHolidays.count - 5) more")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                    }
                }
                .padding(10)
                .background(JohoColors.pink.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(12)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1)
        )
    }

    private func summaryCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)
            Text(title)
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text("Generated by Onsen Planner")
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.4))

            Spacer()

            Text(Date(), style: .date)
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.4))
        }
    }

    // MARK: - Data Helpers

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let components = DateComponents(year: year, month: month, day: 1)
        guard let date = calendar.date(from: components) else { return "" }
        return formatter.string(from: date)
    }

    private var weeksInMonth: [Date] {
        var weeks: [Date] = []
        let components = DateComponents(year: year, month: month, day: 1)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }

        // Find the Monday of the week containing the 1st
        var current = firstOfMonth
        while calendar.component(.weekday, from: current) != 2 { // Monday
            current = calendar.date(byAdding: .day, value: -1, to: current) ?? current
        }

        // Get weeks until we pass the last day of month
        let lastDay = calendar.date(byAdding: .day, value: range.count - 1, to: firstOfMonth) ?? firstOfMonth

        while current <= lastDay {
            weeks.append(current)
            current = calendar.date(byAdding: .day, value: 7, to: current) ?? current
        }

        return weeks
    }

    private var monthDates: [Date] {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }
        return (0..<range.count).compactMap { calendar.date(byAdding: .day, value: $0, to: firstOfMonth) }
    }

    private var monthNotes: [Memo] {
        notes.filter { calendar.component(.month, from: $0.date) == month && calendar.component(.year, from: $0.date) == year }
    }

    private var monthExpenseTotal: Double {
        expenses.filter { calendar.component(.month, from: $0.date) == month && calendar.component(.year, from: $0.date) == year }
            .reduce(0) { $0 + ($1.amount ?? 0) }
    }

    private var monthEvents: [Memo] {
        events.filter { calendar.component(.month, from: $0.date) == month && calendar.component(.year, from: $0.date) == year }
    }

    private var monthHolidays: [String] {
        var holidays: [String] = []
        for date in monthDates {
            if let dayHolidays = HolidayManager.cache[Calendar.current.startOfDay(for: date)] {
                holidays.append(contentsOf: dayHolidays.map { $0.displayTitle })
            }
        }
        return holidays
    }

    private struct DayData {
        var hasHoliday = false
        var hasNotes = false
        var hasExpenses = false
        var hasEvents = false
    }

    private func getDayData(for date: Date) -> DayData {
        var data = DayData()

        // Holidays
        if let holidays = HolidayManager.cache[Calendar.current.startOfDay(for: date)], !holidays.isEmpty {
            data.hasHoliday = true
        }

        // Notes (Memo)
        data.hasNotes = notes.contains { calendar.isDate($0.date, inSameDayAs: date) }

        // Expenses (Memo)
        data.hasExpenses = expenses.contains { calendar.isDate($0.date, inSameDayAs: date) }

        // Events (Memo countdowns)
        data.hasEvents = events.contains { calendar.isDate($0.date, inSameDayAs: date) }

        // Birthdays
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        if contacts.contains(where: { contact in
            guard let birthday = contact.birthday else { return false }
            return calendar.component(.month, from: birthday) == month && calendar.component(.day, from: birthday) == day
        }) {
            data.hasEvents = true
        }

        return data
    }

    private func formatExpense(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "SEK"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount)) kr"
    }
}

// MARK: - Professional Audit Reports

/// Professional Week Audit Report - Shows ALL 7 days with full details
/// Suitable for accounting/audit purposes
struct PDFWeekAuditReport: View {
    let weekNumber: Int
    let year: Int
    let pageNumber: Int
    let totalPages: Int
    let days: [Date]

    @Query private var allMemos: [Memo]
    @Query private var contacts: [Contact]

    // Filter by type
    private var notes: [Memo] { allMemos.filter { $0.type == .note } }
    private var expenses: [Memo] { allMemos.filter { $0.type == .expense } }
    private var trips: [Memo] { allMemos.filter { $0.type == .trip } }
    private var events: [Memo] { allMemos.filter { $0.type == .countdown } }

    private let calendar = Calendar.iso8601
    private let pageSize = CGSize(width: 595.2, height: 841.8) // A4

    init(weekNumber: Int, year: Int, pageNumber: Int = 1, totalPages: Int = 1, days: [Date] = []) {
        self.weekNumber = weekNumber
        self.year = year
        self.pageNumber = pageNumber
        self.totalPages = totalPages
        self.days = days.isEmpty ? Self.computeWeekDates(weekNumber: weekNumber, year: year) : days
    }

    private static func computeWeekDates(weekNumber: Int, year: Int) -> [Date] {
        let calendar = Calendar.iso8601
        var components = DateComponents()
        components.yearForWeekOfYear = year
        components.weekOfYear = weekNumber
        components.weekday = 2 // Monday

        guard let monday = calendar.date(from: components) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Professional header
            reportHeader

            Divider().background(JohoColors.black)

            // Data table (no ScrollView - PDF is fixed size)
            VStack(alignment: .leading, spacing: 0) {
                // Table header
                tableHeader

                // Daily rows - ALL days shown
                ForEach(days, id: \.self) { date in
                    dailyDataRow(for: date)
                    Divider().background(JohoColors.black.opacity(0.3))
                }

                // Week totals
                weekTotalsRow
            }

            Spacer(minLength: 8)

            // Footer
            reportFooter
        }
        .padding(24)
        .frame(width: pageSize.width, height: pageSize.height)
        .background(JohoColors.white)
    }

    // MARK: - Header

    private var reportHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("WEEKLY ACTIVITY REPORT")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                        .tracking(2)

                    Text("Week \(weekNumber), \(String(year))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    Text(dateRangeString)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Spacer()

                // Report metadata
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Generated: \(formattedGenerationDate)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))

                    Text("Onsen Planner")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Table Header

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("DATE")
                .frame(width: 90, alignment: .leading)
            Text("HOLIDAYS/EVENTS")
                .frame(width: 140, alignment: .leading)
            Text("NOTES")
                .frame(width: 150, alignment: .leading)
            Text("EXPENSES")
                .frame(minWidth: 100, alignment: .trailing)
        }
        .font(.system(size: 8, weight: .bold, design: .rounded))
        .foregroundStyle(JohoColors.black.opacity(0.6))
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(JohoColors.black.opacity(0.05))
    }

    // MARK: - Daily Data Row

    private func dailyDataRow(for date: Date) -> some View {
        let dayNotes = notes.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let dayExpenses = expenses.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let dayHolidays = HolidayManager.cache[Calendar.current.startOfDay(for: date)] ?? []
        let dayEvents = events.filter { calendar.isDate($0.date, inSameDayAs: date) }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, MMM d"

        let isEmpty = dayNotes.isEmpty && dayExpenses.isEmpty && dayHolidays.isEmpty && dayEvents.isEmpty

        return HStack(alignment: .top, spacing: 0) {
            // Date column
            VStack(alignment: .leading, spacing: 2) {
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(JohoColors.black)

                if calendar.isDateInToday(date) {
                    Text("TODAY")
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(JohoColors.black)
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                }
            }
            .frame(width: 90, alignment: .leading)

            // Holidays/Events column
            VStack(alignment: .leading, spacing: 2) {
                ForEach(dayHolidays, id: \.displayTitle) { holiday in
                    HStack(spacing: 3) {
                        Circle().fill(JohoColors.pink).frame(width: 5, height: 5)
                        Text(holiday.displayTitle)
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                            .lineLimit(1)
                    }
                }
                ForEach(dayEvents) { event in
                    HStack(spacing: 3) {
                        Circle().fill(JohoColors.cyan).frame(width: 5, height: 5)
                        Text(event.text)
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                            .lineLimit(1)
                    }
                }
                if dayHolidays.isEmpty && dayEvents.isEmpty {
                    Text("—")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.3))
                }
            }
            .frame(width: 140, alignment: .leading)

            // Notes column
            VStack(alignment: .leading, spacing: 2) {
                ForEach(dayNotes.prefix(3)) { note in
                    HStack(spacing: 3) {
                        Circle().fill(JohoColors.yellow).frame(width: 5, height: 5)
                        Text(note.text.prefix(40) + (note.text.count > 40 ? "..." : ""))
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                            .lineLimit(1)
                    }
                }
                if dayNotes.count > 3 {
                    Text("+\(dayNotes.count - 3) more")
                        .font(.system(size: 8, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
                if dayNotes.isEmpty {
                    Text("—")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.3))
                }
            }
            .frame(width: 150, alignment: .leading)

            // Expenses column
            VStack(alignment: .trailing, spacing: 2) {
                ForEach(dayExpenses.prefix(3)) { expense in
                    HStack(spacing: 3) {
                        Text(expense.place ?? "Other")
                            .font(.system(size: 8, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                        Text(formatCurrency(expense.amount ?? 0, currency: expense.currency ?? "SEK"))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                    }
                }
                if dayExpenses.count > 3 {
                    Text("+\(dayExpenses.count - 3) more")
                        .font(.system(size: 8, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
                if !dayExpenses.isEmpty {
                    Divider().frame(width: 60)
                    Text(formatCurrency(dayExpenses.reduce(0) { $0 + ($1.amount ?? 0) }, currency: dayExpenses.first?.currency ?? "SEK"))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.green)
                }
                if dayExpenses.isEmpty {
                    Text("—")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.3))
                }
            }
            .frame(minWidth: 100, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(isEmpty ? Color.clear : JohoColors.yellow.opacity(0.05))
    }

    // MARK: - Week Totals

    private var weekTotalsRow: some View {
        let weekNotes = notes.filter { note in days.contains { calendar.isDate($0, inSameDayAs: note.date) } }
        let weekExpenses = expenses.filter { expense in days.contains { calendar.isDate($0, inSameDayAs: expense.date) } }
        let totalExpenses = weekExpenses.reduce(0) { $0 + ($1.amount ?? 0) }

        return HStack(spacing: 0) {
            Text("WEEK TOTALS")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)
                .frame(width: 90, alignment: .leading)

            Text("\(countHolidaysAndEvents()) holidays/events")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.7))
                .frame(width: 140, alignment: .leading)

            Text("\(weekNotes.count) notes")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.7))
                .frame(width: 150, alignment: .leading)

            Text(formatCurrency(totalExpenses, currency: weekExpenses.first?.currency ?? "SEK"))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.green)
                .frame(minWidth: 100, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(JohoColors.black.opacity(0.08))
    }

    // MARK: - Footer

    private var reportFooter: some View {
        HStack {
            Text("Confidential - For authorized use only")
                .font(.system(size: 8, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.4))

            Spacer()

            Text("Page \(pageNumber) of \(totalPages)")
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.5))
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private var dateRangeString: String {
        guard let first = days.first, let last = days.last else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: first)) – \(formatter.string(from: last)), \(year)"
    }

    private var formattedGenerationDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter.string(from: Date())
    }

    private func formatCurrency(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }

    private func countHolidaysAndEvents() -> Int {
        var count = 0
        for date in days {
            if let holidays = HolidayManager.cache[Calendar.current.startOfDay(for: date)] {
                count += holidays.count
            }
            count += events.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
        }
        return count
    }
}

/// Professional Month Audit Report - Shows ALL days in month with full details
/// Multi-page format suitable for accounting/audit purposes
struct PDFMonthAuditReport: View {
    let month: Int
    let year: Int
    let pageNumber: Int
    let totalPages: Int
    let daysOnThisPage: [Date]

    @Query private var allMemos: [Memo]
    @Query private var contacts: [Contact]

    // Filter by type
    private var notes: [Memo] { allMemos.filter { $0.type == .note } }
    private var expenses: [Memo] { allMemos.filter { $0.type == .expense } }
    private var trips: [Memo] { allMemos.filter { $0.type == .trip } }
    private var events: [Memo] { allMemos.filter { $0.type == .countdown } }

    private let calendar = Calendar.iso8601
    private let pageSize = CGSize(width: 595.2, height: 841.8) // A4

    init(month: Int, year: Int, pageNumber: Int = 1, totalPages: Int = 1, daysOnThisPage: [Date] = []) {
        self.month = month
        self.year = year
        self.pageNumber = pageNumber
        self.totalPages = totalPages
        self.daysOnThisPage = daysOnThisPage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Professional header
            reportHeader

            Divider().background(JohoColors.black)

            // Data table
            VStack(alignment: .leading, spacing: 0) {
                // Table header
                tableHeader

                // Daily rows
                ForEach(daysOnThisPage, id: \.self) { date in
                    dailyDataRow(for: date)
                    Divider().background(JohoColors.black.opacity(0.2))
                }

                // Show totals on last page
                if pageNumber == totalPages {
                    monthTotalsRow
                }
            }

            Spacer(minLength: 8)

            // Footer
            reportFooter
        }
        .padding(24)
        .frame(width: pageSize.width, height: pageSize.height)
        .background(JohoColors.white)
    }

    // MARK: - Header

    private var reportHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MONTHLY ACTIVITY REPORT")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                        .tracking(2)

                    Text("\(monthName) \(String(year))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Generated: \(formattedGenerationDate)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))

                    Text("Onsen Planner")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
            }
        }
        .padding(.bottom, 12)
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let components = DateComponents(year: year, month: month, day: 1)
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "Month \(month)"
    }

    // MARK: - Table Header

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("DATE")
                .frame(width: 80, alignment: .leading)
            Text("HOLIDAYS/EVENTS")
                .frame(width: 130, alignment: .leading)
            Text("NOTES")
                .frame(width: 160, alignment: .leading)
            Text("EXPENSES")
                .frame(minWidth: 100, alignment: .trailing)
        }
        .font(.system(size: 8, weight: .bold, design: .rounded))
        .foregroundStyle(JohoColors.black.opacity(0.6))
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(JohoColors.black.opacity(0.05))
    }

    // MARK: - Daily Data Row

    private func dailyDataRow(for date: Date) -> some View {
        let dayNotes = notes.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let dayExpenses = expenses.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let dayHolidays = HolidayManager.cache[Calendar.current.startOfDay(for: date)] ?? []
        let dayEvents = events.filter { calendar.isDate($0.date, inSameDayAs: date) }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE d"

        let isEmpty = dayNotes.isEmpty && dayExpenses.isEmpty && dayHolidays.isEmpty && dayEvents.isEmpty
        let isWeekend = calendar.isDateInWeekend(date)

        return HStack(alignment: .top, spacing: 0) {
            // Date column
            VStack(alignment: .leading, spacing: 1) {
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(isWeekend ? JohoColors.black.opacity(0.5) : JohoColors.black)

                if calendar.isDateInToday(date) {
                    Text("TODAY")
                        .font(.system(size: 6, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(JohoColors.black)
                        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                }
            }
            .frame(width: 80, alignment: .leading)

            // Holidays/Events
            VStack(alignment: .leading, spacing: 1) {
                ForEach(dayHolidays.prefix(2), id: \.displayTitle) { holiday in
                    HStack(spacing: 2) {
                        Circle().fill(JohoColors.pink).frame(width: 4, height: 4)
                        Text(holiday.displayTitle)
                            .font(.system(size: 8, design: .rounded))
                            .lineLimit(1)
                    }
                }
                ForEach(dayEvents.prefix(2)) { event in
                    HStack(spacing: 2) {
                        Circle().fill(JohoColors.cyan).frame(width: 4, height: 4)
                        Text(event.text)
                            .font(.system(size: 8, design: .rounded))
                            .lineLimit(1)
                    }
                }
                if dayHolidays.isEmpty && dayEvents.isEmpty {
                    Text("—")
                        .font(.system(size: 8, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.2))
                }
            }
            .foregroundStyle(JohoColors.black)
            .frame(width: 130, alignment: .leading)

            // Notes
            VStack(alignment: .leading, spacing: 1) {
                ForEach(dayNotes.prefix(2)) { note in
                    HStack(spacing: 2) {
                        Circle().fill(JohoColors.yellow).frame(width: 4, height: 4)
                        Text(note.text.prefix(35) + (note.text.count > 35 ? "..." : ""))
                            .font(.system(size: 8, design: .rounded))
                            .lineLimit(1)
                    }
                }
                if dayNotes.count > 2 {
                    Text("+\(dayNotes.count - 2) more")
                        .font(.system(size: 7, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.4))
                }
                if dayNotes.isEmpty {
                    Text("—")
                        .font(.system(size: 8, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.2))
                }
            }
            .foregroundStyle(JohoColors.black)
            .frame(width: 160, alignment: .leading)

            // Expenses
            VStack(alignment: .trailing, spacing: 1) {
                let dayTotal = dayExpenses.reduce(0) { $0 + ($1.amount ?? 0) }
                if !dayExpenses.isEmpty {
                    Text("\(dayExpenses.count) item\(dayExpenses.count == 1 ? "" : "s")")
                        .font(.system(size: 7, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                    Text(formatCurrency(dayTotal, currency: dayExpenses.first?.currency ?? "SEK"))
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoColors.green)
                } else {
                    Text("—")
                        .font(.system(size: 8, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.2))
                }
            }
            .frame(minWidth: 100, alignment: .trailing)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(
            isEmpty ? (isWeekend ? JohoColors.black.opacity(0.02) : Color.clear) :
            JohoColors.yellow.opacity(0.05)
        )
    }

    // MARK: - Month Totals

    private var monthTotalsRow: some View {
        let allMonthDates = Self.getAllMonthDates(month: month, year: year)
        let monthNotes = notes.filter { note in allMonthDates.contains { calendar.isDate($0, inSameDayAs: note.date) } }
        let monthExpenses = expenses.filter { expense in allMonthDates.contains { calendar.isDate($0, inSameDayAs: expense.date) } }
        let totalExpenses = monthExpenses.reduce(0) { $0 + ($1.amount ?? 0) }

        var holidayCount = 0
        for date in allMonthDates {
            if let holidays = HolidayManager.cache[Calendar.current.startOfDay(for: date)] {
                holidayCount += holidays.count
            }
        }
        let eventCount = events.filter { event in allMonthDates.contains { calendar.isDate($0, inSameDayAs: event.date) } }.count

        return HStack(spacing: 0) {
            Text("MONTH TOTALS")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)
                .frame(width: 80, alignment: .leading)

            Text("\(holidayCount + eventCount) holidays/events")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.7))
                .frame(width: 130, alignment: .leading)

            Text("\(monthNotes.count) notes")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.7))
                .frame(width: 160, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(monthExpenses.count) expenses")
                    .font(.system(size: 8, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.5))
                Text(formatCurrency(totalExpenses, currency: monthExpenses.first?.currency ?? "SEK"))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.green)
            }
            .frame(minWidth: 100, alignment: .trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(JohoColors.black.opacity(0.08))
    }

    // MARK: - Footer

    private var reportFooter: some View {
        HStack {
            Text("Confidential - For authorized use only")
                .font(.system(size: 8, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.4))

            Spacer()

            Text("Page \(pageNumber) of \(totalPages)")
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.5))
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private var formattedGenerationDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter.string(from: Date())
    }

    private func formatCurrency(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }

    static func getAllMonthDates(month: Int, year: Int) -> [Date] {
        let calendar = Calendar.iso8601
        var components = DateComponents(year: year, month: month, day: 1)
        guard let startOfMonth = calendar.date(from: components) else { return [] }

        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<32
        return range.compactMap { day in
            components.day = day
            return calendar.date(from: components)
        }
    }
}
