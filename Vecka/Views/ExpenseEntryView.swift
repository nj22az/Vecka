//
//  ExpenseEntryView.swift
//  Vecka
//
//  情報デザイン expense entry (accessed from + button)
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Expense Category Groups (情報デザイン: Collapsible sections)

enum ExpenseCategoryGroup: String, CaseIterable, Identifiable {
    case transportation = "Transportation"
    case foodDining = "Food & Dining"
    case accommodation = "Accommodation"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case business = "Business"
    case health = "Health"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .transportation: return "car.fill"
        case .foodDining: return "fork.knife"
        case .accommodation: return "bed.double.fill"
        case .entertainment: return "ticket.fill"
        case .shopping: return "bag.fill"
        case .business: return "briefcase.fill"
        case .health: return "cross.case.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    /// Maps category icon names to groups
    static func group(for category: ExpenseCategory) -> ExpenseCategoryGroup {
        let icon = category.iconName.lowercased()
        let name = category.name.lowercased()

        // Transportation
        if icon.contains("car") || icon.contains("airplane") || icon.contains("bus") ||
           icon.contains("train") || icon.contains("tram") || icon.contains("ferry") ||
           icon.contains("bicycle") || icon.contains("fuelpump") ||
           name.contains("transport") || name.contains("taxi") || name.contains("uber") ||
           name.contains("flight") || name.contains("gas") || name.contains("fuel") {
            return .transportation
        }

        // Food & Dining
        if icon.contains("fork") || icon.contains("cup") || icon.contains("takeoutbag") ||
           icon.contains("wineglass") || icon.contains("mug") ||
           name.contains("food") || name.contains("restaurant") || name.contains("coffee") ||
           name.contains("lunch") || name.contains("dinner") || name.contains("breakfast") ||
           name.contains("meal") || name.contains("grocery") {
            return .foodDining
        }

        // Accommodation
        if icon.contains("bed") || icon.contains("house") || icon.contains("building") ||
           name.contains("hotel") || name.contains("lodging") || name.contains("airbnb") ||
           name.contains("accommodation") || name.contains("stay") {
            return .accommodation
        }

        // Entertainment
        if icon.contains("ticket") || icon.contains("film") || icon.contains("music") ||
           icon.contains("gamecontroller") || icon.contains("theatermasks") ||
           name.contains("entertainment") || name.contains("movie") || name.contains("concert") ||
           name.contains("show") || name.contains("event") {
            return .entertainment
        }

        // Shopping
        if icon.contains("bag") || icon.contains("cart") || icon.contains("gift") ||
           icon.contains("tag") ||
           name.contains("shopping") || name.contains("store") || name.contains("retail") ||
           name.contains("clothes") || name.contains("electronics") {
            return .shopping
        }

        // Business
        if icon.contains("briefcase") || icon.contains("doc") || icon.contains("printer") ||
           icon.contains("phone") || icon.contains("envelope") ||
           name.contains("business") || name.contains("office") || name.contains("meeting") ||
           name.contains("conference") || name.contains("subscription") {
            return .business
        }

        // Health
        if icon.contains("cross") || icon.contains("heart") || icon.contains("pill") ||
           icon.contains("staroflife") ||
           name.contains("health") || name.contains("medical") || name.contains("pharmacy") ||
           name.contains("doctor") || name.contains("hospital") {
            return .health
        }

        return .other
    }
}

// MARK: - 情報デザイン Expense Editor Sheet (Standalone - like Event editor)

/// Standalone expense editor sheet matching the Event editor pattern
/// Used when creating expenses from the + menu
struct JohoExpenseEditorSheet: View {
    let initialDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode

    @State private var amount: String = ""
    @State private var currency: String = "SEK"
    @State private var description: String = ""
    @State private var merchant: String = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var showingIconPicker = false
    @State private var selectedSymbol: String = "dollarsign.circle.fill"

