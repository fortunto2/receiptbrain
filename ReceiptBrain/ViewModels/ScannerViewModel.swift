import SwiftUI
import SwiftData
import PhotosUI
import CoreSpotlight

// AICODE-NOTE: ViewModel uses typed pipeline: UIImage → OCRResult → ParsedReceipt → Receipt. No raw strings.
@MainActor
@Observable
final class ScannerViewModel {
    var selectedPhoto: PhotosPickerItem?
    var capturedImage: UIImage?
    var parsedReceipt: ParsedReceipt?
    var isProcessing = false
    var errorMessage: String?

    // Editable fields (user can override OCR results)
    var merchantName = ""
    var totalAmount = ""
    var selectedCategory: ExpenseCategory = .other
    var selectedPaymentMethod: PaymentMethod = .cash
    var receiptDate = Date.now

    private let visionService = VisionService()
    private let parser = ReceiptParser()
    private let llmParser = LLMParser()
    private let photoLibrary = PhotoLibraryService.shared

    func processImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        capturedImage = image

        do {
            // Typed pipeline: UIImage → OCRResult → LLM/Regex → ParsedReceipt
            let ocrResult = try await visionService.recognizeText(from: image)

            guard !ocrResult.isEmpty else {
                self.errorMessage = ReceiptError.emptyOCRResult.localizedDescription
                self.isProcessing = false
                return
            }

            // AICODE-NOTE: Use Foundation Models LLM when available, regex fallback otherwise
            let parsed = await llmParser.parse(ocrResult)

            self.parsedReceipt = parsed
            self.merchantName = parsed.merchantName
            self.totalAmount = "\(parsed.totalAmount)"
            self.selectedCategory = parsed.category
            self.receiptDate = parsed.date
            self.isProcessing = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isProcessing = false
        }
    }

    func saveReceipt(context: ModelContext) {
        guard let parsed = parsedReceipt else { return }
        let amount = Decimal(string: totalAmount) ?? 0
        let imageData = capturedImage?.jpegData(compressionQuality: 0.7)

        // Save to Photos album (fire-and-forget, don't block receipt saving)
        if let image = capturedImage {
            Task {
                try? await photoLibrary.savePhoto(image)
            }
        }

        // Use ParsedReceipt.toReceipt() — schema-driven conversion
        let receipt = parsed.toReceipt(
            merchantName: merchantName,
            totalAmount: amount,
            date: receiptDate,
            category: selectedCategory,
            paymentMethod: selectedPaymentMethod,
            imageData: imageData
        )

        context.insert(receipt)
        indexInSpotlight(receipt)
        reset()
    }

    private func indexInSpotlight(_ receipt: Receipt) {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.displayName = receipt.merchantName
        attributes.contentDescription = receipt.shareText
        if let data = receipt.imageData {
            attributes.thumbnailData = data
        }

        let item = CSSearchableItem(
            uniqueIdentifier: receipt.id.uuidString,
            domainIdentifier: "com.receiptbrain.receipts",
            attributeSet: attributes
        )
        CSSearchableIndex.default().indexSearchableItems([item])
    }

    func reset() {
        selectedPhoto = nil
        capturedImage = nil
        parsedReceipt = nil
        merchantName = ""
        totalAmount = ""
        selectedCategory = .other
        selectedPaymentMethod = .cash
        receiptDate = .now
        errorMessage = nil
    }
}
