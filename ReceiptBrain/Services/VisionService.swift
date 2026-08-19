import Vision
import UIKit

// AI-NOTE: VisionService returns OCRResult (typed), not raw [String]. Errors use domain ReceiptError.
/// Actor for thread-safe OCR. Part of the typed pipeline:
/// UIImage → **VisionService** → OCRResult → ReceiptParser → ParsedReceipt → Receipt
///
/// Receipts are the hardest case Vision handles: thermal paper, low contrast,
/// tiny condensed type, product codes that are not words in any language, and a
/// photo that is nearly always taken at an angle. The settings below are all
/// chosen against that, and each one was wrong before.
actor VisionService {

    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw ReceiptError.invalidImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate

        // Language correction fits what it reads to a dictionary. On prose that
        // helps; on a receipt it rewrites exactly the parts that matter —
        // merchant names, abbreviated product lines, article numbers — into
        // whatever real word is nearest. Off.
        request.usesLanguageCorrection = false

        // One language, not three. Vision degrades noticeably when asked to
        // consider several at once, and worse when their alphabets differ.
        // The device locale is the best guess for where the receipt came from.
        request.recognitionLanguages = [Self.preferredLanguage()]

        // Receipt type is small and dense; the default floor drops whole lines
        // on a long receipt photographed from a normal distance.
        request.minimumTextHeight = 0.008

        // Prices and totals are what this app exists to read, so read them
        // together with everything else rather than in a second pass.
        request.recognitionLevel = .accurate

        // The image carries its own orientation. Hardcoding .up meant a photo
        // taken in the usual portrait grip arrived rotated, and the recogniser
        // saw sideways text — which is most of why receipts "did not scan".
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
        try handler.perform([request])

        guard let observations = request.results else {
            return OCRResult(lines: [])
        }

        return OCRResult(lines: Self.rowsByPosition(observations))
    }

    /// Group observations into visual rows, then read each row left to right.
    ///
    /// This is the part that makes a receipt parseable at all. A receipt is two
    /// columns — label on the left, amount on the right — and Vision returns
    /// each column as its own observation with no guaranteed order. Read
    /// naively you get "TOPLAM" and "123.30" as separate lines, so the parser
    /// never sees an amount next to its keyword and falls back to "largest
    /// number on the receipt", which on most receipts is the year in the date.
    static func rowsByPosition(_ observations: [VNRecognizedTextObservation]) -> [String] {
        // Half a line height: tall enough to hold a label and its amount
        // together, tight enough not to merge two adjacent items.
        let tolerance = 0.012

        let sorted = observations.sorted { $0.boundingBox.midY > $1.boundingBox.midY }
        var rows: [[VNRecognizedTextObservation]] = []

        for observation in sorted {
            if let last = rows.last?.first,
               abs(last.boundingBox.midY - observation.boundingBox.midY) < tolerance {
                rows[rows.count - 1].append(observation)
            } else {
                rows.append([observation])
            }
        }

        return rows.compactMap { row in
            let text = row
                .sorted { $0.boundingBox.minX < $1.boundingBox.minX }
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
            return text.isEmpty ? nil : text
        }
    }

    /// The receipt is almost always from where the phone is. Falls back to
    /// English, which is also what most receipt keywords (TOTAL, VAT) are in.
    private static func preferredLanguage() -> String {
        let supported = ["en-US", "tr-TR", "ru-RU", "de-DE", "fr-FR", "es-ES", "it-IT"]
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return supported.first { $0.hasPrefix(code) } ?? "en-US"
    }
}

private extension CGImagePropertyOrientation {
    /// UIImage.Orientation and CGImagePropertyOrientation do not share values;
    /// mapping them by hand is the only correct way across.
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
