import AppIntents
import SwiftData

// MARK: - "How much did I spend today?"

struct TodaySpendingIntent: AppIntent {
    static let title: LocalizedStringResource = "Today's Spending"
    static let description: IntentDescription = "Shows how much you spent today"
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let schema = Schema([Receipt.self])
        let config = ModelConfiguration(schema: schema)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let startOfDay = Calendar.current.startOfDay(for: .now)
        let predicate = #Predicate<Receipt> { $0.date >= startOfDay }
        let descriptor = FetchDescriptor<Receipt>(predicate: predicate)
        let receipts = try context.fetch(descriptor)

        let total = receipts.reduce(Decimal(0)) { $0 + $1.totalAmount }
        let currency = receipts.first?.currency ?? "USD"
        let formatted = total.formatted(.currency(code: currency))

        if receipts.isEmpty {
            return .result(dialog: "You haven't spent anything today.")
        }
        return .result(dialog: "You spent \(formatted) today across \(receipts.count) receipt\(receipts.count == 1 ? "" : "s").")
    }
}

// MARK: - "How much did I spend this week?"

struct WeekSpendingIntent: AppIntent {
    static let title: LocalizedStringResource = "This Week's Spending"
    static let description: IntentDescription = "Shows how much you spent this week"
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let schema = Schema([Receipt.self])
        let config = ModelConfiguration(schema: schema)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let startOfWeek = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: .now).date ?? .now
        let predicate = #Predicate<Receipt> { $0.date >= startOfWeek }
        let descriptor = FetchDescriptor<Receipt>(predicate: predicate)
        let receipts = try context.fetch(descriptor)

        let total = receipts.reduce(Decimal(0)) { $0 + $1.totalAmount }
        let currency = receipts.first?.currency ?? "USD"
        let formatted = total.formatted(.currency(code: currency))

        if receipts.isEmpty {
            return .result(dialog: "You haven't spent anything this week.")
        }
        return .result(dialog: "You spent \(formatted) this week across \(receipts.count) receipt\(receipts.count == 1 ? "" : "s").")
    }
}

// MARK: - Shortcuts Provider

struct ReceiptBrainShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TodaySpendingIntent(),
            phrases: [
                "How much did I spend today in \(.applicationName)",
                "Today's spending in \(.applicationName)",
            ],
            shortTitle: "Today's Spending",
            systemImageName: "dollarsign.circle"
        )
        AppShortcut(
            intent: WeekSpendingIntent(),
            phrases: [
                "How much did I spend this week in \(.applicationName)",
                "This week's spending in \(.applicationName)",
            ],
            shortTitle: "Week's Spending",
            systemImageName: "chart.bar"
        )
    }
}
