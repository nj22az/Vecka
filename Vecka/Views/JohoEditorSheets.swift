//
//  JohoEditorSheets.swift
//  Vecka
//
//  情報デザイン: Shared editor sheets for calendar entries
//  Extracted from SpecialDaysListView for clean architecture
//
//  Contains:
//  - JohoUndoToast: Undo action toast notification
//  - JohoIconPickerSheet: SF Symbol icon picker
//  - JohoSpecialDayEditorSheet: Holiday/Observance/Memo editor
//  - JohoAddSpecialDaySheet: Entry type menu
//

import SwiftUI
import SwiftData

// MARK: - Shared Undo Toast (情報デザイン)

struct JohoUndoToast: View {
    let message: String
    let onUndo: () -> Void
    let onDismiss: () -> Void

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            Text(message)
                .font(JohoFont.body)
                .foregroundStyle(colors.primaryInverted)
                .lineLimit(1)

            Spacer()

            Button {
                HapticManager.selection()
                onUndo()
            } label: {
                Text("Undo")
                    .font(JohoFont.body.bold())
                    .foregroundStyle(JohoColors.cyan)
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(colors.primaryInverted.opacity(0.6))
            }
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.vertical, JohoDimensions.spacingMD)
        .background(colors.surfaceInverted)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, JohoDimensions.spacingLG)
    }
}

// MARK: - Icon Picker Sheet (情報デザイン)

struct JohoIconPickerSheet: View {
    @Binding var selectedSymbol: String
    let accentColor: Color
    let lightBackground: Color
    /// 情報デザイン: Icons to exclude from picker (category defaults should not be selectable)
    var excludedSymbols: Set<String> = []
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let symbolCategories: [(name: String, symbols: [String])] = [
        ("MARU-BATSU", ["circle", "circle.fill", "xmark", "xmark.circle.fill", "triangle", "triangle.fill", "square", "square.fill", "diamond", "diamond.fill"]),
        ("EVENTS", ["star.fill", "sparkles", "gift.fill", "birthday.cake.fill", "party.popper.fill", "balloon.fill", "heart.fill", "bell.fill", "calendar.badge.clock"]),
        ("NATURE", ["leaf.fill", "camera.macro", "sun.max.fill", "moon.fill", "snowflake", "cloud.sun.fill", "flame.fill", "drop.fill"]),
        ("PEOPLE", ["person.fill", "person.2.fill", "figure.stand", "heart.circle.fill", "hand.raised.fill"]),
        ("TIME", ["calendar", "clock.fill", "hourglass", "timer", "sunrise.fill", "sunset.fill"]),
    ]

    /// 情報デザイン: Filter out excluded symbols (category defaults)
    private var filteredCategories: [(name: String, symbols: [String])] {
        symbolCategories.map { category in
            (name: category.name, symbols: category.symbols.filter { !excludedSymbols.contains($0) })
        }.filter { !$0.symbols.isEmpty }
    }

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: JohoDimensions.spacingSM)]

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Header
                VStack(spacing: JohoDimensions.spacingSM) {
                    HStack {
                        Button { dismiss() } label: {
                            Text("Cancel")
                                .font(JohoFont.body)
                                .foregroundStyle(colors.primary)
                                .padding(.horizontal, JohoDimensions.spacingMD)
                                .padding(.vertical, JohoDimensions.spacingSM)
                                .background(colors.surface)
                                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                .overlay(
                                    Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                        .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                                )
                        }
                        Spacer()
                    }

                    Text("Choose Icon")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(colors.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(JohoDimensions.spacingLG)
                .background(colors.surface)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(colors.border, lineWidth: JohoDimensions.borderThick)
                )
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)

                // Categories (情報デザイン: filtered to exclude category defaults)
                ForEach(filteredCategories, id: \.name) { category in
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: category.name, style: .whiteOnBlack, size: .small)

                        LazyVGrid(columns: columns, spacing: JohoDimensions.spacingSM) {
                            ForEach(category.symbols, id: \.self) { symbol in
                                Button {
                                    selectedSymbol = symbol
                                    HapticManager.selection()
                                    dismiss()
                                } label: {
                                    Image(systemName: symbol)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundStyle(selectedSymbol == symbol ? accentColor : colors.primary)
                                        .johoTouchTarget(52)
                                        .background(selectedSymbol == symbol ? lightBackground : colors.surface)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(colors.border, lineWidth: selectedSymbol == symbol ? JohoDimensions.borderMedium : JohoDimensions.borderThin)
                                        )
                                }
                            }
                        }
                    }
                    .padding(JohoDimensions.spacingMD)
                    .background(colors.surface)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusLarge)
                            .stroke(colors.border, lineWidth: JohoDimensions.borderMedium)
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                Spacer(minLength: JohoDimensions.spacingXL)
            }
        }
        .johoBackground()
        .presentationCornerRadius(20)
        .presentationDetents([.large])
    }
}

