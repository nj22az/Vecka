import SwiftUI

struct MonthPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
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
        return Array((current - 20)...(current + 20))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Month") {
                    Picker("Month", selection: $month) {
                        ForEach(1...12, id: \.self) { m in
                            Text(DateFormatterCache.monthName.monthSymbols[m-1]).tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                Section("Year") {
                    Picker("Year", selection: $year) {
                        ForEach(years, id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onSave(month, year); dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

