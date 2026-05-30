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
            footerLeftLabel: "RANDOM FACTS",
            footerRightLabel: fact.displaySource.uppercased()
        ) {
            // 情報デザイン: Japanese 7-compartment packaging layout.
            // JDS §12 — header(existing) → hook → claim pill → details
            // → manufacturer → code footer → footer(existing).
            ShareableCardDivider()

            VStack(spacing: JohoDimensions.spacingSM) {

                // 1. HOOK — the fact text itself, as the loud slogan
                PackagingHook(fact.text)

                // 2. CLAIM PILL — category, tinted with the fact color
                PackagingClaimPill(
                    "RANDOM FACT",
                    subtitle: fact.explanation.isEmpty ? nil : "Did you know?",
                    tint: fact.color
                )

                // 3. DETAILS — explanation, only if present.
                //    Uses the bordered "ingredients" pattern with a single entry.
                if !fact.explanation.isEmpty {
                    PackagingIngredientsBox(
                        entries: [
                            .init(label: "About", value: fact.explanation)
                        ]
                    )
                }

                // 4. MANUFACTURER — source attribution as the "trust" block
                PackagingManufacturerBlock(
                    maker: fact.displaySource,
                    bestBefore: nil,
                    storage: nil
                )

                // 5. CODE FOOTER — short id + URL stub
                PackagingCodeFooter(
                    identifier: shortID,
                    url: "vecka://fact"
                )
            }
            .padding(JohoDimensions.spacingSM)
            .background(fact.color.opacity(JohoDimensions.opacityLight))

            ShareableCardDivider()
        }
    }

    /// First 8 chars of the fact id — short enough to fit, unique enough
    /// to scan. Falls back to the source code if id is empty.
    private var shortID: String {
        let raw = fact.id.replacingOccurrences(of: "-", with: "")
        let prefix = String(raw.prefix(8)).uppercased()
        return prefix.isEmpty ? fact.displaySource.uppercased() : "FACT-\(prefix)"
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
                    source: "SE"
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
                    source: "SE"
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
