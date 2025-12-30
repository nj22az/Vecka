import SwiftUI
import SwiftData

enum JumpMode: String, CaseIterable, Identifiable {
    case week, month
    var id: String { rawValue }
    var title: String { self == .week ? "Week" : "Month" }
}

struct JumpPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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
        let range = ConfigurationManager.shared.getInt("year_picker_range", context: modelContext, default: 20)
        return Array((current - range)...(current + range))
    }

    private var computedWeeks: [Int] {
        let w = ViewUtilities.weeksInYear(year)
        return Array(1...w)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("Mode", selection: $mode) {
                    ForEach(JumpMode.allCases) { m in
                        Text(m.title).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 20)

                VStack(spacing: 0) {
                    // Year Picker
                    VStack(spacing: 8) {
                        Text("Year")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Picker("Year", selection: $year) {
                            ForEach(years, id: \.self) { y in
                                Text(String(y))
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .tag(y)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 180)
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 16)

                    // Month or Week Picker
                    if mode == .month {
                        VStack(spacing: 8) {
                            Text("Month")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Picker("Month", selection: $month) {
                                ForEach(1...12, id: \.self) { m in
                                    Text(DateFormatterCache.monthName.monthSymbols[m-1])
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .tag(m)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 180)
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 8) {
                            Text("Week")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Picker("Week", selection: $week) {
                                ForEach(computedWeeks, id: \.self) { w in
                                    Text("Week \(w)")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .tag(w)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 180)
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .navigationTitle("Jump To")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDone(resolveDate())
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
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
}
