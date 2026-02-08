import Foundation

// AICODE-NOTE: Foundation Models parser — feeds full OCR text to Apple's on-device LLM
// and gets structured receipt data back via @Generable. Falls back to regex ReceiptParser
// when Apple Intelligence is unavailable (unsupported device, not enabled, iOS < 26).

#if canImport(FoundationModels)
import FoundationModels

/// Receipt data extracted by the on-device LLM via @Generable
@available(iOS 26, *)
@Generable(description: "Structured data extracted from a store receipt")
struct LLMReceiptData {
    @Guide(description: "The store or merchant name, e.g. 'Walmart', 'Starbucks'")
    var merchantName: String

    @Guide(description: "The total amount paid as a decimal number, e.g. 15.99")
    var totalAmount: Double

    @Guide(description: "The ISO 4217 currency code, e.g. 'USD', 'EUR', 'TRY', 'RUB'")
    var currency: String

    @Guide(description: "The receipt date in ISO 8601 format YYYY-MM-DD, e.g. '2026-02-08'")
    var dateString: String

    @Guide(description: "The expense category")
    var category: LLMCategory

    @Guide(description: "Individual line items from the receipt, each as 'item name - price'")
    var lineItems: [String]
}

/// Category enum for LLM generation
@available(iOS 26, *)
@Generable
enum LLMCategory: String {
    case groceries
    case dining
    case transport
    case shopping
    case utilities
    case health
    case entertainment
    case education
    case travel
    case other
}
#endif

/// Parses receipt OCR text using Apple's on-device Foundation Models.
/// Falls back to regex-based ReceiptParser when LLM is unavailable.
struct LLMParser {
    private let regexParser = ReceiptParser()

    /// Parse OCR result using LLM when available, regex fallback otherwise
    func parse(_ ocrResult: OCRResult) async -> ParsedReceipt {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let model = SystemLanguageModel.default
            if model.availability == .available {
                do {
                    return try await parseWithLLM(ocrResult)
                } catch {
                    // LLM failed — fall back to regex parser
                    return regexParser.parse(ocrResult)
                }
            }
        }
        #endif
        return regexParser.parse(ocrResult)
    }

    // MARK: - Private

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private func parseWithLLM(_ ocrResult: OCRResult) async throws -> ParsedReceipt {
        let session = LanguageModelSession()

        let prompt = """
        Extract structured receipt data from this OCR text. \
        Identify the merchant name, total amount, currency, date, category, and line items.

        OCR Text:
        \(ocrResult.fullText)
        """

        let response = try await session.respond(
            to: prompt,
            generating: LLMReceiptData.self
        )

        let data = response.content

        // Convert LLM result to domain model
        let category = ExpenseCategory(rawValue: data.category.rawValue) ?? .other
        let date = parseDate(data.dateString) ?? .now

        return ParsedReceipt(
            merchantName: data.merchantName,
            totalAmount: Decimal(data.totalAmount),
            currency: data.currency.isEmpty ? "USD" : data.currency,
            date: date,
            category: category,
            lineItems: data.lineItems,
            rawText: ocrResult.fullText
        )
    }
    #endif

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}
