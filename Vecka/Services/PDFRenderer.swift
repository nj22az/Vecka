//
//  PDFRenderer.swift
//  Vecka
//
//  PDF rendering engine using UIKit's PDF generation
//

import Foundation
import UIKit
import SwiftUI
import SwiftData

/// PDF Renderer - Handles actual PDF page generation
class PDFRenderer {

    // MARK: - Properties
    private let options: PDFExportOptions
    private let modelContext: ModelContext

    // MARK: - Page Dimensions
    private var pageSize: CGSize {
        options.pageSize.size
    }

    private let margin: CGFloat = 56.7 // 20mm margins

    private var contentRect: CGRect {
        CGRect(
            x: margin,
            y: margin,
            width: pageSize.width - (margin * 2),
            height: pageSize.height - (margin * 2)
        )
    }

    // MARK: - Typography
    private struct Fonts {
        static let title = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let heading = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let subheading = UIFont.systemFont(ofSize: 16, weight: .semibold)
        static let body = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let bodyBold = UIFont.systemFont(ofSize: 13, weight: .semibold)
        static let caption = UIFont.systemFont(ofSize: 11, weight: .regular)
        static let small = UIFont.systemFont(ofSize: 10, weight: .regular)
    }

    // MARK: - Colors
    private struct Colors {
        static let text = UIColor.black
        static let textSecondary = UIColor.darkGray
        static let textTertiary = UIColor.gray
        static let accent = UIColor.systemBlue
        static let redDay = UIColor.systemRed
        static let divider = UIColor.lightGray
        static let cardBackground = UIColor(white: 0.97, alpha: 1.0)
    }

    // MARK: - Initialization
    init(options: PDFExportOptions = PDFExportOptions(), modelContext: ModelContext) {
        self.options = options
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// Render days into PDF data
    func render(days: [DayExportData], scope: PDFExportScope) async throws -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Vecka Export - \(scope.title)",
            kCGPDFContextAuthor as String: "Vecka",
            kCGPDFContextCreator as String: "Vecka iOS App"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)

        let data = renderer.pdfData { context in
            for (index, day) in days.enumerated() {
                context.beginPage()
                renderDayPage(day: day, pageNumber: index + 1, totalPages: days.count, in: context.cgContext)
            }
        }

