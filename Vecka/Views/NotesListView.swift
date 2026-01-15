//
//  NotesListView.swift
//  Vecka
//
//  Library view: Notes grouped by month, with pinned items.
//  Design: Jōhō Dezain (Japanese Information Design) - YELLOW/AMBER zone
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
        ScrollView {
            VStack(spacing: JohoDimensions.spacingLG) {
                // Page header with actions
                HStack(alignment: .top) {
                    JohoPageHeader(
                        title: "Your Notes",
                        badge: "NOTES",
                        subtitle: "\(filteredNotes.count) total"
                    )

                    Spacer()

                    // Add note button
                    Button {
                        showingNewNoteFlow = true
                    } label: {
                        JohoActionButton(icon: "plus")
                    }
                    .accessibilityLabel(Localization.addNote)
                }
                .padding(.horizontal, JohoDimensions.spacingLG)
                .padding(.top, JohoDimensions.spacingSM)
                .safeAreaPadding(.top)

                // Search field (unified component)
                JohoSearchField(text: $searchText, placeholder: "Search notes...")
                    .padding(.horizontal, JohoDimensions.spacingLG)

                // Pinned section
                if pinnedUpcomingNotes.isNotEmpty {
                    VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                        HStack {
                            JohoPill(text: Localization.pinnedHeader, style: .whiteOnBlack, size: .medium)
                            Spacer()
                        }
                        .padding(.horizontal, JohoDimensions.spacingLG)

                        ForEach(pinnedUpcomingNotes) { note in
                            NavigationLink {
                                DailyNotesView(selectedDate: note.day, isModal: false)
                            } label: {
                                PinnedNoteRow(note: note, daysRemaining: daysUntil(note.day))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, JohoDimensions.spacingLG)
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

                // Empty state or month sections
                if monthSections.isEmpty {
                    JohoEmptyState(
                        title: trimmedSearch.isEmpty ? "No Notes" : "No Results",
                        message: trimmedSearch.isEmpty
                            ? "Add notes from the calendar using the plus button."
                            : "Try a different search term.",
                        icon: "note.text",
                        zone: .notes
                    )
                    .padding(.top, JohoDimensions.spacingSM)
                } else {
                    ForEach(monthSections) { section in
                        VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                            // Section header
                            HStack {
                                JohoPill(text: section.title, style: .whiteOnBlack, size: .medium)
                                Spacer()
                            }
                            .padding(.horizontal, JohoDimensions.spacingLG)

                            // Day groups
                            ForEach(section.days) { dayGroup in
                                NavigationLink {
                                    DailyNotesView(selectedDate: dayGroup.day, isModal: false)
                                } label: {
                                    NotesDayRow(dayGroup: dayGroup)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, JohoDimensions.spacingLG)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, JohoDimensions.spacingXL)
        }
        .johoBackground()
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingNewNoteFlow) {
            // Direct note creation for today - skips date picker step
            NavigationStack {
                DailyNotesView(selectedDate: Date(), isModal: true, startCreating: true)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(JohoColors.white)  // 情報デザイン: WHITE sheet background
        }
    }

    private var trimmedSearch: String {
        searchText.trimmed
    }

    private var filteredNotes: [DailyNote] {
        guard trimmedSearch.isNotEmpty else { return notes }
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
                let preview = latest?.content.trimmed
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
        HStack(spacing: JohoDimensions.spacingMD) {
            // Icon in yellow squircle
            JohoIconBadge(
                icon: dayGroup.hasPinned ? "pin.fill" : "note.text",
                zone: .notes,
                size: 40
            )

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(dayGroup.day.formatted(date: .abbreviated, time: .omitted))
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)

                if let preview = dayGroup.preview, preview.isNotEmpty {
                    Text(preview)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            // Count badge + pinned pill
            HStack(spacing: JohoDimensions.spacingSM) {
                if dayGroup.hasPinned {
                    JohoPill(text: "PINNED", style: .whiteOnBlack, size: .small)
                }

                if dayGroup.count > 1 {
                    JohoPill(text: "\(dayGroup.count)", style: .colored(SectionZone.notes.background), size: .small)
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)
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

private struct PinnedNoteRow: View {
    let note: DailyNote
    let daysRemaining: Int

    var body: some View {
        let title = titleLine(from: note.content)
        let dateText = scheduleLine(for: note)
        let badgeText = countdownBadgeText(days: daysRemaining)

        HStack(spacing: JohoDimensions.spacingMD) {
            // Note symbol in yellow squircle
            JohoIconBadge(
                icon: note.symbolName ?? "note.text",
                zone: .notes,
                size: 40
            )

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(JohoFont.body)
                    .foregroundStyle(JohoColors.black)
                    .lineLimit(1)

                HStack(spacing: JohoDimensions.spacingXS) {
                    Text(dateText)
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))

                    if let duration = note.duration, duration > 0 {
                        Text("•")
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                        Text(formatDuration(duration))
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                }
            }

            Spacer(minLength: 0)

            // Countdown badge
            JohoPill(text: badgeText, style: .colored(SectionZone.notes.background), size: .small)

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black)
        }
        .padding(JohoDimensions.spacingMD)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderThick)
        )
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    private func titleLine(from raw: String) -> String {
        let trimmed = raw.trimmed
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