    // Collapsible category groups
    @State private var expandedGroups: Set<ExpenseCategoryGroup> = []
    @State private var showingCategoryPicker = false

    // Date selection (情報デザイン: Year, Month, Day)
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int

    // Categories
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    /// Dynamic colors for dark mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Base Currency
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    // 情報デザイン: Expenses ALWAYS use green color scheme
    private var expenseAccentColor: Color { SpecialDayType.expense.accentColor }
    private var expenseLightBackground: Color { SpecialDayType.expense.lightBackground }

    private let calendar = Calendar.current

    private var canSave: Bool {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return false
        }
        return amountValue > 0 && !description.trimmed.isEmpty
    }

    private var selectedDate: Date {
        let components = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
        return calendar.date(from: components) ?? initialDate
    }

    private var yearRange: [Int] {
        let current = calendar.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }

    init(selectedDate: Date = Date()) {
        self.initialDate = selectedDate
        let calendar = Calendar.current
        _selectedYear = State(initialValue: calendar.component(.year, from: selectedDate))
        _selectedMonth = State(initialValue: calendar.component(.month, from: selectedDate))
        _selectedDay = State(initialValue: calendar.component(.day, from: selectedDate))
    }

    var body: some View {
        // 情報デザイン: UNIFIED BENTO PILLBOX - entire editor is one compartmentalized box
        VStack(spacing: 0) {
            Spacer().frame(height: JohoDimensions.spacingLG)

            // UNIFIED BENTO CONTAINER
            VStack(spacing: 0) {
                // ═══════════════════════════════════════════════════════════════
                // HEADER ROW: [<] | [icon] Title/Subtitle | [Save]
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Back button (44pt)
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .johoTouchTarget()
                    }

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Icon + Title/Subtitle
                    HStack(spacing: JohoDimensions.spacingSM) {
                        // Type icon in colored box
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(expenseAccentColor)
                            .frame(width: 36, height: 36)
                            .background(expenseLightBackground)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(colors.border, lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("NEW EXPENSE")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(colors.primary)
                            Text("Set amount & details")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.6))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                    .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // RIGHT: Save button (72pt)
                    Button {
                        saveExpense()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(canSave ? colors.primaryInverted : colors.primary.opacity(0.4))
                            .frame(width: 56, height: 32)
                            .background(canSave ? expenseAccentColor : colors.surface)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(colors.border, lineWidth: 1.5))
                    }
                    .disabled(!canSave)
                    .frame(width: 72)
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 56)
                .background(expenseAccentColor.opacity(0.7))  // 情報デザイン: Darker header like Event editor

                // Thick divider after header
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // DESCRIPTION ROW: [●] | Expense description
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Type indicator dot (40pt)
                    Circle()
                        .fill(expenseAccentColor)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Description field
                    TextField("Expense description", text: $description)
                        .font(JohoFont.body)
                        .foregroundStyle(colors.primary)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 48)
                .background(expenseLightBackground)

                // 情報デザイン: Row divider (solid black)
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // AMOUNT ROW: [$] | Amount | Currency
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Dollar sign icon (40pt)
                    Image(systemName: "dollarsign")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Amount field
                    TextField("0.00", text: $amount)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .keyboardType(.decimalPad)
                        .foregroundStyle(colors.primary)
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, JohoDimensions.spacingMD)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // RIGHT: Currency picker (80pt)
                    Menu {
                        ForEach(CurrencyDefinition.defaultCurrencies) { curr in
                            Button(curr.code) {
                                currency = curr.code
                            }
                        }
                    } label: {
                        Text(currency)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(colors.primary)
                            .frame(width: 80)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(height: 48)
                .background(expenseLightBackground)

                // 情報デザイン: Row divider (solid black)
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // DATE ROW: [📅] | Year | Month | Day (compartmentalized)
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Calendar icon (40pt)
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // YEAR compartment
                    Menu {
                        ForEach(yearRange, id: \.self) { year in
                            Button { selectedYear = year } label: { Text(String(year)) }
                        }
                    } label: {
                        Text(String(selectedYear))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // MONTH compartment
                    Menu {
                        ForEach(1...12, id: \.self) { month in
                            Button { selectedMonth = month } label: { Text(monthName(month)) }
                        }
                    } label: {
                        Text(monthName(selectedMonth))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // DAY compartment
                    Menu {
                        ForEach(1...daysInMonth(selectedMonth, year: selectedYear), id: \.self) { day in
                            Button { selectedDay = day } label: { Text("\(day)") }
                        }
                    } label: {
                        Text("\(selectedDay)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(colors.primary)
                            .frame(width: 44)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(height: 48)
                .background(expenseLightBackground)

                // 情報デザイン: Row divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // CATEGORY ROW: [📁] | Category selector (tappable - opens picker)
                // ═══════════════════════════════════════════════════════════════
                Button {
                    showingCategoryPicker = true
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 0) {
                        // LEFT: Folder icon (40pt)
                        Image(systemName: "folder.fill")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .frame(width: 40)
                            .frame(maxHeight: .infinity)

                        // WALL
                        Rectangle()
                            .fill(colors.border)
                            .frame(width: 1.5)
                            .frame(maxHeight: .infinity)

                        // CENTER: Selected category display
                        HStack(spacing: JohoDimensions.spacingSM) {
                            if let category = selectedCategory {
                                // Show selected category icon + name
                                Image(systemName: category.iconName)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(category.color)
                                    .frame(width: 28, height: 28)
                                    .background(category.color.opacity(0.15))
                                    .clipShape(Circle())

                                Text(category.name.uppercased())
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(colors.primary)
                            } else {
                                // No category selected
                                Image(systemName: "minus")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(0.4))
                                    .frame(width: 28, height: 28)
                                    .background(colors.primary.opacity(0.05))
                                    .clipShape(Circle())

                                Text("SELECT CATEGORY")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(colors.primary.opacity(0.6))
                            }

                            Spacer()

                            // Chevron indicator
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.4))
                        }
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .frame(maxHeight: .infinity)
                    }
                    .frame(height: 48)
                    .background(expenseLightBackground)
                }
                .buttonStyle(.plain)

                // 情報デザイン: Row divider (solid black)
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // MERCHANT ROW (OPTIONAL): [🏪] | Store name
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Store icon (40pt)
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.6))
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Merchant field (optional)
                    TextField("Store name (optional)", text: $merchant)
                        .font(JohoFont.caption)
                        .foregroundStyle(colors.primary.opacity(0.6))
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 48)
                .background(expenseLightBackground.opacity(0.5))

                // 情報デザイン: Row divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // ICON PICKER ROW: [icon] | Tap to change icon [>]
                // ═══════════════════════════════════════════════════════════════
                Button {
                    showingIconPicker = true
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 0) {
                        // LEFT: Current icon (40pt)
                        Image(systemName: selectedSymbol)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(expenseAccentColor)
                            .frame(width: 40)
                            .frame(maxHeight: .infinity)

                        // WALL
                        Rectangle()
                            .fill(colors.border)
                            .frame(width: 1.5)
                            .frame(maxHeight: .infinity)

                        // CENTER: Hint text
                        Text("Tap to change icon")
                            .font(JohoFont.caption)
                            .foregroundStyle(colors.primary.opacity(0.6))
                            .padding(.leading, JohoDimensions.spacingMD)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.4))
                            .padding(.trailing, JohoDimensions.spacingMD)
                    }
                    .frame(height: 48)
                    .background(expenseLightBackground)
                }
                .buttonStyle(.plain)
            }
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
            )
            .padding(.horizontal, JohoDimensions.spacingLG)

            Spacer()
        }
        .johoBackground()
        .navigationBarHidden(true)
        .onAppear {
            currency = baseCurrency
        }
        .sheet(isPresented: $showingIconPicker) {
            JohoIconPickerSheet(
                selectedSymbol: $selectedSymbol,
                accentColor: expenseAccentColor,
                lightBackground: expenseLightBackground
            )
        }
        .sheet(isPresented: $showingCategoryPicker) {
            JohoCollapsibleCategoryPicker(
                categories: categories,
                selectedCategory: $selectedCategory,
                expandedGroups: $expandedGroups,
                accentColor: expenseAccentColor,
                lightBackground: expenseLightBackground
            )
        }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let components = DateComponents(year: 2024, month: month, day: 1)
        let tempDate = calendar.date(from: components) ?? Date()
        return formatter.string(from: tempDate)
    }

    private func daysInMonth(_ month: Int, year: Int) -> Int {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let tempDate = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: tempDate) else {
            return 31
        }
        return range.count
    }

    /// Groups categories by their expense category group
    private var groupedCategories: [ExpenseCategoryGroup: [ExpenseCategory]] {
        Dictionary(grouping: categories) { ExpenseCategoryGroup.group(for: $0) }
    }

    private func saveExpense() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else { return }
        let trimmedDesc = description.trimmed
        guard !trimmedDesc.isEmpty else { return }

        let expense = ExpenseItem(
            date: selectedDate,
            amount: amountValue,
            currency: currency,
            merchantName: merchant.isEmpty ? nil : merchant,
            itemDescription: trimmedDesc,
            notes: nil
        )
        expense.category = selectedCategory
        modelContext.insert(expense)

        do {
            try modelContext.save()
            HapticManager.notification(.success)
        } catch {
            Log.w("Failed to save expense: \(error.localizedDescription)")
        }
    }
}

