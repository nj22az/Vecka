//
//  UnifiedEntryView.swift
//  Vecka
//
//  情報デザイン: TRUE Bento Box Entry Form
//  - ONE container with internal compartments
//  - Type selector as compact strip in header
//  - Form fields as bento compartments below
//  - NO spacing between containers - walls only
//
//  Follows: Onsen/Star/Calendar golden standards
//  SF Pro symbols only - NO emojis
//

import SwiftUI
import SwiftData

// MARK: - 情報デザイン TRUE Bento Entry Sheet

struct JohoUnifiedEntrySheet: View {
    let initialDate: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Entry type selection
    @State private var selectedType: EntryType = .note

    // ═══════════════════════════════════════════════════════════════
    // NOTE FIELDS
    // ═══════════════════════════════════════════════════════════════
    @State private var noteContent: String = ""
    @State private var noteSymbol: String = "doc.text"

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
    // HOLIDAY FIELDS
    // ═══════════════════════════════════════════════════════════════
    @State private var holidayName: String = ""
    @State private var holidayIsBank: Bool = false
    @State private var holidaySymbol: String = "star"

    // ═══════════════════════════════════════════════════════════════
    // BIRTHDAY FIELDS
    // ═══════════════════════════════════════════════════════════════
    @State private var birthdayFirstName: String = ""
    @State private var birthdayLastName: String = ""
    @State private var birthdayHasYear: Bool = true

    // ═══════════════════════════════════════════════════════════════
    // EVENT FIELDS (情報デザイン: Countdown with tasks)
    // ═══════════════════════════════════════════════════════════════
    @State private var eventName: String = ""
    @State private var eventIsAnnual: Bool = false
    @State private var eventTasks: [EventTask] = []
    @State private var eventIconName: String? = nil

    // ═══════════════════════════════════════════════════════════════
    // SHARED DATE FIELDS
    // ═══════════════════════════════════════════════════════════════
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int

    // Pickers
    @State private var showingIconPicker = false
    @State private var showingCategoryPicker = false
    @State private var expandedGroups: Set<ExpenseCategoryGroup> = []

    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    private let calendar = Calendar.current

    // ═══════════════════════════════════════════════════════════════
    // SMART DETECTION
    // ═══════════════════════════════════════════════════════════════
    @State private var suggestedType: EntryType? = nil
    @State private var hasDismissedSuggestion: Bool = false
    @State private var detectionTask: Task<Void, Never>? = nil

    // ═══════════════════════════════════════════════════════════════
    // COMPUTED
    // ═══════════════════════════════════════════════════════════════

    private var canSave: Bool {
        switch selectedType {
        case .note:
            return !noteContent.trimmed.isEmpty
        case .trip:
            return !tripDestination.trimmed.isEmpty
        case .expense:
            guard let amount = Double(expenseAmount.replacingOccurrences(of: ",", with: ".")) else { return false }
            return amount > 0 && !expenseDescription.trimmed.isEmpty
        case .holiday:
            return !holidayName.trimmed.isEmpty
        case .birthday:
            return !birthdayFirstName.trimmed.isEmpty
        case .event:
            return !eventName.trimmed.isEmpty
        }
    }

