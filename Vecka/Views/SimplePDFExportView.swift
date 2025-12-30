//
//  SimplePDFExportView.swift
//  WeekGrid
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
                // Preview of what will be exported
                VStack(spacing: 12) {
                    Image(systemName: exportContext.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text(exportContext.title)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(exportContext.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(exportContext.pageCountDescription)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, Spacing.extraLarge)

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
                .padding(.bottom, Spacing.extraLarge)
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

enum PDFExportContext {
    case summary
    case day(Date)
    case week(weekNumber: Int, year: Int)
    case month(month: Int, year: Int)

    var icon: String {
        switch self {
        case .summary: return "list.bullet.rectangle"
        case .day: return "calendar.day.timeline.left"
        case .week: return "calendar"
        case .month: return "calendar.badge.clock"
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
        }
    }

    var subtitle: String {
        switch self {
        case .summary:
            return "Current week overview with stats"
        case .day:
            return "Daily notes, events, and activities"
        case .week:
            return "7 days with full details"
        case .month:
            return "Complete month overview"
        }
    }

    var pageCountDescription: String {
        switch self {
        case .summary:
            return "1 page"
        case .day:
            return "1 page"
        case .week:
            return "7 pages (one per day)"
        case .month(let month, let year):
            let calendar = Calendar.iso8601
            let dateComponents = DateComponents(year: year, month: month, day: 1)
            guard let date = calendar.date(from: dateComponents),
                  let range = calendar.range(of: .day, in: .month, for: date) else {
                return "~30 pages (one per day)"
            }
            let daysInMonth = range.count
            return "\(daysInMonth) pages (one per day)"
        }
    }
}

