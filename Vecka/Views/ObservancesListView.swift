//
//  ObservancesListView.swift
//  Vecka
//
//  Library view: observances by year (non-red-day dates).
//

import SwiftUI
import SwiftData

struct ObservancesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @ObservedObject private var holidayManager = HolidayManager.shared
    @AppStorage("showHolidays") private var showHolidays = true
    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])

    @State private var isPresentingNewObservance = false
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    private struct Row: Identifiable {
        let id: String
        let ruleID: String
        let region: String
        let date: Date
        let title: String
        let symbolName: String?
        let isCustom: Bool
    }

    private struct MonthSection: Identifiable {
        let id: String
        let title: String
        let rows: [Row]
    }

    private var years: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 20)...(current + 20))
    }

    private var yearRows: [Row] {
        let calendar = Calendar.current

        return holidayManager.holidayCache
            .filter { (date, _) in calendar.component(.year, from: date) == selectedYear }
            .sorted(by: { $0.key < $1.key })
            .flatMap { (date, holidays) in
                holidays.filter { !$0.isRedDay }.map { holiday in
                    Row(
                        id: "\(date.timeIntervalSinceReferenceDate)-\(holiday.id)",
                        ruleID: holiday.id,
                        region: holiday.region,
                        date: date,
                        title: holiday.displayTitle,
                        symbolName: holiday.symbolName,
                        isCustom: holiday.isCustom
                    )
                }
            }
    }

    private var yearSections: [MonthSection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: yearRows) { row in calendar.component(.month, from: row.date) }

        return grouped
            .compactMap { (month, rows) -> MonthSection? in
                guard rows.first != nil else { return nil }
                return MonthSection(
                    id: "\(selectedYear)-\(month)",
                    title: monthTitle(for: month),
                    rows: rows.sorted(by: { $0.date < $1.date })
                )
            }
            .sorted(by: { $0.rows.first?.date ?? .distantFuture < $1.rows.first?.date ?? .distantFuture })
    }

    var body: some View {
        List {
            if !showHolidays {
                ContentUnavailableView(
                    "Holidays Are Off",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text(NSLocalizedString("holidays.turn_on_hint", value: "Turn on Holidays in the Holidays screen to see observances.", comment: "Turn on holidays hint"))
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    Picker(Localization.yearLabel, selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text(String(year))
                                .monospacedDigit()
                                .tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if yearSections.isEmpty {
                    ContentUnavailableView(
                        "No Observances",
                        systemImage: "sparkles",
                        description: Text(NSLocalizedString("holidays.add_observances", value: "Add observances like birthdays or milestones.", comment: "Add observances hint"))
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(yearSections) { section in
                        Section(section.title) {
                            ForEach(section.rows) { row in
                                // TODO: Restore HolidayRuleEditorHostView for database-driven architecture
                                // NavigationLink {
                                //     HolidayRuleEditorHostView(ruleID: row.ruleID)
                                // } label: {
                                HStack(spacing: 12) {
                                        Image(systemName: row.symbolName ?? "star")
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 28, alignment: .center)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(row.title)
                                                .font(.body.weight(.medium))
                                                .foregroundStyle(.primary)

                                            if holidayRegions.regions.count > 1 {
                                                Text("\(row.date.formatted(date: .abbreviated, time: .omitted)) • \(regionOption(for: row.region).displayName)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            } else {
                                                Text(row.date.formatted(date: .abbreviated, time: .omitted))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        Spacer()
                                }
                                .padding(.vertical, Spacing.extraSmall)
                                // }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if row.isCustom {
                                        Button(role: .destructive) {
                                            deleteRule(withId: row.ruleID)
                                        } label: {
                                            Label(Localization.delete, systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Observances")
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingNewObservance = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Observance")
            }
        }
        .onAppear {
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
        }
        .onChange(of: selectedYear) { _, newYear in
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: newYear)
        }
        // TODO: Restore HolidayRuleEditorView for database-driven architecture
        // .sheet(isPresented: $isPresentingNewObservance) {
        //     NavigationStack {
        //         HolidayRuleEditorView(mode: .create(defaultRegion: defaultNewHolidayRegion, defaultKind: .observance))
        //     }
        // }
    }

    private func deleteRule(withId id: String) {
        do {
            let descriptor = FetchDescriptor<HolidayRule>(predicate: #Predicate<HolidayRule> { $0.id == id })
            if let rule = try modelContext.fetch(descriptor).first {
                modelContext.delete(rule)
                try modelContext.save()
                holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
            }
        } catch {
            Log.w("Failed to delete observance: \(error.localizedDescription)")
        }
    }

    private func regionOption(for code: String) -> RegionSelectionView.RegionOption {
        RegionSelectionView.options.first(where: { $0.code == code }) ?? .init(
            code: code,
            titleKey: code,
            symbol: "globe",
            color: .secondary
        )
    }

    private var defaultNewHolidayRegion: String {
        holidayRegions.regions.count == 1 ? (holidayRegions.primaryRegion ?? "") : ""
    }

    private func monthTitle(for month: Int) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateFormat = "LLLL"

        let date = calendar.date(from: DateComponents(year: selectedYear, month: month, day: 1)) ?? Date()
        var title = formatter.string(from: date)
        if locale.language.languageCode?.identifier == "sv" {
            title = title.capitalized(with: locale)
        }
        return "\(title) \(selectedYear)"
    }
}

#Preview {
    if let container = try? ModelContainer(
        for: HolidayRule.self, CalendarRule.self, DailyNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) {
        NavigationStack {
            ObservancesListView()
        }
        .modelContainer(container)
    } else {
        Text(NSLocalizedString("pdf.preview_unavailable", value: "Preview unavailable", comment: "Preview unavailable"))
    }
}
