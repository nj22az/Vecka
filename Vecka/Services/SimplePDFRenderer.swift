//
//  SimplePDFRenderer.swift
//  WeekGrid
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
        let filename = "WeekGrid-\(UUID().uuidString).pdf"
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
        let filename = "WeekGrid-\(UUID().uuidString).pdf"
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
                                Image(systemName: holiday.isRedDay ? "flag.fill" : "flag")
                                    .foregroundStyle(holiday.isRedDay ? .red : .blue)
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
