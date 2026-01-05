//
//  UnifiedEntryView.swift
//  Vecka
//
//  情報デザイン: Unified Entry form for Note, Trip, and Expense creation
//  Single purple entry point, type-switchable form, preserves existing models
//

import SwiftUI
import SwiftData

// MARK: - 情報デザイン Unified Entry Sheet

/// Unified entry creation sheet with type selector
/// Creates DailyNote, TravelTrip, or ExpenseItem based on selected type
struct JohoUnifiedEntrySheet: View {
    let initialDate: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Entry type selection
    @State private var selectedType: EntryType = .note

    // ═══════════════════════════════════════════════════════════════
    // NOTE FIELDS
    // ═══════════════════════════════════════════════════════════════
    @State private var noteContent: String = ""
    @State private var noteSymbol: String = "note.text"

    // ═══════════════════════════════════════════════════════════════
    // TRIP FIELDS
    // ═══════════════════════════════════════════════════════════════
    @State private var tripName: String = ""
    @State private var tripDestination: String = ""
    @State private var tripStartYear: Int
    @State private var tripStartMonth: Int
    @State private var tripStartDay: Int
    @State private var tripEndYear: Int
    @State private var tripEndMonth: Int
    @State private var tripEndDay: Int
    @State private var tripType: TripType = .personal

    // ═══════════════════════════════════════════════════════════════
    // EXPENSE FIELDS
    // ═══════════════════════════════════════════════════════════════
    @State private var expenseAmount: String = ""
    @State private var expenseCurrency: String = "SEK"
    @State private var expenseDescription: String = ""
    @State private var expenseMerchant: String = ""
    @State private var selectedCategory: ExpenseCategory?

    // ═══════════════════════════════════════════════════════════════
    // SHARED DATE FIELDS
    // ═══════════════════════════════════════════════════════════════
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int

    // Icon picker
    @State private var showingIconPicker = false

    // Collapsible category picker
    @State private var showingCategoryPicker = false
    @State private var expandedGroups: Set<ExpenseCategoryGroup> = []

    // Categories
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    // Dynamic colors for dark mode
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Base Currency
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    private let calendar = Calendar.current

    // ═══════════════════════════════════════════════════════════════
    // COMPUTED PROPERTIES
    // ═══════════════════════════════════════════════════════════════

