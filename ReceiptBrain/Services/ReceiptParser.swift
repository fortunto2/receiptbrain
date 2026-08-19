import Foundation
import NaturalLanguage

// AI-NOTE: Parser accepts OCRResult (typed), returns ParsedReceipt (typed). No raw strings cross service boundaries.
/// Parses OCR output into structured receipt data.
/// Part of the typed pipeline: VisionService → OCRResult → **ReceiptParser** → ParsedReceipt
struct ReceiptParser {
    private let merchantDB = MerchantDatabase.shared

    /// Parse typed OCR result into structured receipt data
    func parse(_ ocrResult: OCRResult) -> ParsedReceipt {
        let merchant = extractMerchant(from: ocrResult.lines)
        let amount = extractTotalAmount(from: ocrResult.lines)
        let currency = detectCurrency(from: ocrResult.lines)
        let date = extractDate(from: ocrResult.lines)
        let lineItems = extractLineItems(from: ocrResult.lines)

        // AICODE-NOTE: Merchant DB match overrides regex-based category detection
        // Try merchant database first for canonical name + category
        let dbMatch = merchantDB.match(merchant)
        let finalMerchant = dbMatch?.canonicalName ?? merchant
        let category = dbMatch?.category ?? guessCategory(merchant: merchant, lines: ocrResult.lines)

        return ParsedReceipt(
            merchantName: finalMerchant,
            totalAmount: amount,
            currency: currency,
            date: date,
            category: category,
            lineItems: lineItems,
            rawText: ocrResult.fullText
        )
    }

    // MARK: - Private

    // AICODE-NOTE: Merchant extraction skips address-like lines and prefers UPPER CASE lines near the top
    private func extractMerchant(from lines: [String]) -> String {
        let addressPatterns: [String] = [
            "st.", "str.", "ave.", "ave ", "blvd", "road", "rd.",
            "tel:", "tel.", "phone", "fax", "www.", "http",
            "receipt", "cashier", "register", "terminal",
        ]
        let phonePattern = /\+?\d[\d\s\-()]{7,}/

        // First pass: look for an UPPER CASE line in the first 5 lines (common for store names)
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 2 else { continue }

            let letterCount = trimmed.unicodeScalars.filter(CharacterSet.letters.contains).count
            guard letterCount > trimmed.count / 2 else { continue }

            // Skip address/meta lines
            let lower = trimmed.lowercased()
            if addressPatterns.contains(where: { lower.contains($0) }) { continue }
            if trimmed.firstMatch(of: phonePattern) != nil { continue }

            // Prefer all-caps lines (typical store names)
            let uppercaseLetters = trimmed.unicodeScalars.filter(CharacterSet.uppercaseLetters.contains).count
            if uppercaseLetters > letterCount / 2 {
                return trimmed
            }
        }

        // Second pass: use NaturalLanguage NER to find organization names
        let fullText = lines.prefix(10).joined(separator: "\n")
        if let org = extractOrganizationName(from: fullText) { return org }

        // Third pass: first non-empty, non-numeric, non-address line
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let letterCount = trimmed.unicodeScalars.filter(CharacterSet.letters.contains).count
            guard letterCount > trimmed.count / 2 else { continue }

            let lower = trimmed.lowercased()
            if addressPatterns.contains(where: { lower.contains($0) }) { continue }
            if trimmed.firstMatch(of: phonePattern) != nil { continue }

