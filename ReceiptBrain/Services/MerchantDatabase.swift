import Foundation

// AICODE-NOTE: Fuzzy-matches OCR merchant text against a local database of ~150 known merchants.
// Returns canonical name + category for high-confidence matches.

/// Local merchant database for category auto-detection.
/// Loaded from merchants.json at startup. Uses Levenshtein distance for fuzzy matching.
struct MerchantDatabase {
    static let shared = MerchantDatabase()

    private let merchants: [MerchantEntry]

    struct MerchantEntry: Decodable {
        let name: String
        let aliases: [String]
        let category: String
    }

    struct MatchResult {
        let canonicalName: String
        let category: ExpenseCategory
        let confidence: Double // 0.0–1.0
    }

    private init() {
        guard let url = Bundle.main.url(forResource: "merchants", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([MerchantEntry].self, from: data)
        else {
            merchants = []
            return
        }
        merchants = entries
    }

    /// Find best matching merchant for OCR text. Returns nil if no good match found.
    func match(_ ocrMerchant: String) -> MatchResult? {
        let query = ocrMerchant.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { return nil }

        var bestMatch: (entry: MerchantEntry, score: Double)?

        for entry in merchants {
            // Check canonical name
            let nameScore = similarity(query, entry.name.uppercased())
            if nameScore > (bestMatch?.score ?? 0) {
                bestMatch = (entry, nameScore)
            }

            // Check aliases
            for alias in entry.aliases {
                let aliasScore = similarity(query, alias.uppercased())
                if aliasScore > (bestMatch?.score ?? 0) {
                    bestMatch = (entry, aliasScore)
                }

                // Also check if OCR text contains the alias
                if query.contains(alias.uppercased()) {
                    let containsScore = Double(alias.count) / Double(max(query.count, 1))
                    let boosted = max(containsScore, 0.85)
                    if boosted > (bestMatch?.score ?? 0) {
                        bestMatch = (entry, boosted)
                    }
                }
            }

            // Check if OCR text contains canonical name
            if query.contains(entry.name.uppercased()) {
                let containsScore = Double(entry.name.count) / Double(max(query.count, 1))
                let boosted = max(containsScore, 0.85)
                if boosted > (bestMatch?.score ?? 0) {
                    bestMatch = (entry, boosted)
                }
            }
        }

        guard let match = bestMatch, match.score >= 0.6 else { return nil }

        let category = ExpenseCategory(rawValue: match.entry.category) ?? .other
        return MatchResult(
            canonicalName: match.entry.name,
            category: category,
            confidence: match.score
        )
    }

    // MARK: - Fuzzy Matching

    /// Normalized similarity score (0.0–1.0) using Levenshtein distance
    private func similarity(_ a: String, _ b: String) -> Double {
        let maxLen = max(a.count, b.count)
        guard maxLen > 0 else { return 1.0 }
        let distance = levenshteinDistance(a, b)
        return 1.0 - Double(distance) / Double(maxLen)
    }

    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        let aLen = aChars.count
        let bLen = bChars.count

        if aLen == 0 { return bLen }
        if bLen == 0 { return aLen }

        var prev = Array(0...bLen)
        var curr = [Int](repeating: 0, count: bLen + 1)

        for i in 1...aLen {
            curr[0] = i
            for j in 1...bLen {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,       // deletion
                    curr[j - 1] + 1,   // insertion
                    prev[j - 1] + cost  // substitution
                )
            }
            prev = curr
        }
        return prev[bLen]
    }
}