// MARK: - 情報デザイン Collapsible Category Picker Sheet

/// Category picker with collapsible grouped sections
struct JohoCollapsibleCategoryPicker: View {
    let categories: [ExpenseCategory]
    @Binding var selectedCategory: ExpenseCategory?
    @Binding var expandedGroups: Set<ExpenseCategoryGroup>

    let accentColor: Color
    let lightBackground: Color

    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode

    /// Dynamic colors for dark mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    /// Groups categories by their expense category group
    private var groupedCategories: [ExpenseCategoryGroup: [ExpenseCategory]] {
        Dictionary(grouping: categories) { ExpenseCategoryGroup.group(for: $0) }
    }

    /// Ordered groups that have categories
    private var orderedGroups: [ExpenseCategoryGroup] {
        ExpenseCategoryGroup.allCases.filter { groupedCategories[$0] != nil }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ═══════════════════════════════════════════════════════════════
            // HEADER
            // ═══════════════════════════════════════════════════════════════
            HStack {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("CATEGORY")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(colors.surface)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(accentColor)

                    Text("SELECT TYPE")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)
                }

                Spacer()

                // Close button
                Button {
                    dismiss()
                    HapticManager.selection()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 36, height: 36)
                        .background(colors.surface)
                        .clipShape(Squircle(cornerRadius: 8))
                        .overlay(
                            Squircle(cornerRadius: 8)
                                .stroke(colors.border, lineWidth: 3)
                        )
                }
            }
            .padding(JohoDimensions.spacingLG)
            .background(colors.surface)

            // Thick divider
            Rectangle().fill(colors.border).frame(height: 3)

            // ═══════════════════════════════════════════════════════════════
            // CATEGORY LIST
            // ═══════════════════════════════════════════════════════════════
            ScrollView {
                VStack(spacing: 0) {
                    // "None" option
                    noneOption

                    Rectangle().fill(colors.border).frame(height: 1.5)

                    // Grouped sections
                    ForEach(orderedGroups) { group in
                        categoryGroupSection(group)
                    }
                }
            }
        }
        .background(colors.surface)
        .presentationCornerRadius(0)
        .presentationDetents([.medium, .large])
    }

    // MARK: - None Option

    private var noneOption: some View {
        Button {
            selectedCategory = nil
            HapticManager.selection()
            dismiss()
        } label: {
            HStack(spacing: JohoDimensions.spacingMD) {
                // Icon
                Image(systemName: "minus.circle")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .background(colors.primary.opacity(0.05))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(colors.border.opacity(0.3), lineWidth: 1.5)
                    )

                // Label
                Text("NO CATEGORY")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.6))

                Spacer()

                // Selection indicator
                if selectedCategory == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(selectedCategory == nil ? accentColor.opacity(0.1) : colors.surface)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category Group Section

    private func categoryGroupSection(_ group: ExpenseCategoryGroup) -> some View {
        let categoriesInGroup = groupedCategories[group] ?? []
        let isExpanded = expandedGroups.contains(group)

        return VStack(spacing: 0) {
            // Group header (tappable to expand/collapse)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedGroups.remove(group)
                    } else {
                        expandedGroups.insert(group)
                    }
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Group icon
                    Image(systemName: group.icon)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.surface)
                        .frame(width: 28, height: 28)
                        .background(colors.primary)
                        .clipShape(Squircle(cornerRadius: 6))

                    // Group name
                    Text(group.rawValue.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(colors.surface)

                    // Count badge
                    Text("(\(categoriesInGroup.count))")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(colors.surface.opacity(0.7))

                    Spacer()

                    // Chevron indicator
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.surface.opacity(0.7))
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .background(colors.primary)
            }
            .buttonStyle(.plain)

            // Categories (only shown when expanded)
            if isExpanded {
                ForEach(categoriesInGroup) { category in
                    categoryRow(category)
                }
            }

            // Bottom divider
            Rectangle().fill(colors.border).frame(height: 1.5)
        }
    }

    // MARK: - Category Row

    private func categoryRow(_ category: ExpenseCategory) -> some View {
        let isSelected = selectedCategory?.id == category.id

        return Button {
            selectedCategory = category
            HapticManager.selection()
            dismiss()
        } label: {
            HStack(spacing: JohoDimensions.spacingMD) {
                // Category icon
                Image(systemName: category.iconName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? colors.surface : category.color)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? category.color : category.color.opacity(0.15))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(category.color, lineWidth: isSelected ? 2.5 : 1.5)
                    )

                // Category name
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name.uppercased())
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)

                    // Show expense count if any
                    if let expenses = category.expenses, !expenses.isEmpty {
                        Text("\(expenses.count) expense\(expenses.count == 1 ? "" : "s")")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(category.color)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(isSelected ? category.color.opacity(0.1) : colors.surface)
        }
        .buttonStyle(.plain)
    }
}

