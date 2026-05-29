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
        RegionDatabase(id: "DK", name: "Denmark", localName: "Danmark", continent: "Nordic", icon: IconCatalog.holiday),
        RegionDatabase(id: "FI", name: "Finland", localName: "Suomi", continent: "Nordic", icon: "snowflake"),
        RegionDatabase(id: "IS", name: "Iceland", localName: "Ísland", continent: "Nordic", icon: "flame.fill"),
        // Asia (priority)
        RegionDatabase(id: "JP", name: "Japan", localName: "日本", continent: "Asia", icon: "sun.max.fill"),
        RegionDatabase(id: "VN", name: "Vietnam", localName: "Việt Nam", continent: "Asia", icon: "leaf.fill"),
        // Additional (if needed later)
        RegionDatabase(id: "US", name: "United States", localName: "USA", continent: "Americas", icon: "building.columns.fill")
    ]

    /// Color for the region (情報デザイン semantic colors)
    func accentColor(colors: JohoScheme) -> Color {
        switch continent {
        case "Nordic": return JohoColors.cyan
        case "Asia": return JohoColors.pink
        case "Americas": return JohoColors.cyan
        default: return colors.primary
        }
    }

    func lightBackground(colors: JohoScheme) -> Color {
        accentColor(colors: colors).opacity(JohoDimensions.opacityLight)
    }
}

// MARK: - Holiday Database Explorer (情報デザイン: Bento-Style)

