import Testing
import Foundation
@testable import ReceiptBrain

@Suite("Receipt Parser Tests")
struct ReceiptParserTests {
    let parser = ReceiptParser()

    // Helper: create typed OCRResult from lines
    private func ocr(_ lines: [String]) -> OCRResult {
        OCRResult(lines: lines)
    }

    @Test("Extracts merchant from first text line")
    func extractMerchant() {
        let result = parser.parse(ocr(["MIGROS", "Istanbul, Turkey", "Item 1   $3.50", "TOTAL   $15.00"]))
        // MerchantDatabase normalizes "MIGROS" → "Migros"
        #expect(result.merchantName == "Migros")
    }

    @Test("Extracts total amount near TOTAL keyword")
    func extractTotalAmount() {
        let result = parser.parse(ocr(["STARBUCKS", "Latte   $5.50", "Cookie  $3.00", "TOTAL   $8.50"]))
        #expect(result.totalAmount == Decimal(string: "8.50"))
    }

    @Test("Falls back to largest amount when no TOTAL keyword")
    func extractLargestAmount() {
        let result = parser.parse(ocr(["SHOP", "$2.00", "$5.00", "$12.50"]))
        #expect(result.totalAmount == Decimal(string: "12.50"))
    }

    @Test("Categorizes grocery stores correctly via MerchantDB")
    func categorizeGroceries() {
        let result = parser.parse(ocr(["MIGROS", "TOTAL $25.00"]))
        #expect(result.category == .groceries)
    }

    @Test("Categorizes restaurants correctly via MerchantDB")
    func categorizeDining() {
        let result = parser.parse(ocr(["STARBUCKS COFFEE", "TOTAL $8.50"]))
        #expect(result.category == .dining)
    }

    @Test("Returns .other for unknown merchants")
    func categorizeUnknown() {
        let result = parser.parse(ocr(["RANDOM SHOP XYZ", "TOTAL $10.00"]))
        #expect(result.category == .other)
    }

    @Test("Extracts date from dd/MM/yyyy format")
    func extractDateDDMMYYYY() {
        let result = parser.parse(ocr(["SHOP", "07/02/2026", "TOTAL $5.00"]))
        let calendar = Calendar.current
        #expect(calendar.component(.year, from: result.date) == 2026)
    }

    @Test("Handles empty input gracefully")
    func emptyInput() {
        let result = parser.parse(ocr([]))
        #expect(result.merchantName == "Unknown")
        #expect(result.totalAmount == 0)
    }

    @Test("Detects USD currency from $ symbol")
    func detectCurrencyUSD() {
        let result = parser.parse(ocr(["SHOP", "TOTAL $10.00"]))
        #expect(result.currency == "USD")
    }

    @Test("Detects TRY currency from ₺ symbol")
    func detectCurrencyTRY() {
        let result = parser.parse(ocr(["MIGROS", "TOPLAM ₺25.00"]))
        #expect(result.currency == "TRY")
    }

    @Test("OCRResult.isEmpty returns true for blank lines")
    func ocrResultEmpty() {
        let empty = OCRResult(lines: ["", "  "])
        #expect(empty.isEmpty)
    }

    @Test("OCRResult.fullText joins lines")
    func ocrResultFullText() {
        let result = OCRResult(lines: ["Line 1", "Line 2"])
        #expect(result.fullText == "Line 1\nLine 2")
    }

    @Test("ParsedReceipt.toReceipt creates valid Receipt")
    func parsedToReceipt() {
        let parsed = parser.parse(ocr(["STARBUCKS", "TOTAL $8.50"]))
        let receipt = parsed.toReceipt(paymentMethod: .creditCard)
        // MerchantDatabase normalizes "STARBUCKS" → "Starbucks"
        #expect(receipt.merchantName == "Starbucks")
        #expect(receipt.totalAmount == Decimal(string: "8.50"))
        #expect(receipt.paymentMethod == .creditCard)
        #expect(receipt.category == .dining)
    }

    // MARK: - Line Items

    @Test("Extracts line items from receipt")
    func extractLineItems() {
        let result = parser.parse(ocr([
            "WALMART",
            "Milk 2%   $3.99",
            "Bread     $2.50",
            "Eggs      $4.29",
            "SUBTOTAL  $10.78",
            "TAX       $0.86",
            "TOTAL     $11.64",
        ]))
        #expect(result.lineItems.count >= 2)
        #expect(result.totalAmount == Decimal(string: "11.64"))
    }

    @Test("Extracts amounts without decimals")
    func extractWholeAmounts() {
        let result = parser.parse(ocr(["SHOP", "Item $15", "TOTAL $15"]))
        #expect(result.totalAmount == 15)
    }

    // MARK: - Merchant Database

    @Test("MerchantDB matches known merchants")
    func merchantDBMatch() {
        let result = parser.parse(ocr(["WALMART SUPERCENTER", "TOTAL $50.00"]))
        #expect(result.merchantName == "Walmart")
        #expect(result.category == .groceries)
    }

    @Test("MerchantDB handles restaurant aliases")
    func merchantDBRestaurant() {
        let result = parser.parse(ocr(["MCDONALDS", "Big Mac $5.99", "TOTAL $5.99"]))
        #expect(result.merchantName == "McDonald's")
        #expect(result.category == .dining)
    }
}
