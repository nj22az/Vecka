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
        ShareableContactCard(contact: contact)
            .frame(width: size.width, height: size.height)
    }

    /// Calculate dynamic size based on contact content
    static func calculateSize(for contact: Contact) -> CGSize {
        let width: CGFloat = 340
        var height: CGFloat = 0

        // Header: 40pt + divider 2pt
        height += 42

        // Name section (always): 60pt
        height += 60

        // Contact info rows (28pt each)
        height += CGFloat(contact.phoneNumbers.count) * 28
        height += CGFloat(contact.emailAddresses.count) * 28

        // Organization if present: 28pt
        if let org = contact.organizationName, !org.isEmpty {
            height += 28
        }

        // Birthday if present: 28pt
        if contact.birthday != nil && contact.birthdayKnown {
            height += 28
        }

        // Divider before QR: 2pt
        height += 2

        // QR code section: 120pt
        height += 120

        // Divider before footer: 2pt
        height += 2

        // Footer: 32pt
        height += 32

        // Minimum height for cards with little info
        return CGSize(width: width, height: max(height, 300))
    }
}

// MARK: - Shareable Contact Card View (情報デザイン styled)

/// A beautiful contact card designed for sharing
/// Uses 情報デザイン bento styling with embedded QR code
struct ShareableContactCard: View {
    let contact: Contact

    @Environment(\.johoColorMode) private var colorMode

    private var colors: JohoScheme { JohoScheme.colors(for: colorMode) }

    private let cornerRadius: CGFloat = 16

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    /// Contact group color for accents
    private var accentColor: Color {
        Color(hex: contact.group.color)
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
                // HEADER: App branding + contact icon
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: 0) {
                    // LEFT: App branding
                    HStack(spacing: JohoDimensions.spacingSM) {
                        Image(systemName: "person.crop.rectangle.stack.fill")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(colors.primary)

                        Text("CONTACTS")
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

                    // RIGHT: Group icon
                    Image(systemName: contact.group.icon)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .frame(width: 48)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 40)
                .background(accentColor.opacity(0.5))

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // ═══════════════════════════════════════════════════════════════
                // MAIN CONTENT: Contact info
                // ═══════════════════════════════════════════════════════════════
                VStack(alignment: .leading, spacing: JohoDimensions.spacingSM) {
                    // Name (always prominent)
                    Text(contact.displayName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary)
                        .lineLimit(2)

                    // Organization
                    if let org = contact.organizationName, !org.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(JohoColors.cyan)
                            Text(org)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)
                                .lineLimit(1)
                        }
                    }

                    // Phone numbers
                    ForEach(contact.phoneNumbers.prefix(2), id: \.id) { phone in
                        HStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(JohoColors.green)
                            Text(phone.value)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)
                                .lineLimit(1)
                        }
                    }

                    // Email addresses
                    ForEach(contact.emailAddresses.prefix(2), id: \.id) { email in
                        HStack(spacing: 6) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(JohoColors.yellow)
                            Text(email.value)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)
                                .lineLimit(1)
                        }
                    }

                    // Birthday
                    if let birthday = contact.birthday, contact.birthdayKnown {
                        HStack(spacing: 6) {
                            Image(systemName: "birthday.cake.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(JohoColors.pink)
                            Text(birthday.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(colors.primary)
                        }
                    }
                }
                .padding(JohoDimensions.spacingMD)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accentColor.opacity(0.1))

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // ═══════════════════════════════════════════════════════════════
                // QR CODE SECTION: Scannable vCard
                // ═══════════════════════════════════════════════════════════════
                HStack(spacing: JohoDimensions.spacingMD) {
                    // QR Code (generated from vCard without photo)
                    if let qrImage = QRCodeGenerator.generate(from: contact.toVCard(includePhoto: false), size: 200) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 90, height: 90)
                            .background(colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(colors.border, lineWidth: 1)
                            )
                    } else {
                        // Fallback if QR generation fails
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(colors.surface)
                            .frame(width: 90, height: 90)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(colors.border, lineWidth: 1)
                            )
                            .overlay {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 32))
                                    .foregroundStyle(colors.primary.opacity(0.3))
                            }
                    }

                    // Instructions
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SCAN TO SAVE")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(colors.primary.opacity(0.5))
                            .tracking(0.5)

                        Text("Point your camera at this QR code to add contact")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(colors.primary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
                .padding(JohoDimensions.spacingMD)
                .frame(height: 120)
                .background(colors.surface)

                // Divider
                Rectangle()
                    .fill(colors.border)
                    .frame(height: 2)

                // ═══════════════════════════════════════════════════════════════
                // FOOTER: Contact card branding with group
                // ═══════════════════════════════════════════════════════════════
                HStack {
                    Text("CONTACT CARD")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(colors.primary.opacity(0.5))
                        .tracking(1)

                    Spacer()

                    // Group badge
                    Text(contact.group.localizedName.uppercased())
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

/// Compact share button for toolbars
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
            Image(systemName: "square.and.arrow.up")
        }
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
    .background(Color.gray.opacity(0.2))
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
        .background(Color.gray.opacity(0.2))
}
