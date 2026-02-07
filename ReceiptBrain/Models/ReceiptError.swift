import Foundation

/// Domain errors for the receipt scanning pipeline.
/// Consolidated in Models/ per SGR — errors are part of the domain contract.
enum ReceiptError: Error, LocalizedError {
    // Vision / OCR errors
    case invalidImage
    case recognitionFailed
    case emptyOCRResult

    // Parser errors
    case noAmountFound

    var errorDescription: String? {
        switch self {
        case .invalidImage: "Could not process the image"
        case .recognitionFailed: "Text recognition failed"
        case .emptyOCRResult: "No text found on the receipt"
        case .noAmountFound: "Could not find an amount on the receipt"
        }
    }
}
