//
//  PDFExportView.swift
//  Vecka
//
//  User interface for PDF export configuration and generation
//

import SwiftUI
import SwiftData

struct PDFExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Export configuration
    @State private var exportMode: ExportMode = .day
    @State private var selectedDate = Date()
    @State private var selectedWeek = WeekCalculator.shared.currentWeekNumber()
    @State private var selectedMonth = Calendar.iso8601.component(.month, from: Date())
    @State private var selectedYear = Calendar.iso8601.component(.year, from: Date())
    @State private var rangeStart = Date()
    @State private var rangeEnd = Date()

    // Options
    @State private var includeWeather = false
    @State private var includeStatistics = true
    @State private var includeNotes = true
    @State private var includeHolidays = true
    @State private var includeExpenses = true

    // Export state
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    // Preview state
    @State private var isLoadingPreview = false
    @State private var previewData: ReportPreviewData?
    @State private var previewTask: Task<Void, Never>?

    enum ExportMode: String, CaseIterable, Identifiable {
        case day = "Single Day"
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case range = "Date Range"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Mode Selection
                Section {
                    Picker("Export", selection: $exportMode) {
                        ForEach(ExportMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Export Type")
                }

                // Date Selection
                Section {
                    switch exportMode {
                    case .day:
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)

                    case .week:
                        Picker("Week", selection: $selectedWeek) {
                            ForEach(1...ViewUtilities.weeksInYear(selectedYear), id: \.self) { week in
                                Text("Week \(week)").tag(week)
                            }
                        }
                        Picker("Year", selection: $selectedYear) {
                            ForEach(yearRange(), id: \.self) { year in
                                Text(verbatim: "\(year)").tag(year)
                            }
                        }

                    case .month:
                        Picker("Month", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(DateFormatterCache.monthName.monthSymbols[month - 1]).tag(month)
                            }
                        }
                        Picker("Year", selection: $selectedYear) {
                            ForEach(yearRange(), id: \.self) { year in
                                Text(verbatim: "\(year)").tag(year)
                            }
                        }

                    case .year:
                        Picker("Year", selection: $selectedYear) {
                            ForEach(yearRange(), id: \.self) { year in
                                Text(verbatim: "\(year)").tag(year)
                            }
                        }

                    case .range:
                        DatePicker("Start Date", selection: $rangeStart, displayedComponents: .date)
                        DatePicker("End Date", selection: $rangeEnd, displayedComponents: .date)
                    }
                } header: {
                    Text("Date Selection")
                } footer: {
                    Text(exportScopeDescription)
                        .font(.caption)
                }

                // Options
                Section {
                    Toggle("Include Notes", isOn: $includeNotes)
                    Toggle("Include Expenses", isOn: $includeExpenses)
                    Toggle("Include Holidays", isOn: $includeHolidays)
                    Toggle("Include Statistics", isOn: $includeStatistics)

                    // MARK: - Weather option (Disabled)
                    // if #available(iOS 16.0, *) {
                    //     Toggle("Include Weather", isOn: $includeWeather)
                    // }
                } header: {
                    Text("Export Options")
                } footer: {
                    Text("Export includes selected data for the chosen date range")
                        .font(.caption)
                    // if includeWeather {
                    //     Text("Weather data will be included if available")
                    //         .font(.caption)
                    // }
                }

                // Live Preview
                Section {
                    if isLoadingPreview {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Loading preview...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                    } else if let preview = previewData {
                        VStack(alignment: .leading, spacing: 16) {
                            // Report Summary Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text(preview.reportTitle)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                HStack(spacing: 16) {
                                    if preview.totalExpenses > 0 {
                                        HStack(spacing: 4) {
                                            Image(systemName: "creditcard.fill")
                                                .font(.caption)
                                                .foregroundStyle(JohoColors.green)
                                            Text(preview.totalExpenses, format: .currency(code: preview.currency))
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                        }
                                    }
                                    if preview.tripCount > 0 {
                                        HStack(spacing: 4) {
                                            Image(systemName: "airplane.departure")
                                                .font(.caption)
                                                .foregroundStyle(JohoColors.orange)
                                            Text("\(preview.tripCount) trip\(preview.tripCount == 1 ? "" : "s")")
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                        }
                                    }
                                }
                                .foregroundStyle(JohoColors.black.opacity(0.7))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                Squircle(cornerRadius: 12)
                                    .fill(JohoColors.white)
                            )
                            .overlay(
                                Squircle(cornerRadius: 12)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )

                            // Daily Activity Preview (first 3 days)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Activity Preview")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                ForEach(preview.dailyEntries.prefix(3), id: \.date) { day in
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Date Header
                                        HStack {
                                            Text(day.date.formatted(date: .abbreviated, time: .omitted))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)

                                            if let weekday = Calendar.current.dateComponents([.weekday], from: day.date).weekday {
                                                Text(Calendar.current.weekdaySymbols[weekday - 1])
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        // Holidays
                                        if !day.holidays.isEmpty {
                                            ForEach(day.holidays, id: \.self) { holiday in
                                                HStack(spacing: 6) {
                                                    Image(systemName: "flag.fill")
                                                        .font(.caption2)
                                                        .foregroundStyle(.red)
                                                    Text(holiday)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }

                                        // Notes (full content)
                                        if !day.notes.isEmpty {
                                            ForEach(day.notes, id: \.self) { note in
                                                Text("• \(note)")
                                                    .font(.caption)
                                                    .foregroundStyle(.primary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }

                                        // Expenses
                                        if !day.expenses.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                ForEach(day.expenses, id: \.description) { expense in
                                                    HStack {
                                                        Text(expense.description)
                                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                                            .foregroundStyle(JohoColors.black.opacity(0.6))
                                                        Spacer()
                                                        Text(expense.amount, format: .currency(code: expense.currency))
                                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                            .foregroundStyle(JohoColors.green)
                                                    }
                                                }
                                            }
                                        }

                                        // Trips
                                        if !day.trips.isEmpty {
                                            ForEach(day.trips, id: \.name) { trip in
                                                HStack(spacing: 6) {
                                                    Image(systemName: "airplane.departure")
                                                        .font(.caption2)
                                                        .foregroundStyle(JohoColors.orange)
                                                    Text("\(trip.name) → \(trip.destination)")
                                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                                        .foregroundStyle(JohoColors.orange)
                                                }
                                            }
                                        }
                                    }
                                    .padding(JohoDimensions.spacingSM)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(JohoColors.black.opacity(0.03))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(JohoColors.black.opacity(0.1), lineWidth: 1)
                                    )
                                }

                                if preview.dailyEntries.count > 3 {
                                    Text("+ \(preview.dailyEntries.count - 3) more days in full report")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .italic()
                                }
                            }
                        }
                    } else {
                        Text("Select options to preview report content")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                } header: {
                    Text("Preview")
                } footer: {
                    Text("Preview updates as you change options")
                        .font(.caption)
                }

                // Export Action
                Section {
                    Button {
                        Task {
                            await performExport()
                        }
                    } label: {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, JohoDimensions.spacingSM)
                            }
                            Label(isExporting ? "Generating PDF..." : "Export as PDF", systemImage: "doc.fill")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isExporting || !isValidSelection)
                } footer: {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
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
                if let url = exportedURL {
                    ShareSheet(url: url)
                }
            }
            .task {
                // Delay initial preview load slightly to ensure view is fully presented
                try? await Task.sleep(for: .milliseconds(100))
                await loadPreview()
            }
            .onChange(of: exportMode) { _, _ in
                debouncedPreviewUpdate()
            }
            .onChange(of: selectedDate) { _, _ in
                debouncedPreviewUpdate()
            }
            .onChange(of: selectedWeek) { _, _ in
                debouncedPreviewUpdate()
            }
            .onChange(of: selectedMonth) { _, _ in
                debouncedPreviewUpdate()
            }
            .onChange(of: selectedYear) { _, _ in
                debouncedPreviewUpdate()
            }
            .onChange(of: rangeStart) { _, _ in
                debouncedPreviewUpdate()
            }
            .onChange(of: rangeEnd) { _, _ in
                debouncedPreviewUpdate()
            }
            .onChange(of: includeNotes) { _, _ in
                debouncedPreviewUpdate()
            }
            .onChange(of: includeExpenses) { _, _ in
                debouncedPreviewUpdate()
            }
            .onChange(of: includeHolidays) { _, _ in
                debouncedPreviewUpdate()
            }
        }
    }

    // MARK: - Computed Properties

    private var exportScopeDescription: String {
        let scope = buildExportScope()
        return scope.title
    }

    private var isValidSelection: Bool {
        switch exportMode {
        case .day, .week, .month, .year:
            return true
        case .range:
            return rangeStart <= rangeEnd
        }
    }

    // MARK: - Helper Methods

    private func yearRange() -> [Int] {
        let current = Calendar.iso8601.component(.year, from: Date())
        return Array((current - 10)...(current + 5))
    }

    private func buildExportScope() -> PDFExportScope {
        switch exportMode {
        case .day:
            return .day(selectedDate)
        case .week:
            return .week(weekNumber: selectedWeek, year: selectedYear)
        case .month:
            return .month(month: selectedMonth, year: selectedYear)
        case .year:
            return .year(selectedYear)
        case .range:
            return .range(start: rangeStart, end: rangeEnd)
        }
    }

    private func performExport() async {
        isExporting = true
        errorMessage = nil

        defer {
            isExporting = false
        }

        do {
            let scope = buildExportScope()
            let options = PDFExportOptions(
                includeWeather: includeWeather,
                includeStatistics: includeStatistics,
                includeNotes: includeNotes,
                includeHolidays: includeHolidays,
                includeExpenses: includeExpenses
            )

            let url = try await PDFExportService.shared.generatePDF(
                scope: scope,
                context: modelContext,
                options: options
            )

            exportedURL = url
            showShareSheet = true

        } catch {
            errorMessage = error.localizedDescription
            Log.w("PDF export failed: \(error)")
        }
    }

    // MARK: - Preview Logic

    private func debouncedPreviewUpdate() {
        // Cancel previous task
        previewTask?.cancel()

        // Create new task with delay
        previewTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await loadPreview()
        }
    }

    private func loadPreview() async {
        guard isValidSelection else {
            previewData = nil
            return
        }

        isLoadingPreview = true

        defer {
            isLoadingPreview = false
        }

        do {
            // Ensure we're on main actor
            await MainActor.run { }

            let scope = buildExportScope()
            let dateRange = getDateRange(for: scope)
            let calendar = Calendar.iso8601

            // Fetch all data
            let allNotes = includeNotes ? try modelContext.fetch(FetchDescriptor<DailyNote>(sortBy: [SortDescriptor(\DailyNote.date)])) : []
            let allExpenses = includeExpenses ? try modelContext.fetch(FetchDescriptor<ExpenseItem>(sortBy: [SortDescriptor(\ExpenseItem.date)])) : []
            let allTrips = try modelContext.fetch(FetchDescriptor<TravelTrip>(sortBy: [SortDescriptor(\TravelTrip.startDate)]))

            // Build daily entries
            var dailyEntries: [DailyEntry] = []
            var currentDate = dateRange.start
            var totalExpenses: Double = 0

            while currentDate <= dateRange.end {
                let dayStart = calendar.startOfDay(for: currentDate)

                // Holidays for this day
                var holidays: [String] = []
                if includeHolidays {
                    if let dayHolidays = HolidayManager.shared.holidayCache[dayStart] {
                        holidays = dayHolidays.map { $0.displayTitle }
                    }
                }

                // Notes for this day
                let dayNotes = allNotes.filter { calendar.startOfDay(for: $0.day) == dayStart }
                    .map { $0.content }

                // Expenses for this day
                let dayExpenses = allExpenses.filter { calendar.startOfDay(for: $0.date) == dayStart }
                let expenseEntries = dayExpenses.map { expense in
                    totalExpenses += expense.amount
                    return ExpenseEntry(
                        description: expense.itemDescription,
                        amount: expense.amount,
                        currency: expense.currency
                    )
                }

                // Trips active on this day
                let dayTrips = allTrips.filter { trip in
                    let tripStart = calendar.startOfDay(for: trip.startDate)
                    let tripEnd = calendar.startOfDay(for: trip.endDate)
                    return dayStart >= tripStart && dayStart <= tripEnd
                }.map { trip in
                    TripEntry(name: trip.tripName, destination: trip.destination)
                }

                // Only add days that have content
                if !holidays.isEmpty || !dayNotes.isEmpty || !expenseEntries.isEmpty || !dayTrips.isEmpty {
                    let entry = DailyEntry(
                        date: currentDate,
                        holidays: holidays,
                        notes: dayNotes,
                        expenses: expenseEntries,
                        trips: dayTrips
                    )
                    dailyEntries.append(entry)
                }

                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? dateRange.end
            }

            // Generate report title
            let reportTitle: String
            switch scope {
            case .day(let date):
                reportTitle = "Daily Report - \(date.formatted(date: .long, time: .omitted))"
            case .week(let weekNumber, let year):
                reportTitle = "Week \(weekNumber), \(year)"
            case .month(let month, let year):
                let monthName = DateFormatter().monthSymbols[month - 1]
                reportTitle = "\(monthName) \(year) Report"
            case .year(let year):
                reportTitle = "\(year) Annual Report"
            case .range(let start, let end):
                reportTitle = "\(start.formatted(date: .abbreviated, time: .omitted)) - \(end.formatted(date: .abbreviated, time: .omitted))"
            }

            let tripCount = Set(allTrips.filter { trip in
                let tripStart = calendar.startOfDay(for: trip.startDate)
                let tripEnd = calendar.startOfDay(for: trip.endDate)
                return tripStart <= dateRange.end && tripEnd >= dateRange.start
            }).count

            let preview = ReportPreviewData(
                reportTitle: reportTitle,
                tripCount: tripCount,
                totalExpenses: totalExpenses,
                currency: "SEK",
                dailyEntries: dailyEntries
            )

            previewData = preview

        } catch {
            Log.w("Preview fetch failed: \(error)")
            previewData = nil
        }
    }

    private func getDateRange(for scope: PDFExportScope) -> (start: Date, end: Date) {
        let calendar = Calendar.iso8601

        switch scope {
        case .day(let date):
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            return (start, end)

        case .week(let weekNumber, let year):
            // Find a date in the specified week
            var dateComponents = DateComponents()
            dateComponents.weekOfYear = weekNumber
            dateComponents.yearForWeekOfYear = year
            dateComponents.weekday = 2 // Monday
            if let dateInWeek = calendar.date(from: dateComponents) {
                let weekInfo = WeekCalculator.shared.weekInfo(for: dateInWeek)
                return (weekInfo.startDate, weekInfo.endDate)
            }
            return (Date(), Date())

        case .month(let month, let year):
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            let startOfMonth = calendar.date(from: components) ?? Date()
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? startOfMonth
            return (startOfMonth, endOfMonth)

        case .year(let year):
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1
            let startOfYear = calendar.date(from: startComponents) ?? Date()

            var endComponents = DateComponents()
            endComponents.year = year
            endComponents.month = 12
            endComponents.day = 31
            let endOfYear = calendar.date(from: endComponents) ?? startOfYear
            return (startOfYear, endOfYear)

        case .range(let start, let end):
            return (calendar.startOfDay(for: start), calendar.startOfDay(for: end))
        }
    }
}

// MARK: - Preview Data Models

struct ReportPreviewData {
    let reportTitle: String
    let tripCount: Int
    let totalExpenses: Double
    let currency: String
    let dailyEntries: [DailyEntry]
}

struct DailyEntry {
    let date: Date
    let holidays: [String]
    let notes: [String]
    let expenses: [ExpenseEntry]
    let trips: [TripEntry]
}

struct ExpenseEntry: Hashable {
    let description: String
    let amount: Double
    let currency: String
}

struct TripEntry: Hashable {
    let name: String
    let destination: String
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    PDFExportView()
        .modelContainer(for: [DailyNote.self, HolidayRule.self], inMemory: true)
}
