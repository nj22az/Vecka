//
//  ContactExportService.swift
//  Vecka
//
//  TRUE 情報デザイン: Every element answers a question.
//  If it does not answer a question, it is noise. Decoration is failure.
//

import Foundation
import SwiftUI
import SwiftData
import UIKit

/// TRUE 情報デザイン Contact Export
///
/// Mental Model: Think train timetable, pharmacy instruction sheet, municipal notice.
/// The user is hunting for a contact. Every mark on the page exists to accelerate that hunt.
///
/// Design Law: Every visual element must answer a question.
/// If it does not answer a question, it is noise.
@MainActor
class ContactExportService {

    // MARK: - Singleton
    static let shared = ContactExportService()
    private init() {}

    // MARK: - TRUE 情報デザイン Constants

    /// Page Architecture (A4)
    private enum Page {
        static let width: CGFloat = 595.2
        static let height: CGFloat = 841.8
        static let marginTop: CGFloat = 52      // 18mm top
        static let marginSide: CGFloat = 48     // 17mm sides
        static let marginBottom: CGFloat = 48
    }

    /// Border Hierarchy: Thick → Medium → Thin
    private enum Border {
        static let outer: CGFloat = 2.0         // Document frame
        static let section: CGFloat = 1.5       // Section dividers
        static let row: CGFloat = 0.5           // Row separators
    }

    /// Typography: Functional, readable
    private enum Font {
        static let title = UIFont.systemFont(ofSize: 20, weight: .bold)
        static let meta = UIFont.systemFont(ofSize: 11, weight: .semibold)
        static let sectionLabel = UIFont.systemFont(ofSize: 14, weight: .bold)
        static let sectionCount = UIFont.systemFont(ofSize: 11, weight: .medium)
        static let name = UIFont.systemFont(ofSize: 12, weight: .semibold)
        static let detail = UIFont.systemFont(ofSize: 11, weight: .regular)
        static let mono = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        static let legend = UIFont.systemFont(ofSize: 10, weight: .medium)
        static let footer = UIFont.systemFont(ofSize: 9, weight: .medium)
    }

    /// Colors: Black, White, ONE accent max
    private enum Ink {
        static let black = UIColor.black
        static let white = UIColor.white
        static let gray = UIColor(white: 0.45, alpha: 1.0)  // Readable gray
        static let grayLight = UIColor(white: 0.7, alpha: 1.0)
        static let accent = UIColor(red: 0.99, green: 0.80, blue: 0.83, alpha: 1.0) // Pink for birthdays only
    }

    /// Vertical Rhythm: 8pt baseline grid
    private enum Grid {
        static let unit: CGFloat = 8
        static let half: CGFloat = 4
        static let double: CGFloat = 16
        static let triple: CGFloat = 24
    }

    // MARK: - Public API

    func exportContacts(
        _ contacts: [Contact],
        options: ContactExportOptions,
        pdfTitle: String = "Contact Directory",
        pdfFooter: String = "",
        modelContext: ModelContext
    ) async throws -> URL {

        guard !contacts.isEmpty else {
            throw ContactExportError.noData
        }

        let pdfData = try renderPDF(contacts, options: options, title: pdfTitle, footer: pdfFooter)

        // Save to temporary file
        let dateStr = Date().formatted(.iso8601.year().month().day())
        let filename = "Contacts_\(dateStr).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try pdfData.write(to: tempURL)

        return tempURL
    }

    // MARK: - PDF Rendering

    private func renderPDF(_ contacts: [Contact], options: ContactExportOptions, title: String, footer: String) throws -> Data {
        let pageSize = CGSize(width: Page.width, height: Page.height)
        let contentWidth = Page.width - (Page.marginSide * 2)
        let contentHeight = Page.height - Page.marginTop - Page.marginBottom

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: title.isEmpty ? "Contact Directory" : title,
            kCGPDFContextAuthor as String: "Onsen Planner",
            kCGPDFContextCreator as String: "Onsen Planner iOS",
            kCGPDFContextSubject as String: "\(contacts.count) contacts"
        ]

        // Group contacts
        let groups: [(key: String, contacts: [Contact])]
        if options.sortByBirthday {
            groups = groupByMonth(contacts)
        } else {
            groups = groupByLetter(contacts)
        }

        // Pre-calculate total pages
        let totalPages = calculateTotalPages(groups, options: options, contentHeight: contentHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)

