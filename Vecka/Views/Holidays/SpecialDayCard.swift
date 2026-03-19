//
//  SpecialDayCard.swift
//  Vecka
//
//  情報デザイン: Collapsible day card for special days timeline.
//  Extracted from SpecialDaysListView for focused component architecture.
//
//  Renders a single day's worth of special items as a collapsible bento card:
//  - Collapsed: header row with date badge + category dot indicators
//  - Expanded: sectioned list of holidays, observances, and memos
//

import SwiftUI

// MARK: - Collapsible Special Day Card

struct CollapsibleSpecialDayCard: View {
    let dayCard: DayCardData
    let isExpanded: Bool
    let onToggle: () -> Void

    // Closures for data management (passed from parent)
    let isEditable: (SpecialDayRow) -> Bool
    let deleteRow: (SpecialDayRow) -> Void
    let openEditor: (SpecialDayRow) -> Void
    let showDetail: (SpecialDayRow) -> Void

    // Item expansion state (情報デザイン: tap row to show details)
    @Binding var expandedItemID: String?

    // Locale for displaying localized holiday names (情報デザイン: show user's locale name)
    @Environment(\.locale) private var locale
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let calendar = Calendar.iso8601

    // Group items by type
    private var holidays: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .holiday }
    }

    /// Consolidated holidays: Groups same-name holidays into single rows with multiple country pills
    private var consolidatedHolidays: [ConsolidatedHoliday] {
        let holidays = dayCard.items.filter { $0.type == .holiday }
        guard !holidays.isEmpty else { return [] }

        // 情報デザイン: Group by DATE, not by title
        // Same date + same type = same semantic holiday (regardless of localized name)
        // All items in dayCard are already for the same date, so consolidate ALL holidays
        // into one row with multiple country pills
        if let consolidated = ConsolidatedHoliday.from(holidays: holidays) {
            return [consolidated]
        }
        return []
    }
    private var observances: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .observance }
    }
    private var birthdays: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .birthday }
    }
    private var memosForDay: [SpecialDayRow] {
        dayCard.items.filter { $0.type == .memo }
    }

    private var isToday: Bool {
        calendar.isDateInToday(dayCard.date)
    }

    /// Days from today (negative = past, positive = future)
    private var daysFromToday: Int {
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: dayCard.date)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    /// Date status pill for the day header (情報デザイン: Only TODAY highlighted)
    @ViewBuilder
    private var dateStatusPill: some View {
        if daysFromToday == 0 {
            // TODAY - Orange inverted pill (consistent with calendar)
            JohoPill(text: "TODAY", style: .coloredInverted(JohoColors.todayOrange), size: .small)
        }
        // Past/future dates: no pill needed (date is already visible)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row (always visible)
            headerRow

            // Expanded content
            if isExpanded {
                // Thin divider
                Rectangle()
                    .fill(colors.border.opacity(JohoDimensions.opacityLight))
                    .frame(height: 1)

                expandedContent
                    .padding(.top, JohoDimensions.spacingSM)
                    .padding(.bottom, JohoDimensions.spacingMD)
            }
        }
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: isToday ? JohoDimensions.borderThick : JohoDimensions.borderMedium)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        Button(action: onToggle) {
            HStack(spacing: JohoDimensions.spacingSM) {
                // Day badge: [THU 1]
                dayBadge

                // Full date: January 1, 2026
                Text(fullDateText)
                    .font(JohoFont.body)
                    .foregroundStyle(colors.primary)

                Spacer()

                // Status indicators
                HStack(spacing: JohoDimensions.spacingXS) {
                    // Date status pill (情報デザイン: TODAY, YESTERDAY, or X DAYS AGO)
                    dateStatusPill

                    // Content indicator dots (when collapsed)
                    if !isExpanded {
                        contentIndicatorDots
                    }

                    // Expand/collapse chevron
                    Image(systemName: isExpanded ? IconCatalog.chevronDown : IconCatalog.chevronRight)
                        .font(JohoFont.bodySmallBold)
                        .foregroundStyle(colors.primary)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Day Badge

    private var dayBadge: some View {
        HStack(spacing: 4) {
            Text(weekdayShort)
                .font(JohoFont.labelSmall)
            Text("\(dayCard.day)")
                .font(JohoFont.headline)
        }
        .foregroundStyle(isToday ? JohoColors.black : colors.primary)
        .padding(.horizontal, JohoDimensions.spacingSM)
        .padding(.vertical, JohoDimensions.spacingXS)
        .background(isToday ? JohoColors.todayOrange : colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: JohoDimensions.borderThin)
    }

    // MARK: - Content Indicator Icons (情報デザイン: Black outline shapes)

    private var contentIndicatorDots: some View {
        HStack(spacing: 6) {
            // 情報デザイン: 3-category indicator system
            // Colored dots are FIXED (red, blue, green) - colors encode category meaning
            // Icons are separate and customizable via database

            // Holidays - Red dot
            if holidays.isNotEmpty {
                HStack(spacing: 2) {
                    Circle()
                        .fill(CategoryColorSettings.shared.color(for: .holiday))
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(colors.border, lineWidth: 0.5))
                    Text("\(holidays.count)")
                        .font(JohoFont.labelBold)
                        .foregroundStyle(colors.primary)
                }
            }

            // Observances - Blue dot
            if observances.isNotEmpty {
                HStack(spacing: 2) {
                    Circle()
                        .fill(CategoryColorSettings.shared.color(for: .observance))
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(colors.border, lineWidth: 0.5))
                    Text("\(observances.count)")
                        .font(JohoFont.labelBold)
                        .foregroundStyle(colors.primary)
                }
            }

            // Memos + Birthdays - Green dot
            if birthdays.isNotEmpty || memosForDay.isNotEmpty {
                HStack(spacing: 2) {
                    Circle()
                        .fill(CategoryColorSettings.shared.color(for: .memo))
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(colors.border, lineWidth: 0.5))
                    Text("\(birthdays.count + memosForDay.count)")
                        .font(JohoFont.labelBold)
                        .foregroundStyle(colors.primary)
                }
            }
        }
    }

    // MARK: - Expanded Content

    /// Combined birthdays + memos for 情報デザイン 3-category system
    private var combinedMemos: [SpecialDayRow] {
        // Birthdays + memos combined under メモ category (GREEN)
        (birthdays + memosForDay).sorted { $0.date < $1.date }
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
            // 情報デザイン: 3-category system
            // RED = Holidays, BLUE = Observances
            // GREEN = Memos (includes birthdays)

            // Icons resolve via DisplayCategory.categoryAwareIcon

            // Holidays (PINK zone)
            if consolidatedHolidays.isNotEmpty {
                consolidatedHolidaySection(
                    title: DisplayCategory.holiday.localizedLabel,
                    items: consolidatedHolidays,
                    zone: .holidays,
                    icon: DisplayCategory.holiday.categoryAwareIcon
                )
            }

            // Observances (CYAN zone)
            if observances.isNotEmpty {
                specialDaySection(
                    title: DisplayCategory.observance.localizedLabel,
                    items: observances,
                    zone: .observances,
                    icon: DisplayCategory.observance.categoryAwareIcon
                )
            }

            // Memos (GREEN zone - includes birthdays)
            if combinedMemos.isNotEmpty {
                specialDaySection(
                    title: DisplayCategory.memo.localizedLabel,
                    items: combinedMemos,
                    zone: .memos,
                    icon: DisplayCategory.memo.categoryAwareIcon
                )
            }
        }
        .padding(.horizontal, JohoDimensions.spacingMD)
    }

    // MARK: - Section Box (情報デザイン: Bento with compartmentalized header)

    @ViewBuilder
    private func specialDaySection(title: String, items: [SpecialDayRow], zone: SectionZone, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header (情報デザイン: Bento with icon in RIGHT compartment)
            HStack(spacing: 0) {
                // LEFT: Title pill
                JohoPill(text: title.uppercased(), style: .whiteOnBlack, size: .small)
                    .padding(.leading, JohoDimensions.spacingMD)

                Spacer()

                // WALL (vertical divider)
                Rectangle()
                    .fill(colors.border)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Icon compartment sticker
                JohoSticker.mini(icon: icon, color: zone.background(for: colorMode))
                    .frame(width: 40)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 32)
            .background(zone.background(for: colorMode).opacity(JohoDimensions.opacityHeavy))  // Colored header

            // Horizontal divider between header and items
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Items on WHITE background (情報デザイン: white content backgrounds)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    specialDayItemRow(item, zone: zone)

                    // Divider between items (not after last)
                    if index < items.count - 1 {
                        Rectangle()
                            .fill(colors.border.opacity(JohoDimensions.opacityMedium))
                            .frame(height: 1)
                            .padding(.horizontal, 6)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(colors.surface)  // WHITE body instead of colored
        }
        .johoBordered()
    }

    // MARK: - Consolidated Holiday Section (情報デザイン: Same-name holidays merged)

    @ViewBuilder
    private func consolidatedHolidaySection(title: String, items: [ConsolidatedHoliday], zone: SectionZone, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header (情報デザイン: Bento with icon in RIGHT compartment)
            HStack(spacing: 0) {
                // LEFT: Title pill
                JohoPill(text: title.uppercased(), style: .whiteOnBlack, size: .small)
                    .padding(.leading, JohoDimensions.spacingMD)

                Spacer()

                // WALL (vertical divider)
                Rectangle()
                    .fill(colors.border)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Icon compartment sticker
                JohoSticker.mini(icon: icon, color: zone.background(for: colorMode))
                    .frame(width: 40)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 32)
            .background(zone.background(for: colorMode).opacity(JohoDimensions.opacityHeavy))  // Colored header

            // Horizontal divider between header and items
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Items on WHITE background (情報デザイン: white content backgrounds)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    consolidatedHolidayRow(item, zone: zone)

                    // Divider between items (not after last)
                    if index < items.count - 1 {
                        Rectangle()
                            .fill(colors.border.opacity(JohoDimensions.opacityMedium))
                            .frame(height: 1)
                            .padding(.horizontal, 6)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(colors.surface)  // WHITE body instead of colored
        }
        .johoBordered()
    }

    // MARK: - Consolidated Holiday Row

    @ViewBuilder
    private func consolidatedHolidayRow(_ item: ConsolidatedHoliday, zone: SectionZone) -> some View {
        HStack(spacing: JohoDimensions.spacingSM) {
            // Holiday name (情報デザイン: icon already in header, no need to repeat)
            Text(item.displayName(for: locale))
                .padding(.leading, JohoDimensions.spacingMD)
                .font(JohoFont.body)
                .foregroundStyle(colors.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            // Region codes as plain text (情報デザイン: Clean, minimal)
            regionCodesText(regions: item.regions)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        // 情報デザイン: Tap shows detail sheet for first item in consolidated group
        .onTapGesture {
            if let firstItem = item.sourceRows.first {
                showDetail(firstItem)
                HapticManager.selection()
            }
        }
    }

    // MARK: - Region Codes Text

    /// Shows region codes as plain text ("NO SE FI") with optional overflow indicator
    @ViewBuilder
    private func regionCodesText(regions: [String]) -> some View {
        let maxVisible = 4
        let visibleRegions = Array(regions.prefix(maxVisible))
        let overflowCount = regions.count - maxVisible

        HStack(spacing: 4) {
            Text(visibleRegions.joined(separator: " "))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))

            if overflowCount > 0 {
                Text("+\(overflowCount)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityModerate))
            }
        }
        .padding(.trailing, JohoDimensions.spacingMD)
    }

    // MARK: - Item Row (情報デザイン Bento: Compartmentalized with walls)

    @ViewBuilder
    private func specialDayItemRow(_ item: SpecialDayRow, zone: SectionZone) -> some View {
        let canEdit = isEditable(item)
        let isExpanded = expandedItemID == item.id

        VStack(spacing: 0) {
            // MAIN ROW (情報デザイン: vertical growth, no truncation)
            HStack(alignment: .top, spacing: JohoDimensions.spacingSM) {
                // Content area - grows vertically as needed
                if item.type == .birthday {
                    // Birthday: two-line layout (name + 🎂 age)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(JohoFont.body)
                            .foregroundStyle(colors.primary)
                        if let age = item.turningAge {
                            // 情報デザイン: Icon + number (no words needed)
                            HStack(spacing: 4) {
                                Image(systemName: IconCatalog.birthdayCake)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                Text("\(age)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
                        }
                    }
                    .padding(.leading, JohoDimensions.spacingMD)
                } else {
                    // Regular memo/observance: single text, wraps vertically
                    Text(item.title)
                        .font(JohoFont.body)
                        .padding(.leading, JohoDimensions.spacingMD)
                        .foregroundStyle(colors.primary)
                }

                Spacer(minLength: 8)

                // Region codes as plain text (情報デザイン: Clean, minimal)
                if item.hasCountryPill {
                    let regions = item.mergedRegions.isEmpty ? [item.region] : item.mergedRegions
                    Text(regions.joined(separator: " "))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
                        .padding(.trailing, JohoDimensions.spacingMD)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            // 情報デザイン: Tap shows detail sheet, long-press expands inline
            .contentShape(Rectangle())
            .onTapGesture {
                showDetail(item)
                HapticManager.selection()
            }
            .onLongPressGesture(minimumDuration: 0.3) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedItemID = isExpanded ? nil : item.id
                }
                HapticManager.impact(.light)
            }

            // EXPANDED DETAILS (情報デザイン: tap to reveal)
            if isExpanded {
                // Horizontal divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 1.5)

                // Details area - separate from tap gesture
                HStack(spacing: 8) {
                    // 情報デザイン: Only show notes if they ADD information beyond title
                    // For .note type, notes = full content, title = first line
                    // Don't show if notes == title (single-line note)
                    if let notes = item.notes,
                       !notes.isEmpty,
                       notes != item.title {
                        // Show additional content (lines beyond first)
                        let additionalLines = notes.components(separatedBy: .newlines).dropFirst().joined(separator: "\n")
                        if !additionalLines.isEmpty {
                            Text(additionalLines)
                                .font(JohoFont.caption)
                                .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityDense))
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    // Date badge
                    Text(formatDate(item.date))
                        .font(JohoFont.labelBold)
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(colors.border.opacity(JohoDimensions.opacityFaint))
                        .clipShape(Capsule())

                    // Edit button (for user entries) - 情報デザイン: 44pt touch target
                    if canEdit {
                        Button {
                            openEditor(item)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: IconCatalog.pencil)
                                Text("EDIT")
                            }
                            .font(JohoFont.labelBold)
                            .foregroundStyle(JohoColors.cyan.contrastingForeground)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(JohoColors.cyan)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(colors.border, lineWidth: 1.5))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
        }
        // 情報デザイン: Context menu for Edit/Delete (long-press)
        // Clean UI - no swipe clutter, just long-press for actions
        .contextMenu {
            if canEdit {
                Button {
                    openEditor(item)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    deleteRow(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                // System entry - show info only
                Text("System entry (read-only)")
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Formatters

    private var weekdayShort: String {
        DateFormatterCache.weekdayShort.string(from: dayCard.date).uppercased()
    }

    private var fullDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: dayCard.date)
    }
}
