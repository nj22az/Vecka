//
//  ShareableFact.swift
//  Vecka
//
//  情報デザイン: Shareable fact cards using Transferable protocol
//  Renders facts as shareable PNG images (meme-style)
//

import SwiftUI
import CoreTransferable

// MARK: - Shareable Fact Snapshot (Transferable)

/// A fact that can be shared as an image
/// Inspired by Swift Playgrounds Meme Creator pattern
@available(iOS 16.0, *)
struct ShareableFactSnapshot: Transferable {
    let fact: RandomFact
    let size: CGSize

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { snapshot in
            await snapshot.renderToPNG()
        }
    }

    /// Renders the fact card view to PNG data
    @MainActor
    func renderToPNG() -> Data {
        CardSnapshotRenderer.renderToPNG(
            ShareableFactCard(fact: fact, isShareable: true),
            size: size
        )
    }
}

// MARK: - Shareable Fact Card View (情報デザイン styled)

/// A beautiful fact card designed for sharing
/// Uses 情報デザイン bento styling with clean compartments
struct ShareableFactCard: View {
    let fact: RandomFact
    /// When true, text expands fully without line limits (for sharing as image)
    var isShareable: Bool = false

    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    var body: some View {
        ShareableCardShell(
            headerIcon: fact.icon ?? "lightbulb.fill",
            headerIconColor: fact.color,
            headerAccentColor: fact.color,
            footerLeftLabel: fact.displaySource.uppercased(),
            footerRightLabel: fact.displayCategory.uppercased()
        ) {
            // Divider after header
            ShareableCardDivider()

            // ═══════════════════════════════════════════════════════════════
            // MAIN CONTENT: Large icon + fact text
            // ═══════════════════════════════════════════════════════════════
            HStack(alignment: .top, spacing: 0) {
                // LEFT: Large icon
                VStack {
                    Spacer()
                    Image(systemName: fact.icon ?? "lightbulb.fill")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(fact.color)
                    Spacer()
                }
                .frame(width: 100)
                .frame(minHeight: 140)

                // WALL
                Rectangle()
                    .fill(colors.border)
                    .frame(width: 1.5)

                // RIGHT: Fact text
                VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                    Text(fact.text)
                        .font(JohoFont.headlineSmall)
                        .foregroundStyle(colors.primary)
                        .lineLimit(isShareable ? nil : 4)
                        .multilineTextAlignment(.leading)

                    if !fact.explanation.isEmpty {
                        Text(fact.explanation)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityStrong))
                            .lineLimit(isShareable ? nil : 3)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(JohoDimensions.spacingMD)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 140)
            .background(fact.color.opacity(JohoDimensions.opacityLight))

            // Divider before footer
            ShareableCardDivider()
        }
    }
}

// MARK: - Share Button for Fact

/// A share button that creates a shareable fact snapshot
@available(iOS 16.0, *)
struct FactShareButton: View {
    let fact: RandomFact

    private var snapshot: ShareableFactSnapshot {
        ShareableFactSnapshot(
            fact: fact,
            size: CGSize(width: 340, height: 0)  // Height is dynamic (content-driven)
        )
    }

    var body: some View {
        ShareLink(
            item: snapshot,
            preview: SharePreview(
                "Random Fact",
                image: Image(systemName: fact.icon ?? "lightbulb.fill")
            )
        ) {
            JohoShareCircleButton()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Shareable Fact Card") {
    ScrollView {
        VStack(spacing: 20) {
            // Compact (in-app display)
            ShareableFactCard(
                fact: RandomFact(
                    id: "preview-1",
                    text: "Swedish coffee: strongest in Europe",
                    icon: "fork.knife",
                    color: JohoColors.yellow,
                    explanation: "Swedes drink more coffee per capita than almost any other nation - about 4 cups daily. Swedish coffee is notably stronger than most European varieties, reflecting the deep cultural tradition of fika.",
                    source: "SE",
                    category: "food"
                )
            )
            .frame(width: 340, height: 220)

            // Shareable (expanded, full text)
            ShareableFactCard(
                fact: RandomFact(
                    id: "preview-2",
                    text: "Swedish coffee: strongest in Europe",
                    icon: "fork.knife",
                    color: JohoColors.yellow,
                    explanation: "Swedes drink more coffee per capita than almost any other nation - about 4 cups daily. Swedish coffee is notably stronger than most European varieties, reflecting the deep cultural tradition of fika.",
                    source: "SE",
                    category: "food"
                ),
                isShareable: true
            )
            .frame(width: 340)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }
    .johoBackground()
}
