import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct SpendingEntry: TimelineEntry {
    let date: Date
    let todayTotal: Decimal
    let weekTotal: Decimal
    let monthTotal: Decimal
    let receiptCount: Int
    let currency: String
    let topCategory: String
}

// MARK: - Timeline Provider

struct SpendingProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpendingEntry {
        SpendingEntry(
            date: .now,
            todayTotal: 42.50,
            weekTotal: 185.30,
            monthTotal: 723.90,
            receiptCount: 15,
            currency: "USD",
            topCategory: "Groceries"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SpendingEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendingEntry>) -> Void) {
        let entry = fetchEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> SpendingEntry {
        do {
            let schema = Schema([Receipt.self])
            let config = ModelConfiguration(schema: schema)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)

            let calendar = Calendar.current
            let now = Date.now

            // Today
            let startOfDay = calendar.startOfDay(for: now)
            let todayPredicate = #Predicate<Receipt> { $0.date >= startOfDay }
            let todayReceipts = try context.fetch(FetchDescriptor<Receipt>(predicate: todayPredicate))

            // This week
            let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date ?? now
            let weekPredicate = #Predicate<Receipt> { $0.date >= startOfWeek }
            let weekReceipts = try context.fetch(FetchDescriptor<Receipt>(predicate: weekPredicate))

            // This month
            let startOfMonth = calendar.dateComponents([.calendar, .year, .month], from: now).date ?? now
            let monthPredicate = #Predicate<Receipt> { $0.date >= startOfMonth }
            let monthReceipts = try context.fetch(FetchDescriptor<Receipt>(predicate: monthPredicate))

            let todayTotal = todayReceipts.reduce(Decimal(0)) { $0 + $1.totalAmount }
            let weekTotal = weekReceipts.reduce(Decimal(0)) { $0 + $1.totalAmount }
            let monthTotal = monthReceipts.reduce(Decimal(0)) { $0 + $1.totalAmount }
            let currency = monthReceipts.first?.currency ?? "USD"

            // Top category this month
            var categoryTotals: [String: Decimal] = [:]
            for receipt in monthReceipts {
                categoryTotals[receipt.category.displayName, default: 0] += receipt.totalAmount
            }
            let topCategory = categoryTotals.max(by: { $0.value < $1.value })?.key ?? "None"

            return SpendingEntry(
                date: now,
                todayTotal: todayTotal,
                weekTotal: weekTotal,
                monthTotal: monthTotal,
                receiptCount: monthReceipts.count,
                currency: currency,
                topCategory: topCategory
            )
        } catch {
            return SpendingEntry(
                date: .now,
                todayTotal: 0,
                weekTotal: 0,
                monthTotal: 0,
                receiptCount: 0,
                currency: "USD",
                topCategory: "—"
            )
        }
    }
}

// MARK: - Widget Views

struct SpendingWidgetSmallView: View {
    let entry: SpendingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.blue)
                Text("Today")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Text(entry.todayTotal.formatted(.currency(code: entry.currency)))
                .font(.title2.bold())
                .minimumScaleFactor(0.5)

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("Week")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.weekTotal.formatted(.currency(code: entry.currency)))
                        .font(.caption.bold())
                        .minimumScaleFactor(0.5)
                }
                Spacer()
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SpendingWidgetMediumView: View {
    let entry: SpendingEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: today + week
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.blue)
                    Text("ReceiptBrain")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.todayTotal.formatted(.currency(code: entry.currency)))
                        .font(.title2.bold())
                        .minimumScaleFactor(0.5)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("This Week")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.weekTotal.formatted(.currency(code: entry.currency)))
                        .font(.subheadline.bold())
                }
            }

            Divider()

            // Right: month + stats
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Month")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.monthTotal.formatted(.currency(code: entry.currency)))
                        .font(.title3.bold())
                        .minimumScaleFactor(0.5)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.receiptCount) receipts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text(entry.topCategory)
                            .font(.caption.bold())
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget

@main
struct ReceiptBrainWidget: Widget {
    let kind = "ReceiptBrainSpending"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendingProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                SpendingWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Spending Tracker")
        .description("See your daily, weekly, and monthly spending at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SpendingWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SpendingEntry

    var body: some View {
        switch family {
        case .systemMedium:
            SpendingWidgetMediumView(entry: entry)
        default:
            SpendingWidgetSmallView(entry: entry)
        }
    }
}
