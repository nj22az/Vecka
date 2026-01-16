//
//  SimplePDFExportView.swift
//  Onsen Planner
//
//  Simplified PDF export - exports exactly what you see on screen
//

import SwiftUI
import SwiftData

struct SimplePDFExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let exportContext: PDFExportContext

    @State private var isGenerating = false
    @State private var generatedURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview of what will be exported (情報デザイン styled)
                VStack(spacing: JohoDimensions.spacingMD) {
                    // Icon zone
                    Image(systemName: exportContext.icon)
                        .font(.system(size: 48, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 80, height: 80)
                        .background(JohoColors.cyan.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(JohoColors.black, lineWidth: 1.5)
                        )

                    Text(exportContext.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    Text(exportContext.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))

                    Text(exportContext.pageCountDescription)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.4))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(JohoColors.black.opacity(0.05))
                        .clipShape(Capsule())
                }
                .padding(.top, JohoDimensions.spacingSM)

                Spacer()

                // Export button
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Button {
                    generatePDF()
                } label: {
                    if isGenerating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Export as PDF", systemImage: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isGenerating)
                .padding(.bottom, JohoDimensions.spacingXL)
            }
            .navigationTitle("Export PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = generatedURL {
                    ShareSheet(url: url)
                }
            }
        }
    }

    private func generatePDF() {
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let url: URL

                switch exportContext {
                case .summary:
                    url = try await SimplePDFExportService.exportSummary(modelContext: modelContext)
                case .day(let date):
                    url = try await SimplePDFExportService.exportDay(date, modelContext: modelContext)
                case .week(let week, let year):
                    url = try await SimplePDFExportService.exportWeek(weekNumber: week, year: year, modelContext: modelContext)
                case .month(let month, let year):
                    url = try await SimplePDFExportService.exportMonth(month: month, year: year, modelContext: modelContext)
                case .weekSummary(let week, let year, let baseCurrency):
                    url = try await SimplePDFExportService.exportWeekSummary(weekNumber: week, year: year, baseCurrency: baseCurrency, modelContext: modelContext)
                case .expenseReportWeek(let week, let year, let baseCurrency):
                    url = try await SimplePDFExportService.exportExpenseReportForWeek(weekNumber: week, year: year, baseCurrency: baseCurrency, modelContext: modelContext)
                case .expenseReportMonth(let month, let year, let baseCurrency):
                    url = try await SimplePDFExportService.exportExpenseReportForMonth(month: month, year: year, baseCurrency: baseCurrency, modelContext: modelContext)
                case .expenseReportTrip(let trip, let baseCurrency):
                    url = try await SimplePDFExportService.exportExpenseReportForTrip(trip: trip, baseCurrency: baseCurrency, modelContext: modelContext)
                }

                await MainActor.run {
                    generatedURL = url
                    showShareSheet = true
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate PDF: \(error.localizedDescription)"
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Export Context

enum PDFExportContext: Identifiable {
    case summary
    case day(Date)
    case week(weekNumber: Int, year: Int)
    case month(month: Int, year: Int)
    case weekSummary(weekNumber: Int, year: Int, baseCurrency: String)
    case expenseReportWeek(weekNumber: Int, year: Int, baseCurrency: String)
    case expenseReportMonth(month: Int, year: Int, baseCurrency: String)
    case expenseReportTrip(trip: TravelTrip, baseCurrency: String)

    var id: String {
        switch self {
        case .summary: return "summary"
        case .day(let date): return "day-\(date.timeIntervalSince1970)"
        case .week(let week, let year): return "week-\(week)-\(year)"
        case .month(let month, let year): return "month-\(month)-\(year)"
        case .weekSummary(let week, let year, _): return "weekSummary-\(week)-\(year)"
        case .expenseReportWeek(let week, let year, _): return "expenseWeek-\(week)-\(year)"
        case .expenseReportMonth(let month, let year, _): return "expenseMonth-\(month)-\(year)"
        case .expenseReportTrip(let trip, _): return "expenseTrip-\(trip.id)"
        }
    }

    var icon: String {
        switch self {
        case .summary: return "list.bullet.rectangle"
        case .day: return "calendar.day.timeline.left"
        case .week: return "calendar"
        case .month: return "calendar.badge.clock"
        case .weekSummary: return "square.text.square"
        case .expenseReportWeek, .expenseReportMonth, .expenseReportTrip: return "dollarsign.circle"
        }
    }

    var title: String {
        switch self {
        case .summary:
            return "Summary Report"
        case .day(let date):
            return DateFormatterCache.fullDate.string(from: date)
        case .week(let week, let year):
            return "Week \(week), \(year)"
        case .month(let month, let year):
            let monthName = DateFormatterCache.monthName.monthSymbols[month - 1]
            return "\(monthName) \(year)"
        case .weekSummary(let week, _, _):
            return "Week \(week) Summary"
        case .expenseReportWeek(let week, _, _):
            return "Expense Report – Week \(week)"
        case .expenseReportMonth(let month, let year, _):
            let monthName = DateFormatterCache.monthName.monthSymbols[month - 1]
            return "Expense Report – \(monthName) \(year)"
        case .expenseReportTrip(let trip, _):
            return "Trip Expenses – \(trip.tripName)"
        }
    }

    var subtitle: String {
        switch self {
        case .summary:
            return "Current week overview with stats"
        case .day:
            return "Daily notes, events, and activities"
        case .week:
            return "All 7 days with full activity details"
        case .month:
            return "All days with full activity details"
        case .weekSummary:
            return "Compact single-page week overview"
        case .expenseReportWeek:
            return "All expenses for the week with breakdown"
        case .expenseReportMonth:
            return "Monthly expense breakdown by category"
        case .expenseReportTrip(let trip, _):
            return "Expenses for \(trip.destination)"
        }
    }

    var pageCountDescription: String {
        switch self {
        case .summary:
            return "1 page"
        case .day:
            return "1 page"
        case .week:
            return "1 page (audit report)"
        case .month:
            return "2-3 pages (audit report)"
        case .weekSummary:
            return "1 page (compact summary)"
        case .expenseReportWeek, .expenseReportMonth, .expenseReportTrip:
            return "1 page (expense breakdown)"
        }
    }
}

