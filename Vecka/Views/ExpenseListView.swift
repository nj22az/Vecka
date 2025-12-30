//
//  ExpenseListView.swift
//  Vecka
//
//  Comprehensive expense list with filtering and grouping
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

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        // Note: This view is embedded via NavigationLink or presented in sheet with NavigationStack
        // Do NOT add NavigationStack here to avoid nested navigation issues
        VStack(spacing: 0) {
            // Summary Card
            summaryCard

            // Filter Bar
            filterBar

            // Expense List
            expenseList
        }
        .slateBackground()
        .standardNavigation(title: "Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddExpense = true
                    } label: {
                        Label("Add Expense", systemImage: "plus.circle.fill")
                    }
                }

                ToolbarItem(placement: .secondaryAction) {
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
                    } label: {
                        Label("Options", systemImage: "ellipsis.circle")
                    }
                }
            }
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
            .onChange(of: baseCurrency) { _, _ in
                recalculateAllExpenses()
            }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                // Total Expenses
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if isRecalculating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(totalAmount, format: .currency(code: baseCurrency))
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }

                Spacer()


                // Count
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Expenses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(filteredExpenses.count)")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .glassCard(cornerRadius: 12, material: .ultraThinMaterial)
        .padding(.horizontal)
        .padding(.top, Spacing.small)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
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
                        iconColor: category.color,
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
            .padding(.horizontal)
            .padding(.vertical, Spacing.small)
        }
    }

    // MARK: - Expense List

    private var expenseList: some View {
        Group {
            if filteredExpenses.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(groupedExpenses.keys.sorted(by: >), id: \.self) { key in
                        Section {
                            ForEach(groupedExpenses[key] ?? []) { expense in
                                ExpenseRow(expense: expense)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedExpense = expense
                                    }
                            }
                        } header: {
                            Text(sectionHeader(for: key))
                                .foregroundStyle(SlateColors.secondaryText)
                        }
                    }
                }
                .standardListStyle()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Expenses",
            systemImage: "creditcard",
            description: Text("Tap + to add your first expense")
        )
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

// MARK: - Expense Row

struct ExpenseRow: View {
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"
    let expense: ExpenseItem

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            if let category = expense.category {
                Image(systemName: category.iconName)
                    .font(.title3)
                    .foregroundStyle(category.color)
                    .frame(width: 40, height: 40)
                    .background(category.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Image(systemName: "creditcard.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.itemDescription)
                    .font(.body)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    if let merchant = expense.merchantName {
                        Text(merchant)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if expense.receiptImageData != nil {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }

                    if expense.currency != baseCurrency {
                        Text(expense.currency)
                            .font(.caption2)
                            .padding(.horizontal, Spacing.small)
                            .padding(.vertical, Spacing.extraSmall)
                            .background(Color.blue.opacity(0.2), in: Capsule())
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(expense.amount, format: .currency(code: expense.currency))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                if let converted = expense.convertedAmount, expense.currency != baseCurrency {
                    Text(converted, format: .currency(code: baseCurrency))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, Spacing.extraSmall)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String?
    var iconColor: Color = .blue
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(isSelected ? iconColor : .secondary)
                }

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : .primary)

                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.small)
            .background(
                isSelected ? Color.blue : Color.secondary.opacity(0.1),
                in: Capsule()
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
            List {
                Section("Date Range") {
                    ForEach([DateRange.all, .thisWeek, .thisMonth, .thisYear], id: \.self) { range in
                        Button {
                            selectedDateRange = range
                        } label: {
                            HStack {
                                Text(range.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedDateRange == range {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Category") {
                    Button {
                        selectedCategory = nil
                    } label: {
                        HStack {
                            Text("All Categories")
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    ForEach(categories) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            HStack {
                                Image(systemName: category.iconName)
                                    .foregroundStyle(category.color)
                                Text(category.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedCategory?.id == category.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                if !trips.isEmpty {
                    Section("Trip") {
                        Button {
                            selectedTrip = nil
                        } label: {
                            HStack {
                                Text("All Trips")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedTrip == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }

                        ForEach(trips) { trip in
                            Button {
                                selectedTrip = trip
                            } label: {
                                HStack {
                                    Image(systemName: "airplane")
                                        .foregroundStyle(trip.tripType.color)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(trip.tripName)
                                            .foregroundStyle(.primary)
                                        Text(trip.destination)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedTrip?.id == trip.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .standardListStyle()
            .standardNavigation(title: "Filter Options")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
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
                VStack(spacing: 20) {
                    // Amount Card
                    VStack(spacing: 8) {
                        Text(expense.amount, format: .currency(code: expense.currency))
                            .font(.system(size: 48, weight: .bold))

                        if let converted = expense.convertedAmount, expense.currency != baseCurrency {
                            Text("\(converted, format: .currency(code: baseCurrency)) (converted)")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .glassCard(cornerRadius: 16, material: .ultraThinMaterial)

                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Description", value: expense.itemDescription)

                        if let merchant = expense.merchantName {
                            DetailRow(label: "Merchant", value: merchant)
                        }

                        if let category = expense.category {
                            HStack {
                                Text("Category")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Label(category.name, systemImage: category.iconName)
                                    .foregroundStyle(category.color)
                            }
                        }

                        DetailRow(label: "Date", value: expense.date.formatted(date: .long, time: .omitted))

                        if let notes = expense.notes {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes")
                                    .foregroundStyle(.secondary)
                                Text(notes)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding()
                    .glassCard(cornerRadius: 16, material: .ultraThinMaterial)

                    // Receipt
                    if let imageData = expense.receiptImageData,
                       let uiImage = UIImage(data: imageData) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Receipt")
                                .font(.headline)
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding()
                        .glassCard(cornerRadius: 16, material: .ultraThinMaterial)
                    }
                }
                .padding()
            }
            .slateBackground()
            .standardNavigation(title: "Expense Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                ExpenseEntryView(existingExpense: expense)
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
        }
    }
}

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
