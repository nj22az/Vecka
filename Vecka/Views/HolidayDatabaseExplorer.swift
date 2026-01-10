//
//  HolidayDatabaseExplorer.swift
//  Vecka
//
//  情報デザイン (Jōhō Dezain) - Bento-Style Holiday Database
//  Matches the Star Page (SpecialDaysListView) visual language
//
//  Design: 3-column flipcard grid for regions
//  NO emoji flags - text codes only (strict 情報デザイン)
//

import SwiftUI
import SwiftData

// MARK: - Region Database Info
// 情報デザイン: NO emoji flags - text codes only
// Priority: Nordic countries first, then Japan + Vietnam

struct RegionDatabase: Identifiable {
    let id: String  // Region code (SE, NO, DK, etc.)
    let name: String  // English name
    let localName: String  // Native language name
    let continent: String
    let icon: String  // SF Symbol for region

    static let all: [RegionDatabase] = [
        // Nordic countries (priority)
        RegionDatabase(id: "SE", name: "Sweden", localName: "Sverige", continent: "Nordic", icon: "crown.fill"),
        RegionDatabase(id: "NO", name: "Norway", localName: "Norge", continent: "Nordic", icon: "mountain.2.fill"),
        RegionDatabase(id: "DK", name: "Denmark", localName: "Danmark", continent: "Nordic", icon: "star.fill"),
        RegionDatabase(id: "FI", name: "Finland", localName: "Suomi", continent: "Nordic", icon: "snowflake"),
        RegionDatabase(id: "IS", name: "Iceland", localName: "Ísland", continent: "Nordic", icon: "flame.fill"),
        // Asia (priority)
        RegionDatabase(id: "JP", name: "Japan", localName: "日本", continent: "Asia", icon: "sun.max.fill"),
        RegionDatabase(id: "VN", name: "Vietnam", localName: "Việt Nam", continent: "Asia", icon: "leaf.fill"),
        // Additional (if needed later)
        RegionDatabase(id: "US", name: "United States", localName: "USA", continent: "Americas", icon: "building.columns.fill")
    ]

    /// Color for the region (情報デザイン semantic colors)
    var accentColor: Color {
        switch continent {
        case "Nordic": return JohoColors.cyan
        case "Asia": return JohoColors.pink
        case "Americas": return JohoColors.orange
        default: return JohoColors.black
        }
    }

    var lightBackground: Color {
        accentColor.opacity(0.15)
    }
}

// MARK: - Holiday Database Explorer (情報デザイン: Bento-Style)