    private var canSave: Bool {
        switch selectedType {
        case .note:
            return !noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .trip:
            return !tripDestination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .expense:
            guard let amount = Double(expenseAmount.replacingOccurrences(of: ",", with: ".")) else { return false }
            return amount > 0 && !expenseDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var selectedDate: Date {
        let components = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
        return calendar.date(from: components) ?? initialDate
    }

    private var tripStartDate: Date {
        let components = DateComponents(year: tripStartYear, month: tripStartMonth, day: tripStartDay)
        return calendar.date(from: components) ?? initialDate
    }

    private var tripEndDate: Date {
        let components = DateComponents(year: tripEndYear, month: tripEndMonth, day: tripEndDay)
        return calendar.date(from: components) ?? initialDate
    }

    private var yearRange: [Int] {
        let current = calendar.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }

    // ═══════════════════════════════════════════════════════════════
    // INIT
    // ═══════════════════════════════════════════════════════════════

    init(selectedDate: Date = Date()) {
        self.initialDate = selectedDate
        let cal = Calendar.current
        let year = cal.component(.year, from: selectedDate)
        let month = cal.component(.month, from: selectedDate)
        let day = cal.component(.day, from: selectedDate)

        _selectedYear = State(initialValue: year)
        _selectedMonth = State(initialValue: month)
        _selectedDay = State(initialValue: day)

        // Trip defaults: same start, +7 days for end
        _tripStartYear = State(initialValue: year)
        _tripStartMonth = State(initialValue: month)
        _tripStartDay = State(initialValue: day)

        if let endDate = cal.date(byAdding: .day, value: 7, to: selectedDate) {
            _tripEndYear = State(initialValue: cal.component(.year, from: endDate))
            _tripEndMonth = State(initialValue: cal.component(.month, from: endDate))
            _tripEndDay = State(initialValue: cal.component(.day, from: endDate))
        } else {
            _tripEndYear = State(initialValue: year)
            _tripEndMonth = State(initialValue: month)
            _tripEndDay = State(initialValue: day)
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // BODY
    // ═══════════════════════════════════════════════════════════════

    var body: some View {
        // 情報デザイン: UNIFIED BENTO PILLBOX
        VStack(spacing: 0) {
            Spacer().frame(height: JohoDimensions.spacingLG)

            // UNIFIED BENTO CONTAINER
            VStack(spacing: 0) {
                headerRow

                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                typeSelector

                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // Dynamic content based on type
                dynamicFields
            }
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
            )
            .padding(.horizontal, JohoDimensions.spacingLG)

            Spacer()
        }
        .johoBackground()
        .navigationBarHidden(true)
        .onAppear {
            expenseCurrency = baseCurrency
        }
        .sheet(isPresented: $showingIconPicker) {
            JohoIconPickerSheet(
                selectedSymbol: $noteSymbol,
                accentColor: selectedType.color,
                lightBackground: selectedType.lightBackground
            )
        }
        .sheet(isPresented: $showingCategoryPicker) {
            JohoCollapsibleCategoryPicker(
                categories: categories,
                selectedCategory: $selectedCategory,
                expandedGroups: $expandedGroups,
                accentColor: selectedType.color,
                lightBackground: selectedType.lightBackground
            )
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // HEADER ROW
    // ═══════════════════════════════════════════════════════════════

    private var headerRow: some View {
        HStack(spacing: 0) {
            // LEFT: Close button (マルバツ: ×)
            Button { dismiss() } label: {
                Text("×")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 44, height: 44)
            }

            // WALL
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // CENTER: Purple Entry icon + Title
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: EntryType.entryButtonIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(EntryType.entryButtonColor)
                    .frame(width: 36, height: 36)
                    .background(EntryType.entryButtonColor.opacity(0.15))
                    .clipShape(Squircle(cornerRadius: 8))
                    .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1.5))

                VStack(alignment: .leading, spacing: 2) {
                    Text("NEW ENTRY")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                    Text(selectedType.subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Spacer()
            }
            .padding(.horizontal, JohoDimensions.spacingSM)
            .frame(maxHeight: .infinity)

            // WALL
            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            // RIGHT: Save button (マルバツ: ○)
            Button {
                saveEntry()
                dismiss()
            } label: {
                Text("○")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.4))
                    .frame(width: 44, height: 44)
                    .background(canSave ? selectedType.color : JohoColors.white)
                    .clipShape(Squircle(cornerRadius: 8))
                    .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1.5))
            }
            .disabled(!canSave)
            .padding(.horizontal, 8)
            .frame(maxHeight: .infinity)
        }
        .frame(height: 56)
        .background(selectedType.headerBackground)
    }

    // ═══════════════════════════════════════════════════════════════
    // TYPE SELECTOR (Segmented)
    // ═══════════════════════════════════════════════════════════════

    private var typeSelector: some View {
        HStack(spacing: 0) {
            ForEach(EntryType.allCases) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedType = type
                    }
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.system(size: 12, weight: .bold))
                        Text(type.displayName)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(selectedType == type ? JohoColors.white : JohoColors.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(selectedType == type ? type.color : type.lightBackground)
                }
                .buttonStyle(.plain)

                if type != EntryType.allCases.last {
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                }
            }
        }
        .frame(height: 40)
    }

    // ═══════════════════════════════════════════════════════════════
    // DYNAMIC FIELDS
    // ═══════════════════════════════════════════════════════════════

    @ViewBuilder
    private var dynamicFields: some View {
        switch selectedType {
        case .note:
            noteFields
        case .trip:
            tripFields
        case .expense:
            expenseFields
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // NOTE FIELDS
    // ═══════════════════════════════════════════════════════════════

    private var noteFields: some View {
        VStack(spacing: 0) {
            // Content row
            fieldRow(
                icon: "pencil",
                iconColor: JohoColors.black,
                content: {
                    TextField("Note content", text: $noteContent, axis: .vertical)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(3...6)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                },
                background: selectedType.lightBackground,
                minHeight: 72
            )

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // Date row
            dateRow(
                year: $selectedYear,
                month: $selectedMonth,
                day: $selectedDay,
                background: selectedType.lightBackground
            )

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // Icon picker row
            iconPickerRow(
                currentIcon: noteSymbol,
                accentColor: selectedType.color,
                background: selectedType.lightBackground.opacity(0.5)
            )
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TRIP FIELDS
    // ═══════════════════════════════════════════════════════════════

    private var tripFields: some View {
        VStack(spacing: 0) {
            // Trip name row
            fieldRow(
                icon: "tag.fill",
                iconColor: JohoColors.black,
                content: {
                    TextField("Trip name", text: $tripName)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                },
                background: selectedType.lightBackground
            )

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // Destination row
            fieldRow(
                icon: "mappin.circle.fill",
                iconColor: selectedType.color,
                content: {
                    TextField("Destination", text: $tripDestination)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                },
                background: selectedType.lightBackground
            )

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // Start date row
            HStack(spacing: 0) {
                Text("FROM")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.6))
                    .frame(width: 44)
                    .frame(maxHeight: .infinity)

                Rectangle().fill(JohoColors.black).frame(width: 1.5).frame(maxHeight: .infinity)

                datePickerCells(
                    year: $tripStartYear,
                    month: $tripStartMonth,
                    day: $tripStartDay
                )
            }
            .frame(height: 44)
            .background(selectedType.lightBackground)

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // End date row
            HStack(spacing: 0) {
                Text("TO")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.6))
                    .frame(width: 44)
                    .frame(maxHeight: .infinity)

                Rectangle().fill(JohoColors.black).frame(width: 1.5).frame(maxHeight: .infinity)

                datePickerCells(
                    year: $tripEndYear,
                    month: $tripEndMonth,
                    day: $tripEndDay
                )
            }
            .frame(height: 44)
            .background(selectedType.lightBackground)

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // Trip type row
            HStack(spacing: 0) {
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 44)
                    .frame(maxHeight: .infinity)

                Rectangle().fill(JohoColors.black).frame(width: 1.5).frame(maxHeight: .infinity)

                ForEach(TripType.allCases, id: \.self) { type in
                    Button {
                        tripType = type
                        HapticManager.selection()
                    } label: {
                        Text(type.rawValue.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(tripType == type ? JohoColors.white : JohoColors.black)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                            .background(tripType == type ? selectedType.color : Color.clear)
                    }
                    .buttonStyle(.plain)

                    if type != TripType.allCases.last {
                        Rectangle().fill(JohoColors.black).frame(width: 1.5).frame(maxHeight: .infinity)
                    }
                }
            }
            .frame(height: 44)
            .background(selectedType.lightBackground.opacity(0.5))
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // EXPENSE FIELDS
    // ═══════════════════════════════════════════════════════════════

    private var expenseFields: some View {
        VStack(spacing: 0) {
            // Description row
            fieldRow(
                icon: "pencil",
                iconColor: selectedType.color,
                content: {
                    TextField("Expense description", text: $expenseDescription)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                },
                background: selectedType.lightBackground
            )

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // Amount row
            HStack(spacing: 0) {
                Image(systemName: "dollarsign")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 44)
                    .frame(maxHeight: .infinity)

                Rectangle().fill(JohoColors.black).frame(width: 1.5).frame(maxHeight: .infinity)

                TextField("0.00", text: $expenseAmount)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .keyboardType(.decimalPad)
                    .foregroundStyle(JohoColors.black)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, JohoDimensions.spacingMD)

                Rectangle().fill(JohoColors.black).frame(width: 1.5).frame(maxHeight: .infinity)

                Menu {
                    ForEach(CurrencyDefinition.defaultCurrencies) { curr in
                        Button(curr.code) {
                            expenseCurrency = curr.code
                        }
                    }
                } label: {
                    Text(expenseCurrency)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 72)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(height: 48)
            .background(selectedType.lightBackground)

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // Date row
            dateRow(
                year: $selectedYear,
                month: $selectedMonth,
                day: $selectedDay,
                background: selectedType.lightBackground
            )

            Rectangle().fill(JohoColors.black).frame(height: 1.5)

            // Category row - tappable to open collapsible picker
            Button {
                showingCategoryPicker = true
                HapticManager.selection()
            } label: {
                HStack(spacing: 0) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(colors.primary)
                        .frame(width: 44)
                        .frame(maxHeight: .infinity)

                    Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

                    // Selected category display
                    HStack(spacing: JohoDimensions.spacingSM) {
                        if let category = selectedCategory {
                            // Show selected category icon + name
                            Image(systemName: category.iconName)
                                .font(.system(size: 16, weight: .bold))
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
                                .font(.system(size: 16, weight: .bold))
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
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(colors.primary.opacity(0.4))
                    }
                    .padding(.horizontal, JohoDimensions.spacingMD)
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 48)
                .background(selectedType.lightBackground)
            }
            .buttonStyle(.plain)

            Rectangle().fill(colors.border).frame(height: 1.5)

            // Merchant row (optional)
            fieldRow(
                icon: "storefront.fill",
                iconColor: JohoColors.black.opacity(0.6),
                content: {
                    TextField("Store name (optional)", text: $expenseMerchant)
                        .font(JohoFont.caption)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                        .padding(.horizontal, JohoDimensions.spacingMD)
                },
                background: selectedType.lightBackground.opacity(0.5)
            )
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // HELPER VIEWS
    // ═══════════════════════════════════════════════════════════════

    private func fieldRow<Content: View>(
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content,
        background: Color,
        minHeight: CGFloat = 48
    ) -> some View {
        HStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 44)
                .frame(maxHeight: .infinity)

            Rectangle()
                .fill(JohoColors.black)
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(maxHeight: .infinity)
        }
        .frame(minHeight: minHeight)
        .background(background)
    }

    private func dateRow(
        year: Binding<Int>,
        month: Binding<Int>,
        day: Binding<Int>,
        background: Color
    ) -> some View {
        HStack(spacing: 0) {
            Image(systemName: "calendar")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(JohoColors.black)
                .frame(width: 44)
                .frame(maxHeight: .infinity)

            Rectangle().fill(JohoColors.black).frame(width: 1.5).frame(maxHeight: .infinity)

            datePickerCells(year: year, month: month, day: day)
        }
        .frame(height: 48)
        .background(background)
    }

    private func datePickerCells(
        year: Binding<Int>,
        month: Binding<Int>,
        day: Binding<Int>
    ) -> some View {
        HStack(spacing: 0) {
            // Year
            Menu {
                ForEach(yearRange, id: \.self) { y in
                    Button { year.wrappedValue = y } label: { Text(String(y)) }
                }
            } label: {
                Text(String(year.wrappedValue))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(JohoColors.black)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
            }

            Rectangle().fill(JohoColors.black).frame(width: 1.5).frame(maxHeight: .infinity)

            // Month
            Menu {
                ForEach(1...12, id: \.self) { m in
                    Button { month.wrappedValue = m } label: { Text(monthName(m)) }
                }
            } label: {
                Text(monthName(month.wrappedValue))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
            }

            Rectangle().fill(JohoColors.black).frame(width: 1.5).frame(maxHeight: .infinity)

            // Day
            Menu {
                ForEach(1...daysInMonth(month.wrappedValue, year: year.wrappedValue), id: \.self) { d in
                    Button { day.wrappedValue = d } label: { Text("\(d)") }
                }
            } label: {
                Text("\(day.wrappedValue)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 44)
                    .frame(maxHeight: .infinity)
            }
        }
    }

    private func iconPickerRow(
        currentIcon: String,
        accentColor: Color,
        background: Color
    ) -> some View {
        Button {
            showingIconPicker = true
            HapticManager.selection()
        } label: {
            HStack(spacing: 0) {
                Image(systemName: currentIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 44)
                    .frame(maxHeight: .infinity)

                Rectangle().fill(JohoColors.black).frame(width: 1.5).frame(maxHeight: .infinity)

                Text("Tap to change icon")
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
                    .padding(.leading, JohoDimensions.spacingMD)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(JohoColors.black.opacity(0.4))
                    .padding(.trailing, JohoDimensions.spacingMD)
            }
            .frame(height: 48)
            .background(background)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func categoryButton(_ category: ExpenseCategory?, isSelected: Bool) -> some View {
        Button {
            selectedCategory = category
            HapticManager.selection()
        } label: {
            Image(systemName: category?.iconName ?? "minus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isSelected ? JohoColors.white : (category?.color ?? JohoColors.black))
                .frame(width: 32, height: 32)
                .background(isSelected ? (category?.color ?? JohoColors.black) : JohoColors.white)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(category?.color ?? JohoColors.black, lineWidth: isSelected ? 2.5 : 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    // ═══════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════

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

    // ═══════════════════════════════════════════════════════════════
    // SAVE
    // ═══════════════════════════════════════════════════════════════

    private func saveEntry() {
        switch selectedType {
        case .note:
            saveNote()
        case .trip:
            saveTrip()
        case .expense:
            saveExpense()
        }
    }

    private func saveNote() {
        let trimmedContent = noteContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        let note = DailyNote(
            date: selectedDate,
            content: trimmedContent,
            symbolName: noteSymbol
        )
        modelContext.insert(note)

        do {
            try modelContext.save()
            HapticManager.notification(.success)
        } catch {
            Log.w("Failed to save note: \(error.localizedDescription)")
        }
    }

    private func saveTrip() {
        let trimmedDestination = tripDestination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDestination.isEmpty else { return }

        let trip = TravelTrip(
            tripName: tripName.isEmpty ? trimmedDestination : tripName,
            destination: trimmedDestination,
            startDate: tripStartDate,
            endDate: tripEndDate,
            tripType: tripType
        )
        modelContext.insert(trip)

        do {
            try modelContext.save()
            HapticManager.notification(.success)
        } catch {
            Log.w("Failed to save trip: \(error.localizedDescription)")
        }
    }

    private func saveExpense() {
        guard let amountValue = Double(expenseAmount.replacingOccurrences(of: ",", with: ".")) else { return }
        let trimmedDesc = expenseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDesc.isEmpty else { return }

        let expense = ExpenseItem(
            date: selectedDate,
            amount: amountValue,
            currency: expenseCurrency,
            merchantName: expenseMerchant.isEmpty ? nil : expenseMerchant,
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

// MARK: - Preview

#Preview {
    JohoUnifiedEntrySheet(selectedDate: Date())
        .modelContainer(for: [DailyNote.self, TravelTrip.self, ExpenseItem.self, ExpenseCategory.self], inMemory: true)
}