    private var selectedDate: Date {
        calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)) ?? initialDate
    }

    private var tripStartDate: Date {
        calendar.date(from: DateComponents(year: tripStartYear, month: tripStartMonth, day: tripStartDay)) ?? initialDate
    }

    private var tripEndDate: Date {
        calendar.date(from: DateComponents(year: tripEndYear, month: tripEndMonth, day: tripEndDay)) ?? initialDate
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
    // BODY - TRUE BENTO (ONE container)
    // ═══════════════════════════════════════════════════════════════

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ═══════════════════════════════════════════════════════════
                // THE BENTO BOX - One unified container
                // ═══════════════════════════════════════════════════════════
                VStack(spacing: 0) {
                    // ROW 1: Header with type selector integrated
                    headerRow

                    wall

                    // ROW 2: Neutral type selector (情報デザイン: no colors in chrome)
                    typeSelector

                    // ROW 2.5: Smart suggestion (conditional)
                    suggestionRow

                    wall

                    // ROW 3+: Dynamic form fields
                    dynamicFields
                }
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
                )
                .padding(.horizontal, JohoDimensions.spacingSM)
                .padding(.top, JohoDimensions.spacingSM)
            }
        }
        .scrollContentBackground(.hidden)
        .johoBackground()
        .navigationBarHidden(true)
        .onAppear { expenseCurrency = baseCurrency }
        .sheet(isPresented: $showingIconPicker) {
            JohoIconPickerSheet(
                selectedSymbol: selectedType == .note ? $noteSymbol : $holidaySymbol,
                accentColor: selectedType.color,
                lightBackground: colors.surface
            )
        }
        .sheet(isPresented: $showingCategoryPicker) {
            JohoCollapsibleCategoryPicker(
                categories: categories,
                selectedCategory: $selectedCategory,
                expandedGroups: $expandedGroups,
                accentColor: selectedType.color,
                lightBackground: colors.surface
            )
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // WALL (Horizontal divider) - 情報デザイン SOFT: Gentle, not harsh
    // ═══════════════════════════════════════════════════════════════

    private var wall: some View {
        Rectangle()
            .fill(colors.border.opacity(0.3))
            .frame(height: 1)
    }

    private var thinWall: some View {
        Rectangle()
            .fill(colors.border.opacity(0.2))
            .frame(height: 0.5)
    }

    private func verticalWall(width: CGFloat = 1) -> some View {
        Rectangle()
            .fill(colors.border.opacity(0.3))
            .frame(width: width)
    }

    // ═══════════════════════════════════════════════════════════════
    // HEADER ROW: [✕] | [+] ENTRY | [✓]
    // ═══════════════════════════════════════════════════════════════

    private var headerRow: some View {
        HStack(spacing: 0) {
            // Close button - clear and visible
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.5))
                    .frame(width: 44, height: 48)
            }
            .buttonStyle(.plain)

            verticalWall()

            // Icon + TYPE NAME - Shows what you're adding (not generic "ENTRY")
            HStack(spacing: JohoDimensions.spacingSM) {
                // Type icon in colored box (like Calendar header)
                Image(systemName: selectedType.icon)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 28, height: 28)
                    .background(selectedType.color)
                    .clipShape(Squircle(cornerRadius: 6))

                // Show TYPE NAME - "ADD NOTE", "ADD TRIP", etc.
                Text("ADD \(selectedType.displayName)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, JohoDimensions.spacingSM)

            verticalWall()

            // Save button - PROMINENT when valid (filled background)
            Button {
                saveEntry()
                dismiss()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(canSave ? JohoColors.black : colors.primary.opacity(0.2))
                    .frame(width: 52, height: 48)
                    .background(canSave ? selectedType.color : Color.clear)
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .frame(height: 48)
    }

    // ═══════════════════════════════════════════════════════════════
    // TYPE SELECTOR: Neutral dropdown menu (情報デザイン compliant)
    // ═══════════════════════════════════════════════════════════════

    private var typeSelector: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            JohoTypeSelector(selectedType: $selectedType) { _ in
                clearSuggestion()
            }

            Spacer()

            // Hint for required fields
            Text(selectedType.requiredFieldsHint)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary.opacity(0.5))
        }
        .padding(JohoDimensions.spacingMD)
    }

    // ═══════════════════════════════════════════════════════════════
    // SMART SUGGESTION: Shows when input matches a pattern
    // ═══════════════════════════════════════════════════════════════

    @ViewBuilder
    private var suggestionRow: some View {
        if let suggested = suggestedType,
           suggested != selectedType,
           !hasDismissedSuggestion {
            JohoTypeSuggestionPill(
                suggestedType: suggested,
                onAccept: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedType = suggested
                        suggestedType = nil
                        hasDismissedSuggestion = false
                    }
                    HapticManager.selection()
                },
                onDismiss: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        hasDismissedSuggestion = true
                    }
                }
            )
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.bottom, JohoDimensions.spacingSM)
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SMART DETECTION LOGIC
    // ═══════════════════════════════════════════════════════════════

    private func runSmartDetection(for input: String) {
        // Cancel previous detection task
        detectionTask?.cancel()

        // Reset suggestion when input is cleared
        guard !input.isEmpty else {
            suggestedType = nil
            return
        }

        // Debounce: Wait 500ms before analyzing
        detectionTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            if let result = EntryTypeDetector.analyze(input),
               result.confidence >= 0.65 {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        suggestedType = result.suggestedType
                        hasDismissedSuggestion = false
                    }
                }
            }
        }
    }

    private func clearSuggestion() {
        suggestedType = nil
        hasDismissedSuggestion = false
    }

    // ═══════════════════════════════════════════════════════════════
    // DYNAMIC FIELDS (per type)
    // ═══════════════════════════════════════════════════════════════

    @ViewBuilder
    private var dynamicFields: some View {
        switch selectedType {
        case .note: noteFields
        case .trip: tripFields
        case .expense: expenseFields
        case .holiday: holidayFields
        case .birthday: birthdayFields
        case .event: eventFields
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // NOTE FIELDS
    // ═══════════════════════════════════════════════════════════════

    private var noteFields: some View {
        VStack(spacing: 0) {
            fieldRow(icon: "pencil", color: selectedType.color) {
                TextField("Note content", text: $noteContent, axis: .vertical)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .lineLimit(2...5)
                    .onChange(of: noteContent) { _, newValue in
                        runSmartDetection(for: newValue)
                    }
            }
            .frame(minHeight: 64)

            thinWall

            dateRow(year: $selectedYear, month: $selectedMonth, day: $selectedDay)

            thinWall

            iconPickerRow(currentIcon: noteSymbol)
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TRIP FIELDS
    // ═══════════════════════════════════════════════════════════════

    private var tripFields: some View {
        VStack(spacing: 0) {
            fieldRow(icon: "mappin.circle", color: selectedType.color) {
                TextField("Destination", text: $tripDestination)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .onChange(of: tripDestination) { _, newValue in
                        runSmartDetection(for: newValue)
                    }
            }

            thinWall

            fieldRow(icon: "tag", color: colors.primary.opacity(0.4)) {
                TextField("Trip name (optional)", text: $tripName)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.8))
            }

            thinWall

            labeledDateRow(label: "FROM", year: $tripStartYear, month: $tripStartMonth, day: $tripStartDay)

            thinWall

            labeledDateRow(label: "TO", year: $tripEndYear, month: $tripEndMonth, day: $tripEndDay)

            thinWall

            tripTypeSegment
        }
    }

    private var tripTypeSegment: some View {
        HStack(spacing: 0) {
            iconZone(icon: "briefcase", color: selectedType.color)
            verticalWall()

            ForEach(TripType.allCases, id: \.self) { type in
                Button {
                    tripType = type
                    HapticManager.selection()
                } label: {
                    // 情報デザイン SOFT: Gentle text, colored backgrounds
                    Text(type.rawValue.uppercased().prefix(4))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(tripType == type ? colors.primary : colors.primary.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(tripType == type ? selectedType.color.opacity(0.6) : Color.clear)
                }
                .buttonStyle(.plain)

                if type != TripType.allCases.last {
                    verticalWall(width: 1)
                }
            }
        }
        .frame(height: 44)
    }

    // ═══════════════════════════════════════════════════════════════
    // EXPENSE FIELDS
    // ═══════════════════════════════════════════════════════════════

    private var expenseFields: some View {
        VStack(spacing: 0) {
            fieldRow(icon: "pencil", color: selectedType.color) {
                TextField("Description", text: $expenseDescription)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .onChange(of: expenseDescription) { _, newValue in
                        runSmartDetection(for: newValue)
                    }
            }

            thinWall

            amountRow

            thinWall

            dateRow(year: $selectedYear, month: $selectedMonth, day: $selectedDay)

            thinWall

            categoryRow

            thinWall

            fieldRow(icon: "storefront", color: colors.primary.opacity(0.4)) {
                TextField("Store (optional)", text: $expenseMerchant)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.7))
            }
        }
    }

    private var amountRow: some View {
        HStack(spacing: 0) {
            iconZone(icon: "dollarsign", color: selectedType.color)
            verticalWall()

            TextField("0", text: $expenseAmount)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .keyboardType(.decimalPad)
                .foregroundStyle(colors.primary)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity)
                .onChange(of: expenseAmount) { _, newValue in
                    runSmartDetection(for: newValue)
                }

            verticalWall()

            Menu {
                ForEach(CurrencyDefinition.defaultCurrencies) { curr in
                    Button(curr.code) { expenseCurrency = curr.code }
                }
            } label: {
                Text(expenseCurrency)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(colors.primary)
                    .frame(width: 48, height: 44)
            }
        }
        .frame(height: 44)
    }

    private var categoryRow: some View {
        Button {
            showingCategoryPicker = true
            HapticManager.selection()
        } label: {
            HStack(spacing: 0) {
                iconZone(icon: "folder", color: selectedType.color)
                verticalWall()

                HStack(spacing: JohoDimensions.spacingSM) {
                    if let category = selectedCategory {
                        Image(systemName: category.iconName)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.white)
                            .frame(width: 22, height: 22)
                            .background(category.color)
                            .clipShape(Circle())

                        Text(category.name.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                    } else {
                        Circle()
                            .stroke(colors.border, lineWidth: 1.5)
                            .frame(width: 22, height: 22)

                        Text("CATEGORY")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.4))
                }
                .padding(.horizontal, JohoDimensions.spacingSM)
                .frame(height: 44)
            }
        }
        .buttonStyle(.plain)
    }

    // ═══════════════════════════════════════════════════════════════
    // HOLIDAY FIELDS
    // ═══════════════════════════════════════════════════════════════

    private var holidayFields: some View {
        VStack(spacing: 0) {
            fieldRow(icon: "pencil", color: selectedType.color) {
                TextField("Holiday name", text: $holidayName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .onChange(of: holidayName) { _, newValue in
                        runSmartDetection(for: newValue)
                    }
            }

            thinWall

            dateRow(year: $selectedYear, month: $selectedMonth, day: $selectedDay)

            thinWall

            holidayTypeSegment

            thinWall

            iconPickerRow(currentIcon: holidaySymbol)
        }
    }

    private var holidayTypeSegment: some View {
        HStack(spacing: 0) {
            iconZone(icon: "flag", color: selectedType.color)
            verticalWall()

            Button {
                holidayIsBank = false
                HapticManager.selection()
            } label: {
                // 情報デザイン SOFT: Gentle orange tint
                Text("OBSERVANCE")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(!holidayIsBank ? colors.primary : colors.primary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(!holidayIsBank ? JohoColors.cyan.opacity(0.6) : Color.clear)
            }
            .buttonStyle(.plain)

            verticalWall(width: 1)

            Button {
                holidayIsBank = true
                HapticManager.selection()
            } label: {
                // 情報デザイン SOFT: Softer red tint
                Text("HOLIDAY")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(holidayIsBank ? colors.primary : colors.primary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(holidayIsBank ? JohoColors.red.opacity(0.5) : Color.clear)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 44)
    }

    // ═══════════════════════════════════════════════════════════════
    // BIRTHDAY FIELDS
    // ═══════════════════════════════════════════════════════════════

    private var birthdayFields: some View {
        VStack(spacing: 0) {
            fieldRow(icon: "person", color: selectedType.color) {
                TextField("First name", text: $birthdayFirstName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .onChange(of: birthdayFirstName) { _, newValue in
                        runSmartDetection(for: newValue)
                    }
            }

            thinWall

            fieldRow(icon: "person.text.rectangle", color: colors.primary.opacity(0.4)) {
                TextField("Last name (optional)", text: $birthdayLastName)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.8))
            }

            thinWall

            birthdayYearSegment

            thinWall

            if birthdayHasYear {
                dateRow(year: $selectedYear, month: $selectedMonth, day: $selectedDay)
            } else {
                monthDayRow(month: $selectedMonth, day: $selectedDay)
            }
        }
    }

    private var birthdayYearSegment: some View {
        HStack(spacing: 0) {
            iconZone(icon: "calendar.badge.clock", color: selectedType.color)
            verticalWall()

            Button {
                birthdayHasYear = true
                HapticManager.selection()
            } label: {
                // 情報デザイン SOFT: Gentle pink tint
                Text("WITH YEAR")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(birthdayHasYear ? colors.primary : colors.primary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(birthdayHasYear ? selectedType.color.opacity(0.6) : Color.clear)
            }
            .buttonStyle(.plain)

            verticalWall(width: 1)

            Button {
                birthdayHasYear = false
                HapticManager.selection()
            } label: {
                // 情報デザイン SOFT: Subtle gray tint
                Text("NO YEAR")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(!birthdayHasYear ? colors.primary : colors.primary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(!birthdayHasYear ? colors.primary.opacity(0.1) : Color.clear)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 44)
    }

    // ═══════════════════════════════════════════════════════════════
    // EVENT FIELDS (情報デザイン: Countdown with preparation tasks)
    // ═══════════════════════════════════════════════════════════════

    private var eventFields: some View {
        VStack(spacing: 0) {
            // Event name
            fieldRow(icon: "calendar.badge.clock", color: selectedType.color) {
                TextField("Event name", text: $eventName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
            }

            thinWall

            // Date
            dateRow(year: $selectedYear, month: $selectedMonth, day: $selectedDay)

            thinWall

            // Annual toggle
            eventAnnualSegment

            thinWall

            // Tasks section (情報デザイン: Embedded task list)
            eventTasksRow
        }
    }

    private var eventAnnualSegment: some View {
        HStack(spacing: 0) {
            iconZone(icon: "arrow.trianglehead.2.clockwise.rotate.90", color: selectedType.color)
            verticalWall()

            Button {
                eventIsAnnual = false
                HapticManager.selection()
            } label: {
                Text("ONE-TIME")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(!eventIsAnnual ? colors.primary : colors.primary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(!eventIsAnnual ? selectedType.color.opacity(0.6) : Color.clear)
            }
            .buttonStyle(.plain)

            verticalWall(width: 1)

            Button {
                eventIsAnnual = true
                HapticManager.selection()
            } label: {
                Text("ANNUAL")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(eventIsAnnual ? colors.primary : colors.primary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(eventIsAnnual ? selectedType.color.opacity(0.6) : Color.clear)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 44)
    }

    private var eventTasksRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tasks header
            HStack(spacing: JohoDimensions.spacingSM) {
                iconZone(icon: "checklist", color: selectedType.color)
                verticalWall()

                Text("PREPARATION TASKS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.6))

                Spacer()

                // Task count
                if !eventTasks.isEmpty {
                    let completed = eventTasks.filter { $0.isCompleted && !$0.text.isEmpty }.count
                    let total = eventTasks.filter { !$0.text.isEmpty }.count
                    if total > 0 {
                        Text("\(completed)/\(total)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(completed == total ? selectedType.color : colors.primary.opacity(0.5))
                            .padding(.trailing, JohoDimensions.spacingMD)
                    }
                }
            }
            .frame(height: 44)

            // Task list
            ForEach(Array(eventTasks.enumerated()), id: \.element.id) { index, _ in
                thinWall

                HStack(spacing: JohoDimensions.spacingSM) {
                    // Checkbox
                    Button {
                        eventTasks[index].isCompleted.toggle()
                        HapticManager.impact(.light)
                    } label: {
                        Image(systemName: eventTasks[index].isCompleted ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(eventTasks[index].isCompleted ? selectedType.color : colors.primary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, JohoDimensions.spacingMD)

                    // Task text
                    TextField("Task", text: $eventTasks[index].text)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(eventTasks[index].isCompleted ? colors.primary.opacity(0.4) : colors.primary)
                        .strikethrough(eventTasks[index].isCompleted, color: colors.primary.opacity(0.4))

                    // Delete button
                    if !eventTasks[index].text.isEmpty {
                        Button {
                            _ = withAnimation {
                                eventTasks.remove(at: index)
                            }
                            HapticManager.notification(.warning)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(colors.primary.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, JohoDimensions.spacingMD)
                    }
                }
                .frame(height: 40)
            }

            // Add task button
            thinWall

            Button {
                withAnimation {
                    eventTasks.append(EventTask(text: ""))
                }
                HapticManager.impact(.light)
            } label: {
                HStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(selectedType.color)

                    Text("Add Task")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(selectedType.color)

                    Spacer()
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .frame(height: 40)
            }
            .buttonStyle(.plain)
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SHARED FIELD COMPONENTS
    // ═══════════════════════════════════════════════════════════════

    private func iconZone(icon: String, color: Color) -> some View {
        // 情報デザイン: BLACK icon on colored tint (like Calendar header)
        // This ensures visibility - colored icons on light tints are invisible
        Image(systemName: icon)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(JohoColors.black.opacity(0.7))
            .johoTouchTarget()
            .background(color.opacity(0.3))
    }

    private func fieldRow<Content: View>(
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 0) {
            iconZone(icon: icon, color: color)
            verticalWall()
            content()
                .padding(.horizontal, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 44)
    }

    private func dateRow(year: Binding<Int>, month: Binding<Int>, day: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            iconZone(icon: "calendar", color: selectedType.color)
            verticalWall()
            datePickerCells(year: year, month: month, day: day)
        }
        .frame(height: 44)
    }

    private func labeledDateRow(label: String, year: Binding<Int>, month: Binding<Int>, day: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(colors.primary.opacity(0.6))
                .johoTouchTarget()
                .background(selectedType.color.opacity(0.15))

            verticalWall()
            datePickerCells(year: year, month: month, day: day)
        }
        .frame(height: 44)
    }

    private func datePickerCells(year: Binding<Int>, month: Binding<Int>, day: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            Menu {
                ForEach(yearRange, id: \.self) { y in
                    Button { year.wrappedValue = y } label: { Text(String(y)) }
                }
            } label: {
                Text(String(year.wrappedValue))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }

            verticalWall(width: 1)

            Menu {
                ForEach(1...12, id: \.self) { m in
                    Button { month.wrappedValue = m } label: { Text(monthName(m)) }
                }
            } label: {
                Text(monthName(month.wrappedValue))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }

            verticalWall(width: 1)

            Menu {
                ForEach(1...daysInMonth(month.wrappedValue, year: year.wrappedValue), id: \.self) { d in
                    Button { day.wrappedValue = d } label: { Text("\(d)") }
                }
            } label: {
                Text("\(day.wrappedValue)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(colors.primary)
                    .johoTouchTarget()
            }
        }
    }

    private func monthDayRow(month: Binding<Int>, day: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            iconZone(icon: "calendar", color: selectedType.color)
            verticalWall()

            Menu {
                ForEach(1...12, id: \.self) { m in
                    Button { month.wrappedValue = m } label: { Text(monthName(m)) }
                }
            } label: {
                Text(monthName(month.wrappedValue))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }

            verticalWall(width: 1)

            Menu {
                ForEach(1...daysInMonth(month.wrappedValue, year: 2024), id: \.self) { d in
                    Button { day.wrappedValue = d } label: { Text("\(d)") }
                }
            } label: {
                Text("\(day.wrappedValue)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(colors.primary)
                    .frame(width: 56, height: 44)
            }
        }
        .frame(height: 44)
    }

    private func iconPickerRow(currentIcon: String) -> some View {
        Button {
            showingIconPicker = true
            HapticManager.selection()
        } label: {
            HStack(spacing: 0) {
                // 情報デザイン: BLACK icon on colored tint (like Calendar header)
                Image(systemName: currentIcon)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.7))
                    .johoTouchTarget()
                    .background(selectedType.color.opacity(0.3))

                verticalWall()

                HStack {
                    Text("Change icon")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.7))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.4))
                }
                .padding(.horizontal, JohoDimensions.spacingSM)
                .frame(height: 44)
            }
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
        return formatter.string(from: calendar.date(from: components) ?? Date())
    }

    private func daysInMonth(_ month: Int, year: Int) -> Int {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else { return 31 }
        return range.count
    }

    // ═══════════════════════════════════════════════════════════════
    // SAVE
    // ═══════════════════════════════════════════════════════════════

    private func saveEntry() {
        switch selectedType {
        case .note: saveNote()
        case .trip: saveTrip()
        case .expense: saveExpense()
        case .holiday: saveHoliday()
        case .birthday: saveBirthday()
        case .event: saveEvent()
        }
    }

    private func saveNote() {
        let content = noteContent.trimmed
        guard !content.isEmpty else { return }

        let note = DailyNote(date: selectedDate, content: content, symbolName: noteSymbol)
        modelContext.insert(note)

        do {
            try modelContext.save()
            HapticManager.notification(.success)
        } catch {
            Log.w("Failed to save note: \(error.localizedDescription)")
        }
    }

    private func saveTrip() {
        let destination = tripDestination.trimmed
        guard !destination.isEmpty else { return }

        let trip = TravelTrip(
            tripName: tripName.isEmpty ? destination : tripName,
            destination: destination,
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
        guard let amount = Double(expenseAmount.replacingOccurrences(of: ",", with: ".")) else { return }
        let desc = expenseDescription.trimmed
        guard !desc.isEmpty else { return }

        let expense = ExpenseItem(
            date: selectedDate,
            amount: amount,
            currency: expenseCurrency,
            merchantName: expenseMerchant.isEmpty ? nil : expenseMerchant,
            itemDescription: desc,
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

    private func saveHoliday() {
        let name = holidayName.trimmed
        guard !name.isEmpty else { return }

        let rule = HolidayRule(
            name: name,
            region: "CUSTOM",
            isBankHoliday: holidayIsBank,
            symbolName: holidaySymbol,
            type: .fixed,
            month: selectedMonth,
            day: selectedDay
        )
        modelContext.insert(rule)

        do {
            try modelContext.save()
            HapticManager.notification(.success)
        } catch {
            Log.w("Failed to save holiday: \(error.localizedDescription)")
        }
    }

    private func saveBirthday() {
        let firstName = birthdayFirstName.trimmed
        guard !firstName.isEmpty else { return }

        let lastName = birthdayLastName.trimmed
        let birthdayDate: Date?
        if birthdayHasYear {
            birthdayDate = selectedDate
        } else {
            birthdayDate = calendar.date(from: DateComponents(year: 1604, month: selectedMonth, day: selectedDay))
        }

        let contact = Contact(
            givenName: firstName,
            familyName: lastName,
            birthday: birthdayDate,
            birthdayKnown: true
        )
        modelContext.insert(contact)

        do {
            try modelContext.save()
            HapticManager.notification(.success)
        } catch {
            Log.w("Failed to save birthday: \(error.localizedDescription)")
        }
    }

    private func saveEvent() {
        let name = eventName.trimmed
        guard !name.isEmpty else { return }

        // Filter out empty tasks
        let validTasks = eventTasks.filter { !$0.text.isEmpty }

        let countdown = CustomCountdown(
            name: name,
            date: selectedDate,
            isAnnual: eventIsAnnual,
            iconName: eventIconName,
            tasks: validTasks
        )

        // Load existing countdowns from UserDefaults
        var countdowns: [CustomCountdown] = []
        if let data = UserDefaults.standard.data(forKey: "customCountdowns"),
           let decoded = try? JSONDecoder().decode([CustomCountdown].self, from: data) {
            countdowns = decoded
        }

        // Add new countdown
        countdowns.append(countdown)

        // Save back to UserDefaults
        if let encoded = try? JSONEncoder().encode(countdowns) {
            UserDefaults.standard.set(encoded, forKey: "customCountdowns")
            HapticManager.notification(.success)
        }
    }
}

// MARK: - Preview

#Preview {
    JohoUnifiedEntrySheet(selectedDate: Date())
        .modelContainer(for: [DailyNote.self, TravelTrip.self, ExpenseItem.self, ExpenseCategory.self, HolidayRule.self, Contact.self], inMemory: true)
}
