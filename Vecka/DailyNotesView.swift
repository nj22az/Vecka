//
//  DailyNotesView.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) Daily Notes
//  Simple, direct note creation with time logging
//

import SwiftUI
import SwiftData

struct DailyNotesView: View {
    let selectedDate: Date
    let isModal: Bool
    let startCreating: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var dayNotes: [DailyNote]

    @State private var isCreating = false
    @State private var didAppear = false

    init(selectedDate: Date, isModal: Bool = true, startCreating: Bool = false) {
        self.selectedDate = selectedDate
        self.isModal = isModal
        self.startCreating = startCreating

        let day = Calendar.iso8601.startOfDay(for: selectedDate)
        _dayNotes = Query(
            filter: #Predicate<DailyNote> { note in
                note.day == day
            },
            sort: \.date,
            order: .reverse
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Page Header
                HStack(alignment: .top) {
                    JohoPageHeader(
                        title: selectedDate.formatted(.dateTime.weekday(.wide)),
                        badge: "NOTES",
                        subtitle: selectedDate.formatted(date: .long, time: .omitted)
                    )

                    Spacer()

                    if isModal {
                        Button {
                            dismiss()
                        } label: {
                            JohoActionButton(icon: "xmark")
                        }
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)
                .safeAreaPadding(.top)

                // Holidays for this day
                if let holidays = holidaysForDay, !holidays.isEmpty {
                    JohoSectionBox(title: "HOLIDAYS", zone: .holidays, icon: "star.fill") {
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                            ForEach(holidays, id: \.id) { holiday in
                                HStack(spacing: JohoDimensions.spacingSM) {
                                    Image(systemName: holiday.symbolName ?? "flag.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(holiday.isRedDay ? JohoColors.pink : JohoColors.cyan)

                                    Text(holiday.displayTitle)
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)

                                    Spacer()

                                    if holiday.isRedDay {
                                        JohoPill(text: "RED DAY", style: .colored(JohoColors.pink), size: .small)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                // Add Note Button
                if !isCreating {
                    Button {
                        withAnimation(AnimationConstants.quickSpring) {
                            isCreating = true
                        }
                    } label: {
                        HStack(spacing: JohoDimensions.spacingSM) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                            Text("Add Note")
                                .font(JohoFont.button)
                        }
                        .foregroundStyle(JohoColors.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .background(JohoColors.black)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                // Inline Note Editor (Create only - edit/delete in month card)
                if isCreating {
                    JohoNoteEditor(
                        day: selectedDate,
                        onSave: { content in
                            createNote(content: content)
                            withAnimation(AnimationConstants.quickSpring) {
                                isCreating = false
                            }
                        },
                        onCancel: {
                            withAnimation(AnimationConstants.quickSpring) {
                                isCreating = false
                            }
                        }
                    )
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                // Existing Notes (display only - edit/delete in month card)
                if !dayNotes.isEmpty {
                    VStack(spacing: JohoDimensions.spacingSM) {
                        ForEach(dayNotes) { note in
                            JohoNoteCard(note: note)
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                // Empty state
                if dayNotes.isEmpty && !isCreating {
                    JohoEmptyState(
                        title: "No Notes",
                        message: "Tap 'Add Note' to create your first note for this day.",
                        icon: "note.text",
                        zone: .notes
                    )
                    .padding(.top, JohoDimensions.spacingXL)
                }
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard !didAppear else { return }
            didAppear = true
            if startCreating {
                withAnimation(AnimationConstants.quickSpring) {
                    isCreating = true
                }
            }
        }
    }

    private var holidaysForDay: [HolidayCacheItem]? {
        let day = Calendar.iso8601.startOfDay(for: selectedDate)
        return HolidayManager.shared.holidayCache[day]
    }

    private func createNote(content: String) {
        guard !content.isEmpty else { return }

        let note = DailyNote(
            date: Date(),
            content: content,
            scheduledAt: nil
        )
        note.day = Calendar.iso8601.startOfDay(for: selectedDate)
        modelContext.insert(note)

        do {
            try modelContext.save()
        } catch {
            Log.w("Failed to save note: \(error.localizedDescription)")
        }
    }
}

// MARK: - 情報デザイン Note Card (Display only - edit/delete in month card)

private struct JohoNoteCard: View {
    let note: DailyNote

    // Category color from note, or default yellow
    private var categoryColor: Color {
        if let hex = note.color {
            return Color(hex: hex)
        }
        return SpecialDayType.note.accentColor
    }

    // Priority symbol (情報デザイン マルバツ)
    private var prioritySymbol: String? {
        guard let priority = note.priority else { return nil }
        switch priority {
        case "high": return "◎"
        case "low": return "△"
        default: return nil  // Normal priority doesn't need symbol
        }
    }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Category color indicator
            Circle()
                .fill(categoryColor)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))

            // Priority symbol if high or low
            if let symbol = prioritySymbol {
                Text(symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(JohoColors.black)
            }

            // Note content
            Text(note.content)
                .font(JohoFont.body)
                .foregroundStyle(JohoColors.black)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Time badge if scheduled
            if let scheduledAt = note.scheduledAt {
                Text(scheduledAt.formatted(date: .omitted, time: .shortened))
                    .font(JohoFont.caption)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
        }
        .padding(JohoDimensions.spacingMD)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }
}

// MARK: - 情報デザイン Note Editor (Create only - edit/delete in month card)

private struct JohoNoteEditor: View {
    let day: Date
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    // Note accent color (cream/yellow from design system)
    private let accentColor = SpecialDayType.note.accentColor

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            // Header with Cancel/Save buttons (情報デザイン style - outside card)
            HStack {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .background(JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                }

                Spacer()

                Button {
                    onSave(text.trimmingCharacters(in: .whitespacesAndNewlines))
                    HapticManager.notification(.success)
                } label: {
                    Text("Save")
                        .font(JohoFont.body.bold())
                        .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.4))
                        .padding(.horizontal, JohoDimensions.spacingLG)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .background(canSave ? accentColor : JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                }
                .disabled(!canSave)
            }

            // Main content card
            VStack(spacing: JohoDimensions.spacingLG) {
                // Title with type indicator (情報デザイン)
                HStack(spacing: JohoDimensions.spacingSM) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
                    Text("New Note")
                        .font(JohoFont.displaySmall)
                        .foregroundStyle(JohoColors.black)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Note icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))

                    Image(systemName: "note.text")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(accentColor)
                }

                // Note content field
                VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                    JohoPill(text: "NOTE", style: .whiteOnBlack, size: .small)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $text)
                            .focused($isFocused)
                            .scrollContentBackground(.hidden)
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black)
                            .frame(minHeight: 100)

                        if text.isEmpty {
                            Text("What's on your mind?")
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(JohoDimensions.spacingSM)
                    .background(JohoColors.white)
                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                    .overlay(
                        Squircle(cornerRadius: JohoDimensions.radiusMedium)
                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                    )
                }
            }
            .padding(JohoDimensions.spacingLG)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
            )
        }
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - 情報デザイン Note Editor Sheet (Standalone - like Event editor)

/// Standalone note editor sheet matching the Event editor pattern
/// Used when creating notes from the Star page add menu
/// Features based on 情報デザイン LATCH method: Time, Category, Hierarchy (priority)
struct JohoNoteEditorSheet: View {
    let initialDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    // Date selection (情報デザイン: Year, Month, Day)
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int

    // Time scheduling
    @State private var hasTime: Bool = false
    @State private var selectedTime: Date = Date()

    // Priority (情報デザイン hierarchy: ◎ ○ △)
    @State private var priority: NotePriority = .normal

    // Category color tag
    @State private var categoryColor: String = "ECC94B"  // Default yellow (note color)

    // Note accent color (cream/yellow from design system)
    private let accentColor = SpecialDayType.note.accentColor

    // Category color palette (semantic colors)
    private let categoryColors: [(name: String, hex: String)] = [
        ("Note", "ECC94B"),      // Yellow - default
        ("Work", "A5F3FC"),      // Cyan - events/tasks
        ("Personal", "E9D5FF"),  // Purple - people
        ("Urgent", "FECDD3"),    // Pink - important
        ("Money", "BBF7D0"),     // Green - financial
        ("Travel", "FED7AA")     // Orange - trips
    ]

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedCategoryColor: Color {
        Color(hex: categoryColor)
    }

    private var selectedDate: Date {
        let calendar = Calendar.current
        return calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)) ?? initialDate
    }

