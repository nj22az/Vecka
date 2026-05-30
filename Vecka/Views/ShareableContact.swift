//
//  ShareableContact.swift
//  Vecka
//
//  情報デザイン: Shareable contact cards using Transferable protocol
//  Renders contacts as shareable PNG images with embedded QR code
//

import SwiftUI
import UIKit
import CoreTransferable
import CoreImage.CIFilterBuiltins

// MARK: - QR Code Generator (Reusable)

enum QRCodeGenerator {
    /// Generate a QR code image from a string (typically vCard data)
    static func generate(from string: String, size: CGFloat = 100) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "H" // High error correction

        guard let outputImage = filter.outputImage else { return nil }

        // Scale to desired size
        let scaleX = size / outputImage.extent.size.width
        let scaleY = size / outputImage.extent.size.height
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Shareable Contact Snapshot (Transferable)

/// A contact that can be shared as an image
/// Inspired by ShareableFact pattern
/// Note: @unchecked Sendable because Contact is a SwiftData model used on MainActor
@available(iOS 16.0, *)
struct ShareableContactSnapshot: Transferable, @unchecked Sendable {
    let contact: Contact
    let size: CGSize

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { snapshot in
            await snapshot.renderToPNG()
        }
    }

    /// Renders the contact card view to PNG data
    @MainActor
    func renderToPNG() -> Data {
        CardSnapshotRenderer.renderToPNG(
            ShareableContactCard(contact: contact),
            size: size
        )
    }

    /// Calculate dynamic size based on contact content
    static func calculateSize(for contact: Contact) -> CGSize {
        let width: CGFloat = 340
        var height: CGFloat = 0

        // Header: 40pt + divider 2pt
        height += 42

        // Main content: hero left | info right (minHeight 140pt) + divider 2pt
        height += 140 + 2

        // QR code section: 120pt + divider 2pt
        height += 120 + 2

        // Footer: 32pt
        height += 32

        return CGSize(width: width, height: height)
    }
}

// MARK: - Shareable Contact Card View (情報デザイン styled)

/// A beautiful contact card designed for sharing
/// Uses 情報デザイン bento styling with embedded QR code
struct ShareableContactCard: View {
    let contact: Contact

    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    /// Contact group color for accents
    private var accentColor: Color {
        contact.group.swiftUIColor
    }

    var body: some View {
        ShareableCardShell(
            headerIcon: contact.group.icon,
            headerIconColor: colors.primary,
            headerAccentColor: accentColor,
            footerLeftLabel: "CONTACT CARD",
            footerRightLabel: contact.group.localizedName.uppercased()
        ) {
            // 情報デザイン: 7-compartment packaging layout. JDS §12.
            // Avatar + QR section preserved — both are functionally essential
            // (visual identity + scannable vCard data).
            ShareableCardDivider()

            VStack(spacing: JohoDimensions.spacingSM) {

                // 1. HOOK — contact name as the loud headline
                PackagingHook(
                    contact.displayName,
                    subline: contact.organizationName?.nonEmpty
                )

                // 2. CLAIM PILL — contact group, tinted with group color
                PackagingClaimPill(
                    contact.group.localizedName.uppercased(),
                    subtitle: nil,
                    tint: accentColor
                )

                // AVATAR + QR — preserved compartment (not from packaging spec,
                // but functionally critical: identity + scannable vCard)
                avatarAndQRSection

                // 3. INGREDIENTS — contact methods as bulleted spec
                if !contactEntries.isEmpty {
                    PackagingIngredientsBox(
                        entries: contactEntries,
                        allergens: nil
                    )
                }

                // 4. NUTRITION — contact stats
                PackagingNutritionTable(
                    title: "Contact Stats",
                    rows: nutritionRows,
                    footnote: nil
                )

                // 5. MANUFACTURER — birthday becomes the Best Before highlight
                PackagingManufacturerBlock(
                    maker: contact.organizationName?.nonEmpty ?? contact.displayName,
                    bestBefore: birthdayStamp,
                    storage: nil
                )

                // 6. CODE FOOTER
                PackagingCodeFooter(
                    identifier: "VCARD-\(contactShortID)",
                    url: "vecka://contact"
                )
            }
            .padding(JohoDimensions.spacingSM)
            .background(accentColor.opacity(JohoDimensions.opacityLight))

            ShareableCardDivider()
        }
    }

    // MARK: - Avatar + QR Compartment

