//
//  ExpenseListView.swift
//  Vecka
//
//  Comprehensive expense list with authentic Japanese Jōhō Dezain packaging
//  GREEN zone for financial tracking
//  Migrated to use unified Memo model
//

import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext

    // Query all memos, filter to expenses in computed property
    @Query(sort: \Memo.date, order: .reverse) private var allMemos: [Memo]

    // Filter to expense type only
    private var allExpenses: [Memo] {
        allMemos.filter { $0.type == .expense }
    }

    // Base Currency
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"
    @State private var isRecalculating = false

    // Filtering (simplified - Memo doesn't have categories)
    @State private var selectedFilter: ExpenseFilter = .all
    @State private var selectedDateRange: DateRange = .thisMonth

    // UI State
    @State private var showAddExpense = false
    @State private var showFilterSheet = false
    @State private var selectedExpense: Memo?
    @State private var groupBy: GroupingOption = .date
    @State private var showExportSheet = false
    @State private var exportContext: PDFExportContext?
    @State private var csvExportURL: URL?
    @State private var showCSVShareSheet = false
    @State private var csvExportError: String?

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        // Note: This view is embedded via NavigationLink or presented in sheet with NavigationStack
        // Do NOT add NavigationStack here to avoid nested navigation issues
        ScrollView {
            VStack(spacing: JohoDimensions.spacingMD) {
                // Page Header with inline actions (情報デザイン)
                HStack(alignment: .top) {
                    JohoPageHeader(
                        title: "Expenses",
                        badge: selectedDateRange.rawValue.uppercased()
                    )

                    Spacer()

                    // Inline action buttons
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Button {
                            showAddExpense = true
                        } label: {
                            JohoActionButton(icon: "plus")
                        }

                        Menu {
                            Section("Group By") {
                                Button {
                                    groupBy = .date
                                } label: {
                                    Label("Date", systemImage: groupBy == .date ? "checkmark" : "")
                                }

                                Button {
                                    groupBy = .merchant
                                } label: {
                                    Label("Merchant", systemImage: groupBy == .merchant ? "checkmark" : "")
                                }
                            }

                            Section {
                                Button {
                                    showFilterSheet = true
                                } label: {
                                    Label("Filter Options", systemImage: "line.3.horizontal.decrease.circle")
                                }
                            }

                            // PDF Export (情報デザイン: Direct access to reports)
                            Section("Export PDF") {
                                Button {
                                    let weekInfo = WeekCalculator.shared.weekInfo(for: Date())
                                    exportContext = .expenseReportWeek(weekNumber: weekInfo.weekNumber, year: weekInfo.year, baseCurrency: baseCurrency)
                                    showExportSheet = true
                                } label: {
                                    Label("This Week (PDF)", systemImage: "doc.text")
                                }

                                Button {
                                    let calendar = Calendar.iso8601
                                    let now = Date()
                                    let month = calendar.component(.month, from: now)
                                    let year = calendar.component(.year, from: now)
                                    exportContext = .expenseReportMonth(month: month, year: year, baseCurrency: baseCurrency)
                                    showExportSheet = true
                                } label: {
                                    Label("This Month (PDF)", systemImage: "doc.text.fill")
                                }
                            }

                            // CSV Export (情報デザイン: Spreadsheet-friendly)
                            Section("Export CSV") {
                                Button {
                                    exportCSVThisWeek()
                                } label: {
                                    Label("This Week (CSV)", systemImage: "tablecells")
                                }

                                Button {
                                    exportCSVThisMonth()
                                } label: {
                                    Label("This Month (CSV)", systemImage: "tablecells.fill")
                                }

                                Button {
                                    exportCSVFiltered()
                                } label: {
                                    Label("Current View (CSV)", systemImage: "square.and.arrow.up")
                                }
                            }
                        } label: {
                            JohoActionButton(icon: "ellipsis")
                        }
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)

                // Summary Card
                summaryCard

                // Category Breakdown Grid
                categoryBreakdownGrid

                // Filter Bar
                filterBar

                // Recent Expenses
                recentExpensesSection
            }
        }
        .johoBackground()
        .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddExpense) {
                ExpenseEntryView()
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
            }
            .sheet(isPresented: $showFilterSheet) {
                SimplifiedFilterSheet(
                    selectedFilter: $selectedFilter,
                    selectedDateRange: $selectedDateRange
                )
            }
            .sheet(isPresented: $showExportSheet) {
                if let context = exportContext {
                    SimplePDFExportView(exportContext: context)
                }
            }
            .sheet(isPresented: $showCSVShareSheet) {
                if let url = csvExportURL {
                    ShareSheet(url: url)
                }
            }
            .alert("Export Error", isPresented: Binding(
                get: { csvExportError != nil },
                set: { if !$0 { csvExportError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(csvExportError ?? "Unknown error")
            }
            .onChange(of: baseCurrency) { _, _ in
                recalculateAllExpenses()
            }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 0) {
            // Main total card
            JohoCard {
                VStack(spacing: JohoDimensions.spacingSM) {
                    JohoPill(text: "Total", style: .blackOnWhite)

                    Text(formattedTotal)
                        .font(JohoFont.displayLarge)
                        .foregroundStyle(JohoColors.black)

                    HStack(spacing: JohoDimensions.spacingXS) {
                        Text(baseCurrency)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black.opacity(0.7))

                        Text("•")
                            .foregroundStyle(JohoColors.black.opacity(0.5))

                        Text("\(filteredExpenses.count) transactions")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(JohoColors.black.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, JohoDimensions.spacingLG)

            // Multi-currency breakdown (情報デザイン: Show original currencies)
            if currencyBreakdown.isNotEmpty && currencyBreakdown.count > 1 {
                multiCurrencyBreakdownSection
            }
        }
    }

    // MARK: - Multi-Currency Breakdown

    /// Breakdown of expenses by original currency
    private var currencyBreakdown: [(currency: String, total: Double, convertedTotal: Double, count: Int)] {
        let grouped = Dictionary(grouping: filteredExpenses) { $0.currency ?? "SEK" }
        return grouped.map { (currency, expenses) in
            let total = expenses.reduce(0.0) { $0 + ($1.amount ?? 0) }
            // Memo doesn't have convertedAmount, use original amount
            let convertedTotal = total
            return (currency, total, convertedTotal, expenses.count)
        }.sorted { $0.convertedTotal > $1.convertedTotal }
    }

    private var multiCurrencyBreakdownSection: some View {
        VStack(spacing: 0) {
            // Section header (情報デザイン: Clear hierarchy)
            HStack {
                JohoPill(text: "BY CURRENCY", style: .blackOnWhite, size: .small)
                Spacer()
                Text("\(currencyBreakdown.count) currencies")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.top, JohoDimensions.spacingSM)
            .padding(.bottom, JohoDimensions.spacingSM)

            // Currency rows
            VStack(spacing: 0) {
                ForEach(Array(currencyBreakdown.enumerated()), id: \.element.currency) { index, item in
                    currencyBreakdownRow(item: item)

                    if index < currencyBreakdown.count - 1 {
                        Rectangle()
                            .fill(JohoColors.black.opacity(0.1))
                            .frame(height: 1)
                            .padding(.horizontal, JohoDimensions.spacingMD)
                    }
                }
            }
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
            )
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.top, JohoDimensions.spacingSM)
    }

    private func currencyBreakdownRow(item: (currency: String, total: Double, convertedTotal: Double, count: Int)) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Currency badge (情報デザイン: Green expense zone)
            Text(item.currency)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(JohoColors.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(SectionZone.expenses.background)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(JohoColors.black, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                // Original amount
                Text(formatCurrency(item.total, code: item.currency))
                    .font(JohoFont.headline)
                    .foregroundStyle(JohoColors.black)

                // Transaction count
                Text("\(item.count) transaction\(item.count == 1 ? "" : "s")")
                    .font(JohoFont.labelSmall)
                    .foregroundStyle(JohoColors.black.opacity(0.5))
            }

            Spacer()

            // Converted amount (if different currency)
            if item.currency != baseCurrency {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("→ \(formatCurrency(item.convertedTotal, code: baseCurrency))")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))

                    // Show approximate rate
                    if item.total > 0 {
                        let rate = item.convertedTotal / item.total
                        Text("≈ \(String(format: "%.2f", rate)) \(baseCurrency)")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.4))
                    }
                }
            }
        }
        .padding(JohoDimensions.spacingMD)
    }

    private func formatCurrency(_ amount: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(code) \(Int(amount))"
    }

    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "0"
    }

    // MARK: - Category Breakdown Grid

    private var categoryBreakdownGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: JohoDimensions.spacingSM),
                GridItem(.flexible(), spacing: JohoDimensions.spacingSM),
                GridItem(.flexible(), spacing: JohoDimensions.spacingSM)
            ],
            spacing: JohoDimensions.spacingSM
        ) {
            JohoStatBox(
                value: categorySummaries.count > 0 ? categorySummaries[0].amount : "0",
                label: categorySummaries.count > 0 ? categorySummaries[0].name : "—",
                zone: .trips
            )
            JohoStatBox(
                value: categorySummaries.count > 1 ? categorySummaries[1].amount : "0",
                label: categorySummaries.count > 1 ? categorySummaries[1].name : "—",
                zone: .contacts
            )
            JohoStatBox(
                value: categorySummaries.count > 2 ? categorySummaries[2].amount : "0",
                label: categorySummaries.count > 2 ? categorySummaries[2].name : "—",
                zone: .calendar
            )
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    private var categorySummaries: [(name: String, amount: String)] {
        // Memo doesn't have categories, show expense breakdown by month
        let calendar = Calendar.iso8601
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            return calendar.date(from: components).map { monthFormatter.string(from: $0) } ?? "Other"
        }

        let sorted = grouped.map { (month, expenses) -> (String, Double) in
            let total = expenses.reduce(0.0) { sum, expense in
                sum + (expense.amount ?? 0)
            }
            return (month, total)
        }.sorted { $0.1 > $1.1 }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        return sorted.prefix(3).map { month, total in
            let formatted = formatter.string(from: NSNumber(value: total)) ?? "0"
            return (month, formatted)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: JohoDimensions.spacingSM) {
                FilterChip(
                    title: "All",
                    isSelected: selectedFilter == .all
                ) {
                    selectedFilter = .all
                }

                FilterChip(
                    title: "This Week",
                    isSelected: selectedDateRange == .thisWeek
                ) {
                    selectedDateRange = .thisWeek
                }

                FilterChip(
                    title: "This Month",
                    isSelected: selectedDateRange == .thisMonth
                ) {
                    selectedDateRange = .thisMonth
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
    }

    // MARK: - Recent Expenses Section

    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
            JohoPill(text: "Recent", style: .blackOnWhite, size: .large)
                .padding(.horizontal, JohoDimensions.spacingLG)

            if filteredExpenses.isEmpty {
                emptyState
            } else {
                expensesList
            }
        }
    }

    // MARK: - Expenses List

    private var expensesList: some View {
        LazyVStack(spacing: JohoDimensions.spacingSM) {
            ForEach(filteredExpenses.prefix(20)) { expense in
                JohoListRow(
                    title: expense.text,
                    subtitle: subtitleText(for: expense),
                    icon: "creditcard.fill",  // Category removed in Memo
                    zone: .expenses,
                    badge: formattedAmount(for: expense),
                    showChevron: true
                )
                .onTapGesture {
                    selectedExpense = expense
                }
                .accessibilityLabel("\(expense.text), \(formattedAmount(for: expense))")
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    private func subtitleText(for expense: Memo) -> String {
        var components: [String] = []

        if let merchant = expense.place {
            components.append(merchant)
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        components.append(formatter.string(from: expense.date))

        return components.joined(separator: " • ")
    }

    private func formattedAmount(for expense: Memo) -> String {
        let amount = expense.amount ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    private var emptyState: some View {
        JohoEmptyState(
            title: "No Expenses",
            message: "Tap + to add your first expense",
            icon: "creditcard.fill",
            zone: .expenses
        )
        .padding(JohoDimensions.spacingXL)
    }

    // MARK: - Computed Properties

    private var filteredExpenses: [Memo] {
        var expenses = allExpenses

        // Note: Category/Trip filters disabled for Memo-based expenses
        // They use legacy models that will be removed in Phase 8

        // Filter by date range
        let calendar = Calendar.iso8601
        let now = Date()

        switch selectedDateRange {
        case .all:
            break
        case .thisWeek:
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            expenses = expenses.filter { $0.date >= weekStart }
        case .thisMonth:
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            expenses = expenses.filter { $0.date >= monthStart }
        case .thisYear:
            let yearStart = calendar.dateInterval(of: .year, for: now)?.start ?? now
            expenses = expenses.filter { $0.date >= yearStart }
        }

        return expenses
    }

    private var groupedExpenses: [String: [Memo]] {
        Dictionary(grouping: filteredExpenses) { expense in
            switch groupBy {
            case .date:
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: expense.date)
            case .merchant:
                return expense.place ?? "Unknown"  // Group by merchant/place
            }
        }
    }

    private var totalAmount: Double {
        filteredExpenses.reduce(0) { total, expense in
            total + (expense.amount ?? 0)
        }
    }

    private func sectionHeader(for key: String) -> String {
        key
    }
    
    // MARK: - Recalculation

    private func recalculateAllExpenses() {
        // Note: Memo doesn't have exchangeRate/convertedAmount
        // Currency conversion would need to be done differently
        // For now, expenses are stored in original currency only
        Log.i("Currency recalculation skipped - Memo stores original currency only")
    }

    // MARK: - CSV Export Functions

    private func exportCSVThisWeek() {
        let weekInfo = WeekCalculator.shared.weekInfo(for: Date())
        do {
            let url = try CSVExportService.shared.exportMemoExpensesForWeek(
                weekNumber: weekInfo.weekNumber,
                year: weekInfo.year,
                context: modelContext
            )
            csvExportURL = url
            showCSVShareSheet = true
        } catch {
            csvExportError = error.localizedDescription
        }
    }

    private func exportCSVThisMonth() {
        let calendar = Calendar.iso8601
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        do {
            let url = try CSVExportService.shared.exportMemoExpensesForMonth(
                month: month,
                year: year,
                context: modelContext
            )
            csvExportURL = url
            showCSVShareSheet = true
        } catch {
            csvExportError = error.localizedDescription
        }
    }

    private func exportCSVFiltered() {
        do {
            let url = try CSVExportService.shared.exportMemoExpenses(filteredExpenses)
            csvExportURL = url
            showCSVShareSheet = true
        } catch {
            csvExportError = error.localizedDescription
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black)
                }

                Text(title)
                    .font(JohoFont.label)
                    .foregroundStyle(JohoColors.black)

                if isSelected {
                    Image(systemName: "xmark.circle")
                        .font(JohoFont.labelSmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(JohoColors.white, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(JohoColors.black, lineWidth: isSelected ? JohoDimensions.borderMedium : JohoDimensions.borderThin)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Simplified Filter Sheet (Date Range Only)

struct SimplifiedFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedFilter: ExpenseFilter
    @Binding var selectedDateRange: DateRange

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // 情報デザイン: Status bar safe zone
                    Spacer().frame(height: 44)

                    // Date Range Section
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "Date Range", style: .blackOnWhite, size: .medium)

                        VStack(spacing: JohoDimensions.spacingXS) {
                            ForEach([DateRange.all, .thisWeek, .thisMonth, .thisYear], id: \.self) { range in
                                Button {
                                    selectedDateRange = range
                                } label: {
                                    HStack {
                                        Text(range.rawValue)
                                            .font(JohoFont.body)
                                            .foregroundStyle(JohoColors.black)
                                        Spacer()
                                        if selectedDateRange == range {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(JohoFont.body)
                                                .foregroundStyle(JohoColors.black)
                                        }
                                    }
                                    .padding(JohoDimensions.spacingMD)
                                    .background(JohoColors.white)
                                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                                    .overlay(
                                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                            .stroke(
                                                selectedDateRange == range ? JohoColors.black : JohoColors.black.opacity(0.3),
                                                lineWidth: selectedDateRange == range ? JohoDimensions.borderMedium : JohoDimensions.borderThin
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(JohoDimensions.spacingLG)
            }
            .johoBackground()
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                HStack {
                    JohoPageHeader(title: "Filter Options", badge: "FILTER")

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        JohoActionButton(icon: "checkmark")
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)
                .background(JohoColors.background)
            }
        }
    }
}

// MARK: - Expense Detail View (Memo-based)

struct ExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"
    @State private var showEditSheet = false
    let expense: Memo

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // 情報デザイン: Status bar safe zone
                    Spacer().frame(height: 44)

                    // Amount Card - Hero display
                    JohoCard {
                        VStack(spacing: JohoDimensions.spacingMD) {
                            JohoPill(text: "Amount", style: .blackOnWhite)

                            Text(expense.amount ?? 0, format: .currency(code: expense.currency ?? "SEK"))
                                .font(JohoFont.displayLarge)
                                .foregroundStyle(JohoColors.black)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Details Section
                    JohoSectionBox(title: "Details", zone: .expenses) {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            JohoMetricRow(label: "Description", value: expense.text, zone: .expenses)

                            if let merchant = expense.place {
                                JohoMetricRow(label: "Merchant", value: merchant, zone: .expenses)
                            }

                            JohoMetricRow(label: "Date", value: expense.date.formatted(date: .long, time: .omitted), zone: .expenses)
                        }
                    }
                }
                .padding(JohoDimensions.spacingLG)
            }
            .johoBackground()
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                // Inline header with actions (情報デザイン)
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        JohoActionButton(icon: "xmark")
                    }

                    Spacer()

                    Button {
                        showEditSheet = true
                    } label: {
                        JohoActionButton(icon: "pencil")
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)
                .background(JohoColors.background)
            }
            .sheet(isPresented: $showEditSheet) {
                ExpenseEntryView(existingExpense: expense)
            }
        }
    }
}

// DetailRow removed - replaced by JohoMetricRow

// MARK: - Supporting Types

enum ExpenseFilter {
    case all
    case category
    case trip
    case dateRange
}

enum DateRange: String, CaseIterable {
    case all = "All Time"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisYear = "This Year"
}

enum GroupingOption {
    case date
    case merchant  // Group by place/merchant (replaces category)
}

// MARK: - Preview

#Preview {
    ExpenseListView()
        .modelContainer(for: [Memo.self], inMemory: true)
}
