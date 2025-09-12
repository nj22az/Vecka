import SwiftUI

struct WeekPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var week: Int
    @State private var year: Int
    let onSave: (Int, Int) -> Void
    
    init(initialWeek: Int, initialYear: Int, onSave: @escaping (Int, Int) -> Void) {
        _week = State(initialValue: initialWeek)
        _year = State(initialValue: initialYear)
        self.onSave = onSave
    }
    
    private var years: [Int] {
        let current = Calendar.iso8601.component(.year, from: Date())
        return Array((current - 20)...(current + 20))
    }
    
    private var weeks: [Int] {
        let wc = WeekPickerSheet.weeksInYear(year)
        return Array(1...wc)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Year") {
                    Picker("Year", selection: $year) {
                        ForEach(years, id: \.self) { y in Text(String(y)).tag(y) }
                    }
                    .pickerStyle(.wheel)
                }
                Section("Week") {
                    Picker("Week", selection: $week) {
                        ForEach(weeks, id: \.self) { w in Text("Week \(w)").tag(w) }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("Select Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onSave(week, year); dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    static func weeksInYear(_ year: Int) -> Int {
        var comps = DateComponents()
        comps.yearForWeekOfYear = year
        comps.weekOfYear = 53
        comps.weekday = 4 // Thursday to ensure ISO week
        let cal = Calendar.iso8601
        if cal.date(from: comps) != nil { return 53 }
        return 52
    }
}