struct HolidayDatabaseExplorer: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedRegion = nil
                            }
                            HapticManager.selection()
                        } label: {
                            Image(systemName: IconCatalog.chevronLeft)
                                .font(JohoFont.bodySmallBold)
                                .foregroundStyle(colors.primary)
                                .frame(width: 32, height: 32)
                                .background(colors.inputBackground)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(colors.border, lineWidth: 1))
                        }
                    }

                    // Icon zone
                    if let regionID = selectedRegion,
                       let region = RegionDatabase.all.first(where: { $0.id == regionID }) {
                        Image(systemName: region.icon)
                            .font(JohoFont.title)
                            .foregroundStyle(region.accentColor(colors: colors))
                            .frame(width: 40, height: 40)
                            .background(region.lightBackground(colors: colors))
                            .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
                    } else {
                        Image(systemName: IconCatalog.globe)
                            .font(JohoFont.title)
                            .foregroundStyle(JohoColors.pink)
                            .frame(width: 40, height: 40)
                            .background(JohoColors.pink.opacity(JohoDimensions.opacityLight))
                            .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
                    }

                    // Title
                    if let regionID = selectedRegion,
                       let region = RegionDatabase.all.first(where: { $0.id == regionID }) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(region.name.uppercased())
                                .font(JohoFont.headline)
                                .foregroundStyle(colors.primary)
                            Text(region.localName)
                                .font(JohoFont.caption)
                                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
                        }
                    } else {
                        Text("HOLIDAY DATABASE")
                            .font(JohoFont.headline)
                            .foregroundStyle(colors.primary)
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)

                // VERTICAL WALL
                Rectangle()
                    .fill(colors.primary)
                    .frame(width: 1.5)

                // RIGHT COMPARTMENT: Actions
                HStack(spacing: JohoDimensions.spacingSM) {
                    // Changelog button
                    Button {
                        showingChangelog = true
                        HapticManager.selection()
                    } label: {
                        Image(systemName: IconCatalog.clockHistory)
                            .font(JohoFont.body)
                            .foregroundStyle(colors.primary)
                    }

                    // Done button
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(JohoFont.bodySmallBold)
                            .foregroundStyle(colors.surface)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(colors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous))
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
            }
            .frame(height: 56)

            // HORIZONTAL DIVIDER
            Rectangle()
                .fill(colors.primary)
                .frame(height: 1.5)

            // STATS ROW
            HStack(spacing: JohoDimensions.spacingSM) {
                if let regionID = selectedRegion {
                    let hCount = holidayCount(for: regionID)
                    let oCount = observanceCount(for: regionID)
                    Text("\(hCount) holidays, \(oCount) observances")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityBold))

                    Spacer()

                    // Active indicator
                    if isActiveRegion(regionID) {
                        HStack(spacing: 4) {
                            Image(systemName: IconCatalog.checkmarkCircleFill)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(JohoColors.green)
                            Text("ACTIVE")
                                .font(JohoFont.labelBold)
                                .foregroundStyle(JohoColors.green)
                        }
                    }
                } else {
                    Text("\(RegionDatabase.all.count) regions available")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityBold))
                    Spacer()
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: 2)
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
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedRegion = region.id
            }
            HapticManager.selection()
        } label: {
            VStack(spacing: 0) {
                // TOP COMPARTMENT: Icon zone (情報デザイン: distinct visual anchor)
                ZStack {
                    Image(systemName: region.icon)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(hasItems ? region.accentColor(colors: colors) : colors.primary.opacity(JohoDimensions.opacityStrong))

                    // Active indicator (top-right corner)
                    if isActive {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: IconCatalog.checkmarkCircleFill)
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
                .background(hasItems ? region.lightBackground(colors: colors) : colors.inputBackground)

                // Horizontal divider
                Rectangle()
                    .fill(colors.primary)
                    .frame(height: 1.5)

                // BOTTOM COMPARTMENT: Data zone
                VStack(spacing: 4) {
                    // Region code (bold, prominent)
                    Text(region.id)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(colors.primary)

                    // Local name
                    Text(region.localName)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
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
                                        .foregroundStyle(colors.primary)
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
                                        .foregroundStyle(colors.primary)
                                }
                            }
                        }
                    } else {
                        Text("—")
                            .font(JohoFont.caption)
                            .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 110)
            .background(colors.surface)
            .clipShape(Squircle(cornerRadius: JohoDimensions.radiusMedium))
            .overlay(
                Squircle(cornerRadius: JohoDimensions.radiusMedium)
                    .stroke(isActive ? JohoColors.green : (hasItems ? colors.primary : colors.primary.opacity(JohoDimensions.opacityMedium)),
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
                    icon: IconCatalog.holiday,
                    color: JohoColors.cyan,
                    rules: obs
                )
            }

            // Disabled section
            if !disabled.isEmpty {
                databaseSection(
                    title: "DISABLED",
                    subtitle: "Hidden from calendar",
                    icon: "eye.slash",
                    color: colors.primary.opacity(JohoDimensions.opacityMedium),
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
                        .font(JohoFont.label)
                        .foregroundStyle(colors.primary)
                        .frame(width: 24, height: 24)
                        .background(color.opacity(JohoDimensions.opacityMedium))
                        .johoBordered(cornerRadius: 5, borderWidth: 1)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(title)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(0.5)
                            .foregroundStyle(colors.primary)
                        Text(subtitle)
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
                    }
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)

                Spacer()

                // Wall
                Rectangle()
                    .fill(colors.primary)
                    .frame(width: 1.5)

                // Count compartment
                Text("\(rules.count)")
                    .font(JohoFont.headlineSmall)
                    .monospacedDigit()
                    .foregroundStyle(colors.primary)
                    .frame(width: 50)
            }
            .frame(height: 52)
            .background(color.opacity(JohoDimensions.opacitySubtle))

            // Divider
            Rectangle()
                .fill(colors.primary)
                .frame(height: 1.5)

            // Rules list
            VStack(spacing: 0) {
                ForEach(rules) { rule in
                    ruleRow(rule, color: color)

                    if rule.id != rules.last?.id {
                        Rectangle()
                            .fill(colors.primary.opacity(JohoDimensions.opacityLight))
                            .frame(height: 1)
                            .padding(.leading, JohoDimensions.spacingMD)
                    }
                }
            }
        }
        .background(colors.surface)
        .johoBordered()
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
                        .font(JohoFont.body)
                        .foregroundStyle(color)
                        .frame(width: 24)
                } else {
                    Image(systemName: rule.isBankHoliday ? "flag.fill" : "star")
                        .font(JohoFont.body)
                        .foregroundStyle(color)
                        .frame(width: 24)
                }

                // Name - 情報デザイン: Show local name with English translation
                VStack(alignment: .leading, spacing: 2) {
                    // Primary: Local name if available, else English
                    if let localName = rule.localName, !localName.isEmpty {
                        Text(localName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(rule.isEnabled ? colors.primary : colors.primary.opacity(JohoDimensions.opacityModerate))
                            .lineLimit(1)
                        // Secondary: English translation
                        Text(displayName(for: rule))
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
                    } else {
                        Text(displayName(for: rule))
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(rule.isEnabled ? colors.primary : colors.primary.opacity(JohoDimensions.opacityModerate))
                            .lineLimit(1)
                        // Type description
                        Text(ruleTypeDescription(rule))
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
                    }
                }

                Spacer()

                // Modified indicator
                if rule.isModifiedFromDefault {
                    Text("※")
                        .font(JohoFont.label)
                        .foregroundStyle(JohoColors.cyan)
                }

                // Chevron
                Image(systemName: IconCatalog.chevronRight)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityMedium))
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
            Image(systemName: IconCatalog.tray)
                .font(.system(size: 48, weight: .medium, design: .rounded))
                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityMild))

            Text("No holidays in database")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(colors.primary)

            Text("Tap 'Load Defaults' to add holidays for this region")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(JohoDimensions.spacingXL)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: 1, borderColor: colors.primary.opacity(JohoDimensions.opacityMild))
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
                Image(systemName: IconCatalog.arrowDownCircle)
                    .font(JohoFont.body)
                Text("Load Defaults")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(colors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(colors.surface)
            .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: 1.5)
        }
        .buttonStyle(.plain)
    }

    private func applyToCalendarButton(for regionID: String) -> some View {
        Button {
            applyRegion(regionID)
        } label: {
            HStack(spacing: JohoDimensions.spacingSM) {
                Image(systemName: IconCatalog.checkmarkCircleFill)
                    .font(JohoFont.body)
                Text("Apply to Calendar")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(colors.surface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoDimensions.spacingMD)
            .background(JohoColors.green)
            .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: 1.5)
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
                let components = DateComponents(month: month, day: day)
                if let date = Calendar.current.date(from: components) {
                    return "Fixed: \(DateFormatterCache.weekRange.string(from: date))"
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
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
                .background(colors.surface)
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
                        .font(JohoFont.body)
                        .foregroundStyle(isEnabled ? colors.primary : colors.primary.opacity(JohoDimensions.opacityModerate))
                        .frame(width: 24)

                    Text(isEnabled ? "Visible on Calendar" : "Hidden from Calendar")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.primary)

                    Spacer()

                    // 情報デザイン: Custom toggle (マルバツ style)
                    Text(isEnabled ? "○" : "×")
                        .font(JohoFont.headline)
                        .foregroundStyle(isEnabled ? JohoColors.green : JohoColors.red)
                        .frame(width: 32, height: 32)
                        .background(isEnabled ? JohoColors.green.opacity(JohoDimensions.opacityLight) : JohoColors.red.opacity(JohoDimensions.opacityLight))
                        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
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
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityBold))
                Text("Rule type cannot be changed")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityModerate))
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
                Image(systemName: IconCatalog.arrowCounterclockwise)
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
                Image(systemName: IconCatalog.trash)
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
                .font(JohoFont.tag)
                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
                .padding(.horizontal, JohoDimensions.spacingSM)
                .padding(.bottom, 4)

            content()
                .background(colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: JohoDimensions.radiusSmall, style: .continuous)
                        .stroke(colors.primary.opacity(JohoDimensions.opacityMild), lineWidth: 1)
                )
        }
    }

    private func typeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(JohoFont.bodySmall)
                .foregroundStyle(isSelected ? colors.surface : colors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? colors.primary : colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: JohoDimensions.radiusChip, style: .continuous)
                        .stroke(colors.border, lineWidth: 1)
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
