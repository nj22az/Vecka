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
        let wc = ViewUtilities.weeksInYear(year)
        return Array(1...wc)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 0) {
                    // Year Picker
                    VStack(spacing: 8) {
                        Text(Localization.yearLabel)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Picker(Localization.yearLabel, selection: $year) {
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
                    .padding(.top, 20)

                    Divider()
                        .padding(.vertical, 16)

                    // Week Picker
                    VStack(spacing: 8) {
                        Text(Localization.weekLabel)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Picker(Localization.weekLabel, selection: $week) {
                            ForEach(weeks, id: \.self) { w in
                                Text(Localization.weekDisplayText(w))
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

                Spacer()
            }
            .navigationTitle(Localization.selectWeek)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Localization.cancel) { dismiss() }
                        .foregroundStyle(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Localization.done) { onSave(week, year); dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }
        }
    }
}

