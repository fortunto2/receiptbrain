import Foundation

/// Intermediate domain model between OCR and persistence.
/// ReceiptParser produces this; user reviews it; then it becomes a Receipt (@Model).
///
/// Part of the typed pipeline: UIImage → OCRResult → **ParsedReceipt** → Receipt
struct ParsedReceipt: Sendable {
    let merchantName: String
    let totalAmount: Decimal
    let currency: String
    let date: Date
    let category: ExpenseCategory
    let rawText: String

    /// Convert to a persisted Receipt model (after user review/edit)
    func toReceipt(
        merchantName: String? = nil,
        totalAmount: Decimal? = nil,
        date: Date? = nil,
        category: ExpenseCategory? = nil,
        paymentMethod: PaymentMethod = .cash,
        imageData: Data? = nil
    ) -> Receipt {
        Receipt(
            merchantName: merchantName ?? self.merchantName,
            totalAmount: totalAmount ?? self.totalAmount,
            currency: currency,
            date: date ?? self.date,
            category: category ?? self.category,
            paymentMethod: paymentMethod,
            imageData: imageData,
            rawOCRText: rawText
        )
    }
}
