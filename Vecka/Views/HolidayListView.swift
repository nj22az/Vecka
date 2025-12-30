//
//  HolidayListView.swift
//  Vecka
//
//  Library view: holidays by year (red days).
//

import SwiftUI
import SwiftData

struct HolidayListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @ObservedObject private var holidayManager = HolidayManager.shared
    @AppStorage("showHolidays") private var showHolidays = true
    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])

    @State private var isPresentingNewHoliday = false
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    private struct Row: Identifiable {
        let id: String
        let ruleID: String
        let region: String
        let date: Date
        let title: String
        let isRedDay: Bool
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
                holidays.filter { $0.isRedDay }.map { holiday in
                    Row(
                        id: "\(date.timeIntervalSinceReferenceDate)-\(holiday.id)",
                        ruleID: holiday.id,
                        region: holiday.region,
                        date: date,
                        title: holiday.displayTitle,
                        isRedDay: holiday.isRedDay,
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
            Section {
                Toggle("Show Holidays", isOn: $showHolidays)
                    .tint(AppColors.accentBlue)
                    .onChange(of: showHolidays) { _, _ in
                        holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
                    }

                if showHolidays {
                    NavigationLink {
                        RegionSelectionView(selectedRegions: $holidayRegions)
                    } label: {
                        HStack {
                            Label {
                                Text(NSLocalizedString("settings.region", comment: "Region"))
                            } icon: {
                                Image(systemName: regionSymbolName)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(regionSymbolColor)
                            }
                            .foregroundStyle(.primary)
                            Spacer()
                            Text(regionSummary)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: holidayRegions) { _, _ in
                        holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
                    }

                    Picker(Localization.yearLabel, selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text(String(year))
                                .monospacedDigit()
                                .tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                }
            } header: {
                Text("Holidays")
            } footer: {
                Text(Localization.holidaysHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !showHolidays {
                ContentUnavailableView(
                    "Holidays Are Off",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Turn on Holidays above to see holidays.")
                )
                .listRowBackground(Color.clear)
            } else if yearSections.isEmpty {
                ContentUnavailableView(
                    "No Holidays",
                    systemImage: "calendar",
                    description: Text("Add custom holidays with +, or adjust your region.")
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
                                    Image(systemName: row.symbolName ?? (row.isRedDay ? "flag.fill" : "star"))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(row.isRedDay ? .red : .secondary)
                                        .frame(width: 28, alignment: .center)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(row.title)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)

                                    if holidayRegions.regions.count > 1 {
                                        Text("\(weekdayName(for: row.date)), \(row.date.formatted(date: .abbreviated, time: .omitted)) • \(regionOption(for: row.region).displayName)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("\(weekdayName(for: row.date)), \(row.date.formatted(date: .abbreviated, time: .omitted))")
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
        .navigationTitle("Holidays")
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingNewHoliday = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Holiday")
            }
        }
        .onAppear {
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: selectedYear)
        }
        .onChange(of: selectedYear) { _, newYear in
            holidayManager.calculateAndCacheHolidays(context: modelContext, focusYear: newYear)
        }
        // TODO: Restore HolidayRuleEditorView for database-driven architecture
        // .sheet(isPresented: $isPresentingNewHoliday) {
        //     NavigationStack {
        //         HolidayRuleEditorView(mode: .create(defaultRegion: defaultNewHolidayRegion, defaultKind: .publicHoliday))
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
            Log.w("Failed to delete holiday: \(error.localizedDescription)")
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

    private var regionSummary: String {
        let names = holidayRegions.regions.map { regionOption(for: $0).displayName }
        if names.isEmpty { return Localization.none }
        return names.joined(separator: ", ")
    }

    private var regionSymbolName: String {
        if let only = holidayRegions.primaryRegion, holidayRegions.regions.count == 1 {
            return regionOption(for: only).symbol
        }
        return "globe"
    }

    private var regionSymbolColor: Color {
        if let only = holidayRegions.primaryRegion, holidayRegions.regions.count == 1 {
            return regionOption(for: only).color
        }
        return .secondary
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

    private func weekdayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.iso8601
        formatter.locale = locale
        formatter.dateFormat = "EEE"  // Abbreviated weekday (e.g., Mon, Tue, Wed)
        return formatter.string(from: date)
    }
}
