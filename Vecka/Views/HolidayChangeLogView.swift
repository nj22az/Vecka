//
//  HolidayChangeLogView.swift
//  Vecka
//
//  情報デザイン: Audit trail viewer for holiday database changes
//  Provides transparency and traceability for all modifications
//

import SwiftUI
import SwiftData

// MARK: - Changelog Viewer Sheet

struct HolidayChangeLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HolidayChangeLog.timestamp, order: .reverse) private var allEntries: [HolidayChangeLog]

    @State private var selectedRegion: String? = nil
    @State private var selectedEntry: HolidayChangeLog?
    @State private var showingLoadDefaultsConfirmation = false

    private let holidayManager = HolidayManager.shared
    private let regions = ["ALL", "SE", "NO", "DK", "FI", "IS", "US", "VN", "DE", "GB", "FR", "IT", "NL", "JP", "HK", "CN", "TH"]
    private let loadableRegions = ["SE", "NO", "DK", "FI", "IS", "US", "VN"]  // Regions with load defaults support

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Region filter strip
                regionFilterStrip

                // Divider
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: JohoDimensions.borderMedium)

                // Entries list
                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    entriesList
                }
            }
            .background(JohoColors.white)
            .navigationTitle("Change Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                }

                // Load Defaults button (only for loadable regions)
                if let region = selectedRegion, loadableRegions.contains(region) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingLoadDefaultsConfirmation = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle")
                                Text("Load Defaults")
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                    }
                }
            }
            .sheet(item: $selectedEntry) { entry in
                ChangeLogDetailSheet(entry: entry)
            }
            .confirmationDialog(
                "Load Default Holidays?",
                isPresented: $showingLoadDefaultsConfirmation,
                titleVisibility: .visible
            ) {
                Button("Load Defaults for \(selectedRegion ?? "")") {
                    if let region = selectedRegion {
                        holidayManager.loadDefaults(for: region, context: context)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will add any missing default holidays for \(selectedRegion ?? "this region"). Existing holidays will not be modified.")
            }
        }
    }

    // MARK: - Filtered Entries

    private var filteredEntries: [HolidayChangeLog] {
        guard let region = selectedRegion, region != "ALL" else {
            return allEntries
        }
        return allEntries.filter { $0.region == region }
    }

    // MARK: - Region Filter Strip

    private var regionFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: JohoDimensions.spacingSM) {
                ForEach(regions, id: \.self) { region in
                    let isSelected = (selectedRegion ?? "ALL") == region
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedRegion = region
                        }
                    } label: {
                        Text(region)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(isSelected ? JohoColors.white : JohoColors.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? JohoColors.black : JohoColors.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(JohoColors.black, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(JohoColors.white)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48, weight: .light, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.3))

            Text("No Changes Yet")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoColors.black)

            Text("Changes to the holiday database will appear here")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.6))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(JohoDimensions.spacingLG)
    }

    // MARK: - Entries List

    private var entriesList: some View {
        ScrollView {
            LazyVStack(spacing: JohoDimensions.spacingSM) {
                ForEach(filteredEntries) { entry in
                    ChangeLogEntryRow(entry: entry)
                        .onTapGesture {
                            selectedEntry = entry
                        }
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
    }
}

// MARK: - Entry Row

struct ChangeLogEntryRow: View {
    let entry: HolidayChangeLog

    private var actionColor: Color {
        switch entry.action {
        case .created: return JohoColors.green
        case .modified: return JohoColors.orange
        case .deleted: return JohoColors.red
        case .enabled: return JohoColors.green
        case .disabled: return JohoColors.black.opacity(0.4)
        case .reset: return JohoColors.cyan
        case .migrated: return JohoColors.cyan
        case .defaultsLoaded: return JohoColors.cyan
        }
    }

    var body: some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Action icon
            Image(systemName: entry.actionIcon)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(actionColor)
                .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                // Rule name and action
                HStack(spacing: 4) {
                    Text(entry.ruleName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(1)

                    Text("•")
                        .foregroundStyle(JohoColors.black.opacity(0.4))

                    Text(entry.region)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                // Change description
                Text(entry.changeDescription)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.7))
                    .lineLimit(2)

                // Timestamp and source
                HStack(spacing: 4) {
                    Text(entry.formattedTimestamp)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))

                    Text("•")
                        .foregroundStyle(JohoColors.black.opacity(0.3))

                    Text(entry.sourceLabel)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.3))
        }
        .padding(JohoDimensions.spacingSM)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                .stroke(JohoColors.black.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Detail Sheet

struct ChangeLogDetailSheet: View {
    let entry: HolidayChangeLog
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: JohoDimensions.spacingMD) {
                    // Header card
                    headerCard

                    // Change details
                    if entry.beforeJSON != nil || entry.afterJSON != nil {
                        jsonDiffSection
                    }

                    // Notes if any
                    if let notes = entry.notes, !notes.isEmpty {
                        notesSection(notes)
                    }

                    // Metadata
                    metadataSection
                }
                .padding(JohoDimensions.spacingMD)
            }
            .background(JohoColors.white)
            .navigationTitle("Change Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                }
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: entry.actionIcon)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(actionColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.ruleName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    Text(entry.action.rawValue)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(actionColor)
                }

                Spacer()

                JohoPill(text: entry.region, style: .blackOnWhite, size: .small)
            }

            Rectangle()
                .fill(JohoColors.black.opacity(0.1))
                .frame(height: 1)

            Text(entry.changeDescription)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.8))
        }
        .padding(JohoDimensions.spacingMD)
        .background(actionColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: JohoDimensions.radiusMedium, style: .continuous)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    private var actionColor: Color {
        switch entry.action {
        case .created: return JohoColors.green
        case .modified: return JohoColors.orange
        case .deleted: return JohoColors.red
        case .enabled: return JohoColors.green
        case .disabled: return JohoColors.black.opacity(0.4)
        case .reset: return JohoColors.cyan
        case .migrated: return JohoColors.cyan
        case .defaultsLoaded: return JohoColors.cyan
        }
    }

    // MARK: - JSON Diff Section

    private var jsonDiffSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            Text("CHANGE DETAILS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.5))

            if let before = entry.beforeJSON {
                jsonCard(title: "Before", json: before, color: .red)
            }

            if let after = entry.afterJSON {
                jsonCard(title: "After", json: after, color: .green)
            }
        }
    }

    private func jsonCard(title: String, json: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(color)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(formatJSON(json))
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(JohoColors.black.opacity(0.8))
            }
        }
        .padding(JohoDimensions.spacingSM)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }

    private func formatJSON(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return json
        }
        return prettyString
    }

    // MARK: - Notes Section

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            Text("NOTES")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.5))

            Text(notes)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.8))
                .padding(JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(JohoColors.black.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            Text("METADATA")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.5))

            VStack(spacing: 0) {
                metadataRow(label: "Timestamp", value: entry.formattedTimestamp)
                metadataRow(label: "Source", value: entry.sourceLabel)
                metadataRow(label: "Rule ID", value: entry.ruleId)
                if let version = entry.appVersion {
                    metadataRow(label: "App Version", value: version)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                    .stroke(JohoColors.black.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.6))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(JohoColors.black)
                .lineLimit(1)
        }
        .padding(.horizontal, JohoDimensions.spacingSM)
        .padding(.vertical, 8)
        .background(JohoColors.white)
    }
}

// MARK: - Preview

#Preview {
    HolidayChangeLogView()
        .modelContainer(for: [HolidayChangeLog.self], inMemory: true)
}
