import Foundation

// AI-NOTE: OCRResult is the typed output of VisionService — replaces raw [String] in the pipeline
/// Typed wrapper for Vision OCR output. Part of the typed pipeline:
/// UIImage → OCRResult → ParsedReceipt → Receipt
struct OCRResult: Sendable {
    /// Individual text lines recognized by Vision
    let lines: [String]

    /// Full text joined from lines (convenience for raw storage)
    var fullText: String {
        lines.joined(separator: "\n")
    }

    /// Whether OCR produced any meaningful output
    var isEmpty: Bool {
        lines.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
