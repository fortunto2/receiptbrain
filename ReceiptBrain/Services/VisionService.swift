import Vision
import UIKit

// AICODE-NOTE: VisionKit OCR pipeline — VNRecognizeTextRequest with .accurate level, runs off main thread
actor VisionService {
    func recognizeText(from image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "tr-TR", "ru-RU"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        try handler.perform([request])

        guard let observations = request.results else {
            return []
        }

        return observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
    }
}

enum VisionError: Error, LocalizedError {
    case invalidImage
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage: "Could not process the image"
        case .recognitionFailed: "Text recognition failed"
        }
    }
}
