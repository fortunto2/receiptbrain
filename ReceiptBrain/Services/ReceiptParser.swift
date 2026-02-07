import Foundation

// AICODE-NOTE: Parser extracts amounts via regex, merchant from first non-empty line, date via DateFormatter patterns
struct ReceiptParser {
    /// Parse OCR text lines into structured receipt data
    func parse(lines: [String]) -> ParsedReceipt {
        let fullText = lines.joined(separator: "\n")
        let merchant = extractMerchant(from: lines)
        let amount = extractTotalAmount(from: lines)
        let date = extractDate(from: lines)
        let category = guessCategory(merchant: merchant)

        return ParsedReceipt(
            merchantName: merchant,
            totalAmount: amount,
            date: date,
            category: category,
            rawText: fullText
        )
    }

    // MARK: - Private

    private func extractMerchant(from lines: [String]) -> String {
        // First non-empty, non-numeric line is usually the merchant
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            // Skip lines that are mostly numbers/symbols
            let letterCount = trimmed.unicodeScalars.filter(CharacterSet.letters.contains).count
            if letterCount > trimmed.count / 2 {
                return trimmed
            }
        }
        return "Unknown"
    }

    private func extractTotalAmount(from lines: [String]) -> Decimal {
        // Look for "TOTAL", "TOPLAM", "ИТОГО" followed by amount, or largest amount
        let totalKeywords = ["total", "toplam", "итого", "grand total", "amount due", "balance"]
        var amounts: [(Decimal, Bool)] = [] // (amount, isNearKeyword)

        let amountPattern = /[\$€₺₽]?\s*(\d{1,6}[.,]\d{2})/

        for line in lines {
            let lower = line.lowercased()
            let isKeywordLine = totalKeywords.contains { lower.contains($0) }

            if let match = lower.firstMatch(of: amountPattern) {
                let numStr = String(match.1).replacingOccurrences(of: ",", with: ".")
                if let value = Decimal(string: numStr) {
                    amounts.append((value, isKeywordLine))
                }
            }
        }

        // Prefer amount near "TOTAL" keyword
        if let totalLine = amounts.first(where: { $0.1 }) {
            return totalLine.0
        }
        // Otherwise return the largest amount
        return amounts.map(\.0).max() ?? 0
    }

    private func extractDate(from lines: [String]) -> Date {
        let dateFormats = [
            "dd/MM/yyyy", "MM/dd/yyyy", "dd.MM.yyyy",
            "yyyy-MM-dd", "dd-MM-yyyy", "dd/MM/yy",
        ]

        let datePattern = /\d{1,4}[\/.–-]\d{1,2}[\/.–-]\d{2,4}/

        for line in lines {
            if let match = line.firstMatch(of: datePattern) {
                let dateStr = String(match.0)
                for format in dateFormats {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                }
            }
        }
        return .now
    }

    private func guessCategory(merchant: String) -> ExpenseCategory {
        let lower = merchant.lowercased()
        let categoryKeywords: [(ExpenseCategory, [String])] = [
            (.groceries, ["migros", "bim", "a101", "carrefour", "walmart", "aldi", "lidl", "market", "grocery", "supermarket"]),
            (.dining, ["restaurant", "cafe", "coffee", "starbucks", "mcdonald", "burger", "pizza", "kebab"]),
            (.transport, ["uber", "lyft", "taxi", "gas", "fuel", "shell", "bp", "petrol", "parking"]),
            (.health, ["pharmacy", "apotek", "hospital", "clinic", "doctor"]),
            (.entertainment, ["cinema", "netflix", "spotify", "theater", "museum"]),
            (.shopping, ["zara", "h&m", "amazon", "electronics", "ikea"]),
        ]

        for (category, keywords) in categoryKeywords {
            if keywords.contains(where: { lower.contains($0) }) {
                return category
            }
        }
        return .other
    }
}

struct ParsedReceipt {
    let merchantName: String
    let totalAmount: Decimal
    let date: Date
    let category: ExpenseCategory
    let rawText: String
}