struct HolidayDatabaseExplorer: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \HolidayRule.name) private var allRules: [HolidayRule]

    // Active region (the one applied to calendar)
    @AppStorage("holidayRegions") private var holidayRegions = HolidayRegionSelection(regions: ["SE"])

    // View state: nil = grid view, String = region detail view
    @State private var selectedRegion: String? = nil
    @State private var showingChangelog = false
    @State private var editingRule: HolidayRule?

    private let holidayManager = HolidayManager.shared

    // Rules for the selected region
    private func rulesFor(_ regionID: String) -> [HolidayRule] {
        allRules.filter { rule in
            if regionID == "SE" {
                return rule.region == "SE" || rule.region.isEmpty
            }
            return rule.region == regionID
        }
    }

    // Separate into holidays and observances
    private func holidays(for regionID: String) -> [HolidayRule] {
        rulesFor(regionID).filter { $0.isBankHoliday && $0.isEnabled }
    }

    private func observances(for regionID: String) -> [HolidayRule] {
        rulesFor(regionID).filter { !$0.isBankHoliday && $0.isEnabled }
    }

    private func disabledRules(for regionID: String) -> [HolidayRule] {
        rulesFor(regionID).filter { !$0.isEnabled }
    }

    // Count holidays for a region
    private func holidayCount(for regionID: String) -> Int {
        holidays(for: regionID).count
    }

    private func observanceCount(for regionID: String) -> Int {
        observances(for: regionID).count
    }

    // Is this region currently active on calendar?
    private func isActiveRegion(_ regionID: String) -> Bool {
        holidayRegions.regions.contains(regionID)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: JohoDimensions.spacingLG) {
                    // Header with title
                    headerCard

                    // Main content: Grid or Detail
                    if let regionID = selectedRegion {
                        regionDetailView(for: regionID)
                    } else {
                        regionGrid
                    }

                    Spacer(minLength: JohoDimensions.spacingXL)
                }
                .padding(.bottom, JohoDimensions.spacingXL)
            }
            .johoBackground()
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingChangelog) {
                HolidayChangeLogView()
            }
            .sheet(item: $editingRule) { rule in
                HolidayRuleEditorSheet(rule: rule)
            }
        }
    }

    // MARK: - Header Card (情報デザイン: Bento Compartments)

    private var headerCard: some View {
        VStack(spacing: 0) {
            // TOP ROW: Back button (if needed) + Icon + Title | WALL | Stats
            HStack(spacing: 0) {
                // LEFT COMPARTMENT: Navigation + Icon + Title
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Back button when in region detail
                    if selectedRegion != nil {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedRegion = nil
                            }
                            HapticManager.selection()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.black)
                                .frame(width: 32, height: 32)
                                .background(JohoColors.inputBackground)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                        }
                    }

                    // Icon zone
                    if let regionID = selectedRegion,
                       let region = RegionDatabase.all.first(where: { $0.id == regionID }) {
                        Image(systemName: region.icon)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(region.accentColor)
                            .frame(width: 40, height: 40)
                            .background(region.lightBackground)
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: 1.5)
                            )
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.pink)
                            .frame(width: 40, height: 40)
                            .background(JohoColors.pink.opacity(0.15))
                            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusSmall))
                            .overlay(
                                Squircle(cornerRadius: JohoDimensions.radiusSmall)
                                    .stroke(JohoColors.black, lineWidth: 1.5)
                            )
                    }

                    // Title
                    if let regionID = selectedRegion,
                       let region = RegionDatabase.all.first(where: { $0.id == regionID }) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(region.name.uppercased())
                                .font(JohoFont.headline)
                                .foregroundStyle(JohoColors.black)
                            Text(region.localName)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(JohoColors.black.opacity(0.6))
                        }
                    } else {
                        Text("HOLIDAY DATABASE")
                            .font(JohoFont.headline)
                            .foregroundStyle(JohoColors.black)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

                // VERTICAL WALL
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)

                // RIGHT COMPARTMENT: Actions
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Changelog button
                    Button {
                        showingChangelog = true
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                    }

                    // Done button
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(JohoColors.black)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
            }
            .frame(height: 56)

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // STATS ROW
            HStack(spacing: JohoDimensions.spacingSM) {
                if let regionID = selectedRegion {
                    let hCount = holidayCount(for: regionID)
                    let oCount = observanceCount(for: regionID)
                    Text("\(hCount) holidays, \(oCount) observances")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))

                    Spacer()

                    // Active indicator
                    if isActiveRegion(regionID) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(JohoColors.green)
                            Text("ACTIVE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(JohoColors.green)
                        }
                    }
                } else {
                    Text("\(RegionDatabase.all.count) regions available")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.7))
                    Spacer()
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: 2)
        )
        .padding(.horizontal, JohoDimensions.spacingLG)
        .padding(.top, JohoDimensions.spacingSM)
    }

    // MARK: - Region Grid (情報デザイン: 3-Column Bento like Star Page)

    private var regionGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: JohoDimensions.spacingSM),
            GridItem(.flexible(), spacing: JohoDimensions.spacingSM),
            GridItem(.flexible(), spacing: JohoDimensions.spacingSM)
        ]

        return LazyVGrid(columns: columns, spacing: JohoDimensions.spacingSM) {
            ForEach(RegionDatabase.all) { region in
                regionFlipcard(for: region)
            }
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Region Flipcard (情報デザイン: Compartmentalized like monthFlipcard)

    @ViewBuilder
    private func regionFlipcard(for region: RegionDatabase) -> some View {
        let hCount = holidayCount(for: region.id)
        let oCount = observanceCount(for: region.id)
        let totalCount = hCount + oCount
        let hasItems = totalCount > 0
        let isActive = isActiveRegion(region.id)

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedRegion = region.id
            }
            HapticManager.selection()
        } label: {
            VStack(spacing: 0) {
                // TOP COMPARTMENT: Icon zone (情報デザイン: distinct visual anchor)
                ZStack {
                    Image(systemName: region.icon)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(hasItems ? region.accentColor : JohoColors.black.opacity(0.6))

                    // Active indicator (top-right corner)
                    if isActive {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(JohoColors.green)
                            }
                            Spacer()
                        }
                        .padding(6)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(hasItems ? region.lightBackground : JohoColors.inputBackground)

                // Horizontal divider
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(height: 1.5)

                // BOTTOM COMPARTMENT: Data zone
                VStack(spacing: 4) {
                    // Region code (bold, prominent)
                    Text(region.id)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    // Local name
                    Text(region.localName)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    // Stats row (情報デザイン: Colored icons with counts)
                    if hasItems {
                        HStack(spacing: 4) {
                            // Holidays: Star icon
                            if hCount > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: SpecialDayType.holiday.defaultIcon)
                                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                                        .foregroundStyle(SpecialDayType.holiday.accentColor)
                                    Text("\(hCount)")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(JohoColors.black)
                                }
                            }

                            // Observances: Sparkles icon
                            if oCount > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: SpecialDayType.observance.defaultIcon)
                                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                                        .foregroundStyle(SpecialDayType.observance.accentColor)
                                    Text("\(oCount)")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(JohoColors.black)
                                }
                            }
                        }
                    } else {
                        Text("—")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 110)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(isActive ? JohoColors.green : (hasItems ? JohoColors.black : JohoColors.black.opacity(0.3)),
                            lineWidth: isActive ? 2.5 : (hasItems ? JohoDimensions.borderMedium : JohoDimensions.borderThin))
            )
        }
        .buttonStyle(.plain)
        .opacity(hasItems ? 1.0 : 0.7)
    }

    // MARK: - Region Detail View (情報デザイン: Timeline of holidays)

    @ViewBuilder
    private func regionDetailView(for regionID: String) -> some View {
        let hols = holidays(for: regionID)
        let obs = observances(for: regionID)
        let disabled = disabledRules(for: regionID)

        VStack(spacing: JohoDimensions.spacingMD) {
            // Holidays section
            if !hols.isEmpty {
                databaseSection(
                    title: "HOLIDAYS",
                    subtitle: "Bank holidays / Red days",
                    icon: "flag.fill",
                    color: JohoColors.red,
                    rules: hols
                )
            }

            // Observances section
            if !obs.isEmpty {
                databaseSection(
                    title: "OBSERVANCES",
                    subtitle: "Notable days (not bank holidays)",
                    icon: "star.fill",
                    color: JohoColors.orange,
                    rules: obs
                )
            }

            // Disabled section
            if !disabled.isEmpty {
                databaseSection(
                    title: "DISABLED",
                    subtitle: "Hidden from calendar",
                    icon: "eye.slash",
                    color: JohoColors.black.opacity(0.3),
                    rules: disabled
                )
            }

            // Empty state
            if hols.isEmpty && obs.isEmpty && disabled.isEmpty {
                emptyDatabaseState(for: regionID)
            }

            // Action buttons
            actionButtonsSection(for: regionID)
        }
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Database Section (情報デザイン: Bento compartment)

    private func databaseSection(title: String, subtitle: String, icon: String, color: Color, rules: [HolidayRule]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 0) {
                // Title compartment
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Icon zone
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .frame(width: 24, height: 24)
                        .background(color.opacity(0.3))
                        .clipShape(Squircle(cornerRadius: 5))
                        .overlay(Squircle(cornerRadius: 5).stroke(JohoColors.black, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 0) {
                        Text(title)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(0.5)
                            .foregroundStyle(JohoColors.black)
                        Text(subtitle)
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)

                Spacer()

                // Wall
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)

                // Count compartment
                Text("\(rules.count)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 50)
            }
            .frame(height: 52)
            .background(color.opacity(0.1))

            // Divider
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 1.5)

            // Rules list
            VStack(spacing: 0) {
                ForEach(rules) { rule in
                    ruleRow(rule, color: color)

                    if rule.id != rules.last?.id {
                        Rectangle()
                            .fill(JohoColors.black.opacity(0.15))
                            .frame(height: 1)
                            .padding(.leading, JohoDimensions.spacingMD)
                    }
                }
            }
        }
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black, lineWidth: JohoDimensions.borderMedium)
        )
    }

    // MARK: - Rule Row (情報デザイン: Clean, tappable row)

    private func ruleRow(_ rule: HolidayRule, color: Color) -> some View {
        Button {
            editingRule = rule
            HapticManager.selection()
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Icon
                if let symbolName = rule.symbolName, !symbolName.isEmpty {
                    Image(systemName: symbolName)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(color)
                        .frame(width: 24)
                } else {
                    Image(systemName: rule.isBankHoliday ? "flag.fill" : "star")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(color)
                        .frame(width: 24)
                }

                // Name - 情報デザイン: Show local name with English translation
                VStack(alignment: .leading, spacing: 2) {
                    // Primary: Local name if available, else English
                    if let localName = rule.localName, !localName.isEmpty {
                        Text(localName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(rule.isEnabled ? JohoColors.black : JohoColors.black.opacity(0.4))
                            .lineLimit(1)
                        // Secondary: English translation
                        Text(displayName(for: rule))
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                    } else {
                        Text(displayName(for: rule))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(rule.isEnabled ? JohoColors.black : JohoColors.black.opacity(0.4))
                            .lineLimit(1)
                        // Type description
                        Text(ruleTypeDescription(rule))
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.5))
                    }
                }

                Spacer()

                // Modified indicator
                if rule.isModifiedFromDefault {
                    Text("※")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.orange)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.3))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private func emptyDatabaseState(for regionID: String) -> some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            Image(systemName: "tray")
                .font(.system(size: 48, weight: .light, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.2))

            Text("No holidays in database")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(JohoColors.black)

            Text("Tap 'Load Defaults' to add holidays for this region")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingXL)
        .background(JohoColors.white)
        .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
        .overlay(
            Squircle(cornerRadius: JohoDimensions.radiusMedium)
                .stroke(JohoColors.black.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons Section

    @ViewBuilder
    private func actionButtonsSection(for regionID: String) -> some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            // Load defaults button (only for supported regions)
            if ["SE", "US", "VN"].contains(regionID) {
                loadDefaultsButton(for: regionID)
            }

            // Apply to calendar button (if not already active)
            if !isActiveRegion(regionID) {
                applyToCalendarButton(for: regionID)
            }
        }
    }

    private func loadDefaultsButton(for regionID: String) -> some View {
        Button {
            holidayManager.loadDefaults(for: regionID, context: context)
            HapticManager.notification(.success)
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                Text("Load Defaults")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(JohoColors.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(JohoColors.black, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func applyToCalendarButton(for regionID: String) -> some View {
        Button {
            applyRegion(regionID)
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                Text("Apply to Calendar")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(JohoColors.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(JohoColors.green)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(JohoColors.black, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func displayName(for rule: HolidayRule) -> String {
        if let override = rule.titleOverride, !override.isEmpty {
            return override
        }
        if rule.name.hasPrefix("holiday.") {
            return NSLocalizedString(rule.name, comment: "Holiday name")
        }
        return rule.name
    }

    private func ruleTypeDescription(_ rule: HolidayRule) -> String {
        switch rule.type {
        case .fixed:
            if let month = rule.month, let day = rule.day {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                let components = DateComponents(month: month, day: day)
                if let date = Calendar.current.date(from: components) {
                    return "Fixed: \(formatter.string(from: date))"
                }
            }
            return "Fixed date"
        case .easterRelative:
            if let offset = rule.daysOffset {
                if offset == 0 { return "Easter Sunday" }
                if offset > 0 { return "Easter +\(offset) days" }
                return "Easter \(offset) days"
            }
            return "Easter-relative"
        case .floating:
            return "Floating (calculated)"
        case .nthWeekday:
            if let ordinal = rule.ordinal {
                let ordinalStr = ordinal == -1 ? "Last" : "\(ordinal)th"
                return "\(ordinalStr) weekday of month"
            }
            return "Nth weekday"
        case .lunar:
            return "Lunar calendar"
        case .astronomical:
            return "Astronomical event"
        }
    }

    private func applyRegion(_ regionID: String) {
        // Replace active region with selected region
        holidayRegions = HolidayRegionSelection(regions: [regionID])
        holidayManager.calculateAndCacheHolidays(context: context)
        HapticManager.notification(.success)
    }
}

// MARK: - Holiday Rule Editor Sheet

struct HolidayRuleEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let rule: HolidayRule

    @State private var name: String = ""
    @State private var titleOverride: String = ""
    @State private var isBankHoliday: Bool = true
    @State private var isEnabled: Bool = true
    @State private var symbolName: String = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingResetConfirmation = false

    private let holidayManager = HolidayManager.shared

    var body: some View {
        NavigationStack {
            editorContent
                .background(JohoColors.white)
                .navigationTitle(displayName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { editorToolbar }
                .onAppear { loadRuleData() }
                .confirmationDialog("Reset to Default?", isPresented: $showingResetConfirmation) {
                    Button("Reset") {
                        _ = holidayManager.resetRuleToDefault(rule, context: context)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will restore the original settings for this holiday.")
                }
                .confirmationDialog("Delete Rule?", isPresented: $showingDeleteConfirmation) {
                    Button("Delete", role: .destructive) { deleteRule() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This action cannot be undone.")
                }
        }
    }

    // MARK: - Editor Content

    private var editorContent: some View {
        ScrollView {
            VStack(spacing: JohoDimensions.spacingMD) {
                nameSection
                typeSection
                statusSection
                ruleInfoSection
                actionsSection
            }
            .padding(JohoDimensions.spacingMD)
        }
    }

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
                .font(.system(size: 16, weight: .regular, design: .rounded))
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Save") { saveChanges() }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
        }
    }

    private var nameSection: some View {
        formSection(title: "DISPLAY NAME") {
            TextField("Holiday name", text: $titleOverride)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .padding(JohoDimensions.spacingSM)
        }
    }

    private var typeSection: some View {
        formSection(title: "TYPE") {
            HStack {
                typeButton(title: "Holiday", isSelected: isBankHoliday) {
                    isBankHoliday = true
                }
                typeButton(title: "Observance", isSelected: !isBankHoliday) {
                    isBankHoliday = false
                }
            }
            .padding(JohoDimensions.spacingSM)
        }
    }

    // 情報デザイン: Custom toggle instead of iOS default
    private var statusSection: some View {
        formSection(title: "STATUS") {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEnabled.toggle()
                }
                HapticManager.selection()
            } label: {
                HStack {
                    Image(systemName: isEnabled ? "eye" : "eye.slash")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(isEnabled ? JohoColors.black : JohoColors.black.opacity(0.4))
                        .frame(width: 24)

                    Text(isEnabled ? "Visible on Calendar" : "Hidden from Calendar")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    Spacer()

                    // 情報デザイン: Custom toggle (マルバツ style)
                    Text(isEnabled ? "○" : "×")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isEnabled ? JohoColors.green : JohoColors.red)
                        .frame(width: 32, height: 32)
                        .background(isEnabled ? JohoColors.green.opacity(0.15) : JohoColors.red.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isEnabled ? JohoColors.green : JohoColors.red, lineWidth: 1.5)
                        )
                }
            }
            .buttonStyle(.plain)
            .padding(JohoDimensions.spacingSM)
        }
    }

    private var ruleInfoSection: some View {
        formSection(title: "CALCULATION RULE") {
            VStack(alignment: .leading, spacing: 4) {
                Text(ruleDescription)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.7))
                Text("Rule type cannot be changed")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.4))
            }
            .padding(JohoDimensions.spacingSM)
        }
    }

    private var actionsSection: some View {
        VStack(spacing: JohoDimensions.spacingSM) {
            if rule.canResetToDefault {
                resetButton
            }
            if !rule.isSystemDefault {
                deleteButton
            }
        }
        .padding(.top, JohoDimensions.spacingSM)
    }

    private var resetButton: some View {
        Button {
            showingResetConfirmation = true
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("Reset to Default")
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(JohoColors.cyan)
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
    }

    private var deleteButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Rule")
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(JohoColors.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
    }

    // MARK: - Form Section

    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.black.opacity(0.5))
                .padding(.horizontal, JohoDimensions.spacingSM)
                .padding(.bottom, 4)

            content()
                .background(JohoColors.white)
                .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                        .stroke(JohoColors.black.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private func typeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(isSelected ? JohoColors.white : JohoColors.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? JohoColors.black : JohoColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(JohoColors.black, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var displayName: String {
        if let override = rule.titleOverride, !override.isEmpty {
            return override
        }
        if rule.name.hasPrefix("holiday.") {
            return NSLocalizedString(rule.name, comment: "Holiday name")
        }
        return rule.name
    }

    private var ruleDescription: String {
        switch rule.type {
        case .fixed:
            if let month = rule.month, let day = rule.day {
                return "Fixed date: \(monthName(month)) \(day)"
            }
            return "Fixed date"
        case .easterRelative:
            if let offset = rule.daysOffset {
                if offset == 0 { return "Easter Sunday" }
                if offset > 0 { return "\(offset) days after Easter" }
                return "\(abs(offset)) days before Easter"
            }
            return "Relative to Easter"
        case .floating:
            return "Floating date (calculated each year)"
        case .nthWeekday:
            return "Nth weekday of month"
        case .lunar:
            return "Lunar calendar date"
        case .astronomical:
            return "Astronomical event (solstice/equinox)"
        }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        return formatter.monthSymbols[month - 1]
    }

    private func loadRuleData() {
        name = rule.name
        titleOverride = rule.titleOverride ?? ""
        isBankHoliday = rule.isBankHoliday
        isEnabled = rule.isEnabled
        symbolName = rule.symbolName ?? ""
    }

    private func saveChanges() {
        // Capture before state
        let beforeState = HolidayRuleSnapshot(from: rule)

        // Apply changes
        rule.titleOverride = titleOverride.isEmpty ? nil : titleOverride
        rule.isBankHoliday = isBankHoliday
        rule.isEnabled = isEnabled
        rule.userModifiedAt = Date()

        do {
            try context.save()

            // Log modification
            HolidayChangeLogService.shared.logModification(
                rule: rule,
                beforeState: beforeState,
                source: .user,
                context: context,
                notes: nil
            )

            // Refresh cache
            holidayManager.calculateAndCacheHolidays(context: context)

            HapticManager.notification(.success)
            dismiss()
        } catch {
            Log.w("Failed to save rule: \(error)")
        }
    }

    private func deleteRule() {
        // Log deletion
        HolidayChangeLogService.shared.logDeletion(
            rule: rule,
            source: .user,
            context: context,
            notes: nil
        )

        context.delete(rule)

        do {
            try context.save()
            holidayManager.calculateAndCacheHolidays(context: context)
            HapticManager.notification(.success)
            dismiss()
        } catch {
            Log.w("Failed to delete rule: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    HolidayDatabaseExplorer()
        .modelContainer(for: [HolidayRule.self, HolidayChangeLog.self], inMemory: true)
}
