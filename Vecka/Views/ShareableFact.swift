//
//  ShareableFact.swift
//  Vecka
//
//  情報デザイン: Shareable fact cards using Transferable protocol
//  Renders facts as shareable PNG images (meme-style)
//

import SwiftUI
import UIKit
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
        let renderer = ImageRenderer(content: shareableView())
        renderer.scale = 3.0  // 3x for crisp sharing
        renderer.isOpaque = false  // 情報デザイン: Allow transparency for rounded corners

        guard let uiImage = renderer.uiImage else {
            return Data()
        }

        return uiImage.pngData() ?? Data()
    }

    /// The view to render for sharing
    @MainActor
    func shareableView() -> some View {
        ShareableFactCard(fact: fact, isShareable: true)
            .frame(width: size.width)
            .fixedSize(horizontal: false, vertical: true)
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

    private let cornerRadius: CGFloat = 16

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        // 情報デザイン: ZStack ensures white background fills corners before content
        ZStack {
            // Layer 1: Solid background (fills squircle corners)
            cardShape
                .fill(colors.surface)

            // Layer 2: Content compartments
            VStack(spacing: 0) {
                // ═══════════════════════════════════════════════════════════════
                // HEADER: App branding + icon
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: App branding
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)

                        Text("ONSEN PLANNER")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary)
                    }
                    .padding(.leading, JohoDimensions.spacingMD)

                    Spacer()

                    // WALL
                    Rectangle()
                        .fill(colors.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)

                    // RIGHT: Fact icon
                    Image(systemName: fact.icon ?? "lightbulb.fill")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(fact.color)
                        .frame(width: 48)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 40)
                .background(fact.color.opacity(0.5))

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

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
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .lineLimit(isShareable ? nil : 4)
                            .multilineTextAlignment(.leading)

                        if !fact.explanation.isEmpty {
                            Text(fact.explanation)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary.opacity(0.6))
                                .lineLimit(isShareable ? nil : 3)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(JohoDimensions.spacingMD)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 140)
                .background(fact.color.opacity(0.15))

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // ═══════════════════════════════════════════════════════════════
                // FOOTER: Random Facts branding with source country
                // ═══════════════════════════════════════════════════════════════
                HStack {
                    Text("RANDOM FACTS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .tracking(1)

                    Spacer()

                    // Source country/category
                    Text(fact.displaySource.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.4))
                        .tracking(0.5)
                }
                .padding(.horizontal, JohoDimensions.spacingMD)
                .padding(.vertical, JohoDimensions.spacingSM)
                .frame(height: 32)
            }
            .clipShape(cardShape)

            // Layer 3: Border (strokeBorder keeps it inside the shape)
            cardShape
                .strokeBorder(colors.border, lineWidth: 3)
        }
    }
}

// MARK: - Share Button for Fact

/// A share button that creates a shareable fact snapshot
@available(iOS 16.0, *)
struct FactShareButton: View {
    let fact: RandomFact
    @Environment(\.johoColorMode) private var colorMode
    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

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
            ZStack {
                Circle()
                    .fill(colors.surface)
                    .frame(width: 28, height: 28)
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(colors.primary)
            }
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
