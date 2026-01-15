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
        let renderer = ImageRenderer(content: shareableView())
        renderer.scale = 3.0  // 3x for crisp sharing

        guard let uiImage = renderer.uiImage else {
            return Data()
        }

        return uiImage.pngData() ?? Data()
    }

    /// The view to render for sharing
    @MainActor
    func shareableView() -> some View {
        ShareableCountdownCard(
            name: countdown.name,
            daysRemaining: daysRemaining,
            targetDate: countdown.date,
            iconName: countdown.iconName ?? "calendar.badge.clock",
            isAnnual: countdown.isAnnual,
            tasks: countdown.tasks
        )
        .frame(width: size.width, height: size.height)
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

    // 情報デザイン: Event color (purple/cyan)
    private var accentColor: Color { JohoColors.cyan }
    private var lightBackground: Color { JohoColors.cyan.opacity(0.15) }

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
            HStack(spacing: 0) {
                // LEFT: App branding
                HStack(spacing: JohoDimensions.spacingSM) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)

                    Text("ONSEN PLANNER")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                }
                .padding(.leading, JohoDimensions.spacingMD)

                Spacer()

                // WALL
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Event icon
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .frame(width: 48)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 40)
            .background(accentColor.opacity(0.5))

            // Divider
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 2)

            // ═══════════════════════════════════════════════════════════════
            // MAIN CONTENT: Days countdown + event name
            // ═══════════════════════════════════════════════════════════════
            HStack(spacing: 0) {
                // LEFT: Days counter (large)
                VStack(spacing: 4) {
                    if daysRemaining == 0 {
                        Text("TODAY")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(JohoColors.black)
                    } else {
                        Text("\(daysRemaining)")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundStyle(JohoColors.black)

                        Text(daysRemaining == 1 ? "DAY" : "DAYS")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(JohoColors.black.opacity(0.7))
                    }
                }
                .frame(width: 120)
                .frame(maxHeight: .infinity)

                // WALL
                Rectangle()
                    .fill(JohoColors.black)
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)

                // RIGHT: Event details
                VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                    // Event name
                    Text(name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(JohoColors.black)
                        .lineLimit(2)

                    // Target date
                    Text(targetDate.formatted(.dateTime.month(.wide).day().year()))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(JohoColors.black.opacity(0.6))

                    // Annual indicator
                    if isAnnual {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 10, weight: .bold))
                            Text("ANNUAL")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(JohoColors.black.opacity(0.5))
                    }

                    // Task progress (if has tasks)
                    if totalTasks > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: completedTasks == totalTasks ? "checkmark.circle.fill" : "circle.dotted")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(completedTasks == totalTasks ? accentColor : JohoColors.black.opacity(0.5))

                            Text("\(completedTasks)/\(totalTasks) TASKS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(completedTasks == totalTasks ? accentColor : JohoColors.black.opacity(0.5))
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
            Rectangle()
                .fill(JohoColors.black)
                .frame(height: 2)

            // ═══════════════════════════════════════════════════════════════
            // FOOTER: Countdown message
            // ═══════════════════════════════════════════════════════════════
            HStack {
                Text(countdownMessage)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.7))

                Spacer()

                // 情報デザイン: Japanese design mark
                Text("情報")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(JohoColors.black.opacity(0.4))
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .padding(.vertical, JohoDimensions.spacingSM)
            .frame(height: 32)
            .background(JohoColors.white)
        }
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 3)
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
                image: Image(systemName: countdown.iconName ?? "calendar.badge.clock")
            )
        ) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.cyan)
                .frame(width: 32, height: 32)
                .background(JohoColors.cyan.opacity(0.15))
                .clipShape(Squircle(cornerRadius: 8))
                .overlay(Squircle(cornerRadius: 8).stroke(JohoColors.black, lineWidth: 1))
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
