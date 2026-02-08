import UIKit
import PDFKit

// AICODE-NOTE: Generates a monthly spending report PDF with header, category breakdown, and receipt list.
/// Service for generating monthly expense report PDFs.
struct PDFExportService {
    /// Generate a PDF report for the given receipts
    func generateReport(
        receipts: [Receipt],
        title: String,
        month: Date
    ) -> Data {
        let pageWidth: CGFloat = 612   // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )

        let data = renderer.pdfData { context in
            var yPosition: CGFloat = 0

            func ensureSpace(_ needed: CGFloat) {
                if yPosition + needed > pageHeight - margin {
                    context.beginPage()
                    yPosition = margin
                }
            }

            // Page 1
            context.beginPage()
            yPosition = margin

            // Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.label,
            ]
            let titleStr = title as NSString
            let titleRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 32)
            titleStr.draw(in: titleRect, withAttributes: titleAttr)
            yPosition += 40

            // Date range
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
            let dateStr = dateFormatter.string(from: month)
            let subtitleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.secondaryLabel,
            ]
            (dateStr as NSString).draw(
                in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 20),
                withAttributes: subtitleAttr
            )
            yPosition += 30

            // Separator
            drawLine(context: context.cgContext, y: yPosition, margin: margin, width: contentWidth)
            yPosition += 16

            // Summary
            let total = receipts.reduce(Decimal(0)) { $0 + $1.totalAmount }
            let currency = receipts.first?.currency ?? "USD"
            let formattedTotal = total.formatted(.currency(code: currency))

            let summaryFont = UIFont.boldSystemFont(ofSize: 18)
            let summaryAttr: [NSAttributedString.Key: Any] = [
                .font: summaryFont,
                .foregroundColor: UIColor.label,
            ]
            ("Total: \(formattedTotal)" as NSString).draw(
                in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 24),
                withAttributes: summaryAttr
            )
            yPosition += 28

            let countStr = "\(receipts.count) receipt\(receipts.count == 1 ? "" : "s")"
            (countStr as NSString).draw(
                in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 18),
                withAttributes: subtitleAttr
            )
            yPosition += 30

            // Category breakdown
            drawLine(context: context.cgContext, y: yPosition, margin: margin, width: contentWidth)
            yPosition += 16

            let sectionFont = UIFont.boldSystemFont(ofSize: 16)
            let sectionAttr: [NSAttributedString.Key: Any] = [
                .font: sectionFont,
                .foregroundColor: UIColor.label,
            ]
            ("By Category" as NSString).draw(
                in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 22),
                withAttributes: sectionAttr
            )
            yPosition += 28

            let categoryTotals = categoryBreakdown(receipts)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let bodyAttr: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.label,
            ]
            let rightAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.label,
            ]

            for (category, catTotal) in categoryTotals {
                ensureSpace(20)
                let catName = category.displayName
                let catAmount = catTotal.formatted(.currency(code: currency))

                (catName as NSString).draw(
                    in: CGRect(x: margin + 8, y: yPosition, width: contentWidth / 2, height: 18),
                    withAttributes: bodyAttr
                )

                let amountSize = (catAmount as NSString).size(withAttributes: rightAttr)
                (catAmount as NSString).draw(
                    at: CGPoint(x: pageWidth - margin - amountSize.width, y: yPosition),
                    withAttributes: rightAttr
                )
                yPosition += 20
            }

            yPosition += 12

            // Receipt list
            drawLine(context: context.cgContext, y: yPosition, margin: margin, width: contentWidth)
            yPosition += 16

            ("All Receipts" as NSString).draw(
                in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 22),
                withAttributes: sectionAttr
            )
            yPosition += 28

            // Table header
            let headerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 10),
                .foregroundColor: UIColor.secondaryLabel,
            ]

            ("DATE" as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttr)
            ("MERCHANT" as NSString).draw(at: CGPoint(x: margin + 80, y: yPosition), withAttributes: headerAttr)
            ("CATEGORY" as NSString).draw(at: CGPoint(x: margin + 300, y: yPosition), withAttributes: headerAttr)
            let amtHeader = "AMOUNT" as NSString
            let amtHeaderSize = amtHeader.size(withAttributes: headerAttr)
            amtHeader.draw(at: CGPoint(x: pageWidth - margin - amtHeaderSize.width, y: yPosition), withAttributes: headerAttr)
            yPosition += 18

            drawLine(context: context.cgContext, y: yPosition, margin: margin, width: contentWidth)
            yPosition += 6

            let rowFont = UIFont.systemFont(ofSize: 10)
            let rowAttr: [NSAttributedString.Key: Any] = [
                .font: rowFont,
                .foregroundColor: UIColor.label,
            ]
            let dateRowFormatter = DateFormatter()
            dateRowFormatter.dateFormat = "MMM d"

            let sorted = receipts.sorted { $0.date > $1.date }
            for receipt in sorted {
                ensureSpace(18)

                let dateStr = dateRowFormatter.string(from: receipt.date)
                (dateStr as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: rowAttr)

                let merchantStr = String(receipt.merchantName.prefix(30))
                (merchantStr as NSString).draw(at: CGPoint(x: margin + 80, y: yPosition), withAttributes: rowAttr)

                (receipt.category.displayName as NSString).draw(
                    at: CGPoint(x: margin + 300, y: yPosition),
                    withAttributes: rowAttr
                )

                let amountStr = receipt.totalAmount.formatted(.currency(code: receipt.currency))
                let amtSize = (amountStr as NSString).size(withAttributes: rightAttr)
                (amountStr as NSString).draw(
                    at: CGPoint(x: pageWidth - margin - amtSize.width, y: yPosition),
                    withAttributes: [
                        .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium),
                        .foregroundColor: UIColor.label,
                    ]
                )
                yPosition += 16
            }

            // Footer
            ensureSpace(40)
            yPosition += 20
            drawLine(context: context.cgContext, y: yPosition, margin: margin, width: contentWidth)
            yPosition += 10
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.tertiaryLabel,
            ]
            let footerStr = "Generated by ReceiptBrain • \(Date.now.formatted(.dateTime.month(.abbreviated).day().year().hour().minute()))"
            (footerStr as NSString).draw(
                in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 14),
                withAttributes: footerAttr
            )
        }

        return data
    }

    // MARK: - Helpers

    private func drawLine(context: CGContext, y: CGFloat, margin: CGFloat, width: CGFloat) {
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: margin + width, y: y))
        context.strokePath()
    }

    private func categoryBreakdown(_ receipts: [Receipt]) -> [(ExpenseCategory, Decimal)] {
        var totals: [ExpenseCategory: Decimal] = [:]
        for receipt in receipts {
            totals[receipt.category, default: 0] += receipt.totalAmount
        }
        return totals.sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }
}
