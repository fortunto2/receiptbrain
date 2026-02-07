import Foundation
import SwiftData

@Model
final class Receipt {
    @Attribute(.unique) var id: UUID
    var merchantName: String
    var totalAmount: Decimal
    var currency: String
    var date: Date
    var category: ExpenseCategory
    var paymentMethod: PaymentMethod
    @Attribute(.externalStorage) var imageData: Data?
    var rawOCRText: String
    var isManuallyEdited: Bool
    var createdAt: Date

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
