//
//  NotesListView.swift
//  Vecka
//
//  Library view: Notes grouped by month, with pinned items.
//

import SwiftUI
import SwiftData

struct NotesListView: View {
    @Query(sort: [SortDescriptor(\DailyNote.day, order: .reverse), SortDescriptor(\DailyNote.date, order: .reverse)])
    private var notes: [DailyNote]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var showingNewNoteFlow = false

    var body: some View {
        List {
            if !pinnedUpcomingNotes.isEmpty {
                Section(Localization.pinnedHeader) {
                    ForEach(pinnedUpcomingNotes) { note in
                        NavigationLink {
                            DailyNotesView(selectedDate: note.day, isModal: false)
                        } label: {
                            PinnedNoteRow(note: note, daysRemaining: daysUntil(note.day))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                unpin(note)
                            } label: {
                                Label("Unpin", systemImage: "pin.slash")
                            }
                            .tint(.gray)

                            Button(role: .destructive) {
                                delete(note)
                            } label: {
                                Label(Localization.delete, systemImage: "trash")
                            }
                        }
                    }
                }
            }

            if monthSections.isEmpty {
                ContentUnavailableView(
                    trimmedSearch.isEmpty ? "No Notes" : "No Results",
                    systemImage: "note.text",
                    description: Text(trimmedSearch.isEmpty
                        ? "Add notes from the calendar using the plus button."
                        : "Try a different search term.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(monthSections) { section in
                    Section(section.title) {
                        ForEach(section.days) { dayGroup in
                            NavigationLink {
                                DailyNotesView(selectedDate: dayGroup.day, isModal: false)
                            } label: {
                                NotesDayRow(dayGroup: dayGroup)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteDay(dayGroup.day)
                                } label: {
                                    Label(Localization.delete, systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Notes")
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: Text("Search Notes"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewNoteFlow = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Localization.addNote)
            }
        }
        .sheet(isPresented: $showingNewNoteFlow) {
            // Direct note creation for today - skips date picker step
            NavigationStack {
                DailyNotesView(selectedDate: Date(), isModal: true, startCreating: true)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredNotes: [DailyNote] {
        guard !trimmedSearch.isEmpty else { return notes }
        return notes.filter { $0.content.localizedCaseInsensitiveContains(trimmedSearch) }
    }

    private var pinnedUpcomingNotes: [DailyNote] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return filteredNotes
            .filter { $0.pinnedToDashboard == true }
            .filter { $0.day >= today }
            .sorted(by: { lhs, rhs in
                if lhs.day != rhs.day { return lhs.day < rhs.day }
                let lhsTime = lhs.scheduledAt ?? lhs.date
                let rhsTime = rhs.scheduledAt ?? rhs.date
                return lhsTime < rhsTime
            })
    }

    private var groupedDays: [NotesDayGroup] {
        let groups = Dictionary(grouping: filteredNotes) { $0.day }
        return groups
            .map { (day, notes) in
                let latest = notes.max(by: { $0.date < $1.date })
                let preview = latest?.content.trimmingCharacters(in: .whitespacesAndNewlines)
                return NotesDayGroup(
                    day: day,
                    count: notes.count,
                    preview: preview?.isEmpty == true ? nil : preview,
                    hasPinned: notes.contains(where: { $0.pinnedToDashboard == true })
                )
            }
            .sorted(by: { $0.day > $1.day })
    }

    private var monthSections: [NotesMonthSection] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "LLLL yyyy"

        let grouped = Dictionary(grouping: groupedDays) { group in
            let comps = calendar.dateComponents([.year, .month], from: group.day)
            return "\(comps.year ?? 0)-\(comps.month ?? 0)"
        }

        return grouped
            .compactMap { (_, dayGroups) -> NotesMonthSection? in
                guard let first = dayGroups.first else { return nil }
                return NotesMonthSection(
                    id: formatter.string(from: first.day),
                    title: formatter.string(from: first.day),
                    days: dayGroups.sorted(by: { $0.day > $1.day })
                )
            }
            .sorted(by: { $0.days.first?.day ?? .distantPast > $1.days.first?.day ?? .distantPast })
    }

    private func daysUntil(_ targetDay: Date) -> Int {
        ViewUtilities.daysUntil(to: targetDay)
    }

    private func unpin(_ note: DailyNote) {
        note.pinnedToDashboard = false
        try? modelContext.save()
    }

    private func delete(_ note: DailyNote) {
        modelContext.delete(note)
        try? modelContext.save()
    }

    private func deleteDay(_ day: Date) {
        let toDelete = notes.filter { $0.day == day }
        for note in toDelete {
            modelContext.delete(note)
        }
        try? modelContext.save()
    }
}

private struct NotesDayGroup: Identifiable, Hashable {
    var id: Date { day }
    let day: Date
    let count: Int
    let preview: String?
    let hasPinned: Bool
}

private struct NotesMonthSection: Identifiable {
    let id: String
    let title: String
    let days: [NotesDayGroup]
}

private struct NotesDayRow: View {
    let dayGroup: NotesDayGroup

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: dayGroup.hasPinned ? "pin.fill" : "note.text")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(dayGroup.hasPinned ? AppColors.accentBlue : .secondary)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(dayGroup.day.formatted(date: .abbreviated, time: .omitted))
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                if let preview = dayGroup.preview, !preview.isEmpty {
                    Text(preview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            if dayGroup.count > 1 {
                Text("\(dayGroup.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.extraSmall)
                    .background(.secondary.opacity(0.10), in: Capsule())
            }
        }
        .padding(.vertical, Spacing.extraSmall)
    }
}

private struct PinnedNoteRow: View {
    let note: DailyNote
    let daysRemaining: Int

    var body: some View {
        let title = titleLine(from: note.content)
        let dateText = scheduleLine(for: note)
        let badgeText = countdownBadgeText(days: daysRemaining)

        HStack(spacing: 12) {
            Image(systemName: note.symbolName ?? NoteSymbolCatalog.defaultSymbol)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppColors.accentBlue)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(dateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text(badgeText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, Spacing.small)
                .background(.secondary.opacity(0.10), in: Capsule())
                .monospacedDigit()
        }
        .padding(.vertical, Spacing.extraSmall)
    }

    private func titleLine(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let newlineIndex = trimmed.firstIndex(where: \.isNewline) {
            return String(trimmed[..<newlineIndex])
        }
        return trimmed.isEmpty ? Localization.untitled : trimmed
    }

    private func scheduleLine(for note: DailyNote) -> String {
        let dayText = note.day.formatted(date: .abbreviated, time: .omitted)
        if let scheduledAt = note.scheduledAt {
            let timeText = scheduledAt.formatted(date: .omitted, time: .shortened)
            return "\(dayText) • \(timeText)"
        }
        return dayText
    }

    private func countdownBadgeText(days: Int) -> String {
        if days <= 0 { return Localization.today }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .short
        formatter.maximumUnitCount = 1
        return formatter.string(from: TimeInterval(days) * 86_400) ?? "\(days)"
    }
}