        let data = renderer.pdfData { ctx in
            var y: CGFloat = Page.marginTop
            var pageNum = 1
            var currentSection = ""

            // === FIRST PAGE ===
            ctx.beginPage()

            // Boxed Header (thick outer border)
            y = drawBoxedHeader(
                title: title.isEmpty ? "Contact Directory" : title,
                count: contacts.count,
                options: options,
                at: y,
                width: contentWidth,
                in: ctx.cgContext
            )

            // Legend/Key (mandatory: explain what symbols mean)
            y = drawLegend(options: options, at: y, width: contentWidth, in: ctx.cgContext)

            // === CONTENT ===
            for group in groups {
                currentSection = group.key

                // Check space for section header + at least one row
                let minSpace = Grid.triple + rowHeight(options: options)
                if y > Page.height - Page.marginBottom - minSpace {
                    drawPageFooter(title: title, page: pageNum, total: totalPages, customFooter: footer, in: ctx.cgContext)
                    ctx.beginPage()
                    pageNum += 1
                    y = Page.marginTop
                    y = drawRunningHeader(title: title, section: currentSection, at: y, width: contentWidth, in: ctx.cgContext)
                }

                // Section Header (heavy top border, black pill)
                y = drawSectionHeader(key: group.key, count: group.contacts.count, at: y, width: contentWidth, in: ctx.cgContext)

                // Contact Rows (timetable style)
                for (index, contact) in group.contacts.enumerated() {
                    let rh = rowHeight(options: options)

                    if y > Page.height - Page.marginBottom - rh {
                        drawPageFooter(title: title, page: pageNum, total: totalPages, customFooter: footer, in: ctx.cgContext)
                        ctx.beginPage()
                        pageNum += 1
                        y = Page.marginTop
                        y = drawRunningHeader(title: title, section: "\(currentSection) cont.", at: y, width: contentWidth, in: ctx.cgContext)
                    }

                    y = drawContactRow(contact, options: options, isLast: index == group.contacts.count - 1, at: y, width: contentWidth, in: ctx.cgContext)
                }

                y += Grid.double  // Section gap
            }

            // Final page footer
            drawPageFooter(title: title, page: pageNum, total: totalPages, customFooter: footer, in: ctx.cgContext)
        }

