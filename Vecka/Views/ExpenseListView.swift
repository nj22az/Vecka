//
//  ExpenseListView.swift
//  Vecka
//
//  Comprehensive expense list with authentic Japanese Jōhō Dezain packaging
//  GREEN zone for financial tracking
//

import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseItem.date, order: .reverse) private var allExpenses: [ExpenseItem]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @Query(sort: \TravelTrip.startDate, order: .reverse) private var trips: [TravelTrip]

    // Base Currency
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"
    @State private var isRecalculating = false

    // Filtering
    @State private var selectedFilter: ExpenseFilter = .all
    @State private var selectedCategory: ExpenseCategory?
    @State private var selectedTrip: TravelTrip?
    @State private var selectedDateRange: DateRange = .thisMonth

    // UI State
    @State private var showAddExpense = false
    @State private var showFilterSheet = false
    @State private var selectedExpense: ExpenseItem?
    @State private var groupBy: GroupingOption = .date
    @State private var showExportSheet = false
    @State private var exportContext: PDFExportContext?

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
                                    groupBy = .category
                                } label: {
                                    Label("Category", systemImage: groupBy == .category ? "checkmark" : "")
                                }

                                Button {
                                    groupBy = .trip
                                } label: {
                                    Label("Trip", systemImage: groupBy == .trip ? "checkmark" : "")
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
                            Section("Export") {
                                Button {
                                    let weekInfo = WeekCalculator.shared.weekInfo(for: Date())
                                    exportContext = .expenseReportWeek(weekNumber: weekInfo.weekNumber, year: weekInfo.year, baseCurrency: baseCurrency)
                                    showExportSheet = true
                                } label: {
                                    Label("This Week's Expenses", systemImage: "doc.text")
                                }

                                Button {
                                    let calendar = Calendar.iso8601
                                    let now = Date()
                                    let month = calendar.component(.month, from: now)
                                    let year = calendar.component(.year, from: now)
                                    exportContext = .expenseReportMonth(month: month, year: year, baseCurrency: baseCurrency)
                                    showExportSheet = true
                                } label: {
                                    Label("This Month's Expenses", systemImage: "doc.text.fill")
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
                FilterOptionsSheet(
                    selectedFilter: $selectedFilter,
                    selectedCategory: $selectedCategory,
                    selectedTrip: $selectedTrip,
                    selectedDateRange: $selectedDateRange,
                    categories: categories,
                    trips: trips
                )
            }
            .sheet(isPresented: $showExportSheet) {
                if let context = exportContext {
                    SimplePDFExportView(exportContext: context)
                }
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
        let grouped = Dictionary(grouping: filteredExpenses) { $0.currency }
        return grouped.map { (currency, expenses) in
            let total = expenses.reduce(0.0) { $0 + $1.amount }
            let convertedTotal = expenses.reduce(0.0) { $0 + ($1.convertedAmount ?? $1.amount) }
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
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            expense.category?.name ?? "Other"
        }

        let sorted = grouped.map { (category, expenses) -> (String, Double) in
            let total = expenses.reduce(0.0) { sum, expense in
                sum + (expense.convertedAmount ?? expense.amount)
            }
            return (category, total)
        }.sorted { $0.1 > $1.1 }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        return sorted.prefix(3).map { category, total in
            let formatted = formatter.string(from: NSNumber(value: total)) ?? "0"
            return (category, formatted)
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
                    selectedCategory = nil
                    selectedTrip = nil
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

                if let category = selectedCategory {
                    FilterChip(
                        title: category.name,
                        icon: category.iconName,
                        isSelected: true
                    ) {
                        selectedCategory = nil
                    }
                }

                if let trip = selectedTrip {
                    FilterChip(
                        title: trip.tripName,
                        icon: "airplane",
                        isSelected: true
                    ) {
                        selectedTrip = nil
                    }
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
                    title: expense.itemDescription,
                    subtitle: subtitleText(for: expense),
                    icon: expense.category?.iconName ?? "creditcard.fill",
                    zone: .expenses,
                    badge: formattedAmount(for: expense),
                    showChevron: true
                )
                .onTapGesture {
                    selectedExpense = expense
                }
                .accessibilityLabel("\(expense.itemDescription), \(formattedAmount(for: expense))")
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    private func subtitleText(for expense: ExpenseItem) -> String {
        var components: [String] = []

        if let merchant = expense.merchantName {
            components.append(merchant)
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        components.append(formatter.string(from: expense.date))

        return components.joined(separator: " • ")
    }

    private func formattedAmount(for expense: ExpenseItem) -> String {
        let amount = expense.convertedAmount ?? expense.amount
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

    private var filteredExpenses: [ExpenseItem] {
        var expenses = allExpenses

        // Filter by category
        if let category = selectedCategory {
            expenses = expenses.filter { $0.category?.id == category.id }
        }

        // Filter by trip
        if let trip = selectedTrip {
            expenses = expenses.filter { $0.trip?.id == trip.id }
        }

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

    private var groupedExpenses: [String: [ExpenseItem]] {
        Dictionary(grouping: filteredExpenses) { expense in
            switch groupBy {
            case .date:
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: expense.date)
            case .category:
                return expense.category?.name ?? "Uncategorized"
            case .trip:
                return expense.trip?.tripName ?? "No Trip"
            }
        }
    }

    private var totalAmount: Double {
        filteredExpenses.reduce(0) { total, expense in
            total + (expense.convertedAmount ?? expense.amount)
        }
    }

    private func sectionHeader(for key: String) -> String {
        key
    }
    
    // MARK: - Recalculation
    
    private func recalculateAllExpenses() {
        guard !isRecalculating else { return }
        isRecalculating = true
        
        Task { @MainActor in
            Log.i("Recalculating all expenses for new base currency: \(baseCurrency)")
            for expense in allExpenses {
                 if expense.currency != baseCurrency {
                     let rate = try? await CurrencyService.shared.getRate(
                         from: expense.currency, 
                         to: baseCurrency, 
                         date: expense.date, 
                         context: modelContext
                     )
                     if let rate {
                         expense.exchangeRate = rate
                         expense.convertedAmount = expense.amount * rate
                     }
                 } else {
                     expense.exchangeRate = 1.0
                     expense.convertedAmount = expense.amount
                 }
            }
            try? modelContext.save()
            isRecalculating = false
            Log.i("Recalculation complete")
        }
    }
}

// MARK: - Expense Row (Legacy - keeping for compatibility)

struct ExpenseRow: View {
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"
    let expense: ExpenseItem

    var body: some View {
        JohoListRow(
            title: expense.itemDescription,
            subtitle: subtitleText,
            icon: expense.category?.iconName ?? "creditcard.fill",
            zone: .expenses,
            badge: formattedAmount,
            showChevron: true
        )
    }

    private var subtitleText: String {
        var components: [String] = []

        if let merchant = expense.merchantName {
            components.append(merchant)
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        components.append(formatter.string(from: expense.date))

        return components.joined(separator: " • ")
    }

    private var formattedAmount: String {
        let amount = expense.convertedAmount ?? expense.amount
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
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

// MARK: - Filter Options Sheet

struct FilterOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedFilter: ExpenseFilter
    @Binding var selectedCategory: ExpenseCategory?
    @Binding var selectedTrip: TravelTrip?
    @Binding var selectedDateRange: DateRange

    let categories: [ExpenseCategory]
    let trips: [TravelTrip]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // 情報デザイン: Status bar safe zone - prevents content from scrolling under status bar icons
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

                    // Category Section
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "Category", style: .blackOnWhite, size: .medium)

                        VStack(spacing: JohoDimensions.spacingXS) {
                            Button {
                                selectedCategory = nil
                            } label: {
                                HStack {
                                    Text("All Categories")
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)
                                    Spacer()
                                    if selectedCategory == nil {
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
                                            selectedCategory == nil ? JohoColors.black : JohoColors.black.opacity(0.3),
                                            lineWidth: selectedCategory == nil ? JohoDimensions.borderMedium : JohoDimensions.borderThin
                                        )
                                )
                            }
                            .buttonStyle(.plain)

                            ForEach(categories) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    HStack(spacing: JohoDimensions.spacingSM) {
                                        JohoIconBadge(icon: category.iconName, zone: .expenses, size: 32)
                                        Text(category.name)
                                            .font(JohoFont.body)
                                            .foregroundStyle(JohoColors.black)
                                        Spacer()
                                        if selectedCategory?.id == category.id {
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
                                                selectedCategory?.id == category.id ? JohoColors.black : JohoColors.black.opacity(0.3),
                                                lineWidth: selectedCategory?.id == category.id ? JohoDimensions.borderMedium : JohoDimensions.borderThin
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Trips Section
                    if trips.isNotEmpty {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            JohoPill(text: "Trip", style: .blackOnWhite, size: .medium)

                            VStack(spacing: JohoDimensions.spacingXS) {
                                Button {
                                    selectedTrip = nil
                                } label: {
                                    HStack {
                                        Text("All Trips")
                                            .font(JohoFont.body)
                                            .foregroundStyle(JohoColors.black)
                                        Spacer()
                                        if selectedTrip == nil {
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
                                                selectedTrip == nil ? JohoColors.black : JohoColors.black.opacity(0.3),
                                                lineWidth: selectedTrip == nil ? JohoDimensions.borderMedium : JohoDimensions.borderThin
                                            )
                                    )
                                }
                                .buttonStyle(.plain)

                                ForEach(trips) { trip in
                                    Button {
                                        selectedTrip = trip
                                    } label: {
                                        HStack(spacing: JohoDimensions.spacingSM) {
                                            JohoIconBadge(icon: "airplane", zone: .trips, size: 32)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(trip.tripName)
                                                    .font(JohoFont.body)
                                                    .foregroundStyle(JohoColors.black)
                                                Text(trip.destination)
                                                    .font(JohoFont.bodySmall)
                                                    .foregroundStyle(JohoColors.black.opacity(0.6))
                                            }
                                            Spacer()
                                            if selectedTrip?.id == trip.id {
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
                                                    selectedTrip?.id == trip.id ? JohoColors.black : JohoColors.black.opacity(0.3),
                                                    lineWidth: selectedTrip?.id == trip.id ? JohoDimensions.borderMedium : JohoDimensions.borderThin
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(JohoDimensions.spacingLG)
            }
            .johoBackground()
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                // Inline header with done button (情報デザイン)
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

// MARK: - Expense Detail View

struct ExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"
    @State private var showEditSheet = false
    let expense: ExpenseItem

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // 情報デザイン: Status bar safe zone - prevents content from scrolling under status bar icons
                    Spacer().frame(height: 44)

                    // Amount Card - Hero display
                    JohoCard {
                        VStack(spacing: JohoDimensions.spacingMD) {
                            JohoPill(text: "Amount", style: .blackOnWhite)

                            Text(expense.amount, format: .currency(code: expense.currency))
                                .font(JohoFont.displayLarge)
                                .foregroundStyle(JohoColors.black)

                            if let converted = expense.convertedAmount, expense.currency != baseCurrency {
                                Text("\(converted, format: .currency(code: baseCurrency)) (converted)")
                                    .font(JohoFont.body)
                                    .foregroundStyle(JohoColors.black.opacity(0.7))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Details Section
                    JohoSectionBox(title: "Details", zone: .expenses) {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            JohoMetricRow(label: "Description", value: expense.itemDescription, zone: .expenses)

                            if let merchant = expense.merchantName {
                                JohoMetricRow(label: "Merchant", value: merchant, zone: .expenses)
                            }

                            if let category = expense.category {
                                HStack(spacing: JohoDimensions.spacingSM) {
                                    Text("Category")
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)
                                    Spacer()
                                    HStack(spacing: JohoDimensions.spacingXS) {
                                        JohoIconBadge(icon: category.iconName, zone: .expenses, size: 24)
                                        Text(category.name)
                                            .font(JohoFont.body)
                                            .foregroundStyle(JohoColors.black)
                                    }
                                }
                                .padding(.horizontal, JohoDimensions.spacingMD)
                                .padding(.vertical, JohoDimensions.spacingSM)
                                .background(SectionZone.expenses.background.opacity(0.3))
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            }

                            JohoMetricRow(label: "Date", value: expense.date.formatted(date: .long, time: .omitted), zone: .expenses)

                            if let notes = expense.notes {
                                VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                                    Text("Notes")
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black.opacity(0.7))
                                    Text(notes)
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)
                                }
                                .padding(.horizontal, JohoDimensions.spacingMD)
                                .padding(.vertical, JohoDimensions.spacingSM)
                                .background(SectionZone.expenses.background.opacity(0.3))
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            }
                        }
                    }

                    // Receipt Section
                    if let imageData = expense.receiptImageData,
                       let uiImage = UIImage(data: imageData) {
                        JohoSectionBox(title: "Receipt", zone: .expenses) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
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
    case category
    case trip
}

// MARK: - Preview

#Preview {
    ExpenseListView()
        .modelContainer(for: [ExpenseItem.self, ExpenseCategory.self, TravelTrip.self], inMemory: true)
}