            return trimmed
        }
        return "Unknown"
    }

    // AICODE-NOTE: NER-based organization name extraction using NaturalLanguage framework
    private func extractOrganizationName(from text: String) -> String? {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var orgName: String?
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word, scheme: .nameType,
            options: [.omitWhitespace, .omitPunctuation, .joinNames]
        ) { tag, range in
            if tag == .organizationName {
                let name = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if name.count >= 2 {
                    orgName = name
                    return false // stop
                }
            }
            return true
        }
        return orgName
    }

    // AICODE-NOTE: Amount regex accepts optional decimal part (e.g. "15" or "15.50" or "15.5")
    private func extractTotalAmount(from lines: [String]) -> Decimal {
        let totalKeywords = [
            "total", "toplam", "genel toplam", "итого", "всего", "сумма",
            "grand total", "amount due", "balance", "to pay", "due",
            "subtotal", "final", "net",
        ]
        var amounts: [(Decimal, Bool)] = [] // (amount, isNearKeyword)

        // Matches amounts with optional decimal part: $15, $15.50, 15.5, €3,00
        let amountPattern = /[\$€₺₽£]?\s*(\d{1,6}([.,]\d{1,2})?)/

        for line in lines {
            let lower = line.lowercased()
            let isKeywordLine = totalKeywords.contains { lower.contains($0) }

            // A date is not an amount. Without this the year wins the
            // "largest number" fallback on any receipt priced under ~2000,
            // which is most receipts in dollars or euros.
            if Self.looksLikeDate(lower) { continue }

            for match in lower.matches(of: amountPattern) {
                let numStr = String(match.1).replacingOccurrences(of: ",", with: ".")
                guard let value = Decimal(string: numStr), value > 0 else { continue }
                if Self.looksLikeYear(numStr) { continue }
                amounts.append((value, isKeywordLine))
            }
        }

        // Prefer amount near "TOTAL" keyword — take the largest one on keyword lines
        let keywordAmounts = amounts.filter(\.1).map(\.0)
        if let totalAmount = keywordAmounts.max() {
            return totalAmount
        }
        // Otherwise return the largest amount
        return amounts.map(\.0).max() ?? 0
    }

    /// 19.08.2026, 2026-08-19, 19/08/26 — any line carrying one is a date line,
    /// and nothing on it should be read as money.
    private static func looksLikeDate(_ line: String) -> Bool {
        let patterns: [Regex<AnyRegexOutput>] = [
            try! Regex(#"\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b"#),
            try! Regex(#"\b\d{4}[./-]\d{1,2}[./-]\d{1,2}\b"#),
        ]
        return patterns.contains { line.firstMatch(of: $0) != nil }
    }

    /// A bare four-digit number in the plausible year range, with no decimal
    /// part. Real totals of exactly 2026.00 exist but are rare enough that
    /// losing them beats reporting a year as the total on every other receipt.
    private static func looksLikeYear(_ numeric: String) -> Bool {
        guard !numeric.contains("."), numeric.count == 4,
              let year = Int(numeric) else { return false }
        return (1990...2100).contains(year)
    }

    private func detectCurrency(from lines: [String]) -> String {
        let symbols: [(String, String)] = [
            ("₺", "TRY"), ("€", "EUR"), ("₽", "RUB"), ("£", "GBP"), ("$", "USD"),
        ]
        // Most receipts never print the symbol — Turkish ones write "TL", German
        // ones "EUR", Russian ones "руб". Reading only symbols is why a Turkish
        // fuel receipt came out as dollars.
        let words: [(String, String)] = [
            ("try", "TRY"), (" tl", "TRY"), ("tl ", "TRY"), ("lira", "TRY"),
            ("eur", "EUR"), ("usd", "USD"), ("rub", "RUB"), ("руб", "RUB"),
            ("gbp", "GBP"), ("chf", "CHF"),
        ]

        for line in lines {
            for (symbol, code) in symbols where line.contains(symbol) { return code }
        }
        for line in lines {
            let padded = " " + line.lowercased() + " "
            for (word, code) in words where padded.contains(word) { return code }
        }

        // A receipt with no currency marking is almost always from where the
        // phone is. Defaulting to dollars made every unmarked local receipt wrong.
        return Locale.current.currency?.identifier ?? "USD"
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

    // AICODE-NOTE: Line items = lines containing an amount but NOT a total keyword
    private func extractLineItems(from lines: [String]) -> [String] {
        let totalKeywords = [
            "total", "toplam", "genel toplam", "итого", "всего", "сумма",
            "subtotal", "grand total", "amount due", "balance", "to pay",
            "tax", "vat", "kdv", "ндс", "change", "cash", "card", "visa", "mastercard",
        ]
        let amountPattern = /[\$€₺₽£]?\s*\d{1,6}([.,]\d{1,2})/

        var items: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let lower = trimmed.lowercased()
            // Skip total/payment/tax lines
            if totalKeywords.contains(where: { lower.contains($0) }) { continue }

            // Must contain an amount to be a line item
            guard trimmed.firstMatch(of: amountPattern) != nil else { continue }

            // Must have some letters (not just numbers)
            let letterCount = trimmed.unicodeScalars.filter(CharacterSet.letters.contains).count
            guard letterCount >= 2 else { continue }

            items.append(trimmed)
        }
        return items
    }

    // AICODE-NOTE: Category detection analyzes merchant name first, then falls back to full receipt text
    private func guessCategory(merchant: String, lines: [String]) -> ExpenseCategory {
        // Merchant-specific keywords (high confidence — store name matches)
        let merchantKeywords: [(ExpenseCategory, [String])] = [
            (.groceries, ["migros", "bim", "a101", "carrefour", "walmart", "aldi", "lidl", "market", "grocery", "supermarket", "whole foods", "trader joe", "costco", "target"]),
            (.dining, ["restaurant", "cafe", "coffee", "starbucks", "mcdonald", "burger", "pizza", "kebab", "sushi", "diner", "bistro", "bakery", "bar ", "pub "]),
            (.transport, ["uber", "lyft", "taxi", "gas", "fuel", "shell", "bp", "petrol", "parking", "metro", "transit"]),
            (.health, ["pharmacy", "apotek", "hospital", "clinic", "doctor", "eczane", "аптека", "medical"]),
            (.entertainment, ["cinema", "netflix", "spotify", "theater", "museum", "concert", "game"]),
            (.shopping, ["zara", "h&m", "amazon", "electronics", "ikea", "nike", "adidas", "uniqlo", "apple store"]),
            (.utilities, ["electric", "water", "internet", "telecom", "turkcell", "vodafone"]),
            (.education, ["bookstore", "university", "school", "course", "udemy"]),
        ]

        let lowerMerchant = merchant.lowercased()
        for (category, keywords) in merchantKeywords {
            if keywords.contains(where: { lowerMerchant.contains($0) }) {
                return category
            }
        }

        // Content-based keywords (lower confidence — scan all receipt lines for product hints)
        let contentKeywords: [(ExpenseCategory, [String])] = [
            (.groceries, ["milk", "bread", "eggs", "cheese", "chicken", "beef", "fruit", "vegetable", "yogurt", "butter", "rice", "pasta", "ekmek", "süt", "peynir", "молоко", "хлеб", "сыр"]),
            (.dining, ["latte", "espresso", "cappuccino", "americano", "tea ", "sandwich", "salad", "soup", "dessert", "wine", "beer"]),
            (.health, ["medicine", "vitamin", "ibuprofen", "paracetamol", "ilaç", "лекарств"]),
            (.transport, ["gasoline", "diesel", "benzin", "бензин", "litre", "liter", "gallon"]),
            (.shopping, ["shirt", "pants", "dress", "shoes", "jacket", "size s", "size m", "size l"]),
        ]

        let fullText = lines.joined(separator: " ").lowercased()
        var scores: [ExpenseCategory: Int] = [:]

        for (category, keywords) in contentKeywords {
            let hits = keywords.filter { fullText.contains($0) }.count
            if hits > 0 {
                scores[category, default: 0] += hits
            }
        }

        if let best = scores.max(by: { $0.value < $1.value }), best.value >= 2 {
            return best.key
        }
        if let best = scores.max(by: { $0.value < $1.value }), best.value >= 1 {
            return best.key
        }

        return .other
    }
}
