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

    // MARK: - Category Cards (Bento Style)

    @ViewBuilder
    private var categoryCardsGrid: some View {
        let counts = monthUniqueCounts()

        VStack(spacing: JohoDimensions.spacingSM) {
            if counts.holidays > 0 {
                categoryBentoCard(category: .holiday, count: counts.holidays)
            }
            if counts.observances > 0 {
                categoryBentoCard(category: .observance, count: counts.observances)
            }
            if counts.memos > 0 {
                categoryBentoCard(category: .memo, count: counts.memos)
            }
        }
        .id(categoryCustomizationsVersion)
        .padding(.horizontal, JohoDimensions.spacingLG)
    }

    // MARK: - Bento Category Card

    @ViewBuilder
    private func categoryBentoCard(category: DisplayCategory, count: Int) -> some View {
        let displayIcon = category.categoryAwareIcon
        let categoryColor = CategoryColorSettings.shared.color(for: category)
        let previewItems = collectPreviewItems(for: category, limit: 3)

        VStack(alignment: .leading, spacing: 0) {
            // Header — sticker + label + count (tinted banner)
            HStack(spacing: JohoDimensions.spacingSM) {
                JohoSticker(content: .icon(displayIcon), color: categoryColor, size: 28)

                Text(category.localizedLabel.uppercased())
                    .font(JohoFont.headerTag)
                    .tracking(1)
                    .foregroundStyle(colors.primary)

                Spacer()

                Text("\(count)")
                    .font(JohoFont.labelBold)
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .background(categoryColor.opacity(JohoDimensions.opacityLight))

            // Divider
            Rectangle()
                .fill(colors.border)
                .frame(height: 1.5)

            // Content — preview rows
            VStack(alignment: .leading, spacing: JohoDimensions.spacingXS) {
                ForEach(previewItems, id: \.id) { item in
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Text(DateFormatterCache.monthDay.string(from: item.date))
                            .font(JohoFont.bodySmall)
                            .foregroundStyle(colors.secondary)
                            .frame(width: 56, alignment: .leading)

                        Text(item.title)
                            .font(JohoFont.body)
                            .foregroundStyle(colors.primary)
                            .lineLimit(1)
                    }
                }

                if count > 3 {
                    Text("+\(count - 3) more")
                        .font(JohoFont.bodySmall)
                        .foregroundStyle(colors.secondary)
                }
            }
            .padding(JohoDimensions.spacingMD)
        }
        .background(colors.surface)
        .johoBordered()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
            HapticManager.selection()
        }
    }

    // MARK: - Preview Item Collection

    private func collectPreviewItems(for category: DisplayCategory, limit: Int) -> [SpecialDayRow] {
        let dayCards = filteredDayCards(category)
        var items: [SpecialDayRow] = []
        for dayCard in dayCards {
            for item in dayCard.items {
                items.append(item)
                if items.count >= limit { return items }
            }
        }
        return items
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
