//
//  DailyNotesView.swift
//  Vecka
//
//  Apple-style per-day notes: multiple entries per day with a focused editor.
//

import SwiftUI
import SwiftData

struct DailyNotesView: View {
    let selectedDate: Date
    let isModal: Bool
    let startCreating: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query private var dayNotes: [DailyNote]

    @State private var isPresentingNewNote = false
    @State private var editingNote: DailyNote?
    @State private var didAppear = false

    init(selectedDate: Date, isModal: Bool = true, startCreating: Bool = false) {
        self.selectedDate = selectedDate
        self.isModal = isModal
        self.startCreating = startCreating

        let day = Calendar.current.startOfDay(for: selectedDate)
        _dayNotes = Query(
            filter: #Predicate<DailyNote> { note in
                note.day == day
            },
            sort: \.date,
            order: .reverse
        )
    }

    var body: some View {
        List {
            if let holidayRow = holidayRow {
                Section {
                    holidayRow
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            }

            if !dayNotes.isEmpty {
                Section {
                    ForEach(dayNotes) { note in
                        Button {
                            editingNote = note
                        } label: {
                            NoteRow(note: note)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(Localization.editNote, systemImage: "pencil") {
                                editingNote = note
                            }
                            Button(role: .destructive) {
                                delete(note)
                            } label: {
                                Label(Localization.delete, systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(note)
                            } label: {
                                Label(Localization.delete, systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(selectedDate.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColors.background)
        .toolbar {
            if isModal {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Localization.done) { dismiss() }
                        .fontWeight(.semibold)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingNewNote = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel(Localization.addNote)
            }
        }
        .sheet(isPresented: $isPresentingNewNote) {
            NavigationStack {
                NoteEditorView(
                    mode: .new(day: Calendar.current.startOfDay(for: selectedDate))
                )
            }
        }
        .sheet(item: $editingNote) { note in
            NavigationStack {
                NoteEditorView(mode: .edit(note: note))
            }
        }
        .onAppear {
            guard !didAppear else { return }
            didAppear = true
            if startCreating {
                isPresentingNewNote = true
            }
        }
    }

    private var holidayRow: AnyView? {
        let day = Calendar.current.startOfDay(for: selectedDate)
        let holidays = HolidayManager.shared.holidayCache[day] ?? []
        guard !holidays.isEmpty else { return nil }

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                ForEach(holidays) { holiday in
                    HStack(spacing: 12) {
                        Image(systemName: holiday.symbolName ?? (holiday.isRedDay ? "flag.fill" : "flag"))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(holiday.isRedDay ? .red : AppColors.accentBlue)

                        Text(holiday.displayTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                }
            }
        )
    }

    private func delete(_ note: DailyNote) {
        modelContext.delete(note)
        do {
            try modelContext.save()
        } catch {
            Log.w("Failed to delete note: \(error.localizedDescription)")
        }
    }
}

private struct NoteRow: View {
    let note: DailyNote

    var body: some View {
        let (title, subtitle) = titleAndSubtitle(from: note.content)
        let timeSource = note.scheduledAt ?? note.date

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(timeSource.formatted(date: .omitted, time: .shortened))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                if note.pinnedToDashboard == true {
                    Image(systemName: "pin.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if let color = note.color {
                    Circle()
                        .fill(colorForName(color))
                        .frame(width: 8, height: 8)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: note.symbolName ?? NoteSymbolCatalog.defaultSymbol)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        default: return AppColors.accentBlue
        }
    }

    private func titleAndSubtitle(from raw: String) -> (String, String?) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ("", nil) }

        if let newlineIndex = trimmed.firstIndex(where: \.isNewline) {
            let firstLine = String(trimmed[..<newlineIndex])
            let remainder = String(trimmed[trimmed.index(after: newlineIndex)...])
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return (firstLine, remainder.isEmpty ? nil : remainder)
        }

        let maxTitleLength = 80
        guard trimmed.count > maxTitleLength else {
            return (trimmed, nil)
        }

        let hardSplitIndex = trimmed.index(trimmed.startIndex, offsetBy: maxTitleLength)
        let prefix = trimmed[..<hardSplitIndex]
        let wordBoundaryIndex = prefix.lastIndex(where: { $0.isWhitespace })

        let splitIndex: String.Index
        if let wordBoundaryIndex, trimmed.distance(from: trimmed.startIndex, to: wordBoundaryIndex) >= 40 {
            splitIndex = wordBoundaryIndex
        } else {
            splitIndex = hardSplitIndex
        }

        let title = String(trimmed[..<splitIndex]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let subtitle = String(trimmed[splitIndex...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return (title, subtitle.isEmpty ? nil : subtitle)
    }
}

private struct NoteEditorView: View {
    enum Mode {
        case new(day: Date)
        case edit(note: DailyNote)
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var text: String = ""
    @State private var selectedColor: String? = nil
    @State private var selectedSymbolName: String? = nil
    @State private var isPinnedToDashboard = false
    @State private var isAllDay = true
    @State private var scheduledDay = Date()
    @State private var scheduledTime = Date()
    @State private var showDetails = false
    @FocusState private var isFocused: Bool
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()

            TextEditor(text: $text)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .background(AppColors.background)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(Localization.notesPlaceholder)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            hydrate()
            isFocused = true
        }
        .sheet(isPresented: $showDetails) {
            NavigationStack {
                NoteDetailsView(
                    day: $scheduledDay,
                    pinnedToDashboard: $isPinnedToDashboard,
                    allDay: $isAllDay,
                    time: $scheduledTime,
                    color: $selectedColor,
                    symbolName: $selectedSymbolName,
                    isEditing: isEditing,
                    onRequestDelete: {
                        showDeleteConfirmation = true
                    }
                )
            }
        }
        .alert(Localization.delete, isPresented: $showDeleteConfirmation) {
            Button(Localization.delete, role: .destructive) {
                deleteIfEditing()
                dismiss()
            }
            Button(Localization.cancel, role: .cancel) {}
        } message: {
            Text(Localization.deleteNoteConfirmation)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.cancel) { dismiss() }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(Localization.save) {
                    save()
                    dismiss()
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDetails = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel(Localization.noteDetails)
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var title: String {
        switch mode {
        case .new:
            return Localization.createNote
        case .edit:
            return Localization.editNote
        }
    }

    private func hydrate() {
        switch mode {
        case .new(let day):
            text = ""
            selectedColor = nil
            selectedSymbolName = nil
            isPinnedToDashboard = false
            isAllDay = true
            scheduledDay = day
            scheduledTime = defaultTime(for: day)
        case .edit(let note):
            text = note.content
            selectedColor = note.color
            selectedSymbolName = note.symbolName
            isPinnedToDashboard = note.pinnedToDashboard ?? false
            if let scheduledAt = note.scheduledAt {
                isAllDay = false
                scheduledDay = Calendar.current.startOfDay(for: scheduledAt)
                scheduledTime = scheduledAt
            } else {
                isAllDay = true
                scheduledDay = note.day
                scheduledTime = defaultTime(for: note.day)
            }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch mode {
        case .new:
            let now = Date()
            let note = DailyNote(
                date: now,
                content: trimmed,
                color: selectedColor,
                symbolName: selectedSymbolName
            )
            note.day = scheduledDay
            note.pinnedToDashboard = isPinnedToDashboard
            note.scheduledAt = isAllDay ? nil : combine(day: scheduledDay, time: scheduledTime)
            modelContext.insert(note)

        case .edit(let note):
            note.content = trimmed
            note.color = selectedColor
            note.symbolName = selectedSymbolName
            note.lastModified = Date()
            note.pinnedToDashboard = isPinnedToDashboard
            note.day = scheduledDay
            note.scheduledAt = isAllDay ? nil : combine(day: scheduledDay, time: scheduledTime)
        }

        do {
            try modelContext.save()
        } catch {
            Log.w("Failed to save note: \(error.localizedDescription)")
        }
    }

    private func deleteIfEditing() {
        guard case .edit(let note) = mode else { return }
        modelContext.delete(note)
        try? modelContext.save()
    }

    private func defaultTime(for day: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
    }

    private func combine(day: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: day
        ) ?? day
    }
}

private struct NoteDetailsView: View {
    @Binding var day: Date
    @Binding var pinnedToDashboard: Bool
    @Binding var allDay: Bool
    @Binding var time: Date
    @Binding var color: String?
    @Binding var symbolName: String?
    let isEditing: Bool
    let onRequestDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let calendar = Calendar.current
        let dayBinding = Binding<Date>(
            get: { day },
            set: { newValue in
                day = calendar.startOfDay(for: newValue)
            }
        )

        Form {
            Section {
                DatePicker(Localization.noteDate, selection: dayBinding, displayedComponents: [.date])

                Toggle(Localization.noteAllDay, isOn: $allDay)

                if !allDay {
                    DatePicker(Localization.noteTime, selection: $time, displayedComponents: [.hourAndMinute])
                }
            } header: {
                Text(Localization.noteSchedule)
            }

            Section {
                NavigationLink {
                    NoteTagColorPickerView(selectedColor: $color)
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(colorSwatch)
                            .frame(width: 14, height: 14)

                        Text("Tag")
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(colorLabel)
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    NoteIconPickerView(selection: $symbolName)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: symbolName ?? NoteSymbolCatalog.defaultSymbol)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .center)

                        Text("Icon")
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(symbolLabel)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Appearance")
            }

            Section {
                Toggle(Localization.notePinnedToDashboard, isOn: $pinnedToDashboard)
                    .tint(AppColors.accentBlue)
            } header: {
                Text(Localization.noteDashboard)
            } footer: {
                Text(Localization.notePinnedHint)
            }

            if isEditing {
                Section {
                    Button(role: .destructive) {
                        dismiss()
                        onRequestDelete()
                    } label: {
                        Text("Delete Note")
                    }
                }
            }
        }
        .navigationTitle(Localization.noteDetails)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Localization.done) { dismiss() }
                    .fontWeight(.semibold)
            }
        }
    }

    private var colorLabel: String {
        guard let color, let noteColor = NoteColor(rawValue: color) else { return Localization.none }
        return noteColor.accessibilityLabel
    }

    private var colorSwatch: Color {
        guard let color, let noteColor = NoteColor(rawValue: color) else { return .secondary.opacity(0.25) }
        return noteColor.color
    }

    private var symbolLabel: String {
        guard let symbolName else { return Localization.none }
        return NoteSymbolCatalog.label(for: symbolName)
    }
}

#Preview {
    Group {
        if let container = try? ModelContainer(
            for: DailyNote.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ) {
            NavigationStack {
                DailyNotesView(selectedDate: Date(), isModal: true)
            }
            .modelContainer(container)
        } else {
            Text("Preview unavailable")
        }
    }
}
