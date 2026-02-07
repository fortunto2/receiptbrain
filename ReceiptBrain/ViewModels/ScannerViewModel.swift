import SwiftUI
import SwiftData
import PhotosUI

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

    func processImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        capturedImage = image

        do {
            let lines = try await visionService.recognizeText(from: image)
            let parsed = parser.parse(lines: lines)

            await MainActor.run {
                self.parsedReceipt = parsed
                self.merchantName = parsed.merchantName
                self.totalAmount = "\(parsed.totalAmount)"
                self.selectedCategory = parsed.category
                self.receiptDate = parsed.date
                self.isProcessing = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
            }
        }
    }

    func saveReceipt(context: ModelContext) {
        let amount = Decimal(string: totalAmount) ?? 0
        let imageData = capturedImage?.jpegData(compressionQuality: 0.7)

        let receipt = Receipt(
            merchantName: merchantName,
            totalAmount: amount,
            date: receiptDate,
            category: selectedCategory,
            paymentMethod: selectedPaymentMethod,
            imageData: imageData,
            rawOCRText: parsedReceipt?.rawText ?? ""
        )

        context.insert(receipt)
        reset()
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
