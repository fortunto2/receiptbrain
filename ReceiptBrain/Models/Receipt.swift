import Foundation
import SwiftData
import UIKit

// AICODE-NOTE: All properties have defaults — required by CloudKit integration
@Model
final class Receipt {
    var id: UUID = UUID()
    var merchantName: String = ""
    var totalAmount: Decimal = 0
    var currency: String = "USD"
    var date: Date = Date.now
    var category: ExpenseCategory = ExpenseCategory.other
    var paymentMethod: PaymentMethod = PaymentMethod.cash
    @Attribute(.externalStorage) var imageData: Data?
    var rawOCRText: String = ""
    var isManuallyEdited: Bool = false
    var createdAt: Date = Date.now

    init(
        merchantName: String,
        totalAmount: Decimal,
        currency: String = "USD",
        date: Date = .now,
        category: ExpenseCategory = .other,
        paymentMethod: PaymentMethod = .cash,
        imageData: Data? = nil,
        rawOCRText: String = ""
    ) {
        self.id = UUID()
        self.merchantName = merchantName
        self.totalAmount = totalAmount
        self.currency = currency
        self.date = date
        self.category = category
        self.paymentMethod = paymentMethod
        self.imageData = imageData
        self.rawOCRText = rawOCRText
        self.isManuallyEdited = false
        self.createdAt = .now
    }
    var shareText: String {
        let amount = totalAmount.formatted(.currency(code: currency))
        let dateStr = date.formatted(.dateTime.month(.abbreviated).day().year())
        return "\(merchantName) \(amount) (\(dateStr)) — \(category.displayName)"
    }

    /// Items for UIActivityViewController: photo (if available) + text
    var shareItems: [Any] {
        var items: [Any] = [shareText]
        if let data = imageData, let image = UIImage(data: data) {
            items.insert(image, at: 0)
        }
        return items
    }
}

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case groceries, dining, transport, shopping, utilities
    case health, entertainment, education, travel, other

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .groceries: "cart.fill"
        case .dining: "fork.knife"
        case .transport: "car.fill"
        case .shopping: "bag.fill"
        case .utilities: "bolt.fill"
        case .health: "heart.fill"
        case .entertainment: "film.fill"
        case .education: "book.fill"
        case .travel: "airplane"
        case .other: "ellipsis.circle.fill"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case cash, creditCard, debitCard, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cash: "Cash"
        case .creditCard: "Credit Card"
        case .debitCard: "Debit Card"
        case .other: "Other"
        }
    }
}