        return data
    }

    // MARK: - Page Calculation

    private func calculateTotalPages(_ groups: [(key: String, contacts: [Contact])], options: ContactExportOptions, contentHeight: CGFloat) -> Int {
        // Header + legend take ~120pt
        let headerSpace: CGFloat = 120
        var usedHeight = headerSpace

        for group in groups {
            usedHeight += Grid.triple  // Section header
            usedHeight += CGFloat(group.contacts.count) * rowHeight(options: options)
            usedHeight += Grid.double  // Section gap
        }

        let usablePerPage = contentHeight - 40  // Footer space
        return max(1, Int(ceil(usedHeight / usablePerPage)))
    }

    private func rowHeight(options: ContactExportOptions) -> CGFloat {
        // Base: name line
        var h: CGFloat = 18
        // Detail lines
        var lines = 0
        if options.includePhone { lines += 1 }
        if options.includeEmail { lines += 1 }
        if options.includeBirthday { lines += 1 }
        h += CGFloat(lines) * 14
        return max(h, 24)  // Minimum touch-friendly height
    }

    // MARK: - Grouping

    private func groupByLetter(_ contacts: [Contact]) -> [(key: String, contacts: [Contact])] {
        var dict: [String: [Contact]] = [:]
        for c in contacts {
            let name = c.familyName.isEmpty ? c.givenName : c.familyName
            let letter = name.isEmpty ? "#" : String(name.prefix(1)).uppercased()
            dict[letter, default: []].append(c)
        }
        return dict.keys.sorted().map { k in
            (key: k, contacts: dict[k]!.sorted {
                ($0.familyName.isEmpty ? $0.givenName : $0.familyName)
                    .localizedCaseInsensitiveCompare($1.familyName.isEmpty ? $1.givenName : $1.familyName) == .orderedAscending
            })
        }
    }

    private func groupByMonth(_ contacts: [Contact]) -> [(key: String, contacts: [Contact])] {
        var dict: [Int: [Contact]] = [:]
        var noDate: [Contact] = []
        for c in contacts {
            if let b = c.birthday {
                let m = Calendar.current.component(.month, from: b)
                dict[m, default: []].append(c)
            } else {
                noDate.append(c)
            }
        }
        var result: [(key: String, contacts: [Contact])] = []
        let months = DateFormatter().monthSymbols ?? []
        for m in 1...12 {
            if let arr = dict[m], !arr.isEmpty {
                let sorted = arr.sorted { c1, c2 in
                    guard let b1 = c1.birthday, let b2 = c2.birthday else { return false }
                    return Calendar.current.component(.day, from: b1) < Calendar.current.component(.day, from: b2)
                }
                result.append((key: months[m-1].uppercased(), contacts: sorted))
            }
        }
        if !noDate.isEmpty {
            result.append((key: "NO DATE", contacts: noDate))
        }
        return result
    }

    // MARK: - Drawing: Boxed Header

    /// TRUE 情報デザイン: Boxed header with thick outer border
    /// Contains: Title, count, metadata, export timestamp
    private func drawBoxedHeader(title: String, count: Int, options: ContactExportOptions, at y: CGFloat, width: CGFloat, in ctx: CGContext) -> CGFloat {
        let x = Page.marginSide
        let boxHeight: CGFloat = 56

        // Thick outer border (2pt)
        ctx.setStrokeColor(Ink.black.cgColor)
        ctx.setLineWidth(Border.outer)
        ctx.stroke(CGRect(x: x, y: y, width: width, height: boxHeight))

        // Title (left)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.title,
            .foregroundColor: Ink.black
        ]
        (title as NSString).draw(at: CGPoint(x: x + Grid.unit, y: y + Grid.unit), withAttributes: titleAttrs)

        // Count pill (right of title)
        let countText = "\(count)"
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.meta,
            .foregroundColor: Ink.white
        ]
        let titleSize = (title as NSString).size(withAttributes: titleAttrs)
        let countSize = (countText as NSString).size(withAttributes: countAttrs)
        let pillRect = CGRect(x: x + Grid.unit + titleSize.width + Grid.unit, y: y + Grid.unit + 4, width: countSize.width + 12, height: 18)

        ctx.setFillColor(Ink.black.cgColor)
        let pillPath = UIBezierPath(roundedRect: pillRect, cornerRadius: 9)
        ctx.addPath(pillPath.cgPath)
        ctx.fillPath()
        (countText as NSString).draw(at: CGPoint(x: pillRect.minX + 6, y: pillRect.minY + 2), withAttributes: countAttrs)

        // Metadata row (bottom of box)
        var meta: [String] = []
        if options.includePhone { meta.append("TEL") }
        if options.includeEmail { meta.append("EMAIL") }
        if options.includeBirthday { meta.append("BDAY") }
        if options.includeGroup { meta.append("GROUP") }
        if meta.isEmpty { meta.append("NAMES ONLY") }
        meta.append(options.sortByBirthday ? "SORT: BIRTHDAY" : "SORT: A–Z")

        let metaAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.legend,
            .foregroundColor: Ink.gray
        ]
        let metaText = meta.joined(separator: " · ")
        (metaText as NSString).draw(at: CGPoint(x: x + Grid.unit, y: y + boxHeight - 16), withAttributes: metaAttrs)

        // Timestamp (right side of bottom)
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
        let tsSize = (timestamp as NSString).size(withAttributes: metaAttrs)
        (timestamp as NSString).draw(at: CGPoint(x: x + width - Grid.unit - tsSize.width, y: y + boxHeight - 16), withAttributes: metaAttrs)

        return y + boxHeight + Grid.unit
    }

    // MARK: - Drawing: Legend/Key

    /// TRUE 情報デザイン: Mandatory legend explaining symbols
    private func drawLegend(options: ContactExportOptions, at y: CGFloat, width: CGFloat, in ctx: CGContext) -> CGFloat {
        let x = Page.marginSide
        var items: [(icon: String, label: String)] = []

        if options.includePhone { items.append(("☎", "Phone")) }
        if options.includeEmail { items.append(("✉", "Email")) }
        if options.includeBirthday { items.append(("★", "Birthday")) }
        if options.includeGroup { items.append(("▣", "Group")) }

        guard !items.isEmpty else { return y }

        let legendAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.legend,
            .foregroundColor: Ink.gray
        ]

        var offsetX: CGFloat = 0
        let prefix = "KEY: "
        (prefix as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: legendAttrs)
        offsetX += (prefix as NSString).size(withAttributes: legendAttrs).width

        for (i, item) in items.enumerated() {
            let text = "\(item.icon) \(item.label)" + (i < items.count - 1 ? "   " : "")
            (text as NSString).draw(at: CGPoint(x: x + offsetX, y: y), withAttributes: legendAttrs)
            offsetX += (text as NSString).size(withAttributes: legendAttrs).width
        }

        // Thin separator line
        let lineY = y + 14
        ctx.setStrokeColor(Ink.grayLight.cgColor)
        ctx.setLineWidth(Border.row)
        ctx.move(to: CGPoint(x: x, y: lineY))
        ctx.addLine(to: CGPoint(x: x + width, y: lineY))
        ctx.strokePath()

        return lineY + Grid.unit
    }

    // MARK: - Drawing: Running Header (continuation pages)

    private func drawRunningHeader(title: String, section: String, at y: CGFloat, width: CGFloat, in ctx: CGContext) -> CGFloat {
        let x = Page.marginSide

        let leftAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.legend,
            .foregroundColor: Ink.gray
        ]
        (title as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: leftAttrs)

        let rightAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.sectionLabel,
            .foregroundColor: Ink.black
        ]
        let sectionSize = (section as NSString).size(withAttributes: rightAttrs)
        (section as NSString).draw(at: CGPoint(x: x + width - sectionSize.width, y: y), withAttributes: rightAttrs)

        // Medium separator
        let lineY = y + 16
        ctx.setStrokeColor(Ink.black.cgColor)
        ctx.setLineWidth(Border.section)
        ctx.move(to: CGPoint(x: x, y: lineY))
        ctx.addLine(to: CGPoint(x: x + width, y: lineY))
        ctx.strokePath()

        return lineY + Grid.unit
    }

    // MARK: - Drawing: Section Header

    /// TRUE 情報デザイン: Heavy top border, black pill label, count
    private func drawSectionHeader(key: String, count: Int, at y: CGFloat, width: CGFloat, in ctx: CGContext) -> CGFloat {
        let x = Page.marginSide

        // Heavy top border (section divider)
        ctx.setStrokeColor(Ink.black.cgColor)
        ctx.setLineWidth(Border.section)
        ctx.move(to: CGPoint(x: x, y: y))
        ctx.addLine(to: CGPoint(x: x + width, y: y))
        ctx.strokePath()

        let labelY = y + Grid.half

        // Black pill with letter
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.sectionLabel,
            .foregroundColor: Ink.white
        ]
        let labelSize = (key as NSString).size(withAttributes: labelAttrs)
        let pillWidth = max(labelSize.width + 12, 28)
        let pillRect = CGRect(x: x, y: labelY, width: pillWidth, height: 20)

        ctx.setFillColor(Ink.black.cgColor)
        let pillPath = UIBezierPath(roundedRect: pillRect, cornerRadius: 4)
        ctx.addPath(pillPath.cgPath)
        ctx.fillPath()

        (key as NSString).draw(at: CGPoint(x: pillRect.minX + (pillWidth - labelSize.width) / 2, y: labelY + 3), withAttributes: labelAttrs)

        // Count (functional: how many in this section)
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.sectionCount,
            .foregroundColor: Ink.gray
        ]
        let countText = "(\(count))"
        (countText as NSString).draw(at: CGPoint(x: x + pillWidth + Grid.unit, y: labelY + 4), withAttributes: countAttrs)

        return y + Grid.triple
    }

    // MARK: - Drawing: Contact Row

    /// TRUE 情報デザイン: Timetable style - name + data columns, icons only (no labels)
    private func drawContactRow(_ contact: Contact, options: ContactExportOptions, isLast: Bool, at y: CGFloat, width: CGFloat, in ctx: CGContext) -> CGFloat {
        let x = Page.marginSide
        var currentY = y

        // NAME (semibold, 12pt)
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.name,
            .foregroundColor: Ink.black
        ]
        (contact.displayName as NSString).draw(at: CGPoint(x: x, y: currentY), withAttributes: nameAttrs)

        // Group badge (right side, if enabled)
        if options.includeGroup {
            let groupAttrs: [NSAttributedString.Key: Any] = [
                .font: Font.detail,
                .foregroundColor: Ink.gray
            ]
            let groupText = contact.group.localizedName
            let gSize = (groupText as NSString).size(withAttributes: groupAttrs)
            (groupText as NSString).draw(at: CGPoint(x: x + width - gSize.width, y: currentY), withAttributes: groupAttrs)
        }

        currentY += 16

        // DETAIL LINES: icon + value (no text labels per TRUE 情報デザイン)
        let detailAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.detail,
            .foregroundColor: Ink.gray
        ]
        let monoAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.mono,
            .foregroundColor: Ink.gray
        ]
        let iconAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.detail,
            .foregroundColor: Ink.black
        ]

        // Phone: ☎ 555-1234
        if options.includePhone && !contact.phoneNumbers.isEmpty {
            let phones = contact.phoneNumbers.prefix(2).map { $0.value }.joined(separator: " · ")
            let more = contact.phoneNumbers.count > 2 ? " +\(contact.phoneNumbers.count - 2)" : ""
            ("☎" as NSString).draw(at: CGPoint(x: x, y: currentY), withAttributes: iconAttrs)
            (phones as NSString).draw(at: CGPoint(x: x + 14, y: currentY), withAttributes: monoAttrs)
            if !more.isEmpty {
                let pSize = (phones as NSString).size(withAttributes: monoAttrs)
                (more as NSString).draw(at: CGPoint(x: x + 14 + pSize.width, y: currentY), withAttributes: detailAttrs)
            }
            currentY += 14
        }

        // Email: ✉ john@example.com
        if options.includeEmail && !contact.emailAddresses.isEmpty {
            let emails = contact.emailAddresses.prefix(2).map { $0.value }.joined(separator: " · ")
            let more = contact.emailAddresses.count > 2 ? " +\(contact.emailAddresses.count - 2)" : ""
            ("✉" as NSString).draw(at: CGPoint(x: x, y: currentY), withAttributes: iconAttrs)
            (emails as NSString).draw(at: CGPoint(x: x + 14, y: currentY), withAttributes: detailAttrs)
            if !more.isEmpty {
                let eSize = (emails as NSString).size(withAttributes: detailAttrs)
                (more as NSString).draw(at: CGPoint(x: x + 14 + eSize.width, y: currentY), withAttributes: detailAttrs)
            }
            currentY += 14
        }

        // Birthday: ★ 15 Mar (pink background = semantic accent)
        if options.includeBirthday, let birthday = contact.birthday {
            let fmt = DateFormatter()
            fmt.dateFormat = "d MMM"
            let dateStr = fmt.string(from: birthday)

            let bdayAttrs: [NSAttributedString.Key: Any] = [
                .font: Font.detail,
                .foregroundColor: Ink.black
            ]
            let iconW: CGFloat = 14
            let textSize = (dateStr as NSString).size(withAttributes: bdayAttrs)
            let bgRect = CGRect(x: x + iconW - 2, y: currentY - 1, width: textSize.width + 6, height: 14)

            // Pink background (semantic: ONE accent color for birthdays)
            ctx.setFillColor(Ink.accent.cgColor)
            let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 3)
            ctx.addPath(bgPath.cgPath)
            ctx.fillPath()

            ("★" as NSString).draw(at: CGPoint(x: x, y: currentY), withAttributes: iconAttrs)
            (dateStr as NSString).draw(at: CGPoint(x: x + iconW + 1, y: currentY), withAttributes: bdayAttrs)
            currentY += 14
        }

        // Row separator (thin, 0.5pt) - skip for last item in section
        if !isLast {
            let lineY = currentY + Grid.half
            ctx.setStrokeColor(Ink.grayLight.cgColor)
            ctx.setLineWidth(Border.row)
            ctx.move(to: CGPoint(x: x, y: lineY))
            ctx.addLine(to: CGPoint(x: x + width, y: lineY))
            ctx.strokePath()
            currentY = lineY + Grid.half
        } else {
            currentY += Grid.half
        }

        return currentY
    }

    // MARK: - Drawing: Page Footer

    /// TRUE 情報デザイン: Report name + Page X / Y + timestamp on every page
    private func drawPageFooter(title: String, page: Int, total: Int, customFooter: String, in ctx: CGContext) {
        let x = Page.marginSide
        let y = Page.height - Page.marginBottom + Grid.unit
        let width = Page.width - (Page.marginSide * 2)

        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: Font.footer,
            .foregroundColor: Ink.gray
        ]

        // Left: Report name or custom footer
        let leftText = customFooter.isEmpty ? title : customFooter
        (leftText as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: footerAttrs)

        // Center: Page X / Y
        let pageText = "Page \(page) / \(total)"
        let pageSize = (pageText as NSString).size(withAttributes: footerAttrs)
        (pageText as NSString).draw(at: CGPoint(x: x + (width - pageSize.width) / 2, y: y), withAttributes: footerAttrs)

        // Right: Timestamp
        let ts = Date().formatted(date: .numeric, time: .shortened)
        let tsSize = (ts as NSString).size(withAttributes: footerAttrs)
        (ts as NSString).draw(at: CGPoint(x: x + width - tsSize.width, y: y), withAttributes: footerAttrs)
    }
}

// MARK: - Errors

enum ContactExportError: LocalizedError {
    case noData
    case renderingFailed

    var errorDescription: String? {
        switch self {
        case .noData: return "No contacts to export"
        case .renderingFailed: return "PDF generation failed"
        }
    }
}
