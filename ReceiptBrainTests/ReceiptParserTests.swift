import Testing
@testable import ReceiptBrain

@Suite("Receipt Parser Tests")
struct ReceiptParserTests {
    let parser = ReceiptParser()

    @Test("Extracts merchant from first text line")
    func extractMerchant() {
        let lines = ["MIGROS", "Istanbul, Turkey", "Item 1   $3.50", "TOTAL   $15.00"]
        let result = parser.parse(lines: lines)
        #expect(result.merchantName == "MIGROS")
    }

    @Test("Extracts total amount near TOTAL keyword")
    func extractTotalAmount() {
        let lines = ["STARBUCKS", "Latte   $5.50", "Cookie  $3.00", "TOTAL   $8.50"]
        let result = parser.parse(lines: lines)
        #expect(result.totalAmount == Decimal(string: "8.50"))
    }

    @Test("Falls back to largest amount when no TOTAL keyword")
    func extractLargestAmount() {
        let lines = ["SHOP", "$2.00", "$5.00", "$12.50"]
        let result = parser.parse(lines: lines)
        #expect(result.totalAmount == Decimal(string: "12.50"))
    }

    @Test("Categorizes grocery stores correctly")
    func categorizeGroceries() {
        let lines = ["MIGROS", "TOTAL $25.00"]
        let result = parser.parse(lines: lines)
        #expect(result.category == .groceries)
    }

    @Test("Categorizes restaurants correctly")
    func categorizeDining() {
        let lines = ["STARBUCKS COFFEE", "TOTAL $8.50"]
        let result = parser.parse(lines: lines)
        #expect(result.category == .dining)
    }

    @Test("Returns .other for unknown merchants")
    func categorizeUnknown() {
        let lines = ["RANDOM SHOP XYZ", "TOTAL $10.00"]
        let result = parser.parse(lines: lines)
        #expect(result.category == .other)
    }

    @Test("Extracts date from dd/MM/yyyy format")
    func extractDateDDMMYYYY() {
        let lines = ["SHOP", "07/02/2026", "TOTAL $5.00"]
        let result = parser.parse(lines: lines)
        let calendar = Calendar.current
        #expect(calendar.component(.year, from: result.date) == 2026)
    }

    @Test("Handles empty input gracefully")
    func emptyInput() {
        let result = parser.parse(lines: [])
        #expect(result.merchantName == "Unknown")
        #expect(result.totalAmount == 0)
    }
}
