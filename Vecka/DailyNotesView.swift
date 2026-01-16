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
                // Page Header (情報デザイン: White text on black background)
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: JohoDimensions.spacingSM) {
                            JohoPill(text: "NOTES", style: .whiteOnBlack, size: .large)
                        }
                        Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                            .font(JohoFont.headline)
                            .foregroundStyle(JohoColors.white)
                        Text(selectedDate.formatted(date: .long, time: .omitted))
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.white.opacity(0.7))
                    }

                    Spacer()

                    if isModal {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(JohoColors.white)
                                .frame(width: 32, height: 32)
                                .background(JohoColors.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)
                .safeAreaPadding(.top)

                // Holidays for this day (in white card)
                if let holidays = holidaysForDay, !holidays.isEmpty {
                    JohoCard(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium) {
                        JohoSectionBox(title: "HOLIDAYS", zone: .holidays) {
                            VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                                ForEach(holidays, id: \.id) { holiday in
                                    HStack(spacing: JohoDimensions.spacingSM) {
                                        Image(systemName: holiday.symbolName ?? "flag.fill")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(holiday.isBankHoliday ? JohoColors.pink : JohoColors.cyan)

                                        Text(holiday.displayTitle)
                                            .font(JohoFont.body)
                                            .foregroundStyle(JohoColors.black)

                                        Spacer()

                                        if holiday.isBankHoliday {
                                            JohoPill(text: "RED DAY", style: .colored(JohoColors.pink), size: .small)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                // Add Note Button (情報デザイン: Yellow accent for notes)
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
                        .foregroundStyle(JohoColors.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, JohoDimensions.spacingMD)
                        .background(JohoColors.yellow)
                        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
                        .overlay(
                            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
                        )
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

                // Existing Notes in white cards (情報デザイン: White cards on black bg)
                if !dayNotes.isEmpty {
                    JohoCard(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium) {
                        JohoSectionBox(title: "NOTES", zone: .notes) {
                            VStack(spacing: JohoDimensions.spacingSM) {
                                ForEach(dayNotes) { note in
                                    JohoNoteCard(note: note)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }

                // Empty state
                if dayNotes.isEmpty && !isCreating {
                    JohoCard(cornerRadius: JohoDimensions.radiusMedium, borderWidth: JohoDimensions.borderMedium) {
                        VStack(spacing: JohoDimensions.spacingMD) {
                            Image(systemName: "note.text")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(JohoColors.yellow)
                            Text("No Notes")
                                .font(JohoFont.headline)
                                .foregroundStyle(JohoColors.black)
                            Text("Tap 'Add Note' to create your first note for this day.")
                                .font(JohoFont.body)
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(JohoDimensions.spacingLG)
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                    .padding(.top, JohoDimensions.spacingXL)
                }
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()  // 情報デザイン: BLACK background for AMOLED
        .scrollContentBackground(.hidden)
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
        // Use Calendar.current to match HolidayManager cache keying
        let day = Calendar.current.startOfDay(for: selectedDate)
        return HolidayManager.cache[day]
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
        !text.trimmed.isEmpty
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
                    onSave(text.trimmed)
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

    // Icon selection
    @State private var selectedSymbol: String = "note.text"
    @State private var showingIconPicker = false

    private let calendar = Calendar.current

    // 情報デザイン: Notes ALWAYS use yellow color scheme
    private var noteAccentColor: Color { SpecialDayType.note.accentColor }
    private var noteLightBackground: Color { SpecialDayType.note.lightBackground }

    private var canSave: Bool {
        !text.trimmed.isEmpty
    }

    private var selectedDate: Date {
        let components = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
        return calendar.date(from: components) ?? initialDate
    }

    private var yearRange: [Int] {
        let current = calendar.component(.year, from: Date())
        return Array((current - 10)...(current + 10))
    }

    private func daysInMonth(_ month: Int, year: Int) -> Int {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let tempDate = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: tempDate) else {
            return 31
        }
        return range.count
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let components = DateComponents(year: 2024, month: month, day: 1)
        let tempDate = calendar.date(from: components) ?? Date()
        return formatter.string(from: tempDate)
    }

    init(selectedDate: Date) {
        self.initialDate = selectedDate
        let calendar = Calendar.current
        _selectedYear = State(initialValue: calendar.component(.year, from: selectedDate))
        _selectedMonth = State(initialValue: calendar.component(.month, from: selectedDate))
        _selectedDay = State(initialValue: calendar.component(.day, from: selectedDate))
    }

    var body: some View {
        // 情報デザイン: UNIFIED BENTO PILLBOX - entire editor is one compartmentalized box
        VStack(spacing: 0) {
            Spacer().frame(height: JohoDimensions.spacingLG)

            // UNIFIED BENTO CONTAINER
            VStack(spacing: 0) {
                // ═══════════════════════════════════════════════════════════════
                // HEADER ROW: [<] | [icon] Title/Subtitle | [Save]
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Back button (44pt)
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(JohoColors.black)
                            .johoTouchTarget()
                    }

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // CENTER: Icon + Title/Subtitle
                    HStack(spacing: JohoDimensions.spacingSM) {
                        // Type icon in colored box
                        Image(systemName: "note.text")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(noteAccentColor)
                            .frame(width: 36, height: 36)
                            .background(noteLightBackground)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("NEW NOTE")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                            Text("Set date & details")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, JohoDimensions.spacingSM)
                    .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // RIGHT: Save button (72pt)
                    Button {
                        saveNote()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(canSave ? JohoColors.white : JohoColors.black.opacity(0.4))
                            .frame(width: 56, height: 32)
                            .background(canSave ? noteAccentColor : JohoColors.white)
                            .clipShape(Squircle(cornerRadius: 8))
                            .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1.5))
                    }
                    .disabled(!canSave)
                    .frame(width: 72)
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 56)
                .background(noteAccentColor.opacity(0.7))  // 情報デザイン: Darker header

                // Thick divider after header
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // NOTE CONTENT ROW: Multi-line text editor
                // ═══════════════════════════════════════════════════════════════
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .focused($isFocused)
                        .scrollContentBackground(.hidden)
                        .font(JohoFont.body)
                        .foregroundStyle(JohoColors.black)
                        .padding(JohoDimensions.spacingMD)

                    if text.isEmpty {
                        Text("What's on your mind?")
                            .font(JohoFont.body)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                            .padding(.top, JohoDimensions.spacingMD + 8)
                            .padding(.leading, JohoDimensions.spacingMD + 4)
                            .allowsHitTesting(false)
                    }
                }
                .frame(minHeight: 120)
                .background(noteLightBackground)

                // 情報デザイン: Row divider (solid black)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // DATE ROW: [📅] | Year | Month | Day (compartmentalized)
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: Calendar icon (40pt)
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // YEAR compartment
                    Menu {
                        ForEach(yearRange, id: \.self) { year in
                            Button { selectedYear = year } label: { Text(String(year)) }
                        }
                    } label: {
                        Text(String(selectedYear))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(JohoColors.black)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // MONTH compartment
                    Menu {
                        ForEach(1...12, id: \.self) { month in
                            Button { selectedMonth = month } label: { Text(monthName(month)) }
                        }
                    } label: {
                        Text(monthName(selectedMonth))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }

                    // WALL
                    Rectangle()
                        .fill(JohoColors.black)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // DAY compartment
                    Menu {
                        ForEach(1...daysInMonth(selectedMonth, year: selectedYear), id: \.self) { day in
                            Button { selectedDay = day } label: { Text("\(day)") }
                        }
                    } label: {
                        Text("\(selectedDay)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(JohoColors.black)
                            .frame(width: 44)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(height: 48)
                .background(noteLightBackground)

                // 情報デザイン: Row divider (solid black)
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // ═══════════════════════════════════════════════════════════════
                // ICON PICKER ROW: [icon] | Tap to change icon [>]
                // ═══════════════════════════════════════════════════════════════
                Button {
                    showingIconPicker = true
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 0) {
                        // LEFT: Current icon (40pt)
                        Image(systemName: selectedSymbol)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(noteAccentColor)
                            .frame(width: 40)
                            .frame(maxHeight: .infinity)

                        // WALL
                        Rectangle()
                            .fill(JohoColors.black)
                            .frame(width: 1.5)
                            .frame(maxHeight: .infinity)

                        // CENTER: Hint text
                        Text("Tap to change icon")
                            .font(JohoFont.caption)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                            .padding(.leading, JohoDimensions.spacingMD)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(JohoColors.black.opacity(0.4))
                            .padding(.trailing, JohoDimensions.spacingMD)
                    }
                    .frame(height: 48)
                    .background(noteLightBackground)
                }
                .buttonStyle(.plain)
            }
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusLarge))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusLarge)
                    .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
            )
            .padding(.horizontal, JohoDimensions.spacingLG)

            Spacer()
        }
        .johoBackground()  // 情報デザイン: BLACK background for AMOLED
        .scrollContentBackground(.hidden)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingIconPicker) {
            JohoIconPickerSheet(
                selectedSymbol: $selectedSymbol,
                accentColor: noteAccentColor,
                lightBackground: noteLightBackground
            )
        }
        .onAppear {
            isFocused = true
        }
    }

    private func saveNote() {
        let trimmed = text.trimmed
        guard !trimmed.isEmpty else { return }

        let note = DailyNote(
            date: Date(),
            content: trimmed,
            scheduledAt: nil
        )
        note.day = Calendar.iso8601.startOfDay(for: selectedDate)
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
