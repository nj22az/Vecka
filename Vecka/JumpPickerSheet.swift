import SwiftUI

enum JumpMode: String, CaseIterable, Identifiable {
    case week, month
    var id: String { rawValue }
    var title: String { self == .week ? "Week" : "Month" }
}

struct JumpPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mode: JumpMode
    @State private var year: Int
    @State private var month: Int
    @State private var week: Int
    let onDone: (Date) -> Void

    init(initialMode: JumpMode, initialYear: Int, initialMonth: Int, initialWeek: Int, onDone: @escaping (Date) -> Void) {
        _mode = State(initialValue: initialMode)
        _year = State(initialValue: initialYear)
        _month = State(initialValue: initialMonth)
        _week = State(initialValue: initialWeek)
        self.onDone = onDone
    }

    private var years: [Int] {
        let current = Calendar.iso8601.component(.year, from: Date())
        return Array((current - 20)...(current + 20))
    }

    private var computedWeeks: [Int] {
        let w = JumpPickerSheet.weeksInYear(year)
        return Array(1...w)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Picker("Mode", selection: $mode) {
                    ForEach(JumpMode.allCases) { m in
                        Text(m.title).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Form {
                    Section("Year") {
                        Picker("Year", selection: $year) {
                            ForEach(years, id: \.self) { y in Text(String(y)).tag(y) }
                        }
                        .pickerStyle(.wheel)
                    }
                    if mode == .month {
                        Section("Month") {
                            Picker("Month", selection: $month) {
                                ForEach(1...12, id: \.self) { m in
                                    Text(DateFormatterCache.monthName.monthSymbols[m-1]).tag(m)
                                }
                            }
                            .pickerStyle(.wheel)
                        }
                    } else {
                        Section("Week") {
                            Picker("Week", selection: $week) {
                                ForEach(computedWeeks, id: \.self) { w in Text("Week \(w)").tag(w) }
                            }
                            .pickerStyle(.wheel)
                        }
                    }
                }
            }
            .navigationTitle("Jump To")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDone(resolveDate())
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func resolveDate() -> Date {
        var comps = DateComponents()
        if mode == .month {
            comps.year = year
            comps.month = month
            comps.day = 1
            return Calendar.iso8601.date(from: comps) ?? Date()
        } else {
            comps.yearForWeekOfYear = year
            comps.weekOfYear = week
            comps.weekday = 2 // Monday
            return Calendar.iso8601.date(from: comps) ?? Date()
        }
    }

    static func weeksInYear(_ year: Int) -> Int {
        var comps = DateComponents()
        comps.yearForWeekOfYear = year
        comps.weekOfYear = 53
        comps.weekday = 4 // Thursday to ensure ISO week validity
        let cal = Calendar.iso8601
        return cal.date(from: comps) != nil ? 53 : 52
    }
}