    private var avatarAndQRSection: some View {
        HStack(spacing: JohoDimensions.spacingMD) {
            // Avatar
            if let imageData = contact.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
            } else {
                ZStack {
                    Circle()
                        .fill(contact.group.swiftUIAvatarColor)
                        .frame(width: 72, height: 72)
                    Text(contact.initials.isEmpty ? "?" : contact.initials)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(JohoColors.white)
                }
                .overlay(Circle().stroke(colors.border, lineWidth: 1.5))
            }

            // SCAN TO SAVE instructions
            VStack(alignment: .leading, spacing: 4) {
                Text("SCAN TO SAVE")
                    .font(JohoFont.pillLabel)
                    .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityHeavy))
                    .tracking(0.5)
                Text("Point your camera at the QR code to add this contact.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(colors.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // QR Code (real, scannable vCard)
            if let qrImage = QRCodeGenerator.generate(from: contact.toVCard(includePhoto: false), size: 200) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 72, height: 72)
                    .background(colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: JohoDimensions.radiusXS, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: JohoDimensions.radiusXS, style: .continuous)
                            .stroke(colors.border, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: JohoDimensions.radiusXS, style: .continuous)
                    .fill(colors.surface)
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: JohoDimensions.radiusXS, style: .continuous)
                            .stroke(colors.border, lineWidth: 1)
                    )
                    .overlay {
                        Image(systemName: IconCatalog.qrcode)
                            .font(.system(size: 28, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(JohoDimensions.opacityMedium))
                    }
            }
        }
        .padding(JohoDimensions.spacingMD)
        .background(colors.surface)
        .johoBordered(cornerRadius: JohoDimensions.radiusSmall, borderWidth: 1.5)
    }

    // MARK: - Packaging Data Builders

    private var contactEntries: [PackagingIngredientsBox.Entry] {
        var out: [PackagingIngredientsBox.Entry] = []
        for phone in contact.phoneNumbers.prefix(3) {
            out.append(.init(label: "TEL", value: phone.value))
        }
        for email in contact.emailAddresses.prefix(2) {
            out.append(.init(label: "MAIL", value: email.value))
        }
        return out
    }

    private var nutritionRows: [PackagingNutritionTable.Row] {
        var rows: [PackagingNutritionTable.Row] = []
        if !contact.phoneNumbers.isEmpty { rows.append(.init(label: "Phones", value: "\(contact.phoneNumbers.count)")) }
        if !contact.emailAddresses.isEmpty { rows.append(.init(label: "Emails", value: "\(contact.emailAddresses.count)")) }
        if !contact.postalAddresses.isEmpty { rows.append(.init(label: "Addresses", value: "\(contact.postalAddresses.count)")) }
        rows.append(.init(label: "Group", value: contact.group.localizedName))
        return rows
    }

    private var birthdayStamp: String? {
        guard let birthday = contact.birthday, contact.birthdayKnown else { return nil }
        return birthday.formatted(.dateTime.year().month(.abbreviated).day())
    }

    private var contactShortID: String {
        String(contact.id.uuidString.prefix(8))
    }
}

// MARK: - String helper

private extension String {
    /// Returns the string if non-empty, otherwise nil.
    var nonEmpty: String? { isEmpty ? nil : self }
}

// MARK: - Share Button for Contact

/// A share button that creates a shareable contact snapshot
@available(iOS 16.0, *)
struct ContactShareButton: View {
    let contact: Contact

    private var snapshot: ShareableContactSnapshot {
        let size = ShareableContactSnapshot.calculateSize(for: contact)
        return ShareableContactSnapshot(contact: contact, size: size)
    }

    var body: some View {
        ShareLink(
            item: snapshot,
            preview: SharePreview(
                contact.displayName,
                image: Image(systemName: contact.group.icon)
            )
        ) {
            Label("Share Contact", systemImage: "square.and.arrow.up")
        }
    }
}

/// Compact share button for toolbars (28x28 circle matching FactShareButton pattern)
@available(iOS 16.0, *)
struct ContactShareIconButton: View {
    let contact: Contact

    private var snapshot: ShareableContactSnapshot {
        let size = ShareableContactSnapshot.calculateSize(for: contact)
        return ShareableContactSnapshot(contact: contact, size: size)
    }

    var body: some View {
        ShareLink(
            item: snapshot,
            preview: SharePreview(
                contact.displayName,
                image: Image(systemName: contact.group.icon)
            )
        ) {
            JohoShareCircleButton()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Shareable Contact Card") {
    let previewContact = Contact(
        givenName: "John",
        familyName: "Smith",
        organizationName: "Acme Corporation",
        phoneNumbers: [
            ContactPhoneNumber(label: "mobile", value: "+1-555-0123"),
            ContactPhoneNumber(label: "work", value: "+1-555-0456")
        ],
        emailAddresses: [
            ContactEmailAddress(label: "work", value: "john.smith@acme.com")
        ],
        birthday: Calendar.current.date(from: DateComponents(month: 3, day: 15)),
        birthdayKnown: true,
        group: .work
    )

    VStack(spacing: 20) {
        ShareableContactCard(contact: previewContact)
            .frame(width: 340, height: ShareableContactSnapshot.calculateSize(for: previewContact).height)
    }
    .padding()
    .background(Color.gray.opacity(JohoDimensions.opacityMild))
}

#Preview("Minimal Contact") {
    let minimalContact = Contact(
        givenName: "Jane",
        familyName: "Doe",
        group: .friends
    )

    ShareableContactCard(contact: minimalContact)
        .frame(width: 340, height: ShareableContactSnapshot.calculateSize(for: minimalContact).height)
        .padding()
        .background(Color.gray.opacity(JohoDimensions.opacityMild))
}
