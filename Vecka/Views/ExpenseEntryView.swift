//
//  ExpenseEntryView.swift
//  Vecka
//
//  Quick expense entry (accessed from + button)
//

import SwiftUI
import SwiftData
import PhotosUI

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
    @FocusState private var isAmountFocused: Bool
    @State private var exchangeRateString: String = "1.0"
    
    // Base Currency
    @AppStorage("baseCurrency") private var baseCurrency = "SEK"
    
    // Edit Mode
    let existingExpense: ExpenseItem?

    init(date: Date = Date(), trip: TravelTrip? = nil, existingExpense: ExpenseItem? = nil) {
        self.initialDate = date
        self.trip = trip
        self.existingExpense = existingExpense
        
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
            // Initialize currency with a default value, will be updated by onAppear if baseCurrency is different
            _currency = State(initialValue: "SEK") 
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Quick Template Selection
                if !categories.isEmpty {
                    Section {
                        Button {
                            showTemplatePicker = true
                        } label: {
                            Label("Use Template", systemImage: "doc.text.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                // Amount Section
                Section {
                    HStack {
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                            .focused($isAmountFocused)

                        Picker("Currency", selection: $currency) {
                            ForEach(CurrencyDefinition.defaultCurrencies) { curr in
                                Text(curr.code).tag(curr.code)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    TextField("Merchant (optional)", text: $merchant)
                } header: {
                    Text(NSLocalizedString("expenses.amount", value: "Amount", comment: "Amount label"))
                }

                // Details Section
                Section {
                    TextField("Description", text: $description)

                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)

                    // Category Picker
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as ExpenseCategory?)
                        ForEach(categories) { category in
                            Label {
                                Text(category.name)
                            } icon: {
                                Image(systemName: category.iconName)
                                    .foregroundStyle(category.color)
                            }
                            .tag(category as ExpenseCategory?)
                        }
                    }
                } header: {
                    Text(NSLocalizedString("expenses.details", value: "Details", comment: "Details label"))
                }

                // Receipt Section
                Section {
                    if let image = receiptImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button(role: .destructive) {
                            receiptImage = nil
                        } label: {
                            Label("Remove Receipt", systemImage: "trash")
                        }
                    } else {
                        Button {
                            showImagePicker = true
                        } label: {
                            Label("Add Receipt Photo", systemImage: "camera.fill")
                        }
                    }
                } header: {
                    Text(NSLocalizedString("expenses.receipt", value: "Receipt", comment: "Receipt label"))
                }

                // Exchange Rate (hidden if same as Base)
                if currency != baseCurrency {
                    Section {
                        HStack {
                            Text(NSLocalizedString("expenses.exchange_rate", value: "Exchange Rate", comment: "Exchange rate label"))
                            Spacer()
                            TextField("Rate", text: $exchangeRateString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }

                        if let calculatedAmount = Double(amount.replacingOccurrences(of: ",", with: ".")) {
                            let rate = Double(exchangeRateString.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                            HStack {
                                Text(NSLocalizedString("expenses.converted_amount", value: "Converted Amount", comment: "Converted amount label"))
                                Spacer()
                                Text((calculatedAmount * rate), format: .currency(code: baseCurrency))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text(NSLocalizedString("expenses.currency_conversion", value: "Currency Conversion", comment: "Currency conversion header"))
                    } footer: {
                       let rate = Double(exchangeRateString.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                        Text("\(NSLocalizedString("expenses.rate_for", value: "Rate for", comment: "Rate for date prefix")) \(selectedDate.formatted(date: .abbreviated, time: .omitted)): 1 \(currency) = \(rate, format: .number.precision(.fractionLength(2...4))) \(baseCurrency)")
                    }
                }

                // Notes Section
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                } header: {
                    Text(NSLocalizedString("expenses.notes", value: "Notes (Optional)", comment: "Notes label"))
                }

                // Trip Assignment
                if let trip = trip {
                    Section {
                        HStack {
                            Label(trip.tripName, systemImage: "airplane")
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        }
                    } header: {
                        Text(NSLocalizedString("expenses.trip", value: "Trip", comment: "Trip label"))
                    }
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !isValid {
                            if let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) {
                                let (isValidAmount, validationError) = ConfigurationManager.shared.validate(
                                    field: "expense_amount",
                                    value: amountValue,
                                    context: modelContext
                                )
                                if !isValidAmount, let error = validationError {
                                    errorMessage = error
                                    showError = true
                                } else if description.isEmpty {
                                    errorMessage = "Please enter a description"
                                    showError = true
                                }
                            } else {
                                errorMessage = "Please enter a valid number"
                                showError = true
                            }
                        } else {
                            saveExpense()
                        }
                    }
                }
            }
            .onChange(of: currency) { _, newCurrency in
                if newCurrency != baseCurrency {
                    fetchExchangeRate(currency: newCurrency, date: selectedDate)
                }
            }
            .onChange(of: selectedDate) { _, newDate in
                if currency != baseCurrency {
                    fetchExchangeRate(currency: currency, date: newDate)
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView(categories: categories) { template in
                    applyTemplate(template)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $receiptImage)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Auto-focus amount field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isAmountFocused = true
                }
                // If it's a new expense, set currency to baseCurrency
                if existingExpense == nil {
                    currency = baseCurrency
                }
            }
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        // Validate amount using database rules
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return false
        }

        let (isValidAmount, _) = ConfigurationManager.shared.validate(
            field: "expense_amount",
            value: amountValue,
            context: modelContext
        )

        if !isValidAmount {
            return false
        }

        return !description.isEmpty
    }

    // MARK: - Actions

    private func fetchExchangeRate(currency: String, date: Date) {
        Task {
            do {
                let rate = try await CurrencyService.shared.getRate(
                    from: currency,
                    to: baseCurrency,
                    date: date,
                    context: modelContext
                )
                await MainActor.run {
                    self.exchangeRateString = String(format: "%.4f", rate)
                }
            } catch {
                Log.w("Failed to fetch rate: \(error)")
            }
        }
    }

    // MARK: - Save

    private func saveExpense() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Invalid amount"
            showError = true
            return
        }

        let expense: ExpenseItem
        if let existing = existingExpense {
            expense = existing
            expense.date = selectedDate
            expense.amount = amountValue
            expense.currency = currency
            expense.merchantName = merchant.isEmpty ? nil : merchant
            expense.itemDescription = description
            expense.notes = notes.isEmpty ? nil : notes
            expense.dateModified = Date()
        } else {
            expense = ExpenseItem(
                date: selectedDate,
                amount: amountValue,
                currency: currency,
                merchantName: merchant.isEmpty ? nil : merchant,
                itemDescription: description,
                notes: notes.isEmpty ? nil : notes
            )
            // Insert immediately if new
            modelContext.insert(expense)
        }

        // Set category
        expense.category = selectedCategory

        // Set trip
        expense.trip = trip

        // Set receipt image
        if let image = receiptImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            expense.receiptImageData = imageData
            expense.receiptFileName = "receipt_\(UUID().uuidString).jpg"
        }

        // Handle exchange rate
        if currency != baseCurrency {
            let rate = Double(exchangeRateString.replacingOccurrences(of: ",", with: ".")) ?? 1.0
            expense.exchangeRate = rate
            expense.convertedAmount = amountValue * rate
        }

        // Save and dismiss
        do {
            try modelContext.save()
            Log.i("Expense saved successfully: \(expense.itemDescription)")
            dismiss()
        } catch {
            Log.w("Failed to save expense: \(error)")
            errorMessage = "Failed to save expense: \(error.localizedDescription)"
            showError = true
        }
    }

    // MARK: - Template

    private func applyTemplate(_ template: ExpenseTemplate) {
        description = template.name
        currency = template.defaultCurrency

        if let defaultAmount = template.defaultAmount {
            amount = String(format: "%.2f", defaultAmount)
        }

        if let notes = template.notes {
            self.notes = notes
        }

        selectedCategory = template.category

        showTemplatePicker = false
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
