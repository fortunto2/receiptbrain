import Vision
import UIKit

// AICODE-NOTE: VisionService returns OCRResult (typed), not raw [String]. Errors use domain ReceiptError.
/// Actor for thread-safe OCR. Part of the typed pipeline:
/// UIImage → **VisionService** → OCRResult → ReceiptParser → ParsedReceipt → Receipt
actor VisionService {
    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw ReceiptError.invalidImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "tr-TR", "ru-RU"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        try handler.perform([request])

        guard let observations = request.results else {
            return OCRResult(lines: [])
        }

        let lines = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }

        return OCRResult(lines: lines)
    }
}
