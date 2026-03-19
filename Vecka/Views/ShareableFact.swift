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
        ShareableCardFrame {
            // Banner: country left + circle sticker right (matches grid tiles)
            HStack {
                Text(fact.displaySource.uppercased())
                    .font(JohoFont.pillLabel)
                    .foregroundStyle(colors.primary)
                    .lineLimit(1)

                Spacer()

                JohoSticker(content: .icon(fact.icon ?? "lightbulb.fill"), color: fact.color, shape: .circle, size: 24)
            }
            .padding(.horizontal, JohoDimensions.spacingMD)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(fact.color.opacity(JohoDimensions.opacityLight))

            ShareableCardDivider()

            // Full-width fact text
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

            ShareableCardDivider()

            // Footer: category left, app branding right
            ShareableCardFooter(
                leftLabel: fact.displayCategory.uppercased(),
                rightLabel: "ONSEN PLANNER"
            )
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
                image: Image(systemName: fact.icon ?? IconCatalog.lightbulbFill)
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