// Legacy ExpenseEntryView for backwards compatibility with full features
struct ExpenseEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let initialDate: Date
    let trip: TravelTrip?

    // Form fields
    @State private var amount = ""
    @State private var currency = "SEK"
    @State private var merchant = ""
    @State private var description = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var selectedDate: Date
    @State private var notes = ""

    // Date components (情報デザイン)
    @State private var selectedDay: Int
    @State private var selectedMonth: Int
    @State private var selectedYear: Int

    // Receipt
    @State private var receiptImage: UIImage?
    @State private var showImagePicker = false

    // Template
    @State private var showTemplatePicker = false

    // Categories
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    // Validation
    @State private var showError = false
    @State private var errorMessage = ""

    // Focus management
    @FocusState private var focusedField: ExpenseField?
    @State private var exchangeRateString: String = "1.0"

    // Base Currency
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    // Edit Mode
    let existingExpense: ExpenseItem?

    enum ExpenseField {
        case amount, merchant, description, notes
    }

    init(date: Date = Date(), trip: TravelTrip? = nil, existingExpense: ExpenseItem? = nil) {
        self.initialDate = date
        self.trip = trip
        self.existingExpense = existingExpense

        let calendar = Calendar.iso8601
        let dateToUse = existingExpense?.date ?? date

        if let expense = existingExpense {
            _amount = State(initialValue: String(format: "%.2f", expense.amount))
            _currency = State(initialValue: expense.currency)
            _merchant = State(initialValue: expense.merchantName ?? "")
            _description = State(initialValue: expense.itemDescription)
            _selectedCategory = State(initialValue: expense.category)
            _selectedDate = State(initialValue: expense.date)
            _notes = State(initialValue: expense.notes ?? "")

            let rate = expense.exchangeRate ?? 1.0
            _exchangeRateString = State(initialValue: String(format: "%.4f", rate))

            if let data = expense.receiptImageData {
                _receiptImage = State(initialValue: UIImage(data: data))
            }
        } else {
            _selectedDate = State(initialValue: date)
            _currency = State(initialValue: "SEK")
        }

        // Initialize date components
        _selectedDay = State(initialValue: calendar.component(.day, from: dateToUse))
        _selectedMonth = State(initialValue: calendar.component(.month, from: dateToUse))
        _selectedYear = State(initialValue: calendar.component(.year, from: dateToUse))
    }

    var body: some View {
        // Redirect to new simplified sheet
        JohoExpenseEditorSheet(selectedDate: initialDate)
    }
}

