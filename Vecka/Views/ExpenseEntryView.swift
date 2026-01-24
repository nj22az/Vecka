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
    let existingExpense: Memo?  // For editing existing expenses

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.johoColorMode) private var colorMode

    @State private var amount: String = ""
    @State private var currency: String = "SEK"
    @State private var description: String = ""
    @State private var merchant: String = ""
    @State private var showingIconPicker = false
    @State private var selectedSymbol: String = "dollarsign.circle.fill"

    // Date selection (情報デザイン: Year, Month, Day)
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int

    /// Dynamic colors for dark mode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // Base Currency
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"

    // 情報デザイン: Expenses ALWAYS use green color scheme
    private var expenseAccentColor: Color { SpecialDayType.expense.accentColor }
    private var expenseLightBackground: Color { SpecialDayType.expense.lightBackground }

    private let calendar = Calendar.current

    private var isEditing: Bool { existingExpense != nil }

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

    init(selectedDate: Date = Date(), existingExpense: Memo? = nil) {
        self.existingExpense = existingExpense
        let dateToUse = existingExpense?.date ?? selectedDate
        self.initialDate = dateToUse

        let calendar = Calendar.current
        _selectedYear = State(initialValue: calendar.component(.year, from: dateToUse))
        _selectedMonth = State(initialValue: calendar.component(.month, from: dateToUse))
        _selectedDay = State(initialValue: calendar.component(.day, from: dateToUse))

        // Initialize from existing expense if editing
        if let expense = existingExpense {
            _amount = State(initialValue: String(format: "%.2f", expense.amount ?? 0))
            _currency = State(initialValue: expense.currency ?? "SEK")
            _description = State(initialValue: expense.text)
            _merchant = State(initialValue: expense.place ?? "")
        }
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
                            Text(isEditing ? "EDIT EXPENSE" : "NEW EXPENSE")
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

    private func saveExpense() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else { return }
        let trimmedDesc = description.trimmed
        guard !trimmedDesc.isEmpty else { return }

        if let existing = existingExpense {
            // Update existing expense
            existing.text = trimmedDesc
            existing.amount = amountValue
            existing.currency = currency
            existing.place = merchant.isEmpty ? nil : merchant
            existing.date = selectedDate
        } else {
            // Create new Memo expense (unified model)
            let expense = Memo.expense(
                trimmedDesc,
                amount: amountValue,
                currency: currency,
                merchant: merchant.isEmpty ? nil : merchant,
                date: selectedDate
            )
            modelContext.insert(expense)
        }

        do {
            try modelContext.save()
            HapticManager.notification(.success)
        } catch {
            Log.w("Failed to save expense: \(error.localizedDescription)")
        }
    }
}

// MARK: - Legacy ExpenseEntryView Wrapper

/// Legacy ExpenseEntryView for backwards compatibility - now uses Memo
struct ExpenseEntryView: View {
    let initialDate: Date
    let existingExpense: Memo?

    init(date: Date = Date(), existingExpense: Memo? = nil) {
        self.initialDate = existingExpense?.date ?? date
        self.existingExpense = existingExpense
    }

    var body: some View {
        // Redirect to new simplified sheet
        JohoExpenseEditorSheet(selectedDate: initialDate, existingExpense: existingExpense)
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
        .modelContainer(for: [Memo.self], inMemory: true)
}
