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

    @MainActor
    static func exportWeek(weekNumber: Int, year: Int, modelContext: ModelContext) async throws -> URL {
        let days = WeekCalculator.shared.dates(in: weekNumber, year: year)

        guard !days.isEmpty else {
            throw PDFExportError.noData
        }

        let pages = days.map { date in
            PDFDayPage(date: date)
                .environment(\.modelContext, modelContext)
        }

        guard let url = SimplePDFRenderer.renderPages(pages) else {
            throw PDFExportError.renderingFailed
        }
        return url
    }

    @MainActor
    static func exportMonth(month: Int, year: Int, modelContext: ModelContext) async throws -> URL {
        let calendar = Calendar.iso8601

        // Get all days in month
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            throw PDFExportError.noData
        }

        let daysInMonth = range.count

        let days = (0..<daysInMonth).compactMap { dayOffset -> Date? in
            calendar.date(byAdding: .day, value: dayOffset, to: monthStart)
        }

        let pages = days.map { date in
            PDFDayPage(date: date)
                .environment(\.modelContext, modelContext)
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
        expenses: [ExpenseItem],
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

        let descriptor = FetchDescriptor<ExpenseItem>(
            predicate: #Predicate { expense in
                expense.date >= start && expense.date < weekEnd
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

        let descriptor = FetchDescriptor<ExpenseItem>(
            predicate: #Predicate { expense in
                expense.date >= monthStart && expense.date < monthEnd
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
        trip: TravelTrip,
        baseCurrency: String,
        modelContext: ModelContext
    ) async throws -> URL {
        let expenses = trip.expenses ?? []

        guard !expenses.isEmpty else {
            throw PDFExportError.noData
        }

        let dateRange = "\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) – \(trip.endDate.formatted(date: .abbreviated, time: .omitted))"

        return try await exportExpenseReport(
            expenses: Array(expenses).sorted { $0.date > $1.date },
            baseCurrency: baseCurrency,
            title: "Trip Expenses – \(trip.tripName)",
            dateRange: dateRange
        )
    }
}

// MARK: - PDF Page Templates

struct PDFSummaryPage: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TravelTrip.startDate) private var trips: [TravelTrip]
    @Query(sort: \ExpenseItem.date, order: .reverse) private var expenses: [ExpenseItem]
    @Query(sort: \DailyNote.date, order: .reverse) private var notes: [DailyNote]
    @Query private var countdowns: [CountdownEvent]

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
            if !trips.filter({ $0.startDate <= Date() && $0.endDate >= Date() }).isEmpty {
                PDFSection(title: NSLocalizedString("pdf.active_trips", value: "Active Trips", comment: ""), icon: "suitcase.fill") {
                    ForEach(trips.filter({ $0.startDate <= Date() && $0.endDate >= Date() })) { trip in
                        Text("📍 \(trip.destination)")
                            .font(.system(size: 12))
                    }
                }
            }

            // Recent Expenses
            if !expenses.prefix(5).isEmpty {
                PDFSection(title: NSLocalizedString("pdf.recent_expenses", value: "Recent Expenses", comment: ""), icon: "dollarsign.circle.fill") {
                    ForEach(Array(expenses.prefix(5)), id: \.id) { expense in
                        HStack {
                            Text(expense.itemDescription)
                                .font(.system(size: 12))
                            Spacer()
                            Text(expense.amount, format: .currency(code: expense.currency))
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                }
            }

            // Recent Notes
            if !notes.prefix(5).isEmpty {
                PDFSection(title: NSLocalizedString("pdf.recent_notes", value: "Recent Notes", comment: ""), icon: "note.text") {
                    ForEach(Array(notes.prefix(5)), id: \.id) { note in
                        if let birthdayInfo = PersonnummerParser.extractBirthdayInfo(from: note.content) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🎂 \(birthdayInfo.localizedDescription)")
                                    .font(.system(size: 12, weight: .medium))
                            }
                        } else {
                            Text("• \(note.content)")
                                .font(.system(size: 12))
                                .lineLimit(2)
                        }
                    }
                }
            }

            Spacer()

            // Footer
            Text(NSLocalizedString("pdf.generated_by", value: "Generated by WeekGrid", comment: ""))
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

    private var dayNotes: [DailyNote] {
        let calendar = Calendar.iso8601
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let descriptor = FetchDescriptor<DailyNote>(
            predicate: #Predicate<DailyNote> { note in
                note.date >= startOfDay && note.date < endOfDay
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var dayHolidays: [HolidayCacheItem] {
        HolidayManager.shared.holidayCache[Calendar.iso8601.startOfDay(for: date)] ?? []
    }

    private var dayExpenses: [ExpenseItem] {
        let calendar = Calendar.iso8601
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let descriptor = FetchDescriptor<ExpenseItem>(
            predicate: #Predicate<ExpenseItem> { expense in
                expense.date >= startOfDay && expense.date < endOfDay
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var activeTrips: [TravelTrip] {
        let descriptor = FetchDescriptor<TravelTrip>(
            predicate: #Predicate<TravelTrip> { trip in
                trip.startDate <= date && trip.endDate >= date
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
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
                                Text(trip.tripName)
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text(trip.destination)
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
                            if !note.content.isEmpty {
                                if let birthdayInfo = PersonnummerParser.extractBirthdayInfo(from: note.content) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("🎂 \(birthdayInfo.localizedDescription)")
                                            .font(.system(size: 12, weight: .medium))
                                            .padding(.vertical, 4)
                                    }
                                } else {
                                    Text(note.content)
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
                                Text(expense.itemDescription)
                                    .font(.system(size: 12))
                                Spacer()
                                Text(expense.amount, format: .currency(code: expense.currency))
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }
                    }
                }
            }

            Spacer()

            // Footer
            Text(NSLocalizedString("pdf.generated_by", value: "Generated by WeekGrid", comment: ""))
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
    @Query(sort: \ExpenseItem.date, order: .reverse) private var allExpenses: [ExpenseItem]
    @Query(sort: \DailyNote.date, order: .reverse) private var allNotes: [DailyNote]
    @Query(sort: \TravelTrip.startDate, order: .reverse) private var allTrips: [TravelTrip]
    @Query private var allCountdowns: [CountdownEvent]

    private var weekDates: [Date] {
        WeekCalculator.shared.dates(in: weekNumber, year: year)
    }

    private var weekExpenses: [ExpenseItem] {
        guard let start = weekDates.first, let end = weekDates.last else { return [] }
        let calendar = Calendar.iso8601
        let weekEnd = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        return allExpenses.filter { $0.date >= start && $0.date < weekEnd }
    }

    private var weekNotes: [DailyNote] {
        guard let start = weekDates.first, let end = weekDates.last else { return [] }
        let calendar = Calendar.iso8601
        let weekEnd = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        return allNotes.filter { $0.date >= start && $0.date < weekEnd }
    }

    private var activeTrips: [TravelTrip] {
        guard let start = weekDates.first, let end = weekDates.last else { return [] }
        return allTrips.filter { trip in
            (trip.startDate <= end && trip.endDate >= start)
        }
    }

    private var weekHolidays: [(date: Date, holidays: [HolidayCacheItem])] {
        weekDates.compactMap { date in
            let holidays = HolidayManager.shared.holidayCache[Calendar.iso8601.startOfDay(for: date)] ?? []
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
                                        .fill(Color.green.opacity(0.3))
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
                            Text(trip.tripName)
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text(trip.destination)
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
                            Text(note.content)
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
        let total = weekExpenses.reduce(0.0) { $0 + ($1.convertedAmount ?? $1.amount) }
        return formatAmount(total, currency: baseCurrency)
    }

    private var expensesByCurrency: [(currency: String, total: Double)] {
        let grouped = Dictionary(grouping: weekExpenses) { $0.currency }
        return grouped.map { (currency, expenses) in
            let total = expenses.reduce(0.0) { $0 + $1.amount }
            return (currency, total)
        }.sorted { $0.total > $1.total }
    }

    private var expensesByCategory: [(category: String, total: Double)] {
        let grouped = Dictionary(grouping: weekExpenses) { $0.category?.name ?? "Other" }
        return grouped.map { (category, expenses) in
            let total = expenses.reduce(0.0) { $0 + ($1.convertedAmount ?? $1.amount) }
            return (category, total)
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
    let expenses: [ExpenseItem]
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
                                .background(Color.green.opacity(0.2))
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
                                    .fill(Color.green)
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

                        Text(expense.itemDescription)
                            .font(.system(size: 10))
                            .lineLimit(1)

                        Spacer()

                        if expense.currency != baseCurrency {
                            Text(formatAmount(expense.amount, currency: expense.currency))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            Text("→")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }

                        Text(formatAmount(expense.convertedAmount ?? expense.amount, currency: baseCurrency))
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
        let total = expenses.reduce(0.0) { $0 + ($1.convertedAmount ?? $1.amount) }
        return formatAmount(total, currency: baseCurrency)
    }

    private var currencyBreakdown: [(currency: String, total: Double, converted: Double, count: Int)] {
        let grouped = Dictionary(grouping: expenses) { $0.currency }
        return grouped.map { (currency, items) in
            let total = items.reduce(0.0) { $0 + $1.amount }
            let converted = items.reduce(0.0) { $0 + ($1.convertedAmount ?? $1.amount) }
            return (currency, total, converted, items.count)
        }.sorted { $0.converted > $1.converted }
    }

    private var categoryBreakdown: [(category: String, total: Double, percentage: Double)] {
        let total = expenses.reduce(0.0) { $0 + ($1.convertedAmount ?? $1.amount) }
        let grouped = Dictionary(grouping: expenses) { $0.category?.name ?? "Other" }
        return grouped.map { (category, items) in
            let categoryTotal = items.reduce(0.0) { $0 + ($1.convertedAmount ?? $1.amount) }
            let percentage = total > 0 ? (categoryTotal / total) * 100 : 0
            return (category, categoryTotal, percentage)
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