// MARK: - 情報デザイン Template Picker

struct JohoTemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let categories: [ExpenseCategory]
    let onSelect: (ExpenseTemplate) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TEMPLATE")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(JohoColors.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(JohoColors.cyan)

                    Text("SELECT PRESET")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(JohoColors.black)
                }

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 36, height: 36)
                        .background(JohoColors.white)
                        .clipShape(Squircle(cornerRadius: 8))
                        .overlay(
                            Squircle(cornerRadius: 8)
                                .stroke(JohoColors.black, lineWidth: 3)
                        )
                }
            }
            .padding(JohoDimensions.spacingLG)
            .background(JohoColors.white)

            Rectangle().fill(JohoColors.black).frame(height: 3)

            // Template list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(categories) { category in
                        if let templates = category.templates, !templates.isEmpty {
                            // Category header
                            HStack(spacing: 8) {
                                Image(systemName: category.iconName)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(category.color)
                                Text(category.name.uppercased())
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundStyle(JohoColors.white)
                                Spacer()
                            }
                            .padding(.horizontal, JohoDimensions.spacingMD)
                            .padding(.vertical, 8)
                            .background(JohoColors.black)

                            // Templates
                            ForEach(templates) { template in
                                Button {
                                    onSelect(template)
                                    dismiss()
                                } label: {
                                    JohoTemplateRow(template: template, category: category)
                                }
                                .buttonStyle(.plain)

                                Rectangle().fill(JohoColors.black.opacity(0.1)).frame(height: 1)
                            }
                        }
                    }
                }
            }
        }
        .background(JohoColors.white)
        .presentationCornerRadius(0)
        .presentationDetents([.medium, .large])
    }
}

private struct JohoTemplateRow: View {
    let template: ExpenseTemplate
    let category: ExpenseCategory

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.iconName)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(category.color)
                .frame(width: 32, height: 32)
                .background(category.color.opacity(0.15))
                .clipShape(Squircle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(JohoColors.black)

                if let amount = template.defaultAmount {
                    Text("\(String(format: "%.0f", amount)) \(template.defaultCurrency)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, 12)
        .background(JohoColors.white)
    }
}

// MARK: - Template Picker

struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let categories: [ExpenseCategory]
    let onSelect: (ExpenseTemplate) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    if let templates = category.templates, !templates.isEmpty {
                        Section {
                            ForEach(templates) { template in
                                Button {
                                    onSelect(template)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: category.iconName)
                                            .foregroundStyle(category.color)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(template.name)
                                                .foregroundStyle(.primary)

                                            if let amount = template.defaultAmount {
                                                Text("\(amount, specifier: "%.0f") \(template.defaultCurrency)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        } header: {
                            Text(category.name)
                        }
                    }
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ExpenseEntryView()
        .modelContainer(for: [ExpenseItem.self, ExpenseCategory.self], inMemory: true)
}
