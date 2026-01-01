//
//  ExpenseEntryView.swift
//  Vecka
//
//  情報デザイン expense entry (accessed from + button)
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - 情報デザイン Expense Editor Sheet (Standalone - like Event editor)

/// Standalone expense editor sheet matching the Event editor pattern
/// Used when creating expenses from the + menu
struct JohoExpenseEditorSheet: View {
    let initialDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var amount: String = ""
    @State private var currency: String = "SEK"
    @State private var description: String = ""
    @State private var merchant: String = ""
    @State private var selectedCategory: ExpenseCategory?
    @FocusState private var isFocused: Bool

    // Date selection (情報デザイン: Year, Month, Day)
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int

    // Categories
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    // Base Currency
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    // Expense accent color - GREEN from design system
    private let accentColor = Color(hex: "BBF7D0")  // Light green for expenses
    private let solidAccent = Color(hex: "38A169")  // Solid green

    private var canSave: Bool {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return false
        }
        return amountValue > 0 && !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedDate: Date {
        let calendar = Calendar.current
        return calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)) ?? initialDate
    }

    private var yearRange: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }

    private func daysInMonth(_ month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 31
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: 2024, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }

    init(selectedDate: Date = Date()) {
        self.initialDate = selectedDate
        let calendar = Calendar.current
        _selectedYear = State(initialValue: calendar.component(.year, from: selectedDate))
        _selectedMonth = State(initialValue: calendar.component(.month, from: selectedDate))
        _selectedDay = State(initialValue: calendar.component(.day, from: selectedDate))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Floating header with Cancel/Save buttons (情報デザイン style)
            HStack {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .background(JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                }

                Spacer()

                Button {
                    saveExpense()
                    dismiss()
                } label: {
                    Text("Save")
                        .font(JohoFont.body.bold())
                        .foregroundStyle(canSave ? JohoColors.black : JohoColors.black.opacity(0.4))
                        .padding(.horizontal, JohoDimensions.spacingLG)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .background(canSave ? accentColor : JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                }
                .disabled(!canSave)
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(JohoColors.background)

            // Scrollable content
            ScrollView {
                // Main content card
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Title with type indicator (情報デザイン)
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Circle()
                            .fill(solidAccent)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
                        Text("New Expense")
                            .font(JohoFont.displaySmall)
                            .foregroundStyle(JohoColors.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Expense icon - 情報デザイン compartmentalized style
                    ZStack {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 64, height: 64)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 2.5))

                        Image(systemName: "banknote.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(JohoColors.black)
                    }

                    // Amount field - 情報デザイン prominent display
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "AMOUNT", style: .whiteOnBlack, size: .small)

                        HStack(spacing: JohoDimensions.spacingSM) {
                            // Amount input with currency symbol
                            HStack(spacing: 4) {
                                TextField("0", text: $amount)
                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                    .keyboardType(.decimalPad)
                                    .foregroundStyle(JohoColors.black)
                                    .focused($isFocused)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(JohoDimensions.spacingMD)
                            .frame(maxWidth: .infinity)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )

                            // Currency picker - 情報デザイン styled
                            Menu {
                                ForEach(CurrencyDefinition.defaultCurrencies) { curr in
                                    Button(curr.code) {
                                        currency = curr.code
                                    }
                                }
                            } label: {
                                Text(currency)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundStyle(JohoColors.black)
                                    .frame(width: 70)
                                    .padding(.vertical, JohoDimensions.spacingMD)
                                    .background(accentColor)
                                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                                    .overlay(
                                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                    )
                            }
                        }
                    }

                    // Description field
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "DESCRIPTION", style: .whiteOnBlack, size: .small)

                        TextField("What did you pay for?", text: $description)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .padding(JohoDimensions.spacingMD)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    // Merchant field (optional)
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "MERCHANT", style: .whiteOnBlack, size: .small)

                        TextField("Store name (optional)", text: $merchant)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .padding(JohoDimensions.spacingMD)
                            .background(JohoColors.white)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                            )
                    }

                    // Category picker - 情報デザイン grid with icons only
                    if !categories.isEmpty {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            HStack {
                                JohoPill(text: "CATEGORY", style: .whiteOnBlack, size: .small)
                                Spacer()
                                if let cat = selectedCategory {
                                    Text(cat.name.uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(JohoColors.black.opacity(0.6))
                                }
                            }

                            // Grid layout - 4 columns, responsive
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: JohoDimensions.spacingSM) {
                                // None option
                                categoryButton(nil, isSelected: selectedCategory == nil)

                                ForEach(categories) { category in
                                    categoryButton(category, isSelected: selectedCategory?.id == category.id)
                                }
                            }
                        }
                    }

                    // Date picker (情報デザイン: Year, Month, Day)
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "DATE", style: .whiteOnBlack, size: .small)

                        HStack(spacing: JohoDimensions.spacingSM) {
                            // Year
                            VStack(alignment: .leading, spacing: 4) {
                                Text("YEAR")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                Menu {
                                    ForEach(yearRange, id: \.self) { year in
                                        Button { selectedYear = year } label: {
                                            Text(String(year))
                                        }
                                    }
                                } label: {
                                    Text(String(selectedYear))
                                        .font(JohoFont.body)
                                        .monospacedDigit()
                                        .foregroundStyle(JohoColors.black)
                                        .padding(JohoDimensions.spacingSM)
                                        .frame(width: 70)
                                        .background(JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                        )
                                }
                            }

                            // Month
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MONTH")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                Menu {
                                    ForEach(1...12, id: \.self) { month in
                                        Button { selectedMonth = month } label: {
                                            Text(monthName(month))
                                        }
                                    }
                                } label: {
                                    Text(monthName(selectedMonth))
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)
                                        .padding(JohoDimensions.spacingSM)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                        )
                                }
                            }

                            // Day
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DAY")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                Menu {
                                    ForEach(1...daysInMonth(selectedMonth, year: selectedYear), id: \.self) { day in
                                        Button { selectedDay = day } label: {
                                            Text("\(day)")
                                        }
                                    }
                                } label: {
                                    Text("\(selectedDay)")
                                        .font(JohoFont.body)
                                        .monospacedDigit()
                                        .foregroundStyle(JohoColors.black)
                                        .padding(JohoDimensions.spacingSM)
                                        .frame(width: 50)
                                        .background(JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(JohoDimensions.spacingLG)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .onAppear {
            currency = baseCurrency
            // Don't auto-focus - let user tap to interact
        }
    }

    // 情報デザイン category button - icon only with color fill
    @ViewBuilder
    private func categoryButton(_ category: ExpenseCategory?, isSelected: Bool) -> some View {
        Button {
            selectedCategory = category
            HapticManager.selection()
        } label: {
            ZStack {
                // Background circle
                Circle()
                    .fill(isSelected ? (category?.color ?? JohoColors.black) : JohoColors.white)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(category?.color ?? JohoColors.black, lineWidth: isSelected ? 3 : 2)
                    )

                // Icon
                Image(systemName: category?.iconName ?? "minus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isSelected ? JohoColors.white : (category?.color ?? JohoColors.black))
            }
        }
        .buttonStyle(.plain)
    }

    private func saveExpense() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else { return }
        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
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
                                    .font(.system(size: 12, weight: .bold))
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
                .font(.system(size: 16, weight: .bold))
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
                .font(.system(size: 12, weight: .bold))
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
