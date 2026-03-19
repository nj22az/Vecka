//
//  SpecialDaysMonthDetail.swift
//  Vecka
//
//  情報デザイン: Single-month expanded view for the Star page.
//  Extracted from SpecialDaysListView for focused component architecture.
//
//  Shows the content for a selected month:
//  - Category cards grid (3 cards: Holidays, Observances, Memos)
//  - Filtered day card list when a category is selected
//  - Expansion state management for day cards
//

import SwiftUI

// MARK: - Special Days Month Detail

struct SpecialDaysMonthDetail: View {
    let month: Int
    let dayCardsForMonth: () -> [DayCardData]
    let filteredDayCards: (DisplayCategory) -> [DayCardData]
    let monthUniqueCounts: () -> (holidays: Int, observances: Int, memos: Int)
    let categoryCustomizationsVersion: Int

    // Editor callbacks (passed down to CollapsibleSpecialDayCard)
    let isEditable: (SpecialDayRow) -> Bool
    let deleteRow: (SpecialDayRow) -> Void
    let openEditor: (SpecialDayRow) -> Void
    let showDetail: (SpecialDayRow) -> Void

    @Binding var selectedCategory: DisplayCategory?
    @Binding var expandedItemID: String?

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    @State private var expandedDays: Set<String> = []

    var body: some View {
        VStack(spacing: JohoDimensions.spacingMD) {
            if selectedCategory == nil {
                // 情報デザイン: Show category cards grid (mirrors month grid structure)
                categoryCardsGrid
            } else if let category = selectedCategory {
                // Show filtered day cards for selected category
                let dayCards = filteredDayCards(category)

                if dayCards.isEmpty {
                    // 情報デザイン: Use customized icon if set, otherwise default
                    let displayIcon = category.categoryAwareIcon
                    JohoEmptyState(
                        title: "No \(category.localizedLabel)",
                        message: "Tap + to add",
                        icon: displayIcon,
                        zone: category.sectionZone
                    )
                    .padding(.top, JohoDimensions.spacingSM)
                } else {
                    // Collapsible timeline (情報デザイン: clean, expandable day cards)
                    VStack(spacing: JohoDimensions.spacingSM) {
                        ForEach(dayCards) { dayCard in
                            CollapsibleSpecialDayCard(
                                dayCard: dayCard,
                                isExpanded: expandedDays.contains(dayCard.id),
                                onToggle: { toggleExpand(dayCard) },
                                isEditable: isEditable,
                                deleteRow: deleteRow,
                                openEditor: openEditor,
                                showDetail: showDetail,
                                expandedItemID: $expandedItemID
                            )
                        }
                    }
                    .padding(.horizontal, JohoDimensions.spacingLG)
                }
            }
        }
        .onAppear { initializeExpandedDays(for: dayCardsForMonth()) }
        .onChange(of: month) { _, _ in
            expandedDays.removeAll()
            selectedCategory = nil
            initializeExpandedDays(for: dayCardsForMonth())
        }
        .onChange(of: selectedCategory) { _, _ in
            expandedDays.removeAll()
            if let category = selectedCategory {
                initializeExpandedDays(for: filteredDayCards(category))
            } else {
                initializeExpandedDays(for: dayCardsForMonth())
            }
        }
    }

    // MARK: - Category Cards Grid

    @ViewBuilder
    private var categoryCardsGrid: some View {
        let counts = monthUniqueCounts()

        // 情報デザイン: Grid (not LazyVGrid) ensures synchronized row heights
        Grid(horizontalSpacing: JohoDimensions.spacingSM, verticalSpacing: JohoDimensions.spacingSM) {
            GridRow {
                categoryCard(category: .holiday, count: counts.holidays)
                categoryCard(category: .observance, count: counts.observances)
                categoryCard(category: .memo, count: counts.memos)
            }
        }
        .id(categoryCustomizationsVersion)  // 情報デザイン: Force refresh when customizations change
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Category Card

    @ViewBuilder
    private func categoryCard(category: DisplayCategory, count: Int) -> some View {
        // 情報デザイン: Custom icon allowed, color from CategoryColorSettings
        let displayIcon = category.categoryAwareIcon
        let categoryColor = CategoryColorSettings.shared.color(for: category)

        VStack(spacing: 0) {
            // TOP: Icon zone (情報デザイン: Sticker-first rendering)
            // Fixed height ensures banner dividers align across all cards
            JohoSticker.small(icon: displayIcon, color: categoryColor)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(categoryColor)

            // Divider (情報デザイン: Black wall between compartments)
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // BOTTOM: Category name + count (情報デザイン: Like message on month cards)
            // minHeight ensures all cards end at same line
            HStack(spacing: 0) {
                Spacer(minLength: 16)

                VStack(spacing: 2) {
                    Text(category.localizedLabel.uppercased())
                        .font(JohoFont.pillLabel)
                        .foregroundStyle(colors.primary)
                        .multilineTextAlignment(.center)

                    // Count always rendered for consistent height (invisible when 0)
                    Text(count > 0 ? "\(count)" : " ")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(count > 0 ? 0.6 : 0))
                }

                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(colors.surface)
        }
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusMedium, borderWidth: 1.5)
        .contentShape(Rectangle())
        // 情報デザイン: NO opacity change - colors define identity regardless of content
        // Category customization moved to Settings → CATEGORIES section
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
            HapticManager.selection()
        }
    }

    // MARK: - Expansion Helpers

    private func toggleExpand(_ dayCard: DayCardData) {
        if expandedDays.contains(dayCard.id) {
            expandedDays.remove(dayCard.id)
        } else {
            expandedDays.insert(dayCard.id)
        }
    }

    private func initializeExpandedDays(for dayCards: [DayCardData]) {
        let calendar = Calendar.iso8601
        let today = calendar.startOfDay(for: Date())

        for card in dayCards {
            let cardDay = calendar.startOfDay(for: card.date)
            // Only auto-expand TODAY (情報デザイン: minimal default expansion)
            if cardDay == today {
                expandedDays.insert(card.id)
            }
        }
    }
}