        return data
    }

    /// Render trip report into PDF data
    func renderTripReport(reportData: TripReportExportInfo) async throws -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Vecka Travel Report - \(reportData.tripName)",
            kCGPDFContextAuthor as String: "Vecka",
            kCGPDFContextCreator as String: "Vecka iOS App"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)

        let data = renderer.pdfData { context in
            context.beginPage()
            renderTripReportPage(reportData: reportData, in: context.cgContext)
        }

        return data
    }

    // MARK: - Page Rendering

    private func renderDayPage(
        day: DayExportData,
        pageNumber: Int,
        totalPages: Int,
        in context: CGContext
    ) {
        var yPosition = contentRect.minY

        // Header
        yPosition = drawHeader(day: day, at: yPosition, in: context)
        yPosition += 24

        // Date Information
        yPosition = drawDateInfo(day: day, at: yPosition, in: context)
        yPosition += 32

        // Holidays
        if !day.holidays.isEmpty {
            yPosition = drawHolidays(day.holidays, at: yPosition, in: context)
            yPosition += 20
        }

        // Notes
        if !day.notes.isEmpty && options.includeNotes {
            yPosition = drawNotes(day.notes, at: yPosition, in: context)
            yPosition += 20
        }

        // Weather
        if let weather = day.weather, options.includeWeather {
            yPosition = drawWeather(weather, at: yPosition, in: context)
            yPosition += 20
        }

        // Statistics
        if options.includeStatistics {
            yPosition = drawStatistics(day: day, at: yPosition, in: context)
        }

        // Footer
        drawFooter(pageNumber: pageNumber, totalPages: totalPages, in: context)
    }

    // MARK: - Drawing Methods

    private func drawHeader(day: DayExportData, at y: CGFloat, in context: CGContext) -> CGFloat {
        let title = "Vecka"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.title,
            .foregroundColor: Colors.text
        ]

        let titleSize = (title as NSString).size(withAttributes: attributes)
        let titlePoint = CGPoint(x: contentRect.minX, y: y)

        (title as NSString).draw(at: titlePoint, withAttributes: attributes)

        // Draw logo or accent line
        let lineY = y + titleSize.height + 8
        context.setStrokeColor(Colors.accent.cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: contentRect.minX, y: lineY))
        context.addLine(to: CGPoint(x: contentRect.maxX, y: lineY))
        context.strokePath()

        return lineY + 4
    }

    private func drawDateInfo(day: DayExportData, at y: CGFloat, in context: CGContext) -> CGFloat {
        var currentY = y

        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        let dateText = dateFormatter.string(from: day.date)

        // Weekday
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        let weekday = weekdayFormatter.string(from: day.date)

        // Draw weekday
        let weekdayAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.heading,
            .foregroundColor: Colors.text
        ]
        let weekdaySize = (weekday as NSString).size(withAttributes: weekdayAttrs)
        (weekday as NSString).draw(at: CGPoint(x: contentRect.minX, y: currentY), withAttributes: weekdayAttrs)
        currentY += weekdaySize.height + 8

        // Draw date
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.textSecondary
        ]
        let dateSize = (dateText as NSString).size(withAttributes: dateAttrs)
        (dateText as NSString).draw(at: CGPoint(x: contentRect.minX, y: currentY), withAttributes: dateAttrs)
        currentY += dateSize.height + 6

        // Draw week number
        let weekText = "Week \(day.weekNumber), \(day.year)"
        let weekAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.caption,
            .foregroundColor: Colors.textTertiary
        ]
        let weekSize = (weekText as NSString).size(withAttributes: weekAttrs)
        (weekText as NSString).draw(at: CGPoint(x: contentRect.minX, y: currentY), withAttributes: weekAttrs)
        currentY += weekSize.height

        return currentY
    }

    private func drawHolidays(_ holidays: [HolidayExportInfo], at y: CGFloat, in context: CGContext) -> CGFloat {
        var currentY = y

        // Section header
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.subheading,
            .foregroundColor: Colors.text
        ]
        let header = "Holidays"
        let headerSize = (header as NSString).size(withAttributes: headerAttrs)
        (header as NSString).draw(at: CGPoint(x: contentRect.minX, y: currentY), withAttributes: headerAttrs)
        currentY += headerSize.height + 12

        // Draw each holiday
        for holiday in holidays {
            let cardRect = CGRect(
                x: contentRect.minX,
                y: currentY,
                width: contentRect.width,
                height: 44
            )

            // Draw card background
            context.setFillColor(Colors.cardBackground.cgColor)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 8)
            context.addPath(cardPath.cgPath)
            context.fillPath()

            // Draw holiday name
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.body,
                .foregroundColor: holiday.isRedDay ? Colors.redDay : Colors.text
            ]

            let namePoint = CGPoint(x: cardRect.minX + 12, y: cardRect.minY + 14)
            (holiday.name as NSString).draw(at: namePoint, withAttributes: nameAttrs)

            // Draw red day indicator
            if holiday.isRedDay {
                let indicatorRect = CGRect(
                    x: cardRect.maxX - 24,
                    y: cardRect.minY + 12,
                    width: 8,
                    height: 20
                )
                context.setFillColor(Colors.redDay.cgColor)
                let indicatorPath = UIBezierPath(roundedRect: indicatorRect, cornerRadius: 2)
                context.addPath(indicatorPath.cgPath)
                context.fillPath()
            }

            currentY += 50
        }

        return currentY
    }

    private func drawNotes(_ notes: [NoteExportInfo], at y: CGFloat, in context: CGContext) -> CGFloat {
        var currentY = y

        // Section header
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.subheading,
            .foregroundColor: Colors.text
        ]
        let header = "Notes (\(notes.count))"
        let headerSize = (header as NSString).size(withAttributes: headerAttrs)
        (header as NSString).draw(at: CGPoint(x: contentRect.minX, y: currentY), withAttributes: headerAttrs)
        currentY += headerSize.height + 12

        // Draw each note
        for note in notes {
            // Calculate note height based on content
            let contentAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.body,
                .foregroundColor: Colors.text
            ]

            let maxWidth = contentRect.width - 24
            let boundingRect = (note.content as NSString).boundingRect(
                with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: contentAttrs,
                context: nil
            )

            let noteHeight = max(60, boundingRect.height + 40)

            let cardRect = CGRect(
                x: contentRect.minX,
                y: currentY,
                width: contentRect.width,
                height: noteHeight
            )

            // Draw card background
            context.setFillColor(Colors.cardBackground.cgColor)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 8)
            context.addPath(cardPath.cgPath)
            context.fillPath()

            // Draw note color indicator
            if let colorHex = note.colorHex, let color = UIColor(hexString: colorHex) {
                let colorRect = CGRect(
                    x: cardRect.minX,
                    y: cardRect.minY,
                    width: 4,
                    height: cardRect.height
                )
                context.setFillColor(color.cgColor)
                context.fill(colorRect)
            }

            // Draw time
            let timeAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.small,
                .foregroundColor: Colors.textTertiary
            ]
            (note.formattedTime as NSString).draw(
                at: CGPoint(x: cardRect.minX + 12, y: cardRect.minY + 10),
                withAttributes: timeAttrs
            )

            // Draw content
            let contentY = cardRect.minY + 28
            let contentRect = CGRect(
                x: cardRect.minX + 12,
                y: contentY,
                width: maxWidth,
                height: cardRect.height - 38
            )

            (note.content as NSString).draw(
                in: contentRect,
                withAttributes: contentAttrs
            )

            currentY += noteHeight + 8
        }

        return currentY
    }

    private func drawWeather(_ weather: WeatherExportInfo, at y: CGFloat, in context: CGContext) -> CGFloat {
        var currentY = y

        // Section header
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.subheading,
            .foregroundColor: Colors.text
        ]
        let header = "Weather"
        let headerSize = (header as NSString).size(withAttributes: headerAttrs)
        (header as NSString).draw(at: CGPoint(x: contentRect.minX, y: currentY), withAttributes: headerAttrs)
        currentY += headerSize.height + 12

        // Weather card
        let cardRect = CGRect(
            x: contentRect.minX,
            y: currentY,
            width: contentRect.width,
            height: 80
        )

        // Draw card background
        context.setFillColor(Colors.cardBackground.cgColor)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 8)
        context.addPath(cardPath.cgPath)
        context.fillPath()

        // Draw weather info
        let tempText = "\(weather.highTemperature) / \(weather.lowTemperature)"
        let tempAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.heading,
            .foregroundColor: Colors.text
        ]
        (tempText as NSString).draw(
            at: CGPoint(x: cardRect.minX + 12, y: cardRect.minY + 15),
            withAttributes: tempAttrs
        )

        let conditionAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.textSecondary
        ]
        (weather.condition as NSString).draw(
            at: CGPoint(x: cardRect.minX + 12, y: cardRect.minY + 45),
            withAttributes: conditionAttrs
        )

        currentY += 88

        return currentY
    }

    private func drawStatistics(day: DayExportData, at y: CGFloat, in context: CGContext) -> CGFloat {
        var currentY = y

        // Section header
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.subheading,
            .foregroundColor: Colors.text
        ]
        let header = "Statistics"
        let headerSize = (header as NSString).size(withAttributes: headerAttrs)
        (header as NSString).draw(at: CGPoint(x: contentRect.minX, y: currentY), withAttributes: headerAttrs)
        currentY += headerSize.height + 12

        // Stats grid
        let stats = [
            ("Notes", "\(day.statistics.noteCount)"),
            ("Words", "\(day.statistics.wordCount)"),
            ("Characters", "\(day.statistics.characterCount)"),
            ("Holidays", "\(day.statistics.holidayCount)")
        ]

        let itemWidth = (contentRect.width - 24) / 2
        var xOffset: CGFloat = 0
        var rowIndex = 0

        for (index, stat) in stats.enumerated() {
            let itemRect = CGRect(
                x: contentRect.minX + xOffset,
                y: currentY,
                width: itemWidth,
                height: 50
            )

            // Draw background
            context.setFillColor(Colors.cardBackground.cgColor)
            let itemPath = UIBezierPath(roundedRect: itemRect.insetBy(dx: 4, dy: 0), cornerRadius: 6)
            context.addPath(itemPath.cgPath)
            context.fillPath()

            // Draw value
            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.heading,
                .foregroundColor: Colors.text
            ]
            (stat.1 as NSString).draw(
                at: CGPoint(x: itemRect.minX + 12, y: itemRect.minY + 8),
                withAttributes: valueAttrs
            )

            // Draw label
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.caption,
                .foregroundColor: Colors.textSecondary
            ]
            (stat.0 as NSString).draw(
                at: CGPoint(x: itemRect.minX + 12, y: itemRect.minY + 32),
                withAttributes: labelAttrs
            )

            // Update position
            if (index + 1) % 2 == 0 {
                xOffset = 0
                currentY += 58
                rowIndex += 1
            } else {
                xOffset = itemWidth + 8
            }
        }

        if stats.count % 2 != 0 {
            currentY += 58
        }

        return currentY
    }

    private func drawFooter(pageNumber: Int, totalPages: Int, in context: CGContext) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let footerText = "Page \(pageNumber) of \(totalPages) • Generated \(dateFormatter.string(from: Date()))"
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.small,
            .foregroundColor: Colors.textSecondary
        ]

        let footerSize = (footerText as NSString).size(withAttributes: footerAttrs)
        let footerPoint = CGPoint(
            x: contentRect.maxX - footerSize.width,
            y: pageSize.height - margin + 8
        )

        (footerText as NSString).draw(at: footerPoint, withAttributes: footerAttrs)
    }

    // MARK: - Trip Report Rendering

    private func renderTripReportPage(
        reportData: TripReportExportInfo,
        in context: CGContext
    ) {
        var yPosition: CGFloat = contentRect.minY

        // Title
        let titleText = "VECKA TRAVEL REPORT"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.title,
            .foregroundColor: Colors.text
        ]
        let titleSize = (titleText as NSString).size(withAttributes: titleAttrs)
        (titleText as NSString).draw(at: CGPoint(x: contentRect.minX, y: yPosition), withAttributes: titleAttrs)
        yPosition += titleSize.height + 24

        // Trip Info
        drawTripHeader(reportData: reportData, yPosition: &yPosition, in: context)

        // Expenses Section
        if !reportData.expenses.isEmpty {
            yPosition += 24
            drawExpensesSection(expenses: reportData.expenses, totalExpenses: reportData.totalExpenses, yPosition: &yPosition, in: context)
        }

        // Mileage Section
        if !reportData.mileageEntries.isEmpty {
            yPosition += 24
            drawMileageSection(entries: reportData.mileageEntries, totalMileage: reportData.totalMileage, yPosition: &yPosition, in: context)
        }

        // Reimbursement Summary
        yPosition += 32
        drawReimbursementSummary(reportData: reportData, yPosition: &yPosition, in: context)

        // Footer
        drawFooter(pageNumber: 1, totalPages: 1, in: context)
    }

    private func drawTripHeader(reportData: TripReportExportInfo, yPosition: inout CGFloat, in context: CGContext) {
        // Trip name
        let tripAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.heading,
            .foregroundColor: Colors.text
        ]
        (reportData.tripName as NSString).draw(at: CGPoint(x: contentRect.minX, y: yPosition), withAttributes: tripAttrs)
        yPosition += 28

        // Destination and dates
        let detailsAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.textSecondary
        ]

        let details = "\(reportData.destination) • \(reportData.dateRange) • \(reportData.duration) days"
        (details as NSString).draw(at: CGPoint(x: contentRect.minX, y: yPosition), withAttributes: detailsAttrs)
        yPosition += 24

        // Separator
        context.setStrokeColor(Colors.textTertiary.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: contentRect.minX, y: yPosition))
        context.addLine(to: CGPoint(x: contentRect.maxX, y: yPosition))
        context.strokePath()
        yPosition += 8
    }

    private func drawExpensesSection(expenses: [ExpenseExportInfo], totalExpenses: Decimal, yPosition: inout CGFloat, in context: CGContext) {
        // Section title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.subheading,
            .foregroundColor: Colors.text
        ]
        let title = "EXPENSES"
        (title as NSString).draw(at: CGPoint(x: contentRect.minX, y: yPosition), withAttributes: titleAttrs)
        yPosition += 24

        // Expense items
        let itemAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.text
        ]
        let amountAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.bodyBold,
            .foregroundColor: Colors.text
        ]

        for expense in expenses.prefix(10) { // Limit to first 10
            let desc = "• \(expense.category)"
            (desc as NSString).draw(at: CGPoint(x: contentRect.minX + 8, y: yPosition), withAttributes: itemAttrs)

            let amount = expense.formattedAmount
            let amountSize = (amount as NSString).size(withAttributes: amountAttrs)
            (amount as NSString).draw(at: CGPoint(x: contentRect.maxX - amountSize.width, y: yPosition), withAttributes: amountAttrs)

            yPosition += 20
        }

        let pdfPageLimit = ConfigurationManager.shared.getInt("pdf_items_per_page", context: modelContext, default: 10)
        if expenses.count > pdfPageLimit {
            let moreText = "... and \(expenses.count - pdfPageLimit) more"
            let moreAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.caption,
                .foregroundColor: Colors.textTertiary
            ]
            (moreText as NSString).draw(at: CGPoint(x: contentRect.minX + 8, y: yPosition), withAttributes: moreAttrs)
            yPosition += 20
        }
    }

    private func drawMileageSection(entries: [MileageExportInfo], totalMileage: Double, yPosition: inout CGFloat, in context: CGContext) {
        // Section title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.subheading,
            .foregroundColor: Colors.text
        ]
        let title = "MILEAGE"
        (title as NSString).draw(at: CGPoint(x: contentRect.minX, y: yPosition), withAttributes: titleAttrs)
        yPosition += 24

        // Mileage entries
        let itemAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.text
        ]
        let distAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.bodyBold,
            .foregroundColor: Colors.text
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        for entry in entries.prefix(10) { // Limit to first 10
            let dateStr = dateFormatter.string(from: entry.date)
            let route = entry.routeDescription
            let desc = "• \(dateStr)  \(route)"
            (desc as NSString).draw(at: CGPoint(x: contentRect.minX + 8, y: yPosition), withAttributes: itemAttrs)

            let distance = entry.formattedDistance
            let distSize = (distance as NSString).size(withAttributes: distAttrs)
            (distance as NSString).draw(at: CGPoint(x: contentRect.maxX - distSize.width, y: yPosition), withAttributes: distAttrs)

            yPosition += 20
        }

        let pdfPageLimit = ConfigurationManager.shared.getInt("pdf_items_per_page", context: modelContext, default: 10)
        if entries.count > pdfPageLimit {
            let moreText = "... and \(entries.count - pdfPageLimit) more"
            let moreAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.caption,
                .foregroundColor: Colors.textTertiary
            ]
            (moreText as NSString).draw(at: CGPoint(x: contentRect.minX + 8, y: yPosition), withAttributes: moreAttrs)
            yPosition += 20
        }
    }

    private func drawReimbursementSummary(reportData: TripReportExportInfo, yPosition: inout CGFloat, in context: CGContext) {
        // Separator
        context.setStrokeColor(Colors.text.cgColor)
        context.setLineWidth(2.0)
        context.move(to: CGPoint(x: contentRect.minX, y: yPosition))
        context.addLine(to: CGPoint(x: contentRect.maxX, y: yPosition))
        context.strokePath()
        yPosition += 16

        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.subheading,
            .foregroundColor: Colors.text
        ]
        ("REIMBURSEMENT SUMMARY" as NSString).draw(at: CGPoint(x: contentRect.minX, y: yPosition), withAttributes: titleAttrs)
        yPosition += 24

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.text
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.bodyBold,
            .foregroundColor: Colors.text
        ]

        // Expenses
        ("Expenses" as NSString).draw(at: CGPoint(x: contentRect.minX, y: yPosition), withAttributes: labelAttrs)
        let expensesText = String(format: "%.0f %@", NSDecimalNumber(decimal: reportData.totalExpenses).doubleValue, reportData.currency)
        let expensesSize = (expensesText as NSString).size(withAttributes: valueAttrs)
        (expensesText as NSString).draw(at: CGPoint(x: contentRect.maxX - expensesSize.width, y: yPosition), withAttributes: valueAttrs)
        yPosition += 20

        // Mileage
        ("Mileage" as NSString).draw(at: CGPoint(x: contentRect.minX, y: yPosition), withAttributes: labelAttrs)
        let mileageText = String(format: "%.0f %@", NSDecimalNumber(decimal: reportData.mileageReimbursement).doubleValue, reportData.currency)
        let mileageSize = (mileageText as NSString).size(withAttributes: valueAttrs)
        (mileageText as NSString).draw(at: CGPoint(x: contentRect.maxX - mileageSize.width, y: yPosition), withAttributes: valueAttrs)

        let mileageDetail = String(format: "(%.1f km × %.2f)", reportData.totalMileage, reportData.mileageRate)
        let detailAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.caption,
            .foregroundColor: Colors.textSecondary
        ]
        let detailSize = (mileageDetail as NSString).size(withAttributes: detailAttrs)
        (mileageDetail as NSString).draw(at: CGPoint(x: contentRect.maxX - mileageSize.width - detailSize.width - 8, y: yPosition + 2), withAttributes: detailAttrs)
        yPosition += 24

        // Separator
        context.setStrokeColor(Colors.text.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: contentRect.minX, y: yPosition))
        context.addLine(to: CGPoint(x: contentRect.maxX, y: yPosition))
        context.strokePath()
        yPosition += 12

        // Total
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.heading,
            .foregroundColor: Colors.text
        ]
        ("TOTAL" as NSString).draw(at: CGPoint(x: contentRect.minX, y: yPosition), withAttributes: totalAttrs)
        let totalText = String(format: "%.0f %@", NSDecimalNumber(decimal: reportData.totalReimbursement).doubleValue, reportData.currency)
        let totalSize = (totalText as NSString).size(withAttributes: totalAttrs)
        (totalText as NSString).draw(at: CGPoint(x: contentRect.maxX - totalSize.width, y: yPosition), withAttributes: totalAttrs)
    }
}

// MARK: - UIColor Hex Extension

extension UIColor {
    convenience init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}
