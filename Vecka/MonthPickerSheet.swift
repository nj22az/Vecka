import SwiftUI
import SwiftData

struct MonthPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext
    @State private var month: Int
    @State private var year: Int
    let onSave: (Int, Int) -> Void
    
    init(initialMonth: Int, initialYear: Int, onSave: @escaping (Int, Int) -> Void) {
        _month = State(initialValue: initialMonth)
        _year = State(initialValue: initialYear)
        self.onSave = onSave
    }
    
    private var years: [Int] {
        let current = Calendar.iso8601.component(.year, from: Date())
        let range = ConfigurationManager.shared.getInt("year_picker_range", context: modelContext, default: 20)
        return Array((current - range)...(current + range))
    }

    // MARK: - Localized Strings
    
    private var pickerTitle: String {
        Localization.selectMonthYear
    }

    private var cancelLabel: String {
        NSLocalizedString("common.cancel", value: "Cancel", comment: "Cancel")
    }

    private var doneLabel: String {
        NSLocalizedString("common.done", value: "Done", comment: "Done")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Dual wheel pickers side by side (Apple Calendar style)
                HStack(spacing: 0) {
                    // Month Picker
                    Picker("Month", selection: $month) {
                        ForEach(1...12, id: \.self) { m in
                            Text(monthDisplayName(for: m))
                                .tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    
                    // Year Picker
                    Picker("Year", selection: $year) {
                        ForEach(years, id: \.self) { y in
                            Text(String(y))
                                .monospacedDigit()
                                .tag(y)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .frame(height: 216)
                .padding(.horizontal)
                
                Spacer(minLength: 0)
            }
            .navigationTitle(pickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancelLabel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(doneLabel) {
                        onSave(month, year)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func monthDisplayName(for month: Int) -> String {
        let symbols = DateFormatterCache.monthName.monthSymbols ?? []
        let raw = symbols.indices.contains(month - 1) ? symbols[month - 1] : ""
        if locale.language.languageCode?.identifier == "sv" {
            return raw.capitalized(with: locale)
        }
        return raw
    }
}