    private var yearRange: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }

    private func daysInMonth(_ month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 31
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: 2024, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }

    init(selectedDate: Date) {
        self.initialDate = selectedDate
        let calendar = Calendar.current
        _selectedYear = State(initialValue: calendar.component(.year, from: selectedDate))
        _selectedMonth = State(initialValue: calendar.component(.month, from: selectedDate))
        _selectedDay = State(initialValue: calendar.component(.day, from: selectedDate))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Floating header with Cancel/Save buttons (情報デザイン style)
            HStack {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, JohoDimensions.spacingMD)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .background(JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                }

                Spacer()

                Button {
                    saveNote()
                    dismiss()
                } label: {
                    Text("Save")
                        .font(JohoFont.body.bold())
                        .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.4))
                        .padding(.horizontal, JohoDimensions.spacingLG)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .background(canSave ? accentColor : JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                }
                .disabled(!canSave)
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(JohoColors.background)

            // Scrollable content
            ScrollView {
                // Main content card
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Title with type indicator (情報デザイン)
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Circle()
                            .fill(selectedCategoryColor)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))
                        Text("New Note")
                            .font(JohoFont.displaySmall)
                            .foregroundStyle(JohoColors.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Note icon with category color
                    ZStack {
                        Circle()
                            .fill(selectedCategoryColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 2))

                        Image(systemName: "note.text")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(selectedCategoryColor)
                    }

                    // Note content field
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "NOTE", style: .whiteOnBlack, size: .small)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $text)
                                .focused($isFocused)
                                .scrollContentBackground(.hidden)
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black)
                                .frame(minHeight: 100)

                            if text.isEmpty {
                                Text("What's on your mind?")
                                    .font(JohoFont.body)
                                    .foregroundStyle(JohoColors.black.opacity(0.6))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(JohoDimensions.spacingSM)
                        .background(JohoColors.white)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
                    }

                    // Date picker (情報デザイン: Year, Month, Day in row)
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "DATE", style: .whiteOnBlack, size: .small)

                        HStack(spacing: JohoDimensions.spacingSM) {
                            // Year
                            VStack(alignment: .leading, spacing: 4) {
                                Text("YEAR")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                Menu {
                                    ForEach(yearRange, id: \.self) { year in
                                        Button { selectedYear = year } label: {
                                            Text(String(year))
                                        }
                                    }
                                } label: {
                                    Text(String(selectedYear))
                                        .font(JohoFont.body)
                                        .monospacedDigit()
                                        .foregroundStyle(JohoColors.black)
                                        .padding(JohoDimensions.spacingSM)
                                        .frame(width: 70)
                                        .background(JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                        )
                                }
                            }

                            // Month
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MONTH")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                Menu {
                                    ForEach(1...12, id: \.self) { month in
                                        Button { selectedMonth = month } label: {
                                            Text(monthName(month))
                                        }
                                    }
                                } label: {
                                    Text(monthName(selectedMonth))
                                        .font(JohoFont.body)
                                        .foregroundStyle(JohoColors.black)
                                        .padding(JohoDimensions.spacingSM)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                        )
                                }
                            }

                            // Day
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DAY")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(JohoColors.black.opacity(0.6))

                                Menu {
                                    ForEach(1...daysInMonth(selectedMonth, year: selectedYear), id: \.self) { day in
                                        Button { selectedDay = day } label: {
                                            Text("\(day)")
                                        }
                                    }
                                } label: {
                                    Text("\(selectedDay)")
                                        .font(JohoFont.body)
                                        .monospacedDigit()
                                        .foregroundStyle(JohoColors.black)
                                        .padding(JohoDimensions.spacingSM)
                                        .frame(width: 50)
                                        .background(JohoColors.white)
                                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                        .overlay(
                                            Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                        )
                                }
                            }
                        }
                    }

                    // Category color picker (情報デザイン LATCH: Category)
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "CATEGORY", style: .whiteOnBlack, size: .small)

                        HStack(spacing: 10) {
                            ForEach(categoryColors, id: \.hex) { color in
                                Button {
                                    categoryColor = color.hex
                                    HapticManager.selection()
                                } label: {
                                    Circle()
                                        .fill(Color(hex: color.hex))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(JohoColors.black, lineWidth: categoryColor == color.hex ? 3 : 1.5)
                                        )
                                }
                            }
                        }
                    }

                    // Priority picker (情報デザイン LATCH: Hierarchy using マルバツ symbols)
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        JohoPill(text: "PRIORITY", style: .whiteOnBlack, size: .small)

                        HStack(spacing: JohoDimensions.spacingMD) {
                            ForEach(NotePriority.allCases, id: \.self) { p in
                                Button {
                                    priority = p
                                    HapticManager.selection()
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(p.symbol)
                                            .font(.system(size: 16, weight: .bold))
                                        Text(p.label)
                                            .font(JohoFont.bodySmall)
                                    }
                                    .foregroundStyle(priority == p ? JohoColors.white : JohoColors.black)
                                    .padding(.horizontal, JohoDimensions.spacingMD)
                                    .padding(.vertical, JohoDimensions.spacingSM)
                                    .background(priority == p ? JohoColors.black : JohoColors.white)
                                    .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                                    .overlay(
                                        Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                            .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                                    )
                                }
                            }
                        }
                    }

                    // Time section (情報デザイン LATCH: Time)
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                        HStack {
                            JohoPill(text: "TIME", style: .whiteOnBlack, size: .small)
                            Spacer()
                            JohoToggle(isOn: $hasTime, accentColor: accentColor)
                        }

                        if hasTime {
                            HStack {
                                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .tint(accentColor)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(JohoDimensions.spacingLG)
                .background(JohoColors.white)
                .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
                .overlay(
                    Squircle(cornerRadius: JohoDimensions.radiusLarge)
                        .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
                )
            }
            .padding(.horizontal, JohoDimensions.spacingLG)
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .onAppear {
            isFocused = true
            // Set initial time to now
            selectedTime = combineDayAndTime(day: selectedDate, time: Date())
        }
    }

    // NOTE: JohoToggle is now in JohoDesignSystem.swift

    private func combineDayAndTime(day: Date, time: Date) -> Date {
        let calendar = Calendar.iso8601
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: timeComponents.hour ?? 9,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: day
        ) ?? day
    }

    private func saveNote() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let note = DailyNote(
            date: Date(),
            content: trimmed,
            scheduledAt: hasTime ? selectedTime : nil
        )
        note.day = Calendar.iso8601.startOfDay(for: selectedDate)
        // Store priority and category color in the note
        note.priority = priority.rawValue
        note.color = categoryColor
        modelContext.insert(note)

        do {
            try modelContext.save()
            HapticManager.notification(.success)
        } catch {
            Log.w("Failed to save note: \(error.localizedDescription)")
        }
    }
}

// MARK: - Note Priority (情報デザイン マルバツ hierarchy)

enum NotePriority: String, CaseIterable {
    case high = "high"
    case normal = "normal"
    case low = "low"

    var symbol: String {
        switch self {
        case .high: return "◎"    // Primary - most important
        case .normal: return "○"  // Secondary - standard
        case .low: return "△"     // Tertiary - optional
        }
    }

    var label: String {
        switch self {
        case .high: return "High"
        case .normal: return "Normal"
        case .low: return "Low"
        }
    }
}

#Preview {
    NavigationStack {
        DailyNotesView(selectedDate: Date(), isModal: true)
            .modelContainer(for: DailyNote.self, inMemory: true)
    }
}