// MARK: - Special Day Editor Sheet (情報デザイン)

struct JohoSpecialDayEditorSheet: View {
    enum Mode {
        case create
        case edit(name: String, date: Date, symbol: String, iconColor: String?, notes: String?, region: String)
    }

    let mode: Mode
    let type: SpecialDayType
    let defaultRegion: String
    let onSave: (String, Date, String, String?, String?, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // 情報デザイン: Access enabled regions for region picker
    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])

    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = 1
    @State private var selectedDay: Int = 1
    @State private var selectedSymbol: String = "star.fill"
    @State private var selectedRegion: String = ""
    @State private var showingIconPicker = false

    /// 情報デザイン: Enabled regions for the region picker (PERSONAL + user-selected regions)
    private var enabledRegions: [String] {
        holidayRegions.expandedRegions
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !name.trimmed.isEmpty
    }

    private var headerTitle: String {
        let typeName = String(type.title.dropLast()).uppercased()
        return isEditing ? "EDIT \(typeName)" : "NEW \(typeName)"
    }

    private var headerSubtitle: String {
        isEditing ? "Update details" : "Set date & details"
    }

    private var namePlaceholder: String {
        switch type {
        case .holiday: return "Holiday name"
        case .observance: return "Observance name"
        case .birthday: return "Name"
        case .memo, .note, .event: return "Memo text"
        case .trip: return "Trip destination"
        case .expense: return "Expense description"
        }
    }

    private var selectedDate: Date {
        Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)) ?? Date()
    }

    private var yearRange: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }

    init(mode: Mode, type: SpecialDayType, defaultRegion: String, onSave: @escaping (String, Date, String, String?, String?, String) -> Void) {
        self.mode = mode
        self.type = type
        self.defaultRegion = defaultRegion
        self.onSave = onSave

        let calendar = Calendar.current
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _notes = State(initialValue: "")
            _selectedYear = State(initialValue: calendar.component(.year, from: Date()))
            _selectedMonth = State(initialValue: calendar.component(.month, from: Date()))
            _selectedDay = State(initialValue: calendar.component(.day, from: Date()))
            _selectedSymbol = State(initialValue: type.defaultIcon)
            _selectedRegion = State(initialValue: defaultRegion)
        case .edit(let editName, let editDate, let editSymbol, _, let editNotes, let editRegion):
            _name = State(initialValue: editName)
            _notes = State(initialValue: editNotes ?? "")
            _selectedYear = State(initialValue: calendar.component(.year, from: editDate))
            _selectedMonth = State(initialValue: calendar.component(.month, from: editDate))
            _selectedDay = State(initialValue: calendar.component(.day, from: editDate))
            _selectedSymbol = State(initialValue: editSymbol)
            _selectedRegion = State(initialValue: editRegion)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: JohoDimensions.spacingLG)

            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .johoTouchTarget()
                    }

                    Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

                    HStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: type.defaultIcon)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(type.accentColor)
                            .frame(width: 36, height: 36)
                            .background(type.lightBackground)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(colors.border, lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(headerTitle)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(colors.primary)
                            Text(headerSubtitle)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.6))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                    .frame(maxHeight: .infinity)

                    Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

                    Button {
                        let notesValue = notes.trimmed
                        onSave(name.trimmed, selectedDate, selectedSymbol, nil, notesValue.isEmpty ? nil : notesValue, selectedRegion)
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(canSave ? colors.primaryInverted : colors.primary.opacity(0.4))
                            .frame(width: 56, height: 32)
                            .background(canSave ? type.accentColor : colors.surface)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(colors.border, lineWidth: 1.5))
                    }
                    .disabled(!canSave)
                    .frame(width: 72).frame(maxHeight: .infinity)
                }
                .frame(height: 56)
                .background(type.accentColor.opacity(0.7))

                Rectangle().fill(colors.border).frame(height: 1.5)

                // Name row
                HStack(spacing: 0) {
                    Circle().fill(type.accentColor).frame(width: 10, height: 10)
                        .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
                        .frame(width: 40).frame(maxHeight: .infinity)

                    Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

                    TextField(namePlaceholder, text: $name)
                        .font(JohoFont.body)
                        .foregroundStyle(colors.primary)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 48)
                .background(type.lightBackground)

                Rectangle().fill(colors.border).frame(height: 1.5)

                // Date row
                HStack(spacing: 0) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 40).frame(maxHeight: .infinity)

                    Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

                    Menu {
                        ForEach(yearRange, id: \.self) { year in
                            Button { selectedYear = year } label: { Text(String(year)) }
                        }
                    } label: {
                        Text(String(selectedYear))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(colors.primary)
                            .frame(maxWidth: .infinity).frame(maxHeight: .infinity)
                    }

                    Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

                    Menu {
                        ForEach(1...12, id: \.self) { month in
                            Button { selectedMonth = month } label: { Text(monthName(month)) }
                        }
                    } label: {
                        Text(monthName(selectedMonth))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .frame(maxWidth: .infinity).frame(maxHeight: .infinity)
                    }

                    Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

                    Menu {
                        ForEach(1...daysInMonth(selectedMonth, year: selectedYear), id: \.self) { day in
                            Button { selectedDay = day } label: { Text("\(day)") }
                        }
                    } label: {
                        Text("\(selectedDay)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(colors.primary)
                            .frame(width: 44).frame(maxHeight: .infinity)
                    }
                }
                .frame(height: 48)
                .background(type.lightBackground)

                Rectangle().fill(colors.border).frame(height: 1.5)

                // Icon picker row
                Button {
                    showingIconPicker = true
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 0) {
                        Image(systemName: selectedSymbol)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(type.accentColor)
                            .frame(width: 40).frame(maxHeight: .infinity)

                        Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

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
                    .background(type.lightBackground)
                }
                .buttonStyle(.plain)

                // 情報デザイン: Region picker row (only for holidays/observances)
                if type == .holiday || type == .observance {
                    Rectangle().fill(colors.border).frame(height: 1.5)
                    regionPickerRow
                }
            }
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(Squircle(cornerRadius: JohoDimensions.radiusLarge).stroke(colors.border, lineWidth: JohoDimensions.borderThick))
            .padding(.horizontal, JohoDimensions.spacingLG)

            Spacer()
        }
        .johoBackground()
        .navigationBarHidden(true)
        .sheet(isPresented: $showingIconPicker) {
            // 情報デザイン: Exclude category default icon from picker
            JohoIconPickerSheet(
                selectedSymbol: $selectedSymbol,
                accentColor: type.accentColor,
                lightBackground: type.lightBackground,
                excludedSymbols: [type.defaultIcon]
            )
        }
    }

    // MARK: - Region Picker Row (情報デザイン: Horizontal scrolling chips)

    private var regionPickerRow: some View {
        HStack(spacing: 0) {
            Image(systemName: "globe")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .frame(width: 40).frame(maxHeight: .infinity)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(maxHeight: .infinity)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(enabledRegions, id: \.self) { region in
                        regionChip(region, label: region)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 48)
        .background(type.lightBackground)
    }

    private func regionChip(_ code: String, label: String) -> some View {
        Button {
            selectedRegion = code
            HapticManager.selection()
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(selectedRegion == code ? colors.primaryInverted : colors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selectedRegion == code ? type.accentColor : colors.surface)
                .clipShape(Squircle(cornerRadius: 8))
                .overlay(Squircle(cornerRadius: 8).stroke(colors.border, lineWidth: 1.5))
        }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let date = Calendar.current.date(from: DateComponents(year: 2024, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }

    private func daysInMonth(_ month: Int, year: Int = Calendar.current.component(.year, from: Date())) -> Int {
        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 31
    }
}

// MARK: - Add Special Day Sheet (情報デザイン)

/// Input option data for add sheet
struct JohoInputOption: Identifiable {
    let id = UUID()
    let icon: String
    let code: String
    let label: String
    let meta: String
    let color: Color
    let action: () -> Void
}

struct JohoAddSpecialDaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    let onSelectHoliday: () -> Void
    let onSelectEntry: () -> Void
    let onSelectBirthday: () -> Void

    private var options: [JohoInputOption] {
        [
            JohoInputOption(icon: "square.and.pencil", code: "MEM", label: "MEMO", meta: "NOTE / TRIP / EXPENSE / EVENT", color: JohoColors.cyan, action: onSelectEntry),
            JohoInputOption(icon: "star.fill", code: "HOL", label: "HOLIDAY", meta: "OFFICIAL & OBSERVANCE", color: SpecialDayType.holiday.accentColor, action: onSelectHoliday),
            JohoInputOption(icon: "birthday.cake.fill", code: "BDY", label: "BIRTHDAY", meta: "ADD TO CONTACTS", color: SpecialDayType.birthday.accentColor, action: onSelectBirthday),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("ADD")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(colors.primaryInverted)
                    .padding(.leading, JohoDimensions.spacingMD)

                Spacer()

                Button { dismiss() } label: {
                    Text("×")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primaryInverted)
                        .johoTouchTarget()
                }
            }
            .frame(height: 48)
            .background(colors.surfaceInverted)

            Rectangle().fill(colors.border).frame(height: 3)

            VStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    Button {
                        HapticManager.selection()
                        option.action()
                    } label: {
                        JohoBentoOptionRow(option: option, colors: colors)
                    }
                    .buttonStyle(.plain)

                    if index < options.count - 1 {
                        Rectangle().fill(colors.border).frame(height: 1.5)
                    }
                }
            }
        }
        .background(colors.surface)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
        .overlay(Squircle(cornerRadius: JohoDimensions.radiusLarge).stroke(colors.border, lineWidth: 3))
        .padding(.horizontal, JohoDimensions.spacingMD)
        .padding(.vertical, JohoDimensions.spacingLG)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
    }
}

/// Bento option row for add sheet
struct JohoBentoOptionRow: View {
    let option: JohoInputOption
    let colors: JohoScheme

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(option.color).frame(width: 48, height: 48)
                Image(systemName: option.icon).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(colors.primaryInverted)
            }
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(colors.border, lineWidth: 2))
            .padding(.leading, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)

            Rectangle().fill(colors.border).frame(width: 1.5).frame(height: 48).padding(.horizontal, JohoDimensions.spacingSM)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(option.code)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(colors.primaryInverted)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(option.color)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(colors.border, lineWidth: 1.5))

                    Text(option.label)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)
                }

                Text(option.meta)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(0.5))
            }

            Spacer()

            Rectangle().fill(colors.border).frame(width: 1.5).frame(height: 48).padding(.trailing, JohoDimensions.spacingSM)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary)
                .frame(width: 44, height: 48)
                .padding(.trailing, JohoDimensions.spacingXS)
        }
        .frame(height: 72)
        .background(colors.surface)
    }
}
