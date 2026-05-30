//
//  ShareableCountdown.swift
//  Vecka
//
//  情報デザイン: Shareable countdown cards using Transferable protocol
//  Renders countdown events as shareable PNG images
//

import SwiftUI
import CoreTransferable

// MARK: - Shareable Countdown Snapshot (Transferable)

/// A countdown that can be shared as an image
/// Inspired by Swift Playgrounds Meme Creator pattern
@available(iOS 16.0, *)
struct ShareableCountdownSnapshot: Transferable {
    let countdown: CustomCountdown
    let daysRemaining: Int
    let size: CGSize

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { snapshot in
            await snapshot.renderToPNG()
        }
    }

    /// Renders the countdown card view to PNG data
    @MainActor
    func renderToPNG() -> Data {
        // Use shared CardSnapshotRenderer for countdown (fixed height)
        let view = ShareableCountdownCard(
            name: countdown.name,
            daysRemaining: daysRemaining,
            targetDate: countdown.date,
            iconName: countdown.iconName ?? IconCatalog.event,
            isAnnual: countdown.isAnnual,
            tasks: countdown.tasks
        )
        .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        renderer.isOpaque = false

        guard let uiImage = renderer.uiImage else {
            return Data()
        }

        return uiImage.pngData() ?? Data()
    }
}

// MARK: - Shareable Countdown Card View (情報デザイン styled)

/// A beautiful countdown card designed for sharing
/// Uses 情報デザイン bento styling with clean compartments
struct ShareableCountdownCard: View {
    let name: String
    let daysRemaining: Int
    let targetDate: Date
    let iconName: String
    let isAnnual: Bool
    let tasks: [EventTask]

    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    // 情報デザイン: Event color (purple/cyan)
    private var accentColor: Color { JohoColors.cyan }
    private var lightBackground: Color { JohoColors.cyan.opacity(JohoDimensions.opacityLight) }

    private var completedTasks: Int {
        tasks.filter { $0.isCompleted && !$0.text.isEmpty }.count
    }

    private var totalTasks: Int {
        tasks.filter { !$0.text.isEmpty }.count
    }

    var body: some View {
        ShareableCardShell(
            headerIcon: iconName,
            headerIconColor: accentColor,
            headerAccentColor: accentColor,
            footerLeftLabel: "COUNTDOWN",
            footerRightLabel: "情報"
        ) {
            // 情報デザイン: 7-compartment packaging layout. JDS §12.
            ShareableCardDivider()

            VStack(spacing: JohoDimensions.spacingSM) {

                // 1. HOOK — countdown message as the loud slogan
                PackagingHook(
                    countdownMessage.uppercased(),
                    subline: name
                )

                // 2. CLAIM PILL — annual / one-off badge
                PackagingClaimPill(
                    isAnnual ? "ANNUAL EVENT" : "ONE-OFF EVENT",
                    subtitle: isAnnual ? "Repeats every year" : "Single occurrence",
                    tint: isAnnual ? JohoColors.purple : JohoColors.cyan
                )

                // 3. TASKS — only if any present; uses the ingredients pattern
                if totalTasks > 0 {
                    PackagingIngredientsBox(
                        entries: taskEntries,
                        allergens: completedTasks == totalTasks ? "ALL DONE" : nil
                    )
                }

                // 4. NUTRITION — the countdown stats
                PackagingNutritionTable(
                    title: "Countdown Stats",
                    rows: nutritionRows,
                    footnote: nil
                )

                // 5. MANUFACTURER — target date as the highlighted "Best Before"
                PackagingManufacturerBlock(
                    maker: "Onsen Planner",
                    bestBefore: targetDateStamp,
                    storage: nil
                )

                // 6. CODE FOOTER
                PackagingCodeFooter(
                    identifier: "CD-\(targetDateStamp)",
                    url: "vecka://countdown"
                )
            }
            .padding(JohoDimensions.spacingSM)
            .background(lightBackground)

            ShareableCardDivider()
        }
    }

    private var targetDateStamp: String {
        DateFormatterCache.compactDate.string(from: targetDate)
    }

    private var taskEntries: [PackagingIngredientsBox.Entry] {
        tasks.filter { !$0.text.isEmpty }.prefix(8).map { task in
            .init(label: task.isCompleted ? "DONE" : "TODO", value: task.text)
        }
    }

    private var nutritionRows: [PackagingNutritionTable.Row] {
        var rows: [PackagingNutritionTable.Row] = []
        rows.append(.init(
            label: "Days Left",
            value: daysRemaining == 0 ? "TODAY" : "\(daysRemaining)"
        ))
        rows.append(.init(label: "Target", value: targetDate.formatted(.dateTime.month(.abbreviated).day())))
        if totalTasks > 0 {
            rows.append(.init(label: "Tasks", value: "\(completedTasks)/\(totalTasks)"))
        }
        return rows
    }

    private var countdownMessage: String {
        if daysRemaining == 0 {
            return "The day has arrived!"
        } else if daysRemaining == 1 {
            return "Just one more day to go!"
        } else if daysRemaining <= 7 {
            return "Less than a week away!"
        } else if daysRemaining <= 30 {
            return "Coming up this month!"
        } else {
            return "Mark your calendar!"
        }
    }
}

// MARK: - Share Button for Countdown

/// A share button that creates a shareable countdown snapshot
@available(iOS 16.0, *)
struct CountdownShareButton: View {
    let countdown: CustomCountdown
    let daysRemaining: Int

    private var snapshot: ShareableCountdownSnapshot {
        ShareableCountdownSnapshot(
            countdown: countdown,
            daysRemaining: daysRemaining,
            size: CGSize(width: 340, height: 220)
        )
    }

    var body: some View {
        ShareLink(
            item: snapshot,
            preview: SharePreview(
                countdown.name,
                image: Image(systemName: countdown.iconName ?? IconCatalog.event)
            )
        ) {
            Image(systemName: IconCatalog.share)
                .font(JohoFont.bodySmallBold)
                .foregroundStyle(JohoColors.cyan)
                .frame(width: 32, height: 32)
                .background(JohoColors.cyan.opacity(JohoDimensions.opacityLight))
                .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1, borderColor: JohoColors.black)
        }
    }
}

// MARK: - Preview

#Preview("Shareable Countdown Card") {
    VStack(spacing: 20) {
        ShareableCountdownCard(
            name: "Summer Vacation",
            daysRemaining: 42,
            targetDate: Date().addingTimeInterval(86400 * 42),
            iconName: "sun.max.fill",
            isAnnual: false,
            tasks: [
                EventTask(text: "Book flights", isCompleted: true),
                EventTask(text: "Pack bags", isCompleted: false),
                EventTask(text: "Hotel reservation", isCompleted: true)
            ]
        )
        .frame(width: 340, height: 220)

        ShareableCountdownCard(
            name: "Christmas",
            daysRemaining: 0,
            targetDate: Date(),
            iconName: "gift.fill",
            isAnnual: true,
            tasks: []
        )
        .frame(width: 340, height: 220)
    }
    .padding()
    .johoBackground()
}
