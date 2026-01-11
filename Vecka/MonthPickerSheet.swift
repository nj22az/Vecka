import SwiftUI
import SwiftData

// MARK: - 情報デザイン Month/Year Picker
// Custom grid-based picker with thick borders and bold typography

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

    private let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    // MARK: - Localized Strings

    private var cancelLabel: String {
        NSLocalizedString("common.cancel", value: "Cancel", comment: "Cancel")
    }

    private var doneLabel: String {
        NSLocalizedString("common.done", value: "Done", comment: "Done")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Clean header bar - NO title, just action buttons
            HStack {
                Button(action: { dismiss() }) {
                    Text(cancelLabel)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                }

                Spacer()

                Button(action: {
                    onSave(month, year)
                    dismiss()
                }) {
                    Text(doneLabel)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // Thick black divider
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 3)

            // 情報デザイン: Month and Year in balanced bento layout
            HStack(alignment: .top, spacing: JohoDimensions.spacingSM) {
                // LEFT: Month Grid (3x4) - fills 65% width
                VStack(spacing: 0) {
                    // Section header integrated into border
                    Text("MONTH")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(JohoColors.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(JohoColors.black)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                        ForEach(1...12, id: \.self) { m in
                            monthButton(month: m)
                        }
                    }
                    .padding(JohoDimensions.spacingSM)
                }
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )

                // RIGHT: Year Grid (2x5 visible) - fills 35% width
                VStack(spacing: 0) {
                    // Section header integrated into border
                    Text("YEAR")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(JohoColors.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(JohoColors.black)

                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 2), spacing: 4) {
                                ForEach(years, id: \.self) { y in
                                    yearButton(year: y)
                                        .id(y)
                                }
                            }
                            .padding(JohoDimensions.spacingSM)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(year, anchor: .center)
                                }
                            }
                        }
                    }
                }
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusMedium)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )
            }
            .padding(JohoDimensions.spacingSM)
        }
        .background(JohoColors.yellow)
        // 情報デザイン: Content fills available space
        .presentationDetents([.medium])
        .presentationCornerRadius(JohoDimensions.radiusLarge)
        .presentationDragIndicator(.hidden)
    }

    private func monthButton(month m: Int) -> some View {
        Button(action: { month = m }) {
            Text(localizedMonthAbbrev(for: m))
                .font(.system(size: 14, weight: month == m ? .bold : .medium, design: .rounded))
                .foregroundStyle(month == m ? JohoColors.white : JohoColors.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(month == m ? JohoColors.black : Color.clear)
                .clipShape(Squircle(cornerRadius: 8))
                .overlay(
                    Squircle(cornerRadius: 8)
                        .stroke(JohoColors.black, lineWidth: month == m ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func yearButton(year y: Int) -> some View {
        Button(action: { year = y }) {
            Text(String(y))
                .font(.system(size: 14, weight: year == y ? .bold : .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(year == y ? JohoColors.white : JohoColors.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(year == y ? JohoColors.black : Color.clear)
                .clipShape(Squircle(cornerRadius: 6))
                .overlay(
                    Squircle(cornerRadius: 6)
                        .stroke(JohoColors.black, lineWidth: year == y ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func localizedMonthAbbrev(for month: Int) -> String {
        let symbols = DateFormatterCache.monthName.shortMonthSymbols ?? []
        let raw = symbols.indices.contains(month - 1) ? symbols[month - 1] : months[month - 1]
        if locale.language.languageCode?.identifier == "sv" {
            return raw.capitalized(with: locale)
        }
        return raw
    }
}

#Preview {
    MonthPickerSheet(initialMonth: 12, initialYear: 2025) { _, _ in }
}
