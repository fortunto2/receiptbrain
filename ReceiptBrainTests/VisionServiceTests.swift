import Testing
import UIKit
@testable import ReceiptBrain

/// These render a receipt and put it through the real recogniser rather than
/// stubbing it. OCR settings are exactly the kind of thing that looks right in
/// review and fails on an actual photo, so the test has to touch Vision.
@Suite("Vision OCR")
struct VisionServiceTests {

    /// A plain white receipt in a condensed monospaced face — close enough to
    /// thermal paper for the settings under test to matter.
    private func receiptImage(rotated: UIImage.Orientation = .up) -> UIImage {
        let size = CGSize(width: 380, height: 520)
        let renderer = UIGraphicsImageRenderer(size: size)
        let upright = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let lines = [
                "MIGROS",
                "Bagdat Cad. 120, Istanbul",
                "",
                "SUT 1L            24.90",
                "EKMEK              8.50",
                "PEYNIR 200G       89.90",
                "",
                "TOPLAM           123.30",
                "KDV %10           12.33",
                "",
                "19.08.2026  14:32",
            ]
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 18, weight: .regular),
                .foregroundColor: UIColor.black,
            ]
            var y: CGFloat = 24
            for line in lines {
                (line as NSString).draw(at: CGPoint(x: 20, y: y), withAttributes: attrs)
                y += 30
            }
        }
        guard rotated != .up, let cg = upright.cgImage else { return upright }
        return UIImage(cgImage: cg, scale: upright.scale, orientation: rotated)
    }

    @Test("Reads a receipt")
    func readsReceipt() async throws {
        let result = try await VisionService().recognizeText(from: receiptImage())
        let text = result.lines.joined(separator: "\n").uppercased()

        #expect(text.contains("MIGROS"), "merchant must survive OCR: \(result.lines)")
        #expect(text.contains("TOPLAM"), "total keyword must survive: \(result.lines)")
        #expect(text.contains("123.30"), "the total itself must survive: \(result.lines)")
    }

    /// The bug this suite exists for: a photo taken in a normal portrait grip
    /// arrives with orientation .right, and the old code told Vision it was .up.
    /// The recogniser then saw sideways text and returned almost nothing.
    @Test("Reads a receipt photographed sideways")
    func readsRotatedReceipt() async throws {
        let result = try await VisionService().recognizeText(from: receiptImage(rotated: .right))
        let text = result.lines.joined(separator: "\n").uppercased()

        #expect(text.contains("MIGROS"), "rotation must be honoured: \(result.lines)")
        #expect(text.contains("123.30"), "total must survive rotation: \(result.lines)")
    }

    /// Order is not decoration: the parser takes the merchant from the first
    /// line and the total from the last amount. Vision returns observations
    /// unordered, so sorting is part of the contract.
    @Test("Returns lines top to bottom")
    func ordersLines() async throws {
        let result = try await VisionService().recognizeText(from: receiptImage())
        let joined = result.lines.joined(separator: "\n").uppercased()
        let merchant = try #require(joined.range(of: "MIGROS"))
        let total = try #require(joined.range(of: "TOPLAM"))
        #expect(merchant.lowerBound < total.lowerBound, "merchant must come before the total")
    }

    /// End to end: what the OCR produces has to be parseable, which is the only
    /// thing that actually matters to the person scanning.
    @Test("OCR output parses into a receipt")
    func ocrFeedsParser() async throws {
        let ocr = try await VisionService().recognizeText(from: receiptImage())
        let parsed = ReceiptParser().parse(ocr)
        #expect(parsed.totalAmount == Decimal(string: "123.30"), "parsed: \(String(describing: parsed.totalAmount))")
    }
}
