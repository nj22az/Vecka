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
        VStack(spacing: 0) {
            // ═══════════════════════════════════════════════════════════════
            // HEADER: App branding + icon
            // ═══════════════════════════════════════════════════════════════
            ShareableCardHeader(
                icon: iconName,
                iconColor: accentColor,
                accentColor: accentColor
            )

            // Divider
            ShareableCardDivider()

            // ═══════════════════════════════════════════════════════════════
            // MAIN CONTENT: Days countdown + event name
            // ═══════════════════════════════════════════════════════════════
            HStack(spacing: 0) {
                // LEFT: Days counter (large)
                VStack(spacing: 4) {
                    if daysRemaining == 0 {
                        Text("TODAY")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)
                    } else {
                        Text("\(daysRemaining)")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)

                        Text(daysRemaining == 1 ? "DAY" : "DAYS")
                            .font(JohoFont.bodySmallBold)
                            .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityBold))
                    }
                }
                .frame(width: 120)
                .frame(maxHeight: .infinity)

                // WALL
                Rectangle()
                    .fill(colors.border)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Event details
                VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                    // Event name
                    Text(name)
                        .font(JohoFont.title)
                        .foregroundStyle(colors.primary)
                        .lineLimit(2)

                    // Target date
                    Text(targetDate.formatted(.dateTime.month(.wide).day().year()))
                        .font(JohoFont.caption)
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))

                    // Annual indicator
                    if isAnnual {
                        HStack(spacing: 4) {
                            Image(systemName: IconCatalog.repeatIcon)
                                .font(JohoFont.labelBold)
                            Text("ANNUAL")
                                .font(JohoFont.labelBold)
                        }
                        .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
                    }

                    // Task progress (if has tasks)
                    if totalTasks > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: completedTasks == totalTasks ? IconCatalog.checkmarkCircleFill : "circle.dotted")
                                .font(JohoFont.label)
                                .foregroundStyle(completedTasks == totalTasks ? accentColor : colors.primary.opacity(JohoDimensions.opacityHeavy))

                            Text("\(completedTasks)/\(totalTasks) TASKS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(completedTasks == totalTasks ? accentColor : colors.primary.opacity(JohoDimensions.opacityHeavy))
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(JohoDimensions.spacingMD)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 140)
            .background(lightBackground)

            // Divider
            ShareableCardDivider()

            // ═══════════════════════════════════════════════════════════════
            // FOOTER: Countdown message (custom - uses different font sizing)
            // ═══════════════════════════════════════════════════════════════
            HStack {
                Text(countdownMessage)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityBold))

                Spacer()

                // 情報デザイン: Japanese design mark
                Text("情報")
                    .font(JohoFont.labelBold)
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityModerate))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .frame(height: 32)
            .background(colors.surface)
        }
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: JohoDimensions.radiusLarge, style: .continuous)
                .stroke(colors.border, lineWidth: 3)
        )
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
